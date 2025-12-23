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
  description = "Azure region for resources (e.g., eastus)"
  type        = string
}

variable "rg_name" {
  description = "Resource group name"
  type        = string
}

variable "tags" {
  description = "Common resource tags"
  type        = map(string)
  default     = {
    app       = "fawkes"
    component = "platform"
  }
}

variable "vnet_name" {
  description = "Virtual network name"
  type        = string
}

variable "vnet_cidr" {
  description = "VNet address space CIDR"
  type        = string
}

variable "subnet_name" {
  description = "Subnet name for AKS"
  type        = string
}

variable "subnet_cidr" {
  description = "Subnet CIDR for AKS nodes"
  type        = string
}

variable "cluster_name" {
  description = "AKS cluster name"
  type        = string
}

variable "node_vm_size" {
  description = "Default node pool VM size (use an allowed SKU in your region)"
  type        = string
  default     = "Standard_B2ms"
}

variable "node_count" {
  description = "Default node pool count"
  type        = number
  default     = 3
}

variable "network_plugin" {
  description = "AKS network plugin (azure or kubenet)"
  type        = string
  default     = "azure"
}

variable "service_cidr" {
  description = "Service CIDR for Kubernetes services"
  type        = string
  default     = "10.0.0.0/16"
}

variable "dns_service_ip" {
  description = "DNS service IP from service CIDR"
  type        = string
  default     = "10.0.0.10"
}

variable "api_server_authorized_ip_ranges" {
  description = "Optional list of authorized IP ranges for the API server"
  type        = list(string)
  default     = []
}

variable "enable_rbac" {
  description = "Enable Kubernetes RBAC"
  type        = bool
  default     = true
}

variable "enable_managed_identity" {
  description = "Enable System Assigned Managed Identity"
  type        = bool
  default     = true
}
