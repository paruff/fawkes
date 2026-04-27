# AWS S3 backend configuration for the staging environment.
# Usage: terraform init -backend-config=environments/staging/backend.hcl
#
# Before using this file, bootstrap the state backend:
#   ./scripts/bootstrap-terraform-state.sh --cloud aws --environment staging --region us-east-1

bucket         = "fawkes-tfstate-staging"
key            = "staging/terraform.tfstate"
region         = "us-east-1"
encrypt        = true
dynamodb_table = "fawkes-tfstate-lock-staging"
