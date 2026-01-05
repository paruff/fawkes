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

variable "subscription_id" {
  description = "Azure subscription ID (optional; defaults to Azure CLI context if not set)"
  type        = string
  default     = null
}

variable "tenant_id" {
  description = "Azure tenant ID (optional; defaults to Azure CLI context if not set)"
  type        = string
  default     = null
}

variable "location" {
  description = "Azure region for resources (e.g., eastus)"
  type        = string
}

variable "rg_name" {
  description = "Resource group name"
  type        = string
}

variable "tags" {
  description = "Common resource tags"
  type        = map(string)
  default = {
    app       = "fawkes"
    component = "platform"
  }
}

variable "vnet_name" {
  description = "Virtual network name"
  type        = string
}

variable "vnet_cidr" {
  description = "VNet address space CIDR"
  type        = string
}

variable "subnet_name" {
  description = "Subnet name for AKS"
  type        = string
}

variable "subnet_cidr" {
  description = "Subnet CIDR for AKS nodes"
  type        = string
}

variable "cluster_name" {
  description = "AKS cluster name"
  type        = string
}

variable "node_vm_size" {
  description = "Default node pool VM size (use an allowed SKU in your region)"
  type        = string
  default     = "Standard_B2ms"
}

variable "node_count" {
  description = "Default node pool count"
  type        = number
  default     = 3
}

variable "network_plugin" {
  description = "AKS network plugin (azure or kubenet)"
  type        = string
  default     = "azure"
}

variable "network_policy" {
  description = "AKS network policy (azure, calico, or cilium)"
  type        = string
  default     = "azure"
}

variable "service_cidr" {
  description = "Service CIDR for Kubernetes services"
  type        = string
  default     = "10.0.0.0/16"
}

variable "dns_service_ip" {
  description = "DNS service IP from service CIDR"
  type        = string
  default     = "10.0.0.10"
}

variable "api_server_authorized_ip_ranges" {
  description = "Optional list of authorized IP ranges for the API server"
  type        = list(string)
  default     = []
}

variable "enable_rbac" {
  description = "Enable Kubernetes RBAC"
  type        = bool
  default     = true
}

variable "enable_managed_identity" {
  description = "Enable System Assigned Managed Identity"
  type        = bool
  default     = true
}
