#!/usr/bin/env bash
set -euo pipefail

# buildinfra.sh - Provision VPC and Kubernetes cluster, configure kubectl, and create namespaces

# Check for required tools
for tool in terraform kubectl aws; do
  if ! command -v "$tool" &>/dev/null; then
    echo "Error: $tool is not installed or not in PATH."
    exit 1
  fi
done

# Initialize and apply Terraform
terraform init
terraform fmt
terraform plan
terraform apply --auto-approve

# Set up kubeconfig using Terraform outputs
REGION=$(terraform output -raw region)
CLUSTER_NAME=$(terraform output -raw cluster_name)

if [[ -n "$REGION" && -n "$CLUSTER_NAME" ]]; then
  aws eks --region "$REGION" update-kubeconfig --name "$CLUSTER_NAME"
else
  echo "Error: REGION or CLUSTER_NAME output is missing from Terraform."
  exit 1
fi

# Backup and set KUBECONFIG
mkdir -p "$HOME/.kube"
cp kubeconfig_* "$HOME/.kube/config" 2>/dev/null || true
cp kubeconfig_* "$HOME/.kube/" 2>/dev/null || true
export KUBECONFIG_SAVED="${KUBECONFIG:-}"
export KUBECONFIG="$HOME/.kube/config"

# Optionally apply AWS auth config map if output is available
if terraform output config_map_aws_auth &>/dev/null; then
  mkdir -p /tmp
  terraform output config_map_aws_auth > /tmp/configmap.yml
  kubectl apply -f /tmp/configmap.yml
fi

# Create namespaces if they do not exist
for ns in fawkes dev stage prod; do
  if ! kubectl get namespace "$ns" &>/dev/null; then
    kubectl create namespace "$ns"
  else
    echo "Namespace '$ns' already exists."
  fi
done

echo "Infrastructure and namespaces are ready."
