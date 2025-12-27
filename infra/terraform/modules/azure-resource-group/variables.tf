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

variable "name" {
  description = "Name of the resource group"
  type        = string

  validation {
    condition     = length(var.name) >= 1 && length(var.name) <= 90
    error_message = "Resource group name must be between 1 and 90 characters."
  }

  validation {
    condition     = can(regex("^[a-zA-Z0-9._()-]+$", var.name))
    error_message = "Resource group name can only contain alphanumerics, periods, underscores, hyphens and parenthesis."
  }
}

variable "location" {
  description = "Azure region for the resource group"
  type        = string

  validation {
    condition = contains([
      "eastus", "eastus2", "westus", "westus2", "westus3", "centralus",
      "northcentralus", "southcentralus", "westcentralus",
      "canadacentral", "canadaeast",
      "brazilsouth",
      "northeurope", "westeurope", "uksouth", "ukwest",
      "francecentral", "germanywestcentral", "norwayeast", "swedencentral", "switzerlandnorth",
      "eastasia", "southeastasia", "australiaeast", "australiasoutheast",
      "centralindia", "southindia", "japaneast", "japanwest", "koreacentral", "koreasouth"
    ], var.location)
    error_message = "Location must be a valid Azure region."
  }
}

variable "tags" {
  description = "Tags to apply to the resource group"
  type        = map(string)
  default     = {}
}
