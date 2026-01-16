# Copyright (c) 2025  Philip Ruff
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
# DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
# OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE
# OR OTHER DEALINGS IN THE SOFTWARE.

# Azure Storage Account module variables

variable "storage_account_name" {
  description = "Name of the storage account"
  type        = string

  validation {
    condition     = length(var.storage_account_name) >= 3 && length(var.storage_account_name) <= 24
    error_message = "Storage account name must be between 3 and 24 characters."
  }

  validation {
    condition     = can(regex("^[a-z0-9]+$", var.storage_account_name))
    error_message = "Storage account name must contain only lowercase alphanumeric characters."
  }
}

variable "location" {
  description = "Azure region for the storage account"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "account_tier" {
  description = "Tier of the storage account (Standard or Premium)"
  type        = string
  default     = "Standard"

  validation {
    condition     = contains(["Standard", "Premium"], var.account_tier)
    error_message = "Account tier must be either Standard or Premium."
  }
}

variable "replication_type" {
  description = "Replication type for the storage account"
  type        = string
  default     = "GRS"

  validation {
    condition     = contains(["LRS", "GRS", "RAGRS", "ZRS", "GZRS", "RAGZRS"], var.replication_type)
    error_message = "Replication type must be one of: LRS, GRS, RAGRS, ZRS, GZRS, RAGZRS."
  }
}

variable "account_kind" {
  description = "Kind of storage account"
  type        = string
  default     = "StorageV2"

  validation {
    condition     = contains(["BlobStorage", "BlockBlobStorage", "FileStorage", "Storage", "StorageV2"], var.account_kind)
    error_message = "Account kind must be one of: BlobStorage, BlockBlobStorage, FileStorage, Storage, StorageV2."
  }
}

variable "access_tier" {
  description = "Access tier for the storage account (Hot or Cool)"
  type        = string
  default     = "Hot"

  validation {
    condition     = contains(["Hot", "Cool"], var.access_tier)
    error_message = "Access tier must be either Hot or Cool."
  }
}

# Security
variable "enable_https_traffic_only" {
  description = "Require HTTPS for all traffic"
  type        = bool
  default     = true
}

variable "min_tls_version" {
  description = "Minimum TLS version"
  type        = string
  default     = "TLS1_2"

  validation {
    condition     = contains(["TLS1_0", "TLS1_1", "TLS1_2"], var.min_tls_version)
    error_message = "TLS version must be one of: TLS1_0, TLS1_1, TLS1_2."
  }
}

variable "allow_nested_items_to_be_public" {
  description = "Allow nested items (blobs and containers) to be public"
  type        = bool
  default     = false
}

variable "shared_access_key_enabled" {
  description = "Enable shared access key authentication"
  type        = bool
  default     = true
}

# Blob Properties
variable "enable_versioning" {
  description = "Enable blob versioning"
  type        = bool
  default     = true
}

variable "enable_change_feed" {
  description = "Enable blob change feed"
  type        = bool
  default     = false
}

variable "change_feed_retention_days" {
  description = "Retention period for change feed in days"
  type        = number
  default     = 7

  validation {
    condition     = var.change_feed_retention_days >= 1 && var.change_feed_retention_days <= 146000
    error_message = "Change feed retention must be between 1 and 146000 days."
  }
}

variable "enable_last_access_time_tracking" {
  description = "Enable last access time tracking for lifecycle management"
  type        = bool
  default     = true
}

variable "blob_soft_delete_retention_days" {
  description = "Number of days to retain deleted blobs (0 to disable)"
  type        = number
  default     = 7

  validation {
    condition     = var.blob_soft_delete_retention_days >= 0 && var.blob_soft_delete_retention_days <= 365
    error_message = "Blob soft delete retention must be between 0 and 365 days."
  }
}

variable "container_soft_delete_retention_days" {
  description = "Number of days to retain deleted containers (0 to disable)"
  type        = number
  default     = 7

  validation {
    condition     = var.container_soft_delete_retention_days >= 0 && var.container_soft_delete_retention_days <= 365
    error_message = "Container soft delete retention must be between 0 and 365 days."
  }
}

# CORS
variable "cors_rules" {
  description = "CORS rules for blob service"
  type = list(object({
    allowed_headers    = list(string)
    allowed_methods    = list(string)
    allowed_origins    = list(string)
    exposed_headers    = list(string)
    max_age_in_seconds = number
  }))
  default = []

  validation {
    condition = alltrue([
      for rule in var.cors_rules :
      rule.max_age_in_seconds >= 0 && rule.max_age_in_seconds <= 2147483647
    ])
    error_message = "CORS max_age_in_seconds must be between 0 and 2147483647."
  }
}

# Network Security
variable "enable_network_rules" {
  description = "Enable network rules for storage account"
  type        = bool
  default     = false
}

variable "default_network_action" {
  description = "Default action for network rules (Allow or Deny)"
  type        = string
  default     = "Deny"

  validation {
    condition     = contains(["Allow", "Deny"], var.default_network_action)
    error_message = "Default network action must be either Allow or Deny."
  }
}

variable "network_bypass" {
  description = "Bypass network rules for Azure services"
  type        = list(string)
  default     = ["AzureServices"]

  validation {
    condition = alltrue([
      for bypass in var.network_bypass :
      contains(["None", "AzureServices", "Logging", "Metrics"], bypass)
    ])
    error_message = "Network bypass must be one of: None, AzureServices, Logging, Metrics."
  }
}

variable "allowed_ip_addresses" {
  description = "List of allowed IP addresses or CIDR blocks"
  type        = list(string)
  default     = []
}

variable "allowed_subnet_ids" {
  description = "List of allowed subnet IDs"
  type        = list(string)
  default     = []
}

# Containers
variable "containers" {
  description = "Map of blob containers to create"
  type = map(object({
    access_type = optional(string, "private")
    metadata    = optional(map(string), {})
  }))
  default = {}
}

# Lifecycle Management
variable "lifecycle_rules" {
  description = "List of lifecycle management rules"
  type = list(object({
    name         = string
    enabled      = bool
    prefix_match = optional(list(string), [])
    blob_types   = optional(list(string), ["blockBlob"])
    base_blob = optional(object({
      tier_to_cool_after_days                        = optional(number)
      tier_to_archive_after_days                     = optional(number)
      delete_after_days                              = optional(number)
      tier_to_cool_after_days_since_last_access      = optional(number)
      tier_to_archive_after_days_since_last_access   = optional(number)
      delete_after_days_since_last_access            = optional(number)
    }))
    snapshot = optional(object({
      tier_to_cool_after_days    = optional(number)
      tier_to_archive_after_days = optional(number)
      delete_after_days          = optional(number)
    }))
    version = optional(object({
      tier_to_cool_after_days    = optional(number)
      tier_to_archive_after_days = optional(number)
      delete_after_days          = optional(number)
    }))
  }))
  default = []
}

# Encryption
variable "enable_managed_identity" {
  description = "Enable system-assigned managed identity"
  type        = bool
  default     = false
}

variable "customer_managed_key_vault_key_id" {
  description = "Key Vault key ID for customer-managed encryption keys"
  type        = string
  default     = null
}

variable "customer_managed_key_user_assigned_identity_id" {
  description = "User-assigned identity ID for customer-managed keys"
  type        = string
  default     = null
}

# Private Endpoint
variable "enable_private_endpoint" {
  description = "Enable private endpoint for blob storage"
  type        = bool
  default     = false
}

variable "private_endpoint_subnet_id" {
  description = "Subnet ID for private endpoint"
  type        = string
  default     = null
}

# Monitoring and Alerting
variable "enable_diagnostic_settings" {
  description = "Enable diagnostic settings"
  type        = bool
  default     = true
}

variable "log_analytics_workspace_id" {
  description = "ID of Log Analytics workspace for diagnostics"
  type        = string
  default     = null
}

variable "enable_alerts" {
  description = "Enable metric alerts"
  type        = bool
  default     = true
}

variable "action_group_id" {
  description = "ID of the action group for alerts"
  type        = string
  default     = null
}

variable "capacity_alert_threshold_bytes" {
  description = "Storage capacity threshold for alerts in bytes"
  type        = number
  default     = 107374182400 # 100 GB

  validation {
    condition     = var.capacity_alert_threshold_bytes > 0
    error_message = "Capacity alert threshold must be greater than 0."
  }
}

variable "availability_alert_threshold_percent" {
  description = "Availability threshold for alerts (percentage)"
  type        = number
  default     = 99.0

  validation {
    condition     = var.availability_alert_threshold_percent >= 0 && var.availability_alert_threshold_percent <= 100
    error_message = "Availability alert threshold must be between 0 and 100."
  }
}

# Tags
variable "tags" {
  description = "Tags to apply to storage resources"
  type        = map(string)
  default     = {}
}
