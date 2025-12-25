#!/bin/bash

# Fawkes GitHub Issues Generator - JSON-based
# Generates all issues from JSON data files
# Requires: gh (GitHub CLI) and jq

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
REPO="paruff/fawkes"
DRY_RUN=false
DATA_DIR="./data/issues"

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --epic)
      EPIC="$2"
      shift 2
      ;;
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --repo)
      REPO="$2"
      shift 2
      ;;
    --data-dir)
      DATA_DIR="$2"
      shift 2
      ;;
    --help)
      echo "Usage: $0 [options]"
      echo ""
      echo "Options:"
      echo "  --epic [1|2|3]      Generate issues for specific epic only"
      echo "  --dry-run           Preview issues without creating them"
      echo "  --repo OWNER/REPO   Specify repository (default: paruff/fawkes)"
      echo "  --data-dir PATH     Path to JSON data files (default: ./data/issues)"
      echo "  --help              Show this help message"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      echo "Use --help for usage information"
      exit 1
      ;;
  esac
done

# Check prerequisites
if ! command -v gh &> /dev/null; then
    echo -e "${RED}Error: GitHub CLI (gh) is not installed${NC}"
    echo "Install from: https://cli.github.com/"
    exit 1
fi

if ! command -v jq &> /dev/null; then
    echo -e "${RED}Error: jq is not installed${NC}"
    echo "Install: brew install jq (macOS) or apt-get install jq (Linux)"
    exit 1
fi

if ! gh auth status &> /dev/null; then
    echo -e "${RED}Error: Not authenticated with GitHub CLI${NC}"
    echo "Run: gh auth login"
    exit 1
fi

echo -e "${GREEN}=== Fawkes GitHub Issues Generator (JSON-based) ===${NC}"
echo "Repository: $REPO"
echo "Data Directory: $DATA_DIR"
echo "Dry Run: $DRY_RUN"
echo ""

# Function to create issue from JSON
create_issue_from_json() {
    local json_file=$1
    local issue_index=$2

    # Extract issue data using jq
    local title=$(jq -r ".issues[$issue_index].title" "$json_file")
    local milestone=$(jq -r ".issues[$issue_index].milestone" "$json_file")
    local priority=$(jq -r ".issues[$issue_index].priority" "$json_file")
    local effort=$(jq -r ".issues[$issue_index].effort" "$json_file")
    local description=$(jq -r ".issues[$issue_index].description" "$json_file")
    local labels=$(jq -r ".issues[$issue_index].labels | join(\",\")" "$json_file")
    local issue_number=$(jq -r ".issues[$issue_index].number" "$json_file")

    # Build acceptance criteria section
    local acceptance_criteria=""
    local criteria_count=$(jq -r ".issues[$issue_index].acceptance_criteria | length" "$json_file")
    if [ "$criteria_count" != "null" ] && [ "$criteria_count" -gt 0 ]; then
        acceptance_criteria="## Acceptance Criteria\n"
        for i in $(seq 0 $((criteria_count - 1))); do
            local criterion=$(jq -r ".issues[$issue_index].acceptance_criteria[$i]" "$json_file")
            acceptance_criteria+="- [ ] $criterion\n"
        done
    fi

    # Build tasks section
    local tasks_section=""
    local tasks_count=$(jq -r ".issues[$issue_index].tasks | length" "$json_file" 2>/dev/null || echo "0")
    if [ "$tasks_count" != "null" ] && [ "$tasks_count" -gt 0 ]; then
        tasks_section="## Tasks\n\n"
        for i in $(seq 0 $((tasks_count - 1))); do
            local task_id=$(jq -r ".issues[$issue_index].tasks[$i].id" "$json_file")
            local task_name=$(jq -r ".issues[$issue_index].tasks[$i].name" "$json_file")
            local task_location=$(jq -r ".issues[$issue_index].tasks[$i].location" "$json_file")
            local task_prompt=$(jq -r ".issues[$issue_index].tasks[$i].prompt" "$json_file")

            tasks_section+="### Task $task_id: $task_name\n"
            tasks_section+="**Location**: \`$task_location\`\n\n"
            tasks_section+="**Copilot Prompt**:\n\`\`\`\n$task_prompt\n\`\`\`\n\n"
        done
    fi

    # Build dependencies section
    local depends_on=$(jq -r ".issues[$issue_index].depends_on | map(\"#\" + tostring) | join(\", \")" "$json_file")
    local blocks=$(jq -r ".issues[$issue_index].blocks | map(\"#\" + tostring) | join(\", \")" "$json_file")

    local dependencies_section=""
    if [ "$depends_on" != "" ] && [ "$depends_on" != "null" ]; then
        dependencies_section+="## Dependencies\n"
        dependencies_section+="- **Depends on**: $depends_on\n"
    fi
    if [ "$blocks" != "" ] && [ "$blocks" != "null" ]; then
        if [ "$dependencies_section" = "" ]; then
            dependencies_section+="## Dependencies\n"
        fi
        dependencies_section+="- **Blocks**: $blocks\n"
    fi

    # Build validation section
    local validation=$(jq -r ".issues[$issue_index].validation" "$json_file" 2>/dev/null || echo "null")
    local validation_section=""
    if [ "$validation" != "null" ] && [ "$validation" != "" ]; then
        validation_section="## Validation\n\`\`\`bash\n$validation\n\`\`\`\n"
    fi

    # Build complete issue body
    local body="# Issue #$issue_number: $title

**Epic**: $(jq -r ".name" "$json_file")
**Milestone**: $milestone
**Priority**: $priority
**Estimated Effort**: $effort hours

## Description
$description

$acceptance_criteria

$tasks_section

$dependencies_section

## Definition of Done
- [ ] Code implemented and committed
- [ ] Tests written and passing
- [ ] Documentation updated
- [ ] Acceptance test passes (if applicable)

$validation_section

## Resources
- [Architecture Doc](https://github.com/$REPO/blob/main/docs/architecture.md)
- [Implementation Plan](https://github.com/$REPO/blob/main/docs/implementation-plan/IMPLEMENTATION_HANDOFF.md)
"

    # Create the issue
    if [ "$DRY_RUN" = true ]; then
        echo -e "${YELLOW}[DRY RUN]${NC} Would create: #$issue_number - $title"
        echo "  Labels: $labels"
        echo "  Milestone: $milestone"
        echo ""
    else
        echo -e "${BLUE}Creating:${NC} #$issue_number - $title"

        # Try with milestone, fallback without if it fails
        gh issue create \
            --repo "$REPO" \
            --title "$title" \
            --body "$body" \
            --label "$labels" \
            --milestone "$milestone" 2>/dev/null || \
        gh issue create \
            --repo "$REPO" \
            --title "$title" \
            --body "$body" \
            --label "$labels"
    fi
}

# Function to generate issues from JSON file
generate_from_json() {
    local json_file=$1

    if [ ! -f "$json_file" ]; then
        echo -e "${RED}Error: JSON file not found: $json_file${NC}"
        return 1
    fi

    local epic_name=$(jq -r ".name" "$json_file")
    local epic_num=$(jq -r ".epic" "$json_file")
    local issue_count=$(jq -r ".issues | length" "$json_file")

    echo -e "${GREEN}=== Generating Epic $epic_num Issues ($epic_name) ===${NC}"
    echo "Total issues: $issue_count"
    echo ""

    # Create each issue
    for i in $(seq 0 $((issue_count - 1))); do
        create_issue_from_json "$json_file" "$i"

        # Small delay to avoid rate limiting
        if [ "$DRY_RUN" = false ]; then
            sleep 1
        fi
    done

    echo ""
    echo -e "${GREEN}Epic $epic_num: Created $issue_count issues${NC}"
}

# Main execution
if [ -z "$EPIC" ]; then
    echo "Generating all issues for all epics..."

    for epic_num in 1 2 3; do
        json_file="$DATA_DIR/epic${epic_num}.json"
        if [ -f "$json_file" ]; then
            generate_from_json "$json_file"
        else
            echo -e "${YELLOW}Warning: $json_file not found, skipping Epic $epic_num${NC}"
        fi
    done

    echo ""
    echo -e "${GREEN}=== Complete! ===${NC}"
else
    json_file="$DATA_DIR/epic${EPIC}.json"
    generate_from_json "$json_file"
fi

if [ "$DRY_RUN" = false ]; then
    echo ""
    echo -e "${GREEN}Issues created successfully!${NC}"
    echo "View them at: https://github.com/$REPO/issues"
else
    echo ""
    echo -e "${YELLOW}Dry run complete. No issues were created.${NC}"
    echo "Remove --dry-run flag to create issues."
fi
