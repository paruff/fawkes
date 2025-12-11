# AKS Terraform Module (Fawkes)

This module provisions a compliant Azure Kubernetes Service (AKS) cluster aligned with Fawkes conventions: declarative IaC, GitOps-first, immutable infra, and observability tags.

## Structure
- `providers.tf`: Terraform and providers (`azurerm`, `azuread`) with `features {}`
- `variables.tf`: Inputs for RG, network, cluster, and conventions
- `network.tf`: Resource Group, VNet, Subnet for AKS
- `aks.tf`: AKS cluster with system node pool, RBAC, MI, network profile
	- If `kubernetes_version` is omitted, AKS selects the default supported version for the region (recommended for Free tier).
- `outputs.tf`: Kubeconfigs and node resource group
- `terraform.tfvars.example`: Example values to copy and edit

## Prereqs
- Azure CLI authenticated and subscription set
- Terraform >= 1.6
- Provide `subscription_id` and `tenant_id` via `terraform.tfvars` (recommended) or export env vars `ARM_SUBSCRIPTION_ID` and `ARM_TENANT_ID`.

## Quick Start
```zsh
# 1) Authenticate and set subscription
az login
az account set --subscription "<SUBSCRIPTION_ID>"

# 2) Check supported Kubernetes versions in region
az aks get-versions -l "<region>" -o table

# 3) Configure variables
cd infra/terraform/aks
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
# Optionally set exact Kubernetes version; otherwise omit to use AKS default (non-LTS) for Free tier.

# (Alt) Set env vars if not using tfvars for subscription/tenant
export ARM_SUBSCRIPTION_ID=$(az account show --query id -o tsv)
export ARM_TENANT_ID=$(az account show --query tenantId -o tsv)

# 4) Plan and apply
terraform init
terraform fmt -check -recursive
terraform validate
terraform plan -out tfplan
terraform apply tfplan

# 5) Use kubeconfig
# Export a temporary kubeconfig from outputs, or use az aks get-credentials
az aks get-credentials -g "<rg_name>" -n "<cluster_name>" --admin
kubectl get nodes
```

## Notes
- Default network plugin is Azure CNI; ensure `subnet_cidr` is sized appropriately.
- For API server IP allow-list, add your public IP to `api_server_authorized_ip_ranges`.
- Use Managed Identity by default and grant `AcrPull` to pull images from ACR if needed.
- Keep tags consistent (`app`, `component`, `environment`) for observability.

## Troubleshooting
- Provider features missing: ensure `provider "azurerm" { features {} }`.
- Subscription/Tenant missing: set `subscription_id` and `tenant_id` in `terraform.tfvars`, or export `ARM_SUBSCRIPTION_ID` and `ARM_TENANT_ID`.
 - Version mismatch: either pick a `kubernetes_version` supported in your region and plan tier, or omit it to use AKS default.
- Quota/SKU: verify VM SKU availability with `az vm list-skus -l <region>`.
- Networking: ensure `service_cidr` and `dns_service_ip` align; subnet exists and is large enough.
 - VM size not allowed: pick an allowed SKU (e.g., `Standard_B2ms` for dev), and confirm availability:
	 ```zsh
	 az vm list-skus -l eastus -o table | grep -i '^standard_b2ms\|^standard_b2s'
	 ```
