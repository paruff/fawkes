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
  description = "Name of the created Terraform state S3 bucket"
  value       = module.state_bucket.bucket_id
}

output "dynamodb_table_name" {
  description = "Name of the created Terraform state lock DynamoDB table"
  value       = aws_dynamodb_table.lock.name
}

output "backend_config_command" {
  description = "Command to run from infra/aws/ to migrate to this backend"
  value       = <<-EOT
    terraform init \
      -backend-config="bucket=${module.state_bucket.bucket_id}" \
      -backend-config="key=aws/terraform.tfstate" \
      -backend-config="region=${var.region}" \
      -backend-config="dynamodb_table=${aws_dynamodb_table.lock.name}" \
      -migrate-state
  EOT
}
