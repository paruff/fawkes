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

# =============================================================================
# Azure-specific helper functions
# =============================================================================

# Install kubelogin for Azure AD authentication
install_kubelogin() {
  if command -v kubelogin &> /dev/null; then
    echo "✅ kubelogin already installed"
    return 0
  fi
  
  echo "📦 Installing kubelogin..."
  
  # Try to install via homebrew on macOS
  if [[ "$OSTYPE" == "darwin"* ]] && command -v brew &> /dev/null; then
    brew install Azure/kubelogin/kubelogin
    return $?
  fi
  
  # Install via curl for Linux
  local version="v0.1.4"
  local arch="amd64"
  local os="linux"
  
  if [[ "$OSTYPE" == "darwin"* ]]; then
    os="darwin"
  fi
  
  local url="https://github.com/Azure/kubelogin/releases/download/${version}/kubelogin-${os}-${arch}.zip"
  local tmp_dir="$(mktemp -d)"
  
  if ! curl -sL "${url}" -o "${tmp_dir}/kubelogin.zip"; then
    echo "❌ Failed to download kubelogin"
    rm -rf "${tmp_dir}"
    return 1
  fi
  
  if ! command -v unzip &> /dev/null; then
    echo "❌ unzip command not found"
    rm -rf "${tmp_dir}"
    return 1
  fi
  
  unzip -q "${tmp_dir}/kubelogin.zip" -d "${tmp_dir}"
  
  local install_dir="${HOME}/.local/bin"
  mkdir -p "${install_dir}"
  
  mv "${tmp_dir}/bin/${os}_${arch}/kubelogin" "${install_dir}/"
  chmod +x "${install_dir}/kubelogin"
  
  rm -rf "${tmp_dir}"
  
  echo "✅ kubelogin installed to ${install_dir}/kubelogin"
  return 0
}

# Refresh AKS cluster credentials
refresh_aks_credentials() {
  local resource_group="$1"
  local cluster_name="$2"
  
  if [[ -z "${resource_group}" || -z "${cluster_name}" ]]; then
    echo "❌ Error: resource_group and cluster_name are required"
    return 1
  fi
  
  echo "🔄 Refreshing AKS credentials for ${cluster_name} in ${resource_group}..."
  
  # Get cluster information (without --query for mock compatibility)
  local cluster_info
  cluster_info=$(az aks show \
    --resource-group "${resource_group}" \
    --name "${cluster_name}" \
    2>/dev/null)
  
  if [[ -z "${cluster_info}" ]]; then
    echo "❌ Error: Failed to get cluster information"
    return 1
  fi
  
  # Parse state from JSON (support both 'state' and 'provisioningState' for compatibility)
  local cluster_state
  if command -v jq &> /dev/null; then
    cluster_state=$(echo "${cluster_info}" | jq -r '.state // .provisioningState // "Unknown"')
  else
    # Fallback to grep for basic parsing if jq is not available
    cluster_state=$(echo "${cluster_info}" | grep -oP '"(state|provisioningState)"\s*:\s*"\K[^"]+' | head -1)
    cluster_state="${cluster_state:-Unknown}"
  fi
  
  if [[ "${cluster_state}" != "Succeeded" ]]; then
    echo "❌ Error: AKS cluster is not in 'Succeeded' state (current: ${cluster_state})"
    return 1
  fi
  
  # Install kubelogin if needed
  install_kubelogin
  
  # Get credentials
  if ! az aks get-credentials \
    --resource-group "${resource_group}" \
    --name "${cluster_name}" \
    --overwrite-existing 2>/dev/null; then
    echo "❌ Failed to get AKS credentials"
    return 1
  fi
  
  # Check if Azure RBAC is enabled
  local azure_rbac
  if command -v jq &> /dev/null; then
    azure_rbac=$(echo "${cluster_info}" | jq -r '.azureRbac // .aadProfile.enableAzureRbac // "false"')
  else
    azure_rbac="false"
  fi
  
  if [[ "${azure_rbac}" == "true" ]]; then
    echo "ℹ️  Azure RBAC is enabled, converting kubeconfig to use kubelogin..."
    kubelogin convert-kubeconfig -l azurecli 2>/dev/null || true
  fi
  
  echo "✅ AKS credentials refreshed successfully"
  return 0
}

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
