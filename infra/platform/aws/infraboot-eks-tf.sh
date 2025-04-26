#!/usr/bin/env bash
set -euo pipefail

# infra-k8s-boot.sh - Provision AWS EKS with Terraform and deploy platform components

# --- OS Detection and Setup ---
case "$OSTYPE" in
  darwin*)  machine=MacOS;;
  msys*)    machine=GBash;;
  win*)     machine=Windows;;
  *)        echo "Unknown or unsupported OS: $OSTYPE"; exit 1;;
esac

echo "OS Identified as ${machine}"

if [ "${machine}" = "MacOS" ]; then
  ../../workspace/space-setup-macosx.sh
elif [ "${machine}" = "GBash" ]; then
  pwsh -File ../../workspace/bootstrap.ps1
fi

# --- Tool Checks ---
for tool in terraform kubectl helm aws; do
  if ! command -v "$tool" &>/dev/null; then
    echo "Error: $tool is not installed or not in PATH."
    exit 1
  fi
done

# --- Terraform: VPC & EKS Cluster ---
terraform init
terraform fmt
terraform plan
terraform apply --auto-approve

# --- Configure kubectl ---
REGION=$(terraform output -raw region)
CLUSTER_NAME=$(terraform output -raw cluster_name)
if [[ -n "$REGION" && -n "$CLUSTER_NAME" ]]; then
  aws eks --region "$REGION" update-kubeconfig --name "$CLUSTER_NAME"
else
  echo "Error: REGION or CLUSTER_NAME output is missing from Terraform."
  exit 1
fi

mkdir -p "$HOME/.kube"
cp kubeconfig_* "$HOME/.kube/config" 2>/dev/null || true
cp kubeconfig_* "$HOME/.kube/" 2>/dev/null || true
export KUBECONFIG_SAVED="${KUBECONFIG:-}"
export KUBECONFIG="$HOME/.kube/config"

# --- Create Namespaces (idempotent) ---
for ns in fawkes dev stage prod; do
  kubectl get namespace "$ns" &>/dev/null || kubectl create namespace "$ns"
done

# --- Helm Repos ---
helm repo add k8s-dashboard https://kubernetes.github.io/dashboard
helm repo add jenkinsci https://charts.jenkins.io/
helm repo add sonarqube https://SonarSource.github.io/helm-chart-sonarqube
helm repo add harbor https://helm.goharbor.io
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo add douban https://douban.github.io/charts/
helm repo add opsmx https://helmcharts.opsmx.com/
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add elastic https://helm.elastic.co
helm repo add anchore-charts https://charts.anchore.io
helm repo add cloudnativeapp https://cloudnativeapp.github.io/charts/curated/
helm repo update

# --- Platform Components (idempotent, use --namespace where possible) ---

# Kubernetes Dashboard
helm upgrade --install fawkes-k8s-dashboard k8s-dashboard/kubernetes-dashboard --namespace fawkes --version 5.0.5 --wait
helm test fawkes-k8s-dashboard --namespace fawkes || true

# Jenkins
helm upgrade --install fawkes-jenkins jenkinsci/jenkins --namespace fawkes --values jenkins/values.yaml --wait
helm test fawkes-jenkins --namespace fawkes || true

# Sonarqube
helm upgrade --install sonarqube sonarqube/sonarqube-lts --namespace fawkes --wait
helm test sonarqube --namespace fawkes || true

# Harbor
helm upgrade --install my-harbor harbor/harbor --namespace fawkes --version 1.8.1 --wait

# Keycloak
helm upgrade --install my-keycloak bitnami/keycloak --namespace fawkes --version 6.0.0 --wait

# Selenium
helm upgrade --install fawkes-selenium douban/selenium --namespace fawkes --version 1.3.0 --wait
helm test fawkes-selenium --namespace fawkes || true

# Spinnaker
helm upgrade --install fawkes-spinnaker opsmx/spinnaker --namespace fawkes --version 2.2.7 --wait
helm test fawkes-spinnaker --namespace fawkes || true

# Prometheus
helm upgrade --install fawkes-prometheus prometheus-community/prometheus --namespace fawkes --version 15.0.2 --wait
helm test fawkes-prometheus --namespace fawkes || true

# ECK Operator (Elastic)
helm upgrade --install fawkes-eck-operator elastic/eck-operator --namespace fawkes --version 1.9.1 --wait
helm test fawkes-eck-operator --namespace fawkes || true

# Anchore Engine
helm upgrade --install my-anchore-engine anchore-charts/anchore-engine --namespace fawkes --version 1.16.0 --wait
helm test my-anchore-engine --namespace fawkes || true

# Distributed JMeter
helm upgrade --install fawkes-distributed-jmeter cloudnativeapp/distributed-jmeter --namespace fawkes --version 1.0.1 --wait
helm test fawkes-distributed-jmeter --namespace fawkes || true

echo "Fawkes EKS infrastructure and platform deployment complete."

