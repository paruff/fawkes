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

provider "google" {
  project = var.project_id
  region  = var.region
}

module "gcs" {
  source = "../../gcs"

  bucket_name                 = var.bucket_name
  location                    = var.location
  project_id                  = var.project_id
  storage_class               = var.storage_class
  uniform_bucket_level_access = true
  force_destroy               = var.force_destroy

  enable_versioning = true
  kms_key_name      = var.kms_key_name

  lifecycle_rules = [
    {
      action_type                      = "SetStorageClass"
      storage_class                    = "NEARLINE"
      condition_age                    = 30
      condition_matches_storage_class  = ["STANDARD"]
    },
    {
      action_type                      = "SetStorageClass"
      storage_class                    = "COLDLINE"
      condition_age                    = 90
      condition_matches_storage_class  = ["NEARLINE"]
    },
    {
      action_type                      = "Delete"
      condition_age                    = 365
    }
  ]

  cors_rules = var.enable_cors ? [
    {
      origins          = ["*"]
      methods          = ["GET", "HEAD"]
      response_headers = ["*"]
      max_age_seconds  = 3600
    }
  ] : []

  enable_logging    = true
  log_object_prefix = "log/"

  public_access_prevention = "enforced"

  iam_members = var.iam_members

  tags = {
    platform    = "fawkes"
    environment = "example"
    managed_by  = "terraform"
  }
}
