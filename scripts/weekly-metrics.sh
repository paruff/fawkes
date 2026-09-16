#!/usr/bin/env bash
# =============================================================================
# FILE:    scripts/weekly-metrics.sh
# PURPOSE: Compute Rework Rate from real GitHub PR history, print a
#          traffic-light status (GREEN / YELLOW / RED), and update the
#          baseline table in docs/METRICS.md.
# USAGE:   ./scripts/weekly-metrics.sh [OPTIONS]
#
# OPTIONS:
#   -r, --repo OWNER/REPO  GitHub repo to query (default: paruff/fawkes)
#   -d, --dry-run          Print status but do not modify docs/METRICS.md
#   -h, --help             Show this help message
#
# DEFINITION (resolved 2026-09-16 from Google DORA's AI-era research —
# services.google.com/fh/files/misc/2025_dora_ai_capabilities_model.pdf,
# .../2025_state_of_ai_assisted_software_development.pdf,
# .../dora-roi-of-ai-assisted-software-development-2026.pdf — see
# docs/research/dora/README.md for the reference table; those PDFs are
# image/CID-font marketing documents with no extractable text layer via
# this repo's tooling, so the resolved definition below is grounded in
# the DORA 2026 framing already embedded in this repo's own Grafana panel
# (platform/apps/grafana-dashboards/dora-metrics-dashboard-configmap.yaml:
# "Fraction of AI output requiring rework ... rework = 1 - acceptance rate"),
# which is the most specific in-repo source and is dated DORA 2026 — the
# same vintage as the ROI report):
#
#   Rework Rate = AI-assisted merged PRs that needed a fix/revert follow-up
#                 within 7 days, ÷ total AI-assisted merged PRs in the window.
#
#   "AI-assisted" = the PR's commits carry a `Co-Authored-By: Claude` trailer
#   (this repo's own attribution convention — 322 real commits already carry
#   it, so this is a signal that already exists, not a new label convention
#   to adopt). "Fix/revert follow-up" = another PR merged within 7 days whose
#   Conventional Commit type (already CI-enforced, AGENTS.md SS7) is fix or
#   revert. This approximates "AI output requiring rework" without needing
#   IDE-level suggestion accept/reject telemetry Fawkes doesn't collect.
#
#   Previously (before 2026-09-16) this script queried Apache DevLake's
#   rework-rate API. DevLake was decommissioned this session in favor of
#   native PromQL DORA metrics (platform/apps/prometheus/rules/dora.yml);
#   this rewrite replaces the dead DevLake dependency with the definition
#   above, computed directly from GitHub via `gh`.
#
#   KNOWN LIMITATION, honestly labeled rather than hidden: "follow-up" is
#   time-proximity only (any fix/revert PR merged in the next 7 days), not
#   file-overlap with the AI PR's actual changed files — checking overlap
#   needs a `gh pr view --json files` call per candidate PR, and on a repo
#   merging 200+ PRs per 14 days (confirmed live 2026-09-16) that's real
#   added API/session cost for a weekly script. On a fast-moving week this
#   over-counts (an unrelated fix PR within 7 days still counts as
#   "rework"), so the number should be read as an upper bound, not a
#   precise rate, until file-overlap is added as a follow-up refinement.
#
# EXIT CODES:
#   0  GREEN  — rework rate < 10 %
#   1  YELLOW — rework rate 10-20 %
#   2  RED    — rework rate > 20 %
#   3  ERROR  — could not reach GitHub, parse response, or no AI-assisted
#               PRs in window (N/A, not a failure — printed and exits 0)
# =============================================================================

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

REPO="${REPO:-paruff/fawkes}"
DRY_RUN=false
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
METRICS_FILE="${REPO_ROOT}/docs/METRICS.md"
TODAY="$(date -u +%Y-%m-%d)"
# Reporting window: AI-assisted PRs must have merged in the last 7 days.
WEEK_AGO="$(date -u -d '7 days ago' +%Y-%m-%d 2> /dev/null \
  || date -u -v-7d +%Y-%m-%d 2> /dev/null \
  || true)"
# Lookback window: 14 days, so a fix/revert PR merged just after the 7-day
# window's start still counts as a follow-up to an AI-assisted PR near that
# boundary.
LOOKBACK="$(date -u -d '14 days ago' +%Y-%m-%d 2> /dev/null \
  || date -u -v-14d +%Y-%m-%d 2> /dev/null \
  || true)"
if [[ -z "${LOOKBACK}" || -z "${WEEK_AGO}" ]]; then
  echo "ERROR: Could not compute relative dates. Install GNU coreutils or ensure BSD date is available." >&2
  exit 3
fi

usage() {
  grep '^# ' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
  exit 0
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -r | --repo)
      REPO="$2"
      shift 2
      ;;
    -d | --dry-run)
      DRY_RUN=true
      shift
      ;;
    -h | --help)
      usage
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage
      ;;
  esac
done

log() { echo -e "${BOLD}[weekly-metrics]${NC} $*"; }
err() { echo -e "${RED}[weekly-metrics] ERROR:${NC} $*" >&2; }

require_cmd() {
  if ! command -v "$1" &> /dev/null; then
    err "Required command not found: $1"
    exit 3
  fi
}

require_cmd gh
require_cmd jq
require_cmd python3

# ---------------------------------------------------------------------------
# Fetch merged PRs (title + mergedAt only — cheap) for the lookback window.
# Deliberately NOT requesting --json commits here: on a repo with heavy PR
# volume (this one merges 200+ PRs per 14 days some weeks) the commits
# field's nested authors/messages connections blow GitHub's GraphQL
# 500,000-node query budget even at --limit 50. Confirmed live 2026-09-16.
# Commit bodies are fetched per-PR below, only for the much smaller subset
# that actually needs them (AI-assisted candidates in the 7-day window).
# ---------------------------------------------------------------------------
log "Querying ${REPO} for merged PRs since ${LOOKBACK} …"

PRS_JSON=$(gh pr list \
  --repo "${REPO}" \
  --state merged \
  --search "merged:>=${LOOKBACK}" \
  --json number,title,mergedAt \
  --limit 500) || {
  err "Failed to query GitHub PRs via gh CLI. Is 'gh auth status' logged in?"
  exit 3
}

# Candidates for "AI-assisted" (needs a commits lookup): PRs merged inside
# the actual 7-day reporting window, not the wider 14-day lookback.
AI_CANDIDATE_NUMBERS=$(echo "${PRS_JSON}" \
  | jq -r --arg start "${WEEK_AGO}" '.[] | select(.mergedAt >= $start) | .number')

AI_COMMITS_JSON="[]"
if [[ -n "${AI_CANDIDATE_NUMBERS}" ]]; then
  AI_COMMITS_JSON="["
  first=true
  while read -r num; do
    [[ -z "${num}" ]] && continue
    c=$(gh pr view "${num}" --repo "${REPO}" --json number,commits 2> /dev/null) || continue
    if [[ "${first}" == "true" ]]; then first=false; else AI_COMMITS_JSON+=","; fi
    AI_COMMITS_JSON+="${c}"
  done <<< "${AI_CANDIDATE_NUMBERS}"
  AI_COMMITS_JSON+="]"
fi

# ---------------------------------------------------------------------------
# Classify and compute the ratio in Python (reliable ISO-8601 date math,
# avoids bash/date GNU-vs-BSD divergence that plagued the DevLake version).
# JSON goes to temp files, not stdin — a heredoc's `<<` already claims the
# Python process's stdin, so piping JSON in too would silently drop it.
# ---------------------------------------------------------------------------
PRS_JSON_FILE="$(mktemp)"
COMMITS_JSON_FILE="$(mktemp)"
trap 'rm -f "${PRS_JSON_FILE}" "${COMMITS_JSON_FILE}"' EXIT
echo "${PRS_JSON}" > "${PRS_JSON_FILE}"
echo "${AI_COMMITS_JSON}" > "${COMMITS_JSON_FILE}"

RESULT=$(
  python3 - "${LOOKBACK}" "${TODAY}" "${PRS_JSON_FILE}" "${COMMITS_JSON_FILE}" << 'PYEOF'
import json, re, sys
from datetime import datetime, timedelta, timezone

with open(sys.argv[3]) as f:
    prs = json.load(f)
with open(sys.argv[4]) as f:
    commits_by_pr = {c["number"]: c.get("commits", []) for c in json.load(f)}

window_start = datetime.fromisoformat(sys.argv[1]).replace(tzinfo=timezone.utc)
window_end = datetime.fromisoformat(sys.argv[2]).replace(tzinfo=timezone.utc) + timedelta(days=1)

def is_ai_assisted(pr):
    for c in commits_by_pr.get(pr["number"], []):
        body = (c.get("messageBody", "") or "") + (c.get("messageHeadline", "") or "")
        if "Co-Authored-By: Claude" in body:
            return True
    return False

CONVENTIONAL_FIX_RE = re.compile(r'^(fix|revert)(\(.+\))?!?:', re.IGNORECASE)

def is_fix_or_revert(pr):
    return bool(CONVENTIONAL_FIX_RE.match(pr["title"].strip()))

for pr in prs:
    pr["_merged_at"] = datetime.fromisoformat(pr["mergedAt"].replace("Z", "+00:00"))

# Only count AI-assisted PRs actually merged inside the 7-day reporting window
ai_prs_in_window = [
    pr for pr in prs
    if window_start <= pr["_merged_at"] < window_end and is_ai_assisted(pr)
]

fix_revert_prs = [pr for pr in prs if is_fix_or_revert(pr)]

reworked = 0
for ai_pr in ai_prs_in_window:
    deadline = ai_pr["_merged_at"] + timedelta(days=7)
    followups = [
        fr for fr in fix_revert_prs
        if ai_pr["_merged_at"] < fr["_merged_at"] <= deadline and fr["number"] != ai_pr["number"]
    ]
    if followups:
        reworked += 1

total = len(ai_prs_in_window)
if total == 0:
    print("NA")
else:
    rate = round(100.0 * reworked / total, 1)
    print(f"{rate} {reworked} {total}")
PYEOF
) || {
  err "Failed to classify PRs (see traceback above)"
  exit 3
}

if [[ "${RESULT}" == "NA" ]]; then
  echo ""
  log "No AI-assisted (Co-Authored-By: Claude) PRs merged in the last 7 days — nothing to report."
  echo ""
  exit 0
fi

read -r REWORK_RATE REWORKED_COUNT TOTAL_COUNT <<< "${RESULT}"

STATUS=$(awk -v rate="${REWORK_RATE}" 'BEGIN {
  if (rate + 0 < 10)       { print "GREEN" }
  else if (rate + 0 <= 20) { print "YELLOW" }
  else                     { print "RED" }
}')

echo ""
case "${STATUS}" in
  GREEN)
    echo -e "${GREEN}${BOLD}●  STATUS: GREEN — Rework rate ${REWORK_RATE}% (${REWORKED_COUNT}/${TOTAL_COUNT} AI-assisted PRs, healthy, < 10%)${NC}"
    echo -e "${GREEN}   No action required.${NC}"
    EXIT_CODE=0
    ;;
  YELLOW)
    echo -e "${YELLOW}${BOLD}●  STATUS: YELLOW — Rework rate ${REWORK_RATE}% (${REWORKED_COUNT}/${TOTAL_COUNT} AI-assisted PRs, watch, 10-20%)${NC}"
    echo -e "${YELLOW}   Add a retro item and review recent AI-assisted PRs for patterns.${NC}"
    EXIT_CODE=1
    ;;
  RED)
    echo -e "${RED}${BOLD}●  STATUS: RED — Rework rate ${REWORK_RATE}% (${REWORKED_COUNT}/${TOTAL_COUNT} AI-assisted PRs, critical, > 20%)${NC}"
    echo -e "${RED}   Stop new feature work. Open a P1 issue and run a root-cause analysis.${NC}"
    EXIT_CODE=2
    ;;
esac
echo ""

# ---------------------------------------------------------------------------
# Update docs/METRICS.md baseline table
# ---------------------------------------------------------------------------
if [[ "${DRY_RUN}" == "true" ]]; then
  log "Dry-run mode — skipping update of ${METRICS_FILE}"
else
  if [[ ! -f "${METRICS_FILE}" ]]; then
    err "docs/METRICS.md not found at ${METRICS_FILE}"
    exit 3
  fi

  log "Updating baseline table in ${METRICS_FILE} …"

  NEW_ROW="| ${TODAY} | ${REWORK_RATE} % | ${STATUS} | Auto-updated by weekly-metrics.sh (${REWORKED_COUNT}/${TOTAL_COUNT} AI-assisted PRs) |"

  # python3, not sed: the file's placeholder row has irregular internal
  # spacing ("| TBD  |", two spaces) and the anchor line starts with a
  # markdown-italic "_" not "*" — both silently broke a sed-based version
  # of this (no error, no match, no write). Matching on the leading "|
  # TBD" token loosely, and the anchor by substring, avoids both traps.
  python3 - "${METRICS_FILE}" "${NEW_ROW}" << 'PYEOF'
import re, sys

path, new_row = sys.argv[1], sys.argv[2]
with open(path) as f:
    lines = f.readlines()

placeholder_re = re.compile(r'^\|\s*TBD\s*\|')
anchor_re = re.compile(r'This table is updated automatically')

for i, line in enumerate(lines):
    if placeholder_re.match(line):
        lines[i] = new_row + "\n"
        break
else:
    for i, line in enumerate(lines):
        if anchor_re.search(line):
            lines.insert(i, new_row + "\n")
            break
    else:
        sys.exit("Could not find the TBD placeholder row or the anchor line in " + path)

with open(path, "w") as f:
    f.writelines(lines)
PYEOF

  log "docs/METRICS.md updated."
  log "Commit the change with:"
  log "  git add docs/METRICS.md"
  log "  git commit -m 'chore(metrics): weekly rework rate update ${TODAY}'"
fi

exit "${EXIT_CODE}"
