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
  name     = "example-aks-rg"
  location = "East US"
}

# Virtual Network
module "vnet" {
  source = "../../vnet"

  vnet_name           = "example-aks-vnet"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  address_space       = ["10.0.0.0/16"]

  public_subnets = [
    {
      name             = "public-subnet"
      address_prefixes = ["10.0.1.0/24"]
    }
  ]

  private_subnets = [
    {
      name             = "aks-subnet"
      address_prefixes = ["10.0.10.0/23"]
    }
  ]

  enable_nat_gateway = true
  enable_flow_logs   = false # Disabled for example

  tags = {
    Environment = "example"
    Purpose     = "aks-demo"
  }
}

# Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "example" {
  name                = "example-aks-logs"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = {
    Environment = "example"
    Purpose     = "aks-demo"
  }
}

# AKS Cluster
module "aks" {
  source = "../../aks"

  cluster_name        = "example-aks-cluster"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  kubernetes_version  = "1.28"
  sku_tier            = "Standard"

  # Network
  subnet_id = module.vnet.private_subnet_ids["aks-subnet"]

  # Default Node Pool
  default_node_pool_name = "systemnp"
  node_vm_size           = "Standard_D2s_v3"
  enable_auto_scaling    = true
  node_min_count         = 2
  node_max_count         = 5
  availability_zones     = ["1", "2", "3"]

  # Additional Node Pools
  additional_node_pools = {
    workload = {
      vm_size             = "Standard_D4s_v3"
      enable_auto_scaling = true
      min_count           = 1
      max_count           = 10
      zones               = ["1", "2", "3"]
      node_labels = {
        workload = "general"
      }
    }
  }

  # Networking
  network_plugin = "azure"
  network_policy = "azure"
  service_cidr   = "10.1.0.0/16"
  dns_service_ip = "10.1.0.10"

  # RBAC
  enable_rbac = true

  # Monitoring
  enable_azure_monitor        = true
  log_analytics_workspace_id  = azurerm_log_analytics_workspace.example.id
  enable_diagnostic_settings  = true

  tags = {
    Environment = "example"
    Purpose     = "aks-demo"
    ManagedBy   = "terraform"
  }
}
