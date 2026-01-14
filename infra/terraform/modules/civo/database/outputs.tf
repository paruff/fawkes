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

output "database_id" {
  description = "The ID of the database cluster"
  value       = civo_database.main.id
}

output "database_name" {
  description = "The name of the database cluster"
  value       = civo_database.main.name
}

output "database_host" {
  description = "Hostname for connecting to the database"
  value       = civo_database.main.host
  sensitive   = true
}

output "database_port" {
  description = "Port for connecting to the database"
  value       = civo_database.main.port
}

output "database_username" {
  description = "Username for database access"
  value       = civo_database.main.username
  sensitive   = true
}

output "database_password" {
  description = "Password for database access"
  value       = civo_database.main.password
  sensitive   = true
}

output "database_uri" {
  description = "Connection URI for the database"
  value       = civo_database.main.uri
  sensitive   = true
}

output "database_status" {
  description = "Status of the database cluster"
  value       = civo_database.main.status
}

output "engine" {
  description = "Database engine type"
  value       = civo_database.main.engine
}

output "engine_version" {
  description = "Database engine version"
  value       = civo_database.main.version
}

output "network_id" {
  description = "Network ID of the database"
  value       = civo_database.main.network_id
}

output "firewall_id" {
  description = "Firewall ID of the database"
  value       = civo_database.main.firewall_id
}

output "size" {
  description = "Size of the database instance"
  value       = civo_database.main.size
}

output "nodes" {
  description = "Number of database nodes"
  value       = civo_database.main.nodes
}

output "public_ipv4" {
  description = "Public IPv4 address of the database"
  value       = civo_database.main.public_ipv4
  sensitive   = true
}

output "region" {
  description = "Region where the database is deployed"
  value       = civo_database.main.region
}
