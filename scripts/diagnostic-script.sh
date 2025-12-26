#!/bin/bash

set -euo pipefail
# Script to diagnose and fix epic3.json issues

echo "=== Diagnosing Epic 3 JSON Issues ==="
echo ""

JSON_FILE="./data/issues/epic3.json"

# Check if file exists
if [ ! -f "$JSON_FILE" ]; then
  echo "ERROR: File $JSON_FILE not found"
  exit 1
fi

echo "1. Checking JSON validity..."
if jq empty "$JSON_FILE" 2> /dev/null; then
  echo "✅ JSON is valid"
else
  echo "❌ JSON is invalid - syntax errors detected"
  jq empty "$JSON_FILE"
  exit 1
fi

echo ""
echo "2. Checking for null tasks arrays..."
NULL_TASKS=$(jq -r '.issues[] | select(.tasks == null) | .number' "$JSON_FILE" 2> /dev/null)
if [ -n "$NULL_TASKS" ]; then
  echo "❌ Found issues with null tasks:"
  echo "$NULL_TASKS"
else
  echo "✅ No null tasks arrays found"
fi

echo ""
echo "3. Checking for issues without tasks array..."
NO_TASKS=$(jq -r '.issues[] | select(has("tasks") | not) | .number' "$JSON_FILE" 2> /dev/null)
if [ -n "$NO_TASKS" ]; then
  echo "⚠️  Found issues without tasks array:"
  echo "$NO_TASKS"
else
  echo "✅ All issues have tasks array"
fi

echo ""
echo "4. Checking for empty or malformed tasks..."
EMPTY_TASKS=$(jq -r '.issues[] | select(.tasks == []) | .number' "$JSON_FILE" 2> /dev/null)
if [ -n "$EMPTY_TASKS" ]; then
  echo "⚠️  Found issues with empty tasks array:"
  echo "$EMPTY_TASKS"
else
  echo "✅ All issues have non-empty tasks"
fi

echo ""
echo "5. Detailed issue analysis..."
jq -r '.issues[] | "Issue #\(.number): \(.title) - Tasks: \(.tasks | if . == null then "NULL" elif . == [] then "EMPTY" else (length | tostring) end)"' "$JSON_FILE"

echo ""
echo "6. Attempting to identify line 920 context..."
sed -n '915,925p' "$JSON_FILE" | cat -n

echo ""
echo "=== Suggested Fixes ==="
echo ""
echo "If you found issues with null or missing tasks, run:"
echo "  ./scripts/fix-epic3-tasks.sh"
echo ""
echo "This will create a backup and fix the issues automatically."
