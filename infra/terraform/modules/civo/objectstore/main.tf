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
    civo = {
      source  = "civo/civo"
      version = ">= 1.0.0"
    }
  }
}

# Civo Object Store (S3-compatible)
resource "civo_object_store" "main" {
  name              = var.bucket_name
  region            = var.location
  max_size_gb       = var.max_size_gb
  access_key_id     = var.access_key_id != null ? var.access_key_id : null
  secret_access_key = var.secret_access_key != null ? var.secret_access_key : null

  # Tags
  tags = join(",", [for k, v in merge(
    var.tags,
    {
      bucket = var.bucket_name
      cost   = "civo-object-store"
    }
  ) : "${k}:${v}"])

  # Wait for object store to be ready
  timeouts {
    create = "10m"
    update = "10m"
    delete = "10m"
  }
}

# Object Store Credentials (if not provided)
resource "civo_object_store_credential" "main" {
  count = var.create_credentials ? 1 : 0

  name   = "${var.bucket_name}-credentials"
  region = var.location

  access_key_id     = civo_object_store.main.access_key_id
  secret_access_key = civo_object_store.main.secret_access_key
}

# Local variables for CORS configuration
locals {
  default_cors_rules = var.enable_cors ? [
    {
      allowed_origins = var.cors_allowed_origins
      allowed_methods = var.cors_allowed_methods
      allowed_headers = var.cors_allowed_headers
      max_age_seconds = var.cors_max_age_seconds
    }
  ] : []
}
