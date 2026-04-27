# AWS S3 backend configuration for the prod environment.
# Usage: terraform init -backend-config=environments/prod/backend.hcl
#
# Before using this file, bootstrap the state backend:
#   ./scripts/bootstrap-terraform-state.sh --cloud aws --environment prod --region us-east-1
#
# NOTE: Prod state access requires elevated permissions. Consult the runbook:
#   docs/runbooks/terraform-state-management.md

bucket         = "fawkes-tfstate-prod"
key            = "prod/terraform.tfstate"
region         = "us-east-1"
encrypt        = true
dynamodb_table = "fawkes-tfstate-lock-prod"
