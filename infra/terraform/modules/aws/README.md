# AWS Terraform Modules

Production-ready Terraform modules for deploying AWS infrastructure following Fawkes platform standards and best practices.

## Available Modules

### Core Infrastructure

- **[vpc](./vpc/)** - Virtual Private Cloud with public/private subnets, NAT gateways, VPC endpoints, and flow logs
- **[eks](./eks/)** - Elastic Kubernetes Service cluster with managed node groups and essential add-ons
- **[rds](./rds/)** - Relational Database Service with automated backups, encryption, and monitoring
- **[s3](./s3/)** - Simple Storage Service buckets with encryption, versioning, and lifecycle policies

## Quick Start

### 1. VPC Setup

```hcl
module "vpc" {
  source = "./modules/aws/vpc"

  network_name         = "fawkes-prod-vpc"
  location             = "us-east-1"
  vpc_cidr             = "10.0.0.0/16"
  availability_zones   = ["us-east-1a", "us-east-1b", "us-east-1c"]
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]

  enable_nat_gateway   = true
  single_nat_gateway   = false
  enable_s3_endpoint   = true
  enable_flow_logs     = true

  tags = local.tags
}
```

### 2. EKS Cluster

```hcl
module "eks" {
  source = "./modules/aws/eks"

  cluster_name       = "fawkes-prod-eks"
  kubernetes_version = "1.28"
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  public_subnet_ids  = module.vpc.public_subnet_ids

  node_instance_types = ["t3.medium"]
  node_desired_size   = 3
  node_min_size       = 1
  node_max_size       = 10

  enable_ebs_csi_driver              = true
  enable_cluster_autoscaler          = true
  enable_aws_load_balancer_controller = true

  tags = local.tags
}
```

### 3. RDS Database

```hcl
module "rds" {
  source = "./modules/aws/rds"

  identifier                 = "fawkes-prod-db"
  vpc_id                     = module.vpc.vpc_id
  subnet_ids                 = module.vpc.private_subnet_ids
  allowed_security_group_ids = [module.eks.cluster_security_group_id]

  engine                 = "postgres"
  engine_version         = "15.4"
  instance_class         = "db.t3.small"
  parameter_group_family = "postgres15"

  allocated_storage = 100
  storage_encrypted = true
  multi_az          = true

  database_name   = "fawkesdb"
  master_username = "dbadmin"

  backup_retention_period      = 7
  performance_insights_enabled = true
  monitoring_interval          = 60

  tags = local.tags
}
```

### 4. S3 Storage

```hcl
module "s3" {
  source = "./modules/aws/s3"

  bucket_name       = "fawkes-prod-data"
  enable_versioning = true
  sse_algorithm     = "AES256"
  enable_logging    = true

  lifecycle_rules = [
    {
      id      = "archive-policy"
      enabled = true
      prefix  = "logs/"
      
      transitions = [
        {
          days          = 30
          storage_class = "STANDARD_IA"
        },
        {
          days          = 90
          storage_class = "GLACIER"
        }
      ]
      
      expiration_days                    = 365
      noncurrent_version_expiration_days = 90
      noncurrent_version_transitions     = []
    }
  ]

  tags = local.tags
}
```

## Module Design Principles

### 1. Extends Base Modules

All AWS modules extend the base modules from `infra/terraform/modules/base/`, ensuring consistency across cloud providers:

- Variables use the same names and validation rules
- Common patterns are reused (naming conventions, tagging, etc.)
- Provider-specific features are added as extensions

### 2. Security First

- **Least Privilege**: Security groups and IAM roles follow least privilege principles
- **Encryption**: Enabled by default for all data at rest and in transit
- **Private by Default**: Resources deployed in private subnets where possible
- **Audit Logging**: CloudWatch logs and VPC flow logs enabled

### 3. Production Ready

- **High Availability**: Multi-AZ deployments for critical services
- **Automated Backups**: Configured with sensible retention periods
- **Monitoring**: CloudWatch metrics and alarms
- **Auto-scaling**: Cluster autoscaler and RDS storage autoscaling

### 4. Cost Optimized

- **Right-sized Defaults**: Conservative defaults suitable for most workloads
- **Cost Tags**: Automatic tagging for cost allocation
- **Optimization Options**: Single NAT gateway, spot instances, storage classes
- **Documentation**: Clear cost guidance in each module README

## Common Tags

All modules support a `tags` variable and automatically add cost allocation tags:

```hcl
locals {
  tags = {
    Platform    = "fawkes"
    Environment = "prod"
    ManagedBy   = "terraform"
    Team        = "platform"
    CostCenter  = "engineering"
  }
}
```

Each resource also gets a `Cost` tag for granular cost tracking:
- `eks-control-plane` - EKS control plane costs
- `eks-worker-nodes` - EC2 instances for EKS
- `eks-addons` - EKS add-ons and IRSA roles
- `database` - RDS instance and related resources
- `storage` - S3 buckets and EBS volumes
- `nat-gateway` - NAT Gateway resources
- `logging` - CloudWatch logs and flow logs
- `shared` - VPC, subnets, security groups

## Validation

All modules include comprehensive validation:

- **terraform fmt**: Code formatting
- **terraform validate**: Syntax and configuration validation
- **tflint**: Linting for AWS best practices
- **tfsec**: Security scanning
- **Terratest**: Automated module testing

Run validation locally:

```bash
# Format check
terraform fmt -check -recursive

# Validate all modules
cd infra/terraform/modules/aws/vpc && terraform init && terraform validate
cd infra/terraform/modules/aws/eks && terraform init && terraform validate
cd infra/terraform/modules/aws/rds && terraform init && terraform validate
cd infra/terraform/modules/aws/s3 && terraform init && terraform validate

# Run Terratest
cd tests/terratest
go test -v -timeout 30m -run "TestAWS.*Validation"
```

## Examples

Complete examples are available in the [examples directory](./examples/):

- **[vpc](./examples/vpc/)** - Standalone VPC configuration
- **[eks](./examples/eks/)** - EKS cluster with VPC
- **[rds](./examples/rds/)** - RDS instance with VPC
- **[s3](./examples/s3/)** - S3 bucket configurations
- **[complete](./examples/complete/)** - Full stack with all modules

## Requirements

- Terraform >= 1.6.0
- AWS Provider >= 5.0.0
- Authenticated AWS CLI or valid credentials

## Support

For questions or issues:
- Review individual module READMEs for detailed documentation
- Check examples for reference implementations
- Consult [ADR-005: Terraform Decision](../../../../docs/adr/ADR-005%20terraform.md)
- Open an issue in the repository

## Contributing

When adding new modules or features:

1. Follow existing module structure
2. Extend base modules where applicable
3. Add comprehensive validation rules
4. Include examples and tests
5. Document security and cost implications
6. Update this README

## License

Copyright (c) 2025 Philip Ruff. Licensed under the MIT License.
