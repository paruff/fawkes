#!/usr/bin/env bash
# =============================================================================
# dev-status.sh — print URLs and credentials for the Fawkes local environment
#
# Usage: ./scripts/dev-status.sh  (or: make dev-status)
# =============================================================================
set -euo pipefail

CLUSTER_NAME="${FAWKES_CLUSTER:-fawkes-dev}"

# Check cluster is running
if ! command -v k3d &> /dev/null || ! k3d cluster list 2> /dev/null | grep -q "^${CLUSTER_NAME} "; then
  echo "❌  Fawkes local cluster '${CLUSTER_NAME}' is not running."
  echo "    Run: make dev-up"
  exit 1
fi

# Retrieve ArgoCD admin password (stored in a Secret after install)
ARGOCD_PASSWORD=""
if kubectl get secret argocd-initial-admin-secret -n argocd &> /dev/null; then
  ARGOCD_PASSWORD="$(kubectl get secret argocd-initial-admin-secret \
    -n argocd -o jsonpath='{.data.password}' | base64 --decode 2> /dev/null \
    || kubectl get secret argocd-initial-admin-secret \
      -n argocd -o jsonpath='{.data.password}' | base64 -d)"
else
  ARGOCD_PASSWORD="(see: kubectl get secret argocd-initial-admin-secret -n argocd)"
fi

echo
echo "╔══════════════════════════════════════════════════════════════════╗"
echo "║           Fawkes Local Environment — Service URLs                ║"
echo "╚══════════════════════════════════════════════════════════════════╝"
echo

echo "  Start port-forwards with the commands below, then open the URLs."
echo

echo "┌─ ArgoCD ────────────────────────────────────────────────────────┐"
echo "│  kubectl port-forward -n argocd svc/argocd-server 8888:80     │"
echo "│  URL:      http://localhost:8888                               │"
echo "│  User:     admin                                               │"
printf "│  Password: %-51s│\n" "${ARGOCD_PASSWORD}"
echo "└─────────────────────────────────────────────────────────────────┘"
echo

echo "┌─ Vault (dev mode) ──────────────────────────────────────────────┐"
echo "│  kubectl port-forward -n vault svc/vault 8200:8200             │"
echo "│  URL:   http://localhost:8200                                   │"
echo "│  Token: fawkes-dev-root                                        │"
echo "└─────────────────────────────────────────────────────────────────┘"
echo

echo "┌─ Backstage ─────────────────────────────────────────────────────┐"
echo "│  kubectl port-forward -n backstage svc/backstage 7007:7007     │"
echo "│  URL:   http://localhost:7007                                   │"
echo "└──────────────────────────��──────────────────────────────────────┘"
echo

echo "┌─ Grafana ───────────────────────────────────────────────────────┐"
echo "│  kubectl port-forward -n monitoring \                          │"
echo "│    svc/kube-prometheus-stack-grafana 3000:80                  │"
echo "│  URL:      http://localhost:3000                               │"
echo "│  User:     admin                                               │"
echo "│  Password: fawkes-grafana                                      │"
echo "└─────────────────────────────────────────────────────────────────┘"
echo

echo "┌─ Prometheus ────────────────────────────────────────────────────┐"
echo "│  kubectl port-forward -n monitoring \                          │"
echo "│    svc/kube-prometheus-stack-prometheus 9090:9090              │"
echo "│  URL:   http://localhost:9090                                   │"
echo "└─────────────────────────────────────────────────────────────────┘"
echo

echo "┌─ Sample App (podinfo) ──────────────────────────────────────────┐"
echo "│  kubectl port-forward -n sample-apps svc/podinfo 9898:9898     │"
echo "│  URL:   http://localhost:9898                                   │"
echo "└─────────────────────────────────────────────────────────────────┘"
echo

echo "Cluster: k3d-${CLUSTER_NAME}"
echo "Namespaces:"
kubectl get namespaces --no-headers \
  -l 'kubernetes.io/metadata.name in (argocd,vault,backstage,monitoring,sample-apps)' \
  2> /dev/null \
  | awk '{printf "  %-20s %s\n", $1, $2}' || true
echo

echo "All pods:"
kubectl get pods -A --no-headers \
  --field-selector "metadata.namespace!=kube-system,metadata.namespace!=kube-public,metadata.namespace!=kube-node-lease,metadata.namespace!=local-path-storage" \
  2> /dev/null \
  | awk '{printf "  %-20s %-35s %s\n", $1, $2, $4}' || true
echo
