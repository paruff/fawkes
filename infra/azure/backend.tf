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
# Resolves KL-01 / GAP-7 / #1153 / #1569: this module's state was previously
# local-only (.tfstate on disk), with no locking and no shared/DR-safe
# location. Azure Blob Storage's backend provides both in one place: Azure
# takes an exclusive lease on the blob for the duration of each
# plan/apply (no separate DynamoDB-equivalent needed, unlike the S3 backend).
#
# Storage account + container were provisioned once, out-of-band, via:
#   az group create --name fawkes-rg --location eastus2
#   az storage account create --name fawkestfstate01 --resource-group fawkes-rg \
#     --location eastus2 --sku Standard_LRS --kind StorageV2 \
#     --min-tls-version TLS1_2 --allow-blob-public-access false
#   az storage account blob-service-properties update \
#     --account-name fawkestfstate01 --resource-group fawkes-rg \
#     --enable-versioning true
#   az storage container create --name tfstate --account-name fawkestfstate01 \
#     --auth-mode login
#
# Auth: uses the current `az login` session (Azure CLI auth) - no storage
# account key or service principal secret is stored anywhere. Whoever runs
# `terraform init`/`plan`/`apply` needs Storage Blob Data Contributor (or
# above) on this storage account.
# =============================================================================

terraform {
  backend "azurerm" {
    resource_group_name  = "fawkes-rg"
    storage_account_name = "fawkestfstate01"
    container_name       = "tfstate"
    key                  = "azure/terraform.tfstate"
    use_azuread_auth     = true
  }
}
