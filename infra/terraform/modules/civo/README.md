# Civo Terraform Modules

Production-ready Terraform modules for deploying Civo infrastructure following Fawkes platform standards and best practices.

## Overview

Civo is a cloud-native service provider focused on Kubernetes and developer experience with:
- **Fast K3s Kubernetes clusters** (2-3 minute deployment)
- **Simple pricing** and transparent costs
- **Developer-friendly** tools and APIs
- **4 regions**: NYC1, LON1, FRA1, PHX1
- **S3-compatible object storage**
- **Managed databases**: PostgreSQL, MySQL, Redis

## Available Modules

### Core Infrastructure

- **[kubernetes](./kubernetes/)** - Kubernetes cluster (K3s-based) with node pools, CNI selection, and marketplace apps
- **[database](./database/)** - Managed database (PostgreSQL, MySQL, Redis) with automated backups
- **[objectstore](./objectstore/)** - S3-compatible object storage with CORS and encryption
- **[network](./network/)** - Virtual network with firewall rules and load balancers

## Quick Start

### Prerequisites

1. **Civo Account**: Sign up at [https://www.civo.com/](https://www.civo.com/)
2. **API Token**: Generate in [Civo Dashboard → Security](https://dashboard.civo.com/security)
3. **Terraform >= 1.6.0**

### Set up Provider

```hcl
terraform {
  required_providers {
    civo = {
      source  = "civo/civo"
      version = ">= 1.0.0"
    }
  }
}

provider "civo" {
  token  = var.civo_token
  region = "NYC1"
}
```

### 1. Network Setup

```hcl
module "network" {
  source = "./modules/civo/network"

  network_name = "fawkes-prod-network"
  location     = "NYC1"
  cidr_block   = "10.0.0.0/16"

  create_firewall = true
  firewall_rules = [
    {
      protocol    = "tcp"
      start_port  = 443
      end_port    = 443
      cidr_blocks = ["0.0.0.0/0"]
      direction   = "ingress"
      label       = "Allow HTTPS"
      action      = "allow"
    }
  ]

  tags = local.tags
}
```

### 2. Kubernetes Cluster

```hcl
module "kubernetes" {
  source = "./modules/civo/kubernetes"

  cluster_name = "fawkes-prod-cluster"
  location     = "NYC1"

  # Use size preset for simplicity
  size_preset = "medium"  # small, medium, or large

  # Or specify explicitly
  node_count   = 3
  node_vm_size = "g4s.kube.medium"

  kubernetes_version = "1.28.0"
  cni_plugin         = "flannel"  # or "cilium"

  network_id  = module.network.network_id
  firewall_id = module.network.firewall_id

  # Install marketplace apps
  marketplace_apps = [
    {
      name    = "metrics-server"
      version = null
    },
    {
      name    = "cert-manager"
      version = null
    }
  ]

  tags = local.tags
}
```

### 3. Database

```hcl
module "database" {
  source = "./modules/civo/database"

  database_name  = "fawkes-prod-db"
  location       = "NYC1"
  engine         = "postgres"  # postgres, mysql, or redis
  engine_version = "14"

  # Use size preset
  size_preset = "small"  # small, medium, or large

  # Or specify explicitly
  database_size = "g3.db.small"
  node_count    = 1

  network_id  = module.network.network_id
  firewall_id = module.network.firewall_id

  # Allow access from specific CIDR blocks
  allowed_cidr_blocks = [module.network.network_cidr]

  backup_enabled        = true
  backup_retention_days = 7

  tags = local.tags
}
```

### 4. Object Storage

```hcl
module "objectstore" {
  source = "./modules/civo/objectstore"

  bucket_name = "fawkes-prod-storage"
  location    = "NYC1"
  max_size_gb = 500

  create_credentials = true

  # Enable CORS for web applications
  enable_cors          = true
  cors_allowed_origins = ["https://*.example.com"]
  cors_allowed_methods = ["GET", "POST", "PUT", "DELETE"]

  enable_versioning = true
  enable_encryption = true

  tags = local.tags
}
```

## Module Features

### Kubernetes Module
- ✅ K3s-based clusters (faster deployment than EKS/GKE)
- ✅ Multiple node pools support
- ✅ Size presets (small/medium/large)
- ✅ CNI plugin selection (Flannel, Cilium)
- ✅ Marketplace app installation
- ✅ Network and firewall integration
- ✅ Cost tagging

### Database Module
- ✅ PostgreSQL, MySQL, Redis support
- ✅ Size presets for easy configuration
- ✅ High availability (1-3 nodes)
- ✅ Automated backups (1-30 days retention)
- ✅ Firewall rules for access control
- ✅ Network integration
- ✅ Cost tagging

### Object Store Module
- ✅ S3-compatible API
- ✅ Automatic credential generation
- ✅ CORS configuration
- ✅ Versioning support
- ✅ Server-side encryption
- ✅ Lifecycle rules
- ✅ Cost tagging

### Network Module
- ✅ Virtual network creation
- ✅ Custom CIDR blocks
- ✅ Firewall with custom rules
- ✅ Load balancer configuration
- ✅ Reserved IP support
- ✅ Cost tagging

## Examples

See the [examples](./examples/) directory for complete working examples:
- **[complete](./examples/complete/)** - Full infrastructure stack with all modules

## Best Practices

### Cost Optimization
1. **Use size presets** - Start with `small` and scale up as needed
2. **Enable auto-scaling** - For Kubernetes node pools
3. **Set backup retention** - Balance cost vs. recovery needs (7 days recommended)
4. **Monitor storage usage** - Set appropriate `max_size_gb` for object stores
5. **Tag resources** - Use cost tags for tracking and allocation

### Security
1. **Restrict firewall rules** - Use specific CIDR blocks instead of `0.0.0.0/0`
2. **Enable encryption** - Always enable for object storage
3. **Use private networks** - Keep databases and clusters in private networks
4. **Rotate credentials** - Regularly rotate database and object store credentials
5. **Enable backups** - Always enable for production databases

### High Availability
1. **Multi-node databases** - Use 2-3 nodes for production
2. **Multiple node pools** - Distribute workloads across pools
3. **Health checks** - Configure load balancer health checks
4. **Backup strategy** - Test restore procedures regularly

### Networking
1. **Plan CIDR blocks** - Avoid overlapping with other networks
2. **Use firewall rules** - Explicit allow/deny rules
3. **Load balancer** - For ingress traffic distribution
4. **Reserved IPs** - For stable external endpoints

## Civo-Specific Considerations

### Regions
Civo currently supports 4 regions:
- **NYC1** - New York, USA
- **LON1** - London, UK
- **FRA1** - Frankfurt, Germany
- **PHX1** - Phoenix, USA

Choose the region closest to your users for best latency.

### Instance Sizes
Civo offers optimized instance sizes:
- **xsmall** - Development/testing
- **small** - Small workloads
- **medium** - Standard workloads (recommended)
- **large** - Production workloads
- **xlarge** - High-performance workloads

### Rate Limits
Civo API has rate limits (~100 requests/min). Use Terraform's parallelism settings:
```bash
terraform apply -parallelism=3
```

### Marketplace Apps
Popular apps available:
- Cert Manager
- Metrics Server
- Traefik
- Longhorn
- ArgoCD
- Prometheus
- Grafana

## Migration from AWS/GCP

Key differences to consider:
- **Kubernetes**: K3s instead of full Kubernetes
- **Databases**: Application-based instead of managed services
- **Networking**: Simpler model, no complex VPC/subnet management
- **Regions**: 4 regions vs 20+ for AWS/GCP
- **Pricing**: More straightforward, typically lower cost

## Validation

Validate your Terraform configurations:

```bash
# Format code
terraform fmt -recursive

# Validate configuration
terraform validate

# Run linter
tflint --recursive

# Check costs
infracost breakdown --path .
```

## Support

- **Civo Documentation**: [https://www.civo.com/docs](https://www.civo.com/docs)
- **Terraform Provider**: [https://registry.terraform.io/providers/civo/civo](https://registry.terraform.io/providers/civo/civo)
- **Civo Community**: [https://www.civo.com/community](https://www.civo.com/community)

## Contributing

When contributing to these modules:
1. Follow the existing code style
2. Add validation rules for all variables
3. Include comprehensive outputs
4. Document all resources
5. Add examples for new features
6. Test thoroughly before submitting

## License

MIT License - See root repository LICENSE file for details.
