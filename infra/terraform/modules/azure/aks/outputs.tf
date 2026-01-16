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
  description = "FQDN of the AKS cluster"
  value       = azurerm_kubernetes_cluster.main.fqdn
}

output "cluster_endpoint" {
  description = "Endpoint for AKS control plane"
  value       = azurerm_kubernetes_cluster.main.kube_config[0].host
  sensitive   = true
}

output "cluster_version" {
  description = "The Kubernetes version for the cluster"
  value       = azurerm_kubernetes_cluster.main.kubernetes_version
}

output "kube_config" {
  description = "Kubernetes configuration for the cluster"
  value       = azurerm_kubernetes_cluster.main.kube_config_raw
  sensitive   = true
}

output "kube_admin_config" {
  description = "Kubernetes admin configuration for the cluster"
  value       = azurerm_kubernetes_cluster.main.kube_admin_config_raw
  sensitive   = true
}

output "client_certificate" {
  description = "Base64 encoded client certificate"
  value       = azurerm_kubernetes_cluster.main.kube_config[0].client_certificate
  sensitive   = true
}

output "client_key" {
  description = "Base64 encoded client key"
  value       = azurerm_kubernetes_cluster.main.kube_config[0].client_key
  sensitive   = true
}

output "cluster_ca_certificate" {
  description = "Base64 encoded cluster CA certificate"
  value       = azurerm_kubernetes_cluster.main.kube_config[0].cluster_ca_certificate
  sensitive   = true
}

output "identity_principal_id" {
  description = "Principal ID of the system assigned managed identity"
  value       = azurerm_kubernetes_cluster.main.identity[0].principal_id
}

output "identity_tenant_id" {
  description = "Tenant ID of the system assigned managed identity"
  value       = azurerm_kubernetes_cluster.main.identity[0].tenant_id
}

output "kubelet_identity_object_id" {
  description = "Object ID of the kubelet managed identity"
  value       = azurerm_kubernetes_cluster.main.kubelet_identity[0].object_id
}

output "kubelet_identity_client_id" {
  description = "Client ID of the kubelet managed identity"
  value       = azurerm_kubernetes_cluster.main.kubelet_identity[0].client_id
}

output "node_resource_group" {
  description = "Auto-generated resource group containing AKS cluster resources"
  value       = azurerm_kubernetes_cluster.main.node_resource_group
}

output "oidc_issuer_url" {
  description = "The OIDC issuer URL for the cluster (for workload identity)"
  value       = azurerm_kubernetes_cluster.main.oidc_issuer_url
}

output "default_node_pool_id" {
  description = "ID of the default node pool"
  value       = azurerm_kubernetes_cluster.main.default_node_pool[0].id
}

output "additional_node_pool_ids" {
  description = "Map of additional node pool names to IDs"
  value = {
    for k, v in azurerm_kubernetes_cluster_node_pool.additional : k => v.id
  }
}

output "log_analytics_workspace_id" {
  description = "ID of the Log Analytics workspace (if created)"
  value       = var.enable_azure_monitor && var.log_analytics_workspace_id == null ? azurerm_log_analytics_workspace.main[0].id : var.log_analytics_workspace_id
}

output "log_analytics_workspace_name" {
  description = "Name of the Log Analytics workspace (if created)"
  value       = var.enable_azure_monitor && var.log_analytics_workspace_id == null ? azurerm_log_analytics_workspace.main[0].name : null
}

output "portal_fqdn" {
  description = "FQDN for the Azure Portal integration"
  value       = azurerm_kubernetes_cluster.main.portal_fqdn
}

output "private_fqdn" {
  description = "FQDN for the private cluster endpoint"
  value       = azurerm_kubernetes_cluster.main.private_fqdn
}
