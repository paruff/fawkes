#!/usr/bin/env bash
set -eu

SAVE_MODE=0
if [ "${1:-}" = "--save" ]; then
  SAVE_MODE=1
elif [ "${1:-}" != "" ]; then
  echo "Usage: bash scripts/token-audit.sh [--save]" >&2
  exit 1
fi

REPO_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$REPO_ROOT"

WORK_DAYS=22
LIGHT_TASKS=10
MODERATE_TASKS=20
HEAVY_TASKS=50
INPUT_COST_PER_1K=0.003
TARGET_LINES=80
TARGET_TOKENS=320

timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
total_lines=0
total_tokens=0
audit_rows=""

print_cost() {
  tokens=$1
  tasks=$2
  awk -v tokens="$tokens" -v tasks="$tasks" -v days="$WORK_DAYS" -v rate="$INPUT_COST_PER_1K"     'BEGIN { printf "%.2f", (tokens / 1000.0) * tasks * days * rate }'
}

audit_file() {
  file_path=$1
  label=$2
  if [ -f "$file_path" ]; then
    lines=$(wc -l < "$file_path" | tr -d ' ')
    chars=$(wc -c < "$file_path" | tr -d ' ')
    tokens=$(awk -v chars="$chars" 'BEGIN { printf "%d", int((chars + 3) / 4) }')
    light=$(print_cost "$tokens" "$LIGHT_TASKS")
    moderate=$(print_cost "$tokens" "$MODERATE_TASKS")
    heavy=$(print_cost "$tokens" "$HEAVY_TASKS")
    total_lines=$((total_lines + lines))
    total_tokens=$((total_tokens + tokens))
    audit_rows="$audit_rows$(printf '%s|%s|%s|%s|%s|%s
' "$label" "$lines" "$tokens" "$light" "$moderate" "$heavy")"
  else
    audit_rows="$audit_rows$(printf '%s|missing|0|0.00|0.00|0.00
' "$label")"
  fi
}

audit_file "AGENTS.md" "AGENTS.md"
audit_file ".github/copilot-instructions.md" ".github/copilot-instructions.md"
audit_file "CLAUDE.md" "CLAUDE.md"

total_light=$(print_cost "$total_tokens" "$LIGHT_TASKS")
total_moderate=$(print_cost "$total_tokens" "$MODERATE_TASKS")
total_heavy=$(print_cost "$total_tokens" "$HEAVY_TASKS")

if [ -f ".copilotignore" ]; then
  copilotignore_rules=$(grep -Evc '^[[:space:]]*(#|$)' .copilotignore || true)
  copilotignore_status="present"
else
  copilotignore_rules=0
  copilotignore_status="missing"
fi

if [ -f "AGENTS.md" ]; then
  agents_lines=$(wc -l < AGENTS.md | tr -d ' ')
  agents_chars=$(wc -c < AGENTS.md | tr -d ' ')
  agents_tokens=$(awk -v chars="$agents_chars" 'BEGIN { printf "%d", int((chars + 3) / 4) }')
else
  agents_lines=0
  agents_tokens=0
fi

if [ "$agents_lines" -le "$TARGET_LINES" ] && [ "$agents_tokens" -le "$TARGET_TOKENS" ]; then
  agents_status="LEAN"
else
  agents_status="OVER"
fi

recommendations=""
if [ "$total_tokens" -gt "$TARGET_TOKENS" ]; then
  recommendations="$recommendations- Always-on context exceeds the 320-token target; move detail into .github/skills/.
"
else
  recommendations="$recommendations- Always-on context is within the lean target; keep new rules in on-demand skills.
"
fi
if [ "$copilotignore_status" = "missing" ]; then
  recommendations="$recommendations- Add a .copilotignore file to keep generated and sensitive files out of prompts.
"
else
  recommendations="$recommendations- Review the top 10 largest files below and add low-signal paths to .copilotignore if needed.
"
fi
if [ "$agents_status" = "OVER" ]; then
  recommendations="$recommendations- Trim AGENTS.md below 80 lines and 320 estimated tokens.
"
else
  recommendations="$recommendations- AGENTS.md meets the lean target; preserve it as a routing layer only.
"
fi

output_file=$(mktemp)
{
  echo "# Copilot Token Audit"
  echo
  echo "Generated: $timestamp"
  echo
  echo "## Always-on context"
  echo "File|Lines|Estimated tokens|Light \$ / month|Moderate \$ / month|Heavy \$ / month"
  echo "---|---:|---:|---:|---:|---:"
  printf '%s' "$audit_rows"
  echo
  echo "Total always-on lines: $total_lines"
  echo "Total always-on tokens: $total_tokens"
  echo "Light monthly input-cost estimate: \$$total_light"
  echo "Moderate monthly input-cost estimate: \$$total_moderate"
  echo "Heavy monthly input-cost estimate: \$$total_heavy"
  echo
  echo "## AGENTS target"
  echo "AGENTS.md status: $agents_status"
  echo "AGENTS.md lines: $agents_lines (target <= $TARGET_LINES)"
  echo "AGENTS.md estimated tokens: $agents_tokens (target <= $TARGET_TOKENS)"
  echo
  echo "## .copilotignore"
  echo "Status: $copilotignore_status"
  echo "Rule count: $copilotignore_rules"
  echo
  echo "## Top 10 largest files"
  find . -type f ! -path './.git/*' -exec du -k {} + | sort -rn | head -10
  echo
  echo "## Recommendations"
  printf '%b' "$recommendations"
  echo
  echo "Note: cost estimates use input-only pricing at \$0.003 per 1K tokens and $WORK_DAYS working days/month."
} > "$output_file"

cat "$output_file"

if [ "$SAVE_MODE" -eq 1 ]; then
  mkdir -p docs
  metrics_file="docs/METRICS.md"
  if [ ! -f "$metrics_file" ]; then
    {
      echo "# Metrics"
      echo
    } > "$metrics_file"
  fi
  {
    echo
    echo "## Copilot Token Audit Snapshot ($timestamp)"
    echo
    echo '```text'
    cat "$output_file"
    echo '```'
  } >> "$metrics_file"
  echo
  echo "Saved audit snapshot to $metrics_file"
fi

rm -f "$output_file"
