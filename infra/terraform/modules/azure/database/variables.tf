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

# Azure Database module variables

variable "server_name" {
  description = "Name of the database server"
  type        = string

  validation {
    condition     = length(var.server_name) >= 3 && length(var.server_name) <= 63
    error_message = "Server name must be between 3 and 63 characters."
  }

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]*[a-z0-9]$", var.server_name))
    error_message = "Server name must be lowercase, start and end with alphanumeric, and contain only lowercase alphanumerics and hyphens."
  }
}

variable "location" {
  description = "Azure region for the database server"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "engine" {
  description = "Database engine type (postgresql or mysql)"
  type        = string

  validation {
    condition     = contains(["postgresql", "mysql"], var.engine)
    error_message = "Engine must be either postgresql or mysql."
  }
}

variable "engine_version" {
  description = "Version of the database engine"
  type        = string

  validation {
    condition = (
      can(regex("^(11|12|13|14|15|16)$", var.engine_version)) ||
      can(regex("^(5\\.7|8\\.0\\.21)$", var.engine_version))
    )
    error_message = "Engine version must be valid PostgreSQL (11-16) or MySQL (5.7, 8.0.21) version."
  }
}

variable "sku_name" {
  description = "SKU name for the database server (e.g., GP_Standard_D2s_v3, B_Standard_B1ms)"
  type        = string
  default     = "GP_Standard_D2s_v3"

  validation {
    condition     = can(regex("^(B|GP|MO)_Standard_", var.sku_name))
    error_message = "SKU name must start with B_ (Burstable), GP_ (General Purpose), or MO_ (Memory Optimized) followed by Standard_."
  }
}

# Authentication
variable "admin_username" {
  description = "Administrator username for the database"
  type        = string
  default     = "dbadmin"

  validation {
    condition     = length(var.admin_username) >= 1 && length(var.admin_username) <= 63
    error_message = "Admin username must be between 1 and 63 characters."
  }
}

variable "admin_password" {
  description = "Administrator password for the database. If not provided, a random password will be generated"
  type        = string
  default     = null
  sensitive   = true

  validation {
    condition     = var.admin_password == null || length(var.admin_password) >= 8
    error_message = "Admin password must be at least 8 characters long."
  }
}

# Storage
variable "storage_mb" {
  description = "Storage size in MB"
  type        = number
  default     = 32768

  validation {
    condition     = var.storage_mb >= 32768 && var.storage_mb <= 16777216
    error_message = "Storage size must be between 32768 MB (32 GB) and 16777216 MB (16 TB)."
  }
}

variable "storage_auto_grow_enabled" {
  description = "Enable storage auto-grow"
  type        = bool
  default     = true
}

variable "storage_iops" {
  description = "Storage IOPS (only for MySQL)"
  type        = number
  default     = null
}

# Backup
variable "backup_retention_days" {
  description = "Backup retention period in days"
  type        = number
  default     = 7

  validation {
    condition     = var.backup_retention_days >= 1 && var.backup_retention_days <= 35
    error_message = "Backup retention must be between 1 and 35 days."
  }
}

variable "geo_redundant_backup_enabled" {
  description = "Enable geo-redundant backups"
  type        = bool
  default     = false
}

# High Availability
variable "high_availability_mode" {
  description = "High availability mode (ZoneRedundant or SameZone). Set to null to disable HA"
  type        = string
  default     = null

  validation {
    condition     = var.high_availability_mode == null || contains(["ZoneRedundant", "SameZone"], var.high_availability_mode)
    error_message = "High availability mode must be either ZoneRedundant or SameZone."
  }
}

variable "standby_availability_zone" {
  description = "Availability zone for standby server"
  type        = string
  default     = null

  validation {
    condition     = var.standby_availability_zone == null || contains(["1", "2", "3"], var.standby_availability_zone)
    error_message = "Standby availability zone must be 1, 2, or 3."
  }
}

variable "zone" {
  description = "Availability zone for the primary server"
  type        = string
  default     = "1"

  validation {
    condition     = contains(["1", "2", "3"], var.zone)
    error_message = "Zone must be 1, 2, or 3."
  }
}

# Maintenance
variable "maintenance_window" {
  description = "Maintenance window configuration"
  type = object({
    day_of_week  = number
    start_hour   = number
    start_minute = number
  })
  default = null

  validation {
    condition = (
      var.maintenance_window == null ||
      (
        var.maintenance_window.day_of_week >= 0 && var.maintenance_window.day_of_week <= 6 &&
        var.maintenance_window.start_hour >= 0 && var.maintenance_window.start_hour <= 23 &&
        var.maintenance_window.start_minute >= 0 && var.maintenance_window.start_minute <= 59
      )
    )
    error_message = "Maintenance window must have valid day_of_week (0-6), start_hour (0-23), and start_minute (0-59)."
  }
}

# Database
variable "create_database" {
  description = "Create a database within the server"
  type        = bool
  default     = true
}

variable "database_name" {
  description = "Name of the database to create"
  type        = string
  default     = "app_db"

  validation {
    condition     = length(var.database_name) >= 1 && length(var.database_name) <= 63
    error_message = "Database name must be between 1 and 63 characters."
  }
}

variable "charset" {
  description = "Character set for the database"
  type        = string
  default     = "UTF8"
}

variable "collation" {
  description = "Collation for the database"
  type        = string
  default     = null
}

# Database Configuration Parameters
variable "database_parameters" {
  description = "Map of database configuration parameters"
  type        = map(string)
  default     = {}
}

# Network Security
variable "firewall_rules" {
  description = "List of firewall rules"
  type = list(object({
    name             = string
    start_ip_address = string
    end_ip_address   = string
  }))
  default = []

  validation {
    condition = alltrue([
      for rule in var.firewall_rules :
      can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}$", rule.start_ip_address)) &&
      can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}$", rule.end_ip_address))
    ])
    error_message = "All firewall rule IP addresses must be valid IPv4 addresses."
  }
}

variable "enable_private_endpoint" {
  description = "Enable private endpoint for the database"
  type        = bool
  default     = false
}

variable "private_endpoint_subnet_id" {
  description = "Subnet ID for private endpoint"
  type        = string
  default     = null
}

# Monitoring and Alerting
variable "enable_diagnostic_settings" {
  description = "Enable diagnostic settings"
  type        = bool
  default     = true
}

variable "log_analytics_workspace_id" {
  description = "ID of Log Analytics workspace for diagnostics"
  type        = string
  default     = null
}

variable "enable_alerts" {
  description = "Enable metric alerts"
  type        = bool
  default     = true
}

variable "action_group_id" {
  description = "ID of the action group for alerts"
  type        = string
  default     = null
}

variable "cpu_alert_threshold" {
  description = "CPU usage threshold for alerts (percentage)"
  type        = number
  default     = 80

  validation {
    condition     = var.cpu_alert_threshold >= 0 && var.cpu_alert_threshold <= 100
    error_message = "CPU alert threshold must be between 0 and 100."
  }
}

variable "storage_alert_threshold" {
  description = "Storage usage threshold for alerts (percentage)"
  type        = number
  default     = 85

  validation {
    condition     = var.storage_alert_threshold >= 0 && var.storage_alert_threshold <= 100
    error_message = "Storage alert threshold must be between 0 and 100."
  }
}

variable "memory_alert_threshold" {
  description = "Memory usage threshold for alerts (percentage)"
  type        = number
  default     = 85

  validation {
    condition     = var.memory_alert_threshold >= 0 && var.memory_alert_threshold <= 100
    error_message = "Memory alert threshold must be between 0 and 100."
  }
}

# Tags
variable "tags" {
  description = "Tags to apply to database resources"
  type        = map(string)
  default     = {}
}
