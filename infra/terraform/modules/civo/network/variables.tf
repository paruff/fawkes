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

variable "firewall_id" {
  description = "Existing firewall ID to use (if not creating new)"
  type        = string
  default     = null
}

variable "firewall_rules" {
  description = "List of firewall rules"
  type = list(object({
    protocol    = string
    start_port  = number
    end_port    = optional(number, null)
    cidr_blocks = list(string)
    direction   = string
    label       = optional(string, null)
    action      = optional(string, "allow")
  }))
  default = []

  validation {
    condition = alltrue([
      for rule in var.firewall_rules :
      contains(["tcp", "udp", "icmp"], rule.protocol)
    ])
    error_message = "Protocol must be tcp, udp, or icmp."
  }

  validation {
    condition = alltrue([
      for rule in var.firewall_rules :
      contains(["ingress", "egress"], rule.direction)
    ])
    error_message = "Direction must be ingress or egress."
  }

  validation {
    condition = alltrue([
      for rule in var.firewall_rules :
      contains(["allow", "deny"], rule.action)
    ])
    error_message = "Action must be allow or deny."
  }
}

variable "create_load_balancer" {
  description = "Create a load balancer for the network"
  type        = bool
  default     = false
}

variable "load_balancer_hostname" {
  description = "Hostname for the load balancer"
  type        = string
  default     = null
}

variable "load_balancer_protocol" {
  description = "Protocol for the load balancer (http, https, tcp)"
  type        = string
  default     = "http"

  validation {
    condition     = contains(["http", "https", "tcp"], var.load_balancer_protocol)
    error_message = "Load balancer protocol must be http, https, or tcp."
  }
}

variable "load_balancer_port" {
  description = "Port for the load balancer"
  type        = number
  default     = 80

  validation {
    condition     = var.load_balancer_port >= 1 && var.load_balancer_port <= 65535
    error_message = "Load balancer port must be between 1 and 65535."
  }
}

variable "load_balancer_max_request_size" {
  description = "Maximum request size in MB"
  type        = number
  default     = 20

  validation {
    condition     = var.load_balancer_max_request_size >= 1 && var.load_balancer_max_request_size <= 100
    error_message = "Max request size must be between 1 and 100 MB."
  }
}

variable "load_balancer_policy" {
  description = "Load balancing policy (round_robin, least_conn, ip_hash)"
  type        = string
  default     = "round_robin"

  validation {
    condition     = contains(["round_robin", "least_conn", "ip_hash"], var.load_balancer_policy)
    error_message = "Policy must be round_robin, least_conn, or ip_hash."
  }
}

variable "load_balancer_health_check_path" {
  description = "Health check path for the load balancer"
  type        = string
  default     = "/"
}

variable "load_balancer_fail_timeout" {
  description = "Fail timeout in seconds"
  type        = number
  default     = 30

  validation {
    condition     = var.load_balancer_fail_timeout >= 1 && var.load_balancer_fail_timeout <= 300
    error_message = "Fail timeout must be between 1 and 300 seconds."
  }
}

variable "load_balancer_max_conns" {
  description = "Maximum connections"
  type        = number
  default     = 10000

  validation {
    condition     = var.load_balancer_max_conns >= 1 && var.load_balancer_max_conns <= 100000
    error_message = "Max connections must be between 1 and 100000."
  }
}

variable "load_balancer_ignore_invalid_backend_tls" {
  description = "Ignore invalid backend TLS certificates"
  type        = bool
  default     = false
}

variable "load_balancer_enable_proxy_protocol" {
  description = "Enable proxy protocol"
  type        = bool
  default     = false
}

variable "load_balancer_backends" {
  description = "List of backend configurations for load balancer"
  type = list(object({
    ip                = string
    protocol          = string
    source_port       = number
    target_port       = number
    health_check_port = optional(number, null)
  }))
  default = []
}

variable "create_reserved_ip" {
  description = "Create a reserved IP for the load balancer"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to network resources"
  type        = map(string)
  default     = {}
}
