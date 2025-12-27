# Azure AKS Cluster Module

This module creates an Azure Kubernetes Service (AKS) cluster with proper configuration and validation.

## Features

- Creates an AKS cluster with system node pool
- Configurable VM size and node count
- Network plugin configuration (Azure CNI or Kubenet)
- API server access control with authorized IP ranges
- SystemAssigned managed identity
- Kubernetes RBAC enabled by default
- Comprehensive validation of all inputs

## Usage

```hcl
module "aks_cluster" {
  source = "../../modules/azure-aks-cluster"

  cluster_name        = "fawkes-aks"
  location            = "eastus2"
  resource_group_name = "fawkes-rg"
  subnet_id           = module.network.subnet_id
  
  node_vm_size = "Standard_B2ms"
  node_count   = 3
  
  network_plugin = "azure"
  service_cidr   = "10.0.0.0/16"
  dns_service_ip = "10.0.0.10"
  
  api_server_authorized_ip_ranges = ["203.0.113.0/24"]
  
  tags = {
    platform   = "fawkes"
    managed_by = "terraform"
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
|------|-------------|------|---------|:--------:|
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
| network_plugin | Network plugin (azure or kubenet) | `string` | `"azure"` | no |
| service_cidr | Service CIDR for Kubernetes services | `string` | `"10.0.0.0/16"` | no |
| dns_service_ip | DNS service IP | `string` | `"10.0.0.10"` | no |
| load_balancer_sku | SKU for the load balancer | `string` | `"standard"` | no |
| outbound_type | Outbound routing type | `string` | `"loadBalancer"` | no |
| api_server_authorized_ip_ranges | Authorized IP ranges for API server | `list(string)` | `[]` | no |
| tags | Tags to apply to the cluster | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| cluster_id | The ID of the AKS cluster |
| cluster_name | The name of the AKS cluster |
| cluster_fqdn | The FQDN of the AKS cluster |
| kube_config | Kubernetes configuration (sensitive) |
| kube_admin_config | Kubernetes admin configuration (sensitive) |
| node_resource_group | The node resource group created by AKS |
| identity_principal_id | Principal ID of managed identity |
| identity_tenant_id | Tenant ID of managed identity |

## Validation Rules

- Cluster name: 1-63 characters, alphanumerics and hyphens only
- Node count: 1-1000 nodes
- VM size must be valid Azure SKU
- Network plugin must be 'azure' or 'kubenet'
- All CIDR blocks must be valid IPv4 notation
- Load balancer SKU must be 'basic' or 'standard'
- Outbound type must be 'loadBalancer' or 'userDefinedRouting'
