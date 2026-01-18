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

output "server_id" {
  description = "The ID of the database server"
  value       = var.engine == "postgresql" ? azurerm_postgresql_flexible_server.main[0].id : azurerm_mysql_flexible_server.main[0].id
}

output "server_name" {
  description = "The name of the database server"
  value       = var.server_name
}

output "server_fqdn" {
  description = "The FQDN of the database server"
  value       = var.engine == "postgresql" ? azurerm_postgresql_flexible_server.main[0].fqdn : azurerm_mysql_flexible_server.main[0].fqdn
}

output "admin_username" {
  description = "Administrator username"
  value       = var.admin_username
}

output "admin_password" {
  description = "Administrator password (if generated)"
  value       = var.admin_password != null ? var.admin_password : random_password.admin[0].result
  sensitive   = true
}

output "database_id" {
  description = "The ID of the created database"
  value       = var.create_database ? (var.engine == "postgresql" ? azurerm_postgresql_flexible_server_database.main[0].id : azurerm_mysql_flexible_database.main[0].id) : null
}

output "database_name" {
  description = "The name of the created database"
  value       = var.create_database ? var.database_name : null
}

output "connection_string" {
  description = "Database connection string (without password)"
  value = var.engine == "postgresql" ? (
    var.create_database ?
    "postgresql://${var.admin_username}@${var.server_name}:PASSWORD@${azurerm_postgresql_flexible_server.main[0].fqdn}:5432/${var.database_name}" :
    "postgresql://${var.admin_username}@${var.server_name}:PASSWORD@${azurerm_postgresql_flexible_server.main[0].fqdn}:5432/postgres"
    ) : (
    var.create_database ?
    "mysql://${var.admin_username}@${var.server_name}:PASSWORD@${azurerm_mysql_flexible_server.main[0].fqdn}:3306/${var.database_name}" :
    "mysql://${var.admin_username}@${var.server_name}:PASSWORD@${azurerm_mysql_flexible_server.main[0].fqdn}:3306"
  )
  sensitive = true
}

output "private_endpoint_id" {
  description = "The ID of the private endpoint (if created)"
  value       = var.enable_private_endpoint ? (var.engine == "postgresql" ? azurerm_private_endpoint.postgresql[0].id : azurerm_private_endpoint.mysql[0].id) : null
}

output "private_endpoint_ip" {
  description = "The private IP address of the private endpoint (if created)"
  value       = var.enable_private_endpoint ? (var.engine == "postgresql" ? azurerm_private_endpoint.postgresql[0].private_service_connection[0].private_ip_address : azurerm_private_endpoint.mysql[0].private_service_connection[0].private_ip_address) : null
}

output "high_availability_enabled" {
  description = "Whether high availability is enabled"
  value       = var.high_availability_mode != null
}

output "backup_retention_days" {
  description = "Backup retention period in days"
  value       = var.backup_retention_days
}

output "geo_redundant_backup_enabled" {
  description = "Whether geo-redundant backups are enabled"
  value       = var.geo_redundant_backup_enabled
}
