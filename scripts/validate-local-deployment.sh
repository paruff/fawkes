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
ARGOCD_RUNNING=$(kubectl get pods -n argocd \
  --field-selector=status.phase=Running --no-headers 2>/dev/null | wc -l | tr -d ' ')
if [[ "${ARGOCD_RUNNING}" -gt 0 ]]; then
  ok "ArgoCD pods are running (${ARGOCD_RUNNING} pod(s))"
else
  fail "ArgoCD pods not running — run: kubectl get pods -n argocd"
fi

# ---------------------------------------------------------------------------
# Backstage
# ---------------------------------------------------------------------------
log "Checking Backstage (namespace: backstage)..."
BACKSTAGE_RUNNING=$(kubectl get pods -n backstage \
  --field-selector=status.phase=Running --no-headers 2>/dev/null | wc -l | tr -d ' ')
if [[ "${BACKSTAGE_RUNNING}" -gt 0 ]]; then
  ok "Backstage pods are running (${BACKSTAGE_RUNNING} pod(s))"
else
  fail "Backstage pods not running — run: kubectl get pods -n backstage"
fi

# ---------------------------------------------------------------------------
# Prometheus / Grafana
# ---------------------------------------------------------------------------
log "Checking Prometheus + Grafana (namespace: monitoring)..."
MONITORING_RUNNING=$(kubectl get pods -n monitoring \
  --field-selector=status.phase=Running --no-headers 2>/dev/null | wc -l | tr -d ' ')
if [[ "${MONITORING_RUNNING}" -gt 0 ]]; then
  ok "Prometheus/Grafana pods are running (${MONITORING_RUNNING} pod(s))"
else
  fail "Prometheus/Grafana pods not running — run: kubectl get pods -n monitoring"
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
echo ""
echo "=== Platform Access URLs ==="
echo "  ArgoCD:    http://localhost:8080"
echo "  Backstage: http://backstage.local.fawkes.dev"
echo "  Grafana:   http://grafana.local.fawkes.dev"
echo ""
echo "  Port-forward ArgoCD:    kubectl port-forward svc/argocd-server -n argocd 8080:80"
echo "  Port-forward Backstage: kubectl port-forward svc/backstage -n backstage 7007:7007"
echo "  Port-forward Grafana:   kubectl port-forward svc/prometheus-grafana -n monitoring 3000:80"
echo ""

if [[ "${FAIL}" -eq 0 ]]; then
  log "✅  All ${PASS} checks passed — platform is operational!"
  exit 0
else
  log "❌  ${FAIL} check(s) failed, ${PASS} passed"
  exit 1
fi
