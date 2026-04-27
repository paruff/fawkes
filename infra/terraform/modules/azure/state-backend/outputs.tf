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

output "resource_group_name" {
  description = "Name of the Azure resource group containing the state backend resources."
  value       = azurerm_resource_group.state.name
}

output "resource_group_id" {
  description = "ID of the Azure resource group containing the state backend resources."
  value       = azurerm_resource_group.state.id
}

output "storage_account_name" {
  description = "Name of the Azure Storage Account used for Terraform state storage."
  value       = azurerm_storage_account.state.name
}

output "storage_account_id" {
  description = "ID of the Azure Storage Account."
  value       = azurerm_storage_account.state.id
}

output "primary_access_key" {
  description = "Primary access key for the storage account. Handle as sensitive. Use for initial bootstrap only; prefer OIDC/managed identity in CI."
  value       = azurerm_storage_account.state.primary_access_key
  sensitive   = true
}

output "container_name" {
  description = "Name of the storage container holding Terraform state files."
  value       = azurerm_storage_container.tfstate.name
}

output "backend_config" {
  description = "Rendered backend configuration block for use with 'terraform init -backend-config'. Copy into environments/<env>/backend.hcl."
  value = <<-EOT
    resource_group_name  = "${azurerm_resource_group.state.name}"
    storage_account_name = "${azurerm_storage_account.state.name}"
    container_name       = "${azurerm_storage_container.tfstate.name}"
    key                  = "${var.environment}/terraform.tfstate"
  EOT
}
