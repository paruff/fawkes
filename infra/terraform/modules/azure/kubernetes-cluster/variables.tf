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

# Azure AKS-specific variables extending base kubernetes-cluster module

variable "cluster_name" {
  description = "Name of the AKS cluster"
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
  description = "Azure region for the AKS cluster"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "dns_prefix" {
  description = "DNS prefix for the AKS cluster (defaults to cluster_name-dns if not set)"
  type        = string
  default     = null
}

variable "subnet_id" {
  description = "ID of the subnet for AKS nodes"
  type        = string
}

variable "node_vm_size" {
  description = "VM size for the default node pool"
  type        = string
  default     = "Standard_B2ms"

  validation {
    condition     = can(regex("^Standard_[A-Z][0-9]+[a-z]*s?(_v[0-9]+)?$", var.node_vm_size))
    error_message = "Node VM size must be a valid Azure VM SKU (e.g., Standard_B2ms, Standard_D2s_v3)."
  }
}

variable "node_count" {
  description = "Number of nodes in the default node pool"
  type        = number
  default     = 3

  validation {
    condition     = var.node_count >= 1 && var.node_count <= 1000
    error_message = "Node count must be between 1 and 1000."
  }
}

variable "only_critical_addons_enabled" {
  description = "Enable only critical addons in the system node pool"
  type        = bool
  default     = true
}

variable "system_zones" {
  description = "Availability zones for the system node pool (null = Azure auto-selects across all zones - fails outright if the chosen VM size is restricted in a zone for this subscription). Set explicitly to route around a known per-subscription zone restriction."
  type        = list(string)
  default     = null
}

variable "max_surge" {
  description = "Maximum surge during node pool upgrades"
  type        = string
  default     = "33%"

  validation {
    condition     = can(regex("^[0-9]+%?$", var.max_surge))
    error_message = "Max surge must be a number or percentage (e.g., '33%' or '10')."
  }
}

variable "enable_managed_identity" {
  description = "Enable SystemAssigned managed identity for the cluster"
  type        = bool
  default     = true
}

variable "enable_rbac" {
  description = "Enable Kubernetes RBAC"
  type        = bool
  default     = true
}

variable "network_plugin" {
  description = "Network plugin for AKS (azure or kubenet)"
  type        = string
  default     = "azure"

  validation {
    condition     = contains(["azure", "kubenet"], var.network_plugin)
    error_message = "Network plugin must be either 'azure' or 'kubenet'."
  }
}

variable "network_policy" {
  description = "Network policy to use (azure or calico)"
  type        = string
  default     = "azure"

  validation {
    condition     = contains(["azure", "calico"], var.network_policy)
    error_message = "Network policy must be either 'azure' or 'calico'."
  }
}

variable "service_cidr" {
  description = "Service CIDR for Kubernetes services"
  type        = string
  default     = "10.1.0.0/16"

  validation {
    condition     = can(cidrhost(var.service_cidr, 0))
    error_message = "Service CIDR must be a valid CIDR block (e.g., 10.1.0.0/16)."
  }
}

variable "dns_service_ip" {
  description = "DNS service IP (must be within service_cidr)"
  type        = string
  default     = "10.1.0.10"

  validation {
    condition     = can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}$", var.dns_service_ip))
    error_message = "DNS service IP must be a valid IP address."
  }
}

variable "load_balancer_sku" {
  description = "SKU for the load balancer"
  type        = string
  default     = "standard"

  validation {
    condition     = contains(["basic", "standard"], var.load_balancer_sku)
    error_message = "Load balancer SKU must be either 'basic' or 'standard'."
  }
}

variable "outbound_type" {
  description = "Outbound routing type"
  type        = string
  default     = "loadBalancer"

  validation {
    condition     = contains(["loadBalancer", "userDefinedRouting"], var.outbound_type)
    error_message = "Outbound type must be either 'loadBalancer' or 'userDefinedRouting'."
  }
}

variable "api_server_authorized_ip_ranges" {
  description = "Authorized IP ranges for AKS API server access. NO DEFAULT - each caller must explicitly decide. Provide the CIDRs that may reach the API server; use [] ONLY for a fully private cluster (the api_server_access_profile block is omitted). 0.0.0.0/0 is rejected; public open access is not allowed"
  type        = list(string)

  validation {
    condition = alltrue([
      for cidr in var.api_server_authorized_ip_ranges :
      can(cidrhost(cidr, 0))
    ])
    error_message = "All IP ranges must be valid CIDR blocks."
  }

  validation {
    condition     = alltrue([for cidr in var.api_server_authorized_ip_ranges : cidr != "0.0.0.0/0"])
    error_message = "0.0.0.0/0 is not allowed; specify explicit authorized IP ranges, or use [] only for a fully private cluster."
  }
}

variable "tags" {
  description = "Tags to apply to the AKS cluster"
  type        = map(string)
  default     = {}
}

# ============================================================================
# Optional Spot-priced user node pool
# AKS requires the default_node_pool (system pool, above) to run on regular
# VMs - system pods need guaranteed availability that Spot can't provide, so
# Spot capacity always goes in a separate user node pool. Off by default;
# enable to add larger, cheaper burst capacity for non-critical workloads
# (tag anything scheduled there as evictable - Spot nodes can be reclaimed
# by Azure at any time with a 30s notice).
# ============================================================================

variable "enable_spot_node_pool" {
  description = "Add a second, Spot-priced node pool alongside the (always regular-priced) system pool"
  type        = bool
  default     = false
}

variable "spot_vm_size" {
  description = "VM size for the Spot node pool"
  type        = string
  default     = "Standard_D4s_v3"

  validation {
    condition     = can(regex("^Standard_[A-Z][0-9]+[a-z]*s?(_v[0-9]+)?$", var.spot_vm_size))
    error_message = "Spot VM size must be a valid Azure VM SKU (e.g., Standard_D4s_v3)."
  }
}

variable "spot_node_count" {
  description = "Number of nodes in the Spot node pool"
  type        = number
  default     = 2

  validation {
    condition     = var.spot_node_count >= 1 && var.spot_node_count <= 1000
    error_message = "Spot node count must be between 1 and 1000."
  }
}

variable "spot_max_price" {
  description = "Maximum hourly price (USD) per Spot node; -1 means pay up to the regular on-demand price (Azure's recommended default - avoids eviction purely on price, only capacity-driven eviction remains possible)"
  type        = number
  default     = -1
}

variable "spot_zones" {
  description = "Availability zones for the Spot node pool (null = Azure auto-selects across all zones - fails outright if the chosen VM size is restricted in a zone for this subscription). Set explicitly to route around a known per-subscription zone restriction."
  type        = list(string)
  default     = null
}

variable "spot_eviction_policy" {
  description = "What happens to a Spot node when Azure reclaims it"
  type        = string
  default     = "Delete"

  validation {
    condition     = contains(["Delete", "Deallocate"], var.spot_eviction_policy)
    error_message = "Spot eviction policy must be either 'Delete' or 'Deallocate'."
  }
}
