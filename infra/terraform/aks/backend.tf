# Copyright (c) 2025  Philip Ruff
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
# DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
# OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE
# OR OTHER DEALINGS IN THE SOFTWARE.

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
