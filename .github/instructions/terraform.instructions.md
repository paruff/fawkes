---
name: Terraform Infrastructure Instructions
description: Applied automatically when working in infra/
applyTo: "infra/**/*.tf,infra/**/*.tfvars"
---

# Terraform Instructions — Fawkes

## Read First
- `AGENTS.md` → IaC Rules section
- `docs/CHANGE_IMPACT_MAP.md` → infra changes that cascade to platform/

## Fawkes Terraform Standards

### File Organisation (one resource type per file)
```
infra/{module}/
  main.tf        → core resources
  variables.tf   → all input variables with descriptions
  outputs.tf     → all outputs with descriptions
  versions.tf    → required_providers with pinned versions
  README.md      → terraform-docs generated (do not hand-edit)
```

### Variable Rules
```hcl
# ✅ Every variable needs description and type
variable "cluster_name" {
  description = "Name of the EKS cluster. Used as prefix for all related resources."
  type        = string
}

# ❌ Never
variable "cluster_name" {}
```

### No Hardcoded Values
```hcl
# ❌ Never
resource "aws_instance" "web" {
  ami    = "ami-0c55b159cbfafe1f0"   # hardcoded AMI
  region = "us-east-1"               # hardcoded region
}

# ✅ Use variables
resource "aws_instance" "web" {
  ami    = var.ami_id
}
```

### Pinned Module Versions
```hcl
# ✅ Pinned version
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.2"
}

# ❌ Never in production
module "vpc" {
  source = "../local-module"   # local path
}
```

### Required Tags on All Resources
```hcl
tags = {
  Project     = "fawkes"
  Environment = var.environment
  ManagedBy   = "terraform"
  Owner       = var.team
}
```

## Linters That Must Pass
```bash
terraform fmt -check -recursive   # formatting
terraform validate                 # syntax + provider validation
tflint --recursive                 # config in .tflint.hcl
```

## CI Behaviour
- `terraform plan` runs on every PR touching `infra/`
- `terraform apply` requires: plan output in PR + two human approvals
- Never run `terraform apply` in CI automatically — always require manual approval step

## What Requires Human Approval
- New Terraform provider
- New external module dependency
- Changes to state backend configuration
- Any resource destruction (`terraform destroy` or resource removal)
