# Azure Terraform State Backend Module

This module provisions the Azure infrastructure required to store Terraform state remotely
with native blob locking and encryption. It creates a resource group, a Storage Account
(GRS, versioned, soft-delete enabled), and a private container named `tfstate`.

## Features

- **Remote State Storage**: Azure Blob Storage with geo-redundancy (GRS)
- **State Locking**: Azure Blob Storage native lease-based locking (no extra resource needed)
- **Encryption at Rest**: Storage Service Encryption (SSE) enabled by default on all Azure Storage Accounts
- **Encryption in Transit**: HTTPS-only enforced, TLS 1.2 minimum
- **Access Controls**: Private container, no public access, optional IP/subnet restrictions
- **Backups**: Blob versioning + soft delete (configurable retention)

## Usage

```hcl
module "terraform_state" {
  source = "../../modules/azure/state-backend"

  project_name         = "fawkes"
  environment          = "dev"
  location             = "eastus2"
  storage_account_name = "fawkestfstatedev"

  soft_delete_retention_days = 30

  tags = {
    Team = "platform"
  }
}
```

After applying, initialise any Terraform root module with:

```bash
terraform init -backend-config=environments/azure-dev/backend.hcl
```

## Bootstrap (first-time setup)

Use the bootstrap script to create state infrastructure before any Terraform workspace exists:

```bash
./scripts/bootstrap-terraform-state.sh --cloud azure --environment dev --location eastus2
```

## Workspace Strategy

| Environment | Container | State Key                    | Workspace    |
|-------------|-----------|------------------------------|--------------|
| dev         | tfstate   | `dev/terraform.tfstate`      | `dev`        |
| staging     | tfstate   | `staging/terraform.tfstate`  | `staging`    |
| prod        | tfstate   | `prod/terraform.tfstate`     | `prod`       |

See [`infra/terraform/environments/README.md`](../../environments/README.md) for full details.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.6.0 |
| azurerm | >= 3.110.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| project\_name | Project name prefix for resource naming | `string` | n/a | yes |
| environment | Deployment environment (dev, staging, prod) | `string` | n/a | yes |
| location | Azure region for state resources | `string` | n/a | yes |
| storage\_account\_name | Globally unique storage account name (3-24 chars, lowercase alphanumeric) | `string` | n/a | yes |
| resource\_group\_name | Override for resource group name | `string` | `null` | no |
| soft\_delete\_retention\_days | Days to retain soft-deleted blobs and containers | `number` | `30` | no |
| allowed\_ip\_ranges | IP CIDR ranges allowed to access storage account | `list(string)` | `[]` | no |
| allowed\_subnet\_ids | Subnet IDs allowed via service endpoints | `list(string)` | `[]` | no |
| tags | Additional tags applied to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| resource\_group\_name | Name of the state resource group |
| resource\_group\_id | ID of the state resource group |
| storage\_account\_name | Name of the storage account |
| storage\_account\_id | ID of the storage account |
| primary\_access\_key | Storage account primary key (sensitive) |
| container\_name | Name of the tfstate container |
| backend\_config | Rendered backend.hcl content |
