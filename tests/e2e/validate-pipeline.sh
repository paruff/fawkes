#!/usr/bin/env bash
# =============================================================================
# E2E Pipeline Validation — Tracer Bullet
# =============================================================================
# Validates the full deployment pipeline:
# 1. Service is running in cluster
# 2. HTTP endpoints respond correctly
# 3. Prometheus metrics are exposed
# 4. OTEL traces are being generated (via Tempo API)
#
# Prerequisites:
#   - kubectl configured with cluster access
#   - curl, jq installed
#   - Service deployed to fawkes namespace
#
# Usage:
#   ./tests/e2e/validate-pipeline.sh [NAMESPACE] [SERVICE_NAME]
# =============================================================================

set -euo pipefail

# Prerequisite check
for cmd in curl jq kubectl; do
  command -v "$cmd" >/dev/null 2>&1 || { echo "❌ Missing required tool: $cmd"; exit 1; }
done

NAMESPACE="${1:-fawkes}"
SERVICE="${2:-tracer-bullet}"
BASE_URL="http://${SERVICE}.${NAMESPACE}.svc.cluster.local"
TEMPO_URL="http://tempo.monitoring.svc.cluster.local:3200"
PASS=0
FAIL=0

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
pass() { echo "  ✅ $1"; PASS=$((PASS + 1)); }
fail() { echo "  ❌ $1"; FAIL=$((FAIL + 1)); }

check_endpoint() {
  local path="$1"
  local expected_status="${2:-200}"
  local status
  status=$(curl -s -o /dev/null -w "%{http_code}" "${BASE_URL}${path}" 2>/dev/null || echo "000")
  if [ "$status" = "$expected_status" ]; then
    pass "GET ${path} → ${status}"
  else
    fail "GET ${path} → ${status} (expected ${expected_status})"
  fi
}

check_body() {
  local path="$1"
  local expected_text="$2"
  local body
  body=$(curl -s "${BASE_URL}${path}" 2>/dev/null || echo "")
  if echo "$body" | grep -q "$expected_text"; then
    pass "GET ${path} contains '${expected_text}'"
  else
    fail "GET ${path} missing '${expected_text}'"
  fi
}

# ---------------------------------------------------------------------------
# 1. Service reachability
# ---------------------------------------------------------------------------
echo ""
echo "🔗 1. Service Reachability"
check_endpoint "/health"
check_endpoint "/ready"
check_endpoint "/info"
check_endpoint "/"

# ---------------------------------------------------------------------------
# 2. Prometheus metrics
# ---------------------------------------------------------------------------
echo ""
echo "📊 2. Prometheus Metrics"
check_body "/metrics" "http_requests_total"
check_body "/metrics" "http_request_duration_seconds"

# ---------------------------------------------------------------------------
# 3. OTEL trace generation
# ---------------------------------------------------------------------------
echo ""
echo "🔍 3. OTEL Trace Generation"

# Hit the demo span endpoint to generate a trace
TRACE_RESPONSE=$(curl -s "${BASE_URL}/demo/span" 2>/dev/null || echo "{}")
TRACE_ID=$(echo "$TRACE_RESPONSE" | jq -r '.trace_id // empty' 2>/dev/null)

if [ -n "$TRACE_ID" ] && [ "$TRACE_ID" != "null" ]; then
  pass "Demo span created trace_id=${TRACE_ID}"

  # Query Tempo for the trace
  TEMPO_STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
    "${TEMPO_URL}/api/traces/${TRACE_ID}" 2>/dev/null || echo "000")

  if [ "$TEMPO_STATUS" = "200" ]; then
    pass "Trace found in Tempo (status ${TEMPO_STATUS})"
  else
    fail "Trace not found in Tempo (status ${TEMPO_STATUS})"
  fi
else
  fail "Demo span did not return a trace_id"
fi

# ---------------------------------------------------------------------------
# 4. K8s deployment health
# ---------------------------------------------------------------------------
echo ""
echo "☸️  4. Kubernetes Deployment Health"

READY=$(kubectl get deployment "$SERVICE" -n "$NAMESPACE" -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo "0")
DESIRED=$(kubectl get deployment "$SERVICE" -n "$NAMESPACE" -o jsonpath='{.spec.replicas}' 2>/dev/null || echo "0")

if [ "$READY" = "$DESIRED" ] && [ "$READY" != "0" ]; then
  pass "Deployment ready: ${READY}/${DESIRED} replicas"
else
  fail "Deployment not ready: ${READY:-0}/${DESIRED} replicas"
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Results: ${PASS} passed, ${FAIL} failed"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
