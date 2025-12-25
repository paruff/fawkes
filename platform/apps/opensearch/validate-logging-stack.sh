#!/bin/bash
# ============================================================================
# FILE: platform/apps/opensearch/validate-logging-stack.sh
# PURPOSE: Validate OpenSearch and OpenTelemetry Collector logging setup
# USAGE: ./validate-logging-stack.sh [--namespace monitoring]
# ============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default values
MONITORING_NAMESPACE="monitoring"
LOGGING_NAMESPACE="logging"
ARGOCD_NAMESPACE="fawkes"

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --namespace)
      MONITORING_NAMESPACE="$2"
      shift 2
      ;;
    --logging-namespace)
      LOGGING_NAMESPACE="$2"
      shift 2
      ;;
    --argocd-namespace)
      ARGOCD_NAMESPACE="$2"
      shift 2
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

echo "=========================================="
echo "Logging Stack Validation"
echo "=========================================="
echo "Monitoring Namespace: $MONITORING_NAMESPACE"
echo "Logging Namespace: $LOGGING_NAMESPACE"
echo "ArgoCD Namespace: $ARGOCD_NAMESPACE"
echo ""

# Track test results
PASSED=0
FAILED=0

# Helper functions
check_pass() {
  echo -e "${GREEN}✓ PASS${NC}: $1"
  ((PASSED++))
}

check_fail() {
  echo -e "${RED}✗ FAIL${NC}: $1"
  ((FAILED++))
}

check_warn() {
  echo -e "${YELLOW}⚠ WARN${NC}: $1"
}

# ============================================================================
# Test 1: Check OpenTelemetry Collector DaemonSet
# ============================================================================
echo "Test 1: OpenTelemetry Collector DaemonSet"
echo "------------------------------------------"

if kubectl get daemonset -n "$MONITORING_NAMESPACE" -l app.kubernetes.io/name=opentelemetry-collector &>/dev/null; then
  DESIRED=$(kubectl get daemonset -n "$MONITORING_NAMESPACE" -l app.kubernetes.io/name=opentelemetry-collector -o jsonpath='{.items[0].status.desiredNumberScheduled}')
  READY=$(kubectl get daemonset -n "$MONITORING_NAMESPACE" -l app.kubernetes.io/name=opentelemetry-collector -o jsonpath='{.items[0].status.numberReady}')

  if [ "$DESIRED" -eq "$READY" ] && [ "$READY" -gt 0 ]; then
    check_pass "OpenTelemetry Collector DaemonSet is running ($READY/$DESIRED pods ready)"
  else
    check_fail "OpenTelemetry Collector DaemonSet not fully ready ($READY/$DESIRED pods ready)"
  fi
else
  check_fail "OpenTelemetry Collector DaemonSet not found"
fi

echo ""

# ============================================================================
# Test 2: Check OpenTelemetry Collector Health
# ============================================================================
echo "Test 2: OpenTelemetry Collector Health Endpoints"
echo "-------------------------------------------------"

OTEL_POD=$(kubectl get pods -n "$MONITORING_NAMESPACE" -l app.kubernetes.io/name=opentelemetry-collector -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)

if [ -n "$OTEL_POD" ]; then
  # Try curl first, fallback to wget if not available
  if kubectl exec -n "$MONITORING_NAMESPACE" "$OTEL_POD" -- sh -c "command -v curl" &>/dev/null; then
    HTTP_CLIENT="curl -s"
  elif kubectl exec -n "$MONITORING_NAMESPACE" "$OTEL_POD" -- sh -c "command -v wget" &>/dev/null; then
    HTTP_CLIENT="wget -qO-"
  else
    check_fail "Neither curl nor wget available in OpenTelemetry Collector pod"
    HTTP_CLIENT=""
  fi

  if [ -n "$HTTP_CLIENT" ]; then
    if kubectl exec -n "$MONITORING_NAMESPACE" "$OTEL_POD" -- sh -c "$HTTP_CLIENT http://localhost:13133" &>/dev/null; then
      check_pass "OpenTelemetry Collector health endpoint is accessible"
    else
      check_fail "OpenTelemetry Collector health endpoint is not accessible"
    fi

    if kubectl exec -n "$MONITORING_NAMESPACE" "$OTEL_POD" -- sh -c "$HTTP_CLIENT http://localhost:55679/debug/servicez" &>/dev/null; then
      check_pass "OpenTelemetry Collector zpages endpoint is accessible"
    else
      check_fail "OpenTelemetry Collector zpages endpoint is not accessible"
    fi
  fi
else
  check_fail "No OpenTelemetry Collector pod found"
fi

echo ""

# ============================================================================
# Test 3: Check OpenSearch Cluster
# ============================================================================
echo "Test 3: OpenSearch Cluster"
echo "--------------------------"

if kubectl get application -n "$ARGOCD_NAMESPACE" opensearch &>/dev/null; then
  APP_HEALTH=$(kubectl get application -n "$ARGOCD_NAMESPACE" opensearch -o jsonpath='{.status.health.status}')
  APP_SYNC=$(kubectl get application -n "$ARGOCD_NAMESPACE" opensearch -o jsonpath='{.status.sync.status}')

  if [ "$APP_HEALTH" == "Healthy" ]; then
    check_pass "OpenSearch ArgoCD Application is Healthy"
  else
    check_fail "OpenSearch ArgoCD Application health: $APP_HEALTH"
  fi

  if [ "$APP_SYNC" == "Synced" ]; then
    check_pass "OpenSearch ArgoCD Application is Synced"
  else
    check_fail "OpenSearch ArgoCD Application sync: $APP_SYNC"
  fi
else
  check_warn "OpenSearch ArgoCD Application not found (deployment pending)"
fi

if kubectl get statefulset -n "$LOGGING_NAMESPACE" opensearch-cluster-master &>/dev/null; then
  DESIRED=$(kubectl get statefulset -n "$LOGGING_NAMESPACE" opensearch-cluster-master -o jsonpath='{.status.replicas}')
  READY=$(kubectl get statefulset -n "$LOGGING_NAMESPACE" opensearch-cluster-master -o jsonpath='{.status.readyReplicas}')

  if [ "$DESIRED" -eq "$READY" ] && [ "$READY" -gt 0 ]; then
    check_pass "OpenSearch StatefulSet is running ($READY/$DESIRED pods ready)"
  else
    check_fail "OpenSearch StatefulSet not fully ready ($READY/$DESIRED pods ready)"
  fi
else
  check_warn "OpenSearch StatefulSet not found (deployment pending)"
fi

echo ""

# ============================================================================
# Test 4: Check OpenSearch Cluster Health
# ============================================================================
echo "Test 4: OpenSearch Cluster Health"
echo "----------------------------------"

OPENSEARCH_POD=$(kubectl get pods -n "$LOGGING_NAMESPACE" -l app=opensearch-cluster-master -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)

if [ -n "$OPENSEARCH_POD" ]; then
  # Check if jq is available for robust JSON parsing
  if command -v jq &> /dev/null; then
    CLUSTER_HEALTH=$(kubectl exec -n "$LOGGING_NAMESPACE" "$OPENSEARCH_POD" -- curl -s http://localhost:9200/_cluster/health 2>/dev/null | jq -r '.status' 2>/dev/null)
  else
    # Fallback to grep parsing if jq is not available
    CLUSTER_HEALTH=$(kubectl exec -n "$LOGGING_NAMESPACE" "$OPENSEARCH_POD" -- curl -s http://localhost:9200/_cluster/health 2>/dev/null | grep -o '"status":"[^"]*"' | cut -d'"' -f4)
  fi

  if [ "$CLUSTER_HEALTH" == "green" ]; then
    check_pass "OpenSearch cluster health is GREEN"
  elif [ "$CLUSTER_HEALTH" == "yellow" ]; then
    check_warn "OpenSearch cluster health is YELLOW (acceptable for single-node)"
  else
    check_fail "OpenSearch cluster health is $CLUSTER_HEALTH"
  fi

  # Check indices
  INDICES=$(kubectl exec -n "$LOGGING_NAMESPACE" "$OPENSEARCH_POD" -- curl -s http://localhost:9200/_cat/indices 2>/dev/null | wc -l)
  if [ "$INDICES" -gt 0 ]; then
    check_pass "OpenSearch has $INDICES indices"
  else
    check_warn "OpenSearch has no indices yet (logs may not have been ingested)"
  fi
else
  check_warn "OpenSearch pod not found (deployment pending)"
fi

echo ""

# ============================================================================
# Test 5: Check OpenSearch Dashboards
# ============================================================================
echo "Test 5: OpenSearch Dashboards"
echo "------------------------------"

if kubectl get application -n "$ARGOCD_NAMESPACE" opensearch-dashboards &>/dev/null; then
  APP_HEALTH=$(kubectl get application -n "$ARGOCD_NAMESPACE" opensearch-dashboards -o jsonpath='{.status.health.status}')

  if [ "$APP_HEALTH" == "Healthy" ]; then
    check_pass "OpenSearch Dashboards ArgoCD Application is Healthy"
  else
    check_fail "OpenSearch Dashboards ArgoCD Application health: $APP_HEALTH"
  fi
else
  check_warn "OpenSearch Dashboards ArgoCD Application not found"
fi

if kubectl get deployment -n "$LOGGING_NAMESPACE" opensearch-dashboards &>/dev/null; then
  DESIRED=$(kubectl get deployment -n "$LOGGING_NAMESPACE" opensearch-dashboards -o jsonpath='{.status.replicas}')
  READY=$(kubectl get deployment -n "$LOGGING_NAMESPACE" opensearch-dashboards -o jsonpath='{.status.readyReplicas}')

  if [ "$DESIRED" -eq "$READY" ] && [ "$READY" -gt 0 ]; then
    check_pass "OpenSearch Dashboards Deployment is running ($READY/$DESIRED pods ready)"
  else
    check_fail "OpenSearch Dashboards Deployment not fully ready ($READY/$DESIRED pods ready)"
  fi
else
  check_warn "OpenSearch Dashboards Deployment not found"
fi

echo ""

# ============================================================================
# Test 6: Check Log Pipeline Configuration
# ============================================================================
echo "Test 6: OpenTelemetry Log Pipeline Configuration"
echo "------------------------------------------------"

if [ -n "$OTEL_POD" ]; then
  # Check if filelog receiver is configured
  if kubectl exec -n "$MONITORING_NAMESPACE" "$OTEL_POD" -- sh -c "env | grep -i filelog" &>/dev/null || \
     kubectl logs -n "$MONITORING_NAMESPACE" "$OTEL_POD" --tail=100 2>/dev/null | grep -i "filelog" &>/dev/null; then
    check_pass "Filelog receiver is configured"
  else
    check_warn "Filelog receiver configuration not verified"
  fi

  # Check if OpenSearch exporter is configured
  if kubectl logs -n "$MONITORING_NAMESPACE" "$OTEL_POD" --tail=100 2>/dev/null | grep -i "opensearch" &>/dev/null; then
    check_pass "OpenSearch exporter is configured"
  else
    check_warn "OpenSearch exporter configuration not verified"
  fi
fi

echo ""

# ============================================================================
# Test 7: Check ISM Policy
# ============================================================================
echo "Test 7: Index State Management (ISM) Policy"
echo "-------------------------------------------"

if [ -n "$OPENSEARCH_POD" ]; then
  ISM_POLICY=$(kubectl exec -n "$LOGGING_NAMESPACE" "$OPENSEARCH_POD" -- \
    curl -s http://localhost:9200/_plugins/_ism/policies/fawkes-log-retention-policy 2>/dev/null)

  if echo "$ISM_POLICY" | grep -q "fawkes-log-retention-policy"; then
    check_pass "ISM retention policy (30 days) is configured"
  else
    check_warn "ISM retention policy not found (will be applied via PostSync hook)"
  fi
fi

echo ""

# ============================================================================
# Test 8: Check Index Templates
# ============================================================================
echo "Test 8: Index Templates"
echo "----------------------"

if [ -n "$OPENSEARCH_POD" ]; then
  TEMPLATES=$(kubectl exec -n "$LOGGING_NAMESPACE" "$OPENSEARCH_POD" -- \
    curl -s http://localhost:9200/_index_template 2>/dev/null | grep -o '"name":"[^"]*"' | wc -l)

  if [ "$TEMPLATES" -gt 0 ]; then
    check_pass "Index templates are configured ($TEMPLATES templates found)"
  else
    check_warn "No index templates found (will be applied via PostSync hook)"
  fi
fi

echo ""

# ============================================================================
# Test 9: Check Log Ingestion
# ============================================================================
echo "Test 9: Log Ingestion (Sample Test)"
echo "-----------------------------------"

if [ -n "$OPENSEARCH_POD" ]; then
  # Check for otel-logs indices
  OTEL_LOGS=$(kubectl exec -n "$LOGGING_NAMESPACE" "$OPENSEARCH_POD" -- \
    curl -s "http://localhost:9200/_cat/indices/otel-logs-*" 2>/dev/null | wc -l)

  if [ "$OTEL_LOGS" -gt 0 ]; then
    check_pass "OTLP log indices found (logs are being ingested)"

    # Check document count
    DOC_COUNT=$(kubectl exec -n "$LOGGING_NAMESPACE" "$OPENSEARCH_POD" -- \
      curl -s "http://localhost:9200/otel-logs-*/_count" 2>/dev/null | grep -o '"count":[0-9]*' | cut -d':' -f2)

    if [ -n "$DOC_COUNT" ] && [ "$DOC_COUNT" -gt 0 ]; then
      check_pass "Log documents found in OpenSearch ($DOC_COUNT documents)"
    else
      check_warn "No log documents found yet (logs may be in transit)"
    fi
  else
    check_warn "No OTLP log indices found yet (logs may not have been ingested)"
  fi

  # Check for fawkes-logs indices
  FAWKES_LOGS=$(kubectl exec -n "$LOGGING_NAMESPACE" "$OPENSEARCH_POD" -- \
    curl -s "http://localhost:9200/_cat/indices/fawkes-logs-*" 2>/dev/null | wc -l)

  if [ "$FAWKES_LOGS" -gt 0 ]; then
    check_pass "Fawkes log indices found"
  fi
fi

echo ""

# ============================================================================
# Test 10: Check Kubernetes Metadata Enrichment
# ============================================================================
echo "Test 10: Kubernetes Metadata Enrichment"
echo "---------------------------------------"

if [ -n "$OPENSEARCH_POD" ] && [ -n "$DOC_COUNT" ] && [ "$DOC_COUNT" -gt 0 ]; then
  # Sample a log document and check for k8s attributes
  SAMPLE_LOG=$(kubectl exec -n "$LOGGING_NAMESPACE" "$OPENSEARCH_POD" -- \
    curl -s "http://localhost:9200/otel-logs-*/_search?size=1" 2>/dev/null)

  if echo "$SAMPLE_LOG" | grep -q "k8s.namespace.name"; then
    check_pass "Logs contain k8s.namespace.name metadata"
  else
    check_warn "Sample log does not contain k8s.namespace.name"
  fi

  if echo "$SAMPLE_LOG" | grep -q "k8s.pod.name"; then
    check_pass "Logs contain k8s.pod.name metadata"
  else
    check_warn "Sample log does not contain k8s.pod.name"
  fi

  if echo "$SAMPLE_LOG" | grep -q "k8s.container.name"; then
    check_pass "Logs contain k8s.container.name metadata"
  else
    check_warn "Sample log does not contain k8s.container.name"
  fi
fi

echo ""

# ============================================================================
# Summary
# ============================================================================
echo "=========================================="
echo "Validation Summary"
echo "=========================================="
echo -e "${GREEN}Passed: $PASSED${NC}"
echo -e "${RED}Failed: $FAILED${NC}"
echo ""

if [ $FAILED -eq 0 ]; then
  echo -e "${GREEN}✓ All critical tests passed!${NC}"
  echo ""
  echo "Next steps:"
  echo "1. Access OpenSearch Dashboards at: http://opensearch-dashboards.127.0.0.1.nip.io"
  echo "2. Create index pattern: otel-logs-*"
  echo "3. View logs in Discover tab"
  echo "4. Run BDD tests: behave tests/bdd/features/centralized-logging.feature --tags=@local"
  exit 0
else
  echo -e "${RED}✗ Some tests failed. Please review the output above.${NC}"
  echo ""
  echo "Troubleshooting:"
  echo "1. Check OpenTelemetry Collector logs: kubectl logs -n $MONITORING_NAMESPACE -l app.kubernetes.io/name=opentelemetry-collector"
  echo "2. Check OpenSearch logs: kubectl logs -n $LOGGING_NAMESPACE -l app=opensearch-cluster-master"
  echo "3. Verify ArgoCD sync: kubectl get application -n $ARGOCD_NAMESPACE opensearch opensearch-dashboards"
  exit 1
fi
