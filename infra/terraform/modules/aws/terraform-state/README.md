# Terraform Remote State Backend Module

> Closes KL-01 / [#1569](https://github.com/paruff/fawkes/issues/1569)

Provides an S3 bucket with versioning, encryption, and public-access blocking, plus a
DynamoDB table for state locking. Concurrent `terraform apply` runs will now fail-fast
instead of silently corrupting state.

## Usage

```hcl
module "terraform_state" {
  source = "../../modules/aws/terraform-state"

  state_bucket_name = "fawkes-terraform-state-us-east-1"
  lock_table_name   = "fawkes-terraform-state-lock"
  aws_region        = "us-east-1"

  tags = {
    Environment = "production"
    Team        = "platform"
  }
}
```

## Migrating an Existing Module

After applying this module, add a `backend "s3"` block to each existing module:

```hcl
terraform {
  backend "s3" {
    bucket         = "fawkes-terraform-state-us-east-1"
    key            = "argocd/terraform.tfstate"   # path within the state bucket
    region         = "us-east-1"
    dynamodb_table = "fawkes-terraform-state-lock"
    encrypt        = true
  }
}
```

Then run `terraform init -migrate-state` to move local state into the remote backend.

## What This Fixes

| Before | After |
|--------|-------|
| State stored locally in `.tfstate` files | State stored in versioned, encrypted S3 bucket |
| No state locking — concurrent applies corrupt state | DynamoDB locking prevents concurrent applies |
| No disaster recovery | S3 versioning enables state recovery |
| Secrets visible in plaintext state files | Server-side encryption (AES-256 or KMS) |

## Security

- All public access blocked
- Server-side encryption enabled
- State locking via DynamoDB `LockID` attribute
- Versioning enabled for state recovery
