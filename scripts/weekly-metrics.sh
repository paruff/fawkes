#!/usr/bin/env bash
# =============================================================================
# FILE:    scripts/weekly-metrics.sh
# PURPOSE: Query DevLake API for rework rate over the last 7 days,
#          print a traffic-light status (GREEN / YELLOW / RED), and
#          update the baseline table in docs/METRICS.md.
# USAGE:   ./scripts/weekly-metrics.sh [OPTIONS]
#
# OPTIONS:
#   -u, --devlake-url URL   DevLake API base URL (default: $DEVLAKE_URL or
#                           http://devlake.127.0.0.1.nip.io)
#   -d, --dry-run           Print status but do not modify docs/METRICS.md
#   -h, --help              Show this help message
#
# ENVIRONMENT:
#   DEVLAKE_URL             Override the DevLake API base URL
#
# EXIT CODES:
#   0  GREEN  — rework rate < 10 %
#   1  YELLOW — rework rate 10–20 %
#   2  RED    — rework rate > 20 %
#   3  ERROR  — could not reach DevLake or parse response
# =============================================================================

set -euo pipefail

# ---------------------------------------------------------------------------
# Colour helpers
# ---------------------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

# ---------------------------------------------------------------------------
# Defaults
# ---------------------------------------------------------------------------
DEVLAKE_URL="${DEVLAKE_URL:-http://devlake.127.0.0.1.nip.io}"
DRY_RUN=false
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
METRICS_FILE="${REPO_ROOT}/docs/METRICS.md"
TODAY="$(date -u +%Y-%m-%d)"
WEEK_AGO="$(date -u -d '7 days ago' +%Y-%m-%d 2> /dev/null \
  || date -u -v-7d +%Y-%m-%d 2> /dev/null \
  || true)"
if [[ -z "${WEEK_AGO}" ]]; then
  echo "ERROR: Could not compute date 7 days ago. Install GNU coreutils or ensure BSD date is available." >&2
  exit 3
fi

# ---------------------------------------------------------------------------
# Usage
# ---------------------------------------------------------------------------
usage() {
  grep '^# ' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
  exit 0
}

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------
while [[ $# -gt 0 ]]; do
  case "$1" in
    -u | --devlake-url)
      DEVLAKE_URL="$2"
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

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
log() { echo -e "${BOLD}[weekly-metrics]${NC} $*"; }
err() { echo -e "${RED}[weekly-metrics] ERROR:${NC} $*" >&2; }

require_cmd() {
  if ! command -v "$1" &> /dev/null; then
    err "Required command not found: $1"
    exit 3
  fi
}

# ---------------------------------------------------------------------------
# Dependency check
# ---------------------------------------------------------------------------
require_cmd curl
require_cmd jq
require_cmd awk
require_cmd sed

# ---------------------------------------------------------------------------
# Query DevLake for rework rate
# ---------------------------------------------------------------------------
log "Querying DevLake at ${DEVLAKE_URL} for rework rate (${WEEK_AGO} → ${TODAY}) …"

DEVLAKE_API="${DEVLAKE_URL}/api/plugins/devlake/rework-rate"

HTTP_RESPONSE=$(curl \
  --silent \
  --show-error \
  --fail \
  --max-time 30 \
  --write-out "\n%{http_code}" \
  "${DEVLAKE_API}?from=${WEEK_AGO}&to=${TODAY}" \
  2>&1) || {
  err "Failed to reach DevLake API at ${DEVLAKE_API}"
  err "Is DevLake running? Check: kubectl get pods -n fawkes-devlake"
  exit 3
}

HTTP_BODY=$(echo "${HTTP_RESPONSE}" | head -n -1)
HTTP_CODE=$(echo "${HTTP_RESPONSE}" | tail -n 1)

if [[ "${HTTP_CODE}" != "200" ]]; then
  err "DevLake API returned HTTP ${HTTP_CODE}"
  err "Response body: ${HTTP_BODY}"
  exit 3
fi

# Extract rework_rate value (expects JSON: {"rework_rate": 12.5, ...})
REWORK_RATE=$(echo "${HTTP_BODY}" | jq -r '.rework_rate // empty') || {
  err "Could not parse .rework_rate from DevLake response"
  err "Response: ${HTTP_BODY}"
  exit 3
}

if [[ -z "${REWORK_RATE}" ]]; then
  err ".rework_rate field missing in DevLake response"
  err "Response: ${HTTP_BODY}"
  exit 3
fi

# ---------------------------------------------------------------------------
# Classify traffic-light status
# ---------------------------------------------------------------------------
# Use awk for floating-point comparison (bash arithmetic is integer-only)
STATUS=$(awk -v rate="${REWORK_RATE}" 'BEGIN {
  if (rate + 0 < 10)       { print "GREEN" }
  else if (rate + 0 <= 20) { print "YELLOW" }
  else                     { print "RED" }
}')

# ---------------------------------------------------------------------------
# Print result
# ---------------------------------------------------------------------------
echo ""
case "${STATUS}" in
  GREEN)
    echo -e "${GREEN}${BOLD}●  STATUS: GREEN — Rework rate ${REWORK_RATE}% (healthy, < 10%)${NC}"
    echo -e "${GREEN}   No action required.${NC}"
    EXIT_CODE=0
    ;;
  YELLOW)
    echo -e "${YELLOW}${BOLD}●  STATUS: YELLOW — Rework rate ${REWORK_RATE}% (watch, 10–20%)${NC}"
    echo -e "${YELLOW}   Add a retro item and review recent PRs for patterns.${NC}"
    EXIT_CODE=1
    ;;
  RED)
    echo -e "${RED}${BOLD}●  STATUS: RED — Rework rate ${REWORK_RATE}% (critical, > 20%)${NC}"
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

  # Build the new row to prepend after the table header line
  NEW_ROW="| ${TODAY} | ${REWORK_RATE} % | ${STATUS} | Auto-updated by weekly-metrics.sh |"

  # Replace the TBD placeholder row (first occurrence only) with the real row,
  # or prepend a new row after the table header if the file already has data rows.
  # The pattern anchors to the start of the table row to avoid unintended matches.
  if grep -qE '^\| TBD \|' "${METRICS_FILE}"; then
    # Replace the placeholder row (anchored to line start)
    sed -i "s|^| TBD |.*|${NEW_ROW}|" "${METRICS_FILE}" 2> /dev/null \
      || sed -i '' "s/^| TBD |.*/${NEW_ROW}/" "${METRICS_FILE}"
  else
    # Append a new row before the closing italic line (*This table is updated…*)
    ANCHOR='*This table is updated automatically'
    sed -i "/${ANCHOR}/i ${NEW_ROW}" "${METRICS_FILE}" 2> /dev/null \
      || sed -i '' "/${ANCHOR}/i\\
${NEW_ROW}" "${METRICS_FILE}"
  fi

  log "docs/METRICS.md updated."
  log "Commit the change with:"
  log "  git add docs/METRICS.md"
  log "  git commit -m 'chore(metrics): weekly rework rate update ${TODAY}'"
fi

exit "${EXIT_CODE}"
