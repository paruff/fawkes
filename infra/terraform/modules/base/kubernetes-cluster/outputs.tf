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

# Base outputs for Kubernetes clusters across all providers

output "cluster_id" {
  description = "The ID of the Kubernetes cluster"
  value       = var.cluster_id
}

output "cluster_name" {
  description = "The name of the Kubernetes cluster"
  value       = var.cluster_name
}

output "cluster_endpoint" {
  description = "The endpoint/FQDN of the Kubernetes cluster"
  value       = var.cluster_endpoint
}

output "kube_config" {
  description = "Kubernetes configuration for the cluster"
  value       = var.kube_config
  sensitive   = true
}

# Variables to pass through from provider-specific modules
variable "cluster_id" {
  description = "Cluster ID from provider-specific module"
  type        = string
  default     = ""
}

variable "cluster_endpoint" {
  description = "Cluster endpoint from provider-specific module"
  type        = string
  default     = ""
}

variable "kube_config" {
  description = "Kube config from provider-specific module"
  type        = any
  default     = null
  sensitive   = true
}
