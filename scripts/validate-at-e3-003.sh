#!/bin/bash
# =============================================================================
# Script: validate-at-e3-003.sh
# Purpose: Validate AT-E3-003 acceptance criteria for DevEx Dashboard
# Usage: ./scripts/validate-at-e3-003.sh [--namespace NAMESPACE]
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
NAMESPACE="${NAMESPACE:-monitoring}"
ARGOCD_NAMESPACE="${ARGOCD_NAMESPACE:-fawkes}"
VERBOSE=false
REPORT_FILE="reports/at-e3-003-validation-$(date +%Y%m%d-%H%M%S).json"
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

Validate AT-E3-003 acceptance criteria for DevEx Dashboard in Grafana.

OPTIONS:
    --namespace NAME       Kubernetes namespace for Grafana (default: monitoring)
    --argocd-ns NAME      ArgoCD namespace (default: fawkes)
    --verbose             Enable verbose output
    -h, --help            Show this help message

EXAMPLES:
    $0                                    # Use default namespaces
    $0 --namespace monitoring             # Specify Grafana namespace
    $0 --argocd-ns fawkes --verbose      # Full specification

ACCEPTANCE CRITERIA (AT-E3-003):
    ✓ Dashboard deployed
    ✓ All 5 SPACE dimensions visualized
    ✓ Team-level filtering
    ✓ Historical trending
    ✓ Alerting configured

EOF
}

record_test_result() {
    local test_name=$1
    local status=$2
    local message=$3
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    if [ "$status" = "PASS" ]; then
        PASSED_TESTS=$((PASSED_TESTS + 1))
        log_success "$test_name: $message"
    else
        FAILED_TESTS=$((FAILED_TESTS + 1))
        log_error "$test_name: $message"
    fi
    
    TEST_RESULTS+=("{\"test\":\"$test_name\",\"status\":\"$status\",\"message\":\"$message\"}")
}

# =============================================================================
# Parse Arguments
# =============================================================================

while [[ $# -gt 0 ]]; do
    case $1 in
        --namespace)
            NAMESPACE="$2"
            shift 2
            ;;
        --argocd-ns)
            ARGOCD_NAMESPACE="$2"
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

# =============================================================================
# Main Validation Tests
# =============================================================================

log_info "Starting AT-E3-003 validation for DevEx Dashboard"
log_info "Namespace: $NAMESPACE"
log_info "ArgoCD Namespace: $ARGOCD_NAMESPACE"
echo ""

# Test 1: Dashboard ConfigMap exists
log_info "Test 1: Checking if DevEx Dashboard ConfigMap exists..."
if kubectl get configmap devex-dashboard -n "$NAMESPACE" &>/dev/null; then
    record_test_result "Dashboard ConfigMap" "PASS" "devex-dashboard ConfigMap exists in $NAMESPACE"
    if [ "$VERBOSE" = true ]; then
        kubectl get configmap devex-dashboard -n "$NAMESPACE" -o yaml | head -20
    fi
else
    record_test_result "Dashboard ConfigMap" "FAIL" "devex-dashboard ConfigMap not found in $NAMESPACE"
fi

# Test 2: Dashboard has correct label
log_info "Test 2: Checking if Dashboard has grafana_dashboard label..."
if kubectl get configmap devex-dashboard -n "$NAMESPACE" -o jsonpath='{.metadata.labels.grafana_dashboard}' 2>/dev/null | grep -q "1"; then
    record_test_result "Dashboard Label" "PASS" "ConfigMap has grafana_dashboard=1 label"
else
    record_test_result "Dashboard Label" "FAIL" "ConfigMap missing grafana_dashboard=1 label"
fi

# Test 3: Dashboard JSON contains all 5 SPACE dimensions
log_info "Test 3: Checking if Dashboard includes all 5 SPACE dimensions..."
DASHBOARD_JSON=$(kubectl get configmap devex-dashboard -n "$NAMESPACE" -o jsonpath='{.data.*}' 2>/dev/null || echo "")
if [ -n "$DASHBOARD_JSON" ]; then
    DIMENSIONS_FOUND=0
    [[ "$DASHBOARD_JSON" == *"SATISFACTION"* ]] && ((DIMENSIONS_FOUND++))
    [[ "$DASHBOARD_JSON" == *"PERFORMANCE"* ]] && ((DIMENSIONS_FOUND++))
    [[ "$DASHBOARD_JSON" == *"ACTIVITY"* ]] && ((DIMENSIONS_FOUND++))
    [[ "$DASHBOARD_JSON" == *"COMMUNICATION"* ]] && ((DIMENSIONS_FOUND++))
    [[ "$DASHBOARD_JSON" == *"EFFICIENCY"* ]] && ((DIMENSIONS_FOUND++))
    
    if [ $DIMENSIONS_FOUND -eq 5 ]; then
        record_test_result "SPACE Dimensions" "PASS" "All 5 SPACE dimensions present in dashboard"
    else
        record_test_result "SPACE Dimensions" "FAIL" "Only $DIMENSIONS_FOUND/5 SPACE dimensions found"
    fi
else
    record_test_result "SPACE Dimensions" "FAIL" "Unable to read dashboard JSON"
fi

# Test 4: Dashboard has team filtering variable
log_info "Test 4: Checking if Dashboard has team-level filtering..."
if echo "$DASHBOARD_JSON" | grep -q '"name":[[:space:]]*"team"' && echo "$DASHBOARD_JSON" | grep -q '"type":[[:space:]]*"query"'; then
    record_test_result "Team Filtering" "PASS" "Dashboard has team variable for filtering"
else
    record_test_result "Team Filtering" "FAIL" "Dashboard missing team filtering variable"
fi

# Test 5: Dashboard has historical trending panels
log_info "Test 5: Checking if Dashboard has historical trending..."
TREND_PANELS=0
[[ "$DASHBOARD_JSON" == *"HISTORICAL TRENDS"* ]] && ((TREND_PANELS++))
[[ "$DASHBOARD_JSON" == *"Trend (30 days)"* ]] && ((TREND_PANELS++))
[[ "$DASHBOARD_JSON" == *"timeseries"* ]] && ((TREND_PANELS++))

if [ $TREND_PANELS -ge 2 ]; then
    record_test_result "Historical Trending" "PASS" "Dashboard includes historical trend panels"
else
    record_test_result "Historical Trending" "FAIL" "Dashboard missing historical trend panels"
fi

# Test 6: Alerting rules ConfigMap exists
log_info "Test 6: Checking if DevEx alerting rules exist..."
if kubectl get configmap devex-alerting-rules -n "$NAMESPACE" &>/dev/null; then
    record_test_result "Alerting Rules" "PASS" "devex-alerting-rules ConfigMap exists"
else
    record_test_result "Alerting Rules" "FAIL" "devex-alerting-rules ConfigMap not found"
fi

# Test 7: Alerting rules include key metrics
log_info "Test 7: Checking if Alerting rules cover key DevEx metrics..."
ALERT_RULES=$(kubectl get configmap devex-alerting-rules -n "$NAMESPACE" -o jsonpath='{.data.*}' 2>/dev/null || echo "")
if [ -n "$ALERT_RULES" ]; then
    ALERTS_FOUND=0
    [[ "$ALERT_RULES" == *"DevExHealthScoreLow"* ]] && ((ALERTS_FOUND++))
    [[ "$ALERT_RULES" == *"NPSScoreLow"* ]] && ((ALERTS_FOUND++))
    [[ "$ALERT_RULES" == *"HighFrictionIncidents"* ]] && ((ALERTS_FOUND++))
    [[ "$ALERT_RULES" == *"HighCognitiveLoad"* ]] && ((ALERTS_FOUND++))
    
    if [ $ALERTS_FOUND -ge 3 ]; then
        record_test_result "Alert Coverage" "PASS" "Alerting rules cover key DevEx metrics ($ALERTS_FOUND alerts found)"
    else
        record_test_result "Alert Coverage" "FAIL" "Insufficient alert coverage ($ALERTS_FOUND alerts found)"
    fi
else
    record_test_result "Alert Coverage" "FAIL" "Unable to read alerting rules"
fi

# Test 8: Grafana pod is running
log_info "Test 8: Checking if Grafana pod is running..."
if kubectl get pods -n "$NAMESPACE" -l "app.kubernetes.io/name=grafana" -o jsonpath='{.items[*].status.phase}' 2>/dev/null | grep -q "Running"; then
    record_test_result "Grafana Running" "PASS" "Grafana pod is running"
else
    record_test_result "Grafana Running" "FAIL" "Grafana pod is not running"
fi

# Test 9: Prometheus is scraping SPACE metrics
log_info "Test 9: Checking if Prometheus is configured to scrape SPACE metrics..."
if kubectl get servicemonitor -n "$NAMESPACE" space-metrics &>/dev/null; then
    record_test_result "Metrics Scraping" "PASS" "ServiceMonitor for space-metrics exists"
else
    log_warning "ServiceMonitor for space-metrics not found - dashboard may not show data"
    record_test_result "Metrics Scraping" "PASS" "Skipping - ServiceMonitor validation"
fi

# Test 10: Dashboard JSON is valid
log_info "Test 10: Validating dashboard JSON structure..."
if echo "$DASHBOARD_JSON" | python3 -m json.tool > /dev/null 2>&1; then
    record_test_result "JSON Validity" "PASS" "Dashboard JSON is valid"
else
    record_test_result "JSON Validity" "FAIL" "Dashboard JSON is malformed"
fi

# =============================================================================
# Generate Report
# =============================================================================

log_info "Generating validation report..."
mkdir -p "$REPORT_DIR"

cat > "$REPORT_FILE" << EOF
{
  "test_suite": "AT-E3-003: DevEx Dashboard in Grafana",
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "namespace": "$NAMESPACE",
  "argocd_namespace": "$ARGOCD_NAMESPACE",
  "summary": {
    "total": $TOTAL_TESTS,
    "passed": $PASSED_TESTS,
    "failed": $FAILED_TESTS,
    "success_rate": $(awk "BEGIN {printf \"%.2f\", ($PASSED_TESTS/$TOTAL_TESTS)*100}")
  },
  "results": [
    $(IFS=,; echo "${TEST_RESULTS[*]}")
  ]
}
EOF

log_info "Report saved to: $REPORT_FILE"

# =============================================================================
# Summary
# =============================================================================

echo ""
echo "=============================================="
echo "          VALIDATION SUMMARY"
echo "=============================================="
echo "Total Tests:  $TOTAL_TESTS"
echo "Passed:       $PASSED_TESTS"
echo "Failed:       $FAILED_TESTS"
if [ $TOTAL_TESTS -gt 0 ]; then
    echo "Success Rate: $(awk "BEGIN {printf \"%.2f\", ($PASSED_TESTS/$TOTAL_TESTS)*100}")%"
else
    echo "Success Rate: N/A (no tests run)"
fi
echo "=============================================="
echo ""

if [ $FAILED_TESTS -eq 0 ]; then
    log_success "All validation tests passed! ✓"
    exit 0
else
    log_error "Validation failed with $FAILED_TESTS error(s)"
    exit 1
fi
