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
  name     = "example-database-rg"
  location = "East US"
}

# Virtual Network for Private Endpoint
resource "azurerm_virtual_network" "example" {
  name                = "example-db-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
}

resource "azurerm_subnet" "example" {
  name                 = "db-subnet"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.1.0/24"]

  service_endpoints = ["Microsoft.Sql"]
}

# Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "example" {
  name                = "example-db-logs"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

# Action Group for Alerts
resource "azurerm_monitor_action_group" "example" {
  name                = "example-db-action-group"
  resource_group_name = azurerm_resource_group.example.name
  short_name          = "dbAlerts"

  email_receiver {
    name          = "admin"
    email_address = "admin@example.com"
  }
}

# PostgreSQL Database
module "postgresql" {
  source = "../../database"

  server_name         = "example-postgresql-server"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  engine         = "postgresql"
  engine_version = "15"
  sku_name       = "GP_Standard_D2s_v3"

  admin_username = "pgadmin"
  # admin_password will be auto-generated

  # Storage
  storage_mb              = 65536 # 64 GB
  storage_auto_grow_enabled = true

  # Backup
  backup_retention_days        = 14
  geo_redundant_backup_enabled = true

  # High Availability
  high_availability_mode    = "ZoneRedundant"
  standby_availability_zone = "2"
  zone                      = "1"

  # Database
  create_database = true
  database_name   = "app_db"

  # Network Security
  firewall_rules = [
    {
      name             = "allow-office"
      start_ip_address = "203.0.113.0"
      end_ip_address   = "203.0.113.255"
    }
  ]

  enable_private_endpoint     = false # Set to true for production
  private_endpoint_subnet_id  = azurerm_subnet.example.id

  # Monitoring
  enable_diagnostic_settings  = true
  log_analytics_workspace_id  = azurerm_log_analytics_workspace.example.id
  
  enable_alerts       = true
  action_group_id     = azurerm_monitor_action_group.example.id
  cpu_alert_threshold = 80
  storage_alert_threshold = 85
  memory_alert_threshold = 85

  tags = {
    Environment = "example"
    Purpose     = "database-demo"
    ManagedBy   = "terraform"
  }
}

# MySQL Database
module "mysql" {
  source = "../../database"

  server_name         = "example-mysql-server"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  engine         = "mysql"
  engine_version = "8.0.21"
  sku_name       = "GP_Standard_D2s_v3"

  admin_username = "mysqladmin"
  # admin_password will be auto-generated

  # Storage
  storage_mb              = 65536 # 64 GB
  storage_auto_grow_enabled = true

  # Backup
  backup_retention_days        = 7
  geo_redundant_backup_enabled = false

  # Database
  create_database = true
  database_name   = "app_db"

  # Network Security
  firewall_rules = [
    {
      name             = "allow-office"
      start_ip_address = "203.0.113.0"
      end_ip_address   = "203.0.113.255"
    }
  ]

  # Monitoring
  enable_diagnostic_settings  = true
  log_analytics_workspace_id  = azurerm_log_analytics_workspace.example.id
  
  enable_alerts   = true
  action_group_id = azurerm_monitor_action_group.example.id

  tags = {
    Environment = "example"
    Purpose     = "database-demo"
    ManagedBy   = "terraform"
  }
}
