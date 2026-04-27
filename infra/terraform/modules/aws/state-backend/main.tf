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

locals {
  bucket_name        = var.state_bucket_name != null ? var.state_bucket_name : "${var.project_name}-tfstate-${var.environment}"
  dynamodb_table     = var.dynamodb_table_name != null ? var.dynamodb_table_name : "${var.project_name}-tfstate-lock-${var.environment}"
  kms_key_alias      = "alias/${var.project_name}-tfstate-${var.environment}"
  common_tags = merge(
    var.tags,
    {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
      Component   = "state-backend"
    }
  )
}

# KMS Key for state encryption
resource "aws_kms_key" "state" {
  count = var.enable_kms_encryption ? 1 : 0

  description             = "KMS key for Terraform state encryption - ${var.project_name} ${var.environment}"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow S3 to use the key"
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
        Action = [
          "kms:GenerateDataKey",
          "kms:Decrypt"
        ]
        Resource = "*"
      }
    ]
  })

  tags = merge(local.common_tags, { Name = local.kms_key_alias })
}

resource "aws_kms_alias" "state" {
  count = var.enable_kms_encryption ? 1 : 0

  name          = local.kms_key_alias
  target_key_id = aws_kms_key.state[0].key_id
}

data "aws_caller_identity" "current" {}

# S3 Bucket for Terraform State
resource "aws_s3_bucket" "state" {
  bucket        = local.bucket_name
  force_destroy = false

  tags = merge(local.common_tags, { Name = local.bucket_name })
}

# Block all public access
resource "aws_s3_bucket_public_access_block" "state" {
  bucket = aws_s3_bucket.state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enable versioning for state recovery
resource "aws_s3_bucket_versioning" "state" {
  bucket = aws_s3_bucket.state.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  bucket = aws_s3_bucket.state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.enable_kms_encryption ? "aws:kms" : "AES256"
      kms_master_key_id = var.enable_kms_encryption ? aws_kms_key.state[0].arn : null
    }
    bucket_key_enabled = var.enable_kms_encryption
  }
}

# Lifecycle rules to expire old non-current versions and abort incomplete uploads
resource "aws_s3_bucket_lifecycle_configuration" "state" {
  bucket     = aws_s3_bucket.state.id
  depends_on = [aws_s3_bucket_versioning.state]

  rule {
    id     = "expire-old-state-versions"
    status = "Enabled"

    noncurrent_version_expiration {
      noncurrent_days = var.versioning_expiration_days
    }
  }

  rule {
    id     = "abort-incomplete-multipart-uploads"
    status = "Enabled"

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

# Bucket policy: enforce encryption in transit and deny non-secure transport
resource "aws_s3_bucket_policy" "state" {
  bucket = aws_s3_bucket.state.id

  # Depend on public access block to avoid conflicts
  depends_on = [aws_s3_bucket_public_access_block.state]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "DenyNonTLS"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.state.arn,
          "${aws_s3_bucket.state.arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })
}

# DynamoDB table for state locking
resource "aws_dynamodb_table" "state_lock" {
  name         = local.dynamodb_table
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  # TTL for stale lock entry cleanup.
  # NOTE: Terraform's built-in state locking does not populate the TTL attribute.
  # This setting enables future automation (e.g., a Lambda) to set TTL on lock
  # entries so that orphaned locks from crashed Terraform runs are automatically
  # expired by DynamoDB. The attribute is optional and does not interfere with
  # Terraform's normal locking behaviour when left unpopulated.
  ttl {
    attribute_name = "TTL"
    enabled        = true
  }

  # Server-side encryption
  server_side_encryption {
    enabled     = true
    kms_key_arn = var.enable_kms_encryption ? aws_kms_key.state[0].arn : null
  }

  # Point-in-time recovery for backup
  point_in_time_recovery {
    enabled = true
  }

  tags = merge(local.common_tags, { Name = local.dynamodb_table })
}
