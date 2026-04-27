# Terraform Environment Backend Configurations

This directory contains backend configuration files (`.hcl`) for each environment and cloud
provider. These files are passed to `terraform init` with the `-backend-config` flag and
are **never** embedded in the Terraform root module source.

## Why separate backend configs?

Embedding the `backend` block directly in `main.tf` forces you to either hard-code
environment-specific values or use partial configuration. The `-backend-config` approach:

- Keeps environment secrets (bucket names, keys) out of the main codebase
- Allows the same Terraform code to target multiple environments without code changes
- Is the recommended pattern for multi-environment GitOps workflows

## Directory Structure

```
environments/
├── dev/                    # AWS dev backend
│   └── backend.hcl
├── staging/                # AWS staging backend
│   └── backend.hcl
├── prod/                   # AWS prod backend
│   └── backend.hcl
├── azure-dev/              # Azure dev backend
│   └── backend.hcl
├── azure-staging/          # Azure staging backend
│   └── backend.hcl
└── azure-prod/             # Azure prod backend
    └── backend.hcl
```

## Workspace Strategy

Fawkes uses Terraform workspaces to separate state by environment within a single backend.

| Environment | Workspace Name | State Key                   |
|-------------|----------------|-----------------------------|
| dev         | `dev`          | `dev/terraform.tfstate`     |
| staging     | `staging`      | `staging/terraform.tfstate` |
| prod        | `prod`         | `prod/terraform.tfstate`    |

## First-Time Setup (Bootstrap)

Before you can use these backend configs, the S3 bucket/DynamoDB table (AWS) or Storage
Account (Azure) must exist. Use the bootstrap script — it does not require Terraform state
itself to run:

```bash
# AWS dev
./scripts/bootstrap-terraform-state.sh --cloud aws --environment dev --region us-east-1

# Azure dev
./scripts/bootstrap-terraform-state.sh --cloud azure --environment dev --location eastus2
```

The script prints a `backend.hcl` block that you should compare against the file in this
directory and update if your resource names differ.

## Initialising a Workspace

```bash
# 1. Initialise with the environment-specific backend config
terraform init -backend-config=infra/terraform/environments/dev/backend.hcl

# 2. Select (or create) the workspace
terraform workspace select dev || terraform workspace new dev

# 3. Plan and apply as normal
terraform plan -out=tfplan
terraform apply tfplan
```

## Switching Environments

```bash
# Switch to staging
terraform workspace select staging
terraform init -reconfigure -backend-config=infra/terraform/environments/staging/backend.hcl
```

## Access Controls

- **AWS**: The CI/CD IAM role must have the permissions listed in the `state_access_policy_document` output of the `aws/state-backend` module.
- **Azure**: The CI/CD service principal must have `Storage Blob Data Contributor` on the storage account.

## Security Notes

- The `.hcl` files contain bucket/storage-account names but **no credentials**. Credentials are sourced from environment variables (`AWS_ACCESS_KEY_ID`, `ARM_CLIENT_ID`, etc.) or OIDC federation in CI.
- **Prefer OIDC federation over static credentials in CI/CD.** OIDC eliminates long-lived secrets in CI environments. For AWS, use the `aws-actions/configure-aws-credentials` action with `role-to-assume`; for Azure, use `azure/login` with federated identity.
- Do **not** commit actual `.tfstate` files to Git. The `.gitignore` at the repo root excludes `*.tfstate` and `*.tfstate.backup`.
- Prod backend configs require two-person review before merging changes (see `AGENTS.md`).
