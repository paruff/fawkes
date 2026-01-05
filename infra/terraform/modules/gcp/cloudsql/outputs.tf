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

output "instance_name" {
  description = "The name of the Cloud SQL instance"
  value       = google_sql_database_instance.main.name
}

output "instance_connection_name" {
  description = "The connection name for the Cloud SQL instance"
  value       = google_sql_database_instance.main.connection_name
}

output "instance_self_link" {
  description = "The self link of the Cloud SQL instance"
  value       = google_sql_database_instance.main.self_link
}

output "instance_service_account_email" {
  description = "The service account email address for the Cloud SQL instance"
  value       = google_sql_database_instance.main.service_account_email_address
}

output "private_ip_address" {
  description = "The private IP address of the Cloud SQL instance"
  value       = length(google_sql_database_instance.main.ip_address) > 0 ? google_sql_database_instance.main.ip_address[0].ip_address : null
}

output "public_ip_address" {
  description = "The public IP address of the Cloud SQL instance"
  value       = var.ipv4_enabled && length(google_sql_database_instance.main.ip_address) > 0 ? google_sql_database_instance.main.ip_address[0].ip_address : null
}

output "database_names" {
  description = "List of created database names"
  value       = [for db in google_sql_database.databases : db.name]
}

output "user_names" {
  description = "List of created user names"
  value       = [for user in google_sql_user.users : user.name]
}

output "replica_connection_names" {
  description = "Map of replica names to their connection names"
  value       = { for k, v in google_sql_database_instance.replicas : k => v.connection_name }
}

output "generated_user_passwords" {
  description = "Map of user names to their generated passwords (for users without specified passwords)"
  value       = { for k, v in random_password.user_password : k => v.result }
  sensitive   = true
}
