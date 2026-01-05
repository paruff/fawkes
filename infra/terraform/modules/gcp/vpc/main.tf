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

# VPC Network
resource "google_compute_network" "main" {
  name                    = var.network_name
  auto_create_subnetworks = false
  routing_mode            = var.routing_mode
  project                 = var.project_id

  description = "Custom VPC network for ${var.network_name}"
}

# Subnets
resource "google_compute_subnetwork" "subnets" {
  for_each = { for subnet in var.subnets : subnet.name => subnet }

  name          = each.value.name
  ip_cidr_range = each.value.ip_cidr_range
  region        = var.location
  network       = google_compute_network.main.id
  project       = var.project_id

  description              = each.value.description
  private_ip_google_access = each.value.enable_private_ip_google_access
  purpose                  = each.value.purpose
  role                     = each.value.purpose == "INTERNAL_HTTPS_LOAD_BALANCER" ? each.value.role : null

  # Secondary IP ranges for GKE pods and services
  dynamic "secondary_ip_range" {
    for_each = each.value.secondary_ip_ranges
    content {
      range_name    = secondary_ip_range.value.range_name
      ip_cidr_range = secondary_ip_range.value.ip_cidr_range
    }
  }

  # VPC Flow Logs
  dynamic "log_config" {
    for_each = var.enable_flow_logs ? [1] : []
    content {
      aggregation_interval = var.flow_logs_aggregation_interval
      flow_sampling        = var.flow_logs_sampling
      metadata             = var.flow_logs_metadata
      metadata_fields      = var.flow_logs_metadata == "CUSTOM_METADATA" ? var.flow_logs_metadata_fields : []
      filter_expr          = var.flow_logs_filter_expr
    }
  }
}

# Cloud Router for Cloud NAT
resource "google_compute_router" "router" {
  count   = var.enable_nat_gateway ? 1 : 0
  name    = "${var.network_name}-router"
  region  = var.location
  network = google_compute_network.main.id
  project = var.project_id

  bgp {
    asn = var.router_asn
  }
}

# Cloud NAT for outbound internet access from private resources
resource "google_compute_router_nat" "nat" {
  count   = var.enable_nat_gateway ? 1 : 0
  name    = "${var.network_name}-nat"
  router  = google_compute_router.router[0].name
  region  = var.location
  project = var.project_id

  nat_ip_allocate_option             = var.nat_ip_allocate_option
  source_subnetwork_ip_ranges_to_nat = var.source_subnetwork_ip_ranges_to_nat

  min_ports_per_vm                    = var.nat_min_ports_per_vm
  enable_endpoint_independent_mapping = var.nat_enable_endpoint_independent_mapping

  log_config {
    enable = var.nat_log_config_enable
    filter = var.nat_log_config_filter
  }

  dynamic "subnetwork" {
    for_each = var.source_subnetwork_ip_ranges_to_nat == "LIST_OF_SUBNETWORKS" ? var.nat_subnetworks : []
    content {
      name                    = subnetwork.value.name
      source_ip_ranges_to_nat = subnetwork.value.source_ip_ranges_to_nat
    }
  }
}

# Firewall Rules
resource "google_compute_firewall" "rules" {
  for_each = { for rule in var.firewall_rules : rule.name => rule }

  name    = each.value.name
  network = google_compute_network.main.name
  project = var.project_id

  description = each.value.description
  direction   = each.value.direction
  priority    = each.value.priority

  source_ranges      = each.value.direction == "INGRESS" ? each.value.source_ranges : null
  destination_ranges = each.value.direction == "EGRESS" ? each.value.destination_ranges : null
  source_tags        = each.value.source_tags
  target_tags        = each.value.target_tags

  dynamic "allow" {
    for_each = each.value.allow
    content {
      protocol = allow.value.protocol
      ports    = allow.value.ports
    }
  }

  dynamic "deny" {
    for_each = each.value.deny
    content {
      protocol = deny.value.protocol
      ports    = deny.value.ports
    }
  }

  log_config {
    metadata = each.value.log_config_metadata
  }
}

# Default firewall rules for common scenarios
resource "google_compute_firewall" "allow_internal" {
  count   = var.create_default_firewall_rules ? 1 : 0
  name    = "${var.network_name}-allow-internal"
  network = google_compute_network.main.name
  project = var.project_id

  description = "Allow internal communication within VPC"
  direction   = "INGRESS"
  priority    = 65534

  source_ranges = [for subnet in var.subnets : subnet.ip_cidr_range]

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "icmp"
  }
}

resource "google_compute_firewall" "allow_ssh_iap" {
  count   = var.create_default_firewall_rules && var.allow_ssh_from_iap ? 1 : 0
  name    = "${var.network_name}-allow-ssh-iap"
  network = google_compute_network.main.name
  project = var.project_id

  description = "Allow SSH from Identity-Aware Proxy"
  direction   = "INGRESS"
  priority    = 1000

  source_ranges = ["35.235.240.0/20"]

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
}

resource "google_compute_firewall" "deny_all_egress" {
  count   = var.create_default_firewall_rules && var.deny_all_egress ? 1 : 0
  name    = "${var.network_name}-deny-all-egress"
  network = google_compute_network.main.name
  project = var.project_id

  description = "Deny all egress traffic (use with caution)"
  direction   = "EGRESS"
  priority    = 65534

  destination_ranges = ["0.0.0.0/0"]

  deny {
    protocol = "all"
  }
}
