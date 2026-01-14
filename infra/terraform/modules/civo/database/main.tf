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
  size    = var.database_size
  engine  = var.engine
  version = var.engine_version
  nodes   = var.node_count

  # Network configuration
  network_id = var.network_id

  # Firewall configuration
  firewall_id = var.firewall_id

  # Tags
  tags = join(",", [for k, v in merge(
    var.tags,
    {
      database = var.database_name
      engine   = var.engine
      cost     = "civo-database"
    }
  ) : "${k}:${v}"])

  # Wait for database to be ready
  timeouts {
    create = "30m"
    update = "30m"
    delete = "15m"
  }
}

# Firewall rules for database access
resource "civo_firewall_rule" "database_ingress" {
  for_each = var.create_firewall_rules ? toset(var.allowed_cidr_blocks) : []

  firewall_id = var.firewall_id != null ? var.firewall_id : civo_firewall.database[0].id
  protocol    = "tcp"
  start_port  = local.engine_ports[var.engine]
  end_port    = local.engine_ports[var.engine]
  cidr        = [each.value]
  direction   = "ingress"
  label       = "Allow ${var.engine} from ${each.value}"
}

# Create firewall if not provided
resource "civo_firewall" "database" {
  count = var.firewall_id == null && var.create_firewall_rules ? 1 : 0

  name       = "${var.database_name}-firewall"
  network_id = var.network_id
  region     = var.location

  create_default_rules = false
}

# Local variables for engine-specific configurations
locals {
  engine_ports = {
    "postgres" = 5432
    "mysql"    = 3306
    "redis"    = 6379
  }

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
