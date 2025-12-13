provider "azurerm" {
  features {
    key_vault {
      # Only purge soft-deleted Key Vaults on destroy in dev environments
      # In production, this should always be false to prevent accidental permanent deletion
      purge_soft_delete_on_destroy = var.environment == "dev" ? true : false
    }
  }
}

# Resource Group for Fawkes platform
resource "azurerm_resource_group" "aks_rg" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

# Virtual Network with subnets for AKS
resource "azurerm_virtual_network" "aks_vnet" {
  name                = "${var.cluster_name}-vnet"
  location            = azurerm_resource_group.aks_rg.location
  resource_group_name = azurerm_resource_group.aks_rg.name
  address_space       = [var.vnet_address_space]
  tags                = var.tags
}

# Subnet for AKS nodes
resource "azurerm_subnet" "aks_subnet" {
  name                 = "${var.cluster_name}-aks-subnet"
  resource_group_name  = azurerm_resource_group.aks_rg.name
  virtual_network_name = azurerm_virtual_network.aks_vnet.name
  address_prefixes     = [var.aks_subnet_address_prefix]
}

# Log Analytics workspace for monitoring
resource "azurerm_log_analytics_workspace" "aks_logs" {
  name                = "${var.cluster_name}-logs"
  location            = azurerm_resource_group.aks_rg.location
  resource_group_name = azurerm_resource_group.aks_rg.name
  sku                 = var.log_analytics_sku
  retention_in_days   = var.log_retention_days
  tags                = var.tags
}

# AKS cluster with system and user node pools
resource "azurerm_kubernetes_cluster" "aks" {
  name                = var.cluster_name
  location            = azurerm_resource_group.aks_rg.location
  resource_group_name = azurerm_resource_group.aks_rg.name
  dns_prefix          = var.dns_prefix
  kubernetes_version  = var.kubernetes_version

  oidc_issuer_enabled       = var.oidc_issuer_enabled
  workload_identity_enabled = var.workload_identity_enabled

  # System node pool
  default_node_pool {
    name           = "system"
    vm_size        = var.system_node_pool_vm_size
    node_count     = var.system_node_pool_count
    vnet_subnet_id = azurerm_subnet.aks_subnet.id
    type           = "VirtualMachineScaleSets"
    os_disk_size_gb = 128
    
    node_labels = {
      "nodepool-type" = "system"
      "environment"   = var.environment
    }
    
    tags = merge(var.tags, {
      nodepool = "system"
    })
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin     = "azure"
    network_policy     = var.network_policy
    dns_service_ip     = var.dns_service_ip
    service_cidr       = var.service_cidr
    load_balancer_sku  = "standard"
  }

  # Enable Azure Monitor for containers
  oms_agent {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.aks_logs.id
  }

  # Enable Azure RBAC
  azure_active_directory_role_based_access_control {
    admin_group_object_ids = []
    azure_rbac_enabled     = true
  }

  tags = var.tags
}

# User node pool with auto-scaling
resource "azurerm_kubernetes_cluster_node_pool" "user" {
  name                  = "user"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks.id
  vm_size               = var.user_node_pool_vm_size
  vnet_subnet_id        = azurerm_subnet.aks_subnet.id
  
  enable_auto_scaling = true
  min_count           = var.user_node_pool_min_count
  max_count           = var.user_node_pool_max_count
  
  mode              = "User"
  os_disk_size_gb   = 128
  
  node_labels = {
    "nodepool-type" = "user"
    "environment"   = var.environment
  }
  
  tags = merge(var.tags, {
    nodepool = "user"
  })
}

# Azure Container Registry
resource "azurerm_container_registry" "acr" {
  name                = var.acr_name
  resource_group_name = azurerm_resource_group.aks_rg.name
  location            = azurerm_resource_group.aks_rg.location
  sku                 = var.acr_sku
  admin_enabled       = false
  
  tags = var.tags
}

# Assign AcrPull role to AKS cluster
resource "azurerm_role_assignment" "aks_acr_pull" {
  principal_id                     = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
  role_definition_name             = "AcrPull"
  scope                            = azurerm_container_registry.acr.id
  skip_service_principal_aad_check = true
}

# Data source for current client configuration
data "azurerm_client_config" "current" {}

# Azure Key Vault for secrets
resource "azurerm_key_vault" "aks_kv" {
  name                       = var.key_vault_name
  location                   = azurerm_resource_group.aks_rg.location
  resource_group_name        = azurerm_resource_group.aks_rg.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  soft_delete_retention_days = var.key_vault_soft_delete_retention_days
  purge_protection_enabled   = var.key_vault_purge_protection_enabled

  network_acls {
    default_action = var.key_vault_network_acls_default_action
    bypass         = "AzureServices"
    # In production, add specific IP ranges or virtual networks:
    # ip_rules       = ["1.2.3.4/32"]
    # virtual_network_subnet_ids = [azurerm_subnet.aks_subnet.id]
  }

  tags = var.tags
}

# Grant Key Vault access to current user/service principal
resource "azurerm_key_vault_access_policy" "deployer" {
  key_vault_id = azurerm_key_vault.aks_kv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  secret_permissions = [
    "Get", "List", "Set", "Delete", "Purge", "Recover"
  ]
}

# Grant Key Vault access to AKS cluster
resource "azurerm_key_vault_access_policy" "aks" {
  key_vault_id = azurerm_key_vault.aks_kv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id

  secret_permissions = [
    "Get", "List"
  ]
}

# Storage account for Terraform state and general storage
resource "azurerm_storage_account" "terraform_state" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.aks_rg.name
  location                 = azurerm_resource_group.aks_rg.location
  account_tier             = "Standard"
  account_replication_type = var.storage_replication_type
  
  tags = var.tags
}

# Container for Terraform state
resource "azurerm_storage_container" "terraform_state" {
  name                  = "tfstate"
  storage_account_name  = azurerm_storage_account.terraform_state.name
  container_access_type = "private"
}
