# Azure Blob backend configuration for the prod environment.
# Usage: terraform init -backend-config=environments/azure-prod/backend.hcl
#
# Before using this file, bootstrap the state backend:
#   ./scripts/bootstrap-terraform-state.sh --cloud azure --environment prod --location eastus2
#
# NOTE: Prod state access requires elevated permissions. Consult the runbook:
#   docs/runbooks/terraform-state-management.md

resource_group_name  = "fawkes-tfstate-prod-rg"
storage_account_name = "fawkestfstateprd"
container_name       = "tfstate"
key                  = "prod/terraform.tfstate"
