# AWS S3 backend configuration for the dev environment.
# Usage: terraform init -backend-config=environments/dev/backend.hcl
#
# Before using this file, bootstrap the state backend:
#   ./scripts/bootstrap-terraform-state.sh --cloud aws --environment dev --region us-east-1

bucket         = "fawkes-tfstate-dev"
key            = "dev/terraform.tfstate"
region         = "us-east-1"
encrypt        = true
dynamodb_table = "fawkes-tfstate-lock-dev"
