#!/usr/bin/env bash

# Fail fast and make unbound variable usage an error. Also propagate pipe failures.
set -euo pipefail

echo "Current working directory: $(pwd)"

# Helper function for error messages
function error_exit {
  echo "[ERROR] $1"
  exit 1
}

# Usage instructions
function usage {
  echo "Usage: $0 <environment|cleanup>"
  echo "  environment: local | dev | stage | production"
  echo "  cleanup: remove ArgoCD and Fawkes resources for a fresh start"
  exit 1
}

if [[ "$1" == "cleanup" ]]; then
  echo "🧹 Cleaning up ArgoCD and Fawkes namespaces..."
  kubectl delete namespace argocd --wait || echo "argocd namespace not found"
  kubectl delete namespace fawkes --wait || echo "fawkes namespace not found"
  kubectl delete namespace jenkins --wait  || echo "argocd namespace not found"
  echo "✅ Cleanup complete."
  exit 0
fi

# Validate parameter
ENV="$1"
if [[ -z "$ENV" ]]; then
  usage
fi

case "$ENV" in
  local|dev|stage|production)
    ;;
  *)
    error_exit "Invalid environment: $ENV. Must be one of: local, dev, stage, production."
    ;;
esac

echo "🔎 Validating prerequisites..."

for tool in kubectl jq base64 argocd; do
  if ! command -v $tool &>/dev/null; then
    error_exit "$tool is required but not installed. Please install $tool and try again."
  fi
done

echo "✅ All required tools are installed."

# List available contexts and check if any are reachable
echo "🔍 Checking available Kubernetes contexts..."
kubectl config get-contexts

ACTIVE_CONTEXT=$(kubectl config current-context 2>/dev/null || echo "")
if [[ -n "$ACTIVE_CONTEXT" ]]; then
  echo "Current active context: $ACTIVE_CONTEXT"
  if kubectl cluster-info &>/dev/null; then
    read -p "Do you want to use the current context '$ACTIVE_CONTEXT'? [y/N]: " USE_CURRENT
    if [[ ! "$USE_CURRENT" =~ ^[Yy]$ ]]; then
      error_exit "Aborted by user."
    fi
    echo "✅ Using current context: $ACTIVE_CONTEXT"
  else
    error_exit "Current context '$ACTIVE_CONTEXT' is not reachable."
  fi
else
  error_exit "No active Kubernetes context found."
fi

echo "✅ Kubernetes context set and reachable."

# Check cluster connectivity
if ! kubectl version &>/dev/null; then
  error_exit "kubectl is not configured or cannot connect to the selected Kubernetes cluster."
fi

echo "✅ Kubernetes cluster is reachable."

# Create argocd namespace if it does not exist
kubectl apply -f - <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: argocd
EOF

echo "namespace/argocd ensured"

# Deploy ArgoCD
echo "🚀 Deploying ArgoCD..."
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo "⏳ Waiting for ArgoCD server to be available..."
kubectl wait --for=condition=available deployment/argocd-server -n argocd --timeout=300s

ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
echo "🔑 ArgoCD admin password: $ARGOCD_PASSWORD"

echo "🌐 Ensuring ArgoCD deployments are available..."

wait_for_workload() {
  # Waits for a named workload which may be a Deployment or StatefulSet.
  # Usage: wait_for_workload <name> <namespace> <timeout_seconds>
  local name="$1" ns="${2:-default}" timeout="${3:-300}"

  echo "⏳ Waiting for workload ${name} in namespace ${ns} (timeout ${timeout}s)..."

  # Prefer Deployment
  if kubectl get deployment "${name}" -n "${ns}" >/dev/null 2>&1; then
    if ! kubectl wait --for=condition=available deployment/${name} -n "${ns}" --timeout="${timeout}s"; then
      kubectl -n "${ns}" get pods -o wide
      kubectl -n "${ns}" describe deployment/${name} || true
      return 1
    fi
    return 0
  fi

  # If not a deployment, check for StatefulSet
  if kubectl get statefulset "${name}" -n "${ns}" >/dev/null 2>&1; then
    # Use rollout status for statefulsets which reports readiness
    if ! kubectl rollout status statefulset/${name} -n "${ns}" --timeout="${timeout}s"; then
      kubectl -n "${ns}" get pods -o wide
      kubectl -n "${ns}" describe statefulset/${name} || true
      return 1
    fi
    return 0
  fi

  # Fallback: wait for any pod with the name prefix to be ready
  echo "Workload ${name} not found as Deployment or StatefulSet; falling back to pods with prefix ${name}"
  local end=$((SECONDS + timeout))
  while [[ ${SECONDS} -lt ${end} ]]; do
    pod=$(kubectl -n "${ns}" get pods --no-headers -o custom-columns=":metadata.name" | grep "^${name}" | head -n1 || true)
    if [[ -n "$pod" ]]; then
      # Check pod readiness
      ready=$(kubectl -n "${ns}" get pod "$pod" -o jsonpath='{.status.containerStatuses[0].ready}' 2>/dev/null || echo "false")
      if [[ "$ready" == "true" ]]; then
        echo "Pod $pod is ready"
        return 0
      fi
    fi
    sleep 2
  done
  kubectl -n "${ns}" get pods -o wide
  return 1
}

# Wait for core ArgoCD components. Some ArgoCD manifests create StatefulSets instead of Deployments
for dep in argocd-server argocd-repo-server argocd-application-controller argocd-dex-server; do
  if ! wait_for_workload "${dep}" argocd 300; then
    error_exit "Deployment ${dep} failed to become available"
  fi
done

# Wait for the argocd-server service to have endpoints (ready pods)
echo "⏳ Waiting for argocd-server service endpoints..."
ENDPOINTS_TIMEOUT=120
end=$((SECONDS + ENDPOINTS_TIMEOUT))
while [[ ${SECONDS} -lt ${end} ]]; do
  if kubectl get endpoints argocd-server -n argocd -o jsonpath='{.subsets}' | grep -q .; then
    echo "✅ argocd-server has endpoints"
    break
  fi
  sleep 2
done
if [[ ${SECONDS} -ge ${end} ]]; then
  kubectl -n argocd get endpoints
  error_exit "argocd-server service has no endpoints after ${ENDPOINTS_TIMEOUT}s"
fi

echo "🌐 Creating ArgoCD Application CRs in-cluster (no port-forward required)..."

# Create Application CRs directly so ArgoCD picks them up without using the argocd CLI
# This avoids needing port-forward access for initial bootstrapping. These Application
# resources include automated sync so ArgoCD will deploy the resources (including Jenkins).

cat <<'EOF' | kubectl apply -f -
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: fawkes-app
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/paruff/fawkes.git
    path: platform/apps
    targetRevision: HEAD
  destination:
    server: https://kubernetes.default.svc
    namespace: fawkes
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
---
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: fawkes-infra
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/paruff/fawkes.git
    path: infra/kubernetes
    targetRevision: HEAD
  destination:
    server: https://kubernetes.default.svc
    namespace: fawkes
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
EOF

echo "✅ ArgoCD Application CRs applied — ArgoCD will pick them up and sync the fawkes namespace." 
echo "If you want to access the ArgoCD UI locally run: kubectl -n argocd port-forward svc/argocd-server 8080:443"

echo ""
echo "🎉 Bootstrap complete for '$ENV' environment!"
echo ""
echo "ArgoCD UI:    https://localhost:8080 (user: admin, password above)"
echo ""
echo "To stop port-forward, run:"
echo "  kill $ARGOCD_PID"