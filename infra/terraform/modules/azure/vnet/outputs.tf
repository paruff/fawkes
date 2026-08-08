# Copyright (c) 2025  Philip Ruff
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
# DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
# OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE
# OR OTHER DEALINGS IN THE SOFTWARE.

output "vnet_id" {
  description = "The ID of the virtual network"
  value       = azurerm_virtual_network.main.id
}

output "vnet_name" {
  description = "The name of the virtual network"
  value       = azurerm_virtual_network.main.name
}

output "vnet_address_space" {
  description = "Address space of the virtual network"
  value       = azurerm_virtual_network.main.address_space
}

output "vnet_guid" {
  description = "GUID of the virtual network"
  value       = azurerm_virtual_network.main.guid
}

output "public_subnet_ids" {
  description = "Map of public subnet names to IDs"
  value = {
    for k, v in azurerm_subnet.public : k => v.id
  }
}

output "public_subnet_names" {
  description = "List of public subnet names"
  value       = [for k in keys(azurerm_subnet.public) : k]
}

output "public_subnet_address_prefixes" {
  description = "Map of public subnet names to address prefixes"
  value = {
    for k, v in azurerm_subnet.public : k => v.address_prefixes
  }
}

output "private_subnet_ids" {
  description = "Map of private subnet names to IDs"
  value = {
    for k, v in azurerm_subnet.private : k => v.id
  }
}

output "private_subnet_names" {
  description = "List of private subnet names"
  value       = [for k in keys(azurerm_subnet.private) : k]
}

output "private_subnet_address_prefixes" {
  description = "Map of private subnet names to address prefixes"
  value = {
    for k, v in azurerm_subnet.private : k => v.address_prefixes
  }
}

output "public_nsg_ids" {
  description = "Map of public subnet names to NSG IDs"
  value = {
    for k, v in azurerm_network_security_group.public : k => v.id
  }
}

output "private_nsg_ids" {
  description = "Map of private subnet names to NSG IDs"
  value = {
    for k, v in azurerm_network_security_group.private : k => v.id
  }
}

output "nat_gateway_id" {
  description = "ID of the NAT Gateway (if created)"
  value       = var.enable_nat_gateway ? azurerm_nat_gateway.main[0].id : null
}

output "nat_gateway_public_ip" {
  description = "Public IP of the NAT Gateway (if created)"
  value       = var.enable_nat_gateway ? azurerm_public_ip.nat[0].ip_address : null
}

output "flow_logs_storage_account_id" {
  description = "ID of the storage account for flow logs (if created)"
  value       = var.enable_flow_logs && var.flow_logs_storage_account_id == null ? azurerm_storage_account.flow_logs[0].id : var.flow_logs_storage_account_id
}
