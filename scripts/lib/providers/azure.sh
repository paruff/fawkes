#!/usr/bin/env bash
# =============================================================================
# Azure cloud provider provisioning
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


provision_azure_cluster() {
  echo "🔧 Provider=azure selected. Applying Terraform under infra/azure..."
  local dir
  local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  dir="${script_dir}/../../../infra/azure"
  dir="$(cd "$dir" 2>/dev/null && pwd)" || {
    echo "❌ Error: Unable to resolve Azure Terraform directory"
    return 1
  }
  tf_apply_dir "$dir"
  try_set_kubeconfig_from_tf_outputs "$dir"
  if [[ ${DRY_RUN:-0} -eq 0 ]] && ! kubectl cluster-info &>/dev/null; then
    error_exit "Cluster not reachable after Azure Terraform apply. Ensure your Azure creds and outputs provide kubeconfig."
  fi
}

destroy_azure_cluster() {
  echo "🔧 Provider=azure selected. Destroying Terraform under infra/azure..."
  local dir
  local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  dir="${script_dir}/../../../infra/azure"
  dir="$(cd "$dir" 2>/dev/null && pwd)" || {
    echo "❌ Error: Unable to resolve Azure Terraform directory"
    return 1
  }
  tf_destroy_dir "$dir"
}
