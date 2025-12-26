#!/bin/bash

set -euo pipefail
# Fix null or missing tasks arrays in epic3.json

JSON_FILE="./data/issues/epic3.json"
BACKUP_FILE="./data/issues/epic3.json.backup.$(date +%Y%m%d_%H%M%S)"

echo "=== Fixing Epic 3 JSON Tasks ==="
echo ""

# Create backup
echo "Creating backup: $BACKUP_FILE"
cp "$JSON_FILE" "$BACKUP_FILE"

echo "Fixing null and missing tasks arrays..."

# Fix the JSON by ensuring all issues have a tasks array
jq '.issues |= map(
  if .tasks == null or (.tasks | type) != "array" then
    . + {"tasks": [
      {
        "id": "1",
        "name": "Placeholder task - needs definition",
        "location": "TBD",
        "type": "configuration",
        "copilot_prompt": "Define specific tasks for this issue",
        "validation": "echo \"Task needs to be defined\""
      }
    ]}
  else
    .
  end
)' "$BACKUP_FILE" > "$JSON_FILE.tmp"

# Verify the fixed JSON is valid
if jq empty "$JSON_FILE.tmp" 2> /dev/null; then
  mv "$JSON_FILE.tmp" "$JSON_FILE"
  echo "✅ Successfully fixed $JSON_FILE"
  echo ""
  echo "Changes made:"
  echo "- Added placeholder tasks to issues with null or missing tasks"
  echo "- Backup saved to: $BACKUP_FILE"
  echo ""
  echo "Next steps:"
  echo "1. Review the fixed JSON: cat $JSON_FILE | jq '.issues[] | select(.tasks[0].name == \"Placeholder task - needs definition\")'"
  echo "2. Update placeholder tasks with actual task definitions"
  echo "3. Re-run: ./scripts/create-issues-from-json.sh --epic 3 --dry-run"
else
  echo "❌ Error: Fixed JSON is invalid"
  rm "$JSON_FILE.tmp"
  exit 1
fi

echo ""
echo "=== Issues that need task definition ==="
jq -r '.issues[] | select(.tasks[0].name == "Placeholder task - needs definition") | "Issue #\(.number): \(.title)"' "$JSON_FILE"
