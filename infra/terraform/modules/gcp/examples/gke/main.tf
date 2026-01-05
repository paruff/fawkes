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

provider "google" {
  project = var.project_id
  region  = var.region
}

provider "google-beta" {
  project = var.project_id
  region  = var.region
}

# First create VPC
module "vpc" {
  source = "../../vpc"

  network_name = var.network_name
  location     = var.region
  project_id   = var.project_id

  subnets = [
    {
      name                            = "${var.network_name}-gke-subnet"
      ip_cidr_range                   = "10.0.0.0/24"
      description                     = "Subnet for GKE cluster"
      enable_private_ip_google_access = true
      purpose                         = "PRIVATE"
      secondary_ip_ranges = [
        {
          range_name    = "gke-pods"
          ip_cidr_range = "10.1.0.0/16"
        },
        {
          range_name    = "gke-services"
          ip_cidr_range = "10.2.0.0/20"
        }
      ]
    }
  ]

  enable_nat_gateway = true

  tags = {
    platform    = "fawkes"
    environment = "example"
  }
}

# Then create GKE cluster
module "gke" {
  source = "../../gke"

  cluster_name        = var.cluster_name
  location            = var.region
  project_id          = var.project_id
  cluster_description = "Example GKE cluster for Fawkes platform"

  enable_autopilot = var.enable_autopilot

  network_id    = module.vpc.network_id
  subnetwork_id = module.vpc.subnet_ids["${var.network_name}-gke-subnet"]

  pods_secondary_range_name     = "gke-pods"
  services_secondary_range_name = "gke-services"

  kubernetes_version = var.kubernetes_version

  logging_components   = ["SYSTEM_COMPONENTS", "WORKLOADS"]
  monitoring_components = ["SYSTEM_COMPONENTS"]
  enable_managed_prometheus = true

  enable_network_policy      = true
  binary_authorization_mode  = "PROJECT_SINGLETON_POLICY_ENFORCE"
  datapath_provider          = "ADVANCED_DATAPATH"

  enable_private_cluster    = true
  enable_private_endpoint   = false
  enable_private_nodes      = true
  master_ipv4_cidr_block    = "172.16.0.0/28"
  enable_master_global_access = false

  master_authorized_networks = var.master_authorized_networks

  maintenance_start_time = "03:00"
  release_channel        = "REGULAR"

  enable_http_load_balancing          = true
  enable_horizontal_pod_autoscaling   = true
  enable_filestore_csi_driver         = false
  enable_gce_persistent_disk_csi_driver = true

  enable_security_posture = true
  vulnerability_mode      = "VULNERABILITY_DISABLED"

  node_pools = var.enable_autopilot ? [] : [
    {
      name               = "default-pool"
      initial_node_count = 1
      enable_autoscaling = true
      min_node_count     = 1
      max_node_count     = 10
      machine_type       = "e2-medium"
      disk_size_gb       = 100
      disk_type          = "pd-standard"
      enable_secure_boot = true
      enable_integrity_monitoring = true
      auto_repair        = true
      auto_upgrade       = true
    }
  ]

  tags = {
    platform    = "fawkes"
    environment = "example"
    managed_by  = "terraform"
  }
}
