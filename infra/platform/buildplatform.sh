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

# Add and update Helm repos
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

# Kubernetes Dashboard
helm upgrade --install fawkes-k8s-dashboard k8s-dashboard/kubernetes-dashboard --namespace "$NAMESPACE" --version 5.0.5 --wait

# Jenkins
helm upgrade --install fawkes-jenkins jenkinsci/jenkins --namespace "$NAMESPACE" --values jenkins/values.yaml --wait

# Sonarqube
helm upgrade --install sonarqube sonarqube/sonarqube-lts --namespace "$NAMESPACE" --wait

# Harbor
helm upgrade --install my-harbor harbor/harbor --namespace "$NAMESPACE" --version 1.8.1 --wait

# Keycloak
helm upgrade --install my-keycloak bitnami/keycloak --namespace "$NAMESPACE" --version 6.0.0 --wait

# Selenium
helm upgrade --install fawkes-selenium douban/selenium --namespace "$NAMESPACE" --version 1.3.0 --wait

# Spinnaker
helm upgrade --install fawkes-spinnaker opsmx/spinnaker --namespace "$NAMESPACE" --version 2.2.7 --wait

# Prometheus
helm upgrade --install fawkes-prometheus prometheus-community/prometheus --namespace "$NAMESPACE" --version 15.0.2 --wait

# ECK Operator (Elastic)
helm upgrade --install fawkes-eck-operator elastic/eck-operator --namespace "$NAMESPACE" --version 1.9.1 --wait

# Anchore Engine
helm upgrade --install my-anchore-engine anchore-charts/anchore-engine --namespace "$NAMESPACE" --version 1.16.0 --wait

# Distributed JMeter
helm upgrade --install fawkes-distributed-jmeter cloudnativeapp/distributed-jmeter --namespace "$NAMESPACE" --version 1.0.1 --wait

echo "All platform components have been deployed (or upgraded) in the '$NAMESPACE' namespace."

