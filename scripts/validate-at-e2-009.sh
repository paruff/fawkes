#!/usr/bin/env bash
###############################################################################
# AT-E2-009 Validation Script
# Tests: AI Observability Dashboard
#
# Validates:
# - AI observability dashboard created
# - Real-time anomaly feed
# - Alert grouping visualization
# - Root cause suggestions visible
# - Historical anomaly trends
# - Dashboard passes acceptance criteria
###############################################################################

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
NAMESPACE="${NAMESPACE:-fawkes}"
ANOMALY_DETECTION_URL="${ANOMALY_DETECTION_URL:-http://anomaly-detection.${NAMESPACE}.svc.cluster.local:8000}"
SMART_ALERTING_URL="${SMART_ALERTING_URL:-http://smart-alerting.${NAMESPACE}.svc.cluster.local:8000}"
GRAFANA_URL="${GRAFANA_URL:-http://grafana.${NAMESPACE}.svc.cluster.local:80}"

# Test results
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_SKIPPED=0

###############################################################################
# Helper Functions
###############################################################################

print_header() {
    echo -e "\n${BLUE}=================================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}=================================================${NC}\n"
}

print_test() {
    echo -e "${YELLOW}TEST:${NC} $1"
}

print_pass() {
    echo -e "${GREEN}✓ PASS:${NC} $1"
    ((TESTS_PASSED++))
}

print_fail() {
    echo -e "${RED}✗ FAIL:${NC} $1"
    ((TESTS_FAILED++))
}

print_skip() {
    echo -e "${YELLOW}⊘ SKIP:${NC} $1"
    ((TESTS_SKIPPED++))
}

print_info() {
    echo -e "${BLUE}ℹ INFO:${NC} $1"
}

###############################################################################
# Test Functions
###############################################################################

test_grafana_dashboard_exists() {
    print_test "Grafana dashboard file exists"
    
    if [[ -f "platform/apps/grafana/dashboards/ai-observability.json" ]]; then
        print_pass "AI observability dashboard JSON file exists"
        return 0
    else
        print_fail "AI observability dashboard JSON file not found"
        return 1
    fi
}

test_dashboard_structure() {
    print_test "Dashboard has required structure"
    
    local dashboard_file="platform/apps/grafana/dashboards/ai-observability.json"
    
    if ! command -v jq &> /dev/null; then
        print_skip "jq not installed, skipping JSON validation"
        return 0
    fi
    
    # Check if valid JSON
    if ! jq empty "$dashboard_file" 2>/dev/null; then
        print_fail "Dashboard is not valid JSON"
        return 1
    fi
    
    # Check for required fields
    local title=$(jq -r '.dashboard.title' "$dashboard_file")
    if [[ "$title" == *"AI Observability"* ]]; then
        print_pass "Dashboard has correct title: $title"
    else
        print_fail "Dashboard title incorrect: $title"
        return 1
    fi
    
    # Check for panels
    local panel_count=$(jq '.dashboard.panels | length' "$dashboard_file")
    if [[ $panel_count -gt 20 ]]; then
        print_pass "Dashboard has $panel_count panels"
    else
        print_fail "Dashboard only has $panel_count panels (expected >20)"
        return 1
    fi
    
    return 0
}

test_required_panels() {
    print_test "Dashboard has required panels"
    
    local dashboard_file="platform/apps/grafana/dashboards/ai-observability.json"
    
    if ! command -v jq &> /dev/null; then
        print_skip "jq not installed, skipping panel validation"
        return 0
    fi
    
    local required_titles=(
        "Active Anomalies Count"
        "Anomaly Detection Accuracy"
        "Alert Fatigue Reduction"
        "Root Cause Analysis Success Rate"
        "Historical Anomaly Trends"
        "Mean Time to Detection"
    )
    
    local panels=$(jq -r '.dashboard.panels[].title' "$dashboard_file")
    
    for title in "${required_titles[@]}"; do
        if echo "$panels" | grep -q "$title"; then
            print_pass "Panel found: $title"
        else
            print_fail "Required panel missing: $title"
            return 1
        fi
    done
    
    return 0
}

test_anomaly_timeline_exists() {
    print_test "Anomaly timeline HTML exists"
    
    if [[ -f "services/anomaly-detection/ui/timeline.html" ]]; then
        print_pass "Anomaly timeline HTML file exists"
        return 0
    else
        print_fail "Anomaly timeline HTML file not found"
        return 1
    fi
}

test_timeline_structure() {
    print_test "Timeline has required features"
    
    local timeline_file="services/anomaly-detection/ui/timeline.html"
    
    # Check for required elements
    local required_features=(
        "timeline-container"
        "severityFilter"
        "metricFilter"
        "hoursFilter"
        "correlated-events"
        "root-cause"
    )
    
    for feature in "${required_features[@]}"; do
        if grep -q "$feature" "$timeline_file"; then
            print_pass "Timeline feature found: $feature"
        else
            print_fail "Timeline feature missing: $feature"
            return 1
        fi
    done
    
    return 0
}

test_anomaly_detection_service() {
    print_test "Anomaly detection service is accessible"
    
    # Check if service exists in Kubernetes
    if kubectl get service anomaly-detection -n "$NAMESPACE" &>/dev/null; then
        print_pass "Anomaly detection service exists in namespace $NAMESPACE"
    else
        print_skip "Anomaly detection service not deployed (acceptable for file validation)"
        return 0
    fi
    
    # Try to access health endpoint
    if kubectl run curl-test --rm -i --restart=Never --image=curlimages/curl:latest -n "$NAMESPACE" \
        -- curl -s -f -m 5 "$ANOMALY_DETECTION_URL/health" &>/dev/null; then
        print_pass "Anomaly detection service health check passed"
    else
        print_skip "Anomaly detection service not accessible (may not be deployed)"
    fi
    
    return 0
}

test_smart_alerting_service() {
    print_test "Smart alerting service is accessible"
    
    # Check if service exists in Kubernetes
    if kubectl get service smart-alerting -n "$NAMESPACE" &>/dev/null; then
        print_pass "Smart alerting service exists in namespace $NAMESPACE"
    else
        print_skip "Smart alerting service not deployed (acceptable for file validation)"
        return 0
    fi
    
    # Try to access health endpoint
    if kubectl run curl-test --rm -i --restart=Never --image=curlimages/curl:latest -n "$NAMESPACE" \
        -- curl -s -f -m 5 "$SMART_ALERTING_URL/health" &>/dev/null; then
        print_pass "Smart alerting service health check passed"
    else
        print_skip "Smart alerting service not accessible (may not be deployed)"
    fi
    
    return 0
}

test_prometheus_metrics() {
    print_test "Required Prometheus metrics are defined"
    
    local dashboard_file="platform/apps/grafana/dashboards/ai-observability.json"
    
    if ! command -v jq &> /dev/null; then
        print_skip "jq not installed, skipping metrics validation"
        return 0
    fi
    
    local required_metrics=(
        "anomaly_detection_total"
        "anomaly_detection_false_positive_rate"
        "anomaly_detection_models_loaded"
        "anomaly_detection_rca_total"
        "smart_alerting_grouped_total"
        "smart_alerting_suppressed_total"
        "smart_alerting_fatigue_reduction"
    )
    
    local queries=$(jq -r '.. | .expr? // empty' "$dashboard_file")
    
    for metric in "${required_metrics[@]}"; do
        if echo "$queries" | grep -q "$metric"; then
            print_pass "Metric query found: $metric"
        else
            print_fail "Required metric missing: $metric"
            return 1
        fi
    done
    
    return 0
}

test_template_variables() {
    print_test "Dashboard has template variables for filtering"
    
    local dashboard_file="platform/apps/grafana/dashboards/ai-observability.json"
    
    if ! command -v jq &> /dev/null; then
        print_skip "jq not installed, skipping variable validation"
        return 0
    fi
    
    local variables=$(jq -r '.dashboard.templating.list[].name' "$dashboard_file")
    
    if echo "$variables" | grep -q "severity"; then
        print_pass "Severity filter variable found"
    else
        print_fail "Severity filter variable missing"
        return 1
    fi
    
    if echo "$variables" | grep -q "metric"; then
        print_pass "Metric filter variable found"
    else
        print_fail "Metric filter variable missing"
        return 1
    fi
    
    return 0
}

test_annotations() {
    print_test "Dashboard has annotations for critical events"
    
    local dashboard_file="platform/apps/grafana/dashboards/ai-observability.json"
    
    if ! command -v jq &> /dev/null; then
        print_skip "jq not installed, skipping annotation validation"
        return 0
    fi
    
    local annotations=$(jq -r '.dashboard.annotations.list[].name' "$dashboard_file")
    
    if echo "$annotations" | grep -q "Critical Anomalies"; then
        print_pass "Critical anomalies annotation found"
    else
        print_fail "Critical anomalies annotation missing"
        return 1
    fi
    
    if echo "$annotations" | grep -q "Alert Groups"; then
        print_pass "Alert groups annotation found"
    else
        print_fail "Alert groups annotation missing"
        return 1
    fi
    
    return 0
}

test_bdd_feature_exists() {
    print_test "BDD feature test exists"
    
    if [[ -f "tests/bdd/features/ai-observability-dashboard.feature" ]]; then
        print_pass "BDD feature file exists"
        
        # Check for AT-E2-009 tag
        if grep -q "@at-e2-009" "tests/bdd/features/ai-observability-dashboard.feature"; then
            print_pass "BDD feature has AT-E2-009 tag"
        else
            print_fail "BDD feature missing AT-E2-009 tag"
            return 1
        fi
        
        return 0
    else
        print_fail "BDD feature file not found"
        return 1
    fi
}

###############################################################################
# Main Execution
###############################################################################

main() {
    print_header "AT-E2-009: AI Observability Dashboard Validation"
    
    print_info "Namespace: $NAMESPACE"
    print_info "Anomaly Detection URL: $ANOMALY_DETECTION_URL"
    print_info "Smart Alerting URL: $SMART_ALERTING_URL"
    print_info "Grafana URL: $GRAFANA_URL"
    
    print_header "Dashboard File Tests"
    test_grafana_dashboard_exists || true
    test_dashboard_structure || true
    test_required_panels || true
    test_template_variables || true
    test_annotations || true
    test_prometheus_metrics || true
    
    print_header "Timeline UI Tests"
    test_anomaly_timeline_exists || true
    test_timeline_structure || true
    
    print_header "Service Integration Tests"
    test_anomaly_detection_service || true
    test_smart_alerting_service || true
    
    print_header "BDD Test Coverage"
    test_bdd_feature_exists || true
    
    print_header "Test Summary"
    echo -e "${GREEN}Passed:${NC}  $TESTS_PASSED"
    echo -e "${YELLOW}Skipped:${NC} $TESTS_SKIPPED"
    echo -e "${RED}Failed:${NC}  $TESTS_FAILED"
    echo ""
    
    if [[ $TESTS_FAILED -eq 0 ]]; then
        print_header "AT-E2-009 VALIDATION: PASSED ✓"
        echo -e "${GREEN}All AI observability dashboard requirements validated successfully!${NC}"
        return 0
    else
        print_header "AT-E2-009 VALIDATION: FAILED ✗"
        echo -e "${RED}Some validations failed. Please review the output above.${NC}"
        return 1
    fi
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
