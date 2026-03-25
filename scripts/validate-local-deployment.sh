#!/usr/bin/env bash
# =============================================================================
# validate-local-deployment.sh — validate the Fawkes kind-based local deployment
#
# Checks that ArgoCD, Backstage, and Prometheus/Grafana pods are Running.
# Usage: ./scripts/validate-local-deployment.sh
# =============================================================================
set -euo pipefail

PASS=0
FAIL=0

log() { echo "$(date -u +%H:%M:%S) $*"; }
ok() {
  log "✅  $*"
  PASS=$((PASS + 1))
}
fail() {
  log "❌  $*"
  FAIL=$((FAIL + 1))
}

echo ""
echo "=== Fawkes Local Deployment Validation ==="
echo ""

# ---------------------------------------------------------------------------
# ArgoCD
# ---------------------------------------------------------------------------
log "Checking ArgoCD (namespace: argocd)..."
if ARGOCD_PODS=$(kubectl get pods -n argocd \
  --field-selector=status.phase=Running --no-headers 2>/dev/null); then
  ARGOCD_RUNNING=$(printf '%s\n' "${ARGOCD_PODS}" | wc -l | tr -d ' ')
  if [[ "${ARGOCD_RUNNING}" -gt 0 ]]; then
    ok "ArgoCD pods are running (${ARGOCD_RUNNING} pod(s))"
  else
    fail "ArgoCD namespace found but no Running pods — run: kubectl get pods -n argocd"
  fi
else
  fail "Unable to query ArgoCD pods — check context and that namespace 'argocd' exists"
fi

# ---------------------------------------------------------------------------
# Backstage
# ---------------------------------------------------------------------------
log "Checking Backstage (namespace: backstage)..."
if BACKSTAGE_PODS=$(kubectl get pods -n backstage \
  --field-selector=status.phase=Running --no-headers 2>/dev/null); then
  BACKSTAGE_RUNNING=$(printf '%s\n' "${BACKSTAGE_PODS}" | wc -l | tr -d ' ')
  if [[ "${BACKSTAGE_RUNNING}" -gt 0 ]]; then
    ok "Backstage pods are running (${BACKSTAGE_RUNNING} pod(s))"
  else
    fail "Backstage namespace found but no Running pods — run: kubectl get pods -n backstage"
  fi
else
  fail "Unable to query Backstage pods — check context and that namespace 'backstage' exists"
fi

# ---------------------------------------------------------------------------
# Prometheus / Grafana
# ---------------------------------------------------------------------------
log "Checking Prometheus + Grafana (namespace: monitoring)..."
if MONITORING_PODS=$(kubectl get pods -n monitoring \
  --field-selector=status.phase=Running --no-headers 2>/dev/null); then
  MONITORING_RUNNING=$(printf '%s\n' "${MONITORING_PODS}" | wc -l | tr -d ' ')
  if [[ "${MONITORING_RUNNING}" -gt 0 ]]; then
    ok "Prometheus/Grafana pods are running (${MONITORING_RUNNING} pod(s))"
  else
    fail "Monitoring namespace found but no Running pods — run: kubectl get pods -n monitoring"
  fi
else
  fail "Unable to query Prometheus/Grafana pods — check context and that namespace 'monitoring' exists"
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
echo ""
echo "=== Platform Access (via port-forward) ==="
echo "  ArgoCD:    http://localhost:8080"
echo "    kubectl port-forward svc/argocd-server -n argocd 8080:80"
echo ""
echo "  Backstage: http://localhost:7007"
echo "    kubectl port-forward svc/backstage -n backstage 7007:7007"
echo ""
echo "  Grafana:   http://localhost:3000"
echo "    kubectl port-forward svc/prometheus-grafana -n monitoring 3000:80"
echo "    Retrieve password: kubectl get secret prometheus-grafana -n monitoring \\"
echo "      -o jsonpath='{.data.admin-password}' | base64 --decode"
echo ""

if [[ "${FAIL}" -eq 0 ]]; then
  log "✅  All ${PASS} checks passed — platform is operational!"
  exit 0
else
  log "❌  ${FAIL} check(s) failed, ${PASS} passed"
  exit 1
fi
