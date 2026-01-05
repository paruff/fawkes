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
  description = "The name of the bucket"
  value       = aws_s3_bucket.main.id
}

output "bucket_arn" {
  description = "The ARN of the bucket"
  value       = aws_s3_bucket.main.arn
}

output "bucket_domain_name" {
  description = "The bucket domain name"
  value       = aws_s3_bucket.main.bucket_domain_name
}

output "bucket_regional_domain_name" {
  description = "The bucket region-specific domain name"
  value       = aws_s3_bucket.main.bucket_regional_domain_name
}

output "bucket_region" {
  description = "The AWS region this bucket resides in"
  value       = aws_s3_bucket.main.region
}

output "logs_bucket_id" {
  description = "The name of the logging bucket"
  value       = var.enable_logging ? aws_s3_bucket.logs[0].id : null
}

output "logs_bucket_arn" {
  description = "The ARN of the logging bucket"
  value       = var.enable_logging ? aws_s3_bucket.logs[0].arn : null
}

output "replication_role_arn" {
  description = "The ARN of the replication IAM role"
  value       = var.replication_configuration != null && var.enable_versioning ? aws_iam_role.replication[0].arn : null
}
