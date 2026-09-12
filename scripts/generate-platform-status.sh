#!/bin/bash
# =============================================================================
# Script: generate-platform-status.sh
# Purpose: Aggregate the JSON reports written by scripts/validate-golden-path-*.sh
#          into docs/PLATFORM_STATUS.md - a machine-generated status page,
#          not a hand-typed one. Part of the "make done mean verified"
#          initiative (docs/elite-engineering-bridge-plan.md, Phase 1).
#
# Reads: reports/golden-path-<plane>-validation-*.json (most recent per plane)
# Writes: docs/PLATFORM_STATUS.md
#
# Each report is expected to have: .plane, .timestamp, .summary.total,
# .summary.passed, .summary.failed. Missing/malformed reports are rendered
# as "no data" rather than crashing the whole generation - one broken plane
# script should not hide the other 7 planes' real status.
# =============================================================================
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPORTS_DIR="${ROOT_DIR}/reports"
OUTPUT_FILE="${ROOT_DIR}/docs/PLATFORM_STATUS.md"
RUN_URL="${GITHUB_SERVER_URL:-}/${GITHUB_REPOSITORY:-}/actions/runs/${GITHUB_RUN_ID:-}"
GENERATED_AT="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

PLANES=(devex dora gitops observability pipeline progressive-delivery resources security)

{
  echo "# Platform Status"
  echo
  echo "> **Machine-generated. Do not hand-edit.** Produced by \`scripts/generate-platform-status.sh\`"
  echo "> from the latest \`scripts/validate-golden-path-*.sh\` reports. Regenerated nightly and"
  echo "> on-demand by \`.github/workflows/golden-path-verification.yml\`."
  echo ">"
  if [ -n "${GITHUB_RUN_ID:-}" ]; then
    echo "> Last run: $GENERATED_AT — [workflow run]($RUN_URL)"
  else
    echo "> Last run: $GENERATED_AT (local/manual run, no workflow link)"
  fi
  echo
  echo "| Plane | Status | Passed / Total | Last Checked |"
  echo "|---|---|---|---|"

  for plane in "${PLANES[@]}"; do
    latest="$(find "$REPORTS_DIR" -maxdepth 1 -name "golden-path-${plane}-validation-*.json" 2> /dev/null | sort | tail -1)"

    if [ -z "$latest" ] || [ ! -f "$latest" ]; then
      echo "| $plane | ⚪ no data | — | never |"
      continue
    fi

    total="$(python3 -c "import json; d=json.load(open('$latest')); print(d.get('summary', {}).get('total', 0))" 2> /dev/null || echo 0)"
    passed="$(python3 -c "import json; d=json.load(open('$latest')); print(d.get('summary', {}).get('passed', 0))" 2> /dev/null || echo 0)"
    timestamp="$(python3 -c "import json; d=json.load(open('$latest')); print(d.get('timestamp', 'unknown'))" 2> /dev/null || echo unknown)"

    if [ "$total" = "0" ]; then
      status="⚪ no checks defined"
    elif [ "$passed" = "$total" ]; then
      status="🟢 all passed"
    elif [ "$passed" = "0" ]; then
      status="🔴 all failed"
    else
      status="🟡 partial"
    fi

    echo "| $plane | $status | ${passed}/${total} | $timestamp |"
  done

  echo
  echo "## What this replaces"
  echo
  echo "Prior to this, \`docs/BACKLOG.md\`'s per-phase status tables were hand-typed and"
  echo "drifted from reality in both directions (see the Phase 2 audit this file's"
  echo "generation was born from). This page is the single source of truth for"
  echo "\"is it actually working right now\" - \`BACKLOG.md\` should link here, not"
  echo "duplicate a status claim."
} > "$OUTPUT_FILE"

echo "Wrote $OUTPUT_FILE"
