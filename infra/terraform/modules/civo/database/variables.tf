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

# Civo Database module variables

variable "database_name" {
  description = "Name of the database cluster"
  type        = string

  validation {
    condition     = length(var.database_name) >= 2 && length(var.database_name) <= 63
    error_message = "Database name must be between 2 and 63 characters."
  }

  validation {
    condition     = can(regex("^[a-zA-Z0-9][a-zA-Z0-9-]*[a-zA-Z0-9]$", var.database_name))
    error_message = "Database name must start and end with alphanumeric, and contain only alphanumerics and hyphens."
  }
}

variable "location" {
  description = "Civo region for the database (NYC1, LON1, FRA1, PHX1)"
  type        = string

  validation {
    condition     = contains(["NYC1", "LON1", "FRA1", "PHX1"], var.location)
    error_message = "Location must be one of: NYC1, LON1, FRA1, PHX1."
  }
}

variable "engine" {
  description = "Database engine (postgres, mysql, redis)"
  type        = string

  validation {
    condition     = contains(["postgres", "mysql", "redis"], var.engine)
    error_message = "Engine must be postgres, mysql, or redis."
  }
}

variable "engine_version" {
  description = "Version of the database engine"
  type        = string
  default     = null
}

variable "database_size" {
  description = "Size of the database instance"
  type        = string
  default     = "g3.db.small"

  validation {
    condition = contains([
      "g3.db.xsmall",
      "g3.db.small",
      "g3.db.medium",
      "g3.db.large",
      "g3.db.xlarge"
    ], var.database_size)
    error_message = "Database size must be a valid Civo database size."
  }
}

variable "node_count" {
  description = "Number of database nodes for high availability"
  type        = number
  default     = 1

  validation {
    condition     = var.node_count >= 1 && var.node_count <= 3
    error_message = "Node count must be between 1 and 3."
  }
}

variable "network_id" {
  description = "Network ID for the database"
  type        = string
  default     = null
}

variable "firewall_id" {
  description = "Firewall ID for the database"
  type        = string
  default     = null
}

variable "create_firewall_rules" {
  description = "Create firewall rules for database access"
  type        = bool
  default     = true
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to access the database"
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for cidr in var.allowed_cidr_blocks :
      can(cidrhost(cidr, 0))
    ])
    error_message = "All CIDR blocks must be valid CIDR notation."
  }
}

variable "backup_enabled" {
  description = "Enable automated backups (managed by Civo)"
  type        = bool
  default     = true
}

variable "backup_retention_days" {
  description = "Number of days to retain backups"
  type        = number
  default     = 7

  validation {
    condition     = var.backup_retention_days >= 1 && var.backup_retention_days <= 30
    error_message = "Backup retention must be between 1 and 30 days."
  }
}

variable "size_preset" {
  description = "Size preset for quick configuration (small, medium, large)"
  type        = string
  default     = null

  validation {
    condition     = var.size_preset == null || contains(["small", "medium", "large"], var.size_preset)
    error_message = "Size preset must be null, small, medium, or large."
  }
}

variable "tags" {
  description = "Tags to apply to database resources"
  type        = map(string)
  default     = {}
}
