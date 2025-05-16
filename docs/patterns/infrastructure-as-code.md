---
title: Infrastructure as Code Pattern
description: Implementation patterns for infrastructure as code based on DORA research
---

# Infrastructure as Code Pattern

![IaC Overview](../assets/images/patterns/iac-overview.png){ width="600" }

Infrastructure as Code (IaC) is a key capability identified in DORA research that enables high-performing organizations to manage their infrastructure using version-controlled declarative configurations.

## Core Principles

| Principle | Description | Implementation |
|-----------|-------------|----------------|
| ![](../assets/images/icons/declarative.png){ width="24" } **Declarative** | Define desired state, not steps | Terraform, ARM templates |
| ![](../assets/images/icons/version.png){ width="24" } **Version Control** | Track all infrastructure changes | Git |
| ![](../assets/images/icons/immutable.png){ width="24" } **Immutable** | Replace rather than modify | Containers, VM images |
| ![](../assets/images/icons/idempotent.png){ width="24" } **Idempotent** | Same input yields same result | Terraform state |

## Implementation Guide

### 1. Infrastructure Definition

```hcl
# Example Terraform Configuration
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

resource "azurerm_kubernetes_cluster" "main" {
  name                = "fawkes-aks"
  location            = "eastus"
  resource_group_name = azurerm_resource_group.main.name
  dns_prefix          = "fawkes"

  default_node_pool {
    name       = "default"
    node_count = 3
    vm_size    = "Standard_D2_v2"
  }

  identity {
    type = "SystemAssigned"
  }
}
```

### 2. GitOps Integration

```yaml
# ArgoCD Application for Infrastructure
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: fawkes-infrastructure
spec:
  source:
    repoURL: https://github.com/paruff/fawkes.git
    path: infrastructure/terraform
    targetRevision: HEAD
  destination:
    server: https://kubernetes.default.svc
    namespace: infrastructure
```

## Best Practices

### 1. Code Organization

```bash
infrastructure/
├── environments/
│   ├── production/
│   │   └── main.tf
│   └── staging/
│       └── main.tf
├── modules/
│   ├── kubernetes/
│   │   └── main.tf
│   └── networking/
│       └── main.tf
└── shared/
    └── variables.tf
```

### 2. Security Controls

```hcl
# Example Security Policy
resource "azurerm_key_vault" "main" {
  name                = "fawkes-vault"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tenant_id          = data.azurerm_client_config.current.tenant_id

  sku_name = "standard"

  network_acls {
    default_action = "Deny"
    bypass         = "AzureServices"
  }
}
```

## Key Metrics

Based on DORA research, track these infrastructure metrics:

| Metric | Elite Performance | Implementation |
|--------|------------------|----------------|
| Infrastructure Change Success Rate | > 95% | `success_rate = successful_changes / total_changes` |
| Infrastructure Recovery Time | < 1 hour | `recovery_time = restore_time - failure_time` |
| Infrastructure Deployment Time | < 30 minutes | `deployment_time = end_time - start_time` |

## Testing Strategy

### 1. Unit Testing

```hcl
# Example Terraform Test
provider "test" {}

resource "test_assertions" "network" {
  component = "network"

  equal "cidr_block" {
    description = "CIDR block should match expected value"
    got         = module.network.cidr_block
    want        = "10.0.0.0/16"
  }
}
```

### 2. Integration Testing

```bash
#!/bin/bash
# Infrastructure Integration Test
terraform init
terraform plan -out=tfplan
terraform apply tfplan

# Validate resources
az aks show --name fawkes-aks --resource-group fawkes-rg
```

## Common Anti-Patterns

❌ **Avoid These Practices:**
- Manual infrastructure changes
- Untested infrastructure code
- Sharing state files
- Hard-coded credentials

✅ **Instead Do This:**
- Automate all changes
- Implement comprehensive testing
- Use remote state storage
- Use secrets management

## Tools Integration

| Category | Tools | Purpose |
|----------|-------|---------|
| IaC | Terraform, Pulumi | Infrastructure definition |
| Version Control | Git | Configuration management |
| CI/CD | Azure DevOps, GitHub Actions | Automation |
| Testing | Terratest, Inspec | Validation |
| Security | Checkov, tfsec | Security scanning |

## References

- [2023 State of DevOps Report](https://dora.dev/)
- [Accelerate: Building and Scaling High Performing Technology Organizations](https://itrevolution.com/book/accelerate/)
- [Infrastructure as Code by Kief Morris](https://infrastructure-as-code.com/)

[View Examples :octicons-code-16:](../examples/infrastructure.md){ .md-button .md-button--primary }
[Implementation Guide :octicons-book-16:](../guides/iac-implementation.md){ .md-button }