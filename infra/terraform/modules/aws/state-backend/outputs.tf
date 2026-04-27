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

output "state_bucket_name" {
  description = "Name of the S3 bucket used to store Terraform state files."
  value       = aws_s3_bucket.state.id
}

output "state_bucket_arn" {
  description = "ARN of the S3 state bucket."
  value       = aws_s3_bucket.state.arn
}

output "state_bucket_region" {
  description = "AWS region where the state bucket resides."
  value       = aws_s3_bucket.state.region
}

output "dynamodb_table_name" {
  description = "Name of the DynamoDB table used for Terraform state locking."
  value       = aws_dynamodb_table.state_lock.name
}

output "dynamodb_table_arn" {
  description = "ARN of the DynamoDB state lock table."
  value       = aws_dynamodb_table.state_lock.arn
}

output "kms_key_id" {
  description = "ID of the KMS key used for state encryption. Null when KMS encryption is disabled."
  value       = var.enable_kms_encryption ? aws_kms_key.state[0].key_id : null
}

output "kms_key_arn" {
  description = "ARN of the KMS key used for state encryption. Null when KMS encryption is disabled."
  value       = var.enable_kms_encryption ? aws_kms_key.state[0].arn : null
}

output "backend_config" {
  description = "Rendered backend configuration block for use with 'terraform init -backend-config'. Copy this into your environments/<env>/backend.hcl file."
  value = <<-EOT
    bucket         = "${aws_s3_bucket.state.id}"
    key            = "${var.environment}/terraform.tfstate"
    region         = "${var.aws_region}"
    encrypt        = true
    dynamodb_table = "${aws_dynamodb_table.state_lock.name}"
  EOT
}

output "state_access_policy_document" {
  description = "JSON IAM policy document granting least-privilege access to read and write Terraform state. Attach this to the CI/CD IAM role."
  value = jsonencode({
    Version = "2012-10-17"
    Statement = concat(
      [
        {
          Sid    = "TerraformStateAccess"
          Effect = "Allow"
          Action = [
            "s3:GetObject",
            "s3:PutObject",
            "s3:DeleteObject",
            "s3:ListBucket"
          ]
          Resource = [
            aws_s3_bucket.state.arn,
            "${aws_s3_bucket.state.arn}/*"
          ]
        },
        {
          Sid    = "TerraformStateLocking"
          Effect = "Allow"
          Action = [
            "dynamodb:GetItem",
            "dynamodb:PutItem",
            "dynamodb:DeleteItem",
            "dynamodb:DescribeTable"
          ]
          Resource = aws_dynamodb_table.state_lock.arn
        }
      ],
      # Only include KMS permissions when a dedicated KMS key is provisioned.
      var.enable_kms_encryption ? [
        {
          Sid    = "TerraformStateKMS"
          Effect = "Allow"
          Action = [
            "kms:GenerateDataKey",
            "kms:Decrypt"
          ]
          Resource = aws_kms_key.state[0].arn
        }
      ] : []
    )
  })
}
