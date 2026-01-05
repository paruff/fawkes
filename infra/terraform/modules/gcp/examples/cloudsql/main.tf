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

module "cloudsql" {
  source = "../../cloudsql"

  instance_name      = var.instance_name
  use_random_suffix  = true
  location           = var.region
  project_id         = var.project_id
  database_version   = var.database_version

  tier               = var.tier
  availability_type  = var.availability_type
  disk_type          = "PD_SSD"
  disk_size          = 20
  disk_autoresize    = true
  disk_autoresize_limit = 100

  deletion_protection = false

  backup_enabled                  = true
  backup_start_time               = "03:00"
  point_in_time_recovery_enabled  = true
  transaction_log_retention_days  = 7
  retained_backups                = 7

  ipv4_enabled                                  = false
  private_network                               = var.private_network
  enable_private_path_for_google_cloud_services = true
  require_ssl                                   = true

  authorized_networks = []

  maintenance_window_day          = 7
  maintenance_window_hour         = 3
  maintenance_window_update_track = "stable"

  query_insights_enabled  = true
  query_plans_per_minute  = 5
  query_string_length     = 1024
  record_application_tags = false

  database_flags = var.database_flags

  databases = var.databases

  users = var.users

  read_replicas = []

  tags = {
    platform    = "fawkes"
    environment = "example"
    managed_by  = "terraform"
  }
}
