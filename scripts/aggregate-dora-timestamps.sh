#!/usr/bin/env bash
# =============================================================================
# Script: scripts/aggregate-dora-timestamps.sh
# Purpose: Parse DORA timestamps from CI logs and compute lead time
# Usage: ./scripts/aggregate-dora-timestamps.sh <log-file>
#        Or pipe from GitHub Actions log output
# =============================================================================

set -euo pipefail

LOG_FILE="${1:-}"

if [[ -z "$LOG_FILE" ]]; then
  echo "Usage: $0 <log-file>" >&2
  echo "" >&2
  echo "Parses DORA timestamp lines from CI logs:" >&2
  echo "  job-start:2026-06-08T12:00:00Z" >&2
  echo "  job-finish:2026-06-08T12:05:00Z" >&2
  echo "" >&2
  echo "Output: JSON array of job durations" >&2
  exit 1
fi

if [[ ! -f "$LOG_FILE" ]]; then
  echo "Error: File not found: $LOG_FILE" >&2
  exit 1
fi

# Cross-platform date parser (macOS BSD date + GNU date)
parse_epoch() {
  local ts="$1"
  if date -j -f "%Y-%m-%dT%H:%M:%SZ" "$ts" "+%s" &>/dev/null; then
    date -j -f "%Y-%m-%dT%H:%M:%SZ" "$ts" "+%s"
  elif date -d "$ts" "+%s" &>/dev/null; then
    date -d "$ts" "+%s"
  else
    echo "Error: Cannot parse timestamp: $ts" >&2
    return 1
  fi
}

echo "["
first=true

current_job=""
current_start=""
current_workflow=""

while IFS= read -r line; do
  # Extract job-start timestamps
  if [[ "$line" =~ job-start:([0-9T:-]+Z) ]]; then
    current_start="${BASH_REMATCH[1]}"
  fi

  # Extract workflow name
  if [[ "$line" =~ workflow:(.+) ]]; then
    current_workflow="${BASH_REMATCH[1]}"
  fi

  # Extract job name
  if [[ "$line" =~ job:(.+) ]]; then
    current_job="${BASH_REMATCH[1]}"
  fi

  # Extract job-finish timestamps
  if [[ "$line" =~ job-finish:([0-9T:-]+Z) ]]; then
    current_finish="${BASH_REMATCH[1]}"

    if [[ -n "$current_start" && -n "$current_job" ]]; then
      start_epoch=$(parse_epoch "$current_start") || start_epoch=0
      finish_epoch=$(parse_epoch "$current_finish") || finish_epoch=0
      duration=$((finish_epoch - start_epoch))

      if [[ "$first" == "true" ]]; then
        first=false
      else
        echo ","
      fi

      cat <<EOF
  {"workflow":"${current_workflow}","job":"${current_job}","start":"${current_start}","finish":"${current_finish}","duration_seconds":${duration}}
EOF
    fi

    current_start=""
    current_job=""
  fi
done < "$LOG_FILE"

echo ""
echo "]"
