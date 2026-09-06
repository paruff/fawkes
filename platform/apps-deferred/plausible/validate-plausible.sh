#!/bin/bash
# ============================================================================
# FILE: platform/apps/plausible/validate-plausible.sh
# PURPOSE: Validate Plausible Analytics deployment
# USAGE: ./validate-plausible.sh [--namespace fawkes]
# ============================================================================

set -euo pipefail

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default values
NAMESPACE="${NAMESPACE:-fawkes}"
VERBOSE=${VERBOSE:-false}

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
    *)
      echo "Unknown option: $1"
      echo "Usage: $0 [--namespace fawkes] [--verbose]"
      exit 1
      ;;
  esac
done

echo "=================================================="
echo "Validating Plausible Analytics Deployment"
echo "Namespace: $NAMESPACE"
echo "=================================================="
echo ""

# Test counter
TESTS_PASSED=0
TESTS_FAILED=0

# Helper functions
pass() {
  echo -e "${GREEN}✓${NC} $1"
  ((TESTS_PASSED++))
}

fail() {
  echo -e "${RED}✗${NC} $1"
  ((TESTS_FAILED++))
}

warn() {
  echo -e "${YELLOW}⚠${NC} $1"
}

info() {
  echo -e "ℹ $1"
}

# Test 1: Check PostgreSQL cluster
echo "Test 1: PostgreSQL Cluster"
if kubectl get cluster db-plausible-dev -n "$NAMESPACE" &> /dev/null; then
  STATUS=$(kubectl get cluster db-plausible-dev -n "$NAMESPACE" -o jsonpath='{.status.phase}')
  if [[ "$STATUS" == "Cluster in healthy state" ]]; then
    pass "PostgreSQL cluster is healthy"
  else
    fail "PostgreSQL cluster status: $STATUS"
  fi
else
  fail "PostgreSQL cluster db-plausible-dev not found"
fi

# Test 2: Check ClickHouse StatefulSet
echo "Test 2: ClickHouse StatefulSet"
if kubectl get statefulset plausible-clickhouse -n "$NAMESPACE" &> /dev/null; then
  READY=$(kubectl get statefulset plausible-clickhouse -n "$NAMESPACE" -o jsonpath='{.status.readyReplicas}')
  DESIRED=$(kubectl get statefulset plausible-clickhouse -n "$NAMESPACE" -o jsonpath='{.spec.replicas}')
  if [[ "$READY" == "$DESIRED" ]]; then
    pass "ClickHouse StatefulSet is ready ($READY/$DESIRED)"
  else
    fail "ClickHouse StatefulSet not ready ($READY/$DESIRED)"
  fi
else
  fail "ClickHouse StatefulSet not found"
fi

# Test 3: Check Plausible Deployment
echo "Test 3: Plausible Deployment"
if kubectl get deployment plausible -n "$NAMESPACE" &> /dev/null; then
  READY=$(kubectl get deployment plausible -n "$NAMESPACE" -o jsonpath='{.status.readyReplicas}')
  DESIRED=$(kubectl get deployment plausible -n "$NAMESPACE" -o jsonpath='{.spec.replicas}')
  if [[ "$READY" == "$DESIRED" ]]; then
    pass "Plausible deployment is ready ($READY/$DESIRED)"
  else
    fail "Plausible deployment not ready ($READY/$DESIRED)"
  fi
else
  fail "Plausible deployment not found"
fi

# Test 4: Check Services
echo "Test 4: Services"
SERVICES=("plausible" "plausible-clickhouse")
for svc in "${SERVICES[@]}"; do
  if kubectl get service "$svc" -n "$NAMESPACE" &> /dev/null; then
    CLUSTER_IP=$(kubectl get service "$svc" -n "$NAMESPACE" -o jsonpath='{.spec.clusterIP}')
    pass "Service $svc exists (ClusterIP: $CLUSTER_IP)"
  else
    fail "Service $svc not found"
  fi
done

# Test 5: Check Ingress
echo "Test 5: Ingress"
if kubectl get ingress plausible -n "$NAMESPACE" &> /dev/null; then
  HOSTS=$(kubectl get ingress plausible -n "$NAMESPACE" -o jsonpath='{.spec.rules[*].host}')
  pass "Ingress configured for host(s): $HOSTS"
else
  fail "Ingress plausible not found"
fi

# Test 6: Check ConfigMaps
echo "Test 6: ConfigMaps"
CONFIGMAPS=("plausible-config" "clickhouse-config")
for cm in "${CONFIGMAPS[@]}"; do
  if kubectl get configmap "$cm" -n "$NAMESPACE" &> /dev/null; then
    pass "ConfigMap $cm exists"
  else
    fail "ConfigMap $cm not found"
  fi
done

# Test 7: Check Secrets
echo "Test 7: Secrets"
SECRETS=("plausible-secret" "db-plausible-credentials")
for secret in "${SECRETS[@]}"; do
  if kubectl get secret "$secret" -n "$NAMESPACE" &> /dev/null; then
    pass "Secret $secret exists"
  else
    fail "Secret $secret not found"
  fi
done

# Test 8: Check Pod Health
echo "Test 8: Pod Health"
if kubectl get pods -n "$NAMESPACE" -l app=plausible --no-headers 2> /dev/null | grep -q .; then
  UNHEALTHY=$(kubectl get pods -n "$NAMESPACE" -l app=plausible --no-headers | grep -v Running | grep -v Completed || true)
  if [[ -z "$UNHEALTHY" ]]; then
    pass "All Plausible pods are healthy"
  else
    fail "Some pods are unhealthy:"
    echo "$UNHEALTHY"
  fi
else
  fail "No Plausible pods found"
fi

# Test 9: Health Endpoint
echo "Test 9: Plausible Health Endpoint"
POD=$(kubectl get pods -n "$NAMESPACE" -l app=plausible,component=analytics --no-headers -o custom-columns=":metadata.name" | head -1)
if [[ -n "$POD" ]]; then
  if kubectl exec -n "$NAMESPACE" "$POD" -- wget -q -O- http://localhost:8000/api/health &> /dev/null; then
    pass "Plausible health endpoint responding"
  else
    fail "Plausible health endpoint not responding"
  fi
else
  fail "No Plausible pod found to test health endpoint"
fi

# Test 10: ClickHouse Health
echo "Test 10: ClickHouse Health"
CH_POD=$(kubectl get pods -n "$NAMESPACE" -l component=clickhouse --no-headers -o custom-columns=":metadata.name" | head -1)
if [[ -n "$CH_POD" ]]; then
  if kubectl exec -n "$NAMESPACE" "$CH_POD" -- wget -q -O- http://localhost:8123/ping &> /dev/null; then
    pass "ClickHouse health endpoint responding"
  else
    fail "ClickHouse health endpoint not responding"
  fi
else
  fail "No ClickHouse pod found to test health endpoint"
fi

# Test 11: Resource Usage
echo "Test 11: Resource Usage"
if command -v kubectl-top &> /dev/null || kubectl top pods -h &> /dev/null; then
  PLAUSIBLE_PODS=$(kubectl get pods -n "$NAMESPACE" -l app=plausible --no-headers -o custom-columns=":metadata.name")
  for pod in $PLAUSIBLE_PODS; do
    CPU=$(kubectl top pod "$pod" -n "$NAMESPACE" --no-headers 2> /dev/null | awk '{print $2}' || echo "N/A")
    MEM=$(kubectl top pod "$pod" -n "$NAMESPACE" --no-headers 2> /dev/null | awk '{print $3}' || echo "N/A")
    info "Pod $pod - CPU: $CPU, Memory: $MEM"
  done
  pass "Resource metrics collected"
else
  warn "kubectl top not available, skipping resource usage check"
fi

# Test 12: Backstage Integration
echo "Test 12: Backstage Integration"
if kubectl get configmap backstage-app-config -n "$NAMESPACE" &> /dev/null; then
  if kubectl get configmap backstage-app-config -n "$NAMESPACE" -o yaml | grep -q "plausible"; then
    pass "Backstage configured with Plausible analytics"
  else
    fail "Plausible not configured in Backstage app-config"
  fi
else
  warn "Backstage app-config not found, skipping integration check"
fi

# Summary
echo ""
echo "=================================================="
echo "Validation Summary"
echo "=================================================="
echo -e "Tests Passed: ${GREEN}${TESTS_PASSED}${NC}"
echo -e "Tests Failed: ${RED}${TESTS_FAILED}${NC}"
echo ""

if [[ $TESTS_FAILED -eq 0 ]]; then
  echo -e "${GREEN}✓ All validation tests passed!${NC}"
  echo ""
  echo "Plausible Analytics is ready to use:"
  echo "  Dashboard: https://plausible.fawkes.idp"
  echo "  Default Login: admin@fawkes.local / changeme-admin-password"
  echo ""
  echo "Next steps:"
  echo "  1. Change the default admin password"
  echo "  2. Add sites to track (e.g., backstage.fawkes.idp)"
  echo "  3. Configure custom goals and events"
  echo "  4. Set up data retention policies"
  exit 0
else
  echo -e "${RED}✗ Some validation tests failed${NC}"
  echo ""
  echo "Troubleshooting:"
  echo "  1. Check pod logs: kubectl logs -n $NAMESPACE -l app=plausible"
  echo "  2. Describe resources: kubectl describe pod -n $NAMESPACE -l app=plausible"
  echo "  3. Check events: kubectl get events -n $NAMESPACE --sort-by='.lastTimestamp'"
  exit 1
fi
