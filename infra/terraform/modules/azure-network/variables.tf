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

variable "vnet_name" {
  description = "Name of the virtual network"
  type        = string

  validation {
    condition     = length(var.vnet_name) >= 2 && length(var.vnet_name) <= 64
    error_message = "Virtual network name must be between 2 and 64 characters."
  }

  validation {
    condition     = can(regex("^[a-zA-Z0-9][a-zA-Z0-9._-]*[a-zA-Z0-9_]$", var.vnet_name))
    error_message = "Virtual network name must start with alphanumeric, end with alphanumeric or underscore, and contain only alphanumerics, periods, hyphens or underscores."
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

variable "subnet_name" {
  description = "Name of the subnet"
  type        = string

  validation {
    condition     = length(var.subnet_name) >= 1 && length(var.subnet_name) <= 80
    error_message = "Subnet name must be between 1 and 80 characters."
  }
}

variable "subnet_address_prefixes" {
  description = "Address prefixes for the subnet (CIDR notation)"
  type        = list(string)

  validation {
    condition     = length(var.subnet_address_prefixes) > 0
    error_message = "At least one subnet address prefix must be specified."
  }

  validation {
    condition = alltrue([
      for cidr in var.subnet_address_prefixes :
      can(cidrhost(cidr, 0))
    ])
    error_message = "All subnet address prefixes must be valid CIDR blocks (e.g., 10.0.1.0/24)."
  }
}

variable "tags" {
  description = "Tags to apply to network resources"
  type        = map(string)
  default     = {}
}
