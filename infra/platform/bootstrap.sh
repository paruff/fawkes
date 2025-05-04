#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

script_name=$(basename "${0}")
readonly script_name

# script_dir is currently unused. Remove or comment if not needed.
# script_dir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
# readonly script_dir

boot_debug=${boot_debug:-0}
# environments and jenkins_values_file are unused. Remove or comment if not needed.
# environments='dev test prod'
# jenkins_values_file=ignore/jenkins_values_final.yaml

usage() {
  echo "Usage: $script_name <command>"
  echo "Commands:"
  echo "  init           Initialize Terraform and workspace"
  echo "  plan           Run Terraform plan"
  echo "  deploy         Deploy cloud and k8s resources"
  echo "  destroy        Destroy all resources"
  echo "  show           Show outputs and service URLs"
  echo "  help           Show this help message"
  exit 1
}

check_requirements() {
  local tools=(terraform kubectl helm aws)
  for tool in "${tools[@]}"; do
    if ! command -v "$tool" &>/dev/null; then
      echo "Error: $tool is not installed or not in PATH."
      exit 1
    fi
  done
}

debug() {
  if [[ "${boot_debug}" -eq 1 ]]; then
    echo "[DEBUG] $1"
  fi
}

detect_os() {
  case "$(uname -s)" in
    Darwin)  echo "Mac" ;;
    Linux)   echo "Linux" ;;
    CYGWIN*|MINGW*|MSYS*) echo "Windows" ;;
    *)       echo "Unknown" ;;
  esac
}

prepspace() {
  local machine
  machine=$(detect_os)
  echo "Detected OS: $machine"

  case "$machine" in
    Mac)
      ../../workspace/space-setup-macosx.sh
      if ! aws-iam-authenticator -h &>/dev/null; then
        brew install aws-iam-authenticator
      fi
      ;;
    Linux)
      # Add Linux setup here if needed
      ;;
    Windows)
      ../../workspace/space-setup-win10.ps1
      ;;
    *)
      echo "Unsupported OS: $machine"
      exit 1
      ;;
  esac
}

init() {
  [ -d .terraform ] || terraform init
  mkdir -p ignore
}

plan() {
  init
  debug "Running plan"
  terraform plan
}

deploy() {
  check_requirements
  prepspace
  plan
  echo "Deploying AWS Resources using Terraform"
  deploy_cloud_resources
  deploy_k8s_resources
  show
}

destroy() {
  echo "Running terraform destroy to delete remaining resources"
  terraform destroy -auto-approve
}

deploy_cloud_resources() {
  provision_cloud
}

deploy_k8s_resources() {
  install_foundations
  install_satisfy
  install_delight
}

install_foundations() {
  install_jenkins
  install_dashboard
  install_sonarqube
  install_selenium
}

install_satisfy() {
  install_elk
  install_prometheus
  install_hygieia
}

install_delight() {
  install_anchore
  install_nexusiq
}

show() {
  export JENKINS_ADMIN_USER="admin"

  JENKINS_ADMIN_PASSWORD=$(kubectl get secret --namespace pline jenkins -o jsonpath="{.data.jenkins-admin-password}" | base64 --decode)
  export JENKINS_ADMIN_PASSWORD

  JENKINS_IP=$(kubectl get svc --namespace pline jenkins --template "{{ range (index .status.loadBalancer.ingress 0) }}{{ . }}{{ end }}")
  export JENKINS_IP

  JENKINS_LB_URL="http://$JENKINS_IP:8080"
  export JENKINS_LB_URL

  SONARQUBE_SERVICE_IP=$(kubectl get svc --namespace pline sonarqube-sonarqube --template "{{ range (index .status.loadBalancer.ingress 0) }}{{ . }}{{ end }}")
  export SONARQUBE_SERVICE_IP

  SONARQUBE_LB_URL="http://$SONARQUBE_SERVICE_IP:9000"
  export SONARQUBE_LB_URL

  token_name=$(kubectl -n kube-system get secret -o custom-columns=NAME:.metadata.name | grep dashboard-admin-user-token)
  DASHBOARD_ADMIN_TOKEN=$(kubectl -n kube-system get secret "$token_name" -o jsonpath='{.data.token}' | base64 --decode)
  export DASHBOARD_ADMIN_TOKEN

  DASHBOARD_SERVICE_IP=$(kubectl get svc --namespace kube-system kubernetes-dashboard --template "{{ range (index .status.loadBalancer.ingress 0) }}{{ . }}{{ end }}")
  export DASHBOARD_SERVICE_IP

  DASHBOARD_LB_URL="https://$DASHBOARD_SERVICE_IP"
  export DASHBOARD_LB_URL

  echo
  echo "Setup Script Outputs:"
  echo "=========================================================="
  echo
  echo "Jenkins admin user:       $JENKINS_ADMIN_USER"
  echo "Jenkins admin password:   $JENKINS_ADMIN_PASSWORD"
  echo "Jenkins LB URL            $JENKINS_LB_URL"
  echo
  echo "Sonarqube LB URL:         $SONARQUBE_LB_URL"
  echo "Sonarqube admin user:     admin"
  echo "Sonarqube admin password: admin"
  echo
  echo "Kubernetes Dashboard LB URL:         $DASHBOARD_LB_URL"
  echo "Kubernetes Dashboard admin token:    $DASHBOARD_ADMIN_TOKEN"
}

provision_cloud() {
  terraform init
  terraform fmt
  terraform plan
  terraform apply --auto-approve

  mkdir -p "$HOME/.kube"
  cp kubeconfig_* "$HOME/.kube/config"
  cp kubeconfig_* "$HOME/.kube/"

  aws eks update-kubeconfig --name pipeline

  export KUBECONFIG_SAVED=$KUBECONFIG
  export KUBECONFIG="$HOME/.kube/config"

  install_helm

  kubectl create namespace pline
  kubectl create namespace dev
  kubectl create namespace test
  kubectl create namespace prod
}

install_helm() {
  helm repo add stable https://kubernetes-charts.storage.googleapis.com
  helm repo update
}

install_jenkins() {
  helm install jenkins --namespace=pline stable/jenkins -f jenkins/values.yaml --wait
  echo "Jenkins admin password:"
  printf "%s" "$(kubectl get secret --namespace pline jenkins -o jsonpath="{.data.jenkins-admin-password}" | base64 --decode)"
  echo
  JENKINS_IP=$(kubectl get svc --namespace pline jenkins --template "{{ range (index .status.loadBalancer.ingress 0) }}{{ . }}{{ end }}")
  export JENKINS_IP
  echo "Jenkins LB URL: http://$JENKINS_IP:8080/login"
}

install_sonarqube() {
  helm install sonarqube stable/sonarqube -f sonarqube/sonarqube-values.yaml --namespace=pline --wait
  helm test sonarqube --cleanup
  export SERVICE_IP=$(kubectl get svc --namespace pline sonarqube-sonarqube --template "{{ range (index .status.loadBalancer.ingress 0) }}{{ . }}{{ end }}")
  echo "Sonarqube LB URL: http://$SERVICE_IP:9000"
}

install_selenium() {
  helm install selenium --namespace=pline stable/selenium --set chromeDebug.enabled=true --wait
}

install_prometheus() {
  kubectl create secret generic --namespace pline prometheus-prometheus-oper-prometheus-scrape-confg --from-file=prometheus/additional-scrape-configs.yaml
  helm install prometheus --namespace pline -f prometheus/prometheus-values.yaml stable/prometheus-operator --wait
}

install_elk() {
  helm install elk stable/elastic-stack -f elk-stack/elk-values.yaml --namespace=pline --wait
  helm test elk --cleanup
}

install_nexusiq() {
  kubectl apply --namespace=pline -f nexusiq/iq-server-all.yaml
}

install_anchore() {
  helm install anchore --namespace=pline stable/anchore-engine --wait
}

install_hygieia() {
  cd hygieia
  ./hygieia-reinstall.sh
  cd ..
}

install_dashboard() {
  helm install dashboard stable/kubernetes-dashboard
}

main() {
  if [[ $# -lt 1 ]]; then
    usage
  fi

  case "$1" in
    init|plan|deploy|destroy|show)
      "$@"
      ;;
    help|-h|--help)
      usage
      ;;
    *)
      echo "Unknown command: $1"
      usage
      ;;
  esac
}

main "$@"