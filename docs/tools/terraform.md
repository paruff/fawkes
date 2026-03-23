# Terraform

[HashiCorp Terraform](https://www.terraform.io/) is an open-source infrastructure-as-code
tool that lets you define cloud and on-premises resources in human-readable configuration
files which can be versioned, reused, and shared.

## How Fawkes Uses Terraform

All cloud infrastructure in Fawkes is provisioned with Terraform. Configuration lives under
`infra/` in the repository:

```
infra/
  aws/          # EKS cluster, VPC, IAM roles
  azure/        # AKS cluster, networking, storage
  terraform/    # Shared modules and configuration
```

Every change to `infra/` triggers a `terraform plan` in CI. No `apply` runs automatically
— a human must review the plan and approve it before infrastructure changes are made.

## Key Concepts

**Providers** declare which cloud APIs Terraform interacts with (`aws`, `azurerm`,
`kubernetes`). Fawkes pins provider versions to ensure reproducible builds.

**Modules** are reusable infrastructure building blocks. Fawkes uses community modules
from the Terraform Registry (e.g., `terraform-aws-modules/eks/aws`) and local modules
for shared networking patterns.

**State** tracks the real-world resources Terraform manages. Fawkes stores state in a
remote backend (S3 or Azure Blob) with state locking to prevent concurrent modifications.

**Workspaces** separate state by environment (`dev`, `staging`, `prod`), allowing the
same configuration to manage multiple environments.

## Typical Workflow

```bash
# 1. Format and validate
terraform fmt -recursive
terraform validate

# 2. Preview changes (required before apply)
terraform plan -out=tfplan

# 3. Apply after human review
terraform apply tfplan
```

## Quality Gates

All Terraform code must pass:

- `terraform fmt -check` — consistent formatting
- `terraform validate` — syntax and provider validation
- `tflint` — style and best-practice rules (config in `.tflint.hcl`)

## See Also

- [Infrastructure as Code Pattern](../patterns/infrastructure-as-code.md)
- [Getting Started](../getting-started.md)
- [Architecture Overview](../architecture.md)
