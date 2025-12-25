#!/usr/bin/env bash
# =============================================================================
# File: scripts/access-summary.sh
# Purpose: Display access information for Fawkes platform services
# Usage: ./scripts/access-summary.sh [service|provider]
#   service: argocd, jenkins, backstage, grafana, prometheus, sonarqube, mattermost, focalboard
#   provider: azure, aws, gcp
# =============================================================================

set -euo pipefail

ARGO_NS="${ARGOCD_NAMESPACE:-fawkes}"
SERVICE="${1:-all}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_header() {
  echo ""
  echo "════════════════════════════════════════════════════════════════════════════════"
  echo "  $1"
  echo "════════════════════════════════════════════════════════════════════════════════"
  echo ""
}

print_service_header() {
  echo ""
  echo "────────────────────────────────────────────────────────────────────────────────"
  echo -e "  ${BLUE}$1${NC}"
  echo "────────────────────────────────────────────────────────────────────────────────"
}

get_password() {
  local secret="$1" namespace="$2" key="${3:-password}"
  kubectl get secret "$secret" -n "$namespace" -o jsonpath="{.data.$key}" 2>/dev/null | base64 -d 2>/dev/null || echo "N/A"
}

check_namespace() {
  kubectl get namespace "$1" >/dev/null 2>&1
}

get_ingress_host() {
  local name="$1" namespace="$2"
  kubectl get ingress -n "$namespace" "$name" -o jsonpath='{.spec.rules[0].host}' 2>/dev/null || echo ""
}

port_forward() {
  local service="$1" namespace="$2" local_port="$3" remote_port="$4"
  echo -e "${GREEN}Starting port-forward...${NC}"
  kubectl -n "$namespace" port-forward "svc/$service" "$local_port:$remote_port" &
  local PF_PID=$!
  echo "Port-forward PID: $PF_PID (kill with: kill $PF_PID)"
  echo "Press Ctrl+C to stop port-forward"
  wait $PF_PID
}

show_argocd() {
  print_service_header "🔷 ArgoCD (GitOps CD)"

  if ! check_namespace "$ARGO_NS"; then
    echo -e "${RED}ArgoCD namespace not found${NC}"
    return 1
  fi

  local host
  host=$(get_ingress_host "argocd-server" "$ARGO_NS")
  if [[ -n "$host" ]]; then
    echo "   External URL: https://$host"
  fi

  echo "   Local URL:    http://localhost:8080"
  echo "   Namespace:    $ARGO_NS"
  echo ""
  echo "   Username:     admin"

  local password
  password=$(get_password "argocd-initial-admin-secret" "$ARGO_NS" "password")
  echo "   Password:     $password"
  echo ""
  echo "   Port Forward: kubectl -n $ARGO_NS port-forward svc/argocd-server 8080:80"
  echo ""
  echo "   CLI Login:    argocd login localhost:8080 --username admin --password '$password' --insecure"
  echo ""

  if [[ "$SERVICE" == "argocd" ]]; then
    read -p "Start port-forward now? [y/N]: " START_PF
    if [[ "$START_PF" =~ ^[Yy]$ ]]; then
      port_forward "argocd-server" "$ARGO_NS" "8080" "80"
    fi
  fi
}

show_jenkins() {
  print_service_header "🔷 Jenkins (CI/CD)"

  if ! check_namespace "jenkins"; then
    echo -e "${YELLOW}Jenkins namespace not found (not deployed)${NC}"
    return 0
  fi

  local host
  host=$(get_ingress_host "jenkins" "jenkins")
  if [[ -n "$host" ]]; then
    echo "   External URL: https://$host"
  fi

  echo "   Local URL:    http://localhost:8081"
  echo "   Namespace:    jenkins"
  echo ""
  echo "   Username:     admin"

  local password
  password=$(get_password "jenkins" "jenkins" "jenkins-admin-password")
  echo "   Password:     $password"
  echo ""
  echo "   Port Forward: kubectl -n jenkins port-forward svc/jenkins 8081:8080"
  echo ""

  if [[ "$SERVICE" == "jenkins" ]]; then
    read -p "Start port-forward now? [y/N]: " START_PF
    if [[ "$START_PF" =~ ^[Yy]$ ]]; then
      port_forward "jenkins" "jenkins" "8081" "8080"
    fi
  fi
}

show_backstage() {
  print_service_header "🔷 Backstage (Developer Portal)"

  local ns="backstage"
  check_namespace "backstage" || ns="fawkes"

  if ! check_namespace "$ns"; then
    echo -e "${YELLOW}Backstage namespace not found (not deployed)${NC}"
    return 0
  fi

  local host
  host=$(get_ingress_host "backstage" "$ns")
  if [[ -n "$host" ]]; then
    echo "   External URL: https://$host"
  fi

  echo "   Local URL:    http://localhost:7007"
  echo "   Namespace:    $ns"
  echo ""
  echo "   Auth:         GitHub OAuth or guest access"
  echo ""
  echo "   Port Forward: kubectl -n $ns port-forward svc/backstage 7007:7007"
  echo ""

  if [[ "$SERVICE" == "backstage" ]]; then
    read -p "Start port-forward now? [y/N]: " START_PF
    if [[ "$START_PF" =~ ^[Yy]$ ]]; then
      port_forward "backstage" "$ns" "7007" "7007"
    fi
  fi
}

show_grafana() {
  print_service_header "🔷 Grafana (Observability)"

  local ns="grafana"
  check_namespace "grafana" || ns="fawkes"

  if ! check_namespace "$ns"; then
    echo -e "${YELLOW}Grafana namespace not found (not deployed)${NC}"
    return 0
  fi

  local host
  host=$(get_ingress_host "grafana" "$ns")
  if [[ -n "$host" ]]; then
    echo "   External URL: https://$host"
  fi

  echo "   Local URL:    http://localhost:3000"
  echo "   Namespace:    $ns"
  echo ""
  echo "   Username:     admin"

  local password
  password=$(get_password "grafana" "$ns" "admin-password")
  echo "   Password:     $password"
  echo ""
  echo "   Port Forward: kubectl -n $ns port-forward svc/grafana 3000:80"
  echo ""

  if [[ "$SERVICE" == "grafana" ]]; then
    read -p "Start port-forward now? [y/N]: " START_PF
    if [[ "$START_PF" =~ ^[Yy]$ ]]; then
      port_forward "grafana" "$ns" "3000" "80"
    fi
  fi
}

show_prometheus() {
  print_service_header "🔷 Prometheus (Metrics)"

  local ns="prometheus"
  check_namespace "prometheus" || ns="fawkes"

  if ! check_namespace "$ns"; then
    echo -e "${YELLOW}Prometheus namespace not found (not deployed)${NC}"
    return 0
  fi

  echo "   Local URL:    http://localhost:9090"
  echo "   Namespace:    $ns"
  echo ""
  echo "   Port Forward: kubectl -n $ns port-forward svc/prometheus-server 9090:80"
  echo ""
}

show_sonarqube() {
  print_service_header "🔷 SonarQube (Code Quality)"

  if ! check_namespace "sonarqube"; then
    echo -e "${YELLOW}SonarQube namespace not found (not deployed)${NC}"
    return 0
  fi

  local host
  host=$(get_ingress_host "sonarqube" "sonarqube")
  if [[ -n "$host" ]]; then
    echo "   External URL: https://$host"
  fi

  echo "   Local URL:    http://localhost:9000"
  echo "   Namespace:    sonarqube"
  echo ""
  echo "   Username:     admin"
  echo "   Password:     admin (change on first login)"
  echo ""
  echo "   Port Forward: kubectl -n sonarqube port-forward svc/sonarqube 9000:9000"
  echo ""
}

show_cluster_info() {
  print_service_header "📍 Cluster Information"

  local ctx
  ctx=$(kubectl config current-context 2>/dev/null || echo "unknown")
  echo "   Context:      $ctx"

  local nodes
  nodes=$(kubectl get nodes --no-headers 2>/dev/null | wc -l | tr -d ' ')
  echo "   Nodes:        $nodes"

  local version
  version=$(kubectl version --short 2>/dev/null | grep "Server Version" | awk '{print $3}' || echo "unknown")
  echo "   K8s Version:  $version"
  echo ""
}

show_azure_info() {
  if ! command -v az >/dev/null 2>&1; then
    return 0
  fi

  print_service_header "☁️  Azure AKS Information"

  local rg="${TF_VAR_resource_group_name:-fawkes-rg}"
  local cluster="${TF_VAR_cluster_name:-fawkes-dev}"

  if az aks show -g "$rg" -n "$cluster" >/dev/null 2>&1; then
    echo "   Resource Group: $rg"
    echo "   Cluster Name:   $cluster"
    echo ""
    echo "   Azure Portal:"
    echo "   https://portal.azure.com/#resource/subscriptions/${ARM_SUBSCRIPTION_ID}/resourceGroups/${rg}/providers/Microsoft.ContainerService/managedClusters/${cluster}"
    echo ""
    echo "   Useful Commands:"
    echo "   az aks show -g $rg -n $cluster"
    echo "   az aks get-credentials -g $rg -n $cluster --overwrite-existing"
    echo "   az aks browse -g $rg -n $cluster"
    echo ""
  fi
}

show_quick_commands() {
  print_service_header "⚡ Quick Commands"

  echo "   View all pods:         kubectl get pods -A"
  echo "   View ArgoCD apps:      kubectl get applications -n $ARGO_NS"
  echo "   View ingress:          kubectl get ingress -A"
  echo "   View nodes:            kubectl get nodes -o wide"
  echo "   Describe pod:          kubectl describe pod <pod-name> -n <namespace>"
  echo "   View logs:             kubectl logs -n <namespace> <pod-name> -f"
  echo "   Execute in pod:        kubectl exec -it -n <namespace> <pod-name> -- /bin/bash"
  echo ""
}

# Main execution
main() {
  print_header "🎉 FAWKES PLATFORM ACCESS GUIDE"

  case "$SERVICE" in
    all)
      show_cluster_info
      show_argocd
      show_jenkins
      show_backstage
      show_grafana
      show_prometheus
      show_sonarqube
      show_quick_commands
      ;;
    argocd) show_argocd ;;
    jenkins) show_jenkins ;;
    backstage) show_backstage ;;
    grafana) show_grafana ;;
    prometheus) show_prometheus ;;
    sonarqube) show_sonarqube ;;
    azure)
      show_cluster_info
      show_azure_info
      show_argocd
      show_quick_commands
      ;;
    *)
      echo "Unknown service: $SERVICE"
      echo "Usage: $0 [all|argocd|jenkins|backstage|grafana|prometheus|sonarqube|azure]"
      exit 1
      ;;
  esac

  echo "════════════════════════════════════════════════════════════════════════════════"
  echo ""
}

main