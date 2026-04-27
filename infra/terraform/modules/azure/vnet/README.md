# Azure Virtual Network (VNet) Module

Manages an Azure Virtual Network with configurable public and private subnets, NSG rules, NAT Gateway, and optional NSG Flow Logs with Traffic Analytics.

## Usage

```hcl
module "vnet" {
  source              = "../../modules/azure/vnet"
  vnet_name           = "fawkes-vnet"
  location            = "eastus2"
  resource_group_name = module.rg.name
  address_space       = ["10.0.0.0/16"]

  private_subnets = [
    {
      name             = "aks-subnet"
      address_prefixes = ["10.0.1.0/24"]
      service_endpoints = ["Microsoft.ContainerRegistry"]
    }
  ]

  public_subnets = [
    {
      name             = "ingress-subnet"
      address_prefixes = ["10.0.10.0/24"]
    }
  ]

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
| vnet_name | Name of the virtual network | `string` | n/a | yes |
| location | Azure region | `string` | n/a | yes |
| resource_group_name | Name of the resource group | `string` | n/a | yes |
| address_space | Address space CIDR blocks | `list(string)` | n/a | yes |
| dns_servers | DNS servers for the VNet | `list(string)` | `[]` | no |
| public_subnets | List of public subnets | `list(object)` | `[]` | no |
| private_subnets | List of private subnets | `list(object)` | `[]` | no |
| enable_nat_gateway | Enable NAT Gateway for private subnets | `bool` | `true` | no |
| nat_gateway_zones | Availability zones for NAT Gateway | `list(string)` | `["1"]` | no |
| nat_gateway_idle_timeout | NAT Gateway idle timeout in minutes | `number` | `4` | no |
| enable_flow_logs | Enable NSG Flow Logs | `bool` | `true` | no |
| network_watcher_name | Name of the Network Watcher | `string` | `null` | no |
| network_watcher_resource_group | Resource group of Network Watcher | `string` | `null` | no |
| flow_logs_storage_account_id | Storage account ID for flow logs | `string` | `null` | no |
| flow_logs_retention_days | Flow logs retention in days | `number` | `30` | no |
| enable_traffic_analytics | Enable Traffic Analytics | `bool` | `true` | no |
| log_analytics_workspace_id | Log Analytics workspace ID | `string` | `null` | no |
| log_analytics_workspace_resource_id | Log Analytics workspace resource ID | `string` | `null` | no |
| traffic_analytics_interval | Traffic Analytics interval in minutes | `number` | `10` | no |
| tags | Tags to apply to resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| vnet_id | The ID of the virtual network |
| vnet_name | The name of the virtual network |
| vnet_address_space | Address space of the VNet |
| vnet_guid | GUID of the VNet |
| public_subnet_ids | Map of public subnet names to IDs |
| public_subnet_names | List of public subnet names |
| public_subnet_address_prefixes | Map of public subnet names to address prefixes |
| private_subnet_ids | Map of private subnet names to IDs |
| private_subnet_names | List of private subnet names |
| private_subnet_address_prefixes | Map of private subnet names to address prefixes |
| public_nsg_ids | Map of public subnet names to NSG IDs |
| private_nsg_ids | Map of private subnet names to NSG IDs |
| nat_gateway_id | ID of the NAT Gateway |
| nat_gateway_public_ip | Public IP of the NAT Gateway |
| flow_logs_storage_account_id | ID of the storage account for flow logs |

## Validation Rules

- VNet name must be 2–64 characters, start with alphanumeric, end with alphanumeric or underscore, contain only alphanumerics, periods, hyphens, or underscores
- At least one address space must be specified; all must be valid CIDR blocks
- All DNS servers must be valid IP addresses
- All subnet address prefixes must be valid CIDR blocks
- NAT Gateway zones must be `1`, `2`, or `3`
- NAT Gateway idle timeout must be 4–120 minutes
- Flow logs retention must be 0–365 days
- Traffic Analytics interval must be `10` or `60` minutes
