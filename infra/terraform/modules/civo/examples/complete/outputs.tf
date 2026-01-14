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

# Network Outputs
output "network_id" {
  description = "ID of the created network"
  value       = module.network.network_id
}

output "firewall_id" {
  description = "ID of the created firewall"
  value       = module.network.firewall_id
}

# Kubernetes Outputs
output "cluster_id" {
  description = "ID of the Kubernetes cluster"
  value       = module.kubernetes.cluster_id
}

output "cluster_endpoint" {
  description = "Kubernetes API endpoint"
  value       = module.kubernetes.cluster_endpoint
  sensitive   = true
}

output "kubeconfig" {
  description = "Kubeconfig for cluster access"
  value       = module.kubernetes.kubeconfig
  sensitive   = true
}

# Database Outputs
output "database_id" {
  description = "ID of the database cluster"
  value       = module.database.database_id
}

output "database_host" {
  description = "Database connection hostname"
  value       = module.database.database_host
  sensitive   = true
}

output "database_uri" {
  description = "Database connection URI"
  value       = module.database.database_uri
  sensitive   = true
}

# Object Store Outputs
output "bucket_id" {
  description = "ID of the object store bucket"
  value       = module.objectstore.bucket_id
}

output "bucket_url" {
  description = "URL of the object store bucket"
  value       = module.objectstore.bucket_url
}

output "s3_configuration" {
  description = "S3 configuration for application integration"
  value       = module.objectstore.s3_configuration
  sensitive   = true
}

# Summary Output
output "deployment_summary" {
  description = "Summary of deployed resources"
  value = {
    region          = var.region
    environment     = var.environment
    network_id      = module.network.network_id
    cluster_id      = module.kubernetes.cluster_id
    cluster_status  = module.kubernetes.cluster_status
    database_id     = module.database.database_id
    database_engine = module.database.engine
    bucket_id       = module.objectstore.bucket_id
  }
}
