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

# AKS Cluster
resource "azurerm_kubernetes_cluster" "main" {
  name                = var.cluster_name
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = var.dns_prefix != null ? var.dns_prefix : "${var.cluster_name}-dns"
  kubernetes_version  = var.kubernetes_version
  sku_tier            = var.sku_tier

  default_node_pool {
    name                         = var.default_node_pool_name
    vm_size                      = var.node_vm_size
    node_count                   = var.enable_auto_scaling ? null : var.node_count
    vnet_subnet_id               = var.subnet_id
    type                         = "VirtualMachineScaleSets"
    only_critical_addons_enabled = var.only_critical_addons_enabled
    zones                        = var.availability_zones

    # Auto-scaling configuration
    enable_auto_scaling = var.enable_auto_scaling
    min_count           = var.enable_auto_scaling ? var.node_min_count : null
    max_count           = var.enable_auto_scaling ? var.node_max_count : null

    # Node configuration
    os_disk_size_gb      = var.node_os_disk_size_gb
    os_disk_type         = var.node_os_disk_type
    max_pods             = var.node_max_pods
    enable_node_public_ip = var.enable_node_public_ip

    node_labels = var.node_labels
    node_taints = var.node_taints

    upgrade_settings {
      max_surge = var.max_surge
    }
  }

  # Managed Identity
  identity {
    type = "SystemAssigned"
  }

  # RBAC and Azure AD Integration
  role_based_access_control_enabled = var.enable_rbac

  dynamic "azure_active_directory_role_based_access_control" {
    for_each = var.enable_azure_ad_rbac ? [1] : []
    content {
      managed                = true
      azure_rbac_enabled     = var.azure_rbac_enabled
      admin_group_object_ids = var.azure_ad_admin_group_object_ids
    }
  }

  # Network Profile - Azure CNI
  network_profile {
    network_plugin      = var.network_plugin
    network_policy      = var.network_policy
    dns_service_ip      = var.dns_service_ip
    service_cidr        = var.service_cidr
    load_balancer_sku   = var.load_balancer_sku
    outbound_type       = var.outbound_type
    network_plugin_mode = var.network_plugin_mode

    dynamic "load_balancer_profile" {
      for_each = var.load_balancer_sku == "standard" ? [1] : []
      content {
        managed_outbound_ip_count = var.load_balancer_managed_outbound_ip_count
      }
      }
  }

  # API Server Access Profile
  dynamic "api_server_access_profile" {
    for_each = length(var.api_server_authorized_ip_ranges) > 0 ? [1] : []
    content {
      authorized_ip_ranges = var.api_server_authorized_ip_ranges
    }
  }

  # Azure Monitor Integration
  dynamic "oms_agent" {
    for_each = var.enable_azure_monitor ? [1] : []
    content {
      log_analytics_workspace_id = var.log_analytics_workspace_id
    }
  }

  # Azure Policy Add-on
  azure_policy_enabled = var.enable_azure_policy

  # HTTP Application Routing (not recommended for production)
  http_application_routing_enabled = var.enable_http_application_routing

  # Maintenance Window
  dynamic "maintenance_window" {
    for_each = var.maintenance_window != null ? [var.maintenance_window] : []
    content {
      dynamic "allowed" {
        for_each = maintenance_window.value.allowed
        content {
          day   = allowed.value.day
          hours = allowed.value.hours
        }
      }
    }
  }

  # Auto-upgrade
  automatic_channel_upgrade = var.automatic_channel_upgrade

  tags = merge(
    var.tags,
    {
      Name = var.cluster_name
      Cost = "aks-control-plane"
    }
  )

  lifecycle {
    ignore_changes = [
      default_node_pool[0].node_count
    ]
  }
}

# Additional Node Pools
resource "azurerm_kubernetes_cluster_node_pool" "additional" {
  for_each = var.additional_node_pools

  name                  = each.key
  kubernetes_cluster_id = azurerm_kubernetes_cluster.main.id
  vm_size               = each.value.vm_size
  vnet_subnet_id        = var.subnet_id
  zones                 = lookup(each.value, "zones", var.availability_zones)

  # Auto-scaling
  enable_auto_scaling = lookup(each.value, "enable_auto_scaling", true)
  node_count          = lookup(each.value, "enable_auto_scaling", true) ? null : lookup(each.value, "node_count", 3)
  min_count           = lookup(each.value, "enable_auto_scaling", true) ? lookup(each.value, "min_count", 1) : null
  max_count           = lookup(each.value, "enable_auto_scaling", true) ? lookup(each.value, "max_count", 10) : null

  # Node configuration
  os_disk_size_gb      = lookup(each.value, "os_disk_size_gb", var.node_os_disk_size_gb)
  os_disk_type         = lookup(each.value, "os_disk_type", var.node_os_disk_type)
  max_pods             = lookup(each.value, "max_pods", var.node_max_pods)
  enable_node_public_ip = lookup(each.value, "enable_node_public_ip", false)

  node_labels = lookup(each.value, "node_labels", {})
  node_taints = lookup(each.value, "node_taints", [])

  upgrade_settings {
    max_surge = lookup(each.value, "max_surge", var.max_surge)
  }

  tags = merge(
    var.tags,
    lookup(each.value, "tags", {}),
    {
      Name = "${var.cluster_name}-${each.key}"
      Cost = "aks-worker-nodes"
    }
  )

  lifecycle {
    ignore_changes = [
      node_count
    ]
  }
}

# Log Analytics Workspace (if not provided)
resource "azurerm_log_analytics_workspace" "main" {
  count               = var.enable_azure_monitor && var.log_analytics_workspace_id == null ? 1 : 0
  name                = "${var.cluster_name}-logs"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = var.log_retention_days

  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_name}-logs"
      Cost = "monitoring"
    }
  )
}

# Diagnostic Settings
resource "azurerm_monitor_diagnostic_setting" "aks" {
  count                      = var.enable_diagnostic_settings ? 1 : 0
  name                       = "${var.cluster_name}-diagnostics"
  target_resource_id         = azurerm_kubernetes_cluster.main.id
  log_analytics_workspace_id = var.log_analytics_workspace_id != null ? var.log_analytics_workspace_id : azurerm_log_analytics_workspace.main[0].id

  dynamic "enabled_log" {
    for_each = var.diagnostic_log_categories
    content {
      category = enabled_log.value
    }
  }

  dynamic "metric" {
    for_each = ["AllMetrics"]
    content {
      category = metric.value
      enabled  = true
    }
  }
}
