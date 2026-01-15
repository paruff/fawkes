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

# Civo Network module variables extending base network module

variable "network_name" {
  description = "Name of the network"
  type        = string

  validation {
    condition     = length(var.network_name) >= 2 && length(var.network_name) <= 64
    error_message = "Network name must be between 2 and 64 characters."
  }

  validation {
    condition     = can(regex("^[a-zA-Z0-9][a-zA-Z0-9._-]*[a-zA-Z0-9_]$", var.network_name))
    error_message = "Network name must start with alphanumeric, end with alphanumeric or underscore, and contain only alphanumerics, periods, hyphens or underscores."
  }
}

variable "location" {
  description = "Civo region for the network (NYC1, LON1, FRA1, PHX1)"
  type        = string

  validation {
    condition     = contains(["NYC1", "LON1", "FRA1", "PHX1"], var.location)
    error_message = "Location must be one of: NYC1, LON1, FRA1, PHX1."
  }
}

variable "cidr_block" {
  description = "CIDR block for the network"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.cidr_block, 0))
    error_message = "CIDR block must be valid CIDR notation."
  }
}

variable "create_firewall" {
  description = "Create a firewall for the network"
  type        = bool
  default     = true
}

variable "firewall_ingress_rules" {
  description = "List of firewall ingress rules"
  type = list(object({
    label       = string
    protocol    = string
    start_port  = number
    end_port    = number
    cidr_blocks = list(string)
    action      = optional(string, "allow")
  }))
  default = []

  validation {
    condition = alltrue([
      for rule in var.firewall_ingress_rules :
      contains(["tcp", "udp", "icmp"], rule.protocol)
    ])
    error_message = "Protocol must be tcp, udp, or icmp."
  }

  validation {
    condition = alltrue([
      for rule in var.firewall_ingress_rules :
      contains(["allow", "deny"], rule.action)
    ])
    error_message = "Action must be allow or deny."
  }
}
