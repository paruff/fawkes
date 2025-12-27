# Azure Resource Group Module

This module creates an Azure Resource Group with proper validation and tagging.

## Features

- Creates a resource group in any Azure region
- Validates resource group name and location
- Supports custom tagging
- Follows Azure naming conventions

## Usage

```hcl
module "resource_group" {
  source = "../../modules/azure-resource-group"

  name     = "fawkes-rg"
  location = "eastus2"
  
  tags = {
    platform   = "fawkes"
    managed_by = "terraform"
    environment = "dev"
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
| name | Name of the resource group | `string` | n/a | yes |
| location | Azure region for the resource group | `string` | n/a | yes |
| tags | Tags to apply to the resource group | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| id | The ID of the resource group |
| name | The name of the resource group |
| location | The location of the resource group |
| tags | The tags applied to the resource group |

## Validation Rules

- Resource group name must be between 1 and 90 characters
- Name can only contain alphanumerics, periods, underscores, hyphens and parenthesis
- Location must be a valid Azure region
