#!/usr/bin/env bash
# bootstrap-terraform-state.sh — Create Terraform remote state infrastructure
#
# This script bootstraps the state backend (S3+DynamoDB for AWS or
# Azure Blob Storage for Azure) before Terraform itself can run.
# It is intentionally idempotent: re-running it on existing resources is safe.
#
# Usage:
#   ./scripts/bootstrap-terraform-state.sh --cloud aws     --environment dev --region us-east-1
#   ./scripts/bootstrap-terraform-state.sh --cloud azure   --environment dev --location eastus2
#
# Required tools (AWS):  aws cli v2
# Required tools (Azure): az cli

set -euo pipefail

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
PROJECT_NAME="fawkes"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
usage() {
  cat <<EOF
Usage: ${SCRIPT_NAME} --cloud <aws|azure> --environment <dev|staging|prod> [OPTIONS]

Bootstrap Terraform remote state infrastructure for Fawkes.

Required:
  --cloud        Cloud provider: aws or azure
  --environment  Target environment: dev, staging, or prod

AWS options (required when --cloud aws):
  --region       AWS region (e.g. us-east-1)

Azure options (required when --cloud azure):
  --location     Azure region (e.g. eastus2)
  --subscription Azure subscription ID (optional; uses current az account if omitted)

General options:
  -h, --help     Show this help message and exit
EOF
  exit 0
}

log() {
  echo "[${SCRIPT_NAME}] $*" >&2
}

error() {
  echo "[${SCRIPT_NAME}] ERROR: $*" >&2
  exit 1
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || error "Required command '$1' is not installed."
}

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------
CLOUD=""
ENVIRONMENT=""
AWS_REGION=""
AZURE_LOCATION=""
AZURE_SUBSCRIPTION=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --cloud)        CLOUD="$2";               shift 2 ;;
    --environment)  ENVIRONMENT="$2";         shift 2 ;;
    --region)       AWS_REGION="$2";          shift 2 ;;
    --location)     AZURE_LOCATION="$2";      shift 2 ;;
    --subscription) AZURE_SUBSCRIPTION="$2";  shift 2 ;;
    -h|--help)      usage ;;
    *)              error "Unknown argument: $1" ;;
  esac
done

# ---------------------------------------------------------------------------
# Validation
# ---------------------------------------------------------------------------
[[ -n "${CLOUD}" ]]       || error "--cloud is required (aws or azure)"
[[ -n "${ENVIRONMENT}" ]] || error "--environment is required (dev, staging, or prod)"

case "${CLOUD}" in
  aws|azure) ;;
  *) error "--cloud must be 'aws' or 'azure', got: ${CLOUD}" ;;
esac

case "${ENVIRONMENT}" in
  dev|staging|prod) ;;
  *) error "--environment must be 'dev', 'staging', or 'prod', got: ${ENVIRONMENT}" ;;
esac

# ---------------------------------------------------------------------------
# AWS bootstrap
# ---------------------------------------------------------------------------
bootstrap_aws() {
  require_cmd aws

  [[ -n "${AWS_REGION}" ]] || error "--region is required for --cloud aws"

  local bucket_name="${PROJECT_NAME}-tfstate-${ENVIRONMENT}"
  local table_name="${PROJECT_NAME}-tfstate-lock-${ENVIRONMENT}"

  log "Bootstrapping AWS state backend in region ${AWS_REGION}"
  log "  S3 bucket:      ${bucket_name}"
  log "  DynamoDB table: ${table_name}"

  # Create S3 bucket (us-east-1 does not accept CreateBucketConfiguration).
  # Use 's3 ls' rather than 'head-bucket' to distinguish owned buckets from
  # name conflicts with buckets owned by other accounts.
  if aws s3 ls "s3://${bucket_name}" --region "${AWS_REGION}" >/dev/null 2>&1; then
    log "S3 bucket '${bucket_name}' already exists — skipping creation."
  else
    if [[ "${AWS_REGION}" == "us-east-1" ]]; then
      aws s3api create-bucket \
        --bucket "${bucket_name}" \
        --region "${AWS_REGION}" \
        >/dev/null
    else
      aws s3api create-bucket \
        --bucket "${bucket_name}" \
        --region "${AWS_REGION}" \
        --create-bucket-configuration LocationConstraint="${AWS_REGION}" \
        >/dev/null
    fi
    log "Created S3 bucket: ${bucket_name}"
  fi

  # Enable versioning
  aws s3api put-bucket-versioning \
    --bucket "${bucket_name}" \
    --versioning-configuration Status=Enabled \
    >/dev/null
  log "Versioning enabled on ${bucket_name}."

  # Enable server-side encryption (AES-256)
  aws s3api put-bucket-encryption \
    --bucket "${bucket_name}" \
    --server-side-encryption-configuration '{
      "Rules": [{
        "ApplyServerSideEncryptionByDefault": {
          "SSEAlgorithm": "AES256"
        },
        "BucketKeyEnabled": true
      }]
    }' \
    >/dev/null
  log "Server-side encryption (AES-256) enabled on ${bucket_name}."

  # Block all public access
  aws s3api put-public-access-block \
    --bucket "${bucket_name}" \
    --public-access-block-configuration \
      "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true" \
    >/dev/null
  log "Public access blocked on ${bucket_name}."

  # Enforce TLS-only bucket policy
  local bucket_arn="arn:aws:s3:::${bucket_name}"
  aws s3api put-bucket-policy \
    --bucket "${bucket_name}" \
    --policy "{
      \"Version\": \"2012-10-17\",
      \"Statement\": [{
        \"Sid\": \"DenyNonTLS\",
        \"Effect\": \"Deny\",
        \"Principal\": \"*\",
        \"Action\": \"s3:*\",
        \"Resource\": [\"${bucket_arn}\", \"${bucket_arn}/*\"],
        \"Condition\": {\"Bool\": {\"aws:SecureTransport\": \"false\"}}
      }]
    }" \
    >/dev/null
  log "TLS-only bucket policy applied to ${bucket_name}."

  # Create DynamoDB table for locking (idempotent: check for ACTIVE status explicitly).
  local table_status
  table_status="$(aws dynamodb describe-table \
    --table-name "${table_name}" \
    --region "${AWS_REGION}" \
    --query 'Table.TableStatus' \
    --output text 2>/dev/null || echo "MISSING")"

  if [[ "${table_status}" == "ACTIVE" ]]; then
    log "DynamoDB table '${table_name}' already exists and is ACTIVE — skipping creation."
  else
    aws dynamodb create-table \
      --table-name "${table_name}" \
      --attribute-definitions AttributeName=LockID,AttributeType=S \
      --key-schema AttributeName=LockID,KeyType=HASH \
      --billing-mode PAY_PER_REQUEST \
      --sse-specification Enabled=true \
      --region "${AWS_REGION}" \
      >/dev/null
    log "Created DynamoDB table: ${table_name}"

    # Enable PITR
    aws dynamodb update-continuous-backups \
      --table-name "${table_name}" \
      --point-in-time-recovery-specification PointInTimeRecoveryEnabled=true \
      --region "${AWS_REGION}" \
      >/dev/null
    log "Point-in-time recovery enabled on ${table_name}."
  fi

  log ""
  log "=== AWS backend bootstrap complete ==="
  log ""
  log "Add the following to infra/terraform/environments/${ENVIRONMENT}/backend.hcl:"
  log ""
  cat <<EOF

bucket         = "${bucket_name}"
key            = "${ENVIRONMENT}/terraform.tfstate"
region         = "${AWS_REGION}"
encrypt        = true
dynamodb_table = "${table_name}"
EOF
}

# ---------------------------------------------------------------------------
# Azure bootstrap
# ---------------------------------------------------------------------------
bootstrap_azure() {
  require_cmd az

  [[ -n "${AZURE_LOCATION}" ]] || error "--location is required for --cloud azure"

  local resource_group="${PROJECT_NAME}-tfstate-${ENVIRONMENT}-rg"
  # Azure storage account names: lowercase alphanumeric, max 24 chars
  local env_short
  case "${ENVIRONMENT}" in
    dev)     env_short="dev" ;;
    staging) env_short="stg" ;;
    prod)    env_short="prd" ;;
  esac
  local storage_account="${PROJECT_NAME}tfstate${env_short}"
  local container_name="tfstate"

  log "Bootstrapping Azure state backend in ${AZURE_LOCATION}"
  log "  Resource group:  ${resource_group}"
  log "  Storage account: ${storage_account}"
  log "  Container:       ${container_name}"

  if [[ -n "${AZURE_SUBSCRIPTION}" ]]; then
    az account set --subscription "${AZURE_SUBSCRIPTION}" >/dev/null
    log "Using Azure subscription: ${AZURE_SUBSCRIPTION}"
  fi

  # Create resource group (idempotent)
  az group create \
    --name "${resource_group}" \
    --location "${AZURE_LOCATION}" \
    --tags \
      Project="${PROJECT_NAME}" \
      Environment="${ENVIRONMENT}" \
      ManagedBy="terraform" \
      Component="state-backend" \
    --output none
  log "Resource group ready: ${resource_group}"

  # Create storage account (idempotent — az storage account create is idempotent for same params)
  az storage account create \
    --name "${storage_account}" \
    --resource-group "${resource_group}" \
    --location "${AZURE_LOCATION}" \
    --sku "Standard_GRS" \
    --kind "StorageV2" \
    --https-only true \
    --min-tls-version "TLS1_2" \
    --allow-blob-public-access false \
    --tags \
      Project="${PROJECT_NAME}" \
      Environment="${ENVIRONMENT}" \
      ManagedBy="terraform" \
      Component="state-backend" \
    --output none
  log "Storage account ready: ${storage_account}"

  # Enable versioning
  az storage account blob-service-properties update \
    --account-name "${storage_account}" \
    --resource-group "${resource_group}" \
    --enable-versioning true \
    --enable-delete-retention true \
    --delete-retention-days 30 \
    --enable-container-delete-retention true \
    --container-delete-retention-days 30 \
    --output none
  log "Blob versioning and soft-delete enabled."

  # Get storage account key for container creation.
  # SECURITY: This key grants full access to the storage account. It is used only
  # to create the tfstate container and is never logged or written to disk.
  # Unset the variable immediately after use below.
  local storage_key
  storage_key="$(az storage account keys list \
    --account-name "${storage_account}" \
    --resource-group "${resource_group}" \
    --query '[0].value' \
    --output tsv)"

  # Create container (idempotent)
  az storage container create \
    --name "${container_name}" \
    --account-name "${storage_account}" \
    --account-key "${storage_key}" \
    --public-access off \
    --output none
  # Unset the key immediately after use
  storage_key=""
  log "Storage container ready: ${container_name}"

  log ""
  log "=== Azure backend bootstrap complete ==="
  log ""
  log "Add the following to infra/terraform/environments/azure-${ENVIRONMENT}/backend.hcl:"
  log ""
  cat <<EOF

resource_group_name  = "${resource_group}"
storage_account_name = "${storage_account}"
container_name       = "${container_name}"
key                  = "${ENVIRONMENT}/terraform.tfstate"
EOF
}

# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------
case "${CLOUD}" in
  aws)   bootstrap_aws ;;
  azure) bootstrap_azure ;;
esac
