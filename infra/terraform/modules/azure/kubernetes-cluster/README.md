# Azure Kubernetes Cluster (AKS) Module

Manages an Azure Kubernetes Service (AKS) cluster, extending the base kubernetes-cluster module.

## Usage

```hcl
module "aks" {
  source              = "../../modules/azure/kubernetes-cluster"
  cluster_name        = "fawkes-aks"
  location            = "eastus2"
  resource_group_name = module.rg.name
  subnet_id           = module.network.subnet_id
  node_vm_size        = "Standard_B2ms"
  node_count          = 3
  tags                = {
    environment = "dev"
    platform    = "fawkes"
  }
}
```

## Requirements

| Name      | Version    |
| --------- | ---------- |
| terraform | >= 1.6.0   |
| azurerm   | >= 3.110.0 |

## Inputs

| Name                            | Description                                     | Type           | Default           | Required |
| ------------------------------- | ----------------------------------------------- | -------------- | ----------------- | -------- |
| cluster_name                    | Name of the AKS cluster                         | `string`       | n/a               | yes      |
| location                        | Azure region for the AKS cluster                | `string`       | n/a               | yes      |
| resource_group_name             | Name of the resource group                      | `string`       | n/a               | yes      |
| subnet_id                       | ID of the subnet for AKS nodes                  | `string`       | n/a               | yes      |
| dns_prefix                      | DNS prefix for the AKS cluster                  | `string`       | `null`            | no       |
| node_vm_size                    | VM size for the default node pool               | `string`       | `"Standard_B2ms"` | no       |
| node_count                      | Number of nodes in the default node pool        | `number`       | `3`               | no       |
| only_critical_addons_enabled    | Enable only critical addons in system node pool | `bool`         | `true`            | no       |
| max_surge                       | Maximum surge during node pool upgrades         | `string`       | `"33%"`           | no       |
| enable_managed_identity         | Enable SystemAssigned managed identity          | `bool`         | `true`            | no       |
| enable_rbac                     | Enable Kubernetes RBAC                          | `bool`         | `true`            | no       |
| network_plugin                  | Network plugin for AKS                          | `string`       | `"azure"`         | no       |
| service_cidr                    | Service CIDR for Kubernetes services            | `string`       | `"10.1.0.0/16"`   | no       |
| dns_service_ip                  | DNS service IP                                  | `string`       | `"10.1.0.10"`     | no       |
| load_balancer_sku               | SKU for the load balancer                       | `string`       | `"standard"`      | no       |
| outbound_type                   | Outbound routing type                           | `string`       | `"loadBalancer"`  | no       |
| api_server_authorized_ip_ranges | Authorized IP ranges for API server (no default - required; 0.0.0.0/0 rejected) | `list(string)` | n/a | yes |
| tags                            | Tags to apply to the AKS cluster                | `map(string)`  | `{}`              | no       |

## Outputs

| Name                  | Description                                |
| --------------------- | ------------------------------------------ |
| cluster_id            | The ID of the AKS cluster                  |
| cluster_name          | The name of the AKS cluster                |
| cluster_fqdn          | The FQDN of the AKS cluster                |
| kube_config           | Kubernetes configuration (sensitive)       |
| kube_admin_config     | Kubernetes admin configuration (sensitive) |
| node_resource_group   | The node resource group created by AKS     |
| identity_principal_id | The Principal ID of the Managed Identity   |
| identity_tenant_id    | The Tenant ID of the Managed Identity      |

## Validation Rules

- Cluster name must be between 1 and 63 characters
- Cluster name must start and end with alphanumeric
- Node VM size must be a valid Azure VM SKU
- Node count must be between 1 and 1000
- Max surge must be a number or percentage
- Network plugin must be 'azure' or 'kubenet'
- Service CIDR must be a valid CIDR block
- DNS service IP must be a valid IP address
- Load balancer SKU must be 'basic' or 'standard'
- Outbound type must be 'loadBalancer' or 'userDefinedRouting'
- All authorized IP ranges must be valid CIDR blocks

## Migrating from Old Module

If you're using the old `azure-aks-cluster` module:

```hcl
# Old
module "aks" {
  source = "../../modules/azure-aks-cluster"
  # ...
}

# New
module "aks" {
  source = "../../modules/azure/kubernetes-cluster"
  # ...
}
```

The interface is identical - only the source path changes.

<!-- prettier-ignore-start -->
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement_terraform) | >= 1.6.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement_azurerm) | >= 3.110.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_azurerm"></a> [azurerm](#provider_azurerm) | 5.0.1 |

## Resources

| Name | Type |
| ---- | ---- |
| [azurerm_kubernetes_cluster.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/kubernetes_cluster) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_api_server_authorized_ip_ranges"></a> [api_server_authorized_ip_ranges](#input_api_server_authorized_ip_ranges) | Authorized IP ranges for AKS API server access. NO DEFAULT - each caller must explicitly decide. Provide the CIDRs that may reach the API server; use [] ONLY for a fully private cluster (the api_server_access_profile block is omitted). 0.0.0.0/0 is rejected; public open access is not allowed | `list(string)` | n/a | yes |
| <a name="input_cluster_name"></a> [cluster_name](#input_cluster_name) | Name of the AKS cluster | `string` | n/a | yes |
| <a name="input_location"></a> [location](#input_location) | Azure region for the AKS cluster | `string` | n/a | yes |
| <a name="input_resource_group_name"></a> [resource_group_name](#input_resource_group_name) | Name of the resource group | `string` | n/a | yes |
| <a name="input_subnet_id"></a> [subnet_id](#input_subnet_id) | ID of the subnet for AKS nodes | `string` | n/a | yes |
| <a name="input_dns_prefix"></a> [dns_prefix](#input_dns_prefix) | DNS prefix for the AKS cluster (defaults to cluster_name-dns if not set) | `string` | `null` | no |
| <a name="input_dns_service_ip"></a> [dns_service_ip](#input_dns_service_ip) | DNS service IP (must be within service_cidr) | `string` | `"10.1.0.10"` | no |
| <a name="input_enable_managed_identity"></a> [enable_managed_identity](#input_enable_managed_identity) | Enable SystemAssigned managed identity for the cluster | `bool` | `true` | no |
| <a name="input_enable_rbac"></a> [enable_rbac](#input_enable_rbac) | Enable Kubernetes RBAC | `bool` | `true` | no |
| <a name="input_load_balancer_sku"></a> [load_balancer_sku](#input_load_balancer_sku) | SKU for the load balancer | `string` | `"standard"` | no |
| <a name="input_max_surge"></a> [max_surge](#input_max_surge) | Maximum surge during node pool upgrades | `string` | `"33%"` | no |
| <a name="input_network_plugin"></a> [network_plugin](#input_network_plugin) | Network plugin for AKS (azure or kubenet) | `string` | `"azure"` | no |
| <a name="input_network_policy"></a> [network_policy](#input_network_policy) | Network policy to use (azure or calico) | `string` | `"azure"` | no |
| <a name="input_node_count"></a> [node_count](#input_node_count) | Number of nodes in the default node pool | `number` | `3` | no |
| <a name="input_node_vm_size"></a> [node_vm_size](#input_node_vm_size) | VM size for the default node pool | `string` | `"Standard_B2ms"` | no |
| <a name="input_only_critical_addons_enabled"></a> [only_critical_addons_enabled](#input_only_critical_addons_enabled) | Enable only critical addons in the system node pool | `bool` | `true` | no |
| <a name="input_outbound_type"></a> [outbound_type](#input_outbound_type) | Outbound routing type | `string` | `"loadBalancer"` | no |
| <a name="input_service_cidr"></a> [service_cidr](#input_service_cidr) | Service CIDR for Kubernetes services | `string` | `"10.1.0.0/16"` | no |
| <a name="input_tags"></a> [tags](#input_tags) | Tags to apply to the AKS cluster | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_cluster_fqdn"></a> [cluster_fqdn](#output_cluster_fqdn) | The FQDN of the AKS cluster |
| <a name="output_cluster_id"></a> [cluster_id](#output_cluster_id) | The ID of the AKS cluster |
| <a name="output_cluster_name"></a> [cluster_name](#output_cluster_name) | The name of the AKS cluster |
| <a name="output_identity_principal_id"></a> [identity_principal_id](#output_identity_principal_id) | The Principal ID of the System Assigned Managed Identity |
| <a name="output_identity_tenant_id"></a> [identity_tenant_id](#output_identity_tenant_id) | The Tenant ID of the System Assigned Managed Identity |
| <a name="output_kube_admin_config"></a> [kube_admin_config](#output_kube_admin_config) | Kubernetes admin configuration for the cluster |
| <a name="output_kube_config"></a> [kube_config](#output_kube_config) | Kubernetes configuration for the cluster |
| <a name="output_node_resource_group"></a> [node_resource_group](#output_node_resource_group) | The node resource group created by AKS |
<!-- END_TF_DOCS -->
<!-- prettier-ignore-end -->
