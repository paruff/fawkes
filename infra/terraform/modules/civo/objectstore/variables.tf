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

# Civo Object Store module variables

variable "bucket_name" {
  description = "Name of the S3-compatible bucket"
  type        = string

  validation {
    condition     = length(var.bucket_name) >= 3 && length(var.bucket_name) <= 63
    error_message = "Bucket name must be between 3 and 63 characters."
  }

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]*[a-z0-9]$", var.bucket_name))
    error_message = "Bucket name must start and end with lowercase letter or number, and contain only lowercase letters, numbers, and hyphens."
  }
}

variable "location" {
  description = "Civo region for the object store (NYC1, LON1, FRA1, PHX1)"
  type        = string

  validation {
    condition     = contains(["NYC1", "LON1", "FRA1", "PHX1"], var.location)
    error_message = "Location must be one of: NYC1, LON1, FRA1, PHX1."
  }
}

variable "max_size_gb" {
  description = "Maximum size of the object store in GB"
  type        = number
  default     = 500

  validation {
    condition     = var.max_size_gb >= 1 && var.max_size_gb <= 10000
    error_message = "Max size must be between 1 and 10000 GB."
  }
}

variable "access_key_id" {
  description = "S3 access key ID (optional, generated if not provided)"
  type        = string
  default     = null
  sensitive   = true
}

variable "secret_access_key" {
  description = "S3 secret access key (optional, generated if not provided)"
  type        = string
  default     = null
  sensitive   = true
}

variable "create_credentials" {
  description = "Create object store credentials"
  type        = bool
  default     = true
}

variable "enable_cors" {
  description = "Enable CORS configuration"
  type        = bool
  default     = false
}

variable "cors_allowed_origins" {
  description = "List of allowed origins for CORS"
  type        = list(string)
  default     = ["*"]

  validation {
    condition     = length(var.cors_allowed_origins) > 0
    error_message = "At least one allowed origin must be specified when CORS is enabled."
  }
}

variable "cors_allowed_methods" {
  description = "List of allowed HTTP methods for CORS"
  type        = list(string)
  default     = ["GET", "POST", "PUT", "DELETE", "HEAD"]

  validation {
    condition = alltrue([
      for method in var.cors_allowed_methods :
      contains(["GET", "POST", "PUT", "DELETE", "HEAD", "PATCH"], method)
    ])
    error_message = "Allowed methods must be valid HTTP methods."
  }
}

variable "cors_allowed_headers" {
  description = "List of allowed headers for CORS"
  type        = list(string)
  default     = ["*"]

  validation {
    condition     = length(var.cors_allowed_headers) > 0
    error_message = "At least one allowed header must be specified when CORS is enabled."
  }
}

variable "cors_max_age_seconds" {
  description = "Max age in seconds for CORS preflight cache"
  type        = number
  default     = 3600

  validation {
    condition     = var.cors_max_age_seconds >= 0 && var.cors_max_age_seconds <= 86400
    error_message = "CORS max age must be between 0 and 86400 seconds (24 hours)."
  }
}

variable "enable_versioning" {
  description = "Enable object versioning"
  type        = bool
  default     = false
}

variable "enable_encryption" {
  description = "Enable server-side encryption"
  type        = bool
  default     = true
}

variable "lifecycle_rules" {
  description = "Lifecycle rules for object management"
  type = list(object({
    id                     = string
    enabled                = bool
    prefix                 = optional(string, "")
    expiration_days        = optional(number, null)
    transition_days        = optional(number, null)
    transition_storage_class = optional(string, null)
  }))
  default = []
}

variable "tags" {
  description = "Tags to apply to object store resources"
  type        = map(string)
  default     = {}
}
