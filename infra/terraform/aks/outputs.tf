output "cluster_name" {
  description = "AKS cluster name"
  value       = azurerm_kubernetes_cluster.aks.name
}

output "kube_admin_config" {
  description = "Kube admin config"
  value       = azurerm_kubernetes_cluster.aks.kube_admin_config
  sensitive   = true
}

output "kube_config" {
  description = "User kubeconfig"
  value       = azurerm_kubernetes_cluster.aks.kube_config
  sensitive   = true
}

output "node_resource_group" {
  description = "Node resource group created by AKS"
  value       = azurerm_kubernetes_cluster.aks.node_resource_group
}
