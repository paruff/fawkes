resource "azurerm_kubernetes_cluster" "aks" {
  name                = var.cluster_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "${var.cluster_name}-dns"


  default_node_pool {
    name       = "systemnp"
    vm_size    = var.node_vm_size
    node_count = var.node_count
    type       = "VirtualMachineScaleSets"
    vnet_subnet_id = azurerm_subnet.aks.id
    upgrade_settings {
      max_surge = "33%"
    }
    only_critical_addons_enabled = true
  }

  identity {
    type = var.enable_managed_identity ? "SystemAssigned" : "None"
  }

  role_based_access_control_enabled = var.enable_rbac

  network_profile {
    network_plugin    = var.network_plugin
    dns_service_ip    = var.dns_service_ip
    service_cidr      = var.service_cidr
    load_balancer_sku = "standard"
    outbound_type     = "loadBalancer"
  }

  api_server_access_profile {
    authorized_ip_ranges = var.api_server_authorized_ip_ranges
  }

  tags = var.tags
}
