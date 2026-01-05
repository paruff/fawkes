# Terraform Modules Refactoring Guide

This document provides a migration guide for the Terraform module refactoring completed as part of Task 4.1.1.

## Overview

The Terraform modules have been reorganized to:
1. Create base modules with common patterns
2. Implement provider-specific modules that extend the base
3. Remove duplicate code between provider implementations
4. Standardize variable naming (snake_case)
5. Add validation rules to all variables

## New Module Structure

```
infra/terraform/modules/
├── base/
│   ├── kubernetes-cluster/    # Common K8s cluster patterns
│   ├── network/                # Common networking patterns
│   └── resource-group/         # Common resource grouping patterns
├── azure/
│   ├── kubernetes-cluster/     # Azure AKS implementation
│   ├── network/                # Azure VNet implementation
│   └── resource-group/         # Azure Resource Group implementation
├── aws/                        # Reserved for AWS implementations
├── gcp/                        # Reserved for GCP implementations
├── civo/                       # Reserved for Civo implementations
├── argocd-helm/               # ArgoCD Helm module (unchanged)
├── azure-aks-cluster/         # DEPRECATED - use azure/kubernetes-cluster
├── azure-network/             # DEPRECATED - use azure/network
└── azure-resource-group/      # DEPRECATED - use azure/resource-group
```

## Migration Steps

### Step 1: Update Module Source Paths

Update your Terraform configurations to use the new module paths.

#### Resource Group Module

```hcl
# Before
module "rg" {
  source   = "./modules/azure-resource-group"
  name     = "fawkes-rg"
  location = "eastus2"
  tags     = { environment = "dev" }
}

# After
module "rg" {
  source   = "./modules/azure/resource-group"
  name     = "fawkes-rg"
  location = "eastus2"
  tags     = { environment = "dev" }
}
```

#### Network Module

```hcl
# Before
module "network" {
  source              = "./modules/azure-network"
  vnet_name           = "fawkes-vnet"
  location            = "eastus2"
  resource_group_name = module.rg.name
  address_space       = ["10.0.0.0/16"]
  subnet_name         = "aks-subnet"
  subnet_address_prefixes = ["10.0.1.0/24"]
}

# After
module "network" {
  source              = "./modules/azure/network"
  vnet_name           = "fawkes-vnet"
  location            = "eastus2"
  resource_group_name = module.rg.name
  address_space       = ["10.0.0.0/16"]
  subnet_name         = "aks-subnet"
  subnet_address_prefixes = ["10.0.1.0/24"]
}
```

#### Kubernetes Cluster Module

```hcl
# Before
module "aks" {
  source              = "./modules/azure-aks-cluster"
  cluster_name        = "fawkes-aks"
  location            = "eastus2"
  resource_group_name = module.rg.name
  subnet_id           = module.network.subnet_id
  node_vm_size        = "Standard_B2ms"
  node_count          = 3
}

# After
module "aks" {
  source              = "./modules/azure/kubernetes-cluster"
  cluster_name        = "fawkes-aks"
  location            = "eastus2"
  resource_group_name = module.rg.name
  subnet_id           = module.network.subnet_id
  node_vm_size        = "Standard_B2ms"
  node_count          = 3
}
```

### Step 2: Verify Variable Names

All variables now use snake_case consistently. Most variable names remain the same, but verify your configuration:

- ✅ `cluster_name` (unchanged)
- ✅ `resource_group_name` (unchanged)
- ✅ `node_vm_size` (unchanged)
- ✅ `node_count` (unchanged)
- ✅ `vnet_name` (unchanged)
- ✅ `subnet_name` (unchanged)

### Step 3: Run Terraform Plan

Before applying changes, run `terraform plan` to verify no resources will be recreated:

```bash
cd infra/terraform
terraform init -upgrade
terraform plan
```

**Expected output:** No resource changes should be detected if you've only updated the module source paths.

### Step 4: Update and Apply

If the plan looks good:

```bash
terraform apply
```

### Step 5: Validate

After applying, validate the changes:

```bash
# Format check
terraform fmt -check -recursive

# Validation
terraform validate

# Verify resources
terraform state list
```

## Breaking Changes

**None.** The refactoring is backward compatible with existing deployments. Only the module source paths change.

## New Features

### 1. Base Modules

Base modules now provide:
- Common variable definitions with validation
- Standardized naming conventions
- Reusable patterns across providers

### 2. Enhanced Validation

All modules now include comprehensive validation rules:
- Name length and format validation
- CIDR block validation
- Enum value validation
- Range validation for numeric values

### 3. Provider-Specific Extensions

Provider modules extend base modules with:
- Provider-specific variables
- Provider-specific validation (e.g., Azure region validation)
- Provider-specific outputs

## Testing

All modules have been tested with:
- `terraform fmt -check`
- `terraform validate`
- Terratest validation tests

To run tests:

```bash
# Format check
cd infra/terraform
terraform fmt -check -recursive

# Validation
cd modules/azure/resource-group
terraform init
terraform validate

# Terratest
cd tests/terratest
go test -v -timeout 30m -run "Validation"
```

## Future Provider Support

The new structure makes it easy to add new providers:

### AWS Example

```
infra/terraform/modules/aws/
├── kubernetes-cluster/    # EKS implementation
├── network/               # VPC implementation
└── resource-group/        # Tags/Organization implementation
```

### GCP Example

```
infra/terraform/modules/gcp/
├── kubernetes-cluster/    # GKE implementation
├── network/               # VPC implementation
└── resource-group/        # Project implementation
```

### Civo Example

```
infra/terraform/modules/civo/
├── kubernetes-cluster/    # Civo K3s implementation
├── network/               # Civo Network implementation
└── resource-group/        # Civo Organization implementation
```

## Rollback Plan

If you encounter issues, you can rollback by:

1. Reverting module source paths to the old locations
2. Running `terraform init -upgrade`
3. Running `terraform plan` to verify no changes
4. The old modules remain in place for backward compatibility

## Support

For questions or issues:
- Review module READMEs in each module directory
- Check examples in `infra/terraform/examples/`
- Consult [ADR-005: Terraform Decision](../../../docs/adr/ADR-005%20terraform.md)
- Open an issue in the repository

## Timeline

- Old modules (`azure-resource-group`, `azure-network`, `azure-aks-cluster`) are **deprecated** but functional
- Deprecation warnings will be added in the next release
- Old modules will be removed in 6 months (July 2025)

## Checklist

Use this checklist when migrating:

- [ ] Update module source paths in all Terraform files
- [ ] Run `terraform init -upgrade`
- [ ] Run `terraform plan` and verify no resource changes
- [ ] Run `terraform apply`
- [ ] Run `terraform fmt -check` to verify formatting
- [ ] Run `terraform validate` to verify configuration
- [ ] Update any documentation referencing old module paths
- [ ] Update any CI/CD pipelines using old module paths
- [ ] Test deployments in dev/staging environment
- [ ] Deploy to production

## Additional Resources

- Base module documentation: `modules/base/*/README.md`
- Azure module documentation: `modules/azure/*/README.md`
- Module development guidelines: `modules/README.md`
- Terraform best practices: [Terraform Best Practices](https://www.terraform-best-practices.com/)
