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

# Civo Kubernetes module variables extending base kubernetes-cluster module

variable "cluster_name" {
  description = "Name of the Kubernetes cluster"
  type        = string

  validation {
    condition     = length(var.cluster_name) >= 1 && length(var.cluster_name) <= 63
    error_message = "Cluster name must be between 1 and 63 characters."
  }

  validation {
    condition     = can(regex("^[a-zA-Z0-9][a-zA-Z0-9-]*[a-zA-Z0-9]$", var.cluster_name))
    error_message = "Cluster name must start and end with alphanumeric, and contain only alphanumerics and hyphens."
  }
}

variable "location" {
  description = "Civo region for the cluster (NYC1, LON1, FRA1, PHX1)"
  type        = string

  validation {
    condition     = contains(["NYC1", "LON1", "FRA1", "PHX1"], var.location)
    error_message = "Location must be one of: NYC1, LON1, FRA1, PHX1."
  }
}

variable "node_count" {
  description = "Number of nodes in the default node pool"
  type        = number
  default     = 3

  validation {
    condition     = var.node_count >= 1 && var.node_count <= 100
    error_message = "Node count must be between 1 and 100."
  }
}

variable "node_vm_size" {
  description = "VM size for the default node pool (e.g., g4s.kube.small, g4s.kube.medium, g4s.kube.large)"
  type        = string
  default     = "g4s.kube.medium"

  validation {
    condition = contains([
      "g4s.kube.xsmall",
      "g4s.kube.small",
      "g4s.kube.medium",
      "g4s.kube.large",
      "g4s.kube.xlarge",
      "g4p.kube.small",
      "g4p.kube.medium",
      "g4p.kube.large",
      "g4p.kube.xlarge"
    ], var.node_vm_size)
    error_message = "Node VM size must be a valid Civo instance size."
  }
}

variable "kubernetes_version" {
  description = "Kubernetes version for the cluster (K3s version)"
  type        = string
  default     = null
}

variable "network_id" {
  description = "Network ID for the cluster"
  type        = string
  default     = null
}

variable "firewall_id" {
  description = "Firewall ID for the cluster"
  type        = string
  default     = null
}

variable "cni_plugin" {
  description = "CNI plugin for Kubernetes networking (flannel or cilium)"
  type        = string
  default     = "flannel"

  validation {
    condition     = contains(["flannel", "cilium"], var.cni_plugin)
    error_message = "CNI plugin must be either 'flannel' or 'cilium'."
  }
}

variable "node_pool_label" {
  description = "Label for the default node pool"
  type        = string
  default     = "default-pool"
}

variable "additional_node_pools" {
  description = "List of additional node pools"
  type = list(object({
    label      = string
    node_count = number
    size       = string
  }))
  default = []

  validation {
    condition = alltrue([
      for pool in var.additional_node_pools :
      pool.node_count >= 1 && pool.node_count <= 100
    ])
    error_message = "All node pools must have node count between 1 and 100."
  }
}

variable "marketplace_apps" {
  description = "List of marketplace applications to install"
  type = list(object({
    name    = string
    version = optional(string, null)
  }))
  default = []
}

variable "size_preset" {
  description = "Size preset for quick configuration (small, medium, large)"
  type        = string
  default     = null

  validation {
    condition     = var.size_preset == null || contains(["small", "medium", "large"], var.size_preset)
    error_message = "Size preset must be null, small, medium, or large."
  }
}

variable "tags" {
  description = "Tags to apply to cluster resources"
  type        = map(string)
  default     = {}
}

# Local size presets
locals {
  size_presets = {
    small = {
      node_vm_size = "g4s.kube.small"
      node_count   = 2
    }
    medium = {
      node_vm_size = "g4s.kube.medium"
      node_count   = 3
    }
    large = {
      node_vm_size = "g4s.kube.large"
      node_count   = 5
    }
  }

  # Use preset if specified, otherwise use explicit values
  effective_node_vm_size = var.size_preset != null ? local.size_presets[var.size_preset].node_vm_size : var.node_vm_size
  effective_node_count   = var.size_preset != null ? local.size_presets[var.size_preset].node_count : var.node_count
}
