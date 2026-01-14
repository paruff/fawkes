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
    civo = {
      source  = "civo/civo"
      version = ">= 1.0.0"
    }
  }
}

# Civo Kubernetes Cluster (K3s-based)
resource "civo_kubernetes_cluster" "main" {
  name               = var.cluster_name
  region             = var.location
  num_target_nodes   = var.node_count
  target_nodes_size  = var.node_vm_size
  kubernetes_version = var.kubernetes_version

  # Network configuration
  network_id = var.network_id

  # CNI plugin selection
  cni = var.cni_plugin

  # Firewall
  firewall_id = var.firewall_id

  # Marketplace applications
  dynamic "applications" {
    for_each = var.marketplace_apps
    content {
      application = applications.value.name
      version     = applications.value.version
    }
  }

  # Node pools
  pools {
    label       = var.node_pool_label
    node_count  = var.node_count
    size        = var.node_vm_size
  }

  # Tags
  tags = join(",", [for k, v in merge(
    var.tags,
    {
      cluster = var.cluster_name
      cost    = "civo-k3s-cluster"
    }
  ) : "${k}:${v}"])

  # Wait for cluster to be active
  timeouts {
    create = "15m"
    update = "15m"
    delete = "15m"
  }
}

# Additional node pools
resource "civo_kubernetes_node_pool" "pools" {
  for_each = { for pool in var.additional_node_pools : pool.label => pool }

  cluster_id = civo_kubernetes_cluster.main.id
  label      = each.value.label
  node_count = each.value.node_count
  size       = each.value.size

  timeouts {
    create = "10m"
    update = "10m"
    delete = "10m"
  }
}
