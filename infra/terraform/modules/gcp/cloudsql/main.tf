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
    random = {
      source  = "hashicorp/random"
      version = ">= 3.0.0"
    }
  }
}

# Random suffix for instance name to ensure uniqueness
resource "random_id" "db_name_suffix" {
  byte_length = 4
}

# Cloud SQL Instance
resource "google_sql_database_instance" "main" {
  name             = var.use_random_suffix ? "${var.instance_name}-${random_id.db_name_suffix.hex}" : var.instance_name
  database_version = var.database_version
  region           = var.location
  project          = var.project_id

  deletion_protection = var.deletion_protection

  settings {
    tier              = var.tier
    availability_type = var.availability_type
    disk_type         = var.disk_type
    disk_size         = var.disk_size
    disk_autoresize   = var.disk_autoresize
    disk_autoresize_limit = var.disk_autoresize_limit

    # Backup configuration
    backup_configuration {
      enabled                        = var.backup_enabled
      start_time                     = var.backup_start_time
      point_in_time_recovery_enabled = var.point_in_time_recovery_enabled
      transaction_log_retention_days = var.transaction_log_retention_days
      backup_retention_settings {
        retained_backups = var.retained_backups
        retention_unit   = "COUNT"
      }
    }

    # IP configuration
    ip_configuration {
      ipv4_enabled                                  = var.ipv4_enabled
      private_network                               = var.private_network
      enable_private_path_for_google_cloud_services = var.enable_private_path_for_google_cloud_services
      require_ssl                                   = var.require_ssl

      dynamic "authorized_networks" {
        for_each = var.authorized_networks
        content {
          name  = authorized_networks.value.name
          value = authorized_networks.value.value
        }
      }
    }

    # Maintenance window
    maintenance_window {
      day          = var.maintenance_window_day
      hour         = var.maintenance_window_hour
      update_track = var.maintenance_window_update_track
    }

    # Insights configuration
    insights_config {
      query_insights_enabled  = var.query_insights_enabled
      query_plans_per_minute  = var.query_insights_enabled ? var.query_plans_per_minute : null
      query_string_length     = var.query_insights_enabled ? var.query_string_length : null
      record_application_tags = var.query_insights_enabled ? var.record_application_tags : null
    }

    # Database flags
    dynamic "database_flags" {
      for_each = var.database_flags
      content {
        name  = database_flags.value.name
        value = database_flags.value.value
      }
    }

    # User labels
    user_labels = merge(
      var.tags,
      {
        instance = var.instance_name
        cost     = "database"
      }
    )
  }

  lifecycle {
    ignore_changes = [
      settings[0].disk_size,
    ]
  }
}

# Database
resource "google_sql_database" "databases" {
  for_each = toset(var.databases)

  name     = each.value
  instance = google_sql_database_instance.main.name
  project  = var.project_id
}

# Random password for database users
resource "random_password" "user_password" {
  for_each = { for user in var.users : user.name => user if user.password == null }

  length  = 32
  special = true
}

# Database users
resource "google_sql_user" "users" {
  for_each = { for user in var.users : user.name => user }

  name     = each.value.name
  instance = google_sql_database_instance.main.name
  password = each.value.password != null ? each.value.password : random_password.user_password[each.key].result
  project  = var.project_id
  type     = each.value.type
  host     = each.value.host
}

# Read replicas
resource "google_sql_database_instance" "replicas" {
  for_each = { for replica in var.read_replicas : replica.name => replica }

  name                 = each.value.name
  master_instance_name = google_sql_database_instance.main.name
  region               = each.value.region
  project              = var.project_id

  replica_configuration {
    failover_target = each.value.failover_target
  }

  settings {
    tier              = each.value.tier
    availability_type = each.value.availability_type
    disk_type         = var.disk_type
    disk_size         = var.disk_size
    disk_autoresize   = var.disk_autoresize

    ip_configuration {
      ipv4_enabled    = var.ipv4_enabled
      private_network = var.private_network
      require_ssl     = var.require_ssl
    }

    user_labels = merge(
      var.tags,
      {
        instance = each.value.name
        replica  = "true"
        cost     = "database"
      }
    )
  }
}

# Private Service Connection (required for private IP)
resource "google_compute_global_address" "private_ip_address" {
  count = var.private_network != null ? 1 : 0

  name          = "${var.instance_name}-private-ip"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = var.private_network
  project       = var.project_id
}

resource "google_service_networking_connection" "private_vpc_connection" {
  count = var.private_network != null ? 1 : 0

  network                 = var.private_network
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address[0].name]
}
