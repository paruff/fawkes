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

output "storage_account_id" {
  description = "The ID of the storage account"
  value       = azurerm_storage_account.main.id
}

output "storage_account_name" {
  description = "The name of the storage account"
  value       = azurerm_storage_account.main.name
}

output "primary_blob_endpoint" {
  description = "Primary blob endpoint"
  value       = azurerm_storage_account.main.primary_blob_endpoint
}

output "primary_blob_host" {
  description = "Primary blob host"
  value       = azurerm_storage_account.main.primary_blob_host
}

output "secondary_blob_endpoint" {
  description = "Secondary blob endpoint"
  value       = azurerm_storage_account.main.secondary_blob_endpoint
}

output "primary_connection_string" {
  description = "Primary connection string"
  value       = azurerm_storage_account.main.primary_connection_string
  sensitive   = true
}

output "secondary_connection_string" {
  description = "Secondary connection string"
  value       = azurerm_storage_account.main.secondary_connection_string
  sensitive   = true
}

output "primary_access_key" {
  description = "Primary access key"
  value       = azurerm_storage_account.main.primary_access_key
  sensitive   = true
}

output "secondary_access_key" {
  description = "Secondary access key"
  value       = azurerm_storage_account.main.secondary_access_key
  sensitive   = true
}

output "identity_principal_id" {
  description = "Principal ID of the system-assigned managed identity"
  value       = var.enable_managed_identity ? azurerm_storage_account.main.identity[0].principal_id : null
}

output "identity_tenant_id" {
  description = "Tenant ID of the system-assigned managed identity"
  value       = var.enable_managed_identity ? azurerm_storage_account.main.identity[0].tenant_id : null
}

output "container_ids" {
  description = "Map of container names to IDs"
  value = {
    for k, v in azurerm_storage_container.main : k => v.id
  }
}

output "container_names" {
  description = "List of created container names"
  value       = [for k in keys(azurerm_storage_container.main) : k]
}

output "private_endpoint_id" {
  description = "The ID of the private endpoint (if created)"
  value       = var.enable_private_endpoint ? azurerm_private_endpoint.blob[0].id : null
}

output "private_endpoint_ip" {
  description = "The private IP address of the private endpoint (if created)"
  value       = var.enable_private_endpoint ? azurerm_private_endpoint.blob[0].private_service_connection[0].private_ip_address : null
}

output "primary_location" {
  description = "Primary location of the storage account"
  value       = azurerm_storage_account.main.primary_location
}

output "secondary_location" {
  description = "Secondary location of the storage account"
  value       = azurerm_storage_account.main.secondary_location
}
