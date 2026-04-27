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

locals {
  resource_group_name = var.resource_group_name != null ? var.resource_group_name : "${var.project_name}-tfstate-${var.environment}-rg"
  common_tags = merge(
    var.tags,
    {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
      Component   = "state-backend"
    }
  )
}

# Resource group for state backend resources
resource "azurerm_resource_group" "state" {
  name     = local.resource_group_name
  location = var.location

  tags = merge(local.common_tags, { Name = local.resource_group_name })
}

# Storage account for Terraform state
resource "azurerm_storage_account" "state" {
  name                = var.storage_account_name
  resource_group_name = azurerm_resource_group.state.name
  location            = azurerm_resource_group.state.location

  account_tier             = "Standard"
  account_replication_type = "GRS"
  account_kind             = "StorageV2"

  # Security
  https_traffic_only_enabled      = true
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
  shared_access_key_enabled       = true

  blob_properties {
    # Versioning for state recovery
    versioning_enabled = true

    # Change feed for auditing
    change_feed_enabled           = true
    change_feed_retention_in_days = 30

    # Soft delete for accidental deletion protection
    delete_retention_policy {
      days = var.soft_delete_retention_days
    }

    container_delete_retention_policy {
      days = var.soft_delete_retention_days
    }
  }

  # Network rules (optional restriction)
  # When allowed_ip_ranges or allowed_subnet_ids are provided, access is restricted to
  # those sources only. "AzureServices" bypass is included so that Azure management
  # plane operations (e.g., Azure Monitor, Azure Backup) can still reach the account.
  # If Terraform is the *only* consumer of this storage account, you may remove the
  # bypass and rely solely on IP/subnet rules plus the storage account key.
  dynamic "network_rules" {
    for_each = length(var.allowed_ip_ranges) > 0 || length(var.allowed_subnet_ids) > 0 ? [1] : []
    content {
      default_action             = "Deny"
      bypass                     = ["AzureServices"]
      ip_rules                   = var.allowed_ip_ranges
      virtual_network_subnet_ids = var.allowed_subnet_ids
    }
  }

  tags = merge(local.common_tags, { Name = var.storage_account_name })
}

# Storage container for state files — private access only
resource "azurerm_storage_container" "tfstate" {
  name                  = "tfstate"
  storage_account_name  = azurerm_storage_account.state.name
  container_access_type = "private"
}
