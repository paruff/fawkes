# Azure AKS Module

Manages an Azure Kubernetes Service (AKS) cluster with full production-grade configuration including auto-scaling, monitoring, Azure AD integration, and diagnostic settings.

## Usage

```hcl
module "aks" {
  source              = "../../modules/azure/aks"
  cluster_name        = "fawkes-aks"
  location            = "eastus2"
  resource_group_name = module.rg.name
  subnet_id           = module.network.private_subnet_ids["aks-subnet"]

  kubernetes_version = "1.28"
  sku_tier           = "Standard"

  # Auto-scaling
  enable_auto_scaling = true
  node_min_count      = 2
  node_max_count      = 10

  # Monitoring
  enable_azure_monitor = true
  log_retention_days   = 30

  tags = {
    environment = "dev"
    platform    = "fawkes"
    managed_by  = "terraform"
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.6.0 |
| azurerm | >= 3.110.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| cluster_name | Name of the AKS cluster | `string` | n/a | yes |
| location | Azure region for the AKS cluster | `string` | n/a | yes |
| resource_group_name | Name of the resource group | `string` | n/a | yes |
| subnet_id | ID of the subnet for AKS nodes | `string` | n/a | yes |
| dns_prefix | DNS prefix for the cluster | `string` | `null` | no |
| kubernetes_version | Kubernetes version to use | `string` | `"1.28"` | no |
| sku_tier | SKU tier (Free or Standard) | `string` | `"Standard"` | no |
| default_node_pool_name | Name of the default node pool | `string` | `"systemnp"` | no |
| node_vm_size | VM size for the default node pool | `string` | `"Standard_D2s_v3"` | no |
| node_count | Number of nodes (when auto-scaling disabled) | `number` | `3` | no |
| only_critical_addons_enabled | Only enable critical addons | `bool` | `false` | no |
| availability_zones | Availability zones for node pools | `list(string)` | `["1","2","3"]` | no |
| enable_auto_scaling | Enable auto-scaling | `bool` | `true` | no |
| node_min_count | Minimum nodes (auto-scaling) | `number` | `1` | no |
| node_max_count | Maximum nodes (auto-scaling) | `number` | `10` | no |
| node_os_disk_size_gb | OS disk size in GB | `number` | `128` | no |
| node_os_disk_type | OS disk type | `string` | `"Managed"` | no |
| node_max_pods | Maximum pods per node | `number` | `110` | no |
| max_surge | Max nodes during upgrade | `string` | `"33%"` | no |
| additional_node_pools | Additional node pools | `map(object)` | `{}` | no |
| enable_rbac | Enable Kubernetes RBAC | `bool` | `true` | no |
| enable_azure_ad_rbac | Enable Azure AD RBAC integration | `bool` | `false` | no |
| azure_rbac_enabled | Enable Azure RBAC for authorization | `bool` | `false` | no |
| azure_ad_admin_group_object_ids | Azure AD admin group IDs | `list(string)` | `[]` | no |
| network_plugin | Network plugin (azure or kubenet) | `string` | `"azure"` | no |
| network_policy | Network policy (azure or calico) | `string` | `"azure"` | no |
| dns_service_ip | DNS service IP | `string` | `"10.1.0.10"` | no |
| service_cidr | Service CIDR | `string` | `"10.1.0.0/16"` | no |
| load_balancer_sku | Load balancer SKU | `string` | `"standard"` | no |
| outbound_type | Outbound routing method | `string` | `"loadBalancer"` | no |
| api_server_authorized_ip_ranges | Authorized IP ranges for API server | `list(string)` | `[]` | no |
| enable_azure_monitor | Enable Azure Monitor Container Insights | `bool` | `true` | no |
| log_analytics_workspace_id | Existing Log Analytics workspace ID | `string` | `null` | no |
| log_retention_days | Log retention in days | `number` | `30` | no |
| enable_diagnostic_settings | Enable diagnostic settings | `bool` | `true` | no |
| enable_azure_policy | Enable Azure Policy add-on | `bool` | `false` | no |
| tags | Tags to apply to resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| cluster_id | The ID of the AKS cluster |
| cluster_name | The name of the AKS cluster |
| cluster_fqdn | FQDN of the AKS cluster |
| cluster_endpoint | Endpoint for AKS control plane (sensitive) |
| cluster_version | The Kubernetes version |
| kube_config | Kubeconfig (sensitive) |
| kube_admin_config | Admin kubeconfig (sensitive) |
| client_certificate | Client certificate (sensitive) |
| client_key | Client key (sensitive) |
| cluster_ca_certificate | CA certificate (sensitive) |
| identity_principal_id | Principal ID of the managed identity |
| identity_tenant_id | Tenant ID of the managed identity |
| kubelet_identity_object_id | Object ID of the kubelet identity |
| kubelet_identity_client_id | Client ID of the kubelet identity |
| node_resource_group | Auto-generated node resource group |
| oidc_issuer_url | OIDC issuer URL |
| default_node_pool_name | Name of the default node pool |
| additional_node_pool_ids | Map of additional node pool names to IDs |
| log_analytics_workspace_id | ID of the Log Analytics workspace |
| log_analytics_workspace_name | Name of the Log Analytics workspace |
| portal_fqdn | FQDN for Azure Portal integration |
| private_fqdn | FQDN for private cluster endpoint |

## Validation Rules

- Cluster name must be 1–63 characters, start and end with alphanumeric, contain only alphanumerics and hyphens
- Kubernetes version must be 1.24 or higher (format: 1.28)
- SKU tier must be `Free` or `Standard`
- Default node pool name must be lowercase alphanumeric, start with a letter, max 12 characters
- Node count must be 1–1000; min count 0–1000; max count 1–1000
- OS disk size must be at least 30 GB
- OS disk type must be `Managed` or `Ephemeral`
- Max pods per node must be 10–250
- Availability zones must each be `1`, `2`, or `3`
- Network plugin must be `azure` or `kubenet`
- Network policy must be `azure` or `calico`
- Service CIDR must be a valid CIDR block
- DNS service IP must be a valid IP address
- Load balancer SKU must be `basic` or `standard`
- Outbound type must be `loadBalancer` or `userDefinedRouting`
- All authorized IP ranges must be valid CIDR blocks
- Log retention must be a valid value: 30, 60, 90, 120, 180, 270, 365, 550, or 730 days
