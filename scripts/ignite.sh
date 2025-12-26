#!/usr/bin/env bash
# =============================================================================
# File: scripts/ignite.sh.new
# Purpose: Orchestrate Fawkes bootstrap - modular refactored version
# Usage: bash ./scripts/ignite.sh [options] <environment>
# See: scripts/lib/flags.sh for full flag documentation
# =============================================================================
set -euo pipefail

# Ensure we are running under bash even if invoked from zsh/sh
if [[ -z "${BASH_VERSION:-}" ]]; then
  exec bash "$0" "$@"
fi

echo "Current working directory: $(pwd)"

# Default configuration
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
SHOW_ACCESS_ONLY=0
ENV=""
PREFER_MINIKUBE=0
PREFER_DOCKER=0

# State tracking
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STATE_FILE="${ROOT_DIR}/.ignite-state.json"
CONTEXT_ID=""

# Source all library modules
LIB_DIR="${ROOT_DIR}/scripts/lib"
source "${LIB_DIR}/common.sh"
source "${LIB_DIR}/flags.sh"
source "${LIB_DIR}/prereqs.sh"
source "${LIB_DIR}/terraform.sh"
source "${LIB_DIR}/validation.sh"
source "${LIB_DIR}/cluster.sh"
source "${LIB_DIR}/argocd.sh"
source "${LIB_DIR}/summary.sh"

# Source provider modules
source "${LIB_DIR}/providers/local.sh"
source "${LIB_DIR}/providers/aws.sh"
source "${LIB_DIR}/providers/azure.sh"
source "${LIB_DIR}/providers/gcp.sh"

# Handle cleanup command early
for _arg in "$@"; do
  if [[ "$_arg" == "cleanup" || "$_arg" == "clean" ]]; then
    cleanup_resources
    exit 0
  fi
done

main() {
  parse_flags "$@"

  # Handle --access flag early
  if [[ $SHOW_ACCESS_ONLY -eq 1 ]]; then
    if [[ -x "$(dirname "${BASH_SOURCE[0]}")/access-summary.sh" ]]; then
      exec "$(dirname "${BASH_SOURCE[0]}")/access-summary.sh" "${PROVIDER:-all}"
    else
      post_deploy_summary
    fi
    exit 0
  fi

  # Validate environment
  if [[ -z "$ENV" ]]; then
    usage
  fi
  case "$ENV" in
    local | dev | stage | production | destroy | cleanup) ;;
    *) error_exit "Invalid command/environment: $ENV. Must be one of: local, dev, stage, production, destroy, cleanup." ;;
  esac

  # Enable verbose mode
  if [[ $VERBOSE -eq 1 ]]; then set -x; fi

  # Export TF vars if provided
  if [[ -n "$CLUSTER_NAME" ]]; then export TF_VAR_cluster_name="$CLUSTER_NAME"; fi
  if [[ -n "$REGION" ]]; then export TF_VAR_region="$REGION"; fi
  if [[ -n "$LOCATION" ]]; then export TF_VAR_location="$LOCATION"; fi

  # Always check prereqs
  check_prereqs

  # Setup state and context for --resume
  CONTEXT_ID="$(context_id)"
  state_setup
  if [[ $RESUME -eq 0 ]]; then
    state_clear_context "$CONTEXT_ID"
  fi
  if [[ $DRY_RUN -eq 0 ]]; then
    state_mark_done "check_prereqs"
  fi

  # Handle destroy subcommand
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

  # Determine if we should provision cluster
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

  # Validate cluster if not dry-run
  if [[ $DRY_RUN -eq 0 ]]; then
    run_step "validate_cluster" validate_cluster
  else
    echo "[DRY-RUN] Skipping cluster validation"
  fi

  # Deploy ArgoCD
  run_step "maybe_cleanup_argocd_cluster_resources" maybe_cleanup_argocd_cluster_resources
  run_step "deploy_argocd" deploy_argocd

  # Wait for ArgoCD and seed applications
  if [[ $DRY_RUN -eq 0 ]]; then
    run_step "ensure_argocd_workloads" ensure_argocd_workloads
    run_step "wait_for_argocd_endpoints" wait_for_argocd_endpoints
    run_step "seed_applications" seed_applications
  else
    echo "[DRY-RUN] Skipping workload waits and application seeding"
  fi

  # Print access summary
  post_deploy_summary
}

main "$@"
exit 0
