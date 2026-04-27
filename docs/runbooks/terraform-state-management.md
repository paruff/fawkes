# Runbook: Terraform State Management

**Category**: Infrastructure  
**Owner**: Platform Team  
**Related Module**: `infra/terraform/modules/aws/state-backend`, `infra/terraform/modules/azure/state-backend`  
**Bootstrap Script**: `scripts/bootstrap-terraform-state.sh`  

---

## Purpose

This runbook covers day-to-day operations for Terraform remote state in Fawkes:

- Bootstrapping a new environment's state backend
- Initialising a workspace
- Switching environments
- Recovering from a corrupt or lost lock
- Restoring state from a backup

---

## Prerequisites

| Tool | Minimum Version | Purpose |
|------|-----------------|---------|
| `terraform` | 1.6.0 | IaC execution |
| `aws` CLI | 2.x | AWS state operations |
| `az` CLI | 2.x | Azure state operations |
| `jq` | 1.6 | JSON parsing (optional) |

---

## 1. Bootstrap a New Environment

Use this procedure when creating a **new environment** (dev, staging, or prod) for the
first time. The state infrastructure must exist before Terraform can store state.

### AWS

```bash
./scripts/bootstrap-terraform-state.sh \
  --cloud aws \
  --environment dev \
  --region us-east-1
```

The script creates:

- S3 bucket: `fawkes-tfstate-<env>` (versioned, AES-256 encrypted, TLS-only)
- DynamoDB table: `fawkes-tfstate-lock-<env>` (PAY_PER_REQUEST, PITR enabled)

### Azure

```bash
./scripts/bootstrap-terraform-state.sh \
  --cloud azure \
  --environment dev \
  --location eastus2
```

The script creates:

- Resource group: `fawkes-tfstate-<env>-rg`
- Storage account: `fawkestfstate<env_short>` (GRS, TLS 1.2, versioning, soft-delete)
- Container: `tfstate` (private access)

---

## 2. Initialise a Terraform Workspace

```bash
# 1. Navigate to the Terraform root module
cd infra/terraform/aks    # or wherever your root module lives

# 2. Initialise with environment-specific backend config
terraform init -backend-config=../../environments/dev/backend.hcl

# 3. Select or create the workspace
terraform workspace select dev 2>/dev/null || terraform workspace new dev

# 4. Verify state connection
terraform state list
```

---

## 3. Switch Environments

```bash
# Switch from dev to staging
terraform workspace select staging
terraform init -reconfigure -backend-config=../../environments/staging/backend.hcl

# Verify correct workspace is active
terraform workspace show
```

---

## 4. Recover from a Stale Lock (AWS)

If a `terraform apply` was interrupted, the DynamoDB lock entry may remain, blocking
subsequent runs.

### Identify the lock

```bash
aws dynamodb get-item \
  --table-name fawkes-tfstate-lock-dev \
  --key '{"LockID": {"S": "fawkes-tfstate-dev/dev/terraform.tfstate"}}' \
  --region us-east-1
```

### Force-unlock (use with caution)

Only unlock if you are **certain** no other `terraform` process is running.

The lock ID is shown in the Terraform error message, for example:

```
Error: Error acquiring the state lock

  Lock Info:
    ID:        a1b2c3d4-e5f6-7890-abcd-ef1234567890
    Path:      fawkes-tfstate-dev/dev/terraform.tfstate
    Operation: OperationTypeApply
    Who:       runner@ci-host
    Version:   1.6.0
    Created:   2025-04-27 10:00:00.000000 +0000 UTC
    Info:
```

```bash
# Use the ID shown above
terraform force-unlock a1b2c3d4-e5f6-7890-abcd-ef1234567890
```

### Azure: Release a blob lease

```bash
az storage blob lease break \
  --account-name fawkestfstatedev \
  --container-name tfstate \
  --blob-name dev/terraform.tfstate
```

---

## 5. Restore State from a Backup (AWS)

If the state file is corrupt, restore a previous version from S3:

```bash
# List available versions
aws s3api list-object-versions \
  --bucket fawkes-tfstate-dev \
  --prefix dev/terraform.tfstate \
  --query 'Versions[*].{VersionId:VersionId,LastModified:LastModified}' \
  --output table

# Download a specific version
aws s3api get-object \
  --bucket fawkes-tfstate-dev \
  --key dev/terraform.tfstate \
  --version-id <VERSION_ID> \
  /tmp/terraform.tfstate.restored

# After verifying the restored file:
aws s3 cp /tmp/terraform.tfstate.restored \
  s3://fawkes-tfstate-dev/dev/terraform.tfstate
```

---

## 6. Restore State from a Backup (Azure)

```bash
# List blob versions
az storage blob list-versions \
  --account-name fawkestfstatedev \
  --container-name tfstate \
  --name dev/terraform.tfstate \
  --output table

# Download a specific version
az storage blob download \
  --account-name fawkestfstatedev \
  --container-name tfstate \
  --name dev/terraform.tfstate \
  --version-id <VERSION_ID> \
  --file /tmp/terraform.tfstate.restored
```

---

## 7. Grant CI/CD Access (AWS)

Attach the IAM policy from the module's `state_access_policy_document` output to the
CI/CD IAM role:

```bash
# Get the policy document from Terraform output
terraform output -json state_access_policy_document

# Create and attach inline policy to CI role
aws iam put-role-policy \
  --role-name fawkes-ci-role \
  --policy-name terraform-state-access \
  --policy-document "$(terraform output -json state_access_policy_document)"
```

---

## 8. Grant CI/CD Access (Azure)

```bash
# Get the CI/CD service principal object ID
SP_ID=$(az ad sp show --id "<client-id>" --query id --output tsv)

# Assign Storage Blob Data Contributor on the storage account
az role assignment create \
  --assignee "${SP_ID}" \
  --role "Storage Blob Data Contributor" \
  --scope "/subscriptions/<sub>/resourceGroups/fawkes-tfstate-dev-rg/providers/Microsoft.Storage/storageAccounts/fawkestfstatedev"
```

---

## 9. Key Files Reference

| File | Description |
|------|-------------|
| `infra/terraform/modules/aws/state-backend/` | AWS state backend Terraform module |
| `infra/terraform/modules/azure/state-backend/` | Azure state backend Terraform module |
| `infra/terraform/environments/dev/backend.hcl` | AWS dev backend config |
| `infra/terraform/environments/azure-dev/backend.hcl` | Azure dev backend config |
| `scripts/bootstrap-terraform-state.sh` | Bootstrap script for first-time setup |
| `docs/KNOWN_LIMITATIONS.md` | KL-01 resolution notes |
