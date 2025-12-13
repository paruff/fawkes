output "resource_group_name" {
  description = "Name of the Azure Resource Group"
  value       = azurerm_resource_group.aks_rg.name
}

output "cluster_name" {
  description = "Name of the AKS cluster"
  value       = azurerm_kubernetes_cluster.aks.name
}

output "cluster_id" {
  description = "ID of the AKS cluster"
  value       = azurerm_kubernetes_cluster.aks.id
}

output "kube_config" {
  description = "Kubeconfig for the AKS cluster"
  value       = azurerm_kubernetes_cluster.aks.kube_config_raw
  sensitive   = true
}

output "kubeconfig_path" {
  description = "Path where kubeconfig should be written"
  value       = "${path.root}/.kube/config"
}

output "host" {
  description = "Kubernetes API server endpoint"
  value       = azurerm_kubernetes_cluster.aks.kube_config[0].host
  sensitive   = true
}

output "cluster_fqdn" {
  description = "FQDN of the AKS cluster"
  value       = azurerm_kubernetes_cluster.aks.fqdn
}

output "node_resource_group" {
  description = "Resource group containing AKS nodes"
  value       = azurerm_kubernetes_cluster.aks.node_resource_group
}

output "oidc_issuer_url" {
  description = "OIDC issuer URL for AKS (used for federated identity)"
  value       = azurerm_kubernetes_cluster.aks.oidc_issuer_url
}

output "acr_id" {
  description = "ID of the Azure Container Registry"
  value       = azurerm_container_registry.acr.id
}

output "acr_login_server" {
  description = "Login server for the Azure Container Registry"
  value       = azurerm_container_registry.acr.login_server
}

output "key_vault_id" {
  description = "ID of the Azure Key Vault"
  value       = azurerm_key_vault.aks_kv.id
}

output "key_vault_uri" {
  description = "URI of the Azure Key Vault"
  value       = azurerm_key_vault.aks_kv.vault_uri
}

output "storage_account_name" {
  description = "Name of the storage account for Terraform state"
  value       = azurerm_storage_account.terraform_state.name
}

output "storage_account_primary_access_key" {
  description = "Primary access key for the storage account"
  value       = azurerm_storage_account.terraform_state.primary_access_key
  sensitive   = true
}

output "log_analytics_workspace_id" {
  description = "ID of the Log Analytics workspace"
  value       = azurerm_log_analytics_workspace.aks_logs.id
}

output "log_analytics_workspace_name" {
  description = "Name of the Log Analytics workspace"
  value       = azurerm_log_analytics_workspace.aks_logs.name
}

output "vnet_id" {
  description = "ID of the virtual network"
  value       = azurerm_virtual_network.aks_vnet.id
}

output "aks_subnet_id" {
  description = "ID of the AKS subnet"
  value       = azurerm_subnet.aks_subnet.id
}

output "dns_zone_id" {
  description = "ID of the DNS zone (if created)"
  value       = var.dns_zone_name != null ? azurerm_dns_zone.fawkes[0].id : null
}

output "dns_zone_name" {
  description = "Name of the DNS zone (if created)"
  value       = var.dns_zone_name
}

output "ingress_public_ip" {
  description = "Public IP address of the ingress controller (if DNS records are created)"
  value       = var.dns_zone_name != null && var.create_dns_records ? data.azurerm_public_ip.ingress[0].ip_address : null
}

# Backup outputs
output "recovery_vault_name" {
  description = "Name of the Recovery Services vault for backups"
  value       = azurerm_recovery_services_vault.aks_backup.name
}

output "recovery_vault_id" {
  description = "ID of the Recovery Services vault"
  value       = azurerm_recovery_services_vault.aks_backup.id
}

output "disk_backup_vault_name" {
  description = "Name of the Data Protection backup vault for disk backups"
  value       = azurerm_data_protection_backup_vault.disk_backup_vault.name
}

output "disk_backup_vault_id" {
  description = "ID of the Data Protection backup vault"
  value       = azurerm_data_protection_backup_vault.disk_backup_vault.id
}

output "backup_policy_id" {
  description = "ID of the daily backup policy"
  value       = azurerm_backup_policy_vm.daily_backup.id
}

output "disk_backup_policy_id" {
  description = "ID of the disk backup policy"
  value       = azurerm_data_protection_backup_policy_disk.disk_backup_policy.id
}

