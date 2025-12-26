#!/usr/bin/env bash
# =============================================================================
# File: scripts/lib/providers/aws.sh

set -euo pipefail
# Purpose: AWS EKS cluster provisioning
# =============================================================================


set -euo pipefail
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
