#!/bin/bash
# =============================================================================
# Script: validate-at-e3-005.sh
# Purpose: Validate AT-E3-005 acceptance criteria for Journey Mapping
# Usage: ./scripts/validate-at-e3-005.sh
# Exit Codes: 0=success, 1=validation failed
# =============================================================================

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
VERBOSE=false
REPORT_FILE="reports/at-e3-005-validation-$(date +%Y%m%d-%H%M%S).json"
REPORT_DIR="reports"
JOURNEY_MAPS_DIR="docs/research/journey-maps"

# Test results
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
declare -a TEST_RESULTS=()

# =============================================================================
# Helper Functions
# =============================================================================

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Validate AT-E3-005 acceptance criteria for Journey Mapping.

OPTIONS:
    --verbose          Enable verbose output
    -h, --help         Show this help message

EXAMPLES:
    $0                           # Run validation
    $0 --verbose                 # Enable verbose output

ACCEPTANCE CRITERIA (AT-E3-005):
    ✓ 5 journey maps created
    ✓ Pain points identified
    ✓ Touchpoints mapped
    ✓ Opportunities documented
    ✓ Validated with users
    ✓ Success metrics defined

EOF
}

record_test_result() {
    local test_name=$1
    local status=$2
    local message=$3
    local details=${4:-""}

    TOTAL_TESTS=$((TOTAL_TESTS + 1))

    if [ "$status" = "PASS" ]; then
        PASSED_TESTS=$((PASSED_TESTS + 1))
        log_success "$test_name: $message"
    else
        FAILED_TESTS=$((FAILED_TESTS + 1))
        log_error "$test_name: $message"
    fi

    TEST_RESULTS+=("{\"test\":\"$test_name\",\"status\":\"$status\",\"message\":\"$message\",\"details\":\"$details\"}")
}

# =============================================================================
# Validation Tests
# =============================================================================

validate_directory_structure() {
    log_info "Validating journey maps directory structure..."

    if [ -d "$JOURNEY_MAPS_DIR" ]; then
        record_test_result "directory_exists" "PASS" "Journey maps directory exists"
    else
        record_test_result "directory_exists" "FAIL" "Journey maps directory not found at $JOURNEY_MAPS_DIR"
        return 1
    fi
}

validate_journey_maps_count() {
    log_info "Validating journey maps count (need 5)..."

    local journey_files=(
        "01-developer-onboarding.md"
        "02-deploying-first-app.md"
        "03-debugging-production-issue.md"
        "04-requesting-platform-feature.md"
        "05-contributing-to-platform.md"
    )

    local found_count=0
    for file in "${journey_files[@]}"; do
        if [ -f "$JOURNEY_MAPS_DIR/$file" ]; then
            found_count=$((found_count + 1))
            [ "$VERBOSE" = true ] && log_info "  Found: $file"
        else
            log_warning "  Missing: $file"
        fi
    done

    if [ $found_count -eq 5 ]; then
        record_test_result "journey_maps_count" "PASS" "All 5 journey maps exist ($found_count/5)"
    else
        record_test_result "journey_maps_count" "FAIL" "Only $found_count/5 journey maps found"
    fi
}

validate_summary_document() {
    log_info "Validating summary document..."

    local summary_file="$JOURNEY_MAPS_DIR/00-SUMMARY.md"

    if [ ! -f "$summary_file" ]; then
        record_test_result "summary_exists" "FAIL" "Summary document not found"
        return 1
    fi

    record_test_result "summary_exists" "PASS" "Summary document exists"

    # Check for required sections in summary
    local required_sections=(
        "Overview"
        "Key Findings"
        "Success Metrics"
        "Validation Summary"
    )

    local missing_sections=()
    for section in "${required_sections[@]}"; do
        if ! grep -q "$section" "$summary_file"; then
            missing_sections+=("$section")
        fi
    done

    if [ ${#missing_sections[@]} -eq 0 ]; then
        record_test_result "summary_sections" "PASS" "All required sections present in summary"
    else
        record_test_result "summary_sections" "FAIL" "Missing sections: ${missing_sections[*]}"
    fi
}

validate_pain_points() {
    log_info "Validating pain points identified in journey maps..."

    local pain_points_found=0
    local journey_files=(
        "01-developer-onboarding.md"
        "02-deploying-first-app.md"
        "03-debugging-production-issue.md"
        "04-requesting-platform-feature.md"
        "05-contributing-to-platform.md"
    )

    for file in "${journey_files[@]}"; do
        local filepath="$JOURNEY_MAPS_DIR/$file"
        if [ -f "$filepath" ]; then
            # Check for pain points section (case insensitive)
            if grep -iq "pain point\|frustration\|challenge" "$filepath"; then
                pain_points_found=$((pain_points_found + 1))
            fi
        fi
    done

    if [ $pain_points_found -ge 5 ]; then
        record_test_result "pain_points_identified" "PASS" "Pain points documented in $pain_points_found/5 journey maps"
    else
        record_test_result "pain_points_identified" "FAIL" "Pain points only found in $pain_points_found/5 journey maps"
    fi
}

validate_touchpoints() {
    log_info "Validating touchpoints mapped in journey maps..."

    local touchpoints_found=0
    local journey_files=(
        "01-developer-onboarding.md"
        "02-deploying-first-app.md"
        "03-debugging-production-issue.md"
        "04-requesting-platform-feature.md"
        "05-contributing-to-platform.md"
    )

    # Common touchpoints to look for
    local touchpoints=(
        "Backstage"
        "Jenkins"
        "ArgoCD"
        "Grafana"
        "Mattermost"
        "GitHub"
    )

    for file in "${journey_files[@]}"; do
        local filepath="$JOURNEY_MAPS_DIR/$file"
        if [ -f "$filepath" ]; then
            local found_touchpoint=false
            for touchpoint in "${touchpoints[@]}"; do
                if grep -iq "$touchpoint" "$filepath"; then
                    found_touchpoint=true
                    break
                fi
            done
            if $found_touchpoint; then
                touchpoints_found=$((touchpoints_found + 1))
            fi
        fi
    done

    if [ $touchpoints_found -ge 5 ]; then
        record_test_result "touchpoints_mapped" "PASS" "Platform touchpoints documented in $touchpoints_found/5 journey maps"
    else
        record_test_result "touchpoints_mapped" "FAIL" "Touchpoints only found in $touchpoints_found/5 journey maps"
    fi
}

validate_opportunities() {
    log_info "Validating improvement opportunities documented..."

    local opportunities_found=0
    local journey_files=(
        "01-developer-onboarding.md"
        "02-deploying-first-app.md"
        "03-debugging-production-issue.md"
        "04-requesting-platform-feature.md"
        "05-contributing-to-platform.md"
    )

    for file in "${journey_files[@]}"; do
        local filepath="$JOURNEY_MAPS_DIR/$file"
        if [ -f "$filepath" ]; then
            # Check for opportunities section
            if grep -iq "opportunit\|improvement\|recommendation\|quick win" "$filepath"; then
                opportunities_found=$((opportunities_found + 1))
            fi
        fi
    done

    if [ $opportunities_found -ge 5 ]; then
        record_test_result "opportunities_documented" "PASS" "Improvement opportunities in $opportunities_found/5 journey maps"
    else
        record_test_result "opportunities_documented" "FAIL" "Opportunities only found in $opportunities_found/5 journey maps"
    fi
}

validate_user_validation() {
    log_info "Validating user research and validation..."

    local summary_file="$JOURNEY_MAPS_DIR/00-SUMMARY.md"

    if [ -f "$summary_file" ]; then
        # Check for validation information
        if grep -iq "interview\|user\|participant\|validated" "$summary_file"; then
            record_test_result "user_validation" "PASS" "User validation documented in summary"
        else
            record_test_result "user_validation" "FAIL" "No evidence of user validation in summary"
        fi
    else
        record_test_result "user_validation" "FAIL" "Summary file not found for validation check"
    fi
}

validate_success_metrics() {
    log_info "Validating success metrics defined..."

    local summary_file="$JOURNEY_MAPS_DIR/00-SUMMARY.md"

    if [ -f "$summary_file" ]; then
        # Check for metrics section
        if grep -iq "metric\|measure\|target\|kpi" "$summary_file"; then
            record_test_result "success_metrics" "PASS" "Success metrics documented in summary"
        else
            record_test_result "success_metrics" "FAIL" "No success metrics found in summary"
        fi
    else
        record_test_result "success_metrics" "FAIL" "Summary file not found for metrics check"
    fi
}

validate_journey_map_template() {
    log_info "Validating journey map template exists..."

    local template_file="docs/research/templates/journey-map.md"

    if [ -f "$template_file" ]; then
        record_test_result "template_exists" "PASS" "Journey map template available"
    else
        record_test_result "template_exists" "FAIL" "Journey map template not found"
    fi
}

validate_readme() {
    log_info "Validating README documentation..."

    local readme_file="$JOURNEY_MAPS_DIR/README.md"

    if [ -f "$readme_file" ]; then
        record_test_result "readme_exists" "PASS" "Journey maps README exists"
    else
        log_warning "README.md not found in journey-maps directory (optional)"
        # This is optional, so we don't fail the test
    fi
}

# =============================================================================
# Report Generation
# =============================================================================

generate_report() {
    log_info "Generating validation report..."

    mkdir -p "$REPORT_DIR"

    cat > "$REPORT_FILE" <<EOF
{
  "test_id": "AT-E3-005",
  "test_name": "Journey Mapping Validation",
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "summary": {
    "total_tests": $TOTAL_TESTS,
    "passed": $PASSED_TESTS,
    "failed": $FAILED_TESTS,
    "pass_rate": $(awk "BEGIN {printf \"%.2f\", ($PASSED_TESTS/$TOTAL_TESTS)*100}")
  },
  "results": [
    $(IFS=,; echo "${TEST_RESULTS[*]}")
  ]
}
EOF

    log_info "Report saved to: $REPORT_FILE"
}

print_summary() {
    echo ""
    echo "=========================================="
    echo "AT-E3-005 Validation Summary"
    echo "=========================================="
    echo "Total Tests:  $TOTAL_TESTS"
    echo -e "Passed:       ${GREEN}$PASSED_TESTS${NC}"
    echo -e "Failed:       ${RED}$FAILED_TESTS${NC}"

    if [ $TOTAL_TESTS -gt 0 ]; then
        local pass_rate=$(awk "BEGIN {printf \"%.1f\", ($PASSED_TESTS/$TOTAL_TESTS)*100}")
        echo "Pass Rate:    ${pass_rate}%"
    fi

    echo "=========================================="

    if [ $FAILED_TESTS -eq 0 ]; then
        echo -e "${GREEN}✓ AT-E3-005 PASSED${NC}"
        echo "Journey Mapping validation successful!"
    else
        echo -e "${RED}✗ AT-E3-005 FAILED${NC}"
        echo "Please address the failed tests above."
    fi
    echo ""
}

# =============================================================================
# Main Execution
# =============================================================================

main() {
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --verbose)
                VERBOSE=true
                shift
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                usage
                exit 1
                ;;
        esac
    done

    echo ""
    echo "=========================================="
    echo "AT-E3-005: Journey Mapping Validation"
    echo "=========================================="
    echo ""

    # Run validation tests
    validate_directory_structure
    validate_journey_maps_count
    validate_summary_document
    validate_pain_points
    validate_touchpoints
    validate_opportunities
    validate_user_validation
    validate_success_metrics
    validate_journey_map_template
    validate_readme

    # Generate report
    generate_report

    # Print summary
    print_summary

    # Exit with appropriate code
    if [ $FAILED_TESTS -eq 0 ]; then
        exit 0
    else
        exit 1
    fi
}

main "$@"
