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

# GCP Cloud SQL module variables

variable "instance_name" {
  description = "Name of the Cloud SQL instance"
  type        = string

  validation {
    condition     = length(var.instance_name) >= 1 && length(var.instance_name) <= 84
    error_message = "Instance name must be between 1 and 84 characters."
  }

  validation {
    condition     = can(regex("^[a-z]([-a-z0-9]*[a-z0-9])?$", var.instance_name))
    error_message = "Instance name must start with a lowercase letter, followed by lowercase letters, numbers, or hyphens."
  }
}

variable "use_random_suffix" {
  description = "Add random suffix to instance name for uniqueness"
  type        = bool
  default     = true
}

variable "location" {
  description = "GCP region for the Cloud SQL instance"
  type        = string
}

variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "database_version" {
  description = "Database version (e.g., POSTGRES_15, MYSQL_8_0)"
  type        = string

  validation {
    condition     = can(regex("^(POSTGRES|MYSQL)_[0-9]+(_[0-9]+)?$", var.database_version))
    error_message = "Database version must be in format POSTGRES_XX or MYSQL_XX."
  }
}

variable "tier" {
  description = "Machine tier for the instance"
  type        = string
  default     = "db-f1-micro"
}

variable "availability_type" {
  description = "Availability type (REGIONAL or ZONAL)"
  type        = string
  default     = "REGIONAL"

  validation {
    condition     = contains(["REGIONAL", "ZONAL"], var.availability_type)
    error_message = "Availability type must be REGIONAL or ZONAL."
  }
}

variable "disk_type" {
  description = "Type of disk (PD_SSD or PD_HDD)"
  type        = string
  default     = "PD_SSD"

  validation {
    condition     = contains(["PD_SSD", "PD_HDD"], var.disk_type)
    error_message = "Disk type must be PD_SSD or PD_HDD."
  }
}

variable "disk_size" {
  description = "Disk size in GB"
  type        = number
  default     = 10

  validation {
    condition     = var.disk_size >= 10 && var.disk_size <= 65536
    error_message = "Disk size must be between 10 and 65536 GB."
  }
}

variable "disk_autoresize" {
  description = "Enable automatic disk size increase"
  type        = bool
  default     = true
}

variable "disk_autoresize_limit" {
  description = "Maximum disk size in GB for autoresize (0 for unlimited)"
  type        = number
  default     = 0

  validation {
    condition     = var.disk_autoresize_limit == 0 || var.disk_autoresize_limit >= 10
    error_message = "Disk autoresize limit must be 0 (unlimited) or at least 10 GB."
  }
}

variable "deletion_protection" {
  description = "Enable deletion protection"
  type        = bool
  default     = true
}

variable "backup_enabled" {
  description = "Enable automated backups"
  type        = bool
  default     = true
}

variable "backup_start_time" {
  description = "Start time for daily backups (HH:MM format)"
  type        = string
  default     = "03:00"

  validation {
    condition     = can(regex("^([0-1][0-9]|2[0-3]):[0-5][0-9]$", var.backup_start_time))
    error_message = "Backup start time must be in HH:MM format."
  }
}

variable "point_in_time_recovery_enabled" {
  description = "Enable point-in-time recovery"
  type        = bool
  default     = true
}

variable "transaction_log_retention_days" {
  description = "Number of days to retain transaction logs"
  type        = number
  default     = 7

  validation {
    condition     = var.transaction_log_retention_days >= 1 && var.transaction_log_retention_days <= 35
    error_message = "Transaction log retention must be between 1 and 35 days."
  }
}

variable "retained_backups" {
  description = "Number of backups to retain"
  type        = number
  default     = 7

  validation {
    condition     = var.retained_backups >= 1 && var.retained_backups <= 365
    error_message = "Retained backups must be between 1 and 365."
  }
}

variable "ipv4_enabled" {
  description = "Enable public IP"
  type        = bool
  default     = false
}

variable "private_network" {
  description = "VPC network ID for private IP"
  type        = string
  default     = null
}

variable "enable_private_path_for_google_cloud_services" {
  description = "Enable private path for Google Cloud services"
  type        = bool
  default     = true
}

variable "require_ssl" {
  description = "Require SSL for connections"
  type        = bool
  default     = true
}

variable "authorized_networks" {
  description = "List of authorized networks for public IP access"
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

variable "maintenance_window_day" {
  description = "Day of week for maintenance (1-7, 1 = Monday)"
  type        = number
  default     = 7

  validation {
    condition     = var.maintenance_window_day >= 1 && var.maintenance_window_day <= 7
    error_message = "Maintenance window day must be between 1 and 7."
  }
}

variable "maintenance_window_hour" {
  description = "Hour of day for maintenance (0-23)"
  type        = number
  default     = 3

  validation {
    condition     = var.maintenance_window_hour >= 0 && var.maintenance_window_hour <= 23
    error_message = "Maintenance window hour must be between 0 and 23."
  }
}

variable "maintenance_window_update_track" {
  description = "Update track for maintenance (canary or stable)"
  type        = string
  default     = "stable"

  validation {
    condition     = contains(["canary", "stable"], var.maintenance_window_update_track)
    error_message = "Maintenance window update track must be canary or stable."
  }
}

variable "query_insights_enabled" {
  description = "Enable Query Insights"
  type        = bool
  default     = true
}

variable "query_plans_per_minute" {
  description = "Number of query plans to capture per minute"
  type        = number
  default     = 5

  validation {
    condition     = var.query_plans_per_minute >= 0 && var.query_plans_per_minute <= 20
    error_message = "Query plans per minute must be between 0 and 20."
  }
}

variable "query_string_length" {
  description = "Maximum query string length to log"
  type        = number
  default     = 1024

  validation {
    condition     = var.query_string_length >= 256 && var.query_string_length <= 4500
    error_message = "Query string length must be between 256 and 4500."
  }
}

variable "record_application_tags" {
  description = "Record application tags in Query Insights"
  type        = bool
  default     = false
}

variable "database_flags" {
  description = "Database-specific flags for tuning"
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

variable "databases" {
  description = "List of databases to create"
  type        = list(string)
  default     = []
}

variable "users" {
  description = "List of database users to create"
  type = list(object({
    name     = string
    password = optional(string, null)
    type     = optional(string, "BUILT_IN")
    host     = optional(string, "%")
  }))
  default = []
}

variable "read_replicas" {
  description = "List of read replicas to create"
  type = list(object({
    name              = string
    region            = string
    tier              = string
    availability_type = optional(string, "ZONAL")
    failover_target   = optional(bool, false)
  }))
  default = []
}

variable "tags" {
  description = "Labels to apply to Cloud SQL resources"
  type        = map(string)
  default     = {}
}
