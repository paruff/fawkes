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

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.110.0"
    }
  }
}

# Storage Account
resource "azurerm_storage_account" "main" {
  name                     = var.storage_account_name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = var.account_tier
  account_replication_type = var.replication_type
  account_kind             = var.account_kind
  access_tier              = var.access_tier

  # Security
  enable_https_traffic_only       = var.enable_https_traffic_only
  min_tls_version                 = var.min_tls_version
  allow_nested_items_to_be_public = var.allow_nested_items_to_be_public
  shared_access_key_enabled       = var.shared_access_key_enabled

  # Blob properties
  blob_properties {
    # Versioning
    versioning_enabled = var.enable_versioning

    # Change feed
    change_feed_enabled           = var.enable_change_feed
    change_feed_retention_in_days = var.enable_change_feed ? var.change_feed_retention_days : null

    # Last access time tracking
    last_access_time_enabled = var.enable_last_access_time_tracking

    # Soft delete
    dynamic "delete_retention_policy" {
      for_each = var.blob_soft_delete_retention_days > 0 ? [1] : []
      content {
        days = var.blob_soft_delete_retention_days
      }
    }

    dynamic "container_delete_retention_policy" {
      for_each = var.container_soft_delete_retention_days > 0 ? [1] : []
      content {
        days = var.container_soft_delete_retention_days
      }
    }

    # CORS rules
    dynamic "cors_rule" {
      for_each = var.cors_rules
      content {
        allowed_headers    = cors_rule.value.allowed_headers
        allowed_methods    = cors_rule.value.allowed_methods
        allowed_origins    = cors_rule.value.allowed_origins
        exposed_headers    = cors_rule.value.exposed_headers
        max_age_in_seconds = cors_rule.value.max_age_in_seconds
      }
    }
  }

  # Network rules
  dynamic "network_rules" {
    for_each = var.enable_network_rules ? [1] : []
    content {
      default_action             = var.default_network_action
      bypass                     = var.network_bypass
      ip_rules                   = var.allowed_ip_addresses
      virtual_network_subnet_ids = var.allowed_subnet_ids
    }
  }

  # Identity (for encryption with customer-managed keys)
  dynamic "identity" {
    for_each = var.enable_managed_identity ? [1] : []
    content {
      type = "SystemAssigned"
    }
  }

  # Encryption
  dynamic "customer_managed_key" {
    for_each = var.customer_managed_key_vault_key_id != null ? [1] : []
    content {
      key_vault_key_id          = var.customer_managed_key_vault_key_id
      user_assigned_identity_id = var.customer_managed_key_user_assigned_identity_id
    }
  }

  tags = merge(
    var.tags,
    {
      Name = var.storage_account_name
      Cost = "storage"
    }
  )
}

# Blob Containers
resource "azurerm_storage_container" "main" {
  for_each              = var.containers
  name                  = each.key
  storage_account_name  = azurerm_storage_account.main.name
  container_access_type = lookup(each.value, "access_type", "private")

  metadata = lookup(each.value, "metadata", {})
}

# Management Policy for Lifecycle
resource "azurerm_storage_management_policy" "main" {
  count              = length(var.lifecycle_rules) > 0 ? 1 : 0
  storage_account_id = azurerm_storage_account.main.id

  dynamic "rule" {
    for_each = var.lifecycle_rules
    content {
      name    = rule.value.name
      enabled = rule.value.enabled

      filters {
        prefix_match = lookup(rule.value, "prefix_match", [])
        blob_types   = lookup(rule.value, "blob_types", ["blockBlob"])
      }

      actions {
        dynamic "base_blob" {
          for_each = lookup(rule.value, "base_blob", null) != null ? [rule.value.base_blob] : []
          content {
            tier_to_cool_after_days_since_modification_greater_than        = lookup(base_blob.value, "tier_to_cool_after_days", null)
            tier_to_archive_after_days_since_modification_greater_than     = lookup(base_blob.value, "tier_to_archive_after_days", null)
            delete_after_days_since_modification_greater_than              = lookup(base_blob.value, "delete_after_days", null)
            tier_to_cool_after_days_since_last_access_time_greater_than    = lookup(base_blob.value, "tier_to_cool_after_days_since_last_access", null)
            tier_to_archive_after_days_since_last_access_time_greater_than = lookup(base_blob.value, "tier_to_archive_after_days_since_last_access", null)
            delete_after_days_since_last_access_time_greater_than          = lookup(base_blob.value, "delete_after_days_since_last_access", null)
          }
        }

        dynamic "snapshot" {
          for_each = lookup(rule.value, "snapshot", null) != null ? [rule.value.snapshot] : []
          content {
            change_tier_to_archive_after_days_since_creation = lookup(snapshot.value, "tier_to_archive_after_days", null)
            change_tier_to_cool_after_days_since_creation    = lookup(snapshot.value, "tier_to_cool_after_days", null)
            delete_after_days_since_creation_greater_than    = lookup(snapshot.value, "delete_after_days", null)
          }
        }

        dynamic "version" {
          for_each = lookup(rule.value, "version", null) != null ? [rule.value.version] : []
          content {
            change_tier_to_archive_after_days_since_creation = lookup(version.value, "tier_to_archive_after_days", null)
            change_tier_to_cool_after_days_since_creation    = lookup(version.value, "tier_to_cool_after_days", null)
            delete_after_days_since_creation                 = lookup(version.value, "delete_after_days", null)
          }
        }
      }
    }
  }
}

# Private Endpoint for Blob Storage
resource "azurerm_private_endpoint" "blob" {
  count               = var.enable_private_endpoint ? 1 : 0
  name                = "${var.storage_account_name}-blob-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "${var.storage_account_name}-blob-psc"
    private_connection_resource_id = azurerm_storage_account.main.id
    is_manual_connection           = false
    subresource_names              = ["blob"]
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.storage_account_name}-blob-pe"
      Cost = "storage"
    }
  )
}

# Diagnostic Settings
resource "azurerm_monitor_diagnostic_setting" "blob" {
  count                      = var.enable_diagnostic_settings ? 1 : 0
  name                       = "${var.storage_account_name}-blob-diagnostics"
  target_resource_id         = "${azurerm_storage_account.main.id}/blobServices/default/"
  log_analytics_workspace_id = var.log_analytics_workspace_id

  dynamic "enabled_log" {
    for_each = ["StorageRead", "StorageWrite", "StorageDelete"]
    content {
      category = enabled_log.value
    }
  }

  dynamic "metric" {
    for_each = ["Transaction", "Capacity"]
    content {
      category = metric.value
      enabled  = true
    }
  }
}

# Metric Alerts
resource "azurerm_monitor_metric_alert" "capacity" {
  count               = var.enable_alerts ? 1 : 0
  name                = "${var.storage_account_name}-capacity-alert"
  resource_group_name = var.resource_group_name
  scopes              = [azurerm_storage_account.main.id]
  description         = "Alert when storage capacity is high"
  severity            = 2
  frequency           = "PT1H"
  window_size         = "PT6H"

  criteria {
    metric_namespace = "Microsoft.Storage/storageAccounts"
    metric_name      = "UsedCapacity"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = var.capacity_alert_threshold_bytes
  }

  action {
    action_group_id = var.action_group_id
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.storage_account_name}-capacity-alert"
      Cost = "monitoring"
    }
  )
}

resource "azurerm_monitor_metric_alert" "availability" {
  count               = var.enable_alerts ? 1 : 0
  name                = "${var.storage_account_name}-availability-alert"
  resource_group_name = var.resource_group_name
  scopes              = ["${azurerm_storage_account.main.id}/blobServices/default/"]
  description         = "Alert when blob storage availability is low"
  severity            = 1
  frequency           = "PT5M"
  window_size         = "PT15M"

  criteria {
    metric_namespace = "Microsoft.Storage/storageAccounts/blobServices"
    metric_name      = "Availability"
    aggregation      = "Average"
    operator         = "LessThan"
    threshold        = var.availability_alert_threshold_percent
  }

  action {
    action_group_id = var.action_group_id
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.storage_account_name}-availability-alert"
      Cost = "monitoring"
    }
  )
}
