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

# Azure Virtual Network module variables extending base network module

variable "vnet_name" {
  description = "Name of the virtual network"
  type        = string

  validation {
    condition     = length(var.vnet_name) >= 2 && length(var.vnet_name) <= 64
    error_message = "VNet name must be between 2 and 64 characters."
  }

  validation {
    condition     = can(regex("^[a-zA-Z0-9][a-zA-Z0-9._-]*[a-zA-Z0-9_]$", var.vnet_name))
    error_message = "VNet name must start with alphanumeric, end with alphanumeric or underscore, and contain only alphanumerics, periods, hyphens or underscores."
  }
}

variable "location" {
  description = "Azure region for the virtual network"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "address_space" {
  description = "Address space for the virtual network (CIDR notation)"
  type        = list(string)

  validation {
    condition     = length(var.address_space) > 0
    error_message = "At least one address space must be specified."
  }

  validation {
    condition = alltrue([
      for cidr in var.address_space :
      can(cidrhost(cidr, 0))
    ])
    error_message = "All address spaces must be valid CIDR blocks (e.g., 10.0.0.0/16)."
  }
}

variable "dns_servers" {
  description = "DNS servers for the virtual network"
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for ip in var.dns_servers :
      can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}$", ip))
    ])
    error_message = "All DNS servers must be valid IP addresses."
  }
}

# Subnets
variable "public_subnets" {
  description = "List of public subnets"
  type = list(object({
    name              = string
    address_prefixes  = list(string)
    service_endpoints = optional(list(string), [])
    delegations = optional(list(object({
      name         = string
      service_name = string
      actions      = list(string)
    })), [])
    nsg_rules = optional(map(object({
      priority                   = number
      direction                  = string
      access                     = string
      protocol                   = string
      source_port_range          = string
      destination_port_range     = string
      source_address_prefix      = string
      destination_address_prefix = string
    })), {})
  }))
  default = []

  validation {
    condition = alltrue([
      for subnet in var.public_subnets :
      alltrue([
        for cidr in subnet.address_prefixes :
        can(cidrhost(cidr, 0))
      ])
    ])
    error_message = "All subnet address prefixes must be valid CIDR blocks."
  }
}

variable "private_subnets" {
  description = "List of private subnets"
  type = list(object({
    name              = string
    address_prefixes  = list(string)
    service_endpoints = optional(list(string), [])
    delegations = optional(list(object({
      name         = string
      service_name = string
      actions      = list(string)
    })), [])
    nsg_rules = optional(map(object({
      priority                   = number
      direction                  = string
      access                     = string
      protocol                   = string
      source_port_range          = string
      destination_port_range     = string
      source_address_prefix      = string
      destination_address_prefix = string
    })), {})
  }))
  default = []

  validation {
    condition = alltrue([
      for subnet in var.private_subnets :
      alltrue([
        for cidr in subnet.address_prefixes :
        can(cidrhost(cidr, 0))
      ])
    ])
    error_message = "All subnet address prefixes must be valid CIDR blocks."
  }
}

# NAT Gateway
variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for private subnets"
  type        = bool
  default     = true
}

variable "nat_gateway_zones" {
  description = "Availability zones for NAT Gateway"
  type        = list(string)
  default     = ["1"]

  validation {
    condition = alltrue([
      for zone in var.nat_gateway_zones :
      contains(["1", "2", "3"], zone)
    ])
    error_message = "NAT Gateway zones must be one of: 1, 2, 3."
  }
}

variable "nat_gateway_idle_timeout" {
  description = "Idle timeout in minutes for NAT Gateway"
  type        = number
  default     = 4

  validation {
    condition     = var.nat_gateway_idle_timeout >= 4 && var.nat_gateway_idle_timeout <= 120
    error_message = "NAT Gateway idle timeout must be between 4 and 120 minutes."
  }
}

# Flow Logs
variable "enable_flow_logs" {
  description = "Enable NSG flow logs"
  type        = bool
  default     = true
}

variable "network_watcher_name" {
  description = "Name of the Network Watcher. If not provided, uses default NetworkWatcher_<location>"
  type        = string
  default     = null
}

variable "network_watcher_resource_group" {
  description = "Resource group of the Network Watcher. If not provided, uses NetworkWatcherRG"
  type        = string
  default     = null
}

variable "flow_logs_storage_account_id" {
  description = "Storage Account ID for flow logs. If not provided, a new one will be created"
  type        = string
  default     = null
}

variable "flow_logs_retention_days" {
  description = "Number of days to retain flow logs"
  type        = number
  default     = 30

  validation {
    condition     = var.flow_logs_retention_days >= 0 && var.flow_logs_retention_days <= 365
    error_message = "Flow logs retention must be between 0 and 365 days."
  }
}

# Traffic Analytics
variable "enable_traffic_analytics" {
  description = "Enable Traffic Analytics for flow logs"
  type        = bool
  default     = true
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics Workspace ID for Traffic Analytics"
  type        = string
  default     = null
}

variable "log_analytics_workspace_resource_id" {
  description = "Log Analytics Workspace Resource ID for Traffic Analytics"
  type        = string
  default     = null
}

variable "traffic_analytics_interval" {
  description = "Traffic Analytics processing interval in minutes"
  type        = number
  default     = 10

  validation {
    condition     = contains([10, 60], var.traffic_analytics_interval)
    error_message = "Traffic Analytics interval must be either 10 or 60 minutes."
  }
}

# Tags
variable "tags" {
  description = "Tags to apply to network resources"
  type        = map(string)
  default     = {}
}
