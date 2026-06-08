# =============================================================================
# Remote State Backend — Azure Blob Storage
# =============================================================================
# Usage:
#   terraform init -backend-config="resource_group_name=fawkes-terraform" \
#                  -backend-config="storage_account_name=fawkestfstate" \
#                  -backend-config="container_name=tfstate" \
#                  -backend-config="key=aks/terraform.tfstate"
#
# Or use a backend.hcl file:
#   terraform init -backend-config=backend.hcl
# =============================================================================

terraform {
  backend "azurerm" {
    #resource_group_name  = "fawkes-terraform"
    #storage_account_name = "fawkestfstate"
    #container_name       = "tfstate"
    #key                  = "aks/terraform.tfstate"

    # Uncomment above and provide values via -backend-config or backend.hcl
    # Default: local state (temporary — migrate to Azure Blob before team use)
  }
}
