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

module "vpc" {
  source = "../../vpc"

  network_name = var.network_name
  location     = var.region
  project_id   = var.project_id
  routing_mode = "REGIONAL"

  subnets = [
    {
      name                            = "${var.network_name}-subnet-01"
      ip_cidr_range                   = "10.0.0.0/24"
      description                     = "Primary subnet for GKE"
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
    },
    {
      name                            = "${var.network_name}-subnet-02"
      ip_cidr_range                   = "10.0.1.0/24"
      description                     = "Secondary subnet"
      enable_private_ip_google_access = true
      purpose                         = "PRIVATE"
      secondary_ip_ranges             = []
    }
  ]

  enable_nat_gateway                 = true
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  enable_flow_logs                  = true
  flow_logs_aggregation_interval    = "INTERVAL_5_SEC"
  flow_logs_sampling                = 0.5
  flow_logs_metadata                = "INCLUDE_ALL_METADATA"

  firewall_rules = [
    {
      name          = "${var.network_name}-allow-http"
      description   = "Allow HTTP traffic"
      direction     = "INGRESS"
      priority      = 1000
      source_ranges = ["0.0.0.0/0"]
      target_tags   = ["http-server"]
      allow = [
        {
          protocol = "tcp"
          ports    = ["80"]
        }
      ]
      deny = []
    },
    {
      name          = "${var.network_name}-allow-https"
      description   = "Allow HTTPS traffic"
      direction     = "INGRESS"
      priority      = 1000
      source_ranges = ["0.0.0.0/0"]
      target_tags   = ["https-server"]
      allow = [
        {
          protocol = "tcp"
          ports    = ["443"]
        }
      ]
      deny = []
    }
  ]

  create_default_firewall_rules = true
  allow_ssh_from_iap            = true
  deny_all_egress               = false

  tags = {
    platform    = "fawkes"
    environment = "example"
    managed_by  = "terraform"
  }
}
