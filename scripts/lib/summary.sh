#!/usr/bin/env bash
# =============================================================================
# File: scripts/lib/summary.sh

set -euo pipefail
# Purpose: Access summary generation for all services
# =============================================================================


get_service_password() {
  local secret_name="$1"
  local namespace="$2"
  local key="${3:-password}"
  kubectl get secret "$secret_name" -n "$namespace" -o jsonpath="{.data.$key}" 2>/dev/null | base64 -d 2>/dev/null || echo "N/A"
}

print_access_summary() {
  echo ""
  echo "════════════════════════════════════════════════════════════════════════════════"
  echo "                         🎉 FAWKES PLATFORM ACCESS GUIDE"
  echo "════════════════════════════════════════════════════════════════════════════════"
  echo ""

  local ctx
  ctx=$(kubectl config current-context 2>/dev/null || echo "unknown")
  echo "📍 Kubernetes Context: $ctx"
  echo "🌍 Environment: ${ENV}"
  if [[ -n "${PROVIDER}" ]]; then
    echo "☁️  Provider: ${PROVIDER}"
  fi
  echo ""

  local has_external=0 external_domain=""
  if kubectl get ingress -A 2>/dev/null | grep -q .; then
    has_external=1
    external_domain=$(kubectl get ingress -n "${ARGO_NS}" argocd-server -o jsonpath='{.spec.rules[0].host}' 2>/dev/null || echo "")
  fi

  echo "────────────────────────────────────────────────────────────────────────────────"
  echo "  SERVICE ACCESS INFORMATION"
  echo "────────────────────────────────────────────────────────────────────────────────"
  echo ""

  # ArgoCD
  echo "🔷 ArgoCD (GitOps CD)"
  if [[ $has_external -eq 1 && -n "$external_domain" ]]; then
    echo "   External URL: https://$external_domain"
  fi
  echo "   Local URL:    http://localhost:8080"
  echo "   Port Forward: kubectl -n ${ARGO_NS} port-forward svc/argocd-server 8080:80"
  echo "   Username:     admin"
  echo "   Password:     ${ARGOCD_PASSWORD}"
  echo ""

  # Jenkins
  if kubectl get namespace jenkins >/dev/null 2>&1; then
    echo "🔷 Jenkins (CI/CD)"
    local jenkins_host
    jenkins_host=$(kubectl get ingress -n jenkins jenkins -o jsonpath='{.spec.rules[0].host}' 2>/dev/null || echo "")
    if [[ -n "$jenkins_host" ]]; then
      echo "   External URL: https://$jenkins_host"
    fi
    echo "   Local URL:    http://localhost:8081"
    echo "   Port Forward: kubectl -n jenkins port-forward svc/jenkins 8081:8080"
    echo "   Username:     admin"
    local jenkins_pwd
    jenkins_pwd=$(get_service_password "jenkins" "jenkins" "jenkins-admin-password")
    echo "   Password:     $jenkins_pwd"
    echo ""
  fi

  # Backstage
  if kubectl get namespace backstage >/dev/null 2>&1 || kubectl get deployment -n fawkes backstage >/dev/null 2>&1; then
    local backstage_ns="backstage"
    kubectl get namespace backstage >/dev/null 2>&1 || backstage_ns="fawkes"
    echo "🔷 Backstage (Developer Portal)"
    local backstage_host
    backstage_host=$(kubectl get ingress -n "$backstage_ns" backstage -o jsonpath='{.spec.rules[0].host}' 2>/dev/null || echo "")
    if [[ -n "$backstage_host" ]]; then
      echo "   External URL: https://$backstage_host"
    fi
    echo "   Local URL:    http://localhost:7007"
    echo "   Port Forward: kubectl -n $backstage_ns port-forward svc/backstage 7007:7007"
    echo "   Auth:         GitHub OAuth or guest access"
    echo ""
  fi

  # SonarQube
  if kubectl get namespace sonarqube >/dev/null 2>&1; then
    echo "🔷 SonarQube (Code Quality)"
    local sonar_host
    sonar_host=$(kubectl get ingress -n sonarqube sonarqube -o jsonpath='{.spec.rules[0].host}' 2>/dev/null || echo "")
    if [[ -n "$sonar_host" ]]; then
      echo "   External URL: https://$sonar_host"
    fi
    echo "   Local URL:    http://localhost:9000"
    echo "   Port Forward: kubectl -n sonarqube port-forward svc/sonarqube 9000:9000"
    echo "   Username:     admin"
    echo "   Password:     admin (change on first login)"
    echo ""
  fi

  # Grafana
  if kubectl get namespace grafana >/dev/null 2>&1 || kubectl get deployment -n fawkes grafana >/dev/null 2>&1; then
    local grafana_ns="grafana"
    kubectl get namespace grafana >/dev/null 2>&1 || grafana_ns="fawkes"
    echo "🔷 Grafana (Observability)"
    local grafana_host
    grafana_host=$(kubectl get ingress -n "$grafana_ns" grafana -o jsonpath='{.spec.rules[0].host}' 2>/dev/null || echo "")
    if [[ -n "$grafana_host" ]]; then
      echo "   External URL: https://$grafana_host"
    fi
    echo "   Local URL:    http://localhost:3000"
    echo "   Port Forward: kubectl -n $grafana_ns port-forward svc/grafana 3000:80"
    echo "   Username:     admin"
    local grafana_pwd
    grafana_pwd=$(get_service_password "grafana" "$grafana_ns" "admin-password")
    echo "   Password:     $grafana_pwd"
    echo ""
  fi

  # Prometheus
  if kubectl get namespace prometheus >/dev/null 2>&1 || kubectl get deployment -n fawkes prometheus-server >/dev/null 2>&1; then
    local prom_ns="prometheus"
    kubectl get namespace prometheus >/dev/null 2>&1 || prom_ns="fawkes"
    echo "🔷 Prometheus (Metrics)"
    echo "   Local URL:    http://localhost:9090"
    echo "   Port Forward: kubectl -n $prom_ns port-forward svc/prometheus-server 9090:80"
    echo ""
  fi

  # Mattermost
  if kubectl get namespace mattermost >/dev/null 2>&1; then
    echo "🔷 Mattermost (Team Chat)"
    local mm_host
    mm_host=$(kubectl get ingress -n mattermost mattermost -o jsonpath='{.spec.rules[0].host}' 2>/dev/null || echo "")
    if [[ -n "$mm_host" ]]; then
      echo "   External URL: https://$mm_host"
    fi
    echo "   Local URL:    http://localhost:8065"
    echo "   Port Forward: kubectl -n mattermost port-forward svc/mattermost 8065:8065"
    echo "   Setup:        Create admin account on first access"
    echo ""
  fi

  # Focalboard
  if kubectl get namespace focalboard >/dev/null 2>&1; then
    echo "🔷 Focalboard (Project Management)"
    local fb_host
    fb_host=$(kubectl get ingress -n focalboard focalboard -o jsonpath='{.spec.rules[0].host}' 2>/dev/null || echo "")
    if [[ -n "$fb_host" ]]; then
      echo "   External URL: https://$fb_host"
    fi
    echo "   Local URL:    http://localhost:8000"
    echo "   Port Forward: kubectl -n focalboard port-forward svc/focalboard 8000:8000"
    echo ""
  fi

  echo "────────────────────────────────────────────────────────────────────────────────"
  echo "  QUICK COMMANDS"
  echo "────────────────────────────────────────────────────────────────────────────────"
  echo ""
  echo "View all pods:              kubectl get pods -A"
  echo "View ArgoCD apps:           kubectl get applications -n ${ARGO_NS}"
  echo "View application logs:      kubectl logs -n <namespace> <pod-name> -f"
  echo "Check ingress:              kubectl get ingress -A"
  echo "View nodes:                 kubectl get nodes -o wide"
  echo ""
  echo "ArgoCD CLI login:"
  echo "  argocd login localhost:8080 --username admin --password ${ARGOCD_PASSWORD} --insecure"
  echo ""

  if [[ "${PROVIDER}" == "azure" ]]; then
    echo "────────────────────────────────────────────────────────────────────────────────"
    echo "  AZURE-SPECIFIC"
    echo "────────────────────────────────────────────────────────────────────────────────"
    echo ""
    echo "View AKS cluster:           az aks show -g ${TF_VAR_resource_group_name:-fawkes-rg} -n ${TF_VAR_cluster_name:-fawkes-dev}"
    echo "Get credentials:            az aks get-credentials -g ${TF_VAR_resource_group_name:-fawkes-rg} -n ${TF_VAR_cluster_name:-fawkes-dev}"
    echo "Open Azure Portal:          https://portal.azure.com/#resource/subscriptions/${ARM_SUBSCRIPTION_ID}/resourceGroups/${TF_VAR_resource_group_name:-fawkes-rg}/providers/Microsoft.ContainerService/managedClusters/${TF_VAR_cluster_name:-fawkes-dev}"
    echo ""
  fi

  echo "════════════════════════════════════════════════════════════════════════════════"
  echo "  📚 Documentation: ./docs/ or https://github.com/yourorg/fawkes/docs"
  echo "  🐛 Issues: https://github.com/yourorg/fawkes/issues"
  echo "  💬 Support: #fawkes-platform on Mattermost"
  echo "════════════════════════════════════════════════════════════════════════════════"
  echo ""
}

post_deploy_summary() {
  print_access_summary
}
