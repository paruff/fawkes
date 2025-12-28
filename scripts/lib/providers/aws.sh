#!/usr/bin/env bash
# =============================================================================
# AWS cloud provider provisioning
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


provision_aws_cluster() {
  echo "🔧 Provider=aws selected. Applying Terraform under infra/aws..."
  local dir
  dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../infra/aws" && pwd)"
  tf_apply_dir "$dir"
  try_set_kubeconfig_from_tf_outputs "$dir"
  if [[ ${DRY_RUN:-0} -eq 0 ]] && ! kubectl cluster-info &>/dev/null; then
    error_exit "Cluster not reachable after AWS Terraform apply. Ensure your AWS creds and outputs provide kubeconfig."
  fi
}

destroy_aws_cluster() {
  echo "🔧 Provider=aws selected. Destroying Terraform under infra/aws..."
  local dir
  dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../infra/aws" && pwd)"
  tf_destroy_dir "$dir"
}
