# Azure Storage Account Module

Manages an Azure Storage Account with configurable security, blob properties, lifecycle management, network rules, containers, and monitoring.

## Usage

```hcl
module "storage" {
  source               = "../../modules/azure/storage"
  storage_account_name = "fawkesdevstore"
  location             = "eastus2"
  resource_group_name  = module.rg.name

  account_tier       = "Standard"
  replication_type   = "GRS"

  enable_versioning  = true
  enable_https_traffic_only = true

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
| storage_account_name | Name of the storage account | `string` | n/a | yes |
| location | Azure region for the storage account | `string` | n/a | yes |
| resource_group_name | Name of the resource group | `string` | n/a | yes |
| account_tier | Tier (Standard or Premium) | `string` | `"Standard"` | no |
| replication_type | Replication type | `string` | `"GRS"` | no |
| account_kind | Kind of storage account | `string` | `"StorageV2"` | no |
| access_tier | Access tier (Hot or Cool) | `string` | `"Hot"` | no |
| enable_https_traffic_only | Require HTTPS for all traffic | `bool` | `true` | no |
| min_tls_version | Minimum TLS version | `string` | `"TLS1_2"` | no |
| allow_nested_items_to_be_public | Allow public blob access | `bool` | `false` | no |
| shared_access_key_enabled | Enable shared access key auth | `bool` | `true` | no |
| enable_versioning | Enable blob versioning | `bool` | `true` | no |
| enable_change_feed | Enable blob change feed | `bool` | `false` | no |
| change_feed_retention_days | Change feed retention days | `number` | `7` | no |
| enable_last_access_time_tracking | Enable last access time tracking | `bool` | `true` | no |
| blob_soft_delete_retention_days | Blob soft delete retention (0 to disable) | `number` | `7` | no |
| container_soft_delete_retention_days | Container soft delete retention | `number` | `7` | no |
| cors_rules | CORS rules for blob service | `list(object)` | `[]` | no |
| enable_network_rules | Enable network rules | `bool` | `false` | no |
| default_network_action | Default network action (Allow or Deny) | `string` | `"Deny"` | no |
| network_bypass | Bypass for Azure services | `list(string)` | `["AzureServices"]` | no |
| allowed_ip_addresses | Allowed IP addresses or CIDRs | `list(string)` | `[]` | no |
| allowed_subnet_ids | Allowed subnet IDs | `list(string)` | `[]` | no |
| containers | Blob containers to create | `map(object)` | `{}` | no |
| lifecycle_rules | Lifecycle management rules | `list(object)` | `[]` | no |
| enable_managed_identity | Enable system-assigned managed identity | `bool` | `false` | no |
| enable_private_endpoint | Enable private endpoint | `bool` | `false` | no |
| private_endpoint_subnet_id | Subnet ID for private endpoint | `string` | `null` | no |
| enable_diagnostic_settings | Enable diagnostic settings | `bool` | `true` | no |
| log_analytics_workspace_id | Log Analytics workspace ID | `string` | `null` | no |
| enable_alerts | Enable metric alerts | `bool` | `true` | no |
| action_group_id | Action group ID for alerts | `string` | `null` | no |
| capacity_alert_threshold_bytes | Capacity alert threshold | `number` | `107374182400` | no |
| availability_alert_threshold_percent | Availability alert threshold | `number` | `99.0` | no |
| tags | Tags to apply to resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| storage_account_id | The ID of the storage account |
| storage_account_name | The name of the storage account |
| primary_blob_endpoint | Primary blob endpoint |
| primary_blob_host | Primary blob host |
| secondary_blob_endpoint | Secondary blob endpoint |
| primary_connection_string | Primary connection string (sensitive) |
| secondary_connection_string | Secondary connection string (sensitive) |
| primary_access_key | Primary access key (sensitive) |
| secondary_access_key | Secondary access key (sensitive) |
| identity_principal_id | Principal ID of the managed identity |
| identity_tenant_id | Tenant ID of the managed identity |
| container_ids | Map of container names to IDs |
| container_names | List of created container names |
| private_endpoint_id | ID of the private endpoint |
| private_endpoint_ip | Private IP of the private endpoint |
| primary_location | Primary location |
| secondary_location | Secondary location |

## Validation Rules

- Storage account name must be 3–24 characters, lowercase alphanumeric only
- Account tier must be `Standard` or `Premium`
- Replication type must be one of: `LRS`, `GRS`, `RAGRS`, `ZRS`, `GZRS`, `RAGZRS`
- Account kind must be one of: `BlobStorage`, `BlockBlobStorage`, `FileStorage`, `Storage`, `StorageV2`
- Access tier must be `Hot` or `Cool`
- TLS version must be `TLS1_0`, `TLS1_1`, or `TLS1_2`
- Change feed retention must be 1–146000 days
- Blob soft delete retention must be 0–365 days
- Container soft delete retention must be 0–365 days
- CORS max_age_in_seconds must be 0–2147483647
- Default network action must be `Allow` or `Deny`
- Network bypass values must be `None`, `AzureServices`, `Logging`, or `Metrics`
- Capacity alert threshold must be greater than 0
- Availability alert threshold must be 0–100
