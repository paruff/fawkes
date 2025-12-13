# ============================================================================
# FILE: infra/azure/dns.tf
# PURPOSE: Azure DNS configuration for Fawkes platform
#          Creates DNS zone and records for ingress public IP
# ============================================================================

# Azure DNS Zone for custom domain (optional)
# Note: This is optional and only needed if you want to use a custom domain
# Comment out or set var.dns_zone_name to null to disable
resource "azurerm_dns_zone" "fawkes" {
  count               = var.dns_zone_name != null ? 1 : 0
  name                = var.dns_zone_name
  resource_group_name = azurerm_resource_group.aks_rg.name
  tags                = var.tags
}

# Data source to get the ingress controller's public IP
# This will fail if ingress-nginx is not deployed yet
# You may need to run terraform apply after deploying ingress-nginx
data "azurerm_public_ip" "ingress" {
  count               = var.dns_zone_name != null && var.create_dns_records ? 1 : 0
  name                = var.ingress_public_ip_name
  resource_group_name = azurerm_kubernetes_cluster.aks.node_resource_group
  
  # Add dependency to ensure cluster is created first
  depends_on = [azurerm_kubernetes_cluster.aks]
}

# A record for root domain
resource "azurerm_dns_a_record" "root" {
  count               = var.dns_zone_name != null && var.create_dns_records ? 1 : 0
  name                = "@"
  zone_name           = azurerm_dns_zone.fawkes[0].name
  resource_group_name = azurerm_resource_group.aks_rg.name
  ttl                 = 300
  records             = [data.azurerm_public_ip.ingress[0].ip_address]
  tags                = var.tags
}

# Wildcard A record for all subdomains (*.fawkes.yourdomain.com)
resource "azurerm_dns_a_record" "wildcard" {
  count               = var.dns_zone_name != null && var.create_dns_records ? 1 : 0
  name                = "*"
  zone_name           = azurerm_dns_zone.fawkes[0].name
  resource_group_name = azurerm_resource_group.aks_rg.name
  ttl                 = 300
  records             = [data.azurerm_public_ip.ingress[0].ip_address]
  tags                = var.tags
}

# Optional: Additional A records for specific services
# Uncomment and customize as needed
# resource "azurerm_dns_a_record" "jenkins" {
#   count               = var.dns_zone_name != null && var.create_dns_records ? 1 : 0
#   name                = "jenkins"
#   zone_name           = azurerm_dns_zone.fawkes[0].name
#   resource_group_name = azurerm_resource_group.aks_rg.name
#   ttl                 = 300
#   records             = [data.azurerm_public_ip.ingress[0].ip_address]
#   tags                = var.tags
# }

# resource "azurerm_dns_a_record" "backstage" {
#   count               = var.dns_zone_name != null && var.create_dns_records ? 1 : 0
#   name                = "backstage"
#   zone_name           = azurerm_dns_zone.fawkes[0].name
#   resource_group_name = azurerm_resource_group.aks_rg.name
#   ttl                 = 300
#   records             = [data.azurerm_public_ip.ingress[0].ip_address]
#   tags                = var.tags
# }

# resource "azurerm_dns_a_record" "focalboard" {
#   count               = var.dns_zone_name != null && var.create_dns_records ? 1 : 0
#   name                = "focalboard"
#   zone_name           = azurerm_dns_zone.fawkes[0].name
#   resource_group_name = azurerm_resource_group.aks_rg.name
#   ttl                 = 300
#   records             = [data.azurerm_public_ip.ingress[0].ip_address]
#   tags                = var.tags
# }

# Output DNS nameservers for delegation
output "dns_zone_name_servers" {
  description = "Name servers for DNS zone delegation. Update your domain registrar with these nameservers."
  value       = var.dns_zone_name != null ? azurerm_dns_zone.fawkes[0].name_servers : []
}
