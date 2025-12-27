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
  description = "The ID of the AKS cluster"
  value       = azurerm_kubernetes_cluster.main.id
}

output "cluster_name" {
  description = "The name of the AKS cluster"
  value       = azurerm_kubernetes_cluster.main.name
}

output "cluster_fqdn" {
  description = "The FQDN of the AKS cluster"
  value       = azurerm_kubernetes_cluster.main.fqdn
}

output "kube_config" {
  description = "Kubernetes configuration for the cluster"
  value       = azurerm_kubernetes_cluster.main.kube_config
  sensitive   = true
}

output "kube_admin_config" {
  description = "Kubernetes admin configuration for the cluster"
  value       = azurerm_kubernetes_cluster.main.kube_admin_config
  sensitive   = true
}

output "node_resource_group" {
  description = "The node resource group created by AKS"
  value       = azurerm_kubernetes_cluster.main.node_resource_group
}

output "identity_principal_id" {
  description = "The Principal ID of the System Assigned Managed Identity"
  value       = var.enable_managed_identity ? azurerm_kubernetes_cluster.main.identity[0].principal_id : null
}

output "identity_tenant_id" {
  description = "The Tenant ID of the System Assigned Managed Identity"
  value       = var.enable_managed_identity ? azurerm_kubernetes_cluster.main.identity[0].tenant_id : null
}
