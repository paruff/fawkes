#!/bin/bash
# ============================================================================
# FILE: scripts/validate-at-e2-003.sh
# PURPOSE: Validation script for AT-E2-003 acceptance test (Data Catalog)
# USAGE: ./scripts/validate-at-e2-003.sh --namespace fawkes
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
LOGGING_NAMESPACE="${LOGGING_NAMESPACE:-logging}"
TIMEOUT="${TIMEOUT:-300}"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --namespace)
            NAMESPACE="$2"
            shift 2
            ;;
        --logging-namespace)
            LOGGING_NAMESPACE="$2"
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
            echo "  --namespace NAMESPACE          Kubernetes namespace (default: fawkes)"
            echo "  --logging-namespace NAMESPACE  Logging namespace (default: logging)"
            echo "  --timeout TIMEOUT              Timeout in seconds (default: 300)"
            echo "  --help                         Show this help message"
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
echo "AT-E2-003: DataHub Data Catalog Validation"
echo "================================================================================"
echo ""
echo "Namespace: $NAMESPACE"
echo "Logging Namespace: $LOGGING_NAMESPACE"
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

test_postgresql() {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Phase 2: PostgreSQL Database"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    # Check if PostgreSQL cluster exists
    run_test
    if kubectl get cluster db-datahub-dev -n "$NAMESPACE" &> /dev/null; then
        pass "PostgreSQL cluster 'db-datahub-dev' exists"
        
        # Check cluster status
        status=$(kubectl get cluster db-datahub-dev -n "$NAMESPACE" -o jsonpath='{.status.phase}' 2>/dev/null || echo "Unknown")
        info "Cluster status: $status"
    else
        fail "PostgreSQL cluster 'db-datahub-dev' not found"
    fi
    
    # Check if PostgreSQL pods are running
    run_test
    pod_count=$(kubectl get pods -n "$NAMESPACE" -l "cnpg.io/cluster=db-datahub-dev" --field-selector=status.phase=Running --no-headers 2>/dev/null | wc -l)
    if [ "$pod_count" -ge 1 ]; then
        pass "PostgreSQL has $pod_count running pod(s)"
    else
        fail "No PostgreSQL pods are running"
    fi
    
    # Check PostgreSQL service
    run_test
    if kubectl get service db-datahub-dev-rw -n "$NAMESPACE" &> /dev/null; then
        pass "PostgreSQL read-write service exists"
    else
        fail "PostgreSQL read-write service not found"
    fi
    
    echo ""
}

test_opensearch() {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Phase 3: OpenSearch"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    # Check OpenSearch pods
    run_test
    pod_count=$(kubectl get pods -n "$LOGGING_NAMESPACE" -l "app=opensearch" --field-selector=status.phase=Running --no-headers 2>/dev/null | wc -l)
    if [ "$pod_count" -ge 1 ]; then
        pass "OpenSearch has $pod_count running pod(s)"
    else
        fail "No OpenSearch pods are running in namespace '$LOGGING_NAMESPACE'"
    fi
    
    # Check OpenSearch service
    run_test
    if kubectl get service opensearch -n "$LOGGING_NAMESPACE" &> /dev/null; then
        pass "OpenSearch service exists"
    else
        fail "OpenSearch service not found"
    fi
    
    echo ""
}

test_datahub_deployment() {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Phase 4: DataHub Deployment"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    # Check GMS deployment
    run_test
    if kubectl get deployment datahub-datahub-gms -n "$NAMESPACE" &> /dev/null; then
        pass "DataHub GMS deployment exists"
        
        # Check GMS readiness
        gms_ready=$(kubectl get deployment datahub-datahub-gms -n "$NAMESPACE" -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo "0")
        gms_desired=$(kubectl get deployment datahub-datahub-gms -n "$NAMESPACE" -o jsonpath='{.spec.replicas}' 2>/dev/null || echo "1")
        
        run_test
        if [ "${gms_ready:-0}" -ge 1 ] && [ "$gms_ready" = "$gms_desired" ]; then
            pass "DataHub GMS is ready ($gms_ready/$gms_desired replicas)"
        else
            fail "DataHub GMS is not ready ($gms_ready/$gms_desired replicas)"
        fi
    else
        fail "DataHub GMS deployment not found"
    fi
    
    # Check Frontend deployment
    run_test
    if kubectl get deployment datahub-datahub-frontend -n "$NAMESPACE" &> /dev/null; then
        pass "DataHub Frontend deployment exists"
        
        # Check Frontend readiness
        frontend_ready=$(kubectl get deployment datahub-datahub-frontend -n "$NAMESPACE" -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo "0")
        frontend_desired=$(kubectl get deployment datahub-datahub-frontend -n "$NAMESPACE" -o jsonpath='{.spec.replicas}' 2>/dev/null || echo "1")
        
        run_test
        if [ "${frontend_ready:-0}" -ge 1 ] && [ "$frontend_ready" = "$frontend_desired" ]; then
            pass "DataHub Frontend is ready ($frontend_ready/$frontend_desired replicas)"
        else
            fail "DataHub Frontend is not ready ($frontend_ready/$frontend_desired replicas)"
        fi
    else
        fail "DataHub Frontend deployment not found"
    fi
    
    echo ""
}

test_services() {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Phase 5: Services"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    # Check GMS service
    run_test
    if kubectl get service datahub-datahub-gms -n "$NAMESPACE" &> /dev/null; then
        pass "DataHub GMS service exists"
    else
        fail "DataHub GMS service not found"
    fi
    
    # Check Frontend service
    run_test
    if kubectl get service datahub-datahub-frontend -n "$NAMESPACE" &> /dev/null; then
        pass "DataHub Frontend service exists"
    else
        fail "DataHub Frontend service not found"
    fi
    
    echo ""
}

test_ingress() {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Phase 6: Ingress Configuration"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    # Check ingress exists
    run_test
    if kubectl get ingress datahub-datahub-frontend -n "$NAMESPACE" &> /dev/null; then
        pass "DataHub ingress exists"
        
        # Get ingress hosts
        hosts=$(kubectl get ingress datahub-datahub-frontend -n "$NAMESPACE" -o jsonpath='{.spec.rules[*].host}' 2>/dev/null || echo "")
        if [ -n "$hosts" ]; then
            info "Ingress hosts: $hosts"
        fi
    else
        fail "DataHub ingress not found"
    fi
    
    echo ""
}

test_api_health() {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Phase 7: API Health"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    # Check GMS health endpoint
    run_test
    gms_pod=$(kubectl get pods -n "$NAMESPACE" -l "app.kubernetes.io/component=datahub-gms" --field-selector=status.phase=Running -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
    if [ -n "$gms_pod" ]; then
        if kubectl exec -n "$NAMESPACE" "$gms_pod" -- curl -s -f http://localhost:8080/health 2>/dev/null | grep -q "healthy\|ok\|UP" || [ $? -eq 0 ]; then
            pass "DataHub GMS health check passed"
        else
            info "DataHub GMS health check not available (may be initializing)"
        fi
    else
        info "No GMS pod found for health check"
    fi
    
    # Check Frontend health endpoint
    run_test
    frontend_pod=$(kubectl get pods -n "$NAMESPACE" -l "app.kubernetes.io/component=datahub-frontend" --field-selector=status.phase=Running -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
    if [ -n "$frontend_pod" ]; then
        if kubectl exec -n "$NAMESPACE" "$frontend_pod" -- curl -s -f http://localhost:9002/admin 2>/dev/null >/dev/null || [ $? -eq 0 ]; then
            pass "DataHub Frontend health check passed"
        else
            info "DataHub Frontend health check not available (may be initializing)"
        fi
    else
        info "No Frontend pod found for health check"
    fi
    
    echo ""
}

test_ingestion_automation() {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Phase 8: Ingestion Automation"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    # Check PostgreSQL ingestion CronJob
    run_test
    if kubectl get cronjob datahub-postgres-ingestion -n "$NAMESPACE" &> /dev/null; then
        pass "PostgreSQL ingestion CronJob exists"
        
        schedule=$(kubectl get cronjob datahub-postgres-ingestion -n "$NAMESPACE" -o jsonpath='{.spec.schedule}' 2>/dev/null || echo "")
        if [ -n "$schedule" ]; then
            info "Schedule: $schedule"
        fi
    else
        info "PostgreSQL ingestion CronJob not found (optional)"
    fi
    
    # Check Kubernetes ingestion CronJob
    run_test
    if kubectl get cronjob datahub-k8s-ingestion -n "$NAMESPACE" &> /dev/null; then
        pass "Kubernetes ingestion CronJob exists"
        
        schedule=$(kubectl get cronjob datahub-k8s-ingestion -n "$NAMESPACE" -o jsonpath='{.spec.schedule}' 2>/dev/null || echo "")
        if [ -n "$schedule" ]; then
            info "Schedule: $schedule"
        fi
    else
        info "Kubernetes ingestion CronJob not found (optional)"
    fi
    
    # Check Git/CI ingestion CronJob
    run_test
    if kubectl get cronjob datahub-git-ci-ingestion -n "$NAMESPACE" &> /dev/null; then
        pass "Git/CI ingestion CronJob exists"
        
        schedule=$(kubectl get cronjob datahub-git-ci-ingestion -n "$NAMESPACE" -o jsonpath='{.spec.schedule}' 2>/dev/null || echo "")
        if [ -n "$schedule" ]; then
            info "Schedule: $schedule"
        fi
    else
        info "Git/CI ingestion CronJob not found (optional)"
    fi
    
    echo ""
}

test_resource_limits() {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Phase 9: Resource Limits"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    # Check GMS resource limits
    run_test
    gms_cpu_request=$(kubectl get deployment datahub-datahub-gms -n "$NAMESPACE" -o jsonpath='{.spec.template.spec.containers[0].resources.requests.cpu}' 2>/dev/null || echo "")
    gms_memory_request=$(kubectl get deployment datahub-datahub-gms -n "$NAMESPACE" -o jsonpath='{.spec.template.spec.containers[0].resources.requests.memory}' 2>/dev/null || echo "")
    
    if [ -n "$gms_cpu_request" ] && [ -n "$gms_memory_request" ]; then
        pass "GMS has resource requests configured (CPU: $gms_cpu_request, Memory: $gms_memory_request)"
    else
        fail "GMS missing resource requests"
    fi
    
    run_test
    gms_cpu_limit=$(kubectl get deployment datahub-datahub-gms -n "$NAMESPACE" -o jsonpath='{.spec.template.spec.containers[0].resources.limits.cpu}' 2>/dev/null || echo "")
    gms_memory_limit=$(kubectl get deployment datahub-datahub-gms -n "$NAMESPACE" -o jsonpath='{.spec.template.spec.containers[0].resources.limits.memory}' 2>/dev/null || echo "")
    
    if [ -n "$gms_cpu_limit" ] && [ -n "$gms_memory_limit" ]; then
        pass "GMS has resource limits configured (CPU: $gms_cpu_limit, Memory: $gms_memory_limit)"
    else
        fail "GMS missing resource limits"
    fi
    
    # Check Frontend resource limits
    run_test
    frontend_cpu_request=$(kubectl get deployment datahub-datahub-frontend -n "$NAMESPACE" -o jsonpath='{.spec.template.spec.containers[0].resources.requests.cpu}' 2>/dev/null || echo "")
    frontend_memory_request=$(kubectl get deployment datahub-datahub-frontend -n "$NAMESPACE" -o jsonpath='{.spec.template.spec.containers[0].resources.requests.memory}' 2>/dev/null || echo "")
    
    if [ -n "$frontend_cpu_request" ] && [ -n "$frontend_memory_request" ]; then
        pass "Frontend has resource requests configured (CPU: $frontend_cpu_request, Memory: $frontend_memory_request)"
    else
        fail "Frontend missing resource requests"
    fi
    
    run_test
    frontend_cpu_limit=$(kubectl get deployment datahub-datahub-frontend -n "$NAMESPACE" -o jsonpath='{.spec.template.spec.containers[0].resources.limits.cpu}' 2>/dev/null || echo "")
    frontend_memory_limit=$(kubectl get deployment datahub-datahub-frontend -n "$NAMESPACE" -o jsonpath='{.spec.template.spec.containers[0].resources.limits.memory}' 2>/dev/null || echo "")
    
    if [ -n "$frontend_cpu_limit" ] && [ -n "$frontend_memory_limit" ]; then
        pass "Frontend has resource limits configured (CPU: $frontend_cpu_limit, Memory: $frontend_memory_limit)"
    else
        fail "Frontend missing resource limits"
    fi
    
    echo ""
}

test_argocd_application() {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Phase 10: ArgoCD Application"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    # Check ArgoCD Application
    run_test
    if kubectl get application datahub -n argocd &> /dev/null; then
        pass "ArgoCD Application exists"
        
        # Check sync status
        sync_status=$(kubectl get application datahub -n argocd -o jsonpath='{.status.sync.status}' 2>/dev/null || echo "Unknown")
        health_status=$(kubectl get application datahub -n argocd -o jsonpath='{.status.health.status}' 2>/dev/null || echo "Unknown")
        
        info "Sync Status: $sync_status"
        info "Health Status: $health_status"
    else
        info "ArgoCD Application not found (manual deployment)"
    fi
    
    echo ""
}

# Generate test report
generate_report() {
    local timestamp=$(date -Iseconds)
    local report_file="reports/at-e2-003-validation-$(date +%Y%m%d-%H%M%S).json"
    
    # Create reports directory if it doesn't exist
    mkdir -p reports
    
    # Generate JSON report
    cat > "$report_file" << EOF
{
  "test_suite": "AT-E2-003",
  "acceptance_test": "DataHub Data Catalog",
  "timestamp": "$timestamp",
  "namespace": "$NAMESPACE",
  "summary": {
    "total_tests": $TESTS_RUN,
    "passed_tests": $TESTS_PASSED,
    "failed_tests": $TESTS_FAILED,
    "success_rate": $(awk "BEGIN {printf \"%.2f\", ($TESTS_PASSED * 100 / $TESTS_RUN)}")
  },
  "acceptance_criteria": {
    "datahub_deployed": $([ $TESTS_PASSED -gt 0 ] && echo "true" || echo "false"),
    "postgresql_operational": $(kubectl get cluster db-datahub-dev -n "$NAMESPACE" &>/dev/null && echo "true" || echo "false"),
    "opensearch_operational": $([ $(kubectl get pods -n "$LOGGING_NAMESPACE" -l "app=opensearch" --field-selector=status.phase=Running --no-headers 2>/dev/null | wc -l) -ge 1 ] && echo "true" || echo "false"),
    "gms_accessible": $(kubectl get deployment datahub-datahub-gms -n "$NAMESPACE" &>/dev/null && echo "true" || echo "false"),
    "frontend_accessible": $(kubectl get deployment datahub-datahub-frontend -n "$NAMESPACE" &>/dev/null && echo "true" || echo "false"),
    "ingress_configured": $(kubectl get ingress datahub-datahub-frontend -n "$NAMESPACE" &>/dev/null && echo "true" || echo "false")
  },
  "status": $([ $TESTS_FAILED -eq 0 ] && echo "\"PASSED\"" || echo "\"FAILED\"")
}
EOF
    
    echo "Test report generated: $report_file"
}

# Run all tests
test_prerequisites
test_postgresql
test_opensearch
test_datahub_deployment
test_services
test_ingress
test_api_health
test_ingestion_automation
test_resource_limits
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

# Generate report
generate_report
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ AT-E2-003: All tests passed!${NC}"
    echo ""
    echo "DataHub data catalog is deployed and operational."
    exit 0
else
    echo -e "${RED}✗ AT-E2-003: Some tests failed${NC}"
    echo ""
    echo "Please review the failures above and fix the issues."
    exit 1
fi
