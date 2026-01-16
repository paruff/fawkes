# Azure Terraform Modules

This directory contains production-ready Terraform modules for Azure infrastructure, following best practices and extending base modules defined in `../base/`.

## Modules

### 1. AKS (Azure Kubernetes Service)
**Path:** `./aks/`

Comprehensive AKS cluster module with:
- Managed node pools with autoscaling
- Azure CNI network plugin support
- Azure Monitor Container Insights integration
- Managed identities and RBAC
- Azure AD integration
- Multiple node pools support
- Private endpoint support
- Security best practices

**Usage:**
```hcl
module "aks" {
  source = "./modules/azure/aks"

  cluster_name        = "my-aks-cluster"
  location            = "East US"
  resource_group_name = "my-rg"
  subnet_id           = azurerm_subnet.aks.id

  enable_auto_scaling = true
  node_min_count      = 2
  node_max_count      = 10

  enable_azure_monitor       = true
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  tags = {
    Environment = "production"
  }
}
```

### 2. Database (Azure Database for PostgreSQL/MySQL)
**Path:** `./database/`

Flexible server module supporting:
- PostgreSQL (versions 11-16)
- MySQL (versions 5.7, 8.0.21)
- High availability (Zone Redundant or Same Zone)
- Automated backups with geo-redundancy
- Encryption at rest
- Private endpoint support
- Parameter configuration
- Azure Monitor integration with alerts

**Usage:**
```hcl
module "database" {
  source = "./modules/azure/database"

  server_name         = "my-db-server"
  location            = "East US"
  resource_group_name = "my-rg"

  engine         = "postgresql"
  engine_version = "15"
  sku_name       = "GP_Standard_D2s_v3"

  high_availability_mode = "ZoneRedundant"
  backup_retention_days  = 14

  enable_diagnostic_settings = true
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  tags = {
    Environment = "production"
  }
}
```

### 3. Storage (Azure Storage Account)
**Path:** `./storage/`

Storage account module with:
- Blob container management
- Versioning and soft delete
- Lifecycle management policies
- Network rules and private endpoints
- CORS configuration
- Customer-managed encryption keys support
- Azure Monitor integration
- Capacity and availability alerts

**Usage:**
```hcl
module "storage" {
  source = "./modules/azure/storage"

  storage_account_name = "mystorageaccount"
  location             = "East US"
  resource_group_name  = "my-rg"

  replication_type = "GRS"
  
  enable_versioning           = true
  blob_soft_delete_retention_days = 7

  containers = {
    documents = {
      access_type = "private"
    }
  }

  lifecycle_rules = [
    {
      name    = "move-to-cool"
      enabled = true
      base_blob = {
        tier_to_cool_after_days = 30
      }
    }
  ]

  tags = {
    Environment = "production"
  }
}
```

### 4. VNet (Virtual Network)
**Path:** `./vnet/`

Enhanced virtual network module with:
- Public and private subnets
- Network Security Groups with custom rules
- NAT Gateway for outbound connectivity
- Service endpoints for Azure services
- NSG Flow Logs to Azure Monitor
- Traffic Analytics integration
- Subnet delegation support

**Usage:**
```hcl
module "vnet" {
  source = "./modules/azure/vnet"

  vnet_name           = "my-vnet"
  location            = "East US"
  resource_group_name = "my-rg"
  address_space       = ["10.0.0.0/16"]

  public_subnets = [
    {
      name             = "public-subnet"
      address_prefixes = ["10.0.1.0/24"]
      service_endpoints = ["Microsoft.Storage"]
    }
  ]

  private_subnets = [
    {
      name             = "app-subnet"
      address_prefixes = ["10.0.10.0/24"]
      service_endpoints = ["Microsoft.Sql", "Microsoft.Storage"]
    }
  ]

  enable_nat_gateway = true
  enable_flow_logs   = true

  tags = {
    Environment = "production"
  }
}
```

## Design Principles

### 1. Extending Base Modules
All cloud-specific modules extend the base module definitions from `../base/`:
- `base/kubernetes-cluster` → `azure/aks`
- `base/network` → `azure/vnet`

This ensures:
- Consistent variable naming
- Reusable validation patterns
- Cross-cloud compatibility

### 2. Security Best Practices
- Encryption at rest by default
- HTTPS-only traffic
- Minimum TLS 1.2
- Private endpoints support
- Network isolation with NSGs
- Managed identities over access keys
- Least privilege access

### 3. Cost Optimization
- Auto-tagging with "Cost" tags
- Auto-scaling capabilities
- Lifecycle policies for storage
- Resource right-sizing options
- Zone-redundant vs. single-zone options

### 4. Observability
- Azure Monitor integration
- Diagnostic settings
- Flow logs for networks
- Traffic Analytics
- Metric alerts
- Log Analytics workspace integration

## Examples

Each module includes comprehensive examples in `./examples/<module-name>/`:
- **aks**: Complete AKS cluster with monitoring
- **database**: PostgreSQL and MySQL configurations
- **storage**: Blob containers with lifecycle policies
- **vnet**: Multi-tier network with NSGs

To use an example:
```bash
cd examples/aks
terraform init
terraform plan
terraform apply
```

## Testing

### Terratest Validation
All modules are validated using Terratest:

```bash
cd tests/terratest
go test -v -run TestAzure
```

Individual module tests:
```bash
go test -v -run TestAzureAKSModuleValidation
go test -v -run TestAzureDatabaseModuleValidation
go test -v -run TestAzureStorageModuleValidation
go test -v -run TestAzureVNetModuleValidation
```

### Static Analysis

#### tflint
```bash
cd infra/terraform/modules/azure/aks
tflint --init
tflint
```

#### tfsec
```bash
cd infra/terraform/modules/azure
tfsec .
```

## Variable Validation

All modules include comprehensive input validation:

- **String lengths**: Min/max character limits
- **Naming patterns**: Regex validation for Azure naming rules
- **CIDR blocks**: Valid IP range validation
- **Enums**: Allowed values for configuration options
- **Dependencies**: Cross-variable validation

Example validation error:
```
Error: Invalid value for variable

  on variables.tf line 23:
  23: variable "cluster_name" {

Cluster name must be between 1 and 63 characters.
```

## Integration

### AKS + VNet + Database
```hcl
# Network
module "vnet" {
  source = "./modules/azure/vnet"
  # ... configuration
}

# Database
module "database" {
  source = "./modules/azure/database"
  
  private_endpoint_subnet_id = module.vnet.private_subnet_ids["data-subnet"]
  # ... configuration
}

# AKS
module "aks" {
  source = "./modules/azure/aks"
  
  subnet_id = module.vnet.private_subnet_ids["aks-subnet"]
  # ... configuration
}
```

### Using Outputs
All modules provide comprehensive outputs for integration:

```hcl
# Use AKS cluster for kubectl
output "kube_config" {
  value     = module.aks.kube_config
  sensitive = true
}

# Use database connection
output "db_connection_string" {
  value     = module.database.connection_string
  sensitive = true
}

# Use storage endpoints
output "storage_endpoint" {
  value = module.storage.primary_blob_endpoint
}
```

## Common Patterns

### Shared Log Analytics Workspace
```hcl
resource "azurerm_log_analytics_workspace" "shared" {
  name                = "shared-logs"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

module "aks" {
  source                     = "./modules/azure/aks"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.shared.id
  # ...
}

module "database" {
  source                     = "./modules/azure/database"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.shared.id
  # ...
}
```

### Tagging Strategy
```hcl
locals {
  common_tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
    Owner       = var.owner_email
    CostCenter  = var.cost_center
  }
}

module "aks" {
  source = "./modules/azure/aks"
  tags   = local.common_tags
  # ...
}
```

## Troubleshooting

### Common Issues

#### 1. Terraform Init Fails
```bash
# Clear cache and reinitialize
rm -rf .terraform
terraform init -upgrade
```

#### 2. Resource Name Conflicts
Ensure globally unique names for:
- Storage accounts (3-24 lowercase alphanumeric)
- Database servers (3-63 lowercase alphanumeric with hyphens)

#### 3. Subnet Size
Ensure subnets are large enough:
- AKS: Minimum /24 for small clusters
- Database: Minimum /28
- NAT Gateway: Minimum /29

#### 4. Service Endpoint Conflicts
Cannot use private endpoints and firewall rules simultaneously on databases

## Migration from Old Modules

If migrating from `azure-aks-cluster`, `azure-network`, etc.:

1. **Import existing resources**:
```bash
terraform import module.aks.azurerm_kubernetes_cluster.main /subscriptions/.../resourceGroups/.../providers/Microsoft.ContainerService/managedClusters/...
```

2. **Update references**:
```hcl
# Old
module "aks" {
  source = "./modules/azure-aks-cluster"
}

# New
module "aks" {
  source = "./modules/azure/aks"
}
```

3. **Variable mapping** (most are compatible, but check new validations)

## Contributing

When adding new features:
1. Update variables with validation
2. Add outputs for new resources
3. Update examples
4. Add Terratest validation
5. Update this README
6. Run `tflint` and `tfsec`

## License

Copyright (c) 2025 Philip Ruff - See LICENSE file
