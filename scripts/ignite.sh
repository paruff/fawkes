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
# Usage: [bash ./scripts/ignite.sh --provider [local|aws|azure|gcp] [--cluster-name NAME] [--region REGION|--location LOCATION] [--only-cluster|--only-apps|--skip-cluster] [--dry-run] [--resume] [--verbose] <local|dev|stage|production>]
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
ARGOCD_PASSWORD=""
PROVIDER=""
CLUSTER_NAME=""
REGION=""
LOCATION=""
ONLY_CLUSTER=0
ONLY_APPS=0
SKIP_CLUSTER=0
DRY_RUN=0
RESUME=0
VERBOSE=0
ENV=""
PREFER_MINIKUBE=0
PREFER_DOCKER=0

# State tracking (for --resume)
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STATE_FILE="${ROOT_DIR}/.ignite-state.json"
CONTEXT_ID=""

context_id() {
  # Build a context key including env/provider/cluster/region/location (sanitize spaces)
  local env_part="${ENV:-unknown}"
  local prov_part="${PROVIDER:-none}"
  local name_part="${CLUSTER_NAME:-}" \
        reg_part="${REGION:-}" \
        loc_part="${LOCATION:-}"
  if [[ -z "$name_part" ]]; then
    name_part="$(kubectl config current-context 2>/dev/null || echo unknown)"
  fi
  local key="${env_part}:${prov_part}:${name_part}:${reg_part}:${loc_part}"
  echo "${key// /_}"
}

state_setup() {
  # Ensure state file exists and has a top-level object
  if [[ ! -f "$STATE_FILE" ]]; then
    echo '{}' > "$STATE_FILE"
  fi
  # Ensure `.runs` object exists
  local tmp
  tmp=$(mktemp -t ignite-state-XXXX.json)
  jq '(.runs //= {})' "$STATE_FILE" > "$tmp" && mv "$tmp" "$STATE_FILE"
}

state_clear_context() {
  # Remove previous context state unless resuming
  local ctx="$1"
  local tmp
  tmp=$(mktemp -t ignite-state-XXXX.json)
  jq --arg ctx "$ctx" '(.runs[$ctx]) = null | del(.runs[$ctx])' "$STATE_FILE" > "$tmp" && mv "$tmp" "$STATE_FILE"
}

state_is_done() {
  local step="$1" ctx="$CONTEXT_ID"
  jq -e --arg ctx "$ctx" --arg step "$step" '.runs[$ctx].steps[$step].status == "done"' "$STATE_FILE" >/dev/null 2>&1
}

state_mark_done() {
  local step="$1" ctx="$CONTEXT_ID" ts
  ts=$(date -u +%FT%TZ)
  local tmp
  tmp=$(mktemp -t ignite-state-XXXX.json)
  jq --arg ctx "$ctx" --arg step "$step" --arg ts "$ts" '
    .runs[$ctx] //= {steps:{}} | .runs[$ctx].steps //= {} | .runs[$ctx].steps[$step] = {status:"done", ts:$ts}
  ' "$STATE_FILE" > "$tmp" && mv "$tmp" "$STATE_FILE"
}

run_step() {
  local step_name="$1"; shift
  local fn="$1"; shift || true
  if [[ $RESUME -eq 1 ]] && state_is_done "$step_name"; then
    echo "⏭️  Skipping step '$step_name' (resume)"
    return 0
  fi
  "$fn" "$@"
  local rc=$?
  if [[ $rc -ne 0 ]]; then
    return $rc
  fi
  if [[ $DRY_RUN -eq 0 ]]; then
    state_mark_done "$step_name"
  else
    echo "[DRY-RUN] Not marking step '$step_name' as done"
  fi
}

function error_exit { echo "[ERROR] $1"; exit 1; }

# ----------------------------- Phase: Cleanup ------------------------------
cleanup_resources() {
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
  echo "✅ Cleanup complete."; }

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

# Try to find and use an existing local Kubernetes context (docker-desktop, minikube, kind-*, rancher-desktop, colima)
function use_first_reachable_local_context() {
  local contexts
  contexts=$(kubectl config get-contexts -o name 2>/dev/null || true)
  if [[ -z "$contexts" ]]; then return 1; fi
  local -a candidates=()
  if [[ $PREFER_MINIKUBE -eq 1 ]]; then
    echo "$contexts" | grep -qx "minikube" && candidates+=("minikube")
    echo "$contexts" | grep -qx "docker-desktop" && candidates+=("docker-desktop")
  else
    echo "$contexts" | grep -qx "docker-desktop" && candidates+=("docker-desktop")
    echo "$contexts" | grep -qx "minikube" && candidates+=("minikube")
  fi
  # Add any kind-* contexts in order
  while IFS= read -r ctx; do
    [[ "$ctx" == kind-* ]] && candidates+=("$ctx")
  done < <(echo "$contexts")
  echo "$contexts" | grep -qx "rancher-desktop" && candidates+=("rancher-desktop")
  echo "$contexts" | grep -qx "colima" && candidates+=("colima")

  local ctx
  for ctx in "${candidates[@]}"; do
    if kubectl --context "$ctx" cluster-info >/dev/null 2>&1; then
      if [[ $DRY_RUN -eq 1 ]]; then
        echo "[DRY-RUN] Would use local Kubernetes context '$ctx'"
        return 0
      fi
      kubectl config use-context "$ctx" >/dev/null 2>&1 || true
      echo "Using local Kubernetes context '$ctx'."
      return 0
    fi
  done
  return 1
}

# Provide driver-specific extra args (e.g., qemu networking)
function driver_extra_args() {
  local driver="$1"
  local -a args=()
  # Only add --arch if supported by current minikube
  if minikube start --help 2>/dev/null | grep -q -- "--arch"; then
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
  if (( ${#args[@]} > 0 )); then
    printf "%s " "${args[@]}"
  fi
}

function usage {
  echo "Usage: $0 [--provider local|aws|azure|gcp] [--cluster-name NAME] [--region REGION|--location LOCATION] [--only-cluster|--only-apps|--skip-cluster] [--dry-run] [--resume] [--verbose] <environment|cleanup|destroy>"
  echo "  environment: local | dev | stage | production"
  echo "  cleanup: remove ArgoCD and Fawkes resources for a fresh start"
  echo "  destroy: run Terraform destroy for the selected provider"
  echo "  flags:"
  echo "    --provider|-p        One of local|aws|azure|gcp"
  echo "    --cluster-name|-n    Cluster name for provider Terraform (TF_VAR_cluster_name)"
  echo "    --region|-r          Region for AWS/GCP (TF_VAR_region)"
  echo "    --location           Location for Azure (TF_VAR_location)"
  echo "    --prefer-minikube    Prefer minikube over docker-desktop for local"
  echo "    --prefer-docker-desktop Prefer docker-desktop over minikube for local (default)"
  echo "    --only-cluster       Provision cluster only (skip Argo CD & apps)"
  echo "    --only-apps          Deploy Argo CD & apps only (skip cluster)"
  echo "    --skip-cluster       Alias for --only-apps"
  echo "    --dry-run            Plan-only (no apply), print intended actions"
  echo "    --resume             Attempt to resume a previous run (placeholder)"
  echo "    --verbose|-v         Verbose output (set -x)"
  exit 1
}

# Allow cleanup anywhere in args
for _arg in "$@"; do
  if [[ "$_arg" == "cleanup" || "$_arg" == "clean" ]]; then
    cleanup_resources
    exit 0
  fi
done

# ------------------------ Flag parsing (tasks 2 & 3) ---------------------
parse_flags() {
  # Parse supported flags; ignore unknown for forward compatibility
  local argv=("$@")
  local i=0
  while [[ $i -lt ${#argv[@]} ]]; do
    local arg="${argv[$i]}"
    case "$arg" in
      --provider|-p)
        local next_index=$((i+1))
        if [[ $next_index -ge ${#argv[@]} ]]; then
          error_exit "--provider requires a value: local|aws|azure|gcp"
        fi
        PROVIDER="${argv[$next_index]}"
        i=$((i+2))
        continue
        ;;
      --cluster-name|-n)
        local next_index=$((i+1))
        if [[ $next_index -ge ${#argv[@]} ]]; then
          error_exit "--cluster-name requires a value"
        fi
        CLUSTER_NAME="${argv[$next_index]}"
        i=$((i+2))
        continue
        ;;
      --region|-r)
        local next_index=$((i+1))
        if [[ $next_index -ge ${#argv[@]} ]]; then
          error_exit "--region requires a value"
        fi
        REGION="${argv[$next_index]}"
        i=$((i+2))
        continue
        ;;
      --location)
        local next_index=$((i+1))
        if [[ $next_index -ge ${#argv[@]} ]]; then
          error_exit "--location requires a value"
        fi
        LOCATION="${argv[$next_index]}"
        i=$((i+2))
        continue
        ;;
      --only-cluster)
        ONLY_CLUSTER=1; i=$((i+1)); continue ;;
      --only-apps)
        ONLY_APPS=1; i=$((i+1)); continue ;;
      --skip-cluster)
        SKIP_CLUSTER=1; i=$((i+1)); continue ;;
      --dry-run)
        DRY_RUN=1; i=$((i+1)); continue ;;
      --resume)
        RESUME=1; i=$((i+1)); continue ;;
      --verbose|-v)
        VERBOSE=1; i=$((i+1)); continue ;;
      --prefer-minikube)
        PREFER_MINIKUBE=1; i=$((i+1)); continue ;;
      --prefer-docker-desktop)
        PREFER_DOCKER=1; i=$((i+1)); continue ;;
      --help|-h)
        usage ;;
      *)
        # First non-flag positional becomes ENV (environment)
        if [[ ! "$arg" =~ ^- && -z "$ENV" && "$arg" != "clean" && "$arg" != "cleanup" ]]; then
          ENV="$arg"
        fi
        i=$((i+1))
        ;;
    esac
  done

  if [[ -z "${PROVIDER}" ]]; then
    # Derive a default from ENV for backward-compatibility
    if [[ "$ENV" == "local" ]]; then
      PROVIDER="local"
    fi
  fi

  if [[ -n "${PROVIDER}" ]] && ! [[ "${PROVIDER}" =~ ^(local|aws|azure|gcp)$ ]]; then
    error_exit "Unknown provider '${PROVIDER}'. Expected one of: local, aws, azure, gcp."
  fi

  # Validate mutually exclusive flags
  if [[ $ONLY_CLUSTER -eq 1 && ( $ONLY_APPS -eq 1 || $SKIP_CLUSTER -eq 1 ) ]]; then
    error_exit "--only-cluster cannot be combined with --only-apps/--skip-cluster"
  fi
  if [[ $PREFER_MINIKUBE -eq 1 && $PREFER_DOCKER -eq 1 ]]; then
    error_exit "--prefer-minikube cannot be combined with --prefer-docker-desktop"
  fi
}

check_prereqs() {
  echo "🔎 Validating prerequisites..."
  if [[ -f "$(dirname "${BASH_SOURCE[0]}")/tools.sh" ]]; then
    echo "➡ Running tools check via scripts/tools.sh"
    if ! "$(dirname "${BASH_SOURCE[0]}")/tools.sh" check; then
      echo "Some required tools are missing in your environment."
      echo "You can enter the Nix dev shell to get a reproducible environment:"
      echo "  ./scripts/tools.sh shell"
      if command -v bash >/dev/null 2>&1 && [[ -f "$(dirname "${BASH_SOURCE[0]}")/tools-install.sh" || -f "$(dirname "${BASH_SOURCE[0]}")/brew-install.sh" ]]; then
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
}

provision_cluster() {
  # If provider specified, dispatch to provider-specific provisioning
  if [[ -n "${PROVIDER}" ]]; then
    case "${PROVIDER}" in
      local)
        provision_local_cluster
        ;;
      aws)
        provision_aws_cluster
        ;;
      azure)
        provision_azure_cluster
        ;;
      gcp)
        provision_gcp_cluster
        ;;
      *)
        error_exit "Unhandled provider '${PROVIDER}'"
        ;;
    esac
    echo "✅ Kubernetes context set and reachable."
    return 0
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
      if [[ "$ENV" == "local" ]]; then
        provision_local_cluster
      else
        error_exit "Current context not reachable. Aborting."
      fi
    fi
  else
    if [[ "$ENV" == "local" ]]; then
      provision_local_cluster
    else
      error_exit "No active Kubernetes context found. Configure kubectl and try again."
    fi
  fi
  echo "✅ Kubernetes context set and reachable."
}

provision_local_cluster() {
  # Prefer existing local contexts before provisioning
  if use_first_reachable_local_context; then
    return 0
  fi

  if ! command -v minikube >/dev/null 2>&1; then
    error_exit "minikube not installed and Docker Desktop K8s not reachable; install minikube or enable Docker Desktop Kubernetes."
  fi
  echo "Provisioning local cluster via minikube..."
  if [[ $DRY_RUN -eq 1 ]]; then
    echo "[DRY-RUN] Would start minikube with computed resources and chosen driver."
    return 0
  fi
  DRIVER="$(choose_minikube_driver)"
  if command -v docker >/dev/null 2>&1 && ! docker info >/dev/null 2>&1 && [[ "$(uname -s)" == "Darwin" ]]; then
    echo "Docker CLI found but daemon is not running. Attempting to start Docker Desktop..."
    open -a Docker || true
    echo "Waiting for Docker engine to become ready (up to 90s)..."
    end=$((SECONDS + 90))
    until docker info >/dev/null 2>&1 || [[ ${SECONDS} -ge ${end} ]]; do sleep 3; done
    if docker info >/dev/null 2>&1; then echo "Docker engine is ready."; else echo "Docker engine not ready; will try other drivers."; fi
  fi
  if [[ "$DRIVER" == "docker" ]] && { ! command -v docker >/dev/null 2>&1 || ! docker info >/dev/null 2>&1; }; then
    echo "Docker driver selected but daemon not running; attempting anyway."
  fi
  read MEM CPUS < <(compute_minikube_resources)
  EXTRA_ARGS=$(driver_extra_args "${DRIVER}")
  DISK=$(compute_minikube_disk_size)
  echo "Starting minikube (driver=${DRIVER}, memory=${MEM}MB, cpus=${CPUS}, disk=${DISK})..."
  # shellcheck disable=SC2086
  minikube start --driver="${DRIVER}" --memory="${MEM}" --cpus="${CPUS}" --disk-size="${DISK}" ${EXTRA_ARGS}
  kubectl config use-context minikube || true
}

tf_apply_dir() {
  local dir="$1"
  if [[ ! -d "$dir" ]]; then
    error_exit "Terraform directory not found: $dir"
  fi
  echo "🚀 Running Terraform in $dir"
  pushd "$dir" >/dev/null
  
  # Ensure Azure subscription and tenant env vars are set from az CLI context if available
  if command -v az >/dev/null 2>&1; then
    # Verify Azure CLI is logged in before proceeding
    if ! az account show >/dev/null 2>&1; then
      echo "[ERROR] Azure CLI is not logged in"
      echo "[ACTION] Running: az login"
      if ! az login; then
        error_exit "Azure login failed. Please authenticate and try again."
      fi
    fi
    
    export ARM_SUBSCRIPTION_ID="${ARM_SUBSCRIPTION_ID:-$(az account show --query id -o tsv 2>/dev/null || true)}"
    export ARM_TENANT_ID="${ARM_TENANT_ID:-$(az account show --query tenantId -o tsv 2>/dev/null || true)}"
    
    echo "✅ Using Azure subscription: ${ARM_SUBSCRIPTION_ID}"
  fi
  
  terraform init -upgrade -input=false 2>&1 | tee terraform.log
  
  # Attempt to import existing AKS user node pool into state to avoid conflicts
  if command -v az >/dev/null 2>&1; then
    local rg="${TF_VAR_resource_group_name:-fawkes-rg}"
    local cluster="${TF_VAR_cluster_name:-fawkes-dev}"
    local pool_name="user"
    if az aks nodepool show -g "$rg" --cluster-name "$cluster" -n "$pool_name" >/dev/null 2>&1; then
      echo "🔗 Importing existing AKS node pool '$pool_name' into Terraform state"
      terraform import -input=false azurerm_kubernetes_cluster_node_pool.user \
"/subscriptions/${ARM_SUBSCRIPTION_ID}/resourceGroups/${rg}/providers/Microsoft.ContainerService/managedClusters/${cluster}/agentPools/${pool_name}" \
        2>&1 | tee -a terraform.log || true
    fi
  fi
  
  terraform plan -input=false -out=plan.tfplan 2>&1 | tee -a terraform.log
  
  local rc=0
  if [[ $DRY_RUN -eq 1 ]]; then
    echo "[DRY-RUN] Skipping terraform apply in $dir"
  else
    terraform apply -input=false plan.tfplan 2>&1 | tee -a terraform.log
    rc=${PIPESTATUS[0]}
  fi
  popd >/dev/null
  
  if [[ $rc -ne 0 ]]; then
    error_exit "Terraform apply failed for $dir; see $dir/terraform.log"
  fi

  # Export KUBECONFIG from Terraform outputs
  echo "🔑 Resolving kubeconfig for cluster access..."
  local tfjson kubeconfig_path rg_name cluster_name
  rg_name="${TF_VAR_resource_group_name:-fawkes-rg}"
  cluster_name="${TF_VAR_cluster_name:-fawkes-dev}"
  
  tfjson=$(cd "$dir" && terraform output -json 2>/dev/null || true)
  
  if [[ -n "$tfjson" ]]; then
    kubeconfig_path=$(echo "$tfjson" | jq -r '.kubeconfig_path.value // empty' 2>/dev/null || true)
    if [[ -n "$kubeconfig_path" ]]; then
      # Make path absolute if relative
      if [[ "$kubeconfig_path" != /* ]]; then
        kubeconfig_path="$dir/$kubeconfig_path"
      fi
      export KUBECONFIG="$kubeconfig_path"
      export TF_VAR_kubeconfig_path="$kubeconfig_path"
      echo "✅ KUBECONFIG set to $KUBECONFIG"
    fi
  fi

  # For Azure, always refresh credentials
  if [[ "$PROVIDER" == "azure" ]] && command -v az >/dev/null 2>&1; then
    echo "🔄 Refreshing AKS credentials..."
    
    # Verify cluster exists and is running
    echo "🔍 Checking AKS cluster status..."
    local cluster_state
    cluster_state=$(az aks show -g "$rg_name" -n "$cluster_name" --query "provisioningState" -o tsv 2>/dev/null || echo "Unknown")
    
    if [[ "$cluster_state" != "Succeeded" ]]; then
      error_exit "AKS cluster is not in 'Succeeded' state (current: $cluster_state). Wait for cluster to be ready."
    fi
    
    echo "✅ AKS cluster status: $cluster_state"
    
    # Get credentials (will merge into kubeconfig)
    echo "📥 Downloading cluster credentials..."
    az aks get-credentials \
      --resource-group "$rg_name" \
      --name "$cluster_name" \
      --overwrite-existing \
      --file "${KUBECONFIG:-$HOME/.kube/config}"
    
    # Install kubelogin if needed
    if ! command -v kubelogin >/dev/null 2>&1; then
      install_kubelogin || {
        echo "[ERROR] kubelogin installation failed"
        echo "[HINT] Install manually: brew install Azure/kubelogin/kubelogin"
        echo "[HINT] Or visit: https://github.com/Azure/kubelogin"
        return 1
      }
    fi

    # Convert kubeconfig to use azurecli authentication
    echo "[INFO] Converting kubeconfig to azurecli authentication..."
    if kubelogin convert-kubeconfig -l azurecli --kubeconfig "${KUBECONFIG:-$HOME/.kube/config}"; then
      echo "✅ Kubeconfig converted to azurecli auth"
    else
      echo "[WARN] azurecli conversion failed, trying devicecode..."
      if kubelogin convert-kubeconfig -l devicecode --kubeconfig "${KUBECONFIG:-$HOME/.kube/config}"; then
        echo "✅ Kubeconfig converted to devicecode auth"
        echo "[INFO] You may need to authenticate via browser on first kubectl command"
      else
        echo "[ERROR] Kubeconfig conversion failed"
        return 1
      fi
    fi

    # Verify connectivity (with retries for newly created clusters)
    echo "🔍 Verifying cluster connectivity (may take up to 60s for new clusters)..."
    local max_attempts=12
    local attempt=1
    local connected=0
    
    while [[ $attempt -le $max_attempts ]]; do
      echo "   Attempt $attempt/$max_attempts..."
      
      if kubectl get nodes >/dev/null 2>&1; then
        echo "✅ kubectl connectivity verified"
        kubectl get nodes -o wide
        connected=1
        break
      fi
      
      if [[ $attempt -lt $max_attempts ]]; then
        echo "   Waiting 5 seconds before retry..."
        sleep 5
      fi
      
      attempt=$((attempt + 1))
    done
    
    if [[ $connected -eq 0 ]]; then
      echo ""
      echo "════════════════════════════════════════════════════════════════════════════════"
      echo "[ERROR] Unable to reach cluster after $max_attempts attempts"
      echo "════════════════════════════════════════════════════════════════════════════════"
      echo ""
      echo "Troubleshooting checklist:"
      echo ""
      echo "1️⃣  Verify Azure CLI authentication:"
      echo "    az account show"
      echo "    If not logged in: az login"
      echo ""
      echo "2️⃣  Set correct subscription:"
      echo "    az account set --subscription ${ARM_SUBSCRIPTION_ID}"
      echo ""
      echo "3️⃣  Check AKS cluster status:"
      echo "    az aks show -g $rg_name -n $cluster_name --query '{name:name, state:provisioningState, powerState:powerState.code}'"
      echo ""
      echo "4️⃣  Verify network connectivity:"
      echo "    az aks show -g $rg_name -n $cluster_name --query 'apiServerAccessProfile'"
      echo ""
      echo "5️⃣  Try manual kubeconfig setup:"
      echo "    az aks get-credentials -g $rg_name -n $cluster_name --overwrite-existing"
      echo "    kubelogin convert-kubeconfig -l azurecli"
      echo "    kubectl get nodes"
      echo ""
      echo "6️⃣  Check if cluster has authorized IP ranges:"
      echo "    az aks show -g $rg_name -n $cluster_name --query 'apiServerAccessProfile.authorizedIpRanges'"
      echo "    Your IP: $(curl -s ifconfig.me || echo 'unknown')"
      echo ""
      echo "7️⃣  Try device code authentication:"
      echo "    kubelogin convert-kubeconfig -l devicecode --kubeconfig ${KUBECONFIG:-$HOME/.kube/config}"
      echo "    kubectl get nodes"
      echo ""
      echo "════════════════════════════════════════════════════════════════════════════════"
      return 1
    fi
  fi
}

# Install kubelogin for AKS authentication (Azure-specific)
install_kubelogin() {
  if command -v kubelogin >/dev/null 2>&1; then
    echo "✅ kubelogin already installed"
    return 0
  fi

  echo "📦 Installing kubelogin for AKS authentication..."
  
  if [[ "$(uname -s)" == "Darwin" ]]; then
    # macOS: Use Homebrew
    if command -v brew >/dev/null 2>&1; then
      echo "Installing kubelogin via Homebrew..."
      brew install Azure/kubelogin/kubelogin || {
        echo "[WARN] Homebrew install failed, trying direct download..."
        install_kubelogin_binary
      }
    else
      install_kubelogin_binary
    fi
  else
    install_kubelogin_binary
  fi

  if command -v kubelogin >/dev/null 2>&1; then
    echo "✅ kubelogin installed successfully"
    return 0
  else
    echo "[ERROR] Failed to install kubelogin"
    return 1
  fi
}

install_kubelogin_binary() {
  local os arch url install_dir
  os="$(uname -s | tr '[:upper:]' '[:lower:]')"
  arch="$(uname -m)"
  
  case "$arch" in
    x86_64) arch="amd64" ;;
    aarch64|arm64) arch="arm64" ;;
  esac

  # Get latest version from GitHub
  local version
  version=$(curl -s https://api.github.com/repos/Azure/kubelogin/releases/latest | jq -r '.tag_name' || echo "v0.1.4")
  
  url="https://github.com/Azure/kubelogin/releases/download/${version}/kubelogin-${os}-${arch}.zip"
  
  # Try user-writable directory first
  if [[ -w "${HOME}/.local/bin" ]] || mkdir -p "${HOME}/.local/bin" 2>/dev/null; then
    install_dir="${HOME}/.local/bin"
  elif [[ -w "/usr/local/bin" ]]; then
    install_dir="/usr/local/bin"
  else
    install_dir="${HOME}/.local/bin"
    mkdir -p "$install_dir"
  fi

  echo "Downloading kubelogin ${version} from ${url}..."
  local tmpdir
  tmpdir=$(mktemp -d)
  
  if curl -sL "$url" -o "${tmpdir}/kubelogin.zip"; then
    unzip -q "${tmpdir}/kubelogin.zip" -d "${tmpdir}"
    
    # Find the kubelogin binary
    local binary
    binary=$(find "${tmpdir}" -name "kubelogin" -type f | head -n1)
    
    if [[ -n "$binary" ]]; then
      chmod +x "$binary"
      mv "$binary" "${install_dir}/kubelogin"
      
      # Add to PATH if not already there
      if [[ ":$PATH:" != *":${install_dir}:"* ]]; then
        export PATH="${install_dir}:${PATH}"
        echo "Added ${install_dir} to PATH for this session"
        echo "Add 'export PATH=\"${install_dir}:\$PATH\"' to your shell profile for persistence"
      fi
    fi
  fi
  
  rm -rf "${tmpdir}"
}

tf_destroy_dir() {
  local dir="$1"
  if [[ ! -d "$dir" ]]; then
    error_exit "Terraform directory not found: $dir"
  fi
  echo "🗑️  Destroying Terraform in $dir"
  pushd "$dir" >/dev/null
  # Ensure Azure subscription and tenant env vars are set from az CLI context if available
  if command -v az >/dev/null 2>&1; then
    export ARM_SUBSCRIPTION_ID="${ARM_SUBSCRIPTION_ID:-$(az account show --query id -o tsv 2>/dev/null || true)}"
    export ARM_TENANT_ID="${ARM_TENANT_ID:-$(az account show --query tenantId -o tsv 2>/dev/null || true)}"
  fi
  terraform init -upgrade -input=false 2>&1 | tee terraform.log
  local rc=0
  if [[ $DRY_RUN -eq 1 ]]; then
    echo "[DRY-RUN] Skipping terraform destroy in $dir"
  else
    terraform destroy -auto-approve -input=false 2>&1 | tee -a terraform.log
    rc=${PIPESTATUS[0]}
  fi
  popd >/dev/null
  if [[ $rc -ne 0 ]]; then
    error_exit "Terraform destroy failed for $dir; see $dir/terraform.log"
  fi
}

try_set_kubeconfig_from_tf_outputs() {
  local dir="$1"
  local out_json
  pushd "$dir" >/dev/null
  if ! out_json=$(terraform output -json 2>/dev/null); then
    popd >/dev/null
    echo "[WARN] No Terraform outputs available in $dir; leaving KUBECONFIG unchanged." >&2
    return 0
  fi
  popd >/dev/null
  # Try kubeconfig_path first
  local path
  path=$(echo "$out_json" | jq -r 'try .kubeconfig_path.value // empty')
  if [[ -n "$path" && -f "$path" ]]; then
    export KUBECONFIG="$path"
    export TF_VAR_kubeconfig_path="$path"
    echo "✅ Using kubeconfig path from Terraform output: $path"
    return 0
  fi
  # Try kubeconfig content
  local content
  content=$(echo "$out_json" | jq -r 'try .kubeconfig.value // empty')
  if [[ -n "$content" ]]; then
    local tmpkc
    tmpkc=$(mktemp -t fawkes-kubeconfig-XXXX.yaml)
    printf "%s" "$content" > "$tmpkc"
    export KUBECONFIG="$tmpkc"
    export TF_VAR_kubeconfig_path="$tmpkc"
    echo "✅ Wrote kubeconfig from Terraform output to: $tmpkc"
    return 0
  fi
  echo "[WARN] Terraform outputs in $dir do not include kubeconfig_path or kubeconfig; leaving KUBECONFIG unchanged." >&2
}

provision_aws_cluster() {
  echo "🔧 Provider=aws selected. Applying Terraform under infra/aws..."
  local dir
  dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../infra/aws" && pwd)"
  tf_apply_dir "$dir"
  try_set_kubeconfig_from_tf_outputs "$dir"
  if [[ $DRY_RUN -eq 0 ]] && ! kubectl cluster-info &>/dev/null; then
    error_exit "Cluster not reachable after AWS Terraform apply. Ensure your AWS creds and outputs provide kubeconfig."
  fi
}

provision_azure_cluster() {
  echo "🔧 Provider=azure selected. Applying Terraform under infra/azure..."
  local dir
  dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../infra/azure" && pwd)"
  # Ensure required TF_VARS are exported if provided via flags
  if [[ -n "$LOCATION" ]]; then export TF_VAR_location="$LOCATION"; fi
  if [[ -n "$CLUSTER_NAME" ]]; then export TF_VAR_cluster_name="$CLUSTER_NAME"; fi
  tf_apply_dir "$dir"
  try_set_kubeconfig_from_tf_outputs "$dir"
  if [[ $DRY_RUN -eq 0 ]] && ! kubectl cluster-info &>/dev/null; then
    error_exit "Cluster not reachable after Azure Terraform apply. Ensure your Azure creds and outputs provide kubeconfig."
  fi
}

# Provider-specific destroy commands
destroy_aws_cluster() {
  echo "🔧 Provider=aws selected. Destroying Terraform under infra/aws..."
  local dir
  dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../infra/aws" && pwd)"
  tf_destroy_dir "$dir"
}

destroy_azure_cluster() {
  echo "🔧 Provider=azure selected. Destroying Terraform under infra/azure..."
  local dir
  dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../infra/azure" && pwd)"
  # Ensure required TF_VARS are exported if provided via flags
  if [[ -n "$LOCATION" ]]; then export TF_VAR_location="$LOCATION"; fi
  if [[ -n "$CLUSTER_NAME" ]]; then export TF_VAR_cluster_name="$CLUSTER_NAME"; fi
  tf_destroy_dir "$dir"
  # Optional: clean KUBECONFIG if pointing to destroyed cluster
  if [[ -n "${KUBECONFIG:-}" && -f "$KUBECONFIG" ]]; then
    echo "[INFO] Destroy complete. Keeping existing KUBECONFIG at $KUBECONFIG; remove manually if desired."
  fi
}

destroy_gcp_cluster() {
  echo "🔧 Provider=gcp selected. Destroying Terraform under infra/gcp..."
  local dir
  dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../infra/gcp" 2>/dev/null || true)"
  if [[ -z "$dir" || ! -d "$dir" ]]; then
    error_exit "infra/gcp not found yet. GCP provisioning not implemented."
  fi
  tf_destroy_dir "$dir"
}

provision_gcp_cluster() {
  echo "🔧 Provider=gcp selected. Applying Terraform under infra/gcp..."
  local dir
  dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../infra/gcp" 2>/dev/null || true)"
  if [[ -z "$dir" || ! -d "$dir" ]]; then
    error_exit "infra/gcp not found yet. GCP provisioning not implemented."
  fi
  tf_apply_dir "$dir"
  try_set_kubeconfig_from_tf_outputs "$dir"
  if [[ $DRY_RUN -eq 0 ]] && ! kubectl cluster-info &>/dev/null; then
    error_exit "Cluster not reachable after GCP Terraform apply. Ensure your GCP creds and outputs provide kubeconfig."
  fi
}

# Validate target cluster health before deploying Argo CD/apps
validate_cluster() {
  echo "🔎 Validating Kubernetes cluster health..."
  # API reachability
  if ! kubectl cluster-info >/dev/null 2>&1; then
    error_exit "Kubernetes API is not reachable with current context '$(kubectl config current-context 2>/dev/null || echo unknown)'."
  fi

  # Node readiness (wait up to 120s for at least one Ready node)
  local ready=0
  local end=$((SECONDS + 120))
  while [[ ${SECONDS} -lt ${end} ]]; do
    ready=$(kubectl get nodes -o json 2>/dev/null | jq -r '[.items[].status.conditions[] | select(.type=="Ready") | .status=="True"] | map(select(.==true)) | length' 2>/dev/null || echo 0)
    if [[ -n "$ready" && $ready -ge 1 ]]; then
      break
    fi
    sleep 3
  done
  if [[ -z "$ready" || $ready -lt 1 ]]; then
    kubectl get nodes -o wide || true
    error_exit "No Ready nodes detected after wait. Ensure your cluster has at least one Ready node."
  fi
  echo "✅ Nodes Ready: ${ready}"

  # StorageClass existence and default
  if ! kubectl get storageclass >/dev/null 2>&1; then
    error_exit "No StorageClass resources found. Configure a default StorageClass for dynamic provisioning."
  fi
  local has_default
  has_default=$(kubectl get storageclass -o json | jq -e '[.items[] | .metadata.annotations["storageclass.kubernetes.io/is-default-class"]=="true" or .metadata.annotations["storageclass.beta.kubernetes.io/is-default-class"]=="true"] | any' >/dev/null 2>&1; echo $?)
  if [[ "$has_default" != "0" ]]; then
    echo "[WARN] No default StorageClass detected. Some workloads may fail to provision PersistentVolumes."
    echo "       Tip (minikube): minikube addons enable storage-provisioner default-storageclass"
  else
    local def_sc
    def_sc=$(kubectl get storageclass -o json | jq -r '.items[] | select(.metadata.annotations["storageclass.kubernetes.io/is-default-class"]=="true" or .metadata.annotations["storageclass.beta.kubernetes.io/is-default-class"]=="true").metadata.name' | head -n1)
    echo "✅ Default StorageClass: ${def_sc}"
  fi
}

# Namespace for Argo CD is created by Helm (Terraform helm_release create_namespace=true)

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

## (moved under main flow and gated by resume)

# If Argo CD CRDs pre-exist (from previous installs), label/annotate them so Helm can adopt
# CRD patching no longer needed since Helm now manages CRD installation

# Deploy ArgoCD using Terraform
deploy_argocd() {
  TF_MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../infra/terraform/argocd" && pwd)"
  echo "Deploying ArgoCD via Terraform module at ${TF_MODULE_DIR}"
  TEMP_KUBECONFIG=$(mktemp -t fawkes-kubeconfig-XXXX.yaml)
  kubectl config view --raw --minify --flatten > "${TEMP_KUBECONFIG}"
  # Save previous env to restore after this function returns
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
  if [[ $DRY_RUN -eq 1 ]]; then
    echo "[DRY-RUN] Skipping terraform apply for ArgoCD module"
  else
    echo "Applying plan.tfplan"
    terraform apply -input=false plan.tfplan 2>&1 | tee -a terraform.log
    rc=${PIPESTATUS[0]}
  fi
  popd >/dev/null
  # Restore kubeconfig environment immediately after Terraform operations
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
  if [[ $DRY_RUN -eq 1 ]]; then
    echo "[DRY-RUN] Skipping ArgoCD wait and password steps"
    return 0
  fi
  echo "⏳ Waiting for ArgoCD server to be available..."
  kubectl wait --for=condition=available deployment/argocd-server -n "${ARGO_NS}" --timeout=300s
  ARGOCD_PASSWORD=$(kubectl -n "${ARGO_NS}" get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
  if [[ "$ENV" == "local" ]]; then
    FAWKES_LOCAL_PASSWORD="${FAWKES_LOCAL_PASSWORD:-fawkesidp}"
    if command -v argocd >/dev/null 2>&1; then
      echo "🔐 Setting ArgoCD admin password to a local default for developers..."
      # Detect service ports to choose correct forwarding & scheme
      local svc_ports svc_scheme svc_target_port
      svc_ports=$(kubectl -n "${ARGO_NS}" get svc argocd-server -o jsonpath='{.spec.ports[*].port}' 2>/dev/null || echo "")
      # Prefer HTTP (80) for local since chart is configured insecure=true
      if echo "${svc_ports}" | grep -qw 80; then
        svc_target_port=80; svc_scheme="http"; local argocd_login_flag="--plaintext"
      elif echo "${svc_ports}" | grep -qw 443; then
        svc_target_port=443; svc_scheme="https"; local argocd_login_flag="--insecure"
      else
        # Fallback to first port reported; assume http
        svc_target_port=$(kubectl -n "${ARGO_NS}" get svc argocd-server -o jsonpath='{.spec.ports[0].port}' 2>/dev/null || echo 80)
        svc_scheme="http"; local argocd_login_flag="--plaintext"
      fi
      (kubectl -n "${ARGO_NS}" port-forward svc/argocd-server 8080:${svc_target_port} >/dev/null 2>&1 & echo $! > /tmp/fawkes-argocd-pf.pid)
      sleep 2
      set +e
      # Use appropriate login flag based on scheme
      argocd login localhost:8080 --username admin --password "${ARGOCD_PASSWORD}" ${argocd_login_flag} >/dev/null 2>&1
      if [[ $? -eq 0 ]]; then
        argocd account update-password --current-password "${ARGOCD_PASSWORD}" --new-password "${FAWKES_LOCAL_PASSWORD}" >/dev/null 2>&1 && ARGOCD_PASSWORD="${FAWKES_LOCAL_PASSWORD}"
      else
        echo "[WARN] ArgoCD CLI login failed; attempting password change via kubectl proxy..." >&2
        # Fallback: use API server service proxy to change password
        (kubectl proxy --address 127.0.0.1 --port=8001 >/dev/null 2>&1 & echo $! > /tmp/fawkes-kubectl-proxy.pid)
        sleep 2
        local proxy_base="http://127.0.0.1:8001/api/v1/namespaces/${ARGO_NS}/services/${svc_scheme}:argocd-server:${svc_target_port}/proxy"
        local token
        token=$(curl -sk -X POST -H "Content-Type: application/json" \
          -d '{"username":"admin","password":"'"${ARGOCD_PASSWORD}"'"}' \
          "${proxy_base}/api/v1/session" | jq -r '.token // empty')
        if [[ -n "${token}" ]]; then
          curl -sk -X PUT -H "Authorization: Bearer ${token}" -H "Content-Type: application/json" \
            -d '{"currentPassword":"'"${ARGOCD_PASSWORD}"'","newPassword":"'"${FAWKES_LOCAL_PASSWORD}"'"}' \
            "${proxy_base}/api/v1/account/password" >/dev/null 2>&1 && ARGOCD_PASSWORD="${FAWKES_LOCAL_PASSWORD}" || \
            echo "[WARN] Password change via API proxy did not succeed." >&2
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
  # Derive scheme/port suggestion for local access summary
  local svc_ports_summary svc_scheme_summary svc_target_port_summary
  svc_ports_summary=$(kubectl -n "${ARGO_NS}" get svc argocd-server -o jsonpath='{.spec.ports[*].port}' 2>/dev/null || echo "")
  # Prefer HTTP (80) for local summary when available
  if echo "${svc_ports_summary}" | grep -qw 80; then
    svc_target_port_summary=80; svc_scheme_summary="http"
  elif echo "${svc_ports_summary}" | grep -qw 443; then
    svc_target_port_summary=443; svc_scheme_summary="https"
  else
    svc_target_port_summary=$(kubectl -n "${ARGO_NS}" get svc argocd-server -o jsonpath='{.spec.ports[0].port}' 2>/dev/null || echo 80)
    svc_scheme_summary="http"
  fi
  echo ""; echo "==================== ArgoCD Credentials ===================="; echo "URL:      ${svc_scheme_summary}://localhost:8080 (use port-forward below)"; echo "Username: admin"; echo "Password: ${ARGOCD_PASSWORD}"; echo "============================================================"; echo ""
}

## (log moved into ensure_argocd_workloads when invoked)

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

ensure_argocd_workloads() {
  echo "🌐 Ensuring ArgoCD deployments are available..."
  for dep in argocd-server argocd-repo-server argocd-application-controller argocd-dex-server; do
    if ! wait_for_workload "${dep}" "${ARGO_NS}" 300; then
      error_exit "Deployment ${dep} failed to become available"
    fi
  done
}
## (invoked from main via run_step)

## (log moved into wait_for_argocd_endpoints when invoked)
wait_for_argocd_endpoints() {
  echo "⏳ Waiting for argocd-server service endpoints..."
  ENDPOINTS_TIMEOUT=120
  end=$((SECONDS + ENDPOINTS_TIMEOUT))
  while [[ ${SECONDS} -lt ${end} ]]; do
    if kubectl get endpoints argocd-server -n "${ARGO_NS}" -o jsonpath='{.subsets}' | grep -q .; then
      echo "✅ argocd-server has endpoints"; return 0
    fi
    sleep 2
  done
  kubectl -n "${ARGO_NS}" get endpoints
  error_exit "argocd-server service has no endpoints after ${ENDPOINTS_TIMEOUT}s"
}
## (invoked from main via run_step)

## CRDs are now installed by Helm (Terraform helm_release); no manual ensure step required

## AppProject 'default' is now applied via platform/bootstrap kustomization

## (invoked from main via run_step)

## (log moved into seed_applications when invoked)

seed_applications() {
  echo "🌐 Applying bootstrap kustomization from platform/bootstrap..."
  # Apply the committed GitOps bootstrap (AppProject + root Applications)
  kubectl apply -k "${ROOT_DIR}/platform/bootstrap"
  echo "✅ Bootstrap applied — ArgoCD will pick up Applications and sync."
}

# Get service password from Kubernetes secret
get_service_password() {
  local secret_name="$1"
  local namespace="$2"
  local key="${3:-password}"
  
  kubectl get secret "$secret_name" -n "$namespace" -o jsonpath="{.data.$key}" 2>/dev/null | base64 -d 2>/dev/null || echo "N/A"
}

# Print comprehensive access summary for all services
print_access_summary() {
  echo ""
  echo "════════════════════════════════════════════════════════════════════════════════"
  echo "                         🎉 FAWKES PLATFORM ACCESS GUIDE"
  echo "════════════════════════════════════════════════════════════════════════════════"
  echo ""
  
  local ctx
  ctx=$(kubectl config current-context 2>/dev/null || echo "unknown")
  echo "📍 Kubernetes Context: $ctx"
  echo "🌍 Environment: $ENV"
  if [[ -n "${PROVIDER}" ]]; then
    echo "☁️  Provider: $PROVIDER"
  fi
  echo ""
  
  # Detect if we have ingress/LoadBalancer external IPs
  local has_external=0
  local external_domain=""
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
    fb_host=$(kubectl get ingress -n focalboard focalboard -o jsonpath='{.spec.rules[0].host}' 2>/devnull || echo "")
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
  
  if [[ "$PROVIDER" == "azure" ]]; then
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

main() {
  parse_flags "$@"
  # Validate environment after flag parsing
  if [[ -z "$ENV" ]]; then
    usage
  fi
  case "$ENV" in
    local|dev|stage|production|destroy|cleanup) ;;
    *) error_exit "Invalid command/environment: $ENV. Must be one of: local, dev, stage, production, destroy, cleanup." ;;
  esac
  # Verbose
  if [[ $VERBOSE -eq 1 ]]; then set -x; fi
  # Export TF vars if provided
  if [[ -n "$CLUSTER_NAME" ]]; then export TF_VAR_cluster_name="$CLUSTER_NAME"; fi
  if [[ -n "$REGION" ]]; then export TF_VAR_region="$REGION"; fi
  if [[ -n "$LOCATION" ]]; then export TF_VAR_location="$LOCATION"; fi

  # Always check prereqs before using jq/state
  check_prereqs

  # Setup state and context for --resume
  CONTEXT_ID="$(context_id)"
  state_setup
  if [[ $RESUME -eq 0 ]]; then
    state_clear_context "$CONTEXT_ID"
  fi
  # Mark prereqs completed when not dry-run
  if [[ $DRY_RUN -eq 0 ]]; then
    state_mark_done "check_prereqs"
  fi

  # Handle destroy subcommand early
  if [[ "$ENV" == "destroy" ]]; then
    if [[ -z "${PROVIDER}" ]]; then
      error_exit "Destroy requires --provider to be specified (local|aws|azure|gcp)."
    fi
    case "${PROVIDER}" in
      aws) run_step "destroy_cluster" destroy_aws_cluster ;;
      azure) run_step "destroy_cluster" destroy_azure_cluster ;;
      gcp) run_step "destroy_cluster" destroy_gcp_cluster ;;
      local) error_exit "Destroy for local provider not implemented via Terraform; use minikube delete or docker-desktop reset." ;;
    esac
    echo "✅ Destroy completed for provider '${PROVIDER}'."
    return 0
  fi

  local do_provision=1
  if [[ $ONLY_APPS -eq 1 || $SKIP_CLUSTER -eq 1 ]]; then do_provision=0; fi

  if [[ $do_provision -eq 1 ]]; then
    run_step "provision_cluster" provision_cluster
    if [[ $ONLY_CLUSTER -eq 1 ]]; then
      echo "✅ Cluster provisioning completed (--only-cluster)."
      return 0
    fi
  else
    echo "⏭️  Skipping cluster provisioning (--only-apps/--skip-cluster)."
  fi

  if [[ $DRY_RUN -eq 0 ]]; then
    run_step "validate_cluster" validate_cluster
  else
    echo "[DRY-RUN] Skipping cluster validation"
  fi
  
  run_step "maybe_cleanup_argocd_cluster_resources" maybe_cleanup_argocd_cluster_resources
  # CRD patching not required; Helm manages CRDs now
  run_step "deploy_argocd" deploy_argocd

  if [[ $DRY_RUN -eq 0 ]]; then
    run_step "ensure_argocd_workloads" ensure_argocd_workloads
    run_step "wait_for_argocd_endpoints" wait_for_argocd_endpoints
    # CRDs and AppProject are handled by Helm and bootstrap kustomization
    run_step "seed_applications" seed_applications
  else
    echo "[DRY-RUN] Skipping workload waits and application seeding"
  fi
  post_deploy_summary
}

main "$@"
exit 0
