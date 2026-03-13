#!/usr/bin/env bash
# =============================================================================
# FILE:    scripts/check-ai-readiness.sh
# PURPOSE: Check each service in services/ for AI-readiness signals.
#          Outputs a table and appends/updates results in docs/METRICS.md.
#
# USAGE:   bash scripts/check-ai-readiness.sh [OPTIONS]
#
# OPTIONS:
#   -d, --dry-run    Print table but do not update docs/METRICS.md
#   -h, --help       Show this help message
#
# METRICS EMITTED:
#   type_hint_coverage: % of public functions with return type hints
#   docstring_coverage: % of public functions with docstrings
#   test_coverage:      1 if tests/unit/test_<service>*.py exists, else 0
#   bdd_coverage:       1 if tests/bdd/features/<service>*.feature exists, else 0
#
# EXIT CODES:
#   0  All scanned services at >= 50% type-hint coverage
#   1  One or more services below 50% type-hint threshold
# =============================================================================

set -euo pipefail

# ---------------------------------------------------------------------------
# Colours
# ---------------------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

# ---------------------------------------------------------------------------
# Defaults
# ---------------------------------------------------------------------------
DRY_RUN=false
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
METRICS_FILE="${METRICS_FILE:-${REPO_ROOT}/docs/METRICS.md}"
SERVICES_DIR="${SERVICES_DIR:-${REPO_ROOT}/services}"
TESTS_UNIT_DIR="${TESTS_UNIT_DIR:-${REPO_ROOT}/tests/unit}"
TESTS_BDD_DIR="${TESTS_BDD_DIR:-${REPO_ROOT}/tests/bdd/features}"
TODAY="$(date -u +%Y-%m-%d)"

# ---------------------------------------------------------------------------
# Usage
# ---------------------------------------------------------------------------
usage() {
  grep '^# ' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
}

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------
while [[ $# -gt 0 ]]; do
  case "$1" in
    -d | --dry-run)
      DRY_RUN=true
      shift
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      printf "Unknown option: %s\n" "$1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
log() { printf "${BOLD}[check-ai-readiness]${NC} %s\n" "$*"; }
err() { printf "${RED}[check-ai-readiness] ERROR:${NC} %s\n" "$*" >&2; }

require_cmd() {
  if ! command -v "$1" &> /dev/null; then
    err "Required command not found: $1"
    exit 1
  fi
}

require_cmd python3
require_cmd awk
require_cmd find

# ---------------------------------------------------------------------------
# count_function_metrics <app_dir>
# Uses Python AST for accurate detection of public function type hints
# and docstrings (private functions starting with _ are excluded).
# Prints: typed_count total_count type_pct doc_count doc_pct
# ---------------------------------------------------------------------------
count_function_metrics() {
  local app_dir="$1"
  python3 -c '
import ast
import os
import sys

app_dir = sys.argv[1]
total = 0
typed = 0
with_doc = 0

for root, dirs, files in os.walk(app_dir):
    for fname in files:
        if not fname.endswith(".py"):
            continue
        fpath = os.path.join(root, fname)
        try:
            with open(fpath) as fh:
                tree = ast.parse(fh.read(), filename=fpath)
        except (SyntaxError, OSError):
            continue
        for node in ast.walk(tree):
            if not isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef)):
                continue
            if node.name.startswith("_"):
                continue
            total += 1
            if node.returns is not None:
                typed += 1
            if (
                node.body
                and isinstance(node.body[0], ast.Expr)
                and isinstance(node.body[0].value, ast.Constant)
                and isinstance(node.body[0].value.value, str)
            ):
                with_doc += 1

type_pct = (typed * 100 // total) if total > 0 else 0
doc_pct = (with_doc * 100 // total) if total > 0 else 0
print("{} {} {} {} {}".format(typed, total, type_pct, with_doc, doc_pct))
' "$app_dir" 2> /dev/null \
    || echo "0 0 0 0 0"
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
log "Scanning services in ${SERVICES_DIR} …"
printf "\n"

SEP="$(printf '%80s' | tr ' ' '-')"

printf "%-30s %-22s %-22s %-12s %-6s\n" \
  "Service" "Type-hints" "Docstrings" "Unit tests" "BDD"
printf "%s\n" "${SEP}"

BELOW_THRESHOLD=0
TOTAL_SERVICES=0
MD_ROWS=""

for service_dir in "${SERVICES_DIR}"/*/; do
  [[ -d "${service_dir}" ]] || continue
  name="$(basename "${service_dir}")"
  app_dir="${service_dir}app"

  # Skip services without an app/ directory (e.g. samples/)
  if [[ ! -d "${app_dir}" ]]; then
    continue
  fi

  TOTAL_SERVICES=$((TOTAL_SERVICES + 1))

  # --- Python AST metrics ---
  metrics="$(count_function_metrics "${app_dir}")"
  typed_count="$(printf '%s' "${metrics}" | awk '{print $1}')"
  total_count="$(printf '%s' "${metrics}" | awk '{print $2}')"
  type_pct="$(printf '%s' "${metrics}" | awk '{print $3}')"
  doc_count="$(printf '%s' "${metrics}" | awk '{print $4}')"
  doc_pct="$(printf '%s' "${metrics}" | awk '{print $5}')"

  # --- Unit test coverage ---
  unit_count="$(find "${TESTS_UNIT_DIR}" -maxdepth 1 -name "test_*${name}*.py" 2> /dev/null | wc -l | awk '{print $1}')"
  unit_flag=0
  [[ "${unit_count}" -gt 0 ]] && unit_flag=1

  # --- BDD coverage ---
  bdd_count="$(find "${TESTS_BDD_DIR}" -maxdepth 1 -name "*${name}*.feature" 2> /dev/null | wc -l | awk '{print $1}')"
  bdd_flag=0
  [[ "${bdd_count}" -gt 0 ]] && bdd_flag=1

  # --- Traffic-light colours for type hints ---
  if [[ "${type_pct}" -ge 80 ]]; then
    type_col="${GREEN}"
  elif [[ "${type_pct}" -ge 50 ]]; then
    type_col="${YELLOW}"
  else
    type_col="${RED}"
    BELOW_THRESHOLD=$((BELOW_THRESHOLD + 1))
  fi

  # --- Traffic-light colours for docstrings ---
  if [[ "${doc_pct}" -ge 80 ]]; then
    doc_col="${GREEN}"
  elif [[ "${doc_pct}" -ge 50 ]]; then
    doc_col="${YELLOW}"
  else
    doc_col="${RED}"
  fi

  unit_display="N"
  [[ "${unit_flag}" -eq 1 ]] && unit_display="Y"

  bdd_display="N"
  [[ "${bdd_flag}" -eq 1 ]] && bdd_display="Y"

  type_str="${typed_count}/${total_count} (${type_pct}%)"
  doc_str="${doc_count}/${total_count} (${doc_pct}%)"

  printf "%-30s " "${name}"
  printf "${type_col}%-22s${NC} " "${type_str}"
  printf "${doc_col}%-22s${NC} " "${doc_str}"
  printf "%-12s %-6s\n" "${unit_display}" "${bdd_display}"

  # --- Accumulate markdown rows (no ANSI codes in markdown) ---
  unit_md="N"
  [[ "${unit_flag}" -eq 1 ]] && unit_md="Y"
  bdd_md="N"
  [[ "${bdd_flag}" -eq 1 ]] && bdd_md="Y"

  MD_ROWS="${MD_ROWS}| ${name} | ${type_str} | ${doc_str} | ${unit_md} | ${bdd_md} |
"
done

printf "%s\n" "${SEP}"
printf "\n"
log "Scanned ${TOTAL_SERVICES} service(s). ${BELOW_THRESHOLD} below 50% type-hint threshold."
printf "\n"

# ---------------------------------------------------------------------------
# Update docs/METRICS.md
# ---------------------------------------------------------------------------
if [[ "${DRY_RUN}" == "true" ]]; then
  log "Dry-run mode — skipping update of ${METRICS_FILE}"
else
  if [[ ! -f "${METRICS_FILE}" ]]; then
    err "${METRICS_FILE} not found"
    exit 1
  fi

  log "Updating AI-Readiness section in ${METRICS_FILE} …"

  SECTION_TMP="$(mktemp)"

  {
    printf '## AI-Readiness Metrics\n\n'
    printf '> Last updated: %s by `scripts/check-ai-readiness.sh`\n' "${TODAY}"
    printf '> Threshold: >= 80%% GREEN | 50-79%% YELLOW | < 50%% RED\n\n'
    printf '| Service | Type-hints | Docstrings | Unit Tests | BDD |\n'
    printf '|---|---|---|---|---|\n'
    printf '%s' "${MD_ROWS}"
  } > "${SECTION_TMP}"

  if grep -q "^## AI-Readiness Metrics" "${METRICS_FILE}"; then
    # Replace existing section by removing old lines then appending new content
    python3 -c '
import sys

metrics_file = sys.argv[1]
section_file = sys.argv[2]

with open(section_file) as sf:
    new_section = sf.read()

with open(metrics_file) as f:
    content = f.read()

lines = content.split("\n")
new_lines = []
skip = False
for line in lines:
    if line.startswith("## AI-Readiness Metrics"):
        skip = True
        continue
    if skip and line.startswith("## "):
        skip = False
    if not skip:
        new_lines.append(line)

content = "\n".join(new_lines).rstrip("\n") + "\n\n" + new_section.strip() + "\n"

with open(metrics_file, "w") as f:
    f.write(content)
' "${METRICS_FILE}" "${SECTION_TMP}"
  else
    {
      printf '\n'
      cat "${SECTION_TMP}"
    } >> "${METRICS_FILE}"
  fi

  rm -f "${SECTION_TMP}"
  log "${METRICS_FILE} updated."
  log "Commit with:"
  log "  git add ${METRICS_FILE}"
  log "  git commit -m 'chore(metrics): AI-readiness scan ${TODAY}'"
fi

# Exit 1 if any service is below the 50% type-hint threshold
if [[ "${BELOW_THRESHOLD}" -gt 0 ]]; then
  exit 1
fi
exit 0
