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

output "network_id" {
  description = "The ID of the VPC network"
  value       = google_compute_network.main.id
}

output "network_name" {
  description = "The name of the VPC network"
  value       = google_compute_network.main.name
}

output "network_self_link" {
  description = "The self link of the VPC network"
  value       = google_compute_network.main.self_link
}

output "subnet_ids" {
  description = "Map of subnet names to their IDs"
  value       = { for k, v in google_compute_subnetwork.subnets : k => v.id }
}

output "subnet_self_links" {
  description = "Map of subnet names to their self links"
  value       = { for k, v in google_compute_subnetwork.subnets : k => v.self_link }
}

output "subnet_ip_cidr_ranges" {
  description = "Map of subnet names to their IP CIDR ranges"
  value       = { for k, v in google_compute_subnetwork.subnets : k => v.ip_cidr_range }
}

output "router_id" {
  description = "The ID of the Cloud Router"
  value       = var.enable_nat_gateway ? google_compute_router.router[0].id : null
}

output "router_name" {
  description = "The name of the Cloud Router"
  value       = var.enable_nat_gateway ? google_compute_router.router[0].name : null
}

output "nat_id" {
  description = "The ID of the Cloud NAT"
  value       = var.enable_nat_gateway ? google_compute_router_nat.nat[0].id : null
}

output "nat_name" {
  description = "The name of the Cloud NAT"
  value       = var.enable_nat_gateway ? google_compute_router_nat.nat[0].name : null
}

output "firewall_rule_ids" {
  description = "Map of firewall rule names to their IDs"
  value       = { for k, v in google_compute_firewall.rules : k => v.id }
}
