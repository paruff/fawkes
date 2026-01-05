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
| dns_prefix | DNS prefix for the AKS cluster | `string` | `null` | no |
| node_vm_size | VM size for the default node pool | `string` | `"Standard_B2ms"` | no |
| node_count | Number of nodes in the default node pool | `number` | `3` | no |
| only_critical_addons_enabled | Enable only critical addons in system node pool | `bool` | `true` | no |
| max_surge | Maximum surge during node pool upgrades | `string` | `"33%"` | no |
| enable_managed_identity | Enable SystemAssigned managed identity | `bool` | `true` | no |
| enable_rbac | Enable Kubernetes RBAC | `bool` | `true` | no |
| network_plugin | Network plugin for AKS | `string` | `"azure"` | no |
| service_cidr | Service CIDR for Kubernetes services | `string` | `"10.1.0.0/16"` | no |
| dns_service_ip | DNS service IP | `string` | `"10.1.0.10"` | no |
| load_balancer_sku | SKU for the load balancer | `string` | `"standard"` | no |
| outbound_type | Outbound routing type | `string` | `"loadBalancer"` | no |
| api_server_authorized_ip_ranges | Authorized IP ranges for API server | `list(string)` | `[]` | no |
| tags | Tags to apply to the AKS cluster | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| cluster_id | The ID of the AKS cluster |
| cluster_name | The name of the AKS cluster |
| cluster_fqdn | The FQDN of the AKS cluster |
| kube_config | Kubernetes configuration (sensitive) |
| kube_admin_config | Kubernetes admin configuration (sensitive) |
| node_resource_group | The node resource group created by AKS |
| identity_principal_id | The Principal ID of the Managed Identity |
| identity_tenant_id | The Tenant ID of the Managed Identity |

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
