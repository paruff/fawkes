#!/usr/bin/env bash
# scripts/create-foundation7-issues.sh
#
# Creates the 9 Foundation 7 — Quality Internal Platforms GitHub issues
# from data/issues/foundation7.json using the gh CLI.
#
# Usage:
#   bash scripts/create-foundation7-issues.sh
#   bash scripts/create-foundation7-issues.sh --dry-run
#   bash scripts/create-foundation7-issues.sh --repo myorg/myfork
#
# Prerequisites:
#   gh auth login   (must have issues:write scope)
#   jq              (brew install jq / apt install jq)
#
# These issues implement DORA 2025 Foundation 7 platform quality improvements.
# Source: docs/ai/foundation-7-platform-quality-guide.md

set -euo pipefail

REPO="paruff/fawkes"
DRY_RUN=false
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DATA_FILE="${SCRIPT_DIR}/../data/issues/foundation7.json"

# ── Argument parsing ────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case $1 in
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --repo)
      REPO="$2"
      shift 2
      ;;
    --help)
      sed -n '/^#/p' "$0" | sed 's/^# \?//'
      exit 0
      ;;
    *)
      echo "Unknown option: $1 — use --help" >&2
      exit 1
      ;;
  esac
done

# ── Dependency checks ───────────────────────────────────────────────────────
if ! command -v gh &> /dev/null; then
  echo "ERROR: gh CLI not found. Install from https://cli.github.com/" >&2
  exit 1
fi

if ! command -v jq &> /dev/null; then
  echo "ERROR: jq not found. Install with: brew install jq / apt install jq" >&2
  exit 1
fi

if [[ ! -f "$DATA_FILE" ]]; then
  echo "ERROR: Data file not found: $DATA_FILE" >&2
  exit 1
fi

EPIC_NAME=$(jq -r '.name' "$DATA_FILE")
ISSUE_COUNT=$(jq -r '.issues | length' "$DATA_FILE")

echo "──────────────────────────────────────────────────────────────────"
echo " Foundation 7 Issue Creator"
echo " Epic : ${EPIC_NAME}"
echo " Issues: ${ISSUE_COUNT}"
echo " Repo  : ${REPO}"
if [[ "$DRY_RUN" == "true" ]]; then
  echo " Mode  : DRY RUN (no issues will be created)"
fi
echo "──────────────────────────────────────────────────────────────────"
echo ""

# ── Ensure required labels exist ────────────────────────────────────────────
# Fetch label list once to avoid multiple API calls
EXISTING_LABELS=$(gh label list --repo "$REPO" --json name --jq ".[].name" 2> /dev/null || echo "")

ensure_label() {
  local name="$1"
  local color="$2"
  local description="$3"
  if ! echo "$EXISTING_LABELS" | grep -qx "$name"; then
    if [[ "$DRY_RUN" == "true" ]]; then
      echo "  [DRY RUN] Would create label: $name"
    else
      gh label create "$name" --repo "$REPO" --color "$color" --description "$description" 2> /dev/null || true
    fi
  fi
}

ensure_label "foundation-7" "0075ca" "DORA 2025 Foundation 7 — Quality Internal Platforms"
ensure_label "comp-ai-tooling" "e4e669" "Component: AI tooling, agents, instructions"
ensure_label "comp-devex" "f9d0c4" "Component: Developer experience and workspace"

# ── Create each issue ────────────────────────────────────────────────────────
for i in $(seq 0 $((ISSUE_COUNT - 1))); do
  ISSUE=$(jq -r ".issues[$i]" "$DATA_FILE")

  TITLE=$(echo "$ISSUE" | jq -r '.title')
  EFFORT=$(echo "$ISSUE" | jq -r '.effort')
  DESCRIPTION=$(echo "$ISSUE" | jq -r '.description')
  LABELS=$(echo "$ISSUE" | jq -r '.labels | join(",")')
  SUGGESTED_MODEL=$(echo "$ISSUE" | jq -r '.suggested_model')
  MODEL_RATIONALE=$(echo "$ISSUE" | jq -r '.model_rationale')
  FILES_TO_EDIT=$(echo "$ISSUE" | jq -r '.files_to_edit | join(", ")')
  DO_NOT_TOUCH=$(echo "$ISSUE" | jq -r '.do_not_touch | join(", ")')
  ISSUE_NUM=$((i + 1))

  # Build acceptance criteria
  AC_TEXT=""
  AC_COUNT=$(echo "$ISSUE" | jq -r '.acceptance_criteria | length')
  for j in $(seq 0 $((AC_COUNT - 1))); do
    CRITERION=$(echo "$ISSUE" | jq -r ".acceptance_criteria[$j]")
    AC_TEXT+="- [ ] ${CRITERION}"$'\n'
  done

  # Build tasks section
  TASKS_TEXT=""
  TASK_COUNT=$(echo "$ISSUE" | jq -r '.tasks | length')
  for j in $(seq 0 $((TASK_COUNT - 1))); do
    TASK_ID=$(echo "$ISSUE" | jq -r ".tasks[$j].id")
    TASK_NAME=$(echo "$ISSUE" | jq -r ".tasks[$j].name")
    TASK_LOC=$(echo "$ISSUE" | jq -r ".tasks[$j].location")
    TASK_PROMPT=$(echo "$ISSUE" | jq -r ".tasks[$j].prompt")
    TASKS_TEXT+="### Task ${TASK_ID}: ${TASK_NAME}"$'\n'
    TASKS_TEXT+="**Location:** \`${TASK_LOC}\`"$'\n\n'
    TASKS_TEXT+="**Copilot prompt:**"$'\n'
    TASKS_TEXT+="\`\`\`"$'\n'"${TASK_PROMPT}"$'\n'"\`\`\`"$'\n\n'
  done

  # Build full body
  BODY="## Goal

${DESCRIPTION}

---

## Affected Files

**Edit:**
${FILES_TO_EDIT}

**Do NOT touch:**
${DO_NOT_TOUCH}

---

## Acceptance Criteria

${AC_TEXT}
---

## Tasks

${TASKS_TEXT}---

## Suggested Model

**Suggested model:** ${SUGGESTED_MODEL}
**Task type:** docs / single-file / multi-file (see model routing table in AGENTS.md §10)
**Rationale:** ${MODEL_RATIONALE}

---

## Definition of Done

- [ ] All acceptance criteria checkboxes ticked
- [ ] CI passes on the PR branch
- [ ] A human has reviewed and approved the PR
- [ ] \`Closes #NNN\` reference present in PR description

---

*Source: [Foundation 7 Platform Quality Guide](https://github.com/paruff/fawkes/blob/main/docs/ai/foundation-7-platform-quality-guide.md)*"

  echo "Creating issue ${ISSUE_NUM}/${ISSUE_COUNT}: ${TITLE:0:60}..."

  if [[ "$DRY_RUN" == "true" ]]; then
    echo "  [DRY RUN] Title : $TITLE"
    echo "  [DRY RUN] Labels: $LABELS"
    echo "  [DRY RUN] Effort: ${EFFORT}h"
    echo ""
  else
    gh issue create \
      --repo "$REPO" \
      --title "$TITLE" \
      --body "$BODY" \
      --label "$LABELS" \
      2>&1 | tail -1
    echo ""
    # Brief pause to avoid rate limiting
    sleep 1
  fi
done

echo "──────────────────────────────────────────────────────────────────"
if [[ "$DRY_RUN" == "true" ]]; then
  echo " DRY RUN complete. Remove --dry-run to create the issues."
else
  echo " Done. ${ISSUE_COUNT} issues created in ${REPO}."
  echo " View: https://github.com/${REPO}/issues?q=label%3Afoundation-7"
fi
echo "──────────────────────────────────────────────────────────────────"
