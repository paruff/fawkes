#!/bin/bash
# =============================================================================
# Script: validate-at-e2-010.sh
# Purpose: Validate AT-E2-010 acceptance criteria for Feedback Analytics Dashboard
# Usage: ./scripts/validate-at-e2-010.sh [--namespace NAMESPACE]
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
NAMESPACE="${NAMESPACE:-fawkes}"
FEEDBACK_SERVICE_URL="${FEEDBACK_SERVICE_URL:-http://feedback-service.${NAMESPACE}.svc.cluster.local:8000}"
GRAFANA_URL="${GRAFANA_URL:-http://grafana.${NAMESPACE}.svc.cluster.local:3000}"
VERBOSE=false
REPORT_FILE="reports/at-e2-010-validation-$(date +%Y%m%d-%H%M%S).json"
REPORT_DIR="reports"

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

Validate AT-E2-010 acceptance criteria for Feedback Analytics Dashboard.

OPTIONS:
    --namespace NAME    Kubernetes namespace (default: fawkes)
    --verbose          Enable verbose output
    -h, --help         Show this help message

EXAMPLES:
    $0                           # Use default namespace
    $0 --namespace fawkes        # Specify namespace
    $0 --verbose                 # Enable verbose output

ACCEPTANCE CRITERIA (AT-E2-010):
    ✓ Feedback analytics dashboard created
    ✓ NPS trends visible
    ✓ Feedback categorization shown
    ✓ Sentiment analysis working
    ✓ Top issues highlighted
    ✓ Metrics exported to Prometheus
    ✓ Time-to-action metrics tracked

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

# AC1: Feedback analytics dashboard created
validate_dashboard_exists() {
    log_info "Validating feedback analytics dashboard exists..."
    
    local dashboard_file="platform/apps/grafana/dashboards/feedback-analytics.json"
    
    if [ ! -f "$dashboard_file" ]; then
        record_test_result "AC1_DASHBOARD_FILE_EXISTS" "FAIL" "Dashboard file not found"
        return 1
    fi
    
    record_test_result "AC1_DASHBOARD_FILE_EXISTS" "PASS" "Dashboard file exists"
    
    # Validate dashboard structure
    if ! jq empty "$dashboard_file" 2>/dev/null; then
        record_test_result "AC1_DASHBOARD_VALID_JSON" "FAIL" "Dashboard JSON is invalid"
        return 1
    fi
    
    record_test_result "AC1_DASHBOARD_VALID_JSON" "PASS" "Dashboard JSON is valid"
    
    # Check for required dashboard properties
    local has_title=$(jq -r '.dashboard.title' "$dashboard_file")
    if [ "$has_title" = "Feedback Analytics" ]; then
        record_test_result "AC1_DASHBOARD_TITLE" "PASS" "Dashboard has correct title"
    else
        record_test_result "AC1_DASHBOARD_TITLE" "FAIL" "Dashboard title incorrect or missing"
        return 1
    fi
    
    # Check for panels
    local panel_count=$(jq '.dashboard.panels | length' "$dashboard_file")
    if [ "$panel_count" -gt 10 ]; then
        record_test_result "AC1_DASHBOARD_PANELS" "PASS" "Dashboard has $panel_count panels"
    else
        record_test_result "AC1_DASHBOARD_PANELS" "FAIL" "Dashboard has insufficient panels ($panel_count)"
        return 1
    fi
    
    return 0
}

# AC2: NPS trends visible
validate_nps_metrics() {
    log_info "Validating NPS metrics in dashboard..."
    
    local dashboard_file="platform/apps/grafana/dashboards/feedback-analytics.json"
    
    # Check for NPS score panel
    if jq -e '.dashboard.panels[] | select(.title | contains("NPS Score"))' "$dashboard_file" > /dev/null 2>&1; then
        record_test_result "AC2_NPS_SCORE_PANEL" "PASS" "NPS score panel exists"
    else
        record_test_result "AC2_NPS_SCORE_PANEL" "FAIL" "NPS score panel not found"
        return 1
    fi
    
    # Check for NPS trend panel
    if jq -e '.dashboard.panels[] | select((.title | contains("NPS")) and (.title | contains("Trend")))' "$dashboard_file" > /dev/null 2>&1; then
        record_test_result "AC2_NPS_TREND_PANEL" "PASS" "NPS trend panel exists"
    else
        record_test_result "AC2_NPS_TREND_PANEL" "FAIL" "NPS trend panel not found"
        return 1
    fi
    
    # Check for NPS components panel
    if jq -e '.dashboard.panels[] | select(.title | contains("NPS Components"))' "$dashboard_file" > /dev/null 2>&1; then
        record_test_result "AC2_NPS_COMPONENTS_PANEL" "PASS" "NPS components panel exists"
    else
        record_test_result "AC2_NPS_COMPONENTS_PANEL" "FAIL" "NPS components panel not found"
        return 1
    fi
    
    return 0
}

# AC3: Feedback categorization shown
validate_categorization() {
    log_info "Validating feedback categorization in dashboard..."
    
    local dashboard_file="platform/apps/grafana/dashboards/feedback-analytics.json"
    
    # Check for category panel
    if jq -e '.dashboard.panels[] | select(.title | test("[Cc]ategor"))' "$dashboard_file" > /dev/null 2>&1; then
        record_test_result "AC3_CATEGORY_PANEL" "PASS" "Category panel exists"
    else
        record_test_result "AC3_CATEGORY_PANEL" "FAIL" "Category panel not found"
        return 1
    fi
    
    # Check for rating distribution
    if jq -e '.dashboard.panels[] | select(.title | contains("Rating Distribution"))' "$dashboard_file" > /dev/null 2>&1; then
        record_test_result "AC3_RATING_DISTRIBUTION" "PASS" "Rating distribution panel exists"
    else
        record_test_result "AC3_RATING_DISTRIBUTION" "FAIL" "Rating distribution panel not found"
        return 1
    fi
    
    return 0
}

# AC4: Sentiment analysis working
validate_sentiment_analysis() {
    log_info "Validating sentiment analysis implementation..."
    
    # Check sentiment.py module exists
    local sentiment_file="services/feedback/app/sentiment.py"
    if [ ! -f "$sentiment_file" ]; then
        record_test_result "AC4_SENTIMENT_MODULE" "FAIL" "Sentiment module not found"
        return 1
    fi
    
    record_test_result "AC4_SENTIMENT_MODULE" "PASS" "Sentiment module exists"
    
    # Check for VADER dependency
    local req_file="services/feedback/requirements.txt"
    if grep -q "vaderSentiment" "$req_file"; then
        record_test_result "AC4_VADER_DEPENDENCY" "PASS" "VADER dependency specified"
    else
        record_test_result "AC4_VADER_DEPENDENCY" "FAIL" "VADER dependency not found"
        return 1
    fi
    
    # Check sentiment in database schema
    local main_file="services/feedback/app/main.py"
    if grep -q "sentiment" "$main_file"; then
        record_test_result "AC4_SENTIMENT_SCHEMA" "PASS" "Sentiment fields in schema"
    else
        record_test_result "AC4_SENTIMENT_SCHEMA" "FAIL" "Sentiment fields not in schema"
        return 1
    fi
    
    # Check sentiment panels in dashboard
    local dashboard_file="platform/apps/grafana/dashboards/feedback-analytics.json"
    if jq -e '.dashboard.panels[] | select(.title | contains("Sentiment"))' "$dashboard_file" > /dev/null 2>&1; then
        record_test_result "AC4_SENTIMENT_DASHBOARD" "PASS" "Sentiment panels in dashboard"
    else
        record_test_result "AC4_SENTIMENT_DASHBOARD" "FAIL" "Sentiment panels not found"
        return 1
    fi
    
    return 0
}

# AC5: Top issues highlighted
validate_top_issues() {
    log_info "Validating top issues tracking..."
    
    local dashboard_file="platform/apps/grafana/dashboards/feedback-analytics.json"
    
    # Check for top issues/categories panel
    if jq -e '.dashboard.panels[] | select(.title | contains("Top"))' "$dashboard_file" > /dev/null 2>&1; then
        record_test_result "AC5_TOP_ISSUES_PANEL" "PASS" "Top issues panel exists"
    else
        record_test_result "AC5_TOP_ISSUES_PANEL" "FAIL" "Top issues panel not found"
        return 1
    fi
    
    # Check for low-rated feedback tracking
    if jq -e '.dashboard.panels[] | select(.title | test("[Ll]ow"))' "$dashboard_file" > /dev/null 2>&1; then
        record_test_result "AC5_LOW_RATED_PANEL" "PASS" "Low-rated feedback panel exists"
    else
        record_test_result "AC5_LOW_RATED_PANEL" "FAIL" "Low-rated feedback panel not found"
        return 1
    fi
    
    return 0
}

# AC6: Metrics exported to Prometheus
validate_prometheus_metrics() {
    log_info "Validating Prometheus metrics export..."
    
    # Check metrics module exists
    local metrics_file="services/feedback/app/metrics.py"
    if [ ! -f "$metrics_file" ]; then
        record_test_result "AC6_METRICS_MODULE" "FAIL" "Metrics module not found"
        return 1
    fi
    
    record_test_result "AC6_METRICS_MODULE" "PASS" "Metrics module exists"
    
    # Check for required metrics
    local required_metrics=(
        "nps_score"
        "nps_promoters_percentage"
        "nps_detractors_percentage"
        "feedback_response_rate"
        "feedback_submissions_total"
        "feedback_sentiment_score"
    )
    
    local missing_metrics=0
    for metric in "${required_metrics[@]}"; do
        if ! grep -q "$metric" "$metrics_file"; then
            log_warning "Missing metric: $metric"
            missing_metrics=$((missing_metrics + 1))
        fi
    done
    
    if [ $missing_metrics -eq 0 ]; then
        record_test_result "AC6_METRICS_COMPLETE" "PASS" "All required metrics defined"
    else
        record_test_result "AC6_METRICS_COMPLETE" "FAIL" "Missing $missing_metrics metrics"
        return 1
    fi
    
    # Check metrics integration in main.py
    local main_file="services/feedback/app/main.py"
    if grep -q "from .metrics import" "$main_file"; then
        record_test_result "AC6_METRICS_INTEGRATED" "PASS" "Metrics integrated in main app"
    else
        record_test_result "AC6_METRICS_INTEGRATED" "FAIL" "Metrics not integrated"
        return 1
    fi
    
    return 0
}

# AC7: Time-to-action metrics
validate_time_to_action_metrics() {
    log_info "Validating time-to-action metrics..."
    
    # Check for status_changed_at field in schema
    local main_file="services/feedback/app/main.py"
    if grep -q "status_changed_at" "$main_file"; then
        record_test_result "AC7_STATUS_CHANGED_AT_FIELD" "PASS" "status_changed_at field in schema"
    else
        record_test_result "AC7_STATUS_CHANGED_AT_FIELD" "FAIL" "status_changed_at field not found"
        return 1
    fi
    
    # Check for time-to-action metrics in metrics.py
    local metrics_file="services/feedback/app/metrics.py"
    if grep -q "feedback_time_to_action_seconds" "$metrics_file"; then
        record_test_result "AC7_TIME_TO_ACTION_HISTOGRAM" "PASS" "Time-to-action histogram metric exists"
    else
        record_test_result "AC7_TIME_TO_ACTION_HISTOGRAM" "FAIL" "Time-to-action histogram metric not found"
        return 1
    fi
    
    if grep -q "feedback_avg_time_to_action_hours" "$metrics_file"; then
        record_test_result "AC7_AVG_TIME_TO_ACTION_GAUGE" "PASS" "Average time-to-action gauge metric exists"
    else
        record_test_result "AC7_AVG_TIME_TO_ACTION_GAUGE" "FAIL" "Average time-to-action gauge metric not found"
        return 1
    fi
    
    # Check for update_time_to_action_metrics function
    if grep -q "update_time_to_action_metrics" "$metrics_file"; then
        record_test_result "AC7_UPDATE_FUNCTION" "PASS" "Time-to-action update function exists"
    else
        record_test_result "AC7_UPDATE_FUNCTION" "FAIL" "Time-to-action update function not found"
        return 1
    fi
    
    # Check for time-to-action panels in dashboard
    local dashboard_file="platform/apps/grafana/dashboards/feedback-analytics.json"
    if jq -e '.dashboard.panels[] | select(.title | contains("Time-to-Action") or contains("Time to"))' "$dashboard_file" > /dev/null 2>&1; then
        record_test_result "AC7_DASHBOARD_PANELS" "PASS" "Time-to-action panels in dashboard"
    else
        record_test_result "AC7_DASHBOARD_PANELS" "FAIL" "Time-to-action panels not found"
        return 1
    fi
    
    return 0
}

# =============================================================================
# Report Generation
# =============================================================================

generate_report() {
    log_info "Generating validation report..."
    
    mkdir -p "$REPORT_DIR"
    
    cat > "$REPORT_FILE" << EOF
{
  "test_suite": "AT-E2-010 Feedback Analytics Dashboard Validation",
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "namespace": "$NAMESPACE",
  "summary": {
    "total_tests": $TOTAL_TESTS,
    "passed": $PASSED_TESTS,
    "failed": $FAILED_TESTS,
    "success_rate": $(echo "scale=2; ($PASSED_TESTS / $TOTAL_TESTS) * 100" | bc)
  },
  "tests": [
    $(IFS=,; echo "${TEST_RESULTS[*]}")
  ]
}
EOF
    
    log_success "Report saved to $REPORT_FILE"
}

# =============================================================================
# Main Execution
# =============================================================================

main() {
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --namespace)
                NAMESPACE="$2"
                shift 2
                ;;
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
    
    log_info "Starting AT-E2-010 validation..."
    log_info "Namespace: $NAMESPACE"
    echo ""
    
    # Run validation tests
    validate_dashboard_exists
    validate_nps_metrics
    validate_categorization
    validate_sentiment_analysis
    validate_top_issues
    validate_prometheus_metrics
    validate_time_to_action_metrics
    
    echo ""
    log_info "==================================================================="
    log_info "Validation Summary"
    log_info "==================================================================="
    log_info "Total Tests: $TOTAL_TESTS"
    log_success "Passed: $PASSED_TESTS"
    
    if [ $FAILED_TESTS -gt 0 ]; then
        log_error "Failed: $FAILED_TESTS"
    else
        log_info "Failed: $FAILED_TESTS"
    fi
    
    # Generate report
    generate_report
    
    # Exit with appropriate code
    if [ $FAILED_TESTS -eq 0 ]; then
        log_success "✅ AT-E2-010 validation PASSED"
        exit 0
    else
        log_error "❌ AT-E2-010 validation FAILED"
        exit 1
    fi
}

# Run main function
main "$@"
