---
name: terraform-modules
description: Terraform patterns for Fawkes — variables, backend, tags. Load when editing infra/.
license: MIT
compatibility: opencode
---

# Terraform — Fawkes

Every variable needs `description`. Sensitive vars get `sensitive = true`.

Backend (KL-01):
```hcl
# AWS
terraform { backend "s3" {
  bucket = var.tf_state_bucket
  key    = "fawkes/aws/terraform.tfstate"
  region = var.region
  dynamodb_table = var.tf_lock_table
  encrypt = true
}}

# Azure
terraform { backend "azurerm" {
  resource_group_name  = var.tf_state_resource_group
  storage_account_name = var.tf_state_storage_account
  container_name       = "tfstate"
  key                  = "fawkes/azure/terraform.tfstate"
}}
```

Tags on everything:
```hcl
tags = { Project = "fawkes", Environment = var.environment, ManagedBy = "terraform" }
```

Validate:
```bash
cd infra/MODULE && terraform fmt -check . && terraform init -backend=false && terraform validate
```
