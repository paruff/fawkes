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
add_helm_repo k8s-dashboard https://kubernetes.github.io/dashboard
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

deploy_chart fawkes-k8s-dashboard k8s-dashboard/kubernetes-dashboard --version 7.0.0
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

echo "All platform components have been deployed (or upgraded) in the '$NAMESPACE' namespace."

