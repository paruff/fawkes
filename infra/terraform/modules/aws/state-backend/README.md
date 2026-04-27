# AWS Terraform State Backend Module

This module provisions the AWS infrastructure required to store Terraform state remotely
with locking and encryption. It creates an S3 bucket (versioned, encrypted), a DynamoDB
table (state locking, PITR), and optionally a dedicated KMS key.

## Features

- **Remote State Storage**: S3 bucket with versioning for state recovery
- **State Locking**: DynamoDB table prevents concurrent `terraform apply` runs
- **Encryption at Rest**: KMS-managed (aws:kms) or AWS-managed (AES-256) SSE
- **Encryption in Transit**: Bucket policy enforces HTTPS-only access
- **Access Controls**: Least-privilege IAM policy document output
- **Backups**: DynamoDB point-in-time recovery + S3 versioning
- **Lifecycle Management**: Automatic expiry of old non-current state versions

## Usage

```hcl
module "terraform_state" {
  source = "../../modules/aws/state-backend"

  project_name           = "fawkes"
  environment            = "dev"
  aws_region             = "us-east-1"
  enable_kms_encryption  = true
  versioning_expiration_days = 90

  tags = {
    Team = "platform"
  }
}
```

After applying, initialise any Terraform root module with:

```bash
terraform init -backend-config=environments/dev/backend.hcl
```

## Bootstrap (first-time setup)

Use the bootstrap script to create state infrastructure before any Terraform workspace exists:

```bash
./scripts/bootstrap-terraform-state.sh --cloud aws --environment dev --region us-east-1
```

## Workspace Strategy

| Environment | State Key                    | Workspace    |
|-------------|------------------------------|--------------|
| dev         | `dev/terraform.tfstate`      | `dev`        |
| staging     | `staging/terraform.tfstate`  | `staging`    |
| prod        | `prod/terraform.tfstate`     | `prod`       |

See [`infra/terraform/environments/README.md`](../../environments/README.md) for full details.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.6.0 |
| aws | >= 5.0.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| project\_name | Name of the project, used as resource name prefix | `string` | n/a | yes |
| environment | Deployment environment (dev, staging, prod) | `string` | n/a | yes |
| aws\_region | AWS region for state resources | `string` | n/a | yes |
| enable\_kms\_encryption | Use a dedicated KMS key for encryption | `bool` | `true` | no |
| state\_bucket\_name | Override for S3 bucket name | `string` | `null` | no |
| dynamodb\_table\_name | Override for DynamoDB table name | `string` | `null` | no |
| versioning\_expiration\_days | Days to retain non-current state versions | `number` | `90` | no |
| tags | Additional tags applied to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| state\_bucket\_name | Name of the S3 state bucket |
| state\_bucket\_arn | ARN of the S3 state bucket |
| state\_bucket\_region | Region of the S3 state bucket |
| dynamodb\_table\_name | Name of the DynamoDB lock table |
| dynamodb\_table\_arn | ARN of the DynamoDB lock table |
| kms\_key\_id | ID of the KMS encryption key |
| kms\_key\_arn | ARN of the KMS encryption key |
| backend\_config | Rendered backend.hcl content |
| state\_access\_policy\_document | JSON IAM policy for CI/CD state access |
