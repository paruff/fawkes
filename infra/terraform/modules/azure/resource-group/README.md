# Azure Resource Group Module

Manages an Azure Resource Group, extending the base resource-group module.

## Usage

```hcl
module "rg" {
  source   = "../../modules/azure/resource-group"
  name     = "fawkes-rg"
  location = "eastus2"
  tags     = {
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
| name | Name of the resource group | `string` | n/a | yes |
| location | Azure region for the resource group | `string` | n/a | yes |
| tags | Tags to apply to the resource group | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| id | The ID of the resource group |
| name | The name of the resource group |
| location | The location of the resource group |

## Validation Rules

- Resource group name must be between 1 and 90 characters
- Name can only contain alphanumerics, periods, underscores, hyphens and parenthesis
- Location must be a valid Azure region

## Migrating from Old Module

If you're using the old `azure-resource-group` module:

```hcl
# Old
module "rg" {
  source   = "../../modules/azure-resource-group"
  name     = "fawkes-rg"
  location = "eastus2"
}

# New
module "rg" {
  source   = "../../modules/azure/resource-group"
  name     = "fawkes-rg"
  location = "eastus2"
}
```

The interface is identical - only the source path changes.
