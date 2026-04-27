# Azure Blob backend configuration for the dev environment.
# Usage: terraform init -backend-config=environments/azure-dev/backend.hcl
#
# Before using this file, bootstrap the state backend:
#   ./scripts/bootstrap-terraform-state.sh --cloud azure --environment dev --location eastus2

resource_group_name  = "fawkes-tfstate-dev-rg"
storage_account_name = "fawkestfstatedev"
container_name       = "tfstate"
key                  = "dev/terraform.tfstate"
