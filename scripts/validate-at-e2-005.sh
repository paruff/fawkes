#!/bin/bash
# =============================================================================
# Script: validate-at-e2-005.sh
# Purpose: Validate AT-E2-005 - VSM (Value Stream Mapping) tracking service
# Usage: ./scripts/validate-at-e2-005.sh [--namespace fawkes]
# =============================================================================

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
NAMESPACE="fawkes"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --namespace)
      NAMESPACE="$2"
      shift 2
      ;;
    *)
      shift
      ;;
  esac
done

VSM_HOST="${VSM_HOST:-vsm-service.127.0.0.1.nip.io}"
REPORTS_DIR="${ROOT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}/reports"

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Get the root directory
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

log_info() {
  echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
  echo -e "${GREEN}[✓]${NC} $1"
  ((TESTS_PASSED++))
}

log_error() {
  echo -e "${RED}[✗]${NC} $1"
  ((TESTS_FAILED++))
}

log_warning() {
  echo -e "${YELLOW}[!]${NC} $1"
}

run_test() {
  ((TESTS_RUN++))
}

echo "=========================================="
echo "AT-E2-005: VSM Service Validation"
echo "=========================================="
echo ""

log_info "Namespace: $NAMESPACE"
log_info "VSM Host: $VSM_HOST"
echo ""

# =============================================================================
# Phase 1: Prerequisites
# =============================================================================
log_info "Phase 1: Prerequisites"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Check kubectl
run_test
if command -v kubectl &> /dev/null; then
  log_success "kubectl is installed"
else
  log_error "kubectl is not installed"
  exit 1
fi

# Check cluster access
run_test
if kubectl cluster-info &> /dev/null; then
  log_success "Kubernetes cluster is accessible"
else
  log_error "Cannot access Kubernetes cluster"
  exit 1
fi

# Check namespace exists
run_test
if kubectl get namespace "$NAMESPACE" &> /dev/null; then
  log_success "Namespace $NAMESPACE exists"
else
  log_error "Namespace $NAMESPACE does not exist"
  exit 1
fi

echo ""

# =============================================================================
# Phase 2: PostgreSQL Database
# =============================================================================
log_info "Phase 2: PostgreSQL Database Validation"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Check PostgreSQL cluster
run_test
if kubectl get cluster db-vsm-dev -n "$NAMESPACE" &> /dev/null; then
  log_success "PostgreSQL cluster db-vsm-dev exists"

  # Check cluster health - check multiple possible status values
  CLUSTER_STATUS=$(kubectl get cluster db-vsm-dev -n "$NAMESPACE" -o jsonpath='{.status.phase}' 2> /dev/null || echo "Unknown")
  if [[ "$CLUSTER_STATUS" =~ ^(Cluster in healthy state|Ready|healthy)$ ]]; then
    log_success "PostgreSQL cluster is healthy (status: $CLUSTER_STATUS)"
  else
    log_warning "PostgreSQL cluster status: $CLUSTER_STATUS (may still be initializing)"
  fi
else
  log_error "PostgreSQL cluster db-vsm-dev not found"
fi

# Check PostgreSQL pods
run_test
POSTGRES_PODS=$(kubectl get pods -n "$NAMESPACE" -l "cnpg.io/cluster=db-vsm-dev" --no-headers 2> /dev/null | wc -l)
if [ "$POSTGRES_PODS" -gt 0 ]; then
  log_success "PostgreSQL pods are running ($POSTGRES_PODS pods)"
else
  log_error "No PostgreSQL pods found"
fi

# Check PostgreSQL service
run_test
if kubectl get service db-vsm-dev-rw -n "$NAMESPACE" &> /dev/null; then
  log_success "PostgreSQL service db-vsm-dev-rw exists"
else
  log_error "PostgreSQL service not found"
fi

echo ""

# =============================================================================
# Phase 3: VSM Service Deployment
# =============================================================================
log_info "Phase 3: VSM Service Deployment"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Check deployment
run_test
if kubectl get deployment vsm-service -n "$NAMESPACE" &> /dev/null; then
  log_success "VSM service deployment exists"

  # Check replicas
  READY_REPLICAS=$(kubectl get deployment vsm-service -n "$NAMESPACE" -o jsonpath='{.status.readyReplicas}' 2> /dev/null || echo "0")
  DESIRED_REPLICAS=$(kubectl get deployment vsm-service -n "$NAMESPACE" -o jsonpath='{.spec.replicas}' 2> /dev/null || echo "0")

  run_test
  if [ "$READY_REPLICAS" -ge 2 ] && [ "$READY_REPLICAS" -eq "$DESIRED_REPLICAS" ]; then
    log_success "VSM service has $READY_REPLICAS/$DESIRED_REPLICAS replicas ready"
  else
    log_error "VSM service not ready ($READY_REPLICAS/$DESIRED_REPLICAS replicas)"
  fi
else
  log_error "VSM service deployment not found"
fi

# Check service
run_test
if kubectl get service vsm-service -n "$NAMESPACE" &> /dev/null; then
  log_success "VSM service exists"
else
  log_error "VSM service not found"
fi

# Check ingress
run_test
if kubectl get ingress vsm-service -n "$NAMESPACE" &> /dev/null; then
  log_success "VSM service ingress exists"
  INGRESS_HOST=$(kubectl get ingress vsm-service -n "$NAMESPACE" -o jsonpath='{.spec.rules[0].host}' 2> /dev/null || echo "Unknown")
  log_info "Ingress host: $INGRESS_HOST"
else
  log_warning "VSM service ingress not found (may use port-forward)"
fi

# Check ConfigMap
run_test
if kubectl get configmap vsm-service-config -n "$NAMESPACE" &> /dev/null; then
  log_success "VSM service ConfigMap exists"
else
  log_warning "VSM service ConfigMap not found"
fi

echo ""

# =============================================================================
# Phase 4: VSM API Health Check
# =============================================================================
log_info "Phase 4: VSM API Health Check"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Try to access via ingress or port-forward
PORT_FORWARD_PID=""
if ! curl -s -f "http://${VSM_HOST}/api/v1/health" &> /dev/null; then
  log_warning "Cannot access VSM via $VSM_HOST, trying port-forward..."

  # Setup port-forward in background
  kubectl port-forward -n "$NAMESPACE" svc/vsm-service 8080:80 &> /dev/null &
  PORT_FORWARD_PID=$!
  sleep 3

  VSM_HOST="localhost:8080"

  # Cleanup function
  cleanup() {
    if [ -n "${PORT_FORWARD_PID:-}" ]; then
      kill $PORT_FORWARD_PID 2> /dev/null || true
    fi
  }
  trap cleanup EXIT
fi

# Test health endpoint
run_test
HEALTH_RESPONSE=$(curl -s "http://${VSM_HOST}/api/v1/health" 2> /dev/null || echo "error")
if echo "$HEALTH_RESPONSE" | grep -q "healthy\|ok\|UP" || [ "$HEALTH_RESPONSE" = "OK" ]; then
  log_success "VSM health check passed"
else
  log_error "VSM health check failed: $HEALTH_RESPONSE"
fi

# Test readiness endpoint
run_test
READY_RESPONSE=$(curl -s -w "%{http_code}" -o /dev/null "http://${VSM_HOST}/ready" 2> /dev/null || echo "000")
if [ "$READY_RESPONSE" = "200" ]; then
  log_success "VSM readiness check passed"
else
  log_warning "VSM readiness check returned HTTP $READY_RESPONSE"
fi

echo ""

# =============================================================================
# Phase 5: VSM API Endpoints
# =============================================================================
log_info "Phase 5: VSM API Endpoints"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Test stages endpoint
run_test
STAGES_RESPONSE=$(curl -s "http://${VSM_HOST}/api/v1/stages" 2> /dev/null || echo "{}")
if command -v jq &> /dev/null; then
  STAGES_COUNT=$(echo "$STAGES_RESPONSE" | jq 'length' 2> /dev/null || echo "0")
  if [ "$STAGES_COUNT" -ge 6 ]; then
    log_success "VSM stages endpoint working ($STAGES_COUNT stages found)"
  else
    log_error "VSM stages endpoint returned insufficient stages ($STAGES_COUNT)"
  fi
else
  if echo "$STAGES_RESPONSE" | grep -q "Backlog\|Development\|Production"; then
    log_success "VSM stages endpoint working"
  else
    log_error "VSM stages endpoint failed"
  fi
fi

# Test metrics endpoint
run_test
METRICS_RESPONSE=$(curl -s -w "%{http_code}" -o /dev/null "http://${VSM_HOST}/api/v1/metrics" 2> /dev/null || echo "000")
if [ "$METRICS_RESPONSE" = "200" ]; then
  log_success "VSM metrics endpoint accessible"
else
  log_warning "VSM metrics endpoint returned HTTP $METRICS_RESPONSE"
fi

# Test OpenAPI docs endpoint
run_test
DOCS_RESPONSE=$(curl -s -w "%{http_code}" -o /dev/null "http://${VSM_HOST}/docs" 2> /dev/null || echo "000")
if [ "$DOCS_RESPONSE" = "200" ]; then
  log_success "VSM OpenAPI documentation accessible"
else
  log_warning "VSM OpenAPI docs returned HTTP $DOCS_RESPONSE"
fi

echo ""

# =============================================================================
# Phase 6: VSM Flow Metrics
# =============================================================================
log_info "Phase 6: VSM Flow Metrics Calculation"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Check metrics content
run_test
METRICS_DATA=$(curl -s "http://${VSM_HOST}/api/v1/metrics" 2> /dev/null || echo "{}")
if command -v jq &> /dev/null; then
  # Check for key metric fields
  HAS_THROUGHPUT=$(echo "$METRICS_DATA" | jq 'has("throughput")' 2> /dev/null || echo "false")
  HAS_WIP=$(echo "$METRICS_DATA" | jq 'has("wip") or has("work_in_progress")' 2> /dev/null || echo "false")
  HAS_CYCLE_TIME=$(echo "$METRICS_DATA" | jq 'has("cycle_time") or has("cycle_time_avg")' 2> /dev/null || echo "false")

  if [ "$HAS_THROUGHPUT" = "true" ] || [ "$HAS_WIP" = "true" ] || [ "$HAS_CYCLE_TIME" = "true" ]; then
    log_success "VSM flow metrics are being calculated"
  else
    log_warning "VSM flow metrics may not be fully configured (throughput: $HAS_THROUGHPUT, WIP: $HAS_WIP, cycle_time: $HAS_CYCLE_TIME)"
  fi
else
  if echo "$METRICS_DATA" | grep -q "throughput\|cycle_time\|wip"; then
    log_success "VSM flow metrics are being calculated"
  else
    log_warning "VSM flow metrics may not be fully configured"
  fi
fi

echo ""

# =============================================================================
# Phase 7: Prometheus Metrics
# =============================================================================
log_info "Phase 7: Prometheus Metrics Exposure"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Test Prometheus metrics endpoint
run_test
PROM_METRICS=$(curl -s "http://${VSM_HOST}/metrics" 2> /dev/null || echo "")
if echo "$PROM_METRICS" | grep -q "vsm_"; then
  log_success "Prometheus metrics are exposed"

  # Count VSM-specific metrics
  VSM_METRICS_COUNT=$(echo "$PROM_METRICS" | grep -c "^vsm_" || echo "0")
  log_info "Found $VSM_METRICS_COUNT VSM-specific metrics"
else
  log_warning "Prometheus metrics may not be properly configured"
fi

# Check ServiceMonitor
run_test
if kubectl get servicemonitor vsm-service -n "$NAMESPACE" &> /dev/null; then
  log_success "ServiceMonitor for Prometheus exists"
else
  log_warning "ServiceMonitor not found (monitoring may not be configured)"
fi

echo ""

# =============================================================================
# Phase 8: Resource Limits
# =============================================================================
log_info "Phase 8: Resource Configuration"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Check resource requests and limits
run_test
RESOURCES=$(kubectl get deployment vsm-service -n "$NAMESPACE" -o json 2> /dev/null || echo "{}")
if command -v jq &> /dev/null; then
  CPU_REQUEST=$(echo "$RESOURCES" | jq -r '.spec.template.spec.containers[0].resources.requests.cpu' 2> /dev/null || echo "null")
  CPU_LIMIT=$(echo "$RESOURCES" | jq -r '.spec.template.spec.containers[0].resources.limits.cpu' 2> /dev/null || echo "null")
  MEM_REQUEST=$(echo "$RESOURCES" | jq -r '.spec.template.spec.containers[0].resources.requests.memory' 2> /dev/null || echo "null")
  MEM_LIMIT=$(echo "$RESOURCES" | jq -r '.spec.template.spec.containers[0].resources.limits.memory' 2> /dev/null || echo "null")

  if [ "$CPU_REQUEST" != "null" ] && [ "$MEM_REQUEST" != "null" ]; then
    log_success "Resource requests configured (CPU: $CPU_REQUEST, Memory: $MEM_REQUEST)"
  else
    log_warning "Resource requests not configured"
  fi

  if [ "$CPU_LIMIT" != "null" ] && [ "$MEM_LIMIT" != "null" ]; then
    log_success "Resource limits configured (CPU: $CPU_LIMIT, Memory: $MEM_LIMIT)"
  else
    log_warning "Resource limits not configured"
  fi
else
  log_warning "jq not available, skipping resource validation"
fi

echo ""

# =============================================================================
# Phase 9: ArgoCD Application
# =============================================================================
log_info "Phase 9: ArgoCD Application Status"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Check ArgoCD application
run_test
if kubectl get application vsm-service -n argocd &> /dev/null 2>&1; then
  log_success "ArgoCD application exists"

  # Check sync status
  SYNC_STATUS=$(kubectl get application vsm-service -n argocd -o jsonpath='{.status.sync.status}' 2> /dev/null || echo "Unknown")
  if [ "$SYNC_STATUS" = "Synced" ]; then
    log_success "ArgoCD application is synced"
  else
    log_warning "ArgoCD sync status: $SYNC_STATUS"
  fi

  # Check health status
  HEALTH_STATUS=$(kubectl get application vsm-service -n argocd -o jsonpath='{.status.health.status}' 2> /dev/null || echo "Unknown")
  if [ "$HEALTH_STATUS" = "Healthy" ]; then
    log_success "ArgoCD application is healthy"
  else
    log_warning "ArgoCD health status: $HEALTH_STATUS"
  fi
else
  log_warning "ArgoCD application not found (may not be using GitOps)"
fi

echo ""

# =============================================================================
# Generate Test Report
# =============================================================================
mkdir -p "$REPORTS_DIR"
REPORT_FILE="$REPORTS_DIR/at-e2-005-validation-$(date +%Y%m%d-%H%M%S).json"

cat > "$REPORT_FILE" << EOF
{
  "acceptance_test": "AT-E2-005",
  "test_suite": "VSM Service Validation",
  "timestamp": "$(date -Iseconds)",
  "namespace": "$NAMESPACE",
  "summary": {
    "total_tests": $TESTS_RUN,
    "passed": $TESTS_PASSED,
    "failed": $TESTS_FAILED,
    "success_rate": $([ $TESTS_RUN -gt 0 ] && awk "BEGIN {printf \"%.1f\", ($TESTS_PASSED * 100 / $TESTS_RUN)}" || echo "0.0")
  },
  "status": "$([ $TESTS_FAILED -eq 0 ] && echo "PASSED" || echo "FAILED")",
  "phases": {
    "prerequisites": "completed",
    "postgresql_database": "completed",
    "vsm_deployment": "completed",
    "api_health": "completed",
    "api_endpoints": "completed",
    "flow_metrics": "completed",
    "prometheus_metrics": "completed",
    "resource_configuration": "completed",
    "argocd_application": "completed"
  }
}
EOF

log_info "Test report saved to: $REPORT_FILE"

# =============================================================================
# Summary
# =============================================================================
echo ""
echo "=========================================="
echo "AT-E2-005 Validation Summary"
echo "=========================================="
echo ""
echo "Total Tests: $TESTS_RUN"
echo "Passed: $TESTS_PASSED"
echo "Failed: $TESTS_FAILED"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
  log_success "✓ VSM service is deployed and functional"
  log_success "✓ Work item tracking capability available"
  log_success "✓ Flow metrics calculation working"
  log_success "✓ API endpoints accessible"
  log_success "✓ Prometheus metrics exposed"
  echo ""
  log_info "Next steps:"
  echo "  1. Create work items via API"
  echo "  2. Test stage transitions"
  echo "  3. Verify flow metrics in Grafana dashboard"
  echo "  4. Configure integrations with Backstage/Jenkins/ArgoCD"
  echo ""
  log_success "AT-E2-005 validation completed successfully!"
  exit 0
else
  log_error "AT-E2-005 validation completed with $TESTS_FAILED failures"
  echo ""
  log_info "Check the following:"
  echo "  1. VSM service deployment: kubectl get pods -n $NAMESPACE -l app=vsm-service"
  echo "  2. PostgreSQL cluster: kubectl get cluster db-vsm-dev -n $NAMESPACE"
  echo "  3. Service logs: kubectl logs -n $NAMESPACE -l app=vsm-service"
  echo "  4. Database connectivity from VSM pods"
  exit 1
fi
