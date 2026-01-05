# Fawkes Terraform Modules

This directory contains reusable Terraform modules following HashiCorp best practices for infrastructure provisioning.

## 📋 Module Structure

The modules are organized in a hierarchical structure:

```
modules/
├── base/              # Base modules with common patterns
│   ├── kubernetes-cluster/
│   ├── network/
│   └── resource-group/
├── azure/             # Azure-specific implementations
│   ├── kubernetes-cluster/
│   ├── network/
│   └── resource-group/
├── aws/               # AWS implementations (future)
├── gcp/               # GCP implementations (future)
├── civo/              # Civo implementations (future)
└── argocd-helm/       # Kubernetes add-ons
```

## 🚀 Quick Start

### Azure Infrastructure

#### 1. Resource Group

```hcl
module "rg" {
  source   = "./modules/azure/resource-group"
  name     = "fawkes-rg"
  location = "eastus2"
  tags     = { environment = "dev", platform = "fawkes" }
}
```

#### 2. Network

```hcl
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

#### 3. Kubernetes Cluster (AKS)

```hcl
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

## 📚 Module Catalog

### Base Modules

Base modules define common patterns and variables across all cloud providers.

- **[base/kubernetes-cluster](./base/kubernetes-cluster)** - Common K8s cluster patterns
- **[base/network](./base/network)** - Common networking patterns
- **[base/resource-group](./base/resource-group)** - Common resource grouping patterns

### Azure Modules

Azure-specific implementations extending base modules.

- **[azure/kubernetes-cluster](./azure/kubernetes-cluster)** - Azure AKS cluster
- **[azure/network](./azure/network)** - Azure Virtual Network
- **[azure/resource-group](./azure/resource-group)** - Azure Resource Group

### Deprecated Modules

⚠️ **The following modules are deprecated. Please use the new structure above.**

- ~~[azure-resource-group](./azure-resource-group)~~ → Use `azure/resource-group`
- ~~[azure-network](./azure-network)~~ → Use `azure/network`
- ~~[azure-aks-cluster](./azure-aks-cluster)~~ → Use `azure/kubernetes-cluster`

See [REFACTORING.md](./REFACTORING.md) for migration guide.

### Kubernetes Modules

- **[argocd-helm](./argocd-helm)** - Deploy ArgoCD via Helm

## ✨ Key Features

### 1. Base Module Pattern

Base modules define common variables and validation rules:

- Shared variable definitions across providers
- Consistent validation rules
- Standardized naming conventions (snake_case)
- Reusable patterns

Example:

```hcl
variable "node_count" {
  type = number
  validation {
    condition     = var.node_count >= 1 && var.node_count <= 1000
    error_message = "Node count must be between 1 and 1000."
  }
}
```

### 2. Provider-Specific Extensions

Provider modules extend base modules with cloud-specific implementations while maintaining consistent interfaces.

### 3. Comprehensive Outputs

Modules expose all useful information as outputs:

```hcl
output "cluster_id" {
  description = "The ID of the AKS cluster"
  value       = azurerm_kubernetes_cluster.main.id
}
```

### 4. No Hardcoded Values
All configuration is passed via variables with sensible defaults:

```hcl
variable "network_plugin" {
  description = "Network plugin (azure or kubenet)"
  type        = string
  default     = "azure"
}
```

### 5. Complete Documentation
Each module includes:
- README.md with usage examples
- Variable descriptions
- Output descriptions
- terraform.tfvars.example

### 6. Version Constraints
Modules specify minimum provider versions:

```hcl
terraform {
  required_version = ">= 1.6.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.110.0"
    }
  }
}
```

## Usage Patterns

### Pattern 1: Standalone Module

Use a single module independently:

```hcl
module "resource_group" {
  source   = "./modules/azure-resource-group"
  name     = "my-rg"
  location = "eastus2"
}
```

### Pattern 2: Composed Infrastructure

Chain multiple modules together:

```hcl
module "rg" {
  source = "./modules/azure-resource-group"
  # ...
}

module "network" {
  source              = "./modules/azure-network"
  resource_group_name = module.rg.name  # Output from previous module
  # ...
}

module "aks" {
  source    = "./modules/azure-aks-cluster"
  subnet_id = module.network.subnet_id  # Output from network module
  # ...
}
```

### Pattern 3: Environment-Specific Configuration

Use workspaces or separate directories for different environments:

```
environments/
├── dev/
│   ├── main.tf
│   └── terraform.tfvars
├── staging/
│   ├── main.tf
│   └── terraform.tfvars
└── prod/
    ├── main.tf
    └── terraform.tfvars
```

## Best Practices

### 1. Always Use Remote State

```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "tfstate-rg"
    storage_account_name = "tfstate"
    container_name       = "tfstate"
    key                  = "dev.terraform.tfstate"
  }
}
```

### 2. Pin Provider Versions

```hcl
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.110.0"  # Pin to minor version
    }
  }
}
```

### 3. Use Variables Files

Create `terraform.tfvars` for environment-specific values:

```hcl
location    = "eastus2"
environment = "dev"
node_count  = 3
```

### 4. Tag Everything

```hcl
locals {
  tags = {
    platform    = "fawkes"
    managed_by  = "terraform"
    environment = var.environment
    cost_center = "engineering"
  }
}
```

### 5. Plan Before Apply

Always review changes before applying:

```bash
terraform plan -out=tfplan
# Review the plan
terraform apply tfplan
```

## Module Development Guidelines

When creating new modules:

1. **Follow the structure**:
   ```
   module-name/
   ├── README.md
   ├── main.tf
   ├── variables.tf
   ├── outputs.tf
   └── terraform.tfvars.example
   ```

2. **Add validation** to all variables that have constraints

3. **Document everything**:
   - Add descriptions to all variables
   - Add descriptions to all outputs
   - Include usage examples in README

4. **Test thoroughly**:
   - Run `terraform fmt`
   - Run `terraform validate`
   - Test with actual resources

5. **Version semantically**:
   - Use git tags: v1.0.0, v1.1.0, etc.
   - Follow semantic versioning

## Examples

Complete usage examples are available in the [examples](./examples/) directory:

- **[azure-complete](./examples/azure-complete)**: Full Azure infrastructure with AKS and ArgoCD

## Testing Modules

### Format Check
```bash
terraform fmt -check -recursive
```

### Validation
```bash
cd modules/<module-name>
terraform init
terraform validate
```

### Plan (Dry Run)
```bash
terraform plan
```

## Troubleshooting

### Common Issues

1. **Module not found**: Ensure paths are correct relative to where you run terraform
2. **Provider version conflicts**: Check all modules use compatible provider versions
3. **State locked**: Another process is using the state, wait or force-unlock if needed

## Contributing

When contributing new modules:

1. Follow the module structure and conventions
2. Add comprehensive documentation
3. Include validation rules
4. Provide usage examples
5. Test thoroughly before submitting PR

## References

- [Terraform Best Practices](https://www.terraform-best-practices.com/)
- [HashiCorp Module Standards](https://www.terraform.io/docs/modules/index.html)
- [Azure Provider Documentation](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Fawkes ADR-005: Terraform Decision](../../../docs/adr/ADR-005%20terraform.md)

## Support

For questions or issues with modules:
- Check module README.md
- Review examples/
- Open an issue in the repository
- Consult the Fawkes documentation in docs/
