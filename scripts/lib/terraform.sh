#!/usr/bin/env bash
# =============================================================================
# File: scripts/lib/terraform.sh
# Purpose: Terraform operations - apply, destroy, output handling
# =============================================================================

tf_apply_dir() {
  local dir="$1"
  if [[ ! -d "$dir" ]]; then
    error_exit "Terraform directory not found: $dir"
  fi
  echo "🚀 Running Terraform in $dir"
  pushd "$dir" >/dev/null

  # Ensure Azure subscription and tenant env vars are set from az CLI context if available
  if command -v az >/dev/null 2>&1; then
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
  if command -v az >/dev/null 2>&1 && [[ "${PROVIDER}" == "azure" ]]; then
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
  if [[ ${DRY_RUN:-0} -eq 1 ]]; then
    echo "[DRY-RUN] Skipping terraform apply in $dir"
  else
    terraform apply -input=false plan.tfplan 2>&1 | tee -a terraform.log
    rc=${PIPESTATUS[0]}
  fi
  popd >/dev/null

  if [[ $rc -ne 0 ]]; then
    error_exit "Terraform apply failed for $dir; see $dir/terraform.log"
  fi
}

tf_destroy_dir() {
  local dir="$1"
  if [[ ! -d "$dir" ]]; then
    error_exit "Terraform directory not found: $dir"
  fi
  echo "🗑️  Destroying Terraform in $dir"
  pushd "$dir" >/dev/null
  if command -v az >/dev/null 2>&1; then
    export ARM_SUBSCRIPTION_ID="${ARM_SUBSCRIPTION_ID:-$(az account show --query id -o tsv 2>/dev/null || true)}"
    export ARM_TENANT_ID="${ARM_TENANT_ID:-$(az account show --query tenantId -o tsv 2>/dev/null || true)}"
  fi
  terraform init -upgrade -input=false 2>&1 | tee terraform.log
  local rc=0
  if [[ ${DRY_RUN:-0} -eq 1 ]]; then
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
    printf "%s" "$content" >"$tmpkc"
    export KUBECONFIG="$tmpkc"
    export TF_VAR_kubeconfig_path="$tmpkc"
    echo "✅ Wrote kubeconfig from Terraform output to: $tmpkc"
    return 0
  fi
  echo "[WARN] Terraform outputs in $dir do not include kubeconfig_path or kubeconfig; leaving KUBECONFIG unchanged." >&2
}
