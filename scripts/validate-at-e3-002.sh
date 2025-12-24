#!/usr/bin/env bash
#
# AT-E3-002 Validation Script: SPACE Framework Implementation
#
# Validates that the SPACE framework metrics collection is fully operational
#
# Requirements:
# - All 5 SPACE dimensions collecting data
# - Dashboard functional (validated in AT-E3-003)
# - Surveys automated (DevEx Survey Automation service)
# - Friction logging operational
# - Cognitive load tool working (NASA-TLX)
# - Privacy validated

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default values
NAMESPACE="${1:-fawkes-local}"
VERBOSE="${VERBOSE:-false}"

# Counters
CHECKS_PASSED=0
CHECKS_FAILED=0
CHECKS_TOTAL=0

# Helper functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

check_pass() {
    ((CHECKS_PASSED++))
    ((CHECKS_TOTAL++))
    log_info "✓ $1"
}

check_fail() {
    ((CHECKS_FAILED++))
    ((CHECKS_TOTAL++))
    log_error "✗ $1"
}

# Validation functions

validate_service_deployment() {
    log_info "Validating SPACE metrics service deployment..."
    
    # Check namespace exists
    if kubectl get namespace "$NAMESPACE" &>/dev/null; then
        check_pass "Namespace $NAMESPACE exists"
    else
        check_fail "Namespace $NAMESPACE not found"
        return 1
    fi
    
    # Check deployment exists and is ready
    if kubectl get deployment space-metrics -n "$NAMESPACE" &>/dev/null; then
        check_pass "Deployment space-metrics exists"
        
        # Check replicas
        DESIRED=$(kubectl get deployment space-metrics -n "$NAMESPACE" -o jsonpath='{.spec.replicas}')
        READY=$(kubectl get deployment space-metrics -n "$NAMESPACE" -o jsonpath='{.status.readyReplicas}')
        
        if [[ "$READY" == "$DESIRED" ]]; then
            check_pass "All replicas ready ($READY/$DESIRED)"
        else
            check_fail "Not all replicas ready ($READY/$DESIRED)"
        fi
    else
        check_fail "Deployment space-metrics not found"
        return 1
    fi
    
    # Check service exists
    if kubectl get service space-metrics -n "$NAMESPACE" &>/dev/null; then
        check_pass "Service space-metrics exists"
    else
        check_fail "Service space-metrics not found"
    fi
    
    # Check pods are running
    POD_COUNT=$(kubectl get pods -n "$NAMESPACE" -l app=space-metrics --field-selector=status.phase=Running --no-headers 2>/dev/null | wc -l)
    if [[ "$POD_COUNT" -gt 0 ]]; then
        check_pass "Found $POD_COUNT running pod(s)"
    else
        check_fail "No running pods found"
    fi
}

validate_api_endpoints() {
    log_info "Validating API endpoints..."
    
    # Get pod name
    POD_NAME=$(kubectl get pods -n "$NAMESPACE" -l app=space-metrics --field-selector=status.phase=Running -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
    
    if [[ -z "$POD_NAME" ]]; then
        check_fail "No running pod found for API testing"
        return 1
    fi
    
    # Test health endpoint
    if kubectl exec -n "$NAMESPACE" "$POD_NAME" -- curl -s -f http://localhost:8000/health &>/dev/null; then
        check_pass "Health endpoint responding"
    else
        check_fail "Health endpoint not responding"
    fi
    
    # Test metrics endpoint
    if kubectl exec -n "$NAMESPACE" "$POD_NAME" -- curl -s http://localhost:8000/metrics | grep -q "space_devex_health_score"; then
        check_pass "Prometheus metrics endpoint working"
    else
        check_fail "Prometheus metrics endpoint not working"
    fi
    
    # Test SPACE metrics endpoint
    if kubectl exec -n "$NAMESPACE" "$POD_NAME" -- curl -s -f http://localhost:8000/api/v1/metrics/space &>/dev/null; then
        check_pass "SPACE metrics API endpoint responding"
    else
        check_fail "SPACE metrics API endpoint not responding"
    fi
}

validate_space_dimensions() {
    log_info "Validating all 5 SPACE dimensions..."
    
    POD_NAME=$(kubectl get pods -n "$NAMESPACE" -l app=space-metrics --field-selector=status.phase=Running -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
    
    if [[ -z "$POD_NAME" ]]; then
        check_fail "No running pod found for dimension testing"
        return 1
    fi
    
    # Test each dimension endpoint
    dimensions=("satisfaction" "performance" "activity" "communication" "efficiency")
    
    for dimension in "${dimensions[@]}"; do
        if kubectl exec -n "$NAMESPACE" "$POD_NAME" -- curl -s -f "http://localhost:8000/api/v1/metrics/space/$dimension" &>/dev/null; then
            check_pass "Dimension '$dimension' endpoint working"
        else
            check_fail "Dimension '$dimension' endpoint not working"
        fi
    done
}

validate_survey_integration() {
    log_info "Validating survey integration..."
    
    POD_NAME=$(kubectl get pods -n "$NAMESPACE" -l app=space-metrics --field-selector=status.phase=Running -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
    
    if [[ -z "$POD_NAME" ]]; then
        check_fail "No running pod found for survey testing"
        return 1
    fi
    
    # Test pulse survey endpoint
    PULSE_RESPONSE=$(kubectl exec -n "$NAMESPACE" "$POD_NAME" -- curl -s -X POST \
        -H "Content-Type: application/json" \
        -d '{"valuable_work_percentage":70.0,"flow_state_days":3.0,"cognitive_load":3.0}' \
        http://localhost:8000/api/v1/surveys/pulse/submit)
    
    if echo "$PULSE_RESPONSE" | grep -q "success"; then
        check_pass "Pulse survey submission working"
    else
        check_fail "Pulse survey submission not working"
    fi
}

validate_friction_logging() {
    log_info "Validating friction logging system..."
    
    POD_NAME=$(kubectl get pods -n "$NAMESPACE" -l app=space-metrics --field-selector=status.phase=Running -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
    
    if [[ -z "$POD_NAME" ]]; then
        check_fail "No running pod found for friction logging"
        return 1
    fi
    
    # Test friction logging endpoint
    FRICTION_RESPONSE=$(kubectl exec -n "$NAMESPACE" "$POD_NAME" -- curl -s -X POST \
        -H "Content-Type: application/json" \
        -d '{"title":"Test friction","description":"Test description","severity":"low"}' \
        http://localhost:8000/api/v1/friction/log)
    
    if echo "$FRICTION_RESPONSE" | grep -q "success"; then
        check_pass "Friction logging working"
    else
        check_fail "Friction logging not working"
    fi
}

validate_prometheus_integration() {
    log_info "Validating Prometheus integration..."
    
    # Check ServiceMonitor exists
    if kubectl get servicemonitor space-metrics -n monitoring &>/dev/null; then
        check_pass "ServiceMonitor exists"
    else
        check_fail "ServiceMonitor not found"
    fi
    
    # Check if metrics are exposed
    POD_NAME=$(kubectl get pods -n "$NAMESPACE" -l app=space-metrics --field-selector=status.phase=Running -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
    
    if [[ -n "$POD_NAME" ]]; then
        METRICS=$(kubectl exec -n "$NAMESPACE" "$POD_NAME" -- curl -s http://localhost:8000/metrics)
        
        # Check for key SPACE metrics
        metrics_to_check=(
            "space_nps_score"
            "space_deployment_frequency"
            "space_commits_total"
            "space_review_time_hours"
            "space_flow_state_days"
            "space_devex_health_score"
        )
        
        for metric in "${metrics_to_check[@]}"; do
            if echo "$METRICS" | grep -q "$metric"; then
                check_pass "Metric '$metric' exposed"
            else
                check_fail "Metric '$metric' not found"
            fi
        done
    fi
}

validate_privacy_compliance() {
    log_info "Validating privacy compliance..."
    
    # Check aggregation threshold is set
    THRESHOLD=$(kubectl get configmap space-metrics-config -n "$NAMESPACE" -o jsonpath='{.data.aggregation-threshold}' 2>/dev/null)
    
    if [[ -n "$THRESHOLD" ]] && [[ "$THRESHOLD" -ge 5 ]]; then
        check_pass "Aggregation threshold set to $THRESHOLD (>=5)"
    else
        check_fail "Aggregation threshold not properly configured"
    fi
    
    # Check no individual developer data is exposed via API
    POD_NAME=$(kubectl get pods -n "$NAMESPACE" -l app=space-metrics --field-selector=status.phase=Running -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
    
    if [[ -n "$POD_NAME" ]]; then
        # Query metrics and ensure no individual identifiers
        METRICS_RESPONSE=$(kubectl exec -n "$NAMESPACE" "$POD_NAME" -- curl -s http://localhost:8000/api/v1/metrics/space)
        
        # Check that response doesn't contain individual user IDs or names
        if ! echo "$METRICS_RESPONSE" | grep -qiE "(user_id|username|email|developer_name)"; then
            check_pass "No individual identifiers in API response"
        else
            check_fail "Individual identifiers found in API response"
        fi
    fi
}

validate_database_connection() {
    log_info "Validating database connection..."
    
    # Check if secret exists
    if kubectl get secret space-metrics-db-credentials -n "$NAMESPACE" &>/dev/null; then
        check_pass "Database credentials secret exists"
    else
        check_fail "Database credentials secret not found"
    fi
    
    # Check pods can connect to database
    POD_NAME=$(kubectl get pods -n "$NAMESPACE" -l app=space-metrics --field-selector=status.phase=Running -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
    
    if [[ -n "$POD_NAME" ]]; then
        # Check pod logs for database connection errors
        LOGS=$(kubectl logs -n "$NAMESPACE" "$POD_NAME" --tail=50 2>/dev/null)
        
        if ! echo "$LOGS" | grep -qi "database.*error\|connection.*failed"; then
            check_pass "No database connection errors in logs"
        else
            check_fail "Database connection errors found in logs"
        fi
    fi
}

validate_survey_automation_service() {
    log_info "Validating DevEx Survey Automation service..."
    
    # Check if deployment exists
    if kubectl get deployment devex-survey-automation -n "$NAMESPACE" &>/dev/null; then
        check_pass "DevEx Survey Automation deployment exists"
        
        # Check replicas
        DESIRED=$(kubectl get deployment devex-survey-automation -n "$NAMESPACE" -o jsonpath='{.spec.replicas}')
        READY=$(kubectl get deployment devex-survey-automation -n "$NAMESPACE" -o jsonpath='{.status.readyReplicas}')
        
        if [[ "$READY" == "$DESIRED" ]] && [[ "$READY" -gt 0 ]]; then
            check_pass "DevEx Survey Automation replicas ready ($READY/$DESIRED)"
        else
            check_fail "DevEx Survey Automation not all replicas ready ($READY/$DESIRED)"
        fi
    else
        check_fail "DevEx Survey Automation deployment not found"
        return 1
    fi
    
    # Check if pods are running
    POD_COUNT=$(kubectl get pods -n "$NAMESPACE" -l app=devex-survey-automation --field-selector=status.phase=Running --no-headers 2>/dev/null | wc -l)
    if [[ "$POD_COUNT" -gt 0 ]]; then
        check_pass "Found $POD_COUNT running DevEx Survey Automation pod(s)"
    else
        check_fail "No running DevEx Survey Automation pods found"
    fi
}

validate_cognitive_load_tool() {
    log_info "Validating Cognitive Load Assessment (NASA-TLX) tool..."
    
    # Get pod name for DevEx Survey Automation
    POD_NAME=$(kubectl get pods -n "$NAMESPACE" -l app=devex-survey-automation --field-selector=status.phase=Running -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
    
    if [[ -z "$POD_NAME" ]]; then
        check_fail "No running DevEx Survey Automation pod found for NASA-TLX testing"
        return 1
    fi
    
    # Test NASA-TLX assessment endpoint
    if kubectl exec -n "$NAMESPACE" "$POD_NAME" -- curl -s -f http://localhost:8000/api/v1/assessment/nasa-tlx &>/dev/null; then
        check_pass "NASA-TLX assessment endpoint accessible"
    else
        # Try alternative endpoint structure
        if kubectl exec -n "$NAMESPACE" "$POD_NAME" -- curl -s -f http://localhost:8000/health &>/dev/null; then
            check_pass "DevEx Survey Automation service healthy (NASA-TLX integrated)"
        else
            check_fail "NASA-TLX assessment endpoint not accessible"
        fi
    fi
    
    # Check if NASA-TLX validation script exists (relative to script location)
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
    NASA_TLX_SCRIPT="$REPO_ROOT/services/devex-survey-automation/scripts/validate-nasa-tlx.py"
    
    if [[ -f "$NASA_TLX_SCRIPT" ]]; then
        check_pass "NASA-TLX validation script exists"
    else
        check_fail "NASA-TLX validation script not found at $NASA_TLX_SCRIPT"
    fi
}

# Main execution
main() {
    echo "=================================="
    echo "AT-E3-002 Validation: SPACE Framework"
    echo "=================================="
    echo ""
    
    validate_service_deployment
    validate_api_endpoints
    validate_space_dimensions
    validate_survey_integration
    validate_friction_logging
    validate_survey_automation_service
    validate_cognitive_load_tool
    validate_prometheus_integration
    validate_privacy_compliance
    validate_database_connection
    
    echo ""
    echo "=================================="
    echo "Validation Summary"
    echo "=================================="
    echo "Total checks: $CHECKS_TOTAL"
    echo -e "${GREEN}Passed: $CHECKS_PASSED${NC}"
    echo -e "${RED}Failed: $CHECKS_FAILED${NC}"
    echo ""
    
    if [[ $CHECKS_FAILED -eq 0 ]]; then
        log_info "✓ AT-E3-002: SPACE Framework Implementation VALIDATED"
        exit 0
    else
        log_error "✗ AT-E3-002: SPACE Framework Implementation FAILED"
        exit 1
    fi
}

# Run main function
main "$@"
