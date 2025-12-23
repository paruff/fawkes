provider "azurerm" {
  # Features block is empty as no Azure-specific features are configured
  # Note: Key Vault configuration removed as Fawkes uses HashiCorp Vault
  features {}
  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id
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
    name            = "system"
    vm_size         = var.system_node_pool_vm_size
    node_count      = var.system_node_pool_count
    vnet_subnet_id  = azurerm_subnet.aks_subnet.id
    type            = "VirtualMachineScaleSets"
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
    network_plugin    = "azure"
    network_policy    = var.network_policy
    dns_service_ip    = var.dns_service_ip
    service_cidr      = var.service_cidr
    load_balancer_sku = "standard"
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

  # Private cluster configuration
  private_cluster_enabled = var.private_cluster_enabled

  # Allow access from your current IPv4 address
  api_server_access_profile {
    authorized_ip_ranges = [
      "${chomp(data.http.my_ip.response_body)}/32"
    ]
  }

  tags = var.tags
}

# User node pool with auto-scaling
resource "azurerm_kubernetes_cluster_node_pool" "user" {
  name                  = "user"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks.id
  vm_size               = var.user_node_pool_vm_size
  vnet_subnet_id        = azurerm_subnet.aks_subnet.id

  auto_scaling_enabled = var.user_node_pool_enable_autoscaling
  # When autoscaling is enabled, specify min/max. Otherwise, set a fixed node_count.
  min_count  = var.user_node_pool_enable_autoscaling ? var.user_node_pool_min_count : null
  max_count  = var.user_node_pool_enable_autoscaling ? var.user_node_pool_max_count : null
  node_count = var.user_node_pool_enable_autoscaling ? null : var.user_node_pool_node_count

  mode            = "User"
  os_disk_size_gb = 128

  # Spot instances for cost savings in dev (keep system pool Regular)
  priority        = var.user_node_pool_priority
  eviction_policy = var.user_node_pool_priority == "Spot" ? var.user_node_pool_eviction_policy : null
  spot_max_price  = var.user_node_pool_priority == "Spot" ? var.user_node_pool_spot_max_price : null

  # Required when updating properties like vm_size on existing pools
  temporary_name_for_rotation = "userrot"

  node_labels = {
    "nodepool-type" = "user"
    "environment"   = var.environment
  }

  tags = merge(var.tags, {
    nodepool = "user"
  })
}

# NOTE: Automated shutdown for cost optimization
# Azure AKS Start/Stop feature allows stopping and starting the cluster to save costs during off-hours.
# To manually stop the cluster:
#   az aks stop --name ${var.cluster_name} --resource-group ${var.resource_group_name}
# To manually start the cluster:
#   az aks start --name ${var.cluster_name} --resource-group ${var.resource_group_name}
#
# For automated shutdown schedules, consider using Azure Automation Runbooks or GitHub Actions
# to run the above commands on a schedule (e.g., stop at 8:00 PM EST, start at 8:00 AM EST)

# NOTE: Azure Container Registry (ACR) is NOT provisioned here.
# Fawkes uses a self-hosted Harbor instance for container registry.

# NOTE: Azure Key Vault is NOT provisioned here.
# Fawkes uses a self-hosted HashiCorp Vault instance for secret management.

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
  storage_account_id    = azurerm_storage_account.terraform_state.id
  container_access_type = "private"
}

# Get your current public IP (IPv4 only for AKS)
data "http" "my_ip" {
  url = "https://ipv4.icanhazip.com"  # Forces IPv4 response
}

# Get current Azure client configuration
data "azurerm_client_config" "current" {}

# Grant cluster admin role to the current user
resource "azurerm_role_assignment" "aks_cluster_admin" {
  scope                = azurerm_kubernetes_cluster.aks.id
  role_definition_name = "Azure Kubernetes Service RBAC Cluster Admin"
  principal_id         = data.azurerm_client_config.current.object_id
}

# Wait for role assignment propagation
resource "time_sleep" "wait_for_rbac" {
  depends_on = [azurerm_role_assignment.aks_cluster_admin]
  
  create_duration = "30s"
}
