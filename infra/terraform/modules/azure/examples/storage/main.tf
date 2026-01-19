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

provider "azurerm" {
  features {}
}

# Resource Group
resource "azurerm_resource_group" "example" {
  name     = "example-storage-rg"
  location = "East US"
}

# Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "example" {
  name                = "example-storage-logs"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

# Action Group for Alerts
resource "azurerm_monitor_action_group" "example" {
  name                = "example-storage-action-group"
  resource_group_name = azurerm_resource_group.example.name
  short_name          = "storAlerts"

  email_receiver {
    name          = "admin"
    email_address = "admin@example.com"
  }
}

# Storage Account
module "storage" {
  source = "../../storage"

  storage_account_name = "examplestorageacct123"
  location             = azurerm_resource_group.example.location
  resource_group_name  = azurerm_resource_group.example.name

  # Performance and Redundancy
  account_tier    = "Standard"
  replication_type = "GRS"
  account_kind    = "StorageV2"
  access_tier     = "Hot"

  # Security
  enable_https_traffic_only       = true
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
  shared_access_key_enabled       = true

  # Blob Properties
  enable_versioning                   = true
  enable_change_feed                  = true
  change_feed_retention_days          = 7
  enable_last_access_time_tracking    = true
  blob_soft_delete_retention_days     = 7
  container_soft_delete_retention_days = 7

  # CORS (if needed for web applications)
  cors_rules = [
    {
      allowed_headers    = ["*"]
      allowed_methods    = ["GET", "HEAD", "POST", "OPTIONS", "PUT"]
      allowed_origins    = ["https://example.com"]
      exposed_headers    = ["*"]
      max_age_in_seconds = 3600
    }
  ]

  # Network Security
  enable_network_rules    = false # Set to true for production
  default_network_action  = "Deny"
  network_bypass          = ["AzureServices"]
  allowed_ip_addresses    = []
  allowed_subnet_ids      = []

  # Containers
  containers = {
    documents = {
      access_type = "private"
      metadata = {
        purpose = "document-storage"
      }
    }
    images = {
      access_type = "private"
      metadata = {
        purpose = "image-storage"
      }
    }
    backups = {
      access_type = "private"
      metadata = {
        purpose = "backup-storage"
      }
    }
  }

  # Lifecycle Management
  lifecycle_rules = [
    {
      name    = "move-to-cool-after-30-days"
      enabled = true
      prefix_match = ["documents/"]
      blob_types   = ["blockBlob"]
      base_blob = {
        tier_to_cool_after_days    = 30
        tier_to_archive_after_days = 90
        delete_after_days          = 365
      }
    },
    {
      name    = "delete-old-backups"
      enabled = true
      prefix_match = ["backups/"]
      blob_types   = ["blockBlob"]
      base_blob = {
        delete_after_days = 90
      }
    },
    {
      name    = "clean-snapshots"
      enabled = true
      blob_types = ["blockBlob"]
      snapshot = {
        delete_after_days = 30
      }
    }
  ]

  # Encryption
  enable_managed_identity = false

  # Private Endpoint
  enable_private_endpoint    = false # Set to true for production
  private_endpoint_subnet_id = null

  # Monitoring
  enable_diagnostic_settings = true
  log_analytics_workspace_id = azurerm_log_analytics_workspace.example.id

  enable_alerts                         = true
  action_group_id                       = azurerm_monitor_action_group.example.id
  capacity_alert_threshold_bytes        = 107374182400 # 100 GB
  availability_alert_threshold_percent  = 99.0

  tags = {
    Environment = "example"
    Purpose     = "storage-demo"
    ManagedBy   = "terraform"
  }
}
