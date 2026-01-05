# Azure Network Module

Manages an Azure Virtual Network with subnet, extending the base network module.

## Usage

```hcl
module "network" {
  source              = "../../modules/azure/network"
  vnet_name           = "fawkes-vnet"
  location            = "eastus2"
  resource_group_name = module.rg.name
  address_space       = ["10.0.0.0/16"]
  subnet_name         = "aks-subnet"
  subnet_address_prefixes = ["10.0.1.0/24"]
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
| vnet_name | Name of the virtual network | `string` | n/a | yes |
| location | Azure region for the virtual network | `string` | n/a | yes |
| resource_group_name | Name of the resource group | `string` | n/a | yes |
| address_space | Address space for the virtual network | `list(string)` | n/a | yes |
| subnet_name | Name of the subnet | `string` | n/a | yes |
| subnet_address_prefixes | Address prefixes for the subnet | `list(string)` | n/a | yes |
| tags | Tags to apply to network resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| vnet_id | The ID of the virtual network |
| vnet_name | The name of the virtual network |
| subnet_id | The ID of the subnet |
| subnet_name | The name of the subnet |
| address_space | The address space of the virtual network |
| subnet_address_prefixes | The address prefixes of the subnet |

## Validation Rules

- Virtual network name must be between 2 and 64 characters
- VNet name must start with alphanumeric, end with alphanumeric or underscore
- At least one address space must be specified
- All address spaces must be valid CIDR blocks
- Subnet name must be between 1 and 80 characters
- At least one subnet address prefix must be specified
- All subnet address prefixes must be valid CIDR blocks

## Migrating from Old Module

If you're using the old `azure-network` module:

```hcl
# Old
module "network" {
  source = "../../modules/azure-network"
  # ...
}

# New
module "network" {
  source = "../../modules/azure/network"
  # ...
}
```

The interface is identical - only the source path changes.
