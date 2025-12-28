#!/usr/bin/env bash
# =============================================================================
# GCP cloud provider provisioning
# =============================================================================
set -euo pipefail

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMON_LIB="${SCRIPT_DIR}/../common.sh"

if [[ ! -f "$COMMON_LIB" ]]; then
  echo "❌ Error: common.sh not found at $COMMON_LIB" >&2
  exit 1
fi

source "$COMMON_LIB"


provision_gcp_cluster() {
  echo "🔧 Provider=gcp selected. Applying Terraform under infra/gcp..."
  local dir
  dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../infra/gcp" 2>/dev/null || true)"
  if [[ -z "$dir" || ! -d "$dir" ]]; then
    error_exit "infra/gcp not found yet. GCP provisioning not implemented."
  fi
  tf_apply_dir "$dir"
  try_set_kubeconfig_from_tf_outputs "$dir"
  if [[ ${DRY_RUN:-0} -eq 0 ]] && ! kubectl cluster-info &>/dev/null; then
    error_exit "Cluster not reachable after GCP Terraform apply. Ensure your GCP creds and outputs provide kubeconfig."
  fi
}

destroy_gcp_cluster() {
  echo "🔧 Provider=gcp selected. Destroying Terraform under infra/gcp..."
  local dir
  dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../infra/gcp" 2>/dev/null || true)"
  if [[ -z "$dir" || ! -d "$dir" ]]; then
    error_exit "infra/gcp not found yet. GCP provisioning not implemented."
  fi
  tf_destroy_dir "$dir"
}
