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

variable "create_credentials" {
  description = "Create object store credentials"
  type        = bool
  default     = true
}
