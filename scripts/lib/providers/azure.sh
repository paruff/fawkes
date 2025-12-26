#!/usr/bin/env bash
# =============================================================================
# File: scripts/lib/providers/azure.sh

set -euo pipefail
# Purpose: Azure AKS cluster provisioning with RBAC and kubelogin
# =============================================================================


install_kubelogin() {
  if command -v kubelogin >/dev/null 2>&1; then
    echo "✅ kubelogin already installed"
    return 0
  fi

  echo "📦 Installing kubelogin for AKS authentication..."

  if [[ "$(uname -s)" == "Darwin" ]]; then
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
    aarch64 | arm64) arch="arm64" ;;
  esac

  local version
  version=$(curl -s https://api.github.com/repos/Azure/kubelogin/releases/latest | jq -r '.tag_name' || echo "v0.1.4")

  url="https://github.com/Azure/kubelogin/releases/download/${version}/kubelogin-${os}-${arch}.zip"

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
    local binary
    binary=$(find "${tmpdir}" -name "kubelogin" -type f | head -n1)
    if [[ -n "$binary" ]]; then
      chmod +x "$binary"
      mv "$binary" "${install_dir}/kubelogin"
      if [[ ":$PATH:" != *":${install_dir}:"* ]]; then
        export PATH="${install_dir}:${PATH}"
        echo "Added ${install_dir} to PATH for this session"
        echo "Add 'export PATH=\"${install_dir}:\$PATH\"' to your shell profile for persistence"
      fi
    fi
  fi

  rm -rf "${tmpdir}"
}

refresh_aks_credentials() {
  local rg_name="$1"
  local cluster_name="$2"

  echo "🔄 Refreshing AKS credentials..."
  echo "🔍 Checking AKS cluster status..."
  local cluster_info cluster_state azure_rbac_enabled
  cluster_info=$(az aks show -g "$rg_name" -n "$cluster_name" --query '{state:provisioningState,azureRbac:aadProfile.enableAzureRbac}' -o json 2>/dev/null || echo '{}')
  cluster_state=$(echo "$cluster_info" | jq -r '.state // "Unknown"')
  azure_rbac_enabled=$(echo "$cluster_info" | jq -r '.azureRbac // false')

  if [[ "$cluster_state" != "Succeeded" ]]; then
    error_exit "AKS cluster is not in 'Succeeded' state (current: $cluster_state). Wait for cluster to be ready."
  fi

  echo "✅ AKS cluster status: $cluster_state"

  echo "🧹 Removing old cluster contexts..."
  kubectl config delete-context "$cluster_name" 2>/dev/null || true
  kubectl config delete-cluster "$cluster_name" 2>/dev/null || true
  kubectl config unset "users.clusterUser_${rg_name}_${cluster_name}" 2>/dev/null || true

  if [[ "$azure_rbac_enabled" == "true" ]]; then
    echo "🔐 Azure RBAC for Kubernetes is enabled"
    local user_oid user_email
    user_oid=$(az ad signed-in-user show --query id -o tsv 2>/dev/null || echo "")
    user_email=$(az ad signed-in-user show --query userPrincipalName -o tsv 2>/dev/null || echo "unknown")

    if [[ -n "$user_oid" ]]; then
      echo "👤 Current user: $user_email (OID: $user_oid)"
      echo "🔍 Checking for Azure Kubernetes Service RBAC Cluster Admin role..."
      local has_admin_role
      has_admin_role=$(az role assignment list \
        --assignee "$user_oid" \
        --scope "/subscriptions/${ARM_SUBSCRIPTION_ID}/resourceGroups/${rg_name}/providers/Microsoft.ContainerService/managedClusters/${cluster_name}" \
        --query "[?roleDefinitionName=='Azure Kubernetes Service RBAC Cluster Admin'].roleDefinitionName" \
        -o tsv 2>/dev/null || echo "")

      if [[ -z "$has_admin_role" ]]; then
        echo "⚠️  User does not have cluster admin role yet"
        echo "🔧 Granting Azure Kubernetes Service RBAC Cluster Admin role..."
        if az role assignment create \
          --role "Azure Kubernetes Service RBAC Cluster Admin" \
          --assignee "$user_oid" \
          --scope "/subscriptions/${ARM_SUBSCRIPTION_ID}/resourceGroups/${rg_name}/providers/Microsoft.ContainerService/managedClusters/${cluster_name}" \
          >/dev/null 2>&1; then
          echo "✅ Cluster admin role granted"
        else
          echo "⚠️  Role may already exist or creation failed (continuing anyway)"
        fi
      else
        echo "✅ User already has cluster admin role"
      fi

      echo "⏳ Waiting 30 seconds for Azure RBAC propagation..."
      sleep 30
    fi
  fi

  echo "📥 Downloading cluster credentials..."
  az aks get-credentials \
    --resource-group "$rg_name" \
    --name "$cluster_name" \
    --overwrite-existing \
    --file "${KUBECONFIG:-$HOME/.kube/config}"

  if ! command -v kubelogin >/dev/null 2>&1; then
    install_kubelogin || {
      echo "[ERROR] kubelogin installation failed"
      return 1
    }
  fi

  echo "🔐 Converting kubeconfig to azurecli authentication..."
  if kubelogin convert-kubeconfig -l azurecli --kubeconfig "${KUBECONFIG:-$HOME/.kube/config}"; then
    echo "✅ Kubeconfig converted to azurecli auth"
  else
    echo "[ERROR] Kubeconfig conversion failed"
    return 1
  fi

  echo "🔍 Verifying cluster connectivity (may take up to 60s for RBAC propagation)..."
  local max_attempts=12 attempt=1 connected=0

  while [[ $attempt -le $max_attempts ]]; do
    echo "   Attempt $attempt/$max_attempts..."
    if kubectl get nodes >/dev/null 2>&1; then
      echo "✅ kubectl connectivity verified"
      kubectl get nodes -o wide
      connected=1
      break
    fi

    local last_error
    last_error=$(kubectl get nodes 2>&1 || true)
    if echo "$last_error" | grep -q "Forbidden.*does not have access"; then
      if [[ $attempt -lt 6 ]]; then
        echo "   ℹ️  RBAC permissions still propagating..."
      else
        echo "   ⚠️  RBAC propagation taking longer than expected"
        echo "   Tip: Azure RBAC can take up to 5 minutes to propagate"
      fi
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
    echo "Azure RBAC permissions may still be propagating. Options:"
    echo ""
    echo "1️⃣  Wait a few more minutes and retry:"
    echo "    kubectl get nodes"
    echo ""
    echo "2️⃣  Use admin credentials (dev only - bypasses RBAC):"
    echo "    az aks get-credentials -g $rg_name -n $cluster_name --admin --overwrite-existing"
    echo "    kubectl get nodes"
    echo ""
    echo "3️⃣  Verify role assignment:"
    echo "    az role assignment list --assignee ${user_oid:-USER_OID} --scope /subscriptions/${ARM_SUBSCRIPTION_ID}/resourceGroups/${rg_name}/providers/Microsoft.ContainerService/managedClusters/${cluster_name}"
    echo ""
    echo "════════════════════════════════════════════════════════════════════════════════"
    return 1
  fi
}

provision_azure_cluster() {
  echo "🔧 Provider=azure selected. Applying Terraform under infra/azure..."
  local dir
  dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../infra/azure" && pwd)"
  if [[ -n "${LOCATION:-}" ]]; then export TF_VAR_location="$LOCATION"; fi
  if [[ -n "${CLUSTER_NAME:-}" ]]; then export TF_VAR_cluster_name="$CLUSTER_NAME"; fi
  
  tf_apply_dir "$dir"
  
  # Export KUBECONFIG from Terraform outputs
  echo "🔑 Resolving kubeconfig for cluster access..."
  local rg_name="${TF_VAR_resource_group_name:-fawkes-rg}"
  local cluster_name="${TF_VAR_cluster_name:-fawkes-dev}"
  
  local tfjson kubeconfig_path
  tfjson=$(cd "$dir" && terraform output -json 2>/dev/null || true)
  if [[ -n "$tfjson" ]]; then
    kubeconfig_path=$(echo "$tfjson" | jq -r '.kubeconfig_path.value // empty' 2>/dev/null || true)
    if [[ -n "$kubeconfig_path" ]]; then
      if [[ "$kubeconfig_path" != /* ]]; then
        kubeconfig_path="$dir/$kubeconfig_path"
      fi
      export KUBECONFIG="$kubeconfig_path"
      export TF_VAR_kubeconfig_path="$kubeconfig_path"
      echo "✅ KUBECONFIG set to $KUBECONFIG"
    fi
  fi
  
  if command -v az >/dev/null 2>&1; then
    refresh_aks_credentials "$rg_name" "$cluster_name"
  fi
  
  if [[ ${DRY_RUN:-0} -eq 0 ]] && ! kubectl cluster-info &>/dev/null; then
    error_exit "Cluster not reachable after Azure Terraform apply. Ensure your Azure creds and outputs provide kubeconfig."
  fi
}

destroy_azure_cluster() {
  echo "🔧 Provider=azure selected. Destroying Terraform under infra/azure..."
  local dir
  dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../infra/azure" && pwd)"
  if [[ -n "${LOCATION:-}" ]]; then export TF_VAR_location="$LOCATION"; fi
  if [[ -n "${CLUSTER_NAME:-}" ]]; then export TF_VAR_cluster_name="$CLUSTER_NAME"; fi
  tf_destroy_dir "$dir"
  if [[ -n "${KUBECONFIG:-}" && -f "$KUBECONFIG" ]]; then
    echo "[INFO] Destroy complete. Keeping existing KUBECONFIG at $KUBECONFIG; remove manually if desired."
  fi
}
