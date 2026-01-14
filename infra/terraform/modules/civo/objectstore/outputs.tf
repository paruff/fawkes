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

output "bucket_id" {
  description = "The ID of the object store"
  value       = civo_object_store.main.id
}

output "bucket_name" {
  description = "The name of the object store bucket"
  value       = civo_object_store.main.name
}

output "bucket_url" {
  description = "URL endpoint for the object store"
  value       = civo_object_store.main.bucket_url
}

output "access_key_id" {
  description = "Access key ID for S3 API access"
  value       = civo_object_store.main.access_key_id
  sensitive   = true
}

output "secret_access_key" {
  description = "Secret access key for S3 API access"
  value       = civo_object_store.main.secret_access_key
  sensitive   = true
}

output "max_size_gb" {
  description = "Maximum size of the object store in GB"
  value       = civo_object_store.main.max_size_gb
}

output "status" {
  description = "Status of the object store"
  value       = civo_object_store.main.status
}

output "region" {
  description = "Region where the object store is deployed"
  value       = civo_object_store.main.region
}

output "endpoint" {
  description = "S3-compatible endpoint URL"
  value       = "https://objectstore.${civo_object_store.main.region}.civo.com"
}

output "credentials_id" {
  description = "ID of the generated credentials"
  value       = var.create_credentials ? civo_object_store_credential.main[0].id : null
}

output "s3_configuration" {
  description = "S3 configuration details for application integration"
  value = {
    endpoint           = "https://objectstore.${civo_object_store.main.region}.civo.com"
    bucket             = civo_object_store.main.name
    region             = civo_object_store.main.region
    access_key_id      = civo_object_store.main.access_key_id
    secret_access_key  = civo_object_store.main.secret_access_key
  }
  sensitive = true
}
