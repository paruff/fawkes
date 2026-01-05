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

output "bucket_name" {
  description = "The name of the bucket"
  value       = google_storage_bucket.main.name
}

output "bucket_url" {
  description = "The URL of the bucket"
  value       = google_storage_bucket.main.url
}

output "bucket_self_link" {
  description = "The self link of the bucket"
  value       = google_storage_bucket.main.self_link
}

output "bucket_id" {
  description = "The ID of the bucket"
  value       = google_storage_bucket.main.id
}

output "logs_bucket_name" {
  description = "The name of the logs bucket"
  value       = var.enable_logging ? google_storage_bucket.logs[0].name : null
}

output "logs_bucket_url" {
  description = "The URL of the logs bucket"
  value       = var.enable_logging ? google_storage_bucket.logs[0].url : null
}
