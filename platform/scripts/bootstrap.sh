#!/bin/bash

set -e

# Helper function for error messages
function error_exit {
  echo "[ERROR] $1"
  exit 1
}

# Usage instructions
function usage {
  echo "Usage: $0 <environment>"
  echo "  environment: local | dev | stage | production"
  exit 1
}

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

# Deploy ArgoCD
echo "🚀 Deploying ArgoCD..."
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -k "$KUSTOMIZE_PATH/"

echo "⏳ Waiting for ArgoCD server to be available..."
kubectl wait --for=condition=available deployment -l app.kubernetes.io/name=argocd-server -n argocd --timeout=300s

# Get initial ArgoCD admin password
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
echo "🔑 ArgoCD admin password: $ARGOCD_PASSWORD"

# Port-forward ArgoCD UI
echo "🌐 Port-forwarding ArgoCD UI to http://localhost:8080 ..."
kubectl port-forward svc/argocd-server -n argocd 8080:443 >/dev/null 2>&1 &
ARGOCD_PID=$!

sleep 5

# Test ArgoCD API
echo "🔬 Testing ArgoCD API endpoint..."
if curl -k --silent https://localhost:8080/api/v1/session | grep -q "code"; then
  echo "✅ ArgoCD API is responding."
else
  error_exit "ArgoCD API is not responding as expected."
fi

# Deploy DevLake (if manifests exist for this env)
echo "🚀 Deploying DevLake..."
kubectl create namespace devlake --dry-run=client -o yaml | kubectl apply -f -
if [ -d "$KUSTOMIZE_PATH/devlake" ]; then
  kubectl apply -k "$KUSTOMIZE_PATH/devlake/"
else
  echo "⚠️  DevLake manifests not found in $KUSTOMIZE_PATH/devlake/. Please deploy DevLake manually if needed."
fi

echo "⏳ Waiting for DevLake to be available..."
kubectl wait --for=condition=available deployment -l app.kubernetes.io/name=devlake -n devlake --timeout=300s || \
  echo "⚠️  DevLake deployment not found or not ready. Please check manually."

# Deploy DevLake via ArgoCD Application manifest if present
DEVLAKE_APP_MANIFEST="platform/apps/devlake/devlake-application.yaml"
if [ -f "$DEVLAKE_APP_MANIFEST" ]; then
  echo "🚀 Applying DevLake ArgoCD Application manifest..."
  kubectl apply -f "$DEVLAKE_APP_MANIFEST"
else
  echo "⚠️  DevLake ArgoCD Application manifest not found at $DEVLAKE_APP_MANIFEST. Please deploy DevLake manually if needed."
fi

echo "⏳ Waiting for DevLake deployment to be available..."
kubectl wait --for=condition=available deployment -l app.kubernetes.io/name=devlake -n devlake --timeout=300s || \
  echo "⚠️  DevLake deployment not found or not ready. Please check manually or see docs/troubleshooting.md."

# Port-forward DevLake UI (assuming service name is 'devlake-ui' and port 4000)
echo "🌐 Port-forwarding DevLake UI to http://localhost:4000 ..."
kubectl port-forward svc/devlake-ui -n devlake 4000:4000 >/dev/null 2>&1 &
DEVLAKE_PID=$!

echo ""
echo "🎉 Bootstrap complete for '$ENV' environment!"
echo ""
echo "ArgoCD UI:    https://localhost:8080 (user: admin, password above)"
echo "DevLake UI:   http://localhost:4000"
echo ""
echo "To stop port-forwards, run:"
echo "  kill $ARGOCD_PID $DEVLAKE_PID"