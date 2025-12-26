#!/bin/bash
# =============================================================================
# Script: validate-analytics-dashboard.sh
# Purpose: Validation script for Analytics Dashboard Service (Issue #101)
# Usage: ./scripts/validate-analytics-dashboard.sh [--namespace NAMESPACE]
# Exit Codes: 0=success, 1=validation failed, 2=missing prerequisites
# =============================================================================

set -euo pipefail

# Get script directory for sourcing libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"

# Source error handling library
# shellcheck source=lib/error_handling.sh
source "${SCRIPT_DIR}/lib/error_handling.sh"

# Configuration
NAMESPACE="${NAMESPACE:-fawkes}"
SERVICE_NAME="analytics-dashboard"
API_URL="http://${SERVICE_NAME}.${NAMESPACE}.svc:8000"

# Test counter
TESTS_PASSED=0
TESTS_FAILED=0

# =============================================================================
# Cleanup Functions
# =============================================================================

cleanup() {
  log_debug "Performing cleanup..."
}

# Register cleanup function
register_cleanup_function cleanup

# =============================================================================
# Main Script
# =============================================================================

log_info "=== Analytics Dashboard Validation ==="
log_info "Namespace: $NAMESPACE"
log_info "Service: $SERVICE_NAME"
echo ""

# Check prerequisites
require_command "kubectl" "kubectl is required but not installed"
require_command "jq" "jq is required but not installed"

# Function to run a test
run_test() {
  local test_name="$1"
  local test_command="$2"

  echo -n "Testing: $test_name... "
  if eval "$test_command" > /dev/null 2>&1; then
    log_success "PASSED"
    ((TESTS_PASSED++))
    return 0
  else
    log_error "FAILED"
    ((TESTS_FAILED++))
    return 1
  fi
}

# 1. Check if namespace exists
show_progress "1. Checking namespace..."
run_test "Namespace exists" "kubectl get namespace $NAMESPACE"

# 2. Check deployment
show_progress "2. Checking deployment..."
run_test "Deployment exists" "kubectl get deployment $SERVICE_NAME -n $NAMESPACE"
run_test "Deployment has correct replicas" "[ \$(kubectl get deployment $SERVICE_NAME -n $NAMESPACE -o jsonpath='{.spec.replicas}') -eq 2 ]"

# 3. Check pods
show_progress "3. Checking pods..."
run_test "Pods are running" "kubectl get pods -n $NAMESPACE -l app=$SERVICE_NAME | grep -q Running"
run_test "All pods are ready" "[ \$(kubectl get pods -n $NAMESPACE -l app=$SERVICE_NAME -o jsonpath='{.items[*].status.containerStatuses[*].ready}' | grep -o true | wc -l) -ge 2 ]"

# 4. Check service
show_progress "4. Checking service..."
run_test "Service exists" "kubectl get service $SERVICE_NAME -n $NAMESPACE"
run_test "Service has endpoints" "kubectl get endpoints $SERVICE_NAME -n $NAMESPACE | grep -q $SERVICE_NAME"

# 5. Check ConfigMap
show_progress "5. Checking configuration..."
run_test "ConfigMap exists" "kubectl get configmap ${SERVICE_NAME}-config -n $NAMESPACE"

# 6. Check ServiceMonitor
show_progress "6. Checking monitoring..."
run_test "ServiceMonitor exists" "kubectl get servicemonitor $SERVICE_NAME -n $NAMESPACE"

# 7. Check Ingress
show_progress "7. Checking ingress..."
run_test "Ingress exists" "kubectl get ingress $SERVICE_NAME -n $NAMESPACE"

# 8. Check PodDisruptionBudget
show_progress "8. Checking high availability..."
run_test "PodDisruptionBudget exists" "kubectl get pdb $SERVICE_NAME -n $NAMESPACE"

# 9. Test health endpoint
show_progress "9. Testing health endpoint..."
POD_NAME=$(kubectl get pods -n $NAMESPACE -l app=$SERVICE_NAME -o jsonpath='{.items[0].metadata.name}')
if [ -n "$POD_NAME" ]; then
  run_test "Health endpoint responds" "kubectl exec -n $NAMESPACE $POD_NAME -- wget -q -O- http://localhost:8000/health | grep -q healthy"
fi

# 10. Test API endpoints
show_progress "10. Testing API endpoints..."
if [ -n "$POD_NAME" ]; then
  run_test "Dashboard endpoint responds" "kubectl exec -n $NAMESPACE $POD_NAME -- wget -q -O- 'http://localhost:8000/api/v1/dashboard?time_range=7d' | grep -q usage_trends"
  run_test "Usage trends endpoint responds" "kubectl exec -n $NAMESPACE $POD_NAME -- wget -q -O- 'http://localhost:8000/api/v1/usage-trends?time_range=7d' | grep -q total_users"
  run_test "Feature adoption endpoint responds" "kubectl exec -n $NAMESPACE $POD_NAME -- wget -q -O- 'http://localhost:8000/api/v1/feature-adoption?time_range=30d' | grep -q features"
  run_test "Experiment results endpoint responds" "kubectl exec -n $NAMESPACE $POD_NAME -- wget -q -O- 'http://localhost:8000/api/v1/experiment-results' | grep -q experiment_id"
  run_test "User segments endpoint responds" "kubectl exec -n $NAMESPACE $POD_NAME -- wget -q -O- 'http://localhost:8000/api/v1/user-segments?time_range=30d' | grep -q segments"
  run_test "Funnel endpoint responds" "kubectl exec -n $NAMESPACE $POD_NAME -- wget -q -O- 'http://localhost:8000/api/v1/funnel/onboarding?time_range=30d' | grep -q steps"
fi

# 11. Test metrics endpoint
show_progress "11. Testing Prometheus metrics..."
if [ -n "$POD_NAME" ]; then
  run_test "Metrics endpoint accessible" "kubectl exec -n $NAMESPACE $POD_NAME -- wget -q -O- http://localhost:8000/metrics | grep -q analytics_"
  run_test "Usage metrics present" "kubectl exec -n $NAMESPACE $POD_NAME -- wget -q -O- http://localhost:8000/metrics | grep -q analytics_total_users"
  run_test "Feature metrics present" "kubectl exec -n $NAMESPACE $POD_NAME -- wget -q -O- http://localhost:8000/metrics | grep -q analytics_feature_adoption_rate"
  run_test "Experiment metrics present" "kubectl exec -n $NAMESPACE $POD_NAME -- wget -q -O- http://localhost:8000/metrics | grep -q analytics_active_experiments"
  run_test "Segment metrics present" "kubectl exec -n $NAMESPACE $POD_NAME -- wget -q -O- http://localhost:8000/metrics | grep -q analytics_segment_size"
  run_test "Funnel metrics present" "kubectl exec -n $NAMESPACE $POD_NAME -- wget -q -O- http://localhost:8000/metrics | grep -q analytics_funnel_conversion_rate"
fi

# 12. Check resource limits
show_progress "12. Checking resource configuration..."
run_test "CPU requests set" "kubectl get deployment $SERVICE_NAME -n $NAMESPACE -o jsonpath='{.spec.template.spec.containers[0].resources.requests.cpu}' | grep -q 200m"
run_test "Memory requests set" "kubectl get deployment $SERVICE_NAME -n $NAMESPACE -o jsonpath='{.spec.template.spec.containers[0].resources.requests.memory}' | grep -q 256Mi"
run_test "CPU limits set" "kubectl get deployment $SERVICE_NAME -n $NAMESPACE -o jsonpath='{.spec.template.spec.containers[0].resources.limits.cpu}' | grep -q 500m"
run_test "Memory limits set" "kubectl get deployment $SERVICE_NAME -n $NAMESPACE -o jsonpath='{.spec.template.spec.containers[0].resources.limits.memory}' | grep -q 512Mi"

# 13. Check security context
show_progress "13. Checking security configuration..."
run_test "Non-root user" "kubectl get deployment $SERVICE_NAME -n $NAMESPACE -o jsonpath='{.spec.template.spec.securityContext.runAsNonRoot}' | grep -q true"
run_test "Read-only root filesystem" "kubectl get deployment $SERVICE_NAME -n $NAMESPACE -o jsonpath='{.spec.template.spec.containers[0].securityContext.readOnlyRootFilesystem}' | grep -q true"
run_test "No privilege escalation" "kubectl get deployment $SERVICE_NAME -n $NAMESPACE -o jsonpath='{.spec.template.spec.containers[0].securityContext.allowPrivilegeEscalation}' | grep -q false"

# 14. Check probes
show_progress "14. Checking health probes..."
run_test "Liveness probe configured" "kubectl get deployment $SERVICE_NAME -n $NAMESPACE -o yaml | grep -q livenessProbe"
run_test "Readiness probe configured" "kubectl get deployment $SERVICE_NAME -n $NAMESPACE -o yaml | grep -q readinessProbe"

# 15. Check Grafana dashboard
show_progress "15. Checking Grafana dashboard..."
run_test "Dashboard ConfigMap exists" "kubectl get configmap analytics-dashboard -n monitoring"
run_test "Dashboard has correct label" "kubectl get configmap analytics-dashboard -n monitoring -o jsonpath='{.metadata.labels.grafana_dashboard}' | grep -q 1"

# 16. Test export functionality
show_progress "16. Testing export functionality..."
if [ -n "$POD_NAME" ]; then
  run_test "JSON export works" "kubectl exec -n $NAMESPACE $POD_NAME -- wget -q -O- 'http://localhost:8000/api/v1/export/json?time_range=7d' | grep -q timestamp"
fi

# 17. Check pod anti-affinity
show_progress "17. Checking high availability configuration..."
run_test "Pod anti-affinity configured" "kubectl get deployment $SERVICE_NAME -n $NAMESPACE -o yaml | grep -q podAntiAffinity"

# 18. Verify labels
show_progress "18. Checking labels..."
run_test "App label set" "kubectl get deployment $SERVICE_NAME -n $NAMESPACE -o jsonpath='{.metadata.labels.app}' | grep -q $SERVICE_NAME"
run_test "Component label set" "kubectl get deployment $SERVICE_NAME -n $NAMESPACE -o jsonpath='{.metadata.labels.component}' | grep -q analytics"

# Summary
echo ""
show_section "Validation Summary"
log_info "Tests Passed: $TESTS_PASSED"
log_info "Tests Failed: $TESTS_FAILED"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
  log_success "All validation tests passed!"
  exit 0
else
  log_error "Some validation tests failed."
  exit 1
fi
