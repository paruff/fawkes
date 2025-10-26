#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="fawkes"

# Check for required tools
for tool in helm kubectl; do
  if ! command -v "$tool" &>/dev/null; then
    echo "Error: $tool is not installed or not in PATH."
    exit 1
  fi
done

# Create namespace if it doesn't exist
if ! kubectl get namespace "$NAMESPACE" &>/dev/null; then
  kubectl create namespace "$NAMESPACE"
fi

# Function to add a Helm repo only if it doesn't already exist
add_helm_repo() {
  local name="$1"
  local url="$2"
  if ! helm repo list | grep -q "^$name"; then
    helm repo add "$name" "$url"
  fi
}

# Add and update Helm repos (no deprecated 'stable' repo)
add_helm_repo kubernetes-dashboard https://kubernetes.github.io/dashboard
add_helm_repo jenkinsci https://charts.jenkins.io/
add_helm_repo sonarqube https://SonarSource.github.io/helm-chart-sonarqube
add_helm_repo harbor https://helm.goharbor.io
add_helm_repo bitnami https://charts.bitnami.com/bitnami
add_helm_repo douban https://douban.github.io/charts/
add_helm_repo opsmx https://helmcharts.opsmx.com/
add_helm_repo prometheus-community https://prometheus-community.github.io/helm-charts
add_helm_repo elastic https://helm.elastic.co
add_helm_repo anchore-charts https://charts.anchore.io
add_helm_repo cloudnativeapp https://cloudnativeapp.github.io/charts/curated/
add_helm_repo devlake https://apache.github.io/incubator-devlake-helm-chart/
helm repo update

# Deploy platform components
deploy_chart() {
  local release="$1"
  local chart="$2"
  shift 2
  echo "Deploying $release from $chart..."
  if ! helm upgrade --install "$release" "$chart" --namespace "$NAMESPACE" --wait "$@"; then
    echo "Error: Failed to deploy $release"
    exit 1
  fi
}

helm upgrade --install kubernetes-dashboard kubernetes-dashboard/kubernetes-dashboard --create-namespace --namespace kubernetes-dashboard

# deploy_chart kubernetes-dashboard kubernetes-dashboard/kubernetes-dashboard --version 7.0.0
openssl rand -base64 2000 | tr -dc 'A-Z' | fold -w 128 | head -n 1
kubectl create secret generic devlake-encryption-secret \
  --from-literal=ENCODE_KEY=<your-encryption-key> \
  -n fawkes
deploy_chart apache-devlake devlake/devlake --version 0.21.0

deploy_chart fawkes-jenkins jenkinsci/jenkins --version 5.1.13 --values jenkins/values.yaml
deploy_chart sonarqube sonarqube/sonarqube-lts --version 10.5.0
deploy_chart my-harbor harbor/harbor --version 1.14.2
deploy_chart my-keycloak bitnami/keycloak --version 21.2.2
deploy_chart fawkes-selenium douban/selenium --version 1.3.0
deploy_chart fawkes-spinnaker opsmx/spinnaker --version 2.2.7
deploy_chart fawkes-prometheus prometheus-community/prometheus --version 56.0.0
deploy_chart fawkes-eck-operator elastic/eck-operator --version 2.11.1
deploy_chart my-anchore-engine anchore-charts/anchore-engine --version 1.21.0
deploy_chart fawkes-distributed-jmeter cloudnativeapp/distributed-jmeter --version 1.0.1
deploy_chart apache-devlake devlake/devlake --version 0.21.0

echo "All platform components have been deployed (or upgraded) in the '$NAMESPACE' namespace."

# --- Application Testing Section ---
echo "Testing deployed applications with 'helm test'..."

test_chart() {
  local release="$1"
  echo "Running helm test for $release..."
  if ! helm test "$release" --namespace "$NAMESPACE" --timeout 5m; then
    echo "Warning: helm test failed for $release"
  fi
}

test_chart fawkes-k8s-dashboard
test_chart fawkes-jenkins
test_chart sonarqube
test_chart my-harbor
test_chart my-keycloak
test_chart fawkes-selenium
test_chart fawkes-spinnaker
test_chart fawkes-prometheus
test_chart fawkes-eck-operator
test_chart my-anchore-engine
test_chart fawkes-distributed-jmeter
test_chart apache-devlake

echo "Helm tests completed for all platform components in the '$NAMESPACE' namespace."

