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
  echo "  cleanup: remove ArgoCD, DevLake, and Fawkes resources for a fresh start"
  exit 1
}

if [[ "$1" == "cleanup" ]]; then
  echo "🧹 Cleaning up ArgoCD, DevLake, and Fawkes namespaces..."
  kubectl delete namespace argocd --wait || echo "argocd namespace not found"
  kubectl delete namespace devlake --wait || echo "devlake namespace not found"
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

for tool in kubectl kustomize jq base64; do
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
    if [[ "$USE_CURRENT" =~ ^[Yy]$ ]]; then
      echo "✅ Using current context: $ACTIVE_CONTEXT"
      CONTEXT_SELECTED=true
    fi
  else
    echo "⚠️  Current context '$ACTIVE_CONTEXT' is not reachable."
  fi
fi

if [[ "$CONTEXT_SELECTED" != "true" ]]; then
  # Set cluster context based on environment
  case "$ENV" in
    local)
      # Try kind first, then minikube
      if kubectl config get-contexts kind-fawkes &>/dev/null; then
        kubectl config use-context kind-fawkes
        echo "🔗 Using kind local cluster context: kind-fawkes"
      elif kubectl config get-contexts minikube &>/dev/null; then
        kubectl config use-context minikube
        echo "🔗 Using minikube local cluster context: minikube"
      else
        error_exit "No local Kubernetes cluster context found (kind-fawkes or minikube)."
      fi
      KUSTOMIZE_PATH="clusters/local"
      ;;
    dev)
      kubectl config use-context dev-fawkes || error_exit "Kubernetes context 'dev-fawkes' not found."
      KUSTOMIZE_PATH="clusters/dev"
      ;;
    stage)
      kubectl config use-context stage-fawkes || error_exit "Kubernetes context 'stage-fawkes' not found."
      KUSTOMIZE_PATH="clusters/stage"
      ;;
    production)
      kubectl config use-context prod-fawkes || error_exit "Kubernetes context 'prod-fawkes' not found."
      KUSTOMIZE_PATH="clusters/production"
      ;;
  esac
else
  # Guess kustomize path from context name
  case "$ACTIVE_CONTEXT" in
    kind-fawkes|minikube)
      KUSTOMIZE_PATH="clusters/local"
      ;;
    dev-fawkes)
      KUSTOMIZE_PATH="clusters/dev"
      ;;
    stage-fawkes)
      KUSTOMIZE_PATH="clusters/stage"
      ;;
    prod-fawkes)
      KUSTOMIZE_PATH="clusters/production"
      ;;
    *)
      KUSTOMIZE_PATH="clusters/local"
      ;;
  esac
fi

# Set the base directory for kustomize overlays
if [[ -f "./clusters/local/kustomization.yaml" ]]; then
  # Running from within platform/iac or platform
  KUSTOMIZE_PATH="clusters/$ENV"
elif [[ -f "./platform/iac/clusters/local/kustomization.yaml" ]]; then
  # Running from repo root
  KUSTOMIZE_PATH="platform/iac/clusters/$ENV"
else
  error_exit "Could not find clusters/$ENV/kustomization.yaml. Please run this script from the repo root or platform directory."
fi

echo "Using Kustomize path: $KUSTOMIZE_PATH"

echo "✅ Kubernetes context set and reachable."

# Check cluster connectivity
if ! kubectl version &>/dev/null; then
  error_exit "kubectl is not configured or cannot connect to the selected Kubernetes cluster."
fi

echo "✅ Kubernetes cluster is reachable."

# Create argocd namespace if it does not exist
if ! kubectl get namespace argocd &>/dev/null; then
  kubectl create namespace argocd
  echo "namespace/argocd created"
else
  echo "namespace/argocd already exists"
fi

# Deploy ArgoCD
echo "🚀 Deploying ArgoCD..."
# kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
# kubectl apply -k "$KUSTOMIZE_PATH/"

kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml


echo "⏳ Waiting for ArgoCD server to be available..."
kubectl wait --for=condition=available deployment -l app.kubernetes.io/name=argocd-server -n argocd --timeout=300s

# Get initial ArgoCD admin password
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
echo "🔑 ArgoCD admin password: $ARGOCD_PASSWORD"

# Port-forward ArgoCD UI
echo "🌐 Port-forwarding ArgoCD UI to https://localhost:8080 ..."
kubectl port-forward svc/argocd-server -n argocd 8080:443 >/dev/null 2>&1 &
ARGOCD_PID=$!

sleep 10

# Test ArgoCD API
echo "🔬 Testing ArgoCD API endpoint..."
if curl -ks https://localhost:8080/api/v1/session | grep -q '"code"'; then
  echo "✅ ArgoCD API is responding."
else
  error_exit "ArgoCD API is not responding as expected."
fi

# Wait for ArgoCD API to be ready before using argocd CLI
sleep 10

# Get the Kubernetes API server URL for the current context
KUBE_SERVER=$(kubectl config view -o jsonpath="{.clusters[?(@.name==\"$ACTIVE_CONTEXT\")].cluster.server}")

# Login to ArgoCD using CLI
argocd login localhost:8080 --username admin --password "$ARGOCD_PASSWORD" --insecure

# Set the application path dynamically based on environment
APP_PATH="platform/apps/${ENV}"

# If the environment-specific directory doesn't exist, fall back to platform/apps
if [[ ! -d "$APP_PATH" ]]; then
  APP_PATH="platform/apps"
fi

# Create the Fawkes application in ArgoCD
argocd app create fawkes-app \
  --repo https://github.com/paruff/fawkes.git \
  --path "$APP_PATH" \
  --dest-server "$KUBE_SERVER" \
  --dest-namespace "$DEST_NAMESPACE" \
  --sync-policy automated

echo "✅ Fawkes ArgoCD application created and set to auto-sync."

echo ""
echo "🎉 Bootstrap complete for '$ENV' environment!"
echo ""
echo "ArgoCD UI:    https://localhost:8080 (user: admin, password above)"
echo ""
echo "To stop port-forward, run:"
echo "  kill $ARGOCD_PID"