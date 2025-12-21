#!/bin/bash
# ============================================================================
# FILE: scripts/validate-at-e2-004.sh
# PURPOSE: Validation script for AT-E2-004 acceptance test (Data Quality)
# USAGE: ./scripts/validate-at-e2-004.sh --namespace fawkes
# ============================================================================

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Configuration
NAMESPACE="${NAMESPACE:-fawkes}"
TIMEOUT="${TIMEOUT:-300}"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --namespace)
            NAMESPACE="$2"
            shift 2
            ;;
        --timeout)
            TIMEOUT="$2"
            shift 2
            ;;
        --help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --namespace NAMESPACE  Kubernetes namespace (default: fawkes)"
            echo "  --timeout TIMEOUT      Timeout in seconds (default: 300)"
            echo "  --help                 Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

echo "================================================================================"
echo "AT-E2-004: Great Expectations Data Quality Validation"
echo "================================================================================"
echo ""
echo "Namespace: $NAMESPACE"
echo "Timeout: $TIMEOUT seconds"
echo ""

# Helper functions
pass() {
    echo -e "${GREEN}✓${NC} $1"
    ((TESTS_PASSED++))
}

fail() {
    echo -e "${RED}✗${NC} $1"
    ((TESTS_FAILED++))
}

info() {
    echo -e "${YELLOW}ℹ${NC} $1"
}

run_test() {
    ((TESTS_RUN++))
}

# Test functions
test_prerequisites() {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Phase 1: Prerequisites"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    # Check kubectl
    run_test
    if command -v kubectl &> /dev/null; then
        pass "kubectl is installed"
    else
        fail "kubectl is not installed"
        exit 1
    fi
    
    # Check cluster access
    run_test
    if kubectl cluster-info &> /dev/null; then
        pass "Kubernetes cluster is accessible"
    else
        fail "Cannot access Kubernetes cluster"
        exit 1
    fi
    
    # Check namespace exists
    run_test
    if kubectl get namespace "$NAMESPACE" &> /dev/null; then
        pass "Namespace $NAMESPACE exists"
    else
        fail "Namespace $NAMESPACE does not exist"
        exit 1
    fi
    
    echo ""
}

test_configuration() {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Phase 2: Great Expectations Configuration"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    # Check ConfigMap exists
    run_test
    if kubectl get configmap data-quality-config -n "$NAMESPACE" &> /dev/null; then
        pass "Data quality ConfigMap exists"
    else
        fail "Data quality ConfigMap not found"
    fi
    
    # Check Secret exists
    run_test
    if kubectl get secret data-quality-secrets -n "$NAMESPACE" &> /dev/null; then
        pass "Data quality Secret exists"
    else
        fail "Data quality Secret not found"
    fi
    
    # Check GX config ConfigMap
    run_test
    if kubectl get configmap gx-full-config -n "$NAMESPACE" &> /dev/null; then
        pass "Great Expectations config ConfigMap exists"
    else
        fail "Great Expectations config ConfigMap not found"
    fi
    
    # Check scripts ConfigMap
    run_test
    if kubectl get configmap gx-scripts -n "$NAMESPACE" &> /dev/null; then
        pass "Scripts ConfigMap exists"
    else
        fail "Scripts ConfigMap not found"
    fi
    
    echo ""
}

test_datasources() {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Phase 3: Data Sources Connected"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    # Check Backstage DB
    run_test
    if kubectl get cluster db-backstage -n "$NAMESPACE" &> /dev/null; then
        pass "Backstage database cluster exists"
    else
        fail "Backstage database cluster not found"
    fi
    
    # Check Harbor DB
    run_test
    if kubectl get cluster db-harbor -n "$NAMESPACE" &> /dev/null; then
        pass "Harbor database cluster exists"
    else
        info "Harbor database cluster not found (may not be deployed yet)"
    fi
    
    # Check DataHub DB
    run_test
    if kubectl get cluster db-datahub -n "$NAMESPACE" &> /dev/null; then
        pass "DataHub database cluster exists"
    else
        info "DataHub database cluster not found (may not be deployed yet)"
    fi
    
    # Check SonarQube DB
    run_test
    if kubectl get cluster db-sonarqube-dev -n "$NAMESPACE" &> /dev/null; then
        pass "SonarQube database cluster exists"
    else
        info "SonarQube database cluster not found (may not be deployed yet)"
    fi
    
    echo ""
}

test_expectation_suites() {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Phase 4: Expectation Suites Created"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    # Check ConfigMap contains expectation suites
    run_test
    if kubectl get configmap gx-full-config -n "$NAMESPACE" -o jsonpath='{.data}' | grep -q "backstage_db_suite.json"; then
        pass "Backstage expectation suite exists"
    else
        fail "Backstage expectation suite not found in ConfigMap"
    fi
    
    run_test
    if kubectl get configmap gx-full-config -n "$NAMESPACE" -o jsonpath='{.data}' | grep -q "harbor_db_suite.json"; then
        pass "Harbor expectation suite exists"
    else
        fail "Harbor expectation suite not found in ConfigMap"
    fi
    
    run_test
    if kubectl get configmap gx-full-config -n "$NAMESPACE" -o jsonpath='{.data}' | grep -q "datahub_db_suite.json"; then
        pass "DataHub expectation suite exists"
    else
        fail "DataHub expectation suite not found in ConfigMap"
    fi
    
    run_test
    if kubectl get configmap gx-full-config -n "$NAMESPACE" -o jsonpath='{.data}' | grep -q "dora_metrics_suite.json"; then
        pass "DORA metrics expectation suite exists"
    else
        fail "DORA metrics expectation suite not found in ConfigMap"
    fi
    
    run_test
    if kubectl get configmap gx-full-config -n "$NAMESPACE" -o jsonpath='{.data}' | grep -q "sonarqube_db_suite.json"; then
        pass "SonarQube expectation suite exists"
    else
        fail "SonarQube expectation suite not found in ConfigMap"
    fi
    
    echo ""
}

test_validation_automation() {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Phase 5: Validation Running Automatically"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    # Check CronJob exists
    run_test
    if kubectl get cronjob data-quality-validation -n "$NAMESPACE" &> /dev/null; then
        pass "Data quality CronJob exists"
    else
        fail "Data quality CronJob not found"
        return
    fi
    
    # Check CronJob schedule
    run_test
    schedule=$(kubectl get cronjob data-quality-validation -n "$NAMESPACE" -o jsonpath='{.spec.schedule}')
    if [ -n "$schedule" ]; then
        pass "CronJob schedule configured: $schedule"
    else
        fail "CronJob schedule not configured"
    fi
    
    # Check if any jobs have been created (may be none if recently deployed)
    run_test
    job_count=$(kubectl get jobs -n "$NAMESPACE" -l app=data-quality --no-headers 2>/dev/null | wc -l)
    if [ "$job_count" -gt 0 ]; then
        pass "Data quality jobs have been created ($job_count jobs)"
    else
        info "No data quality jobs created yet (this is normal for new deployments)"
    fi
    
    echo ""
}

test_checkpoints() {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Phase 6: Checkpoints Configuration"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    # Check checkpoints in ConfigMap
    run_test
    if kubectl get configmap gx-full-config -n "$NAMESPACE" -o jsonpath='{.data}' | grep -q "backstage_db_checkpoint.yml"; then
        pass "Backstage checkpoint exists"
    else
        fail "Backstage checkpoint not found"
    fi
    
    run_test
    if kubectl get configmap gx-full-config -n "$NAMESPACE" -o jsonpath='{.data}' | grep -q "all_databases_checkpoint.yml"; then
        pass "All databases checkpoint exists"
    else
        fail "All databases checkpoint not found"
    fi
    
    run_test
    if kubectl get configmap gx-full-config -n "$NAMESPACE" -o jsonpath='{.data}' | grep -q "dora_metrics_checkpoint.yml"; then
        pass "DORA metrics checkpoint exists"
    else
        fail "DORA metrics checkpoint not found"
    fi
    
    run_test
    if kubectl get configmap gx-full-config -n "$NAMESPACE" -o jsonpath='{.data}' | grep -q "sonarqube_db_checkpoint.yml"; then
        pass "SonarQube checkpoint exists"
    else
        fail "SonarQube checkpoint not found"
    fi
    
    echo ""
}

test_argocd_application() {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Phase 7: ArgoCD Application"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    # Check ArgoCD Application
    run_test
    if kubectl get application data-quality -n "$NAMESPACE" &> /dev/null; then
        pass "ArgoCD Application exists"
        
        # Check sync status
        sync_status=$(kubectl get application data-quality -n "$NAMESPACE" -o jsonpath='{.status.sync.status}' 2>/dev/null || echo "Unknown")
        health_status=$(kubectl get application data-quality -n "$NAMESPACE" -o jsonpath='{.status.health.status}' 2>/dev/null || echo "Unknown")
        
        info "Sync Status: $sync_status"
        info "Health Status: $health_status"
    else
        info "ArgoCD Application not found (manual deployment)"
    fi
    
    echo ""
}

# Run all tests
test_prerequisites
test_configuration
test_datasources
test_expectation_suites
test_validation_automation
test_checkpoints
test_argocd_application

# Summary
echo "================================================================================"
echo "Test Summary"
echo "================================================================================"
echo ""
echo "Tests Run:    $TESTS_RUN"
echo "Tests Passed: $TESTS_PASSED"
echo "Tests Failed: $TESTS_FAILED"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ AT-E2-004: All tests passed!${NC}"
    echo ""
    echo "Great Expectations data quality service is configured and operational."
    exit 0
else
    echo -e "${RED}✗ AT-E2-004: Some tests failed${NC}"
    echo ""
    echo "Please review the failures above and fix the issues."
    exit 1
fi
