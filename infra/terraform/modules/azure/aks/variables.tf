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

# Azure AKS module variables extending base kubernetes-cluster module

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
  description = "DNS prefix for the cluster. Defaults to cluster_name-dns"
  type        = string
  default     = null
}

variable "kubernetes_version" {
  description = "Kubernetes version to use for the AKS cluster"
  type        = string
  default     = "1.28"

  validation {
    condition     = can(regex("^1\\.(2[4-9]|[3-9][0-9]|[0-9]{3,})$", var.kubernetes_version))
    error_message = "Kubernetes version must be 1.24 or higher (format: 1.28)."
  }
}

variable "sku_tier" {
  description = "SKU tier for the cluster. Free or Standard (with SLA)"
  type        = string
  default     = "Standard"

  validation {
    condition     = contains(["Free", "Standard"], var.sku_tier)
    error_message = "SKU tier must be either Free or Standard."
  }
}

variable "subnet_id" {
  description = "ID of the subnet for AKS nodes"
  type        = string
}

# Default Node Pool Configuration
variable "default_node_pool_name" {
  description = "Name of the default node pool"
  type        = string
  default     = "systemnp"

  validation {
    condition     = length(var.default_node_pool_name) <= 12 && can(regex("^[a-z][a-z0-9]*$", var.default_node_pool_name))
    error_message = "Node pool name must be lowercase alphanumeric, start with a letter, and be max 12 characters."
  }
}

variable "node_vm_size" {
  description = "VM size for the default node pool"
  type        = string
  default     = "Standard_D2s_v3"
}

variable "node_count" {
  description = "Number of nodes in the default node pool (used when auto-scaling is disabled)"
  type        = number
  default     = 3

  validation {
    condition     = var.node_count >= 1 && var.node_count <= 1000
    error_message = "Node count must be between 1 and 1000."
  }
}

variable "only_critical_addons_enabled" {
  description = "Whether only critical addons should be enabled on the default node pool"
  type        = bool
  default     = false
}

variable "availability_zones" {
  description = "Availability zones for node pools"
  type        = list(string)
  default     = ["1", "2", "3"]

  validation {
    condition = alltrue([
      for zone in var.availability_zones :
      contains(["1", "2", "3"], zone)
    ])
    error_message = "Availability zones must be one of: 1, 2, 3."
  }
}

# Auto-scaling
variable "enable_auto_scaling" {
  description = "Enable auto-scaling for the default node pool"
  type        = bool
  default     = true
}

variable "node_min_count" {
  description = "Minimum number of nodes when auto-scaling is enabled"
  type        = number
  default     = 1

  validation {
    condition     = var.node_min_count >= 0 && var.node_min_count <= 1000
    error_message = "Node min count must be between 0 and 1000."
  }
}

variable "node_max_count" {
  description = "Maximum number of nodes when auto-scaling is enabled"
  type        = number
  default     = 10

  validation {
    condition     = var.node_max_count >= 1 && var.node_max_count <= 1000
    error_message = "Node max count must be between 1 and 1000."
  }
}

# Node Configuration
variable "node_os_disk_size_gb" {
  description = "OS disk size in GB for nodes"
  type        = number
  default     = 128

  validation {
    condition     = var.node_os_disk_size_gb >= 30
    error_message = "OS disk size must be at least 30 GB."
  }
}

variable "node_os_disk_type" {
  description = "OS disk type for nodes"
  type        = string
  default     = "Managed"

  validation {
    condition     = contains(["Managed", "Ephemeral"], var.node_os_disk_type)
    error_message = "OS disk type must be either Managed or Ephemeral."
  }
}

variable "node_max_pods" {
  description = "Maximum number of pods per node"
  type        = number
  default     = 110

  validation {
    condition     = var.node_max_pods >= 10 && var.node_max_pods <= 250
    error_message = "Max pods must be between 10 and 250."
  }
}

variable "enable_node_public_ip" {
  description = "Enable public IP for nodes"
  type        = bool
  default     = false
}

variable "node_labels" {
  description = "Key-value map of Kubernetes labels for default node pool"
  type        = map(string)
  default     = {}
}

variable "node_taints" {
  description = "List of Kubernetes taints for default node pool"
  type        = list(string)
  default     = []
}

variable "max_surge" {
  description = "Maximum number of nodes that can be created during an upgrade"
  type        = string
  default     = "33%"
}

# Additional Node Pools
variable "additional_node_pools" {
  description = "Map of additional node pools to create"
  type = map(object({
    vm_size              = string
    enable_auto_scaling  = optional(bool, true)
    node_count           = optional(number, 3)
    min_count            = optional(number, 1)
    max_count            = optional(number, 10)
    os_disk_size_gb      = optional(number, 128)
    os_disk_type         = optional(string, "Managed")
    max_pods             = optional(number, 110)
    enable_node_public_ip = optional(bool, false)
    zones                = optional(list(string))
    node_labels          = optional(map(string), {})
    node_taints          = optional(list(string), [])
    max_surge            = optional(string, "33%")
    tags                 = optional(map(string), {})
  }))
  default = {}
}

# RBAC and Azure AD Integration
variable "enable_rbac" {
  description = "Enable Kubernetes RBAC"
  type        = bool
  default     = true
}

variable "enable_azure_ad_rbac" {
  description = "Enable Azure AD integration for RBAC"
  type        = bool
  default     = false
}

variable "azure_rbac_enabled" {
  description = "Enable Azure RBAC for Kubernetes authorization"
  type        = bool
  default     = false
}

variable "azure_ad_admin_group_object_ids" {
  description = "List of Azure AD group object IDs that will have admin access to the cluster"
  type        = list(string)
  default     = []
}

# Network Configuration - Azure CNI
variable "network_plugin" {
  description = "Network plugin for Kubernetes networking (azure or kubenet)"
  type        = string
  default     = "azure"

  validation {
    condition     = contains(["azure", "kubenet"], var.network_plugin)
    error_message = "Network plugin must be either azure or kubenet."
  }
}

variable "network_policy" {
  description = "Network policy to use (azure or calico)"
  type        = string
  default     = "azure"

  validation {
    condition     = var.network_policy == null || contains(["azure", "calico"], var.network_policy)
    error_message = "Network policy must be either azure or calico."
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

variable "service_cidr" {
  description = "Service CIDR for Kubernetes services"
  type        = string
  default     = "10.1.0.0/16"

  validation {
    condition     = can(cidrhost(var.service_cidr, 0))
    error_message = "Service CIDR must be a valid CIDR block (e.g., 10.1.0.0/16)."
  }
}

variable "load_balancer_sku" {
  description = "SKU of the load balancer"
  type        = string
  default     = "standard"

  validation {
    condition     = contains(["basic", "standard"], var.load_balancer_sku)
    error_message = "Load balancer SKU must be either basic or standard."
  }
}

variable "outbound_type" {
  description = "Outbound routing method"
  type        = string
  default     = "loadBalancer"

  validation {
    condition     = contains(["loadBalancer", "userDefinedRouting"], var.outbound_type)
    error_message = "Outbound type must be either loadBalancer or userDefinedRouting."
  }
}

variable "network_plugin_mode" {
  description = "Network plugin mode (only applicable with Azure CNI)"
  type        = string
  default     = null

  validation {
    condition     = var.network_plugin_mode == null || contains(["overlay"], var.network_plugin_mode)
    error_message = "Network plugin mode must be overlay when specified."
  }
}

variable "load_balancer_managed_outbound_ip_count" {
  description = "Number of managed outbound IPs for the load balancer"
  type        = number
  default     = 1

  validation {
    condition     = var.load_balancer_managed_outbound_ip_count >= 1 && var.load_balancer_managed_outbound_ip_count <= 100
    error_message = "Managed outbound IP count must be between 1 and 100."
  }
}

# API Server Access
variable "api_server_authorized_ip_ranges" {
  description = "Authorized IP ranges for API server access (empty list allows all)"
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for cidr in var.api_server_authorized_ip_ranges :
      can(cidrhost(cidr, 0))
    ])
    error_message = "All IP ranges must be valid CIDR blocks."
  }
}

# Monitoring
variable "enable_azure_monitor" {
  description = "Enable Azure Monitor Container Insights"
  type        = bool
  default     = true
}

variable "log_analytics_workspace_id" {
  description = "ID of existing Log Analytics workspace. If not provided and monitoring is enabled, a new one will be created"
  type        = string
  default     = null
}

variable "log_retention_days" {
  description = "Number of days to retain logs in Log Analytics workspace"
  type        = number
  default     = 30

  validation {
    condition     = contains([30, 60, 90, 120, 180, 270, 365, 550, 730], var.log_retention_days)
    error_message = "Log retention must be one of: 30, 60, 90, 120, 180, 270, 365, 550, 730 days."
  }
}

variable "enable_diagnostic_settings" {
  description = "Enable diagnostic settings for AKS cluster"
  type        = bool
  default     = true
}

variable "diagnostic_log_categories" {
  description = "List of log categories to enable"
  type        = list(string)
  default = [
    "kube-apiserver",
    "kube-audit",
    "kube-audit-admin",
    "kube-controller-manager",
    "kube-scheduler",
    "cluster-autoscaler",
    "cloud-controller-manager",
    "guard",
    "csi-azuredisk-controller",
    "csi-azurefile-controller",
    "csi-snapshot-controller"
  ]
}

# Add-ons
variable "enable_azure_policy" {
  description = "Enable Azure Policy add-on"
  type        = bool
  default     = false
}

variable "enable_http_application_routing" {
  description = "Enable HTTP Application Routing (not recommended for production)"
  type        = bool
  default     = false
}

# Maintenance
variable "maintenance_window" {
  description = "Maintenance window configuration"
  type = object({
    allowed = list(object({
      day   = string
      hours = list(number)
    }))
  })
  default = null
}

variable "automatic_channel_upgrade" {
  description = "Automatic upgrade channel (patch, rapid, stable, node-image)"
  type        = string
  default     = "stable"

  validation {
    condition     = var.automatic_channel_upgrade == null || contains(["patch", "rapid", "stable", "node-image", "none"], var.automatic_channel_upgrade)
    error_message = "Automatic channel upgrade must be one of: patch, rapid, stable, node-image, none."
  }
}

# Tags
variable "tags" {
  description = "Tags to apply to AKS resources"
  type        = map(string)
  default     = {}
}
