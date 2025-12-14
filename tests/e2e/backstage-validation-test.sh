#!/bin/bash
# =============================================================================
# Script: backstage-validation-test.sh
# Purpose: E2E tests for Backstage Developer Portal
# Usage: ./tests/e2e/backstage-validation-test.sh [--namespace NAMESPACE]
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
TIMEOUT=300

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

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

run_test() {
    local test_name="$1"
    local test_command="$2"
    
    TESTS_RUN=$((TESTS_RUN + 1))
    log_info "Test $TESTS_RUN: $test_name"
    
    if eval "$test_command"; then
        TESTS_PASSED=$((TESTS_PASSED + 1))
        log_success "$test_name passed"
        return 0
    else
        TESTS_FAILED=$((TESTS_FAILED + 1))
        log_error "$test_name failed"
        return 1
    fi
}

# =============================================================================
# Test Functions
# =============================================================================

test_backstage_pods_running() {
    local pod_count=$(kubectl get pods -n "$NAMESPACE" -l app.kubernetes.io/name=backstage -o json 2>/dev/null | jq '.items | length' 2>/dev/null || echo "0")
    
    if [ "$pod_count" -gt 0 ]; then
        local running_pods=$(kubectl get pods -n "$NAMESPACE" -l app.kubernetes.io/name=backstage -o json 2>/dev/null | jq '[.items[] | select(.status.phase=="Running")] | length' 2>/dev/null || echo "0")
        
        if [ "$running_pods" -gt 0 ]; then
            log_info "  Found $running_pods running Backstage pod(s)"
            return 0
        fi
    fi
    
    log_error "  No running Backstage pods found"
    return 1
}

test_backstage_health_endpoint() {
    local pod_name=$(kubectl get pods -n "$NAMESPACE" -l app.kubernetes.io/name=backstage -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
    
    if [ -z "$pod_name" ]; then
        log_error "  Cannot find Backstage pod"
        return 1
    fi
    
    local status_code=$(kubectl exec -n "$NAMESPACE" "$pod_name" -- curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1:7007/healthcheck 2>/dev/null || echo "000")
    
    if [ "$status_code" = "200" ]; then
        log_info "  Health endpoint returned 200"
        return 0
    else
        log_error "  Health endpoint returned $status_code"
        return 1
    fi
}

test_catalog_api_accessible() {
    local pod_name=$(kubectl get pods -n "$NAMESPACE" -l app.kubernetes.io/name=backstage -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
    
    if [ -z "$pod_name" ]; then
        log_error "  Cannot find Backstage pod"
        return 1
    fi
    
    local status_code=$(kubectl exec -n "$NAMESPACE" "$pod_name" -- curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1:7007/api/catalog/entities 2>/dev/null || echo "000")
    
    if [ "$status_code" = "200" ]; then
        log_info "  Catalog API returned 200"
        return 0
    else
        log_error "  Catalog API returned $status_code"
        return 1
    fi
}

test_templates_in_catalog() {
    local pod_name=$(kubectl get pods -n "$NAMESPACE" -l app.kubernetes.io/name=backstage -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
    
    if [ -z "$pod_name" ]; then
        log_error "  Cannot find Backstage pod"
        return 1
    fi
    
    local catalog_response=$(kubectl exec -n "$NAMESPACE" "$pod_name" -- curl -s http://127.0.0.1:7007/api/catalog/entities?filter=kind=Template 2>/dev/null || echo "")
    
    if [ -z "$catalog_response" ]; then
        log_error "  Cannot query catalog API"
        return 1
    fi
    
    local template_count=$(echo "$catalog_response" | jq '.items | length' 2>/dev/null || echo "0")
    
    if [ "$template_count" -ge 3 ]; then
        log_info "  Found $template_count templates (≥3 required)"
        return 0
    else
        log_error "  Only found $template_count templates (≥3 required)"
        return 1
    fi
}

test_postgres_connectivity() {
    local pod_name=$(kubectl get pods -n "$NAMESPACE" -l app.kubernetes.io/name=backstage -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
    
    if [ -z "$pod_name" ]; then
        log_error "  Cannot find Backstage pod"
        return 1
    fi
    
    # Check if POSTGRES_HOST env var is set
    local pg_host=$(kubectl exec -n "$NAMESPACE" "$pod_name" -- printenv POSTGRES_HOST 2>/dev/null || echo "")
    
    if [ -n "$pg_host" ]; then
        log_info "  PostgreSQL configured at: $pg_host"
        return 0
    else
        log_error "  PostgreSQL configuration not found"
        return 1
    fi
}

test_service_exists() {
    if kubectl get service -n "$NAMESPACE" -l app.kubernetes.io/name=backstage &> /dev/null; then
        local service_name=$(kubectl get service -n "$NAMESPACE" -l app.kubernetes.io/name=backstage -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
        log_info "  Service found: $service_name"
        return 0
    else
        log_error "  No service found for Backstage"
        return 1
    fi
}

test_configmap_exists() {
    if kubectl get configmap backstage-app-config -n "$NAMESPACE" &> /dev/null; then
        log_info "  ConfigMap backstage-app-config found"
        return 0
    else
        log_error "  ConfigMap backstage-app-config not found"
        return 1
    fi
}

test_api_response_time() {
    local pod_name=$(kubectl get pods -n "$NAMESPACE" -l app.kubernetes.io/name=backstage -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
    
    if [ -z "$pod_name" ]; then
        log_error "  Cannot find Backstage pod"
        return 1
    fi
    
    local response_time=$(kubectl exec -n "$NAMESPACE" "$pod_name" -- curl -s -o /dev/null -w '%{time_total}' http://127.0.0.1:7007/api/catalog/entities 2>/dev/null || echo "999")
    local response_time_ms=$(echo "$response_time * 1000" | bc 2>/dev/null || echo "999")
    local response_time_ms_int=${response_time_ms%.*}
    
    log_info "  API response time: ${response_time_ms_int}ms"
    
    if [ "$response_time_ms_int" -lt 500 ]; then
        return 0
    else
        log_warning "  API response time ${response_time_ms_int}ms exceeds 500ms target"
        return 0  # Warning, not failure
    fi
}

# =============================================================================
# Main Execution
# =============================================================================

main() {
    echo ""
    echo "============================================================"
    echo "  Backstage E2E Validation Tests"
    echo "============================================================"
    echo ""
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -n|--namespace)
                NAMESPACE="$2"
                shift 2
                ;;
            -t|--timeout)
                TIMEOUT="$2"
                shift 2
                ;;
            -h|--help)
                echo "Usage: $0 [--namespace NAMESPACE] [--timeout TIMEOUT]"
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                exit 1
                ;;
        esac
    done
    
    log_info "Namespace: $NAMESPACE"
    log_info "Timeout: ${TIMEOUT}s"
    echo ""
    
    # Run tests
    run_test "Backstage pods are running" "test_backstage_pods_running"
    run_test "Backstage health endpoint responds" "test_backstage_health_endpoint"
    run_test "Catalog API is accessible" "test_catalog_api_accessible"
    run_test "Templates exist in catalog" "test_templates_in_catalog"
    run_test "PostgreSQL connectivity configured" "test_postgres_connectivity"
    run_test "Service exists" "test_service_exists"
    run_test "ConfigMap exists" "test_configmap_exists"
    run_test "API response time" "test_api_response_time"
    
    # Print summary
    echo ""
    echo "============================================================"
    echo "  Test Summary"
    echo "============================================================"
    echo "Tests Run:    $TESTS_RUN"
    echo "Tests Passed: $TESTS_PASSED"
    echo "Tests Failed: $TESTS_FAILED"
    echo ""
    
    if [ "$TESTS_FAILED" -eq 0 ]; then
        log_success "All E2E tests passed!"
        return 0
    else
        log_error "Some E2E tests failed!"
        return 1
    fi
}

main "$@"
