variable "location" {
  description = "Azure region for the AKS resource group and cluster"
  type        = string
  default     = "East US"
}

variable "resource_group_name" {
  description = "Name of the Azure Resource Group to create/use for AKS"
  type        = string
  default     = "aks-resource-group"
}

variable "cluster_name" {
  description = "AKS cluster name"
  type        = string
  default     = "aks-cluster"
}

variable "dns_prefix" {
  description = "DNS prefix for AKS API Server"
  type        = string
  default     = "aksdns"
}

variable "vm_size" {
  description = "VM size for the default node pool"
  type        = string
  default     = "Standard_D2s_v5"
}

variable "min_count" {
  description = "Minimum node count for default node pool"
  type        = number
  default     = 2
}

variable "max_count" {
  description = "Maximum node count for default node pool"
  type        = number
  default     = 5
}

variable "kubernetes_version" {
  description = "Kubernetes version for the AKS cluster (null for default)"
  type        = string
  default     = null
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
  description = "Tags to apply to AKS resources"
  type        = map(string)
  default     = {}
}

# Deprecated/unused (left for compatibility); autoscaling is enabled
variable "node_count" {
  description = "Deprecated: fixed node count (use min/max with autoscaling)"
  type        = number
  default     = 2
}
