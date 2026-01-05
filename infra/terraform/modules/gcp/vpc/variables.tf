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

# GCP VPC module variables extending base network module

variable "network_name" {
  description = "Name of the VPC network"
  type        = string

  validation {
    condition     = length(var.network_name) >= 2 && length(var.network_name) <= 64
    error_message = "Network name must be between 2 and 64 characters."
  }

  validation {
    condition     = can(regex("^[a-z]([-a-z0-9]*[a-z0-9])?$", var.network_name))
    error_message = "Network name must start with a lowercase letter, followed by lowercase letters, numbers, or hyphens."
  }
}

variable "location" {
  description = "GCP region for the network resources"
  type        = string

  validation {
    condition     = can(regex("^(us|europe|asia|australia|southamerica|northamerica)-(central|east|west|north|south|northeast|southeast|southwest)[0-9]?$", var.location))
    error_message = "Location must be a valid GCP region (e.g., us-central1, europe-west1)."
  }
}

variable "project_id" {
  description = "GCP project ID"
  type        = string

  validation {
    condition     = length(var.project_id) >= 6 && length(var.project_id) <= 30
    error_message = "Project ID must be between 6 and 30 characters."
  }
}

variable "routing_mode" {
  description = "Network routing mode (REGIONAL or GLOBAL)"
  type        = string
  default     = "REGIONAL"

  validation {
    condition     = contains(["REGIONAL", "GLOBAL"], var.routing_mode)
    error_message = "Routing mode must be REGIONAL or GLOBAL."
  }
}

variable "subnets" {
  description = "List of subnets to create"
  type = list(object({
    name                            = string
    ip_cidr_range                   = string
    description                     = optional(string, "")
    enable_private_ip_google_access = optional(bool, true)
    purpose                         = optional(string, "PRIVATE")
    role                            = optional(string, null)
    secondary_ip_ranges = optional(list(object({
      range_name    = string
      ip_cidr_range = string
    })), [])
  }))

  validation {
    condition     = length(var.subnets) >= 1
    error_message = "At least one subnet must be specified."
  }

  validation {
    condition = alltrue([
      for subnet in var.subnets :
      can(cidrhost(subnet.ip_cidr_range, 0))
    ])
    error_message = "All subnet IP CIDR ranges must be valid CIDR blocks."
  }

  validation {
    condition = alltrue([
      for subnet in var.subnets :
      can(regex("^[a-z]([-a-z0-9]*[a-z0-9])?$", subnet.name))
    ])
    error_message = "All subnet names must start with a lowercase letter, followed by lowercase letters, numbers, or hyphens."
  }
}

variable "enable_nat_gateway" {
  description = "Enable Cloud NAT for outbound connectivity from private resources"
  type        = bool
  default     = true
}

variable "router_asn" {
  description = "ASN for Cloud Router"
  type        = number
  default     = 64514

  validation {
    condition     = var.router_asn >= 64512 && var.router_asn <= 65534 || var.router_asn >= 4200000000 && var.router_asn <= 4294967294
    error_message = "Router ASN must be in the private ASN range (64512-65534 or 4200000000-4294967294)."
  }
}

variable "nat_ip_allocate_option" {
  description = "How external IPs should be allocated for Cloud NAT"
  type        = string
  default     = "AUTO_ONLY"

  validation {
    condition     = contains(["MANUAL_ONLY", "AUTO_ONLY"], var.nat_ip_allocate_option)
    error_message = "NAT IP allocate option must be MANUAL_ONLY or AUTO_ONLY."
  }
}

variable "source_subnetwork_ip_ranges_to_nat" {
  description = "How NAT should be configured per subnetwork"
  type        = string
  default     = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  validation {
    condition = contains([
      "ALL_SUBNETWORKS_ALL_IP_RANGES",
      "ALL_SUBNETWORKS_ALL_PRIMARY_IP_RANGES",
      "LIST_OF_SUBNETWORKS"
    ], var.source_subnetwork_ip_ranges_to_nat)
    error_message = "Invalid source_subnetwork_ip_ranges_to_nat value."
  }
}

variable "nat_subnetworks" {
  description = "List of subnetworks for NAT when source_subnetwork_ip_ranges_to_nat is LIST_OF_SUBNETWORKS"
  type = list(object({
    name                    = string
    source_ip_ranges_to_nat = list(string)
  }))
  default = []
}

variable "nat_min_ports_per_vm" {
  description = "Minimum number of ports allocated to a VM for Cloud NAT"
  type        = number
  default     = 64

  validation {
    condition     = var.nat_min_ports_per_vm >= 64 && var.nat_min_ports_per_vm <= 65536
    error_message = "NAT min ports per VM must be between 64 and 65536."
  }
}

variable "nat_enable_endpoint_independent_mapping" {
  description = "Enable endpoint independent mapping for Cloud NAT"
  type        = bool
  default     = false
}

variable "nat_log_config_enable" {
  description = "Enable logging for Cloud NAT"
  type        = bool
  default     = true
}

variable "nat_log_config_filter" {
  description = "Log filter for Cloud NAT"
  type        = string
  default     = "ERRORS_ONLY"

  validation {
    condition     = contains(["ERRORS_ONLY", "TRANSLATIONS_ONLY", "ALL"], var.nat_log_config_filter)
    error_message = "NAT log filter must be ERRORS_ONLY, TRANSLATIONS_ONLY, or ALL."
  }
}

variable "enable_flow_logs" {
  description = "Enable VPC Flow Logs"
  type        = bool
  default     = true
}

variable "flow_logs_aggregation_interval" {
  description = "Aggregation interval for VPC Flow Logs"
  type        = string
  default     = "INTERVAL_5_SEC"

  validation {
    condition = contains([
      "INTERVAL_5_SEC", "INTERVAL_30_SEC", "INTERVAL_1_MIN",
      "INTERVAL_5_MIN", "INTERVAL_10_MIN", "INTERVAL_15_MIN"
    ], var.flow_logs_aggregation_interval)
    error_message = "Invalid flow logs aggregation interval."
  }
}

variable "flow_logs_sampling" {
  description = "Sampling rate for VPC Flow Logs (0.0 to 1.0)"
  type        = number
  default     = 0.5

  validation {
    condition     = var.flow_logs_sampling >= 0.0 && var.flow_logs_sampling <= 1.0
    error_message = "Flow logs sampling must be between 0.0 and 1.0."
  }
}

variable "flow_logs_metadata" {
  description = "Metadata fields to include in flow logs"
  type        = string
  default     = "INCLUDE_ALL_METADATA"

  validation {
    condition     = contains(["EXCLUDE_ALL_METADATA", "INCLUDE_ALL_METADATA", "CUSTOM_METADATA"], var.flow_logs_metadata)
    error_message = "Flow logs metadata must be EXCLUDE_ALL_METADATA, INCLUDE_ALL_METADATA, or CUSTOM_METADATA."
  }
}

variable "flow_logs_metadata_fields" {
  description = "List of metadata fields to include when flow_logs_metadata is CUSTOM_METADATA"
  type        = list(string)
  default     = []
}

variable "flow_logs_filter_expr" {
  description = "Filter expression for VPC Flow Logs"
  type        = string
  default     = "true"
}

variable "firewall_rules" {
  description = "List of custom firewall rules"
  type = list(object({
    name               = string
    description        = optional(string, "")
    direction          = string
    priority           = optional(number, 1000)
    source_ranges      = optional(list(string), [])
    destination_ranges = optional(list(string), [])
    source_tags        = optional(list(string), [])
    target_tags        = optional(list(string), [])
    allow = optional(list(object({
      protocol = string
      ports    = optional(list(string), [])
    })), [])
    deny = optional(list(object({
      protocol = string
      ports    = optional(list(string), [])
    })), [])
    log_config_metadata = optional(string, "INCLUDE_ALL_METADATA")
  }))
  default = []

  validation {
    condition = alltrue([
      for rule in var.firewall_rules :
      contains(["INGRESS", "EGRESS"], rule.direction)
    ])
    error_message = "Firewall rule direction must be INGRESS or EGRESS."
  }

  validation {
    condition = alltrue([
      for rule in var.firewall_rules :
      rule.priority >= 0 && rule.priority <= 65535
    ])
    error_message = "Firewall rule priority must be between 0 and 65535."
  }
}

variable "create_default_firewall_rules" {
  description = "Create default firewall rules for common scenarios"
  type        = bool
  default     = true
}

variable "allow_ssh_from_iap" {
  description = "Allow SSH access from Identity-Aware Proxy"
  type        = bool
  default     = true
}

variable "deny_all_egress" {
  description = "Deny all egress traffic (use with caution, typically for highly restricted environments)"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Labels to apply to network resources (Note: GCP VPC/subnet resources don't support labels, kept for base module compatibility)"
  type        = map(string)
  default     = {}
}
