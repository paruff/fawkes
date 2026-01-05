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

# GCP Cloud Storage module variables

variable "bucket_name" {
  description = "Name of the Cloud Storage bucket (must be globally unique)"
  type        = string

  validation {
    condition     = length(var.bucket_name) >= 3 && length(var.bucket_name) <= 63
    error_message = "Bucket name must be between 3 and 63 characters."
  }

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9._-]*[a-z0-9]$", var.bucket_name))
    error_message = "Bucket name must start and end with a number or letter, and contain only lowercase letters, numbers, hyphens, underscores, and periods."
  }
}

variable "location" {
  description = "GCS bucket location (region or multi-region)"
  type        = string
}

variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "storage_class" {
  description = "Storage class for the bucket"
  type        = string
  default     = "STANDARD"

  validation {
    condition     = contains(["STANDARD", "NEARLINE", "COLDLINE", "ARCHIVE"], var.storage_class)
    error_message = "Storage class must be STANDARD, NEARLINE, COLDLINE, or ARCHIVE."
  }
}

variable "uniform_bucket_level_access" {
  description = "Enable uniform bucket-level access"
  type        = bool
  default     = true
}

variable "force_destroy" {
  description = "Allow bucket to be destroyed even if it contains objects"
  type        = bool
  default     = false
}

variable "enable_versioning" {
  description = "Enable object versioning"
  type        = bool
  default     = true
}

variable "kms_key_name" {
  description = "Cloud KMS key name for encryption (null for Google-managed encryption)"
  type        = string
  default     = null
}

variable "lifecycle_rules" {
  description = "List of lifecycle rules"
  type = list(object({
    action_type                           = string
    storage_class                         = optional(string, null)
    condition_age                         = optional(number, null)
    condition_created_before              = optional(string, null)
    condition_with_state                  = optional(string, null)
    condition_matches_storage_class       = optional(list(string), null)
    condition_num_newer_versions          = optional(number, null)
    condition_days_since_custom_time      = optional(number, null)
    condition_days_since_noncurrent_time  = optional(number, null)
    condition_matches_prefix              = optional(list(string), null)
    condition_matches_suffix              = optional(list(string), null)
  }))
  default = []

  validation {
    condition = alltrue([
      for rule in var.lifecycle_rules :
      contains(["Delete", "SetStorageClass", "AbortIncompleteMultipartUpload"], rule.action_type)
    ])
    error_message = "Lifecycle rule action_type must be Delete, SetStorageClass, or AbortIncompleteMultipartUpload."
  }
}

variable "cors_rules" {
  description = "List of CORS rules"
  type = list(object({
    origins          = list(string)
    methods          = list(string)
    response_headers = list(string)
    max_age_seconds  = number
  }))
  default = []
}

variable "enable_logging" {
  description = "Enable access logging to a separate bucket"
  type        = bool
  default     = true
}

variable "log_object_prefix" {
  description = "Prefix for log objects"
  type        = string
  default     = "log/"
}

variable "public_access_prevention" {
  description = "Public access prevention setting"
  type        = string
  default     = "enforced"

  validation {
    condition     = contains(["inherited", "enforced"], var.public_access_prevention)
    error_message = "Public access prevention must be inherited or enforced."
  }
}

variable "retention_policy_retention_period" {
  description = "Retention period in seconds (null to disable)"
  type        = number
  default     = null

  validation {
    condition     = var.retention_policy_retention_period == null || var.retention_policy_retention_period >= 0
    error_message = "Retention period must be null or a non-negative number."
  }
}

variable "retention_policy_is_locked" {
  description = "Lock the retention policy (cannot be unlocked)"
  type        = bool
  default     = false
}

variable "website_main_page_suffix" {
  description = "Main page suffix for website hosting (null to disable)"
  type        = string
  default     = null
}

variable "website_not_found_page" {
  description = "Not found page for website hosting"
  type        = string
  default     = null
}

variable "iam_bindings" {
  description = "IAM bindings (replaces all existing bindings for the role)"
  type = list(object({
    role    = string
    members = list(string)
    condition = optional(object({
      title       = string
      description = string
      expression  = string
    }), null)
  }))
  default = []
}

variable "iam_members" {
  description = "IAM members (adds members to existing bindings)"
  type = list(object({
    role   = string
    member = string
    condition = optional(object({
      title       = string
      description = string
      expression  = string
    }), null)
  }))
  default = []
}

variable "bucket_acl" {
  description = "Bucket ACL (only used if uniform_bucket_level_access is false)"
  type = list(object({
    entity = string
    role   = string
  }))
  default = []

  validation {
    condition = alltrue([
      for acl in var.bucket_acl :
      contains(["OWNER", "READER", "WRITER"], acl.role)
    ])
    error_message = "Bucket ACL role must be OWNER, READER, or WRITER."
  }
}

variable "tags" {
  description = "Labels to apply to storage resources"
  type        = map(string)
  default     = {}
}
