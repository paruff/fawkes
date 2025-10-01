#!/bin/bash

set -e

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

echo "🌐 Port-forwarding ArgoCD UI to https://localhost:8080 ..."
kubectl port-forward svc/argocd-server -n argocd 8080:443 >/dev/null 2>&1 &
ARGOCD_PID=$!

sleep 10

echo "🔬 Testing ArgoCD API endpoint..."
if curl -ks https://localhost:8080/api/v1/session | grep -q '"code"'; then
  echo "✅ ArgoCD API is responding."
else
  error_exit "ArgoCD API is not responding as expected."
fi

sleep 5

# Login to ArgoCD using CLI
argocd login localhost:8080 --username admin --password "$ARGOCD_PASSWORD" --insecure

# Create the Fawkes application in ArgoCD
argocd app create fawkes-app \
  --repo https://github.com/paruff/fawkes.git \
  --path platform/apps \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace fawkes \
  --sync-policy automated

echo "✅ Fawkes ArgoCD application created and set to auto-sync."

echo ""
echo "🎉 Bootstrap complete for '$ENV' environment!"
echo ""
echo "ArgoCD UI:    https://localhost:8080 (user: admin, password above)"
echo ""
echo "To stop port-forward, run:"
echo "  kill $ARGOCD_PID"