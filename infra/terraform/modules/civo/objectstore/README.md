# Civo Object Store Module

Manages an S3-compatible Civo Object Store bucket with optional credential generation.

## Usage

```hcl
module "objectstore" {
  source      = "../../modules/civo/objectstore"
  bucket_name = "fawkes-artifacts"
  location    = "NYC1"
  max_size_gb = 500

  create_credentials = true
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.6.0 |
| civo | >= 1.0.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| bucket_name | Name of the S3-compatible bucket | `string` | n/a | yes |
| location | Civo region (NYC1, LON1, FRA1, PHX1) | `string` | n/a | yes |
| max_size_gb | Maximum size of the object store in GB | `number` | `500` | no |
| access_key_id | S3 access key ID (optional, sensitive) | `string` | `null` | no |
| create_credentials | Create object store credentials | `bool` | `true` | no |

## Outputs

| Name | Description |
|------|-------------|
| bucket_id | The ID of the object store |
| bucket_name | The name of the bucket |
| bucket_url | URL endpoint for the object store |
| access_key_id | Access key ID for S3 API access (sensitive) |
| secret_access_key | Secret access key for S3 API access (sensitive) |
| max_size_gb | Maximum size in GB |
| status | Status of the object store |
| region | Region where the object store is deployed |
| endpoint | S3-compatible endpoint URL |
| credentials_id | ID of the generated credentials |
| s3_configuration | Full S3 configuration (sensitive) |

## Validation Rules

- Bucket name must be 3–63 characters
- Bucket name must start and end with lowercase letter or number, contain only lowercase letters, numbers, and hyphens
- Location must be one of: `NYC1`, `LON1`, `FRA1`, `PHX1`
- Max size must be 1–10000 GB

## S3 API Usage

The module outputs an `s3_configuration` object with all details needed to configure S3-compatible clients:

```hcl
endpoint          = "https://objectstore.NYC1.civo.com"
bucket            = "fawkes-artifacts"
region            = "NYC1"
access_key_id     = "<generated>"
secret_access_key = "<generated>"
```
