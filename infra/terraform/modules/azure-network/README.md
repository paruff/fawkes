# Azure Network Module

This module creates an Azure Virtual Network with a subnet for AKS or other workloads.

## Features

- Creates a virtual network with configurable address space
- Creates a subnet with proper CIDR validation
- Validates network naming conventions
- Supports custom tagging

## Usage

```hcl
module "network" {
  source = "../../modules/azure-network"

  vnet_name           = "fawkes-vnet"
  location            = "eastus2"
  resource_group_name = "fawkes-rg"
  address_space       = ["10.0.0.0/16"]
  
  subnet_name             = "aks-subnet"
  subnet_address_prefixes = ["10.0.1.0/24"]
  
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
| vnet_name | Name of the virtual network | `string` | n/a | yes |
| location | Azure region for the virtual network | `string` | n/a | yes |
| resource_group_name | Name of the resource group | `string` | n/a | yes |
| address_space | Address space for the virtual network (CIDR notation) | `list(string)` | n/a | yes |
| subnet_name | Name of the subnet | `string` | n/a | yes |
| subnet_address_prefixes | Address prefixes for the subnet (CIDR notation) | `list(string)` | n/a | yes |
| tags | Tags to apply to network resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| vnet_id | The ID of the virtual network |
| vnet_name | The name of the virtual network |
| vnet_address_space | The address space of the virtual network |
| subnet_id | The ID of the subnet |
| subnet_name | The name of the subnet |
| subnet_address_prefixes | The address prefixes of the subnet |

## Validation Rules

- VNet name must be between 2 and 64 characters
- VNet name must start with alphanumeric and end with alphanumeric or underscore
- Subnet name must be between 1 and 80 characters
- All CIDR blocks must be valid IPv4 CIDR notation
- At least one address space and subnet prefix must be specified
