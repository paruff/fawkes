#!/usr/bin/env bash
# =============================================================================
# File: scripts/ignite.sh
# Purpose: Orchestrate Fawkes bootstrap across local test clusters and cloud providers (AWS, Azure, GCP, others): installs prerequisites, can provision a target Kubernetes cluster (via Terraform/provider tooling), then deploys Argo CD and initial Applications. Local runs are for fast validation before cloud deployment.
# Implementation Plan (Transition to Full Multi-Cloud Bootstrap)
# 1. Modularize phases: check_prereqs, provision_cluster, deploy_argocd, seed_applications, post_deploy_summary, cleanup.
# 2. Abstract provider selection: --provider [local|aws|azure|gcp] with per-provider function dispatch.
# 3. Introduce flags: --cluster-name, --region/--location, --only-cluster, --only-apps, --skip-cluster, --dry-run, --resume, --verbose.
# 4. Externalize provider config (e.g. config/providers/<provider>.yaml) for regions, versions, instance types, Terraform module paths.
# 5. Split Terraform: dedicated root modules per provider (infra/aws, infra/azure, infra/gcp) invoked conditionally instead of single argocd module.
# 6. Implement idempotent step tracking (state file .ignite-state.json) enabling --resume after partial failures.
# 7. Refactor local-only (minikube/docker-desktop) logic into provision_local_cluster() separated from cloud drivers.
# 8. Add provider cluster validation (health checks: API reachability, node readiness, storage class existence) before Argo CD deploy.
# 9. Integrate External Secrets Operator + provider secret stores automatically when --provider != local (AWS SM, Azure Key Vault, GCP Secret Manager).
# 10. Enhance logging: structured key=value lines with timestamps; optional JSON log (--log-format json).
# 11. Add observability hooks: emit bootstrap duration & step metrics (Prometheus pushgateway optional) and trace IDs for troubleshooting.
# 12. Security hardening: ensure no plaintext secrets in logs; verify External Secrets adoption before pruning legacy Secret manifests.
# 13. Makefile targets: make ignite-local, ignite-aws, ignite-azure, ignite-gcp, ignite-clean mapping to appropriate flags.
# 14. Add CI pipeline stages: plan cluster, apply cluster, deploy apps; include drift detection & destroy job for ephemeral environments.
# 15. Testing: add bats tests for flag parsing & dry-run; create validation harness that mocks kubectl/terraform.
# 16. Documentation: update docs/getting-started.md + architecture.md with multi-cloud flow diagrams; add usage matrix of flags per provider.
# 17. Deprecation: remove inline Argo CD Application CR heredoc after externalizing manifests to platform/apps; ensure sync relies on GitOps only.
# 18. Future: replace direct Terraform cluster provisioning with Crossplane compositions once stable; keep provider abstraction compatible.
# Context: [local|CI|prod], [caller or workflow]
# Usage: [bash ./scripts/ignite.sh local,aws,azure,gcc local,dev,staging,prod]
# Usage:
#   - bash ./scripts/ignite.sh clean
#   - AUTO_CLEAN_ARGO=1 FAWKES_LOCAL_PASSWORD=fawkesidp bash ./scripts/ignite.sh local
#   - MINIKUBE_DRIVER=docker bash ./scripts/ignite.sh local
#   - bash ./scripts/ignite.sh [dev|stage|production]  # requires a valid kubectl context
# Inputs:
#   - Env: ARGOCD_NAMESPACE (default=fawkes), AUTO_INSTALL, AUTO_CLEAN_ARGO,
#          FAWKES_LOCAL_PASSWORD (default=fawkesidp), MINIKUBE_MEMORY, MINIKUBE_CPUS,
#          MINIKUBE_DISK_SIZE, MINIKUBE_DRIVER, KUBECONFIG (auto-set), TF_VAR_kubeconfig_path (auto-set)
# Outputs:
#   - Argo CD installed in namespace 'fawkes' with Application CRs applied
#   - Admin password printed (and set to FAWKES_LOCAL_PASSWORD for local if argocd CLI present)
#   - Terraform log at infra/terraform/argocd/terraform.log
#   - Namespaces/CRDs/cluster-scoped resources created as needed; exit code reflects success/failure
# Dependencies: kubectl, terraform, helm, argocd (optional), docker or minikube, jq, base64
# Owner: Fawkes Platform Team | Last Updated: 2025-11-17
# Links: docs/getting-started.md, docs/troubleshooting.md, docs/development.md, docs/adr/ADR-003 argocd.md# Inputs: [env VAR_A, flags --bar, files ./x.yaml]
# Outputs: [logs, manifests, exit codes]
# Dependencies: [kubectl, terraform, argocd, jq]
# Owner: [team or handle] | Last Updated: [YYYY-MM-DD]
# Links: [docs url], [ADR-00X]
# =============================================================================
set -euo pipefail

# Ensure we are running under bash even if invoked from zsh/sh
if [[ -z "${BASH_VERSION:-}" ]]; then
  exec bash "$0" "$@"
fi

echo "Current working directory: $(pwd)"

# Default Argo CD namespace (can override via ARGOCD_NAMESPACE env)
ARGO_NS="${ARGOCD_NAMESPACE:-fawkes}"

function error_exit { echo "[ERROR] $1"; exit 1; }

# Determine sensible minikube resource settings
function compute_minikube_resources() {
  # Allow user override via env
  local default_mem=8192
  local default_cpus=4
  local mem_mb="${MINIKUBE_MEMORY:-}" # if set, use as-is
  local cpus="${MINIKUBE_CPUS:-$default_cpus}"

  if [[ -z "$mem_mb" ]]; then
    # Try to detect Docker Desktop memory and choose a safe value
    if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
      local total_line total_val unit
      total_line=$(docker info 2>/dev/null | awk -F': ' '/Total Memory/ {print $2; exit}')
      if [[ -n "$total_line" ]]; then
        # Examples: "7.75GiB" or "15360MiB"
        if [[ "$total_line" =~ ^([0-9]+\.[0-9]+|[0-9]+)GiB$ ]]; then
          total_val=${BASH_REMATCH[1]}
          # Convert GiB to MB (round down)
          mem_mb=$(awk -v v="$total_val" 'BEGIN { printf "%d", v*1024 }')
        elif [[ "$total_line" =~ ^([0-9]+)MiB$ ]]; then
          mem_mb=${BASH_REMATCH[1]}
        fi
        if [[ -n "${mem_mb}" ]]; then
          # Leave 256MB headroom and cap by default_mem
          local safe_mb=$(( mem_mb > 256 ? mem_mb - 256 : mem_mb ))
          if (( safe_mb >= default_mem )); then
            mem_mb=$default_mem
          else
            mem_mb=$safe_mb
          fi
        fi
      fi
    fi
  fi

  # Fallbacks
  if [[ -z "$mem_mb" || "$mem_mb" -lt 4096 ]]; then
    mem_mb=6144
  fi

  echo "${mem_mb}" "${cpus}"
}

function compute_minikube_disk_size() {
  local default_disk="20g"
  local disk="${MINIKUBE_DISK_SIZE:-$default_disk}"
  echo "$disk"
}

# Detect minikube architecture to avoid slow emulation (arm64 vs amd64)
function detect_minikube_arch() {
  local m
  m=$(uname -m)
  case "$m" in
    arm64|aarch64) echo "arm64" ;;
    x86_64|amd64) echo "amd64" ;;
    *) echo "amd64" ;;
  esac
}

# Choose best available minikube driver for macOS >=13 avoiding deprecated/unsupported ones (virtualbox, hyperkit)
function choose_minikube_driver() {
  # Allow explicit override via MINIKUBE_DRIVER env
  if [[ -n "${MINIKUBE_DRIVER:-}" ]]; then
    echo "${MINIKUBE_DRIVER}"
    return 0
  fi
  local os="$(uname -s)"
  if [[ "$os" == "Darwin" ]]; then
    # Prefer Docker if daemon is healthy
    if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
      echo "docker"; return 0
    fi
    # Prefer vfkit (Apple Virtualization Framework) if minikube supports it
    if minikube start --help 2>/dev/null | grep -q "vfkit"; then
      echo "vfkit"; return 0
    fi
    # Fallback to qemu if available
    if command -v qemu-system-x86_64 >/dev/null 2>&1 || command -v qemu-system-aarch64 >/dev/null 2>&1; then
      echo "qemu"; return 0
    fi
    # As a last resort use docker even if not yet ready (script will attempt to start Desktop)
    echo "docker"; return 0
  else
    # Non-macOS: prefer docker, else kvm2/qemu, else auto
    if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
      echo "docker"; return 0
    fi
    if command -v qemu-system-x86_64 >/dev/null 2>&1; then
      echo "qemu"; return 0
    fi
    echo "auto"; return 0
  fi
}

# Provide driver-specific extra args (e.g., qemu networking)
function driver_extra_args() {
  local driver="$1"
  local args=()
  # Only add --arch if supported by current minikube
  if minikube start --help 2>/dev/null | grep -q "--arch"; then
    local arch
    arch=$(detect_minikube_arch)
    args+=("--arch=${arch}")
  fi
  if [[ "$driver" == "qemu" ]]; then
    if command -v socket_vmnet >/dev/null 2>&1; then
      args+=("--network=socket_vmnet")
    else
      echo "[WARN] QEMU running without socket_vmnet; minikube service/tunnel may not work." >&2
    fi
  fi
  printf "%s " "${args[@]}"
}

function usage {
  echo "Usage: $0 <environment|cleanup>"
  echo "  environment: local | dev | stage | production"
  echo "  cleanup: remove ArgoCD and Fawkes resources for a fresh start"
  exit 1
}

if [[ "${1:-}" == "cleanup" || "${1:-}" == "clean" ]]; then
  echo "🧹 Cleaning up ArgoCD and Fawkes namespaces..."
  kubectl delete namespace argocd --wait --ignore-not-found || true
  kubectl delete namespace fawkes --wait --ignore-not-found || true
  kubectl delete namespace jenkins --wait --ignore-not-found || true

  echo "🧹 Cleaning up Argo CD cluster-scoped resources (may be absent)..."
  CRDS=$(kubectl get crd -o name 2>/dev/null | grep -E 'argoproj.io' || true)
  if [[ -n "$CRDS" ]]; then
    echo "$CRDS" | xargs kubectl delete --wait --ignore-not-found || true
  fi
  CROLES=$(kubectl get clusterrole -o name 2>/dev/null | grep -E '^clusterrole/argocd' || true)
  if [[ -n "$CROLES" ]]; then
    echo "$CROLES" | xargs kubectl delete --wait --ignore-not-found || true
  fi
  CRBINDINGS=$(kubectl get clusterrolebinding -o name 2>/dev/null | grep -E '^clusterrolebinding/argocd' || true)
  if [[ -n "$CRBINDINGS" ]]; then
    echo "$CRBINDINGS" | xargs kubectl delete --wait --ignore-not-found || true
  fi
  echo "✅ Cleanup complete."
  exit 0
fi

ENV="${1:-}"
if [[ -z "$ENV" ]]; then
  usage
fi

case "$ENV" in
  local|dev|stage|production) ;;
  *) error_exit "Invalid environment: $ENV. Must be one of: local, dev, stage, production." ;;
esac

echo "🔎 Validating prerequisites..."

if [[ -f "$(dirname "${BASH_SOURCE[0]}")/tools.sh" ]]; then
  echo "➡ Running tools check via scripts/tools.sh"
  if ! "$(dirname "${BASH_SOURCE[0]}")/tools.sh" check; then
    echo "Some required tools are missing in your environment."
    echo "You can enter the Nix dev shell to get a reproducible environment:"
    echo "  ./scripts/tools.sh shell"
    if command -v bash >/dev/null 2>&1 && [[ -f "$(dirname "${BASH_SOURCE[0]}")/tools-install.sh" || -f "$(dirname "${BASH_SOURCE[0]}")/brew-install.sh" ]]; then
      # Detect auto-install flags: either env AUTO_INSTALL=1/true or second positional arg --auto-install
      AUTO_INSTALL=0
      if [[ "${AUTO_INSTALL:-}" == "1" || "${AUTO_INSTALL:-}" == "true" || "${2:-}" == "--auto-install" ]]; then
        AUTO_INSTALL=1
      fi

      if [[ ${AUTO_INSTALL} -eq 1 ]]; then
        echo "AUTO_INSTALL enabled — running installer non-interactively..."
        if [[ "$(uname -s)" == "Darwin" && -f "$(dirname "${BASH_SOURCE[0]}")/brew-install.sh" ]]; then
          bash "$(dirname "${BASH_SOURCE[0]}")/brew-install.sh" --yes --accept-driver-permissions
        else
          bash "$(dirname "${BASH_SOURCE[0]}")/tools-install.sh" --yes
        fi
        echo "Re-running tools check..."
        if ! "$(dirname "${BASH_SOURCE[0]}")/tools.sh" check; then
          error_exit "Prerequisite check failed after installer. Please resolve remaining issues and try again."
        fi
      else
        read -r -p "Would you like to run the interactive installer to provision prerequisites now? [y/N]: " RUN_INSTALL
        if [[ "$RUN_INSTALL" =~ ^[Yy]$ ]]; then
          echo "Running installer helper..."
          if [[ "$(uname -s)" == "Darwin" && -f "$(dirname "${BASH_SOURCE[0]}")/brew-install.sh" ]]; then
            bash "$(dirname "${BASH_SOURCE[0]}")/brew-install.sh"
          else
            bash "$(dirname "${BASH_SOURCE[0]}")/tools-install.sh"
          fi
          echo "Re-running tools check..."
          if ! "$(dirname "${BASH_SOURCE[0]}")/tools.sh" check; then
            error_exit "Prerequisite check failed after installer. Please resolve remaining issues and try again."
          fi
        else
          error_exit "Prerequisite check failed."
        fi
      fi
    else
      error_exit "Prerequisite check failed."
    fi
  fi
  echo "✅ All required tools are available."
else
  for tool in kubectl jq base64 terraform; do
    if ! command -v $tool &>/dev/null; then
      error_exit "$tool is required but not installed. Please install $tool and try again."
    fi
  done
  echo "✅ All required tools are installed."
fi

echo "🔍 Checking available Kubernetes contexts..."
kubectl config get-contexts || true

ACTIVE_CONTEXT=$(kubectl config current-context 2>/dev/null || echo "")
if [[ -n "$ACTIVE_CONTEXT" ]]; then
  echo "Current active context: $ACTIVE_CONTEXT"
  if kubectl cluster-info &>/dev/null; then
    read -p "Do you want to use the current context '$ACTIVE_CONTEXT'? [y/N]: " USE_CURRENT
    if [[ ! "$USE_CURRENT" =~ ^[Yy]$ ]]; then
      error_exit "Aborted by user."
    fi
    echo "✅ Using current context: $ACTIVE_CONTEXT"
  else
    echo "Current context '$ACTIVE_CONTEXT' is not reachable."
    # If local environment requested, try to start minikube automatically
    if [[ "$ENV" == "local" ]]; then
      if command -v minikube >/dev/null 2>&1; then
        echo "Attempting to start minikube for local environment..."
        # select driver (avoids unsupported virtualbox/hyperkit on modern macOS)
        DRIVER="$(choose_minikube_driver)"
        # On macOS, if docker CLI exists but daemon isn't started, try to start Docker Desktop and wait
        if command -v docker >/dev/null 2>&1 && ! docker info >/dev/null 2>&1 && [[ "$(uname -s)" == "Darwin" ]]; then
          echo "Docker CLI found but daemon is not running. Attempting to start Docker Desktop..."
          open -a Docker || true
          echo "Waiting for Docker engine to become ready (up to 90s)..."
          end=$((SECONDS + 90))
          until docker info >/dev/null 2>&1 || [[ ${SECONDS} -ge ${end} ]]; do
            sleep 3
          done
          if docker info >/dev/null 2>&1; then
            echo "Docker engine is ready."
          else
            echo "Docker engine did not become ready within 90s; will try other drivers."
          fi
        fi

        # If chosen docker but daemon not running attempt to start Desktop then re-evaluate
        if [[ "$DRIVER" == "docker" ]]; then
          if ! command -v docker >/dev/null 2>&1 || ! docker info >/dev/null 2>&1; then
            echo "Docker driver selected but daemon not running; attempting to start Docker Desktop..."
          fi
        fi
        read MEM CPUS < <(compute_minikube_resources)
        EXTRA_ARGS=$(driver_extra_args "${DRIVER}")
        DISK=$(compute_minikube_disk_size)
        echo "Starting minikube (driver=${DRIVER}, memory=${MEM}MB, cpus=${CPUS}, disk=${DISK}) — this may take a minute..."
        # shellcheck disable=SC2086
        minikube start --driver="${DRIVER}" --memory="${MEM}" --cpus="${CPUS}" --disk-size="${DISK}" ${EXTRA_ARGS}
        echo "minikube started. Setting context to 'minikube'"
        kubectl config use-context minikube || true
      else
        error_exit "kubectl context is unreachable and minikube is not installed. Install minikube or choose another cluster."
      fi
    else
      error_exit "Current context not reachable. Aborting."
    fi
  fi
else
  # No active context — for local, try to start minikube; otherwise abort
  if [[ "$ENV" == "local" ]]; then
    if command -v minikube >/dev/null 2>&1; then
      echo "No active Kubernetes context found; starting minikube for local development..."
      DRIVER="$(choose_minikube_driver)"
      if command -v docker >/dev/null 2>&1 && ! docker info >/dev/null 2>&1 && [[ "$(uname -s)" == "Darwin" ]]; then
        echo "Docker CLI found but daemon is not running. Attempting to start Docker Desktop..."
        open -a Docker || true
        echo "Waiting for Docker engine to become ready (up to 90s)..."
        end=$((SECONDS + 90))
        until docker info >/dev/null 2>&1 || [[ ${SECONDS} -ge ${end} ]]; do
          sleep 3
        done
        if docker info >/dev/null 2>&1; then
          echo "Docker engine is ready."
        else
          echo "Docker engine did not become ready within 90s; will try other drivers."
        fi
      fi

      if [[ "$DRIVER" == "docker" ]]; then
        if ! command -v docker >/dev/null 2>&1 || ! docker info >/dev/null 2>&1; then
          echo "Docker driver selected but daemon not running; attempting to start Docker Desktop..."
        fi
      fi
      read MEM CPUS < <(compute_minikube_resources)
      EXTRA_ARGS=$(driver_extra_args "${DRIVER}")
      DISK=$(compute_minikube_disk_size)
      echo "Starting minikube (driver=${DRIVER}, memory=${MEM}MB, cpus=${CPUS}, disk=${DISK}) — this may take a minute..."
      # shellcheck disable=SC2086
      minikube start --driver="${DRIVER}" --memory="${MEM}" --cpus="${CPUS}" --disk-size="${DISK}" ${EXTRA_ARGS}
      kubectl config use-context minikube || true
    else
      error_exit "No active context and minikube is not installed. Install minikube or configure a cluster."
    fi
  else
    error_exit "No active Kubernetes context found. Configure kubectl and try again."
  fi
fi

echo "✅ Kubernetes context set and reachable."

# Create target Argo CD namespace if it does not exist
kubectl apply -f - <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: ${ARGO_NS}
EOF

echo "namespace/${ARGO_NS} ensured"

# Optional cleanup of pre-existing Argo CD cluster-scoped resources
maybe_cleanup_argocd_cluster_resources() {
  set +e
  if [[ "$ENV" != "local" ]]; then return 0; fi
  if kubectl get clusterrole argocd-application-controller >/dev/null 2>&1 || \
     kubectl get crd applications.argoproj.io >/dev/null 2>&1; then
    echo "⚠️  Detected pre-existing Argo CD cluster-scoped resources. These can block Helm from installing."
    local do_clean="N"
    if [[ "${AUTO_CLEAN_ARGO:-}" == "1" || "${AUTO_CLEAN_ARGO:-}" == "true" || "${2:-}" == "--auto-clean" ]]; then
      do_clean="Y"
    else
      read -r -p "Do you want to clean them up now? [y/N]: " do_clean
    fi
    if [[ "$do_clean" =~ ^[Yy]$ ]]; then
      echo "🧹 Removing Argo CD cluster-scoped resources (CRDs, ClusterRoles, ClusterRoleBindings)..."
      # Delete CRDs under argoproj.io (macOS-safe, only run delete when list is non-empty)
      CRDS=$(kubectl get crd -o name 2>/dev/null | grep -E 'argoproj.io' || true)
      if [[ -n "$CRDS" ]]; then echo "$CRDS" | xargs kubectl delete --wait --ignore-not-found; fi
      # Delete cluster roles/bindings by name prefix
      CROLES=$(kubectl get clusterrole -o name 2>/dev/null | grep -E '^clusterrole/argocd' || true)
      if [[ -n "$CROLES" ]]; then echo "$CROLES" | xargs kubectl delete --wait --ignore-not-found; fi
      CRBINDINGS=$(kubectl get clusterrolebinding -o name 2>/dev/null | grep -E '^clusterrolebinding/argocd' || true)
      if [[ -n "$CRBINDINGS" ]]; then echo "$CRBINDINGS" | xargs kubectl delete --wait --ignore-not-found; fi
      echo "✅ Cleanup complete."
    else
      echo "Proceeding without cleanup; Helm may fail if resources exist."
    fi
  fi
  set -e
}

maybe_cleanup_argocd_cluster_resources "$@"

# If Argo CD CRDs pre-exist (from previous installs), label/annotate them so Helm can adopt
echo "Checking for existing Argo CD CRDs to patch ownership labels (if needed)..."
for crd in $(kubectl get crd -o name | grep -E 'argoproj.io' | cut -d/ -f2); do
  echo "Patching CRD $crd with Helm ownership labels/annotations"
  kubectl patch crd "$crd" --type merge -p '{
    "metadata": {
      "labels": {"app.kubernetes.io/managed-by": "Helm"},
      "annotations": {
        "meta.helm.sh/release-name": "argocd",
        "meta.helm.sh/release-namespace": "'"${ARGO_NS}"'"
      }
    }
  }' || true
done

# Deploy ArgoCD using Terraform
TF_MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../infra/terraform/argocd" && pwd)"
echo "Deploying ArgoCD via Terraform module at ${TF_MODULE_DIR}"

# Export a stable kubeconfig for Terraform
TEMP_KUBECONFIG=$(mktemp -t fawkes-kubeconfig-XXXX.yaml)
kubectl config view --raw --minify --flatten > "${TEMP_KUBECONFIG}"
export KUBECONFIG="${TEMP_KUBECONFIG}"
export TF_VAR_kubeconfig_path="${TEMP_KUBECONFIG}"
echo "Using temporary KUBECONFIG at ${KUBECONFIG} for Terraform operations"

cleanup_kubeconfig() { rm -f "${TEMP_KUBECONFIG}" || true; }
trap cleanup_kubeconfig EXIT

pushd "${TF_MODULE_DIR}" >/dev/null
echo "Running: terraform init (with -upgrade to reconcile provider constraints)"
terraform init -upgrade -input=false 2>&1 | tee terraform.log

echo "Running: terraform plan"
terraform plan -input=false -out=plan.tfplan 2>&1 | tee -a terraform.log

echo "Applying plan.tfplan"
terraform apply -input=false plan.tfplan 2>&1 | tee -a terraform.log
rc=${PIPESTATUS[0]}
popd >/dev/null
if [[ ${rc} -ne 0 ]]; then
  error_exit "Terraform apply for ArgoCD failed; see ${TF_MODULE_DIR}/terraform.log"
fi

echo "⏳ Waiting for ArgoCD server to be available..."
kubectl wait --for=condition=available deployment/argocd-server -n "${ARGO_NS}" --timeout=300s

ARGOCD_PASSWORD=$(kubectl -n "${ARGO_NS}" get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)

# If running local, optionally reset ArgoCD admin password to a known developer default
if [[ "$ENV" == "local" ]]; then
  FAWKES_LOCAL_PASSWORD="${FAWKES_LOCAL_PASSWORD:-fawkesidp}"
  if command -v argocd >/dev/null 2>&1; then
    echo "🔐 Setting ArgoCD admin password to a local default for developers..."
    # Use a short-lived port-forward to reach the API reliably
    (kubectl -n "${ARGO_NS}" port-forward svc/argocd-server 8080:443 >/dev/null 2>&1 & echo $! > /tmp/fawkes-argocd-pf.pid)
    sleep 2
    set +e
    argocd login localhost:8080 \
      --username admin \
      --password "${ARGOCD_PASSWORD}" \
      --insecure >/dev/null 2>&1
    if [[ $? -eq 0 ]]; then
      argocd account update-password \
        --current-password "${ARGOCD_PASSWORD}" \
        --new-password "${FAWKES_LOCAL_PASSWORD}" >/dev/null 2>&1 && \
      ARGOCD_PASSWORD="${FAWKES_LOCAL_PASSWORD}"
    else
      echo "[WARN] Could not log into ArgoCD to update password automatically. Keeping initial password." >&2
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

echo ""
echo "==================== ArgoCD Credentials ===================="
echo "URL:      https://localhost:8080 (use port-forward below)"
echo "Username: admin"
echo "Password: ${ARGOCD_PASSWORD}"
echo "============================================================"
echo ""

echo "🌐 Ensuring ArgoCD deployments are available..."

wait_for_workload() {
  local name="$1" ns="${2:-default}" timeout="${3:-300}"
  echo "⏳ Waiting for workload ${name} in namespace ${ns} (timeout ${timeout}s)..."
  if kubectl get deployment "${name}" -n "${ns}" >/dev/null 2>&1; then
    if ! kubectl wait --for=condition=available deployment/${name} -n "${ns}" --timeout="${timeout}s"; then
      kubectl -n "${ns}" get pods -o wide
      kubectl -n "${ns}" describe deployment/${name} || true
      return 1
    fi
    return 0
  fi
  if kubectl get statefulset "${name}" -n "${ns}" >/dev/null 2>&1; then
    if ! kubectl rollout status statefulset/${name} -n "${ns}" --timeout="${timeout}s"; then
      kubectl -n "${ns}" get pods -o wide
      kubectl -n "${ns}" describe statefulset/${name} || true
      return 1
    fi
    return 0
  fi
  echo "Workload ${name} not found as Deployment or StatefulSet; falling back to pods with prefix ${name}"
  local end=$((SECONDS + timeout))
  while [[ ${SECONDS} -lt ${end} ]]; do
    pod=$(kubectl -n "${ns}" get pods --no-headers -o custom-columns=":metadata.name" | grep "^${name}" | head -n1 || true)
    if [[ -n "$pod" ]]; then
      ready=$(kubectl -n "${ns}" get pod "$pod" -o jsonpath='{.status.containerStatuses[0].ready}' 2>/dev/null || echo "false")
      if [[ "$ready" == "true" ]]; then
        echo "Pod $pod is ready"
        return 0
      fi
    fi
    sleep 2
  done
  kubectl -n "${ns}" get pods -o wide
  return 1
}

for dep in argocd-server argocd-repo-server argocd-application-controller argocd-dex-server; do
  if ! wait_for_workload "${dep}" "${ARGO_NS}" 300; then
    error_exit "Deployment ${dep} failed to become available"
  fi
done

echo "⏳ Waiting for argocd-server service endpoints..."
ENDPOINTS_TIMEOUT=120
end=$((SECONDS + ENDPOINTS_TIMEOUT))
while [[ ${SECONDS} -lt ${end} ]]; do
  if kubectl get endpoints argocd-server -n "${ARGO_NS}" -o jsonpath='{.subsets}' | grep -q .; then
    echo "✅ argocd-server has endpoints"
    break
  fi
  sleep 2
done
if [[ ${SECONDS} -ge ${end} ]]; then
  kubectl -n "${ARGO_NS}" get endpoints
  error_exit "argocd-server service has no endpoints after ${ENDPOINTS_TIMEOUT}s"
fi

ensure_argocd_crds() {
  echo "🔎 Ensuring Argo CD CRDs exist..."
  local missing=0
  for c in applications.argoproj.io applicationsets.argoproj.io appprojects.argoproj.io; do
    if ! kubectl get crd "$c" >/dev/null 2>&1; then
      missing=1
      break
    fi
  done
  if [[ $missing -eq 1 ]]; then
    echo "CRDs missing. Installing CRDs from argo-helm chart..."
    if ! helm repo list 2>/dev/null | awk '{print $1}' | grep -qx "argo"; then
      helm repo add argo https://argoproj.github.io/argo-helm >/dev/null
    fi
    helm repo update >/dev/null
    if ! helm show crds argo/argo-cd | kubectl apply -f -; then
      echo "[WARN] Failed to pull CRDs via helm. Falling back to direct CRD manifests..."
      kubectl apply -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/crds/application-crd.yaml
      kubectl apply -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/crds/applicationset-crd.yaml
      kubectl apply -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/crds/appproject-crd.yaml
    fi
  else
    echo "CRDs already present."
  fi
}

ensure_argocd_crds

echo "🌐 Creating ArgoCD Application CRs in-cluster (no port-forward required)..."

cat <<EOF | kubectl apply -f -
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: fawkes-app
  namespace: ${ARGO_NS}
spec:
  project: default
  source:
    repoURL: https://github.com/paruff/fawkes.git
    path: platform/apps
    targetRevision: HEAD
  destination:
    server: https://kubernetes.default.svc
    namespace: fawkes
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
---
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: fawkes-infra
  namespace: ${ARGO_NS}
spec:
  project: default
  source:
    repoURL: https://github.com/paruff/fawkes.git
    path: infra/kubernetes
    targetRevision: HEAD
  destination:
    server: https://kubernetes.default.svc
    namespace: fawkes
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
EOF

echo "✅ ArgoCD Application CRs applied — ArgoCD will pick them up and sync the fawkes namespace."
echo "Access the ArgoCD UI locally:"
echo "  kubectl -n ${ARGO_NS} port-forward svc/argocd-server 8080:443"

echo ""
echo "🎉 Ignite complete for '$ENV' environment!"
echo ""
echo "ArgoCD UI:    https://localhost:8080 (user: admin, password above)"
echo ""
exit 0
