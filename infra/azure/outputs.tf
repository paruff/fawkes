output "kube_config" {
  value = azurerm_kubernetes_cluster.aks.kube_config_raw
  sensitive = true
}

output "oidc_issuer_url" {
  description = "OIDC issuer URL for AKS (used for federated identity)."
  value       = azurerm_kubernetes_cluster.aks.oidc_issuer_url
}
