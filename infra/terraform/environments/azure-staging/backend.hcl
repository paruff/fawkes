# Azure Blob backend configuration for the staging environment.
# Usage: terraform init -backend-config=environments/azure-staging/backend.hcl
#
# Before using this file, bootstrap the state backend:
#   ./scripts/bootstrap-terraform-state.sh --cloud azure --environment staging --location eastus2

resource_group_name  = "fawkes-tfstate-staging-rg"
storage_account_name = "fawkestfstatestg"
container_name       = "tfstate"
key                  = "staging/terraform.tfstate"
