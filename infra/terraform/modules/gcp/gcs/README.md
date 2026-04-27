# GCP Cloud Storage (GCS) Module

Manages a Google Cloud Storage bucket with versioning, lifecycle rules, access logging, IAM bindings, and CORS configuration.

## Usage

```hcl
module "gcs" {
  source     = "../../modules/gcp/gcs"
  bucket_name = "my-gcp-project-fawkes-artifacts"
  location    = "us-central1"
  project_id  = "my-gcp-project"

  storage_class     = "STANDARD"
  enable_versioning = true

  tags = {
    environment = "dev"
    platform    = "fawkes"
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.6.0 |
| google | >= 5.0.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| bucket_name | Name of the bucket (globally unique) | `string` | n/a | yes |
| location | GCS bucket location (region or multi-region) | `string` | n/a | yes |
| project_id | GCP project ID | `string` | n/a | yes |
| storage_class | Storage class | `string` | `"STANDARD"` | no |
| uniform_bucket_level_access | Enable uniform bucket-level access | `bool` | `true` | no |
| force_destroy | Allow bucket destruction with objects | `bool` | `false` | no |
| enable_versioning | Enable object versioning | `bool` | `true` | no |
| kms_key_name | Cloud KMS key name for encryption | `string` | `null` | no |
| lifecycle_rules | List of lifecycle rules | `list(object)` | `[]` | no |
| cors_rules | List of CORS rules | `list(object)` | `[]` | no |
| enable_logging | Enable access logging | `bool` | `true` | no |
| log_object_prefix | Prefix for log objects | `string` | `"log/"` | no |
| public_access_prevention | Public access prevention setting | `string` | `"enforced"` | no |
| retention_policy_retention_period | Retention period in seconds | `number` | `null` | no |
| retention_policy_is_locked | Lock the retention policy | `bool` | `false` | no |
| website_main_page_suffix | Main page suffix for website hosting | `string` | `null` | no |
| website_not_found_page | Not found page for website hosting | `string` | `null` | no |
| iam_bindings | IAM bindings for the bucket | `list(object)` | `[]` | no |
| iam_members | IAM members for the bucket | `list(object)` | `[]` | no |
| bucket_acl | Bucket ACL entries | `list(object)` | `[]` | no |
| tags | Labels to apply to resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| bucket_name | The name of the bucket |
| bucket_url | The URL of the bucket |
| bucket_self_link | The self link of the bucket |
| bucket_id | The ID of the bucket |
| logs_bucket_name | The name of the logs bucket |
| logs_bucket_url | The URL of the logs bucket |

## Validation Rules

- Bucket name must be 3–63 characters
- Bucket name must start and end with a number or letter, contain only lowercase letters, numbers, hyphens, underscores, and periods
- Storage class must be `STANDARD`, `NEARLINE`, `COLDLINE`, or `ARCHIVE`
- Public access prevention must be `inherited` or `enforced`
- Lifecycle rule action_type must be `Delete`, `SetStorageClass`, or `AbortIncompleteMultipartUpload`
- Bucket ACL role must be `OWNER`, `READER`, or `WRITER`
- Retention period must be null or a non-negative number
