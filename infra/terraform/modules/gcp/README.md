# GCP Terraform Modules

Production-ready Terraform modules for deploying GCP infrastructure following Fawkes platform standards and best practices.

## Available Modules

### Core Infrastructure

- **[vpc](./vpc/)** - Virtual Private Cloud with custom subnets, Cloud NAT, VPC Flow Logs, and firewall rules
- **[gke](./gke/)** - Google Kubernetes Engine cluster (Standard or Autopilot) with Workload Identity and security features
- **[cloudsql](./cloudsql/)** - Cloud SQL database with automated backups, encryption, and high availability
- **[gcs](./gcs/)** - Cloud Storage buckets with encryption, versioning, and lifecycle policies

## Quick Start

### 1. VPC Setup

```hcl
module "vpc" {
  source = "./modules/gcp/vpc"

  network_name = "fawkes-prod-vpc"
  location     = "us-central1"
  project_id   = "my-project-id"
  routing_mode = "REGIONAL"

  subnets = [
    {
      name                            = "fawkes-subnet-01"
      ip_cidr_range                   = "10.0.0.0/24"
      description                     = "Primary subnet for GKE"
      enable_private_ip_google_access = true
      purpose                         = "PRIVATE"
      secondary_ip_ranges = [
        {
          range_name    = "gke-pods"
          ip_cidr_range = "10.1.0.0/16"
        },
        {
          range_name    = "gke-services"
          ip_cidr_range = "10.2.0.0/20"
        }
      ]
    }
  ]

  enable_nat_gateway = true
  enable_flow_logs   = true

  tags = local.tags
}
```

### 2. GKE Cluster

```hcl
module "gke" {
  source = "./modules/gcp/gke"

  cluster_name        = "fawkes-prod-gke"
  location            = "us-central1"
  project_id          = "my-project-id"
  
  enable_autopilot    = false  # Set to true for Autopilot mode
  kubernetes_version  = "1.28"

  network_id    = module.vpc.network_id
  subnetwork_id = module.vpc.subnet_ids["fawkes-subnet-01"]

  pods_secondary_range_name     = "gke-pods"
  services_secondary_range_name = "gke-services"

  enable_private_cluster  = true
  enable_private_nodes    = true
  master_ipv4_cidr_block  = "172.16.0.0/28"

  enable_network_policy     = true
  binary_authorization_mode = "PROJECT_SINGLETON_POLICY_ENFORCE"
  datapath_provider         = "ADVANCED_DATAPATH"

  node_pools = [
    {
      name               = "default-pool"
      initial_node_count = 3
      enable_autoscaling = true
      min_node_count     = 1
      max_node_count     = 10
      machine_type       = "e2-standard-4"
      enable_secure_boot = true
      enable_integrity_monitoring = true
    }
  ]

  tags = local.tags
}
```

### 3. Cloud SQL Database

```hcl
module "cloudsql" {
  source = "./modules/gcp/cloudsql"

  instance_name    = "fawkes-prod-db"
  location         = "us-central1"
  project_id       = "my-project-id"
  database_version = "POSTGRES_15"

  tier              = "db-custom-2-7680"
  availability_type = "REGIONAL"
  disk_type         = "PD_SSD"
  disk_size         = 100

  ipv4_enabled    = false
  private_network = module.vpc.network_id
  require_ssl     = true

  backup_enabled                 = true
  point_in_time_recovery_enabled = true
  retained_backups               = 7

  databases = ["fawkesdb"]
  users = [
    {
      name = "dbadmin"
    }
  ]

  tags = local.tags
}
```

### 4. Cloud Storage

```hcl
module "gcs" {
  source = "./modules/gcp/gcs"

  bucket_name  = "fawkes-prod-data-${var.project_id}"
  location     = "US"
  project_id   = "my-project-id"
  storage_class = "STANDARD"

  enable_versioning = true
  enable_logging    = true

  lifecycle_rules = [
    {
      action_type                     = "SetStorageClass"
      storage_class                   = "NEARLINE"
      condition_age                   = 30
      condition_matches_storage_class = ["STANDARD"]
    },
    {
      action_type   = "Delete"
      condition_age = 365
    }
  ]

  public_access_prevention = "enforced"

  tags = local.tags
}
```

## Module Design Principles

### 1. Extends Base Modules

All GCP modules extend the base modules from `infra/terraform/modules/base/`, ensuring consistency across cloud providers:

- Variables use the same names and validation rules
- Common patterns are reused (naming conventions, tagging, etc.)
- Provider-specific features are added as extensions

### 2. Security First

- **Least Privilege**: IAM roles and permissions follow least privilege principles
- **Encryption**: Enabled by default for all data at rest and in transit
- **Private by Default**: Resources deployed with private IPs where possible
- **Audit Logging**: VPC Flow Logs and Cloud Audit Logs enabled
- **Workload Identity**: Used instead of service account keys
- **Binary Authorization**: Available for container image verification
- **Shielded Nodes**: Secure Boot and Integrity Monitoring enabled

### 3. Production Ready

- **High Availability**: Regional deployments for critical services
- **Automated Backups**: Configured with point-in-time recovery
- **Monitoring**: Cloud Monitoring and Cloud Logging integrated
- **Auto-scaling**: Node autoscaling and database autoresize
- **Network Policy**: Enforced for GKE clusters

### 4. Cost Optimized

- **Right-sized Defaults**: Conservative defaults suitable for most workloads
- **Cost Labels**: Automatic labeling for cost allocation
- **Optimization Options**: Spot instances, storage classes, regional vs multi-regional
- **Documentation**: Clear cost guidance in each module README

## Common Labels

All modules support a `tags` variable and automatically add cost allocation labels:

```hcl
locals {
  tags = {
    platform    = "fawkes"
    environment = "prod"
    managed_by  = "terraform"
    team        = "platform"
    cost_center = "engineering"
  }
}
```

Each resource also gets a `cost` label for granular cost tracking:
- `gke-control-plane` - GKE control plane costs
- `gke-worker-nodes` - Compute Engine instances for GKE
- `gke-addons` - GKE add-ons and service accounts
- `database` - Cloud SQL instance and related resources
- `storage` - Cloud Storage buckets
- `logging` - Log storage and flow logs
- `shared` - VPC, subnets, firewall rules

## Validation

All modules include comprehensive validation:

- **terraform fmt**: Code formatting
- **terraform validate**: Syntax and configuration validation
- **tflint**: Linting for GCP best practices
- **tfsec**: Security scanning
- **Terratest**: Automated module testing

Run validation locally:

```bash
# Format check
terraform fmt -check -recursive

# Validate all modules
cd infra/terraform/modules/gcp/vpc && terraform init && terraform validate
cd infra/terraform/modules/gcp/gke && terraform init && terraform validate
cd infra/terraform/modules/gcp/cloudsql && terraform init && terraform validate
cd infra/terraform/modules/gcp/gcs && terraform init && terraform validate

# Run Terratest
cd tests/terratest
go test -v -timeout 30m -run "TestGCP.*Validation"
```

## Examples

Complete examples are available in the [examples directory](./examples/):

- **[vpc](./examples/vpc/)** - Standalone VPC configuration
- **[gke](./examples/gke/)** - GKE cluster with VPC
- **[cloudsql](./examples/cloudsql/)** - Cloud SQL instance with VPC
- **[gcs](./examples/gcs/)** - Cloud Storage bucket configurations

## Requirements

- Terraform >= 1.6.0
- Google Provider >= 5.0.0
- Google Beta Provider >= 5.0.0 (for GKE)
- Authenticated gcloud CLI or valid service account credentials
- Required GCP APIs enabled:
  - Compute Engine API
  - Kubernetes Engine API
  - Cloud SQL Admin API
  - Cloud Storage API
  - Service Networking API

## Module Features

### VPC Module

- **Custom VPC Network**: Configurable routing mode (REGIONAL or GLOBAL)
- **Flexible Subnets**: Support for secondary IP ranges (for GKE pods/services)
- **Cloud NAT**: Outbound internet access for private resources
- **VPC Flow Logs**: Network monitoring and troubleshooting
- **Firewall Rules**: Custom and default secure firewall rules
- **Private Google Access**: Access Google APIs from private instances
- **Identity-Aware Proxy**: SSH access without public IPs

### GKE Module

- **Cluster Modes**: Standard (self-managed nodes) or Autopilot (fully managed)
- **Workload Identity**: Secure pod-to-GCP service authentication
- **Private Clusters**: Private nodes and optional private endpoint
- **Node Pools**: Multiple node pools with different configurations
- **Autoscaling**: Cluster autoscaler and horizontal pod autoscaling
- **Security Features**:
  - Shielded GKE nodes with Secure Boot
  - Binary Authorization for image verification
  - Network Policy enforcement
  - Security Posture Management
- **Observability**: Cloud Logging, Cloud Monitoring, Managed Prometheus
- **Addons**: HTTP Load Balancing, Filestore CSI, GCE Persistent Disk CSI

### Cloud SQL Module

- **Database Engines**: PostgreSQL and MySQL
- **High Availability**: Regional (multi-zone) deployment
- **Backups**: Automated backups with point-in-time recovery
- **Encryption**: At rest with Google-managed or customer-managed keys
- **Private Connectivity**: Private IP with VPC peering
- **Performance**: Query Insights for performance monitoring
- **Scaling**: Automatic storage increase
- **Read Replicas**: Support for read replicas in different regions

### GCS Module

- **Encryption**: Google-managed or customer-managed KMS keys
- **Versioning**: Object versioning for data protection
- **Lifecycle Policies**: Automatic data management and cost optimization
- **IAM**: Fine-grained access control with least privilege
- **Logging**: Access logs to separate bucket
- **Security**: Public access prevention enforced by default
- **CORS**: Cross-origin resource sharing configuration
- **Retention Policies**: Compliance and data retention

## Security Best Practices

### Network Security

- Use private IP addresses for all compute resources
- Enable VPC Flow Logs for network monitoring
- Configure firewall rules with least privilege
- Use Cloud NAT instead of public IPs for outbound traffic
- Enable Private Google Access for accessing Google APIs

### Compute Security

- Enable Shielded Nodes for GKE
- Use Workload Identity instead of service account keys
- Enable Binary Authorization for container images
- Configure Network Policies for pod-to-pod communication
- Use least-privilege IAM roles for service accounts

### Data Security

- Enable encryption at rest for all data
- Use private IP for database connectivity
- Require SSL/TLS for all connections
- Enable automated backups with retention policies
- Use Cloud KMS for customer-managed encryption keys

### Access Control

- Use IAM conditions for time-based or attribute-based access
- Enable audit logging for all resources
- Use Identity-Aware Proxy for SSH access
- Configure authorized networks for master access
- Regular review and rotate credentials

## Troubleshooting

### Common Issues

#### Module validation fails

```bash
# Ensure you have the correct Terraform version
terraform version

# Ensure you have authenticated to GCP
gcloud auth application-default login

# Check if required APIs are enabled
gcloud services list --enabled
```

#### VPC peering for Cloud SQL fails

```bash
# Ensure Service Networking API is enabled
gcloud services enable servicenetworking.googleapis.com

# Check if the VPC exists
gcloud compute networks list
```

#### GKE cluster creation fails

```bash
# Ensure Kubernetes Engine API is enabled
gcloud services enable container.googleapis.com

# Check if you have sufficient quota
gcloud compute project-info describe --project=PROJECT_ID
```

## Cost Optimization Tips

1. **Right-size resources**: Start with smaller machine types and scale up as needed
2. **Use Autopilot for GKE**: Let Google manage node provisioning and scaling
3. **Configure lifecycle policies**: Automatically transition or delete old data
4. **Use regional resources**: More cost-effective than multi-regional
5. **Enable autoscaling**: Scale down during off-hours
6. **Use committed use discounts**: For predictable workloads
7. **Monitor costs**: Use labels to track spending by team or project

## Support

For questions or issues:
- Review individual module READMEs for detailed documentation
- Check examples for reference implementations
- Consult [ADR-005: Terraform Decision](../../docs/adr/ADR-005%20terraform.md)
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
