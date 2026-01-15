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

# Civo Database Cluster
resource "civo_database" "main" {
  name    = var.database_name
  region  = var.location
  size    = local.effective_size
  engine  = var.engine
  version = var.engine_version
  nodes   = local.effective_node_count

  # Network configuration
  network_id = var.network_id

  # Wait for database to be ready
  timeouts {
    create = "30m"
    update = "30m"
    delete = "15m"
  }
}

# Local variables for size presets
locals {
  size_presets = {
    small = {
      size  = "g3.db.small"
      nodes = 1
    }
    medium = {
      size  = "g3.db.medium"
      nodes = 2
    }
    large = {
      size  = "g3.db.large"
      nodes = 3
    }
  }

  # Use preset if specified, otherwise use explicit values
  effective_size       = var.size_preset != null ? local.size_presets[var.size_preset].size : var.database_size
  effective_node_count = var.size_preset != null ? local.size_presets[var.size_preset].nodes : var.node_count
}
