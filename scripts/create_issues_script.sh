#!/usr/bin/env bash
#
# create-issues-from-json.sh
# Creates GitHub issues from Epic JSON files for Fawkes platform
#
# Usage:
#   ./scripts/create-issues-from-json.sh --epic 1
#   ./scripts/create-issues-from-json.sh --epic 1 --dry-run
#   ./scripts/create-issues-from-json.sh --epic 1 --start 1 --end 10
#

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
REPO="${GITHUB_REPO:-paruff/fawkes}"
DATA_DIR="data"
DRY_RUN=false
EPIC=""
START_ISSUE=""
END_ISSUE=""

# Logging functions
log_info() { echo -e "${BLUE}ℹ${NC} $*"; }
log_success() { echo -e "${GREEN}✓${NC} $*"; }
log_error() { echo -e "${RED}✗${NC} $*"; }
log_warn() { echo -e "${YELLOW}⚠${NC} $*"; }

# Usage
usage() {
    cat <<EOF
Create GitHub issues from Epic JSON files

Usage:
    $0 --epic <number> [options]

Options:
    --epic <N>          Epic number (1, 2, or 3)
    --dry-run           Show what would be created without creating
    --start <N>         Start from issue number N
    --end <N>           End at issue number N
    --repo <repo>       GitHub repository (default: $REPO)
    --help              Show this help

Examples:
    # Create all Epic 1 issues
    $0 --epic 1

    # Dry run to preview
    $0 --epic 1 --dry-run

    # Create issues 1-10 only
    $0 --epic 1 --start 1 --end 10

    # Use different repo
    $0 --epic 1 --repo myorg/myrepo

EOF
    exit 0
}

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
        --start)
            START_ISSUE="$2"
            shift 2
            ;;
        --end)
            END_ISSUE="$2"
            shift 2
            ;;
        --repo)
            REPO="$2"
            shift 2
            ;;
        --help|-h)
            usage
            ;;
        *)
            log_error "Unknown option: $1"
            usage
            ;;
    esac
done

# Validate epic number
if [[ -z "$EPIC" ]]; then
    log_error "Epic number required"
    usage
fi

if [[ ! "$EPIC" =~ ^[1-3]$ ]]; then
    log_error "Epic must be 1, 2, or 3"
    exit 1
fi

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    if ! command -v gh &> /dev/null; then
        log_error "GitHub CLI (gh) not found. Install: https://cli.github.com/"
        exit 1
    fi
    
    if ! command -v jq &> /dev/null; then
        log_error "jq not found. Install: https://stedolan.github.io/jq/"
        exit 1
    fi
    
    if ! gh auth status &> /dev/null; then
        log_error "GitHub CLI not authenticated. Run: gh auth login"
        exit 1
    fi
    
    log_success "Prerequisites OK"
}

# Load JSON file
load_json() {
    local json_file="${DATA_DIR}/epic${EPIC}-issues.json"
    
    if [[ ! -f "$json_file" ]]; then
        log_error "JSON file not found: $json_file"
        exit 1
    fi
    
    if ! jq empty "$json_file" 2>/dev/null; then
        log_error "Invalid JSON in $json_file"
        exit 1
    fi
    
    log_success "Loaded $json_file"
    echo "$json_file"
}

# Get issue range
get_issue_range() {
    local json_file=$1
    local total_issues
    
    total_issues=$(jq '.issues | length' "$json_file")
    
    START_ISSUE="${START_ISSUE:-1}"
    END_ISSUE="${END_ISSUE:-$total_issues}"
    
    if [[ $START_ISSUE -lt 1 ]] || [[ $START_ISSUE -gt $total_issues ]]; then
        log_error "Start issue out of range (1-$total_issues)"
        exit 1
    fi
    
    if [[ $END_ISSUE -lt $START_ISSUE ]] || [[ $END_ISSUE -gt $total_issues ]]; then
        log_error "End issue out of range ($START_ISSUE-$total_issues)"
        exit 1
    fi
    
    log_info "Creating issues $START_ISSUE to $END_ISSUE (of $total_issues)"
}

# Format issue body
format_issue_body() {
    local json_file=$1
    local index=$2
    
    local description
    local acceptance_criteria
    local dependencies
    local blocks
    local definition_of_done
    local resources
    
    description=$(jq -r ".issues[$index].description" "$json_file")
    
    # Build body
    cat <<EOF
$description

## 🎯 Acceptance Criteria

EOF
    
    jq -r ".issues[$index].acceptance_criteria[]" "$json_file" | while read -r criterion; do
        echo "- [ ] $criterion"
    done
    
    echo ""
    
    # Add dependencies if present
    if jq -e ".issues[$index].dependencies" "$json_file" > /dev/null 2>&1; then
        dependencies=$(jq -r ".issues[$index].dependencies[]?" "$json_file" | tr '\n' ' ')
        if [[ -n "$dependencies" ]]; then
            echo "## 📋 Dependencies"
            echo ""
            echo "**Depends on**: $dependencies"
            echo ""
        fi
    fi
    
    # Add blocks if present
    if jq -e ".issues[$index].blocks" "$json_file" > /dev/null 2>&1; then
        blocks=$(jq -r ".issues[$index].blocks[]?" "$json_file" | tr '\n' ' ')
        if [[ -n "$blocks" ]]; then
            echo "**Blocks**: $blocks"
            echo ""
        fi
    fi
    
    # Add definition of done if present
    if jq -e ".issues[$index].definition_of_done" "$json_file" > /dev/null 2>&1; then
        echo "## ✅ Definition of Done"
        echo ""
        jq -r ".issues[$index].definition_of_done[]?" "$json_file" | while read -r item; do
            echo "- [ ] $item"
        done
        echo ""
    fi
    
    # Add resources if present
    if jq -e ".issues[$index].resources" "$json_file" > /dev/null 2>&1; then
        echo "## 📚 Resources"
        echo ""
        jq -r ".issues[$index].resources[]?" "$json_file" | while read -r resource; do
            echo "- $resource"
        done
        echo ""
    fi
    
    # Add metadata
    local priority estimated_hours
    priority=$(jq -r ".issues[$index].priority" "$json_file")
    estimated_hours=$(jq -r ".issues[$index].estimated_hours" "$json_file")
    
    echo "---"
    echo ""
    echo "**Priority**: $priority | **Estimated**: ${estimated_hours}h | **Epic**: $EPIC"
}

# Create single issue
create_issue() {
    local json_file=$1
    local index=$2
    
    local issue_number title milestone labels body
    
    issue_number=$(jq -r ".issues[$index].number" "$json_file")
    title=$(jq -r ".issues[$index].title" "$json_file")
    milestone=$(jq -r ".issues[$index].milestone" "$json_file")
    labels=$(jq -r ".issues[$index].labels | join(\",\")" "$json_file")
    
    body=$(format_issue_body "$json_file" "$index")
    
    if [[ "$DRY_RUN" == true ]]; then
        log_info "Would create issue #$issue_number: $title"
        echo "  Milestone: $milestone"
        echo "  Labels: $labels"
        echo ""
        return 0
    fi
    
    log_info "Creating issue #$issue_number: $title"
    
    # Create issue with gh CLI
    local issue_url
    issue_url=$(gh issue create \
        --repo "$REPO" \
        --title "$title" \
        --body "$body" \
        --label "$labels" \
        --milestone "$milestone" 2>&1)
    
    if [[ $? -eq 0 ]]; then
        log_success "Created $issue_url"
    else
        log_error "Failed to create issue #$issue_number"
        log_error "$issue_url"
        return 1
    fi
}

# Create milestones if needed
create_milestones() {
    local json_file=$1
    
    log_info "Checking milestones..."
    
    local milestones
    milestones=$(jq -r '.issues[].milestone' "$json_file" | sort -u)
    
    while read -r milestone; do
        if ! gh milestone list --repo "$REPO" | grep -q "$milestone"; then
            if [[ "$DRY_RUN" == true ]]; then
                log_info "Would create milestone: $milestone"
            else
                log_info "Creating milestone: $milestone"
                gh milestone create "$milestone" --repo "$REPO" || true
            fi
        fi
    done <<< "$milestones"
}

# Main function
main() {
    log_info "=== Fawkes Issue Creator ==="
    log_info "Epic: $EPIC"
    log_info "Repository: $REPO"
    
    if [[ "$DRY_RUN" == true ]]; then
        log_warn "DRY RUN MODE - No issues will be created"
    fi
    
    echo ""
    
    check_prerequisites
    
    local json_file
    json_file=$(load_json)
    
    get_issue_range "$json_file"
    
    create_milestones "$json_file"
    
    echo ""
    log_info "Creating issues..."
    echo ""
    
    local created=0
    local failed=0
    
    for ((i=START_ISSUE-1; i<END_ISSUE; i++)); do
        if create_issue "$json_file" "$i"; then
            ((created++))
        else
            ((failed++))
        fi
        
        # Rate limiting
        if [[ "$DRY_RUN" == false ]]; then
            sleep 1
        fi
    done
    
    echo ""
    log_info "=== Summary ==="
    log_success "Created: $created"
    
    if [[ $failed -gt 0 ]]; then
        log_error "Failed: $failed"
    fi
    
    if [[ "$DRY_RUN" == true ]]; then
        log_warn "DRY RUN - No issues were actually created"
        log_info "Remove --dry-run to create issues for real"
    else
        log_success "Epic $EPIC issues created successfully!"
        log_info "View at: https://github.com/$REPO/issues"
    fi
}

main "$@"
