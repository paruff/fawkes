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

output "cluster_id" {
  description = "The ID of the GKE cluster"
  value       = google_container_cluster.main.id
}

output "cluster_name" {
  description = "The name of the GKE cluster"
  value       = google_container_cluster.main.name
}

output "cluster_endpoint" {
  description = "The endpoint for the GKE cluster"
  value       = google_container_cluster.main.endpoint
  sensitive   = true
}

output "cluster_ca_certificate" {
  description = "The CA certificate for the GKE cluster"
  value       = google_container_cluster.main.master_auth[0].cluster_ca_certificate
  sensitive   = true
}

output "cluster_master_version" {
  description = "The Kubernetes master version"
  value       = google_container_cluster.main.master_version
}

output "cluster_location" {
  description = "The location of the GKE cluster"
  value       = google_container_cluster.main.location
}

output "cluster_region" {
  description = "The region of the GKE cluster"
  value       = google_container_cluster.main.location
}

output "workload_identity_pool" {
  description = "The Workload Identity pool for the cluster"
  value       = "${var.project_id}.svc.id.goog"
}

output "node_pool_names" {
  description = "List of node pool names"
  value       = [for pool in google_container_node_pool.node_pools : pool.name]
}

output "node_pool_service_accounts" {
  description = "Map of node pool names to their service account emails"
  value       = { for k, v in google_service_account.node_pool : k => v.email }
}
