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

variable "project_name" {
  description = "Name of the project, used as a prefix for resource names (e.g. 'fawkes')."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]{2,20}$", var.project_name))
    error_message = "project_name must be 2-20 lowercase alphanumeric characters or hyphens."
  }
}

variable "environment" {
  description = "Deployment environment (dev, staging, or prod). Used in resource names and tags."
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be one of: dev, staging, prod."
  }
}

variable "location" {
  description = "Azure region where state backend resources are created (e.g. 'eastus2')."
  type        = string
}

variable "resource_group_name" {
  description = "Override for the Azure resource group name. Defaults to '<project_name>-tfstate-<environment>-rg' when null."
  type        = string
  default     = null
}

variable "storage_account_name" {
  description = "Name of the Azure Storage Account for state storage. Must be globally unique, 3-24 lowercase alphanumeric characters only."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]{3,24}$", var.storage_account_name))
    error_message = "storage_account_name must be 3-24 lowercase alphanumeric characters (no hyphens or underscores)."
  }
}

variable "soft_delete_retention_days" {
  description = "Number of days that deleted blobs and containers are retained before permanent deletion."
  type        = number
  default     = 30

  validation {
    condition     = var.soft_delete_retention_days >= 1 && var.soft_delete_retention_days <= 365
    error_message = "soft_delete_retention_days must be between 1 and 365."
  }
}

variable "allowed_ip_ranges" {
  description = "List of IP address ranges (CIDR notation) allowed to access the storage account. Leave empty to allow all IP addresses."
  type        = list(string)
  default     = []
}

variable "allowed_subnet_ids" {
  description = "List of Azure subnet IDs allowed to access the storage account via service endpoints. Leave empty to allow all subnets."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Additional tags to apply to all state backend resources. Merged with mandatory Project, Environment, ManagedBy, and Component tags."
  type        = map(string)
  default     = {}
}
