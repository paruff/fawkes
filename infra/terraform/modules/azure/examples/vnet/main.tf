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
  name     = "example-vnet-rg"
  location = "East US"
}

# Log Analytics Workspace for Traffic Analytics
resource "azurerm_log_analytics_workspace" "example" {
  name                = "example-vnet-logs"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

# Virtual Network with Subnets and NSGs
module "vnet" {
  source = "../../vnet"

  vnet_name           = "example-vnet"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  address_space       = ["10.0.0.0/16"]

  dns_servers = []

  # Public Subnets
  public_subnets = [
    {
      name             = "public-subnet-1"
      address_prefixes = ["10.0.1.0/24"]
      service_endpoints = [
        "Microsoft.Storage",
        "Microsoft.KeyVault"
      ]
      nsg_rules = {
        allow_http = {
          priority                   = 100
          direction                  = "Inbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          source_port_range          = "*"
          destination_port_range     = "80"
          source_address_prefix      = "*"
          destination_address_prefix = "*"
        }
        allow_https = {
          priority                   = 110
          direction                  = "Inbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          source_port_range          = "*"
          destination_port_range     = "443"
          source_address_prefix      = "*"
          destination_address_prefix = "*"
        }
        allow_ssh = {
          priority                   = 120
          direction                  = "Inbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          source_port_range          = "*"
          destination_port_range     = "22"
          source_address_prefix      = "203.0.113.0/24" # Replace with your IP range
          destination_address_prefix = "*"
        }
      }
    },
    {
      name             = "public-subnet-2"
      address_prefixes = ["10.0.2.0/24"]
      service_endpoints = [
        "Microsoft.Storage"
      ]
    }
  ]

  # Private Subnets
  private_subnets = [
    {
      name             = "app-subnet-1"
      address_prefixes = ["10.0.10.0/24"]
      service_endpoints = [
        "Microsoft.Storage",
        "Microsoft.Sql",
        "Microsoft.KeyVault"
      ]
      nsg_rules = {
        allow_internal = {
          priority                   = 100
          direction                  = "Inbound"
          access                     = "Allow"
          protocol                   = "*"
          source_port_range          = "*"
          destination_port_range     = "*"
          source_address_prefix      = "10.0.0.0/16"
          destination_address_prefix = "*"
        }
      }
    },
    {
      name             = "data-subnet-1"
      address_prefixes = ["10.0.20.0/24"]
      service_endpoints = [
        "Microsoft.Sql",
        "Microsoft.Storage"
      ]
      nsg_rules = {
        allow_app_subnet = {
          priority                   = 100
          direction                  = "Inbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          source_port_range          = "*"
          destination_port_range     = "5432" # PostgreSQL
          source_address_prefix      = "10.0.10.0/24"
          destination_address_prefix = "*"
        }
      }
    },
    {
      name             = "aks-subnet-1"
      address_prefixes = ["10.0.30.0/23"]
      service_endpoints = [
        "Microsoft.Storage",
        "Microsoft.ContainerRegistry"
      ]
    }
  ]

  # NAT Gateway
  enable_nat_gateway          = true
  nat_gateway_zones           = ["1"]
  nat_gateway_idle_timeout    = 10

  # Flow Logs
  enable_flow_logs            = true
  flow_logs_retention_days    = 30

  # Traffic Analytics
  enable_traffic_analytics              = true
  log_analytics_workspace_id            = azurerm_log_analytics_workspace.example.workspace_id
  log_analytics_workspace_resource_id   = azurerm_log_analytics_workspace.example.id
  traffic_analytics_interval            = 10

  tags = {
    Environment = "example"
    Purpose     = "vnet-demo"
    ManagedBy   = "terraform"
  }
}
