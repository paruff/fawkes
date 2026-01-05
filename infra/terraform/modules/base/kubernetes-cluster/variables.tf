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

# Base variables for Kubernetes clusters across all providers

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
  description = "Cloud provider region/location for the cluster"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group (Azure) or equivalent organizational unit"
  type        = string
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

variable "node_vm_size" {
  description = "VM/instance size for the default node pool"
  type        = string
  default     = null
}

variable "enable_rbac" {
  description = "Enable Kubernetes RBAC"
  type        = bool
  default     = true
}

variable "network_plugin" {
  description = "Network plugin for Kubernetes networking"
  type        = string
  default     = null
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

variable "tags" {
  description = "Tags to apply to cluster resources"
  type        = map(string)
  default     = {}
}
