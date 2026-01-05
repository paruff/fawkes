# AWS S3 Module

This module creates a production-ready Amazon S3 bucket with encryption, versioning, lifecycle policies, and access logging.

## Features

- **Encryption**: Server-side encryption with AES-256 or KMS
- **Versioning**: Optional object versioning
- **Lifecycle Policies**: Automated data lifecycle management
- **Access Logging**: Audit trail of bucket access
- **CORS**: Cross-Origin Resource Sharing configuration
- **Object Lock**: WORM (Write Once Read Many) compliance
- **Replication**: Cross-region replication support
- **Security**: Block public access by default

## Usage

```hcl
module "s3" {
  source = "../../modules/aws/s3"

  bucket_name        = "fawkes-dev-data"
  enable_versioning  = true
  sse_algorithm      = "AES256"
  enable_logging     = true

  lifecycle_rules = [
    {
      id      = "archive-old-versions"
      enabled = true
      prefix  = "logs/"
      
      transitions = [
        {
          days          = 30
          storage_class = "STANDARD_IA"
        },
        {
          days          = 90
          storage_class = "GLACIER"
        }
      ]
      
      expiration_days = 365
      noncurrent_version_expiration_days = 90
      noncurrent_version_transitions = []
    }
  ]

  tags = {
    Environment = "dev"
    Platform    = "fawkes"
    ManagedBy   = "terraform"
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.6.0 |
| aws | >= 5.0.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| bucket_name | Name of the S3 bucket | `string` | n/a | yes |
| force_destroy | Allow bucket deletion with objects | `bool` | `false` | no |
| enable_versioning | Enable object versioning | `bool` | `false` | no |
| sse_algorithm | Encryption algorithm (AES256 or aws:kms) | `string` | `"AES256"` | no |
| kms_key_id | KMS key ID for encryption | `string` | `null` | no |
| enable_logging | Enable access logging | `bool` | `false` | no |
| lifecycle_rules | Lifecycle rules | `list(object)` | `[]` | no |
| bucket_policy | JSON bucket policy | `string` | `null` | no |
| cors_rules | CORS configuration | `list(object)` | `[]` | no |
| enable_object_lock | Enable object lock | `bool` | `false` | no |
| replication_configuration | Replication configuration | `object` | `null` | no |
| tags | Tags to apply to resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| bucket_id | S3 bucket name |
| bucket_arn | S3 bucket ARN |
| bucket_domain_name | Bucket domain name |
| bucket_regional_domain_name | Bucket regional domain name |
| logs_bucket_id | Logging bucket name |
| logs_bucket_arn | Logging bucket ARN |

## Lifecycle Policy Examples

### Archive to Glacier
```hcl
lifecycle_rules = [
  {
    id      = "archive-policy"
    enabled = true
    prefix  = "archive/"
    
    transitions = [
      {
        days          = 30
        storage_class = "STANDARD_IA"
      },
      {
        days          = 90
        storage_class = "GLACIER"
      }
    ]
    
    expiration_days = null
    noncurrent_version_expiration_days = null
    noncurrent_version_transitions = []
  }
]
```

### Delete Old Versions
```hcl
lifecycle_rules = [
  {
    id      = "cleanup-old-versions"
    enabled = true
    prefix  = null
    
    transitions = []
    expiration_days = null
    noncurrent_version_expiration_days = 90
    noncurrent_version_transitions = []
  }
]
```

### Temporary Files Cleanup
```hcl
lifecycle_rules = [
  {
    id      = "temp-files"
    enabled = true
    prefix  = "temp/"
    
    transitions = []
    expiration_days = 7
    noncurrent_version_expiration_days = null
    noncurrent_version_transitions = []
  }
]
```

## Bucket Policy Examples

### Allow CloudFront Access
```hcl
bucket_policy = jsonencode({
  Version = "2012-10-17"
  Statement = [
    {
      Sid    = "AllowCloudFrontAccess"
      Effect = "Allow"
      Principal = {
        AWS = "arn:aws:iam::cloudfront:user/CloudFront Origin Access Identity ${aws_cloudfront_origin_access_identity.main.id}"
      }
      Action   = "s3:GetObject"
      Resource = "${module.s3.bucket_arn}/*"
    }
  ]
})
```

### Enforce SSL
```hcl
bucket_policy = jsonencode({
  Version = "2012-10-17"
  Statement = [
    {
      Sid    = "EnforceSSL"
      Effect = "Deny"
      Principal = "*"
      Action = "s3:*"
      Resource = [
        "${module.s3.bucket_arn}",
        "${module.s3.bucket_arn}/*"
      ]
      Condition = {
        Bool = {
          "aws:SecureTransport" = "false"
        }
      }
    }
  ]
})
```

## CORS Configuration Example

```hcl
cors_rules = [
  {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "HEAD"]
    allowed_origins = ["https://example.com"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
]
```

## Security Best Practices

1. **Block Public Access**: Keep all block public access settings enabled (default)
2. **Encryption**: Always enable encryption at rest
3. **Versioning**: Enable versioning for critical data
4. **Access Logging**: Enable logging for audit trails
5. **SSL/TLS**: Use bucket policies to enforce HTTPS
6. **Least Privilege**: Use IAM policies with minimum required permissions
7. **Object Lock**: Enable for compliance and WORM requirements

## Cost Optimization

- **Storage Classes**: Use lifecycle policies to transition to cheaper storage
  - STANDARD_IA: ~50% cheaper for infrequently accessed data (>30 days)
  - GLACIER: ~80% cheaper for archival (>90 days)
  - DEEP_ARCHIVE: ~95% cheaper for long-term archival (>180 days)
- **Versioning**: Clean up old versions with lifecycle policies
- **Access Logging**: Be aware logging doubles storage costs for logged data
- **Replication**: Only replicate critical data (replication incurs transfer costs)

## Storage Class Transition Timeline

```
Day 0      Day 30         Day 90         Day 365
  │           │              │               │
  ▼           ▼              ▼               ▼
STANDARD → STANDARD_IA → GLACIER → GLACIER_DEEP_ARCHIVE
$0.023/GB   $0.0125/GB   $0.004/GB    $0.00099/GB
```

## Examples

See the [examples directory](../examples/) for complete usage examples:
- [s3](../examples/s3/) - S3 bucket configuration
- [complete](../examples/complete/) - Complete AWS infrastructure with VPC, EKS, RDS, and S3
