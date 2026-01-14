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
  description = "The ID of the Kubernetes cluster"
  value       = civo_kubernetes_cluster.main.id
}

output "cluster_name" {
  description = "The name of the Kubernetes cluster"
  value       = civo_kubernetes_cluster.main.name
}

output "cluster_endpoint" {
  description = "The API endpoint for the Kubernetes cluster"
  value       = civo_kubernetes_cluster.main.api_endpoint
  sensitive   = true
}

output "kubeconfig" {
  description = "Kubeconfig for connecting to the cluster"
  value       = civo_kubernetes_cluster.main.kubeconfig
  sensitive   = true
}

output "cluster_status" {
  description = "Status of the cluster"
  value       = civo_kubernetes_cluster.main.status
}

output "cluster_version" {
  description = "Kubernetes version of the cluster"
  value       = civo_kubernetes_cluster.main.kubernetes_version
}

output "master_ip" {
  description = "Master node IP address"
  value       = civo_kubernetes_cluster.main.master_ip
  sensitive   = true
}

output "dns_entry" {
  description = "DNS entry for the cluster"
  value       = civo_kubernetes_cluster.main.dns_entry
}

output "network_id" {
  description = "Network ID of the cluster"
  value       = civo_kubernetes_cluster.main.network_id
}

output "firewall_id" {
  description = "Firewall ID of the cluster"
  value       = civo_kubernetes_cluster.main.firewall_id
}

output "node_pool_ids" {
  description = "IDs of additional node pools"
  value       = { for k, v in civo_kubernetes_node_pool.pools : k => v.id }
}

output "installed_applications" {
  description = "List of installed marketplace applications"
  value       = civo_kubernetes_cluster.main.installed_applications
}

output "created_at" {
  description = "Timestamp when the cluster was created"
  value       = civo_kubernetes_cluster.main.created_at
}

output "region" {
  description = "Region where the cluster is deployed"
  value       = civo_kubernetes_cluster.main.region
}
