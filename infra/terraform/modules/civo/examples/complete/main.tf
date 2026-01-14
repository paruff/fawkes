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

# Complete Civo Infrastructure Example
# This example demonstrates all Civo modules working together

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    civo = {
      source  = "civo/civo"
      version = ">= 1.0.0"
    }
  }
}

provider "civo" {
  token  = var.civo_token
  region = var.region
}

# Common tags for all resources
locals {
  common_tags = {
    platform    = "fawkes"
    environment = var.environment
    managed_by  = "terraform"
    cost_center = var.cost_center
  }
}

# 1. Create Network
module "network" {
  source = "../../network"

  network_name = "${var.project_name}-network"
  location     = var.region
  cidr_block   = "10.0.0.0/16"

  create_firewall = true
  firewall_rules = [
    {
      protocol    = "tcp"
      start_port  = 443
      end_port    = 443
      cidr_blocks = ["0.0.0.0/0"]
      direction   = "ingress"
      label       = "Allow HTTPS"
      action      = "allow"
    },
    {
      protocol    = "tcp"
      start_port  = 80
      end_port    = 80
      cidr_blocks = ["0.0.0.0/0"]
      direction   = "ingress"
      label       = "Allow HTTP"
      action      = "allow"
    },
    {
      protocol    = "tcp"
      start_port  = 22
      end_port    = 22
      cidr_blocks = [var.admin_cidr]
      direction   = "ingress"
      label       = "Allow SSH from admin"
      action      = "allow"
    }
  ]

  tags = local.common_tags
}

# 2. Create Kubernetes Cluster
module "kubernetes" {
  source = "../../kubernetes"

  cluster_name = "${var.project_name}-cluster"
  location     = var.region

  # Use size preset for simplicity
  size_preset = var.cluster_size

  kubernetes_version = var.kubernetes_version
  cni_plugin         = "flannel"

  network_id  = module.network.network_id
  firewall_id = module.network.firewall_id

  # Install marketplace apps
  marketplace_apps = [
    {
      name    = "metrics-server"
      version = null
    },
    {
      name    = "cert-manager"
      version = null
    }
  ]

  tags = local.common_tags

  depends_on = [module.network]
}

# 3. Create PostgreSQL Database
module "database" {
  source = "../../database"

  database_name = "${var.project_name}-db"
  location      = var.region
  engine        = "postgres"
  engine_version = "14"

  # Use size preset
  size_preset = var.database_size

  network_id  = module.network.network_id
  firewall_id = module.network.firewall_id

  # Allow access from Kubernetes cluster CIDR
  allowed_cidr_blocks = [module.network.network_cidr]

  backup_enabled          = true
  backup_retention_days   = 7

  tags = local.common_tags

  depends_on = [module.network]
}

# 4. Create Object Storage
module "objectstore" {
  source = "../../objectstore"

  bucket_name  = "${var.project_name}-storage"
  location     = var.region
  max_size_gb  = 500

  create_credentials = true

  # Enable CORS for web applications
  enable_cors          = true
  cors_allowed_origins = ["https://*.${var.domain}"]
  cors_allowed_methods = ["GET", "POST", "PUT", "DELETE"]

  enable_versioning = true
  enable_encryption = true

  tags = local.common_tags
}
