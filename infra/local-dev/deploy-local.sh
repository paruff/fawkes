#!/bin/bash
# File: infra/local-dev/deploy-local.sh
# Deploy Fawkes components to local Kubernetes (Docker Desktop)

set -e

NAMESPACE="${1:-fawkes-local}"
COMPONENT="${2:-all}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo "🚀 Deploying $COMPONENT to local Kubernetes in namespace: $NAMESPACE"
echo "📁 Repository root: $REPO_ROOT"

# Switch to docker-desktop context
echo "🔄 Switching to docker-desktop context..."
kubectl config use-context docker-desktop || {
  echo "❌ Docker Desktop Kubernetes not found. Is it running?"
  exit 1
}

# Ensure namespace exists
echo "📦 Creating namespace: $NAMESPACE"
kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

# Function to check if Helm repo exists
add_helm_repo() {
  local repo_name=$1
  local repo_url=$2

  if ! helm repo list | grep -q "^${repo_name}"; then
    echo "➕ Adding Helm repo: $repo_name"
    helm repo add "$repo_name" "$repo_url"
  fi
  helm repo update
}

# Deploy based on component
case $COMPONENT in

  backstage)
    echo "🎭 Deploying Backstage Developer Portal..."

    # Add Backstage Helm repo
    add_helm_repo backstage https://backstage.github.io/charts

    # Check if values file exists, create if not
    VALUES_FILE="$REPO_ROOT/infra/kubernetes/backstage/values-local.yaml"
    if [ ! -f "$VALUES_FILE" ]; then
      echo "⚠️  Creating default values-local.yaml..."
      cat > "$VALUES_FILE" << 'EOF'
# Local development values for Backstage
replicaCount: 1

image:
  pullPolicy: IfNotPresent

service:
  type: NodePort
  nodePort: 30007

resources:
  requests:
    cpu: 100m
    memory: 256Mi
  limits:
    cpu: 500m
    memory: 512Mi

backstage:
  appConfig:
    app:
      title: Fawkes IDP (Local)
      baseUrl: http://localhost:7007
EOF
    fi

    helm upgrade --install backstage backstage/backstage \
      -f "$VALUES_FILE" \
      -n "$NAMESPACE" \
      --wait --timeout 5m \
      --create-namespace

    echo "✅ Backstage deployed!"
    echo "🌐 Access via: kubectl port-forward -n $NAMESPACE svc/backstage 7007:7007"
    ;;

  argocd)
    echo "🔄 Deploying ArgoCD..."

    # Check if manifests exist
    ARGOCD_MANIFESTS="$REPO_ROOT/infra/kubernetes/argocd"
    if [ ! -d "$ARGOCD_MANIFESTS" ]; then
      echo "⚠️  ArgoCD manifests not found at $ARGOCD_MANIFESTS"
      echo "📥 Installing from official manifests..."

      kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
      kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
    else
      kubectl apply -n "$NAMESPACE" -f "$ARGOCD_MANIFESTS"
    fi

    # Wait for ArgoCD to be ready
    echo "⏳ Waiting for ArgoCD to be ready..."
    kubectl wait --for=condition=available --timeout=300s \
      deployment/argocd-server -n argocd 2>/dev/null || \
      kubectl wait --for=condition=available --timeout=300s \
      deployment/argocd-server -n "$NAMESPACE"

    echo "✅ ArgoCD deployed!"
    echo "🔑 Get admin password: kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath=\"{.data.password}\" | base64 -d"
    echo "🌐 Access via: kubectl port-forward -n argocd svc/argocd-server 8080:443"
    ;;

  jenkins)
    echo "🏗️  Deploying Jenkins CI/CD..."

    # Check if Jenkins manifests exist
    JENKINS_MANIFESTS="$REPO_ROOT/infra/kubernetes/jenkins"
    if [ ! -d "$JENKINS_MANIFESTS" ]; then
      echo "⚠️  Jenkins manifests not found at $JENKINS_MANIFESTS"
      echo "📥 Installing via Helm..."

      add_helm_repo jenkins https://charts.jenkins.io

      helm upgrade --install jenkins jenkins/jenkins \
        --set controller.serviceType=NodePort \
        --set controller.nodePort=30008 \
        --set controller.resources.requests.cpu=100m \
        --set controller.resources.requests.memory=512Mi \
        --set controller.resources.limits.cpu=1000m \
        --set controller.resources.limits.memory=1Gi \
        -n "$NAMESPACE" \
        --wait --timeout 5m \
        --create-namespace
    else
      kubectl apply -n "$NAMESPACE" -f "$JENKINS_MANIFESTS"
    fi

    echo "✅ Jenkins deployed!"
    echo "🔑 Get admin password: kubectl exec -n $NAMESPACE -it svc/jenkins -c jenkins -- /bin/cat /run/secrets/chart-admin-password"
    echo "🌐 Access via: kubectl port-forward -n $NAMESPACE svc/jenkins 8080:8080"
    ;;

  mattermost)
    echo "💬 Deploying Mattermost..."

    add_helm_repo mattermost https://helm.mattermost.com

    VALUES_FILE="$REPO_ROOT/infra/kubernetes/mattermost/values-local.yaml"
    if [ ! -f "$VALUES_FILE" ]; then
      echo "⚠️  Creating default mattermost values-local.yaml..."
      mkdir -p "$(dirname "$VALUES_FILE")"
      cat > "$VALUES_FILE" << 'EOF'
# Local development values for Mattermost
mysql:
  enabled: true
  mysqlRootPassword: rootpass
  mysqlUser: mattermost
  mysqlPassword: mattermost

service:
  type: NodePort
  nodePort: 30065

resources:
  requests:
    cpu: 100m
    memory: 256Mi
  limits:
    cpu: 500m
    memory: 512Mi
EOF
    fi

    helm upgrade --install mattermost mattermost/mattermost-team-edition \
      -f "$VALUES_FILE" \
      -n "$NAMESPACE" \
      --wait --timeout 5m \
      --create-namespace

    echo "✅ Mattermost deployed!"
    echo "🌐 Access via: kubectl port-forward -n $NAMESPACE svc/mattermost 8065:8065"
    ;;

  postgresql)
    echo "🐘 Deploying PostgreSQL..."

    add_helm_repo bitnami https://charts.bitnami.com/bitnami

    helm upgrade --install postgresql bitnami/postgresql \
      --set auth.username=fawkes \
      --set auth.password=fawkes \
      --set auth.database=fawkes \
      --set primary.persistence.enabled=false \
      -n "$NAMESPACE" \
      --wait --timeout 3m \
      --create-namespace

    echo "✅ PostgreSQL deployed!"
    echo "🔗 Connection: postgresql://fawkes:fawkes@postgresql.$NAMESPACE.svc:5432/fawkes"
    ;;

  all)
    echo "🚀 Deploying all components..."
    "$0" "$NAMESPACE" postgresql
    "$0" "$NAMESPACE" backstage
    "$0" "$NAMESPACE" argocd
    "$0" "$NAMESPACE" jenkins
    "$0" "$NAMESPACE" mattermost

    echo ""
    echo "======================================"
    echo "✅ All components deployed!"
    echo "======================================"
    echo ""
    echo "📋 Quick Access Commands:"
    echo "  Backstage:  kubectl port-forward -n $NAMESPACE svc/backstage 7007:7007"
    echo "  ArgoCD:     kubectl port-forward -n argocd svc/argocd-server 8080:443"
    echo "  Jenkins:    kubectl port-forward -n $NAMESPACE svc/jenkins 8080:8080"
    echo "  Mattermost: kubectl port-forward -n $NAMESPACE svc/mattermost 8065:8065"
    echo ""
    echo "🔍 Check status: kubectl get pods -n $NAMESPACE"
    ;;

  *)
    echo "❌ Unknown component: $COMPONENT"
    echo ""
    echo "Available components:"
    echo "  - backstage"
    echo "  - argocd"
    echo "  - jenkins"
    echo "  - mattermost"
    echo "  - postgresql"
    echo "  - all"
    exit 1
    ;;
esac

echo ""
echo "✅ $COMPONENT deployed successfully to local cluster"
echo "🔍 Run tests: make test-bdd COMPONENT=$COMPONENT"