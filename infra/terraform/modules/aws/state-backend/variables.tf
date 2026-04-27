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
  description = "Name of the project, used as a prefix for all state backend resource names (e.g. 'fawkes')."
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

variable "aws_region" {
  description = "AWS region where the state backend resources will be created (e.g. 'us-east-1')."
  type        = string
}

variable "enable_kms_encryption" {
  description = "When true, create a dedicated KMS key and use it for S3 and DynamoDB encryption. When false, use AWS-managed SSE-S3 (AES-256)."
  type        = bool
  default     = true
}

variable "state_bucket_name" {
  description = "Override for the S3 bucket name. Defaults to '<project_name>-tfstate-<environment>' when null."
  type        = string
  default     = null

  validation {
    condition     = var.state_bucket_name == null || (length(var.state_bucket_name) >= 3 && length(var.state_bucket_name) <= 63)
    error_message = "state_bucket_name must be between 3 and 63 characters when provided."
  }
}

variable "dynamodb_table_name" {
  description = "Override for the DynamoDB lock table name. Defaults to '<project_name>-tfstate-lock-<environment>' when null."
  type        = string
  default     = null
}

variable "versioning_expiration_days" {
  description = "Number of days to retain non-current (old) state file versions before expiring them."
  type        = number
  default     = 90

  validation {
    condition     = var.versioning_expiration_days >= 7
    error_message = "versioning_expiration_days must be at least 7 days."
  }
}

variable "tags" {
  description = "Additional tags to apply to all state backend resources. Merged with mandatory Project, Environment, ManagedBy, and Component tags."
  type        = map(string)
  default     = {}
}
