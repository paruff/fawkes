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
    google-beta = {
      source  = "hashicorp/google-beta"
      version = ">= 5.0.0"
    }
  }
}

# GKE Cluster
resource "google_container_cluster" "main" {
  provider = google-beta

  name     = var.cluster_name
  location = var.location
  project  = var.project_id

  description = var.cluster_description

  # Cluster mode: Autopilot or Standard
  enable_autopilot = var.enable_autopilot

  # Network configuration
  network    = var.network_id
  subnetwork = var.subnetwork_id

  # IP allocation policy for pods and services
  ip_allocation_policy {
    cluster_secondary_range_name  = var.pods_secondary_range_name
    services_secondary_range_name = var.services_secondary_range_name
  }

  # Remove default node pool
  remove_default_node_pool = var.enable_autopilot ? null : true
  initial_node_count       = var.enable_autopilot ? null : 1

  # Kubernetes version
  min_master_version = var.kubernetes_version

  # Logging and Monitoring
  logging_config {
    enable_components = var.logging_components
  }

  monitoring_config {
    enable_components = var.monitoring_components

    managed_prometheus {
      enabled = var.enable_managed_prometheus
    }
  }

  # Workload Identity
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  # Network policy
  network_policy {
    enabled  = var.enable_network_policy
    provider = var.enable_network_policy ? "PROVIDER_UNSPECIFIED" : null
  }

  # Binary Authorization
  binary_authorization {
    evaluation_mode = var.binary_authorization_mode
  }

  # Dataplane V2
  datapath_provider = var.datapath_provider

  # Private cluster configuration
  dynamic "private_cluster_config" {
    for_each = var.enable_private_cluster ? [1] : []
    content {
      enable_private_endpoint = var.enable_private_endpoint
      enable_private_nodes    = var.enable_private_nodes
      master_ipv4_cidr_block  = var.master_ipv4_cidr_block

      dynamic "master_global_access_config" {
        for_each = var.enable_master_global_access ? [1] : []
        content {
          enabled = true
        }
      }
    }
  }

  # Master authorized networks
  dynamic "master_authorized_networks_config" {
    for_each = length(var.master_authorized_networks) > 0 ? [1] : []
    content {
      dynamic "cidr_blocks" {
        for_each = var.master_authorized_networks
        content {
          cidr_block   = cidr_blocks.value.cidr_block
          display_name = cidr_blocks.value.display_name
        }
      }
    }
  }

  # Maintenance window
  dynamic "maintenance_policy" {
    for_each = var.maintenance_start_time != null ? [1] : []
    content {
      daily_maintenance_window {
        start_time = var.maintenance_start_time
      }
    }
  }

  # Release channel
  release_channel {
    channel = var.release_channel
  }

  # Addons
  addons_config {
    http_load_balancing {
      disabled = !var.enable_http_load_balancing
    }

    horizontal_pod_autoscaling {
      disabled = !var.enable_horizontal_pod_autoscaling
    }

    network_policy_config {
      disabled = !var.enable_network_policy
    }

    gcp_filestore_csi_driver_config {
      enabled = var.enable_filestore_csi_driver
    }

    gce_persistent_disk_csi_driver_config {
      enabled = var.enable_gce_persistent_disk_csi_driver
    }
  }

  # Security posture
  dynamic "security_posture_config" {
    for_each = var.enable_security_posture ? [1] : []
    content {
      mode               = "BASIC"
      vulnerability_mode = var.vulnerability_mode
    }
  }

  # Resource labels
  resource_labels = merge(
    var.tags,
    {
      cluster = var.cluster_name
      cost    = "gke-control-plane"
    }
  )

  lifecycle {
    ignore_changes = [
      # Ignore changes to node pool since we manage it separately
      node_pool,
      initial_node_count,
    ]
  }
}

# Node Pools (only for Standard clusters)
resource "google_container_node_pool" "node_pools" {
  for_each = var.enable_autopilot ? {} : { for pool in var.node_pools : pool.name => pool }

  name     = each.value.name
  location = var.location
  cluster  = google_container_cluster.main.name
  project  = var.project_id

  # Node count and autoscaling
  initial_node_count = each.value.initial_node_count

  dynamic "autoscaling" {
    for_each = each.value.enable_autoscaling ? [1] : []
    content {
      min_node_count       = each.value.min_node_count
      max_node_count       = each.value.max_node_count
      location_policy      = each.value.location_policy
      total_min_node_count = each.value.total_min_node_count
      total_max_node_count = each.value.total_max_node_count
    }
  }

  # Node configuration
  node_config {
    machine_type = each.value.machine_type
    disk_size_gb = each.value.disk_size_gb
    disk_type    = each.value.disk_type
    image_type   = each.value.image_type

    # Service account with minimum required permissions
    service_account = each.value.service_account != null ? each.value.service_account : google_service_account.node_pool[each.key].email
    oauth_scopes    = each.value.oauth_scopes

    # Labels, metadata, and tags
    labels   = merge(var.tags, each.value.labels, { node_pool = each.value.name, cost = "gke-worker-nodes" })
    metadata = each.value.metadata
    tags     = each.value.network_tags

    # Shielded instance configuration
    shielded_instance_config {
      enable_secure_boot          = each.value.enable_secure_boot
      enable_integrity_monitoring = each.value.enable_integrity_monitoring
    }

    # Workload Identity
    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    # Taints
    dynamic "taint" {
      for_each = each.value.taints
      content {
        key    = taint.value.key
        value  = taint.value.value
        effect = taint.value.effect
      }
    }

    # Spot instances
    spot = each.value.spot

    # Node preemptibility
    preemptible = each.value.preemptible
  }

  # Upgrade settings
  management {
    auto_repair  = each.value.auto_repair
    auto_upgrade = each.value.auto_upgrade
  }

  upgrade_settings {
    max_surge       = each.value.max_surge
    max_unavailable = each.value.max_unavailable
    strategy        = each.value.upgrade_strategy
  }

  lifecycle {
    ignore_changes = [
      initial_node_count,
    ]
  }
}

# Service account for node pools
resource "google_service_account" "node_pool" {
  for_each = var.enable_autopilot ? {} : { for pool in var.node_pools : pool.name => pool if pool.service_account == null }

  account_id   = "${var.cluster_name}-${each.value.name}-sa"
  display_name = "Service Account for ${var.cluster_name} ${each.value.name} node pool"
  project      = var.project_id
}

# Grant minimum required permissions to node pool service accounts
resource "google_project_iam_member" "node_pool_logging" {
  for_each = var.enable_autopilot ? {} : { for pool in var.node_pools : pool.name => pool if pool.service_account == null }

  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.node_pool[each.key].email}"
}

resource "google_project_iam_member" "node_pool_monitoring" {
  for_each = var.enable_autopilot ? {} : { for pool in var.node_pools : pool.name => pool if pool.service_account == null }

  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.node_pool[each.key].email}"
}

resource "google_project_iam_member" "node_pool_metadata" {
  for_each = var.enable_autopilot ? {} : { for pool in var.node_pools : pool.name => pool if pool.service_account == null }

  project = var.project_id
  role    = "roles/monitoring.viewer"
  member  = "serviceAccount:${google_service_account.node_pool[each.key].email}"
}

resource "google_project_iam_member" "node_pool_artifact_registry" {
  for_each = var.enable_autopilot ? {} : { for pool in var.node_pools : pool.name => pool if pool.service_account == null }

  project = var.project_id
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${google_service_account.node_pool[each.key].email}"
}
