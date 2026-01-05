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

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.0.0"
    }
  }
}

# Cloud Storage Bucket
resource "google_storage_bucket" "main" {
  name     = var.bucket_name
  location = var.location
  project  = var.project_id

  storage_class               = var.storage_class
  uniform_bucket_level_access = var.uniform_bucket_level_access
  force_destroy               = var.force_destroy

  # Versioning
  versioning {
    enabled = var.enable_versioning
  }

  # Encryption
  encryption {
    default_kms_key_name = var.kms_key_name
  }

  # Lifecycle rules
  dynamic "lifecycle_rule" {
    for_each = var.lifecycle_rules
    content {
      action {
        type          = lifecycle_rule.value.action_type
        storage_class = lifecycle_rule.value.action_type == "SetStorageClass" ? lifecycle_rule.value.storage_class : null
      }

      condition {
        age                        = lifecycle_rule.value.condition_age
        created_before             = lifecycle_rule.value.condition_created_before
        with_state                 = lifecycle_rule.value.condition_with_state
        matches_storage_class      = lifecycle_rule.value.condition_matches_storage_class
        num_newer_versions         = lifecycle_rule.value.condition_num_newer_versions
        days_since_custom_time     = lifecycle_rule.value.condition_days_since_custom_time
        days_since_noncurrent_time = lifecycle_rule.value.condition_days_since_noncurrent_time
        matches_prefix             = lifecycle_rule.value.condition_matches_prefix
        matches_suffix             = lifecycle_rule.value.condition_matches_suffix
      }
    }
  }

  # CORS configuration
  dynamic "cors" {
    for_each = var.cors_rules
    content {
      origin          = cors.value.origins
      method          = cors.value.methods
      response_header = cors.value.response_headers
      max_age_seconds = cors.value.max_age_seconds
    }
  }

  # Logging
  dynamic "logging" {
    for_each = var.enable_logging ? [1] : []
    content {
      log_bucket        = google_storage_bucket.logs[0].name
      log_object_prefix = var.log_object_prefix
    }
  }

  # Public access prevention
  public_access_prevention = var.public_access_prevention

  # Retention policy
  dynamic "retention_policy" {
    for_each = var.retention_policy_retention_period != null ? [1] : []
    content {
      is_locked        = var.retention_policy_is_locked
      retention_period = var.retention_policy_retention_period
    }
  }

  # Website configuration
  dynamic "website" {
    for_each = var.website_main_page_suffix != null ? [1] : []
    content {
      main_page_suffix = var.website_main_page_suffix
      not_found_page   = var.website_not_found_page
    }
  }

  # Labels
  labels = merge(
    var.tags,
    {
      bucket = var.bucket_name
      cost   = "storage"
    }
  )
}

# Logging bucket
resource "google_storage_bucket" "logs" {
  count = var.enable_logging ? 1 : 0

  name                        = "${var.bucket_name}-logs"
  location                    = var.location
  project                     = var.project_id
  storage_class               = "STANDARD"
  uniform_bucket_level_access = true
  force_destroy               = var.force_destroy

  public_access_prevention = "enforced"

  labels = merge(
    var.tags,
    {
      bucket = "${var.bucket_name}-logs"
      cost   = "logging"
    }
  )
}

# IAM bindings
resource "google_storage_bucket_iam_binding" "bindings" {
  for_each = { for binding in var.iam_bindings : binding.role => binding }

  bucket  = google_storage_bucket.main.name
  role    = each.value.role
  members = each.value.members

  dynamic "condition" {
    for_each = each.value.condition != null ? [each.value.condition] : []
    content {
      title       = condition.value.title
      description = condition.value.description
      expression  = condition.value.expression
    }
  }
}

# IAM members
resource "google_storage_bucket_iam_member" "members" {
  for_each = { for idx, member in var.iam_members : "${member.role}-${member.member}-${idx}" => member }

  bucket = google_storage_bucket.main.name
  role   = each.value.role
  member = each.value.member

  dynamic "condition" {
    for_each = each.value.condition != null ? [each.value.condition] : []
    content {
      title       = condition.value.title
      description = condition.value.description
      expression  = condition.value.expression
    }
  }
}

# Object ACL (if not using uniform bucket-level access)
resource "google_storage_bucket_access_control" "bucket_acl" {
  for_each = var.uniform_bucket_level_access ? {} : { for acl in var.bucket_acl : acl.entity => acl }

  bucket = google_storage_bucket.main.name
  entity = each.value.entity
  role   = each.value.role
}
