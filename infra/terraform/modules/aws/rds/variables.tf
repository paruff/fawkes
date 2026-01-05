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

# AWS RDS module variables

variable "identifier" {
  description = "The name of the RDS instance"
  type        = string

  validation {
    condition     = length(var.identifier) >= 1 && length(var.identifier) <= 63
    error_message = "Identifier must be between 1 and 63 characters."
  }

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]*[a-z0-9]$", var.identifier))
    error_message = "Identifier must start with a letter, end with alphanumeric, and contain only lowercase alphanumerics and hyphens."
  }
}

variable "vpc_id" {
  description = "ID of the VPC where RDS will be created"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the DB subnet group"
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) >= 2
    error_message = "At least 2 subnets must be specified for high availability."
  }
}

variable "engine" {
  description = "Database engine type"
  type        = string

  validation {
    condition     = contains(["postgres", "mysql"], var.engine)
    error_message = "Engine must be either 'postgres' or 'mysql'."
  }
}

variable "engine_version" {
  description = "Database engine version"
  type        = string
}

variable "instance_class" {
  description = "The instance class to use"
  type        = string
  default     = "db.t3.micro"

  validation {
    condition     = can(regex("^db\\.[a-z0-9]+\\.[a-z0-9]+$", var.instance_class))
    error_message = "Instance class must be a valid RDS instance class (e.g., db.t3.micro)."
  }
}

variable "allocated_storage" {
  description = "The allocated storage in gigabytes"
  type        = number
  default     = 20

  validation {
    condition     = var.allocated_storage >= 20 && var.allocated_storage <= 65536
    error_message = "Allocated storage must be between 20 and 65536 GB."
  }
}

variable "max_allocated_storage" {
  description = "Maximum storage threshold for autoscaling (0 to disable)"
  type        = number
  default     = 100

  validation {
    condition     = var.max_allocated_storage == 0 || (var.max_allocated_storage >= 20 && var.max_allocated_storage <= 65536)
    error_message = "Max allocated storage must be 0 or between 20 and 65536 GB."
  }
}

variable "storage_type" {
  description = "Storage type for RDS instance"
  type        = string
  default     = "gp3"

  validation {
    condition     = contains(["standard", "gp2", "gp3", "io1", "io2"], var.storage_type)
    error_message = "Storage type must be one of: standard, gp2, gp3, io1, io2."
  }
}

variable "storage_encrypted" {
  description = "Enable storage encryption"
  type        = bool
  default     = true
}

variable "kms_key_id" {
  description = "ARN of KMS key for storage encryption (uses default if not specified)"
  type        = string
  default     = null
}

variable "iops" {
  description = "Amount of provisioned IOPS (only for io1/io2 storage types)"
  type        = number
  default     = null
}

variable "database_name" {
  description = "Name of the default database to create"
  type        = string
  default     = null

  validation {
    condition     = var.database_name == null || can(regex("^[a-zA-Z][a-zA-Z0-9_]*$", var.database_name))
    error_message = "Database name must start with a letter and contain only alphanumerics and underscores."
  }
}

variable "master_username" {
  description = "Master username for the database"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9_]*$", var.master_username))
    error_message = "Master username must start with a letter and contain only alphanumerics and underscores."
  }
}

variable "master_password" {
  description = "Master password (leave null to auto-generate)"
  type        = string
  default     = null
  sensitive   = true
}

variable "port" {
  description = "Port for database connections"
  type        = number
  default     = null

  validation {
    condition     = var.port == null || (var.port >= 1024 && var.port <= 65535)
    error_message = "Port must be between 1024 and 65535."
  }
}

variable "multi_az" {
  description = "Enable Multi-AZ deployment for high availability"
  type        = bool
  default     = false
}

variable "publicly_accessible" {
  description = "Make the database publicly accessible"
  type        = bool
  default     = false
}

variable "parameter_group_family" {
  description = "Database parameter group family"
  type        = string
}

variable "parameters" {
  description = "List of database parameters to apply"
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

variable "backup_retention_period" {
  description = "Days to retain backups"
  type        = number
  default     = 7

  validation {
    condition     = var.backup_retention_period >= 0 && var.backup_retention_period <= 35
    error_message = "Backup retention period must be between 0 and 35 days."
  }
}

variable "backup_window" {
  description = "Preferred backup window (UTC)"
  type        = string
  default     = "03:00-04:00"

  validation {
    condition     = can(regex("^[0-9]{2}:[0-9]{2}-[0-9]{2}:[0-9]{2}$", var.backup_window))
    error_message = "Backup window must be in format HH:MM-HH:MM."
  }
}

variable "maintenance_window" {
  description = "Preferred maintenance window"
  type        = string
  default     = "sun:04:00-sun:05:00"

  validation {
    condition     = can(regex("^(mon|tue|wed|thu|fri|sat|sun):[0-9]{2}:[0-9]{2}-(mon|tue|wed|thu|fri|sat|sun):[0-9]{2}:[0-9]{2}$", var.maintenance_window))
    error_message = "Maintenance window must be in format ddd:HH:MM-ddd:HH:MM."
  }
}

variable "skip_final_snapshot" {
  description = "Skip final snapshot when destroying"
  type        = bool
  default     = false
}

variable "enabled_cloudwatch_logs_exports" {
  description = "List of log types to export to CloudWatch"
  type        = list(string)
  default     = []
}

variable "monitoring_interval" {
  description = "Interval for enhanced monitoring (0 to disable, 1, 5, 10, 15, 30, 60)"
  type        = number
  default     = 0

  validation {
    condition     = contains([0, 1, 5, 10, 15, 30, 60], var.monitoring_interval)
    error_message = "Monitoring interval must be 0, 1, 5, 10, 15, 30, or 60 seconds."
  }
}

variable "performance_insights_enabled" {
  description = "Enable Performance Insights"
  type        = bool
  default     = false
}

variable "performance_insights_retention_period" {
  description = "Days to retain Performance Insights data"
  type        = number
  default     = 7

  validation {
    condition     = contains([7, 731], var.performance_insights_retention_period)
    error_message = "Performance Insights retention must be 7 or 731 days."
  }
}

variable "performance_insights_kms_key_id" {
  description = "KMS key ID for Performance Insights encryption"
  type        = string
  default     = null
}

variable "auto_minor_version_upgrade" {
  description = "Enable automatic minor version upgrades"
  type        = bool
  default     = true
}

variable "deletion_protection" {
  description = "Enable deletion protection"
  type        = bool
  default     = true
}

variable "allowed_security_group_ids" {
  description = "List of security group IDs allowed to access the database"
  type        = list(string)
  default     = []
}

variable "allowed_cidr_blocks" {
  description = "List of CIDR blocks allowed to access the database"
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for cidr in var.allowed_cidr_blocks :
      can(cidrhost(cidr, 0))
    ])
    error_message = "All CIDR blocks must be valid."
  }
}

variable "create_cloudwatch_alarms" {
  description = "Create CloudWatch alarms for monitoring"
  type        = bool
  default     = true
}

variable "cpu_utilization_threshold" {
  description = "CPU utilization threshold for CloudWatch alarm"
  type        = number
  default     = 80

  validation {
    condition     = var.cpu_utilization_threshold >= 0 && var.cpu_utilization_threshold <= 100
    error_message = "CPU utilization threshold must be between 0 and 100."
  }
}

variable "database_connections_threshold" {
  description = "Database connections threshold for CloudWatch alarm"
  type        = number
  default     = 100

  validation {
    condition     = var.database_connections_threshold > 0
    error_message = "Database connections threshold must be greater than 0."
  }
}

variable "free_storage_space_threshold" {
  description = "Free storage space threshold in bytes for CloudWatch alarm"
  type        = number
  default     = 5000000000

  validation {
    condition     = var.free_storage_space_threshold > 0
    error_message = "Free storage space threshold must be greater than 0."
  }
}

variable "alarm_actions" {
  description = "List of ARNs to notify when alarm triggers"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags to apply to RDS resources"
  type        = map(string)
  default     = {}
}
