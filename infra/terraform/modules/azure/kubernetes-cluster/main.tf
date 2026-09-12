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

resource "azurerm_kubernetes_cluster" "main" {
  name                = var.cluster_name
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = var.dns_prefix != null ? var.dns_prefix : "${var.cluster_name}-dns"

  default_node_pool {
    name                         = "systemnp"
    vm_size                      = var.node_vm_size
    node_count                   = var.node_count
    type                         = "VirtualMachineScaleSets"
    vnet_subnet_id               = var.subnet_id
    only_critical_addons_enabled = var.only_critical_addons_enabled
    # See the spot pool's zones comment below - same per-subscription,
    # per-region zone restriction can apply to the system pool's VM size too.
    zones = var.system_zones

    upgrade_settings {
      max_surge = var.max_surge
    }
  }

  node_provisioning_profile {
    mode = "Manual"
  }

  identity {
    type = var.enable_managed_identity ? "SystemAssigned" : "None"
  }

  role_based_access_control_enabled = var.enable_rbac

  network_profile {
    network_plugin    = var.network_plugin
    network_policy    = var.network_policy
    dns_service_ip    = var.dns_service_ip
    service_cidr      = var.service_cidr
    load_balancer_sku = var.load_balancer_sku
    outbound_type     = var.outbound_type
  }

  dynamic "api_server_access_profile" {
    for_each = length(var.api_server_authorized_ip_ranges) > 0 ? [1] : []
    content {
      authorized_ip_ranges = var.api_server_authorized_ip_ranges
    }
  }

  tags = var.tags
}

resource "azurerm_kubernetes_cluster_node_pool" "user" {
  count = var.enable_user_node_pool ? 1 : 0

  name                  = "usernp"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.main.id
  vm_size               = var.user_vm_size
  node_count            = var.user_node_count
  vnet_subnet_id        = var.subnet_id
  mode                  = "User"
  zones                 = var.user_zones

  tags = var.tags
}

resource "azurerm_kubernetes_cluster_node_pool" "spot" {
  count = var.enable_spot_node_pool ? 1 : 0

  name                  = "spotnp"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.main.id
  vm_size               = var.spot_vm_size
  node_count            = var.spot_node_count
  vnet_subnet_id        = var.subnet_id
  mode                  = "User"
  # Some subscriptions have a per-zone SKU restriction for certain VM sizes
  # in certain regions (confirmed live: Standard_D4s_v3 is
  # NotAvailableForSubscription in westeurope zones 1-2 for this
  # subscription) - null lets Azure auto-select across all zones, which
  # fails outright if it picks a restricted one. Set explicitly to route
  # around a known restriction.
  zones = var.spot_zones

  priority        = "Spot"
  eviction_policy = var.spot_eviction_policy
  spot_max_price  = var.spot_max_price

  # Workloads must explicitly tolerate this taint to land here - Spot nodes
  # can be reclaimed by Azure with 30s notice, so nothing should be
  # scheduled onto them by default.
  node_taints = ["kubernetes.azure.com/scalesetpriority=spot:NoSchedule"]

  tags = var.tags
}
