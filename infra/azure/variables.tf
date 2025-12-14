variable "subscription_id" {
  description = "Azure subscription ID (optional; defaults to Azure CLI context if not set)"
  type        = string
  default     = null
}

variable "tenant_id" {
  description = "Azure tenant ID (optional; defaults to Azure CLI context if not set)"
  type        = string
  default     = null
}
variable "location" {
  description = "Azure region for the AKS resource group and cluster"
  type        = string
  default     = "East US"
}

variable "resource_group_name" {
  description = "Name of the Azure Resource Group to create/use for AKS"
  type        = string
  default     = "fawkes-rg"
}

variable "cluster_name" {
  description = "AKS cluster name"
  type        = string
  default     = "fawkes-aks"
}

variable "dns_prefix" {
  description = "DNS prefix for AKS API Server"
  type        = string
  default     = "fawkes"
}

variable "kubernetes_version" {
  description = "Kubernetes version for the AKS cluster (null for default)"
  type        = string
  default     = null
}

variable "environment" {
  description = "Environment name (dev, stage, prod)"
  type        = string
  default     = "dev"
}

# Network configuration
variable "vnet_address_space" {
  description = "Address space for the virtual network"
  type        = string
  default     = "10.0.0.0/16"
}

variable "aks_subnet_address_prefix" {
  description = "Address prefix for the AKS subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "service_cidr" {
  description = "Service CIDR for Kubernetes services"
  type        = string
  default     = "10.1.0.0/16"
}

variable "dns_service_ip" {
  description = "DNS service IP (must be within service_cidr)"
  type        = string
  default     = "10.1.0.10"
}

variable "network_policy" {
  description = "Network policy to use (azure, calico, or none)"
  type        = string
  default     = "azure"
}

# System node pool configuration
variable "system_node_pool_vm_size" {
  description = "VM size for the system node pool (choose an allowed, economical SKU)"
  type        = string
  default     = "Standard_B2ms"
}

variable "system_node_pool_count" {
  description = "Number of nodes in the system node pool"
  type        = number
  default     = 1
}

# User node pool configuration
variable "user_node_pool_vm_size" {
  description = "VM size for the user node pool (choose an allowed, economical SKU)"
  type        = string
  default     = "Standard_B2ms"
}

variable "user_node_pool_min_count" {
  description = "Minimum node count for user node pool (auto-scaling)"
  type        = number
  default     = 1
}

variable "user_node_pool_max_count" {
  description = "Maximum node count for user node pool (auto-scaling)"
  type        = number
  default     = 3
}

# Azure Container Registry
variable "acr_name" {
  description = "Name of the Azure Container Registry (must be globally unique)"
  type        = string
  default     = "fawkesacr"
}

variable "acr_sku" {
  description = "SKU for Azure Container Registry (Basic, Standard, Premium)"
  type        = string
  default     = "Standard"
}

# Key Vault
variable "key_vault_name" {
  description = "Name of the Azure Key Vault (must be globally unique)"
  type        = string
  default     = "fawkes-kv"
}

variable "key_vault_soft_delete_retention_days" {
  description = "Number of days to retain soft-deleted Key Vault items (7-90). Use 90 for production."
  type        = number
  default     = 7
}

variable "key_vault_purge_protection_enabled" {
  description = "Enable purge protection for Key Vault. Set to true for production to prevent permanent deletion."
  type        = bool
  default     = false
}

variable "key_vault_network_acls_default_action" {
  description = "Default action for Key Vault network ACLs (Allow or Deny). Use Deny for production."
  type        = string
  default     = "Allow"
  
  validation {
    condition     = contains(["Allow", "Deny"], var.key_vault_network_acls_default_action)
    error_message = "key_vault_network_acls_default_action must be either 'Allow' or 'Deny'."
  }
}

# Storage Account
variable "storage_account_name" {
  description = "Name of the storage account for Terraform state (must be globally unique)"
  type        = string
  default     = "fawkestfstate"
}

variable "storage_replication_type" {
  description = "Replication type for storage account (LRS, GRS, RAGRS, ZRS)"
  type        = string
  default     = "LRS"
}

# Log Analytics
variable "log_analytics_sku" {
  description = "SKU for Log Analytics workspace"
  type        = string
  default     = "PerGB2018"
}

variable "log_retention_days" {
  description = "Number of days to retain logs"
  type        = number
  default     = 30
}

variable "oidc_issuer_enabled" {
  description = "Enable OIDC issuer for AKS (workload identity)"
  type        = bool
  default     = true
}

variable "workload_identity_enabled" {
  description = "Enable Azure Workload Identity"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to all Azure resources"
  type        = map(string)
  default = {
    platform    = "fawkes"
    managed_by  = "terraform"
  }
}

# DNS configuration
variable "dns_zone_name" {
  description = "Name of the DNS zone to create (e.g., fawkes.yourdomain.com). Set to null to skip DNS zone creation."
  type        = string
  default     = null
}

variable "create_dns_records" {
  description = "Whether to create DNS records for ingress. Requires dns_zone_name to be set and ingress-nginx to be deployed."
  type        = bool
  default     = false
}

variable "ingress_public_ip_name" {
  description = "Name of the public IP created by ingress-nginx LoadBalancer service. This is auto-generated by AKS."
  type        = string
  default     = "kubernetes"
}

# Backup configuration
variable "backup_timezone" {
  description = "Timezone for backup schedule (e.g., UTC, Eastern Standard Time)"
  type        = string
  default     = "UTC"
}

variable "backup_time" {
  description = "Time of day to run daily backups (24-hour format, e.g., 02:00)"
  type        = string
  default     = "02:00"
}

variable "backup_retention_daily" {
  description = "Number of daily backups to retain"
  type        = number
  default     = 7
}

variable "backup_retention_weekly" {
  description = "Number of weekly backups to retain"
  type        = number
  default     = 4
}

variable "backup_storage_redundancy" {
  description = "Storage redundancy for backup vault (LocallyRedundant or GeoRedundant)"
  type        = string
  default     = "LocallyRedundant"

  validation {
    condition     = contains(["LocallyRedundant", "GeoRedundant"], var.backup_storage_redundancy)
    error_message = "backup_storage_redundancy must be either 'LocallyRedundant' or 'GeoRedundant'."
  }
}

variable "backup_alert_email" {
  description = "Email address for backup failure alerts"
  type        = string
  default     = "platform-team@example.com"
}

