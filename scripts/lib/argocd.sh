#!/usr/bin/env bash
# =============================================================================
# File: scripts/lib/argocd.sh

set -euo pipefail
# Purpose: ArgoCD deployment and management
# =============================================================================


set -euo pipefail
maybe_cleanup_argocd_cluster_resources() {
  set +e
  if [[ "${ENV}" != "local" ]]; then return 0; fi
  if kubectl get clusterrole argocd-application-controller >/dev/null 2>&1 \
    || kubectl get crd applications.argoproj.io >/dev/null 2>&1; then
    echo "⚠️  Detected pre-existing Argo CD cluster-scoped resources. These can block Helm from installing."
    local do_clean="N"
    if [[ "${AUTO_CLEAN_ARGO:-}" == "1" || "${AUTO_CLEAN_ARGO:-}" == "true" || "${2:-}" == "--auto-clean" ]]; then
      do_clean="Y"
    else
      read -r -p "Do you want to clean them up now? [y/N]: " do_clean
    fi
    if [[ "$do_clean" =~ ^[Yy]$ ]]; then
      echo "🧹 Removing Argo CD cluster-scoped resources (CRDs, ClusterRoles, ClusterRoleBindings)..."
      local CRDS
      CRDS=$(kubectl get crd -o name 2>/dev/null | grep -E 'argoproj.io' || true)
      if [[ -n "$CRDS" ]]; then echo "$CRDS" | xargs kubectl delete --wait --ignore-not-found; fi
      local CROLES
      CROLES=$(kubectl get clusterrole -o name 2>/dev/null | grep -E '^clusterrole/argocd' || true)
      if [[ -n "$CROLES" ]]; then echo "$CROLES" | xargs kubectl delete --wait --ignore-not-found; fi
      local CRBINDINGS
      CRBINDINGS=$(kubectl get clusterrolebinding -o name 2>/dev/null | grep -E '^clusterrolebinding/argocd' || true)
      if [[ -n "$CRBINDINGS" ]]; then echo "$CRBINDINGS" | xargs kubectl delete --wait --ignore-not-found; fi
      echo "✅ Cleanup complete."
    else
      echo "Proceeding without cleanup; Helm may fail if resources exist."
    fi
  fi
  set -e
}

deploy_argocd() {
  local TF_MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../infra/terraform/argocd" && pwd)"
  echo "Deploying ArgoCD via Terraform module at ${TF_MODULE_DIR}"
  local TEMP_KUBECONFIG
  TEMP_KUBECONFIG=$(mktemp -t fawkes-kubeconfig-XXXX.yaml)
  kubectl config view --raw --minify --flatten >"${TEMP_KUBECONFIG}"
  local PREV_KUBECONFIG="${KUBECONFIG-}"
  local PREV_TF_VAR_KUBECONFIG_PATH="${TF_VAR_kubeconfig_path-}"
  export KUBECONFIG="${TEMP_KUBECONFIG}"
  export TF_VAR_kubeconfig_path="${TEMP_KUBECONFIG}"
  echo "Using temporary KUBECONFIG at ${KUBECONFIG} for Terraform operations"
  pushd "${TF_MODULE_DIR}" >/dev/null
  echo "Running: terraform init (with -upgrade to reconcile provider constraints)"
  terraform init -upgrade -input=false 2>&1 | tee terraform.log
  echo "Running: terraform plan"
  terraform plan -input=false -out=plan.tfplan 2>&1 | tee -a terraform.log
  local rc=0
  if [[ ${DRY_RUN:-0} -eq 1 ]]; then
    echo "[DRY-RUN] Skipping terraform apply for ArgoCD module"
  else
    echo "Applying plan.tfplan"
    terraform apply -input=false plan.tfplan 2>&1 | tee -a terraform.log
    rc=${PIPESTATUS[0]}
  fi
  popd >/dev/null
  if [[ -n "${PREV_KUBECONFIG-}" ]]; then
    export KUBECONFIG="${PREV_KUBECONFIG}"
  else
    unset KUBECONFIG
  fi
  if [[ -n "${PREV_TF_VAR_KUBECONFIG_PATH-}" ]]; then
    export TF_VAR_kubeconfig_path="${PREV_TF_VAR_KUBECONFIG_PATH}"
  else
    unset TF_VAR_kubeconfig_path
  fi
  rm -f "${TEMP_KUBECONFIG}" || true
  if [[ ${rc} -ne 0 ]]; then
    error_exit "Terraform apply for ArgoCD failed; see ${TF_MODULE_DIR}/terraform.log"
  fi
  if [[ ${DRY_RUN:-0} -eq 1 ]]; then
    echo "[DRY-RUN] Skipping ArgoCD wait and password steps"
    return 0
  fi
  echo "⏳ Waiting for ArgoCD server to be available..."
  kubectl wait --for=condition=available deployment/argocd-server -n "${ARGO_NS}" --timeout=300s
  ARGOCD_PASSWORD=$(kubectl -n "${ARGO_NS}" get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
  if [[ "${ENV}" == "local" ]]; then
    local FAWKES_LOCAL_PASSWORD="${FAWKES_LOCAL_PASSWORD:-fawkesidp}"
    if command -v argocd >/dev/null 2>&1; then
      echo "🔐 Setting ArgoCD admin password to a local default for developers..."
      local svc_ports svc_scheme svc_target_port
      svc_ports=$(kubectl -n "${ARGO_NS}" get svc argocd-server -o jsonpath='{.spec.ports[*].port}' 2>/dev/null || echo "")
      if echo "${svc_ports}" | grep -qw 80; then
        svc_target_port=80
        svc_scheme="http"
        local argocd_login_flag="--plaintext"
      elif echo "${svc_ports}" | grep -qw 443; then
        svc_target_port=443
        svc_scheme="https"
        local argocd_login_flag="--insecure"
      else
        svc_target_port=$(kubectl -n "${ARGO_NS}" get svc argocd-server -o jsonpath='{.spec.ports[0].port}' 2>/dev/null || echo 80)
        svc_scheme="http"
        local argocd_login_flag="--plaintext"
      fi
      (
        kubectl -n "${ARGO_NS}" port-forward svc/argocd-server 8080:${svc_target_port} >/dev/null 2>&1 &
        echo $! >/tmp/fawkes-argocd-pf.pid
      )
      sleep 2
      set +e
      argocd login localhost:8080 --username admin --password "${ARGOCD_PASSWORD}" ${argocd_login_flag} >/dev/null 2>&1
      if [[ $? -eq 0 ]]; then
        argocd account update-password --current-password "${ARGOCD_PASSWORD}" --new-password "${FAWKES_LOCAL_PASSWORD}" >/dev/null 2>&1 && ARGOCD_PASSWORD="${FAWKES_LOCAL_PASSWORD}"
      else
        echo "[WARN] ArgoCD CLI login failed; attempting password change via kubectl proxy..." >&2
        (
          kubectl proxy --address 127.0.0.1 --port=8001 >/dev/null 2>&1 &
          echo $! >/tmp/fawkes-kubectl-proxy.pid
        )
        sleep 2
        local proxy_base="http://127.0.0.1:8001/api/v1/namespaces/${ARGO_NS}/services/${svc_scheme}:argocd-server:${svc_target_port}/proxy"
        local token
        token=$(curl -sk -X POST -H "Content-Type: application/json" \
          -d '{"username":"admin","password":"'"${ARGOCD_PASSWORD}"'"}' \
          "${proxy_base}/api/v1/session" | jq -r '.token // empty')
        if [[ -n "${token}" ]]; then
          curl -sk -X PUT -H "Authorization: Bearer ${token}" -H "Content-Type: application/json" \
            -d '{"currentPassword":"'"${ARGOCD_PASSWORD}"'","newPassword":"'"${FAWKES_LOCAL_PASSWORD}"'"}' \
            "${proxy_base}/api/v1/account/password" >/dev/null 2>&1 && ARGOCD_PASSWORD="${FAWKES_LOCAL_PASSWORD}" \
            || echo "[WARN] Password change via API proxy did not succeed." >&2
        else
          echo "[WARN] Could not obtain ArgoCD auth token via API proxy; keeping initial password." >&2
        fi
        if [[ -f /tmp/fawkes-kubectl-proxy.pid ]]; then
          kill $(cat /tmp/fawkes-kubectl-proxy.pid) >/dev/null 2>&1 || true
          rm -f /tmp/fawkes-kubectl-proxy.pid || true
        fi
      fi
      set -e
      if [[ -f /tmp/fawkes-argocd-pf.pid ]]; then
        kill $(cat /tmp/fawkes-argocd-pf.pid) >/dev/null 2>&1 || true
        rm -f /tmp/fawkes-argocd-pf.pid || true
      fi
    else
      echo "[WARN] 'argocd' CLI not found; skipping automatic password change."
    fi
  fi
  local svc_ports_summary svc_scheme_summary svc_target_port_summary
  svc_ports_summary=$(kubectl -n "${ARGO_NS}" get svc argocd-server -o jsonpath='{.spec.ports[*].port}' 2>/dev/null || echo "")
  if echo "${svc_ports_summary}" | grep -qw 80; then
    svc_target_port_summary=80
    svc_scheme_summary="http"
  elif echo "${svc_ports_summary}" | grep -qw 443; then
    svc_target_port_summary=443
    svc_scheme_summary="https"
  else
    svc_target_port_summary=$(kubectl -n "${ARGO_NS}" get svc argocd-server -o jsonpath='{.spec.ports[0].port}' 2>/dev/null || echo 80)
    svc_scheme_summary="http"
  fi
  echo ""
  echo "==================== ArgoCD Credentials ===================="
  echo "URL:      ${svc_scheme_summary}://localhost:8080 (use port-forward below)"
  echo "Username: admin"
  echo "Password: ${ARGOCD_PASSWORD}"
  echo "============================================================"
  echo ""
}

ensure_argocd_workloads() {
  echo "🌐 Ensuring ArgoCD deployments are available..."
  for dep in argocd-server argocd-repo-server argocd-application-controller argocd-dex-server; do
    if ! wait_for_workload "${dep}" "${ARGO_NS}" 300; then
      error_exit "Deployment ${dep} failed to become available"
    fi
  done
}

wait_for_argocd_endpoints() {
  echo "⏳ Waiting for argocd-server service endpoints..."
  local ENDPOINTS_TIMEOUT=120
  local end=$((SECONDS + ENDPOINTS_TIMEOUT))
  while [[ ${SECONDS} -lt ${end} ]]; do
    if kubectl get endpoints argocd-server -n "${ARGO_NS}" -o jsonpath='{.subsets}' | grep -q .; then
      echo "✅ argocd-server has endpoints"
      return 0
    fi
    sleep 2
  done
  kubectl -n "${ARGO_NS}" get endpoints
  error_exit "argocd-server service has no endpoints after ${ENDPOINTS_TIMEOUT}s"
}

seed_applications() {
  echo "🌐 Applying bootstrap kustomization from platform/bootstrap..."
  kubectl apply -k "${ROOT_DIR}/platform/bootstrap"
  echo "✅ Bootstrap applied — ArgoCD will pick up Applications and sync."
}
