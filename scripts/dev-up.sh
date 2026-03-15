#!/usr/bin/env bash
# =============================================================================
# dev-up.sh — bring up a fully functional Fawkes local environment
#
# Starts a k3d cluster and installs exactly 5 components:
#   1. ArgoCD         (GitOps controller)
#   2. Vault          (secrets management, dev mode)
#   3. Backstage      (developer portal)
#   4. kube-prometheus-stack (Prometheus + Grafana)
#   5. podinfo sample app deployed via ArgoCD
#
# Prerequisites: docker, k3d, kubectl, helm
# Usage: ./scripts/dev-up.sh  (or: make dev-up)
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

CLUSTER_NAME="${FAWKES_CLUSTER:-fawkes-dev}"
ARGOCD_NS="argocd"
VAULT_NS="vault"
BACKSTAGE_NS="backstage"
MONITORING_NS="monitoring"
SAMPLE_NS="sample-apps"

# Helm chart versions (pinned)
ARGOCD_CHART_VERSION="7.7.14"
VAULT_CHART_VERSION="0.29.1"
BACKSTAGE_CHART_VERSION="2.3.0"
PROMETHEUS_CHART_VERSION="67.9.0"

log() { echo "$(date -u +%H:%M:%S) $*"; }
step() { echo; log "──────────────────────────────────────────"; log "▶  $*"; log "──────────────────────────────────────────"; }
ok() { log "✅  $*"; }
warn() { log "⚠️   $*"; }

# ---------------------------------------------------------------------------
# 1. Dependency check
# ---------------------------------------------------------------------------
step "Checking prerequisites"
MISSING=()
for cmd in docker k3d kubectl helm; do
  if ! command -v "$cmd" &>/dev/null; then
    MISSING+=("$cmd")
  fi
done

if [[ "${#MISSING[@]}" -gt 0 ]]; then
  echo "❌  Missing required tools: ${MISSING[*]}"
  echo ""
  echo "Install hints:"
  echo "  docker   → https://docs.docker.com/get-docker/"
  echo "  k3d      → brew install k3d  OR  https://k3d.io"
  echo "  kubectl  → brew install kubectl"
  echo "  helm     → brew install helm"
  exit 1
fi
ok "All prerequisites found"

# ---------------------------------------------------------------------------
# 2. Create k3d cluster (skip if already running)
# ---------------------------------------------------------------------------
step "Creating k3d cluster: ${CLUSTER_NAME}"
if k3d cluster list 2>/dev/null | grep -q "^${CLUSTER_NAME} "; then
  warn "Cluster '${CLUSTER_NAME}' already exists — skipping creation"
else
  k3d cluster create "${CLUSTER_NAME}" \
    --port "8080:80@loadbalancer" \
    --port "8443:443@loadbalancer" \
    --agents 2 \
    --wait
  ok "Cluster '${CLUSTER_NAME}' created"
fi

# Merge and switch kubeconfig context
k3d kubeconfig merge "${CLUSTER_NAME}" --kubeconfig-merge-default --kubeconfig-switch-context
ok "kubectl context switched to k3d-${CLUSTER_NAME}"

# ---------------------------------------------------------------------------
# 3. Add Helm repositories
# ---------------------------------------------------------------------------
step "Adding Helm repositories"
helm repo add argo      https://argoproj.github.io/argo-helm              2>/dev/null || true
helm repo add hashicorp https://helm.releases.hashicorp.com               2>/dev/null || true
helm repo add backstage https://backstage.github.io/charts                2>/dev/null || true
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts 2>/dev/null || true
helm repo add podinfo   https://stefanprodan.github.io/podinfo             2>/dev/null || true
helm repo update
ok "Helm repos updated"

# ---------------------------------------------------------------------------
# 4. ArgoCD
# ---------------------------------------------------------------------------
step "Installing ArgoCD"
kubectl create namespace "${ARGOCD_NS}" --dry-run=client -o yaml | kubectl apply -f -
helm upgrade --install argocd argo/argo-cd \
  --version "${ARGOCD_CHART_VERSION}" \
  --namespace "${ARGOCD_NS}" \
  --set server.service.type=ClusterIP \
  --set configs.params."server\.insecure"=true \
  --wait --timeout 5m
ok "ArgoCD installed (namespace: ${ARGOCD_NS})"

# ---------------------------------------------------------------------------
# 5. Vault (dev mode)
# ---------------------------------------------------------------------------
step "Installing Vault (dev mode)"
kubectl create namespace "${VAULT_NS}" --dry-run=client -o yaml | kubectl apply -f -
# WARNING: dev-only root token — never use this token or dev mode in production
helm upgrade --install vault hashicorp/vault \
  --version "${VAULT_CHART_VERSION}" \
  --namespace "${VAULT_NS}" \
  --set server.dev.enabled=true \
  --set server.dev.devRootToken="fawkes-dev-root" \
  --set ui.enabled=true \
  --set ui.serviceType=ClusterIP \
  --wait --timeout 5m
ok "Vault installed in dev mode (namespace: ${VAULT_NS})"

# ---------------------------------------------------------------------------
# 6. kube-prometheus-stack (Prometheus + Grafana)
# ---------------------------------------------------------------------------
step "Installing Prometheus + Grafana (kube-prometheus-stack)"
kubectl create namespace "${MONITORING_NS}" --dry-run=client -o yaml | kubectl apply -f -
# WARNING: dev-only password — never use this password in production
helm upgrade --install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  --version "${PROMETHEUS_CHART_VERSION}" \
  --namespace "${MONITORING_NS}" \
  --set grafana.adminPassword="fawkes-grafana" \
  --set grafana.service.type=ClusterIP \
  --set prometheus.service.type=ClusterIP \
  --set alertmanager.enabled=false \
  --set kubeStateMetrics.enabled=true \
  --set nodeExporter.enabled=true \
  --wait --timeout 8m
ok "Prometheus + Grafana installed (namespace: ${MONITORING_NS})"

# ---------------------------------------------------------------------------
# 7. Backstage
# ---------------------------------------------------------------------------
step "Installing Backstage"
kubectl create namespace "${BACKSTAGE_NS}" --dry-run=client -o yaml | kubectl apply -f -
helm upgrade --install backstage backstage/backstage \
  --version "${BACKSTAGE_CHART_VERSION}" \
  --namespace "${BACKSTAGE_NS}" \
  --set backstage.appConfig.app.title="Fawkes IDP (Local)" \
  --set backstage.appConfig.app.baseUrl="http://localhost:7007" \
  --set backstage.appConfig.backend.baseUrl="http://localhost:7007" \
  --set backstage.appConfig.backend.cors.origin="http://localhost:7007" \
  --wait --timeout 8m
ok "Backstage installed (namespace: ${BACKSTAGE_NS})"

# ---------------------------------------------------------------------------
# 8. Sample app via ArgoCD (podinfo)
# ---------------------------------------------------------------------------
step "Deploying sample app (podinfo) via ArgoCD"
kubectl create namespace "${SAMPLE_NS}" --dry-run=client -o yaml | kubectl apply -f -

# Create an ArgoCD Application manifest for podinfo
kubectl apply -f - <<'EOF'
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: podinfo
  namespace: argocd
  labels:
    app: podinfo
    managed-by: fawkes
spec:
  project: default
  source:
    repoURL: https://stefanprodan.github.io/podinfo
    chart: podinfo
    targetRevision: 6.7.0
    helm:
      values: |
        replicaCount: 1
        resources:
          requests:
            cpu: "50m"
            memory: "64Mi"
          limits:
            cpu: "200m"
            memory: "128Mi"
  destination:
    server: https://kubernetes.default.svc
    namespace: sample-apps
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
EOF

ok "podinfo ArgoCD Application created"

# Wait briefly for ArgoCD to reconcile
log "Waiting for ArgoCD to sync podinfo (up to 2 min)..."
kubectl wait --for=condition=available deployment/argocd-server \
  --namespace "${ARGOCD_NS}" --timeout=120s 2>/dev/null || true

# ---------------------------------------------------------------------------
# 9. Print status
# ---------------------------------------------------------------------------
echo
"${SCRIPT_DIR}/dev-status.sh"
