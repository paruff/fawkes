# Civo Provider Setup Guide

This guide covers setting up and using the Civo provider for the Cloud Provider Service.

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Authentication](#authentication)
- [Quick Start](#quick-start)
- [Civo-Specific Limitations](#civo-specific-limitations)
- [Usage Examples](#usage-examples)
- [Best Practices](#best-practices)
- [Troubleshooting](#troubleshooting)

## Overview

Civo is a cloud-native service provider focused on Kubernetes and developer experience. It offers:

- **Fast K3s Kubernetes clusters** (2-3 minute deployment vs 10-15 for EKS/GKE)
- **Simple pricing** and transparent costs
- **Limited regions** for focused service quality
- **Developer-friendly** tools and APIs
- **S3-compatible object storage**
- **Marketplace applications** for quick deployments

### Key Differences from AWS/GCP

| Feature | AWS/GCP | Civo |
|---------|---------|------|
| Kubernetes | EKS/GKE (full K8s) | K3s (lightweight) |
| Regions | 20+ global regions | 4 regions (NYC, LON, FRA, PHX) |
| Databases | Managed services (RDS/CloudSQL) | K8s applications (PostgreSQL, MySQL, etc.) |
| Networking | Complex VPC/subnet management | Simple networking model |
| Cluster Creation | 10-15 minutes | 2-3 minutes |
| Instance Sizes | 100+ instance types | ~10 optimized sizes |
| Rate Limits | High (1000s/min) | Moderate (~100/min) |

## Prerequisites

### Required Components

1. **Civo Account**: Sign up at [https://www.civo.com/](https://www.civo.com/)
2. **API Key**: Generate in [Civo Dashboard → Security](https://dashboard.civo.com/security)
3. **Python 3.8+**: Required for the cloud provider service

### Python Dependencies

```bash
pip install civo==1.0.5
```

Or install all cloud provider dependencies:

```bash
cd services/cloud-provider
pip install -r requirements.txt
```

## Authentication

The Civo provider supports multiple authentication methods, in order of priority:

### 1. API Key Parameter (Recommended for Production)

```python
from src.providers.civo_provider import CivoProvider

provider = CivoProvider(
    api_key="your-api-key-here",
    region="NYC1"
)
```

**Best Practice**: Store API key in a secret manager (AWS Secrets Manager, HashiCorp Vault, etc.)

### 2. Environment Variable

```bash
export CIVO_TOKEN="your-api-key-here"
export CIVO_REGION="NYC1"  # Optional, defaults to NYC1
```

```python
from src.providers.civo_provider import CivoProvider

provider = CivoProvider()  # Reads from environment
```

### 3. Civo CLI Config File

If you use the Civo CLI, it stores credentials in `~/.civo.json`:

```bash
# Install Civo CLI
brew install civo  # macOS
# OR
curl -sL https://civo.com/get | sh

# Authenticate
civo apikey save my-key YOUR_API_KEY
civo region ls
```

The provider will automatically use these credentials.

## Quick Start

### Basic Usage

```python
from src.providers.civo_provider import CivoProvider
from src.interfaces.provider import ClusterConfig, StorageConfig

# Initialize provider
provider = CivoProvider(api_key="your-api-key", region="NYC1")

# Create a Kubernetes cluster
cluster_config = ClusterConfig(
    name="dev-cluster",
    region="NYC1",
    version="1.28.0",
    node_count=3,
    node_instance_type="g4s.kube.medium",
)

cluster = provider.create_cluster(cluster_config)
print(f"Cluster created: {cluster.id}")
print(f"API endpoint: {cluster.endpoint}")

# Create object storage
storage_config = StorageConfig(
    name="my-bucket",
    region="NYC1",
    metadata={"max_size_gb": 500}
)

storage = provider.create_storage(storage_config)
print(f"Storage created: {storage.id}")

# List all clusters
clusters = provider.list_clusters()
for c in clusters:
    print(f"  - {c.name}: {c.status}")

# Clean up
provider.delete_cluster(cluster.id)
provider.delete_storage(storage.id)
```

### With Applications

Install applications during cluster creation:

```python
cluster_config = ClusterConfig(
    name="app-cluster",
    region="NYC1",
    version="1.28.0",
    node_count=3,
    metadata={
        "applications": "PostgreSQL:5GB,Redis:5GB,Prometheus-Operator",
        "cni_plugin": "flannel"  # or "cilium"
    }
)

cluster = provider.create_cluster(cluster_config)
```

## Civo-Specific Limitations

### 1. Limited Regions

Civo currently operates in 4 regions:

- **NYC1**: New York, USA (East Coast)
- **LON1**: London, UK
- **FRA1**: Frankfurt, Germany
- **PHX1**: Phoenix, USA (West Coast)

```python
# Validate region
provider = CivoProvider(api_key="key", region="NYC1")
print(f"Valid regions: {provider.VALID_REGIONS}")
```

### 2. Database Service Model

Unlike AWS RDS or GCP Cloud SQL, Civo doesn't have separate managed database services. Databases are deployed as Kubernetes applications:

```python
from src.interfaces.provider import DatabaseConfig

# Must specify cluster_id for database deployment
db_config = DatabaseConfig(
    name="my-postgres",
    engine="postgresql",
    engine_version="14",
    instance_class="small",
    region="NYC1",
    metadata={
        "cluster_id": "cluster-123",  # REQUIRED
    }
)

# This will deploy PostgreSQL as a K8s application
database = provider.create_database(db_config)
```

**Supported Database Engines**:
- `postgresql` (PostgreSQL)
- `mysql` (MySQL)
- `mariadb` (MariaDB)
- `mongodb` (MongoDB)
- `redis` (Redis)

### 3. Simplified Networking

Civo uses a simpler networking model:

- No complex VPC/subnet management
- Basic network isolation between clusters
- Firewall rules are simpler
- Direct public IP assignment

```python
# VPC ID in config is interpreted as network_id
cluster_config = ClusterConfig(
    name="my-cluster",
    region="NYC1",
    version="1.28.0",
    node_count=2,
    vpc_id="network-abc123",  # Optional Civo network ID
)
```

### 4. Node Instance Types

Civo offers ~10 optimized instance types vs 100+ in AWS/GCP:

**Common Types**:
- `g4s.kube.xsmall`: 1 vCPU, 1GB RAM (development)
- `g4s.kube.small`: 1 vCPU, 2GB RAM
- `g4s.kube.medium`: 2 vCPU, 4GB RAM (default)
- `g4s.kube.large`: 4 vCPU, 8GB RAM
- `g4s.kube.xlarge`: 6 vCPU, 16GB RAM

### 5. Rate Limiting

Civo has stricter rate limits than AWS/GCP:

```python
# Configure rate limiting (default: 5 calls/second)
provider = CivoProvider(
    api_key="key",
    rate_limit_calls=5,      # Max calls
    rate_limit_window=1.0    # Time window in seconds
)
```

**Rate Limit Best Practices**:
- Batch operations when possible
- Use exponential backoff (built into provider)
- Cache results for frequently accessed data
- Don't poll cluster status too frequently

### 6. Object Storage Limits

Civo object storage has size limits:

- Default: 500GB per bucket
- Maximum: 5TB per bucket (with quota increase)
- No versioning support
- S3-compatible but with fewer features

```python
storage_config = StorageConfig(
    name="large-bucket",
    region="NYC1",
    metadata={
        "max_size_gb": 1000,  # Request 1TB
    }
)
```

### 7. Metrics and Monitoring

Civo doesn't have a centralized metrics service like CloudWatch:

- Metrics available through Prometheus in each cluster
- No unified monitoring dashboard
- Use `kubectl` and Prometheus queries

```python
# get_metrics returns a placeholder
metrics = provider.get_metrics(
    resource_id="cluster-123",
    metric_name="cpu_usage",
    start_time="2024-01-14T00:00:00Z",
    end_time="2024-01-14T23:59:59Z",
)
# Returns note: "Query cluster's Prometheus instance directly"
```

## Usage Examples

### Example 1: Development Environment

```python
"""Create a complete development environment."""

from src.providers.civo_provider import CivoProvider
from src.interfaces.provider import ClusterConfig, StorageConfig, DatabaseConfig

provider = CivoProvider(api_key="key", region="NYC1")

# Small K8s cluster for dev
cluster_config = ClusterConfig(
    name="dev-env",
    region="NYC1",
    version="1.28.0",
    node_count=2,
    node_instance_type="g4s.kube.small",
    metadata={
        "applications": "Prometheus-Operator,Traefik",
    }
)

cluster = provider.create_cluster(cluster_config)
print(f"✅ Cluster: {cluster.endpoint}")

# Object storage for backups
storage_config = StorageConfig(
    name="dev-backups",
    region="NYC1",
    metadata={"max_size_gb": 100}
)

storage = provider.create_storage(storage_config)
print(f"✅ Storage: {storage.metadata['bucket_url']}")

# Deploy database
db_config = DatabaseConfig(
    name="dev-db",
    engine="postgresql",
    engine_version="14",
    instance_class="small",
    region="NYC1",
    metadata={"cluster_id": cluster.id}
)

database = provider.create_database(db_config)
print(f"✅ Database: {database.name} deploying")

print("\n🎉 Development environment ready!")
```

### Example 2: Multi-Region Deployment

```python
"""Deploy to multiple Civo regions."""

regions = ["NYC1", "LON1", "FRA1"]

for region in regions:
    provider = CivoProvider(api_key="key", region=region)
    
    config = ClusterConfig(
        name=f"prod-{region.lower()}",
        region=region,
        version="1.28.0",
        node_count=3,
        node_instance_type="g4s.kube.medium",
    )
    
    cluster = provider.create_cluster(config)
    print(f"✅ {region}: {cluster.id}")
```

### Example 3: Cost Monitoring

```python
"""Monitor Civo costs."""

from datetime import datetime

provider = CivoProvider(api_key="key")

# Get cost data
cost_data = provider.get_cost_data("LAST_30_DAYS", "MONTHLY")

print(f"Total cost: ${cost_data.total_cost:.2f} {cost_data.currency}")
print("\nBreakdown:")
for service, cost in cost_data.breakdown.items():
    print(f"  {service}: ${cost:.2f}")

# Check quota
quota = provider.get_quota()
print(f"\nQuota usage: {quota['instance_count_usage']}/{quota['instance_count_limit']}")
```

### Example 4: Cluster Lifecycle Management

```python
"""Complete cluster lifecycle with error handling."""

import time
from src.providers.civo_provider import CivoProvider
from src.interfaces.provider import ClusterConfig
from src.exceptions import CloudProviderError, ResourceNotFoundError

provider = CivoProvider(api_key="key", region="NYC1")

try:
    # Create cluster
    config = ClusterConfig(
        name="lifecycle-test",
        region="NYC1",
        version="1.28.0",
        node_count=2,
    )
    
    cluster = provider.create_cluster(config)
    print(f"✅ Created: {cluster.id}")
    
    # Wait for cluster to be ready
    max_attempts = 30
    for attempt in range(max_attempts):
        cluster = provider.get_cluster(cluster.id)
        print(f"Status: {cluster.status}")
        
        if cluster.status == "ACTIVE":
            print("✅ Cluster ready!")
            break
        
        time.sleep(10)
    
    # Use cluster...
    print(f"Endpoint: {cluster.endpoint}")
    print(f"Kubeconfig: {cluster.metadata.get('kubeconfig')}")
    
    # Clean up
    provider.delete_cluster(cluster.id)
    print("✅ Deleted cluster")
    
except CloudProviderError as e:
    print(f"❌ Error: {e}")
    print(f"Provider: {e.provider}")
    print(f"Error code: {e.error_code}")

except ResourceNotFoundError as e:
    print(f"❌ Resource not found: {e}")
```

## Best Practices

### 1. API Key Security

```python
# ✅ DO: Use secret management
import os
from aws_secretsmanager import get_secret

api_key = get_secret("civo/api-key")
provider = CivoProvider(api_key=api_key)

# ❌ DON'T: Hardcode API keys
provider = CivoProvider(api_key="abc123...")  # Bad!
```

### 2. Rate Limiting

```python
# ✅ DO: Respect rate limits
provider = CivoProvider(
    api_key="key",
    rate_limit_calls=5,  # Be conservative
)

# Use list operations instead of multiple get calls
clusters = provider.list_clusters()

# ❌ DON'T: Make too many individual calls
for cluster_id in cluster_ids:
    cluster = provider.get_cluster(cluster_id)  # Rate limit risk
```

### 3. Resource Naming

```python
# ✅ DO: Use descriptive, unique names
config = ClusterConfig(
    name=f"prod-app-{env}-{timestamp}",
    ...
)

# ❌ DON'T: Use generic names
config = ClusterConfig(name="test", ...)  # Conflicts likely
```

### 4. Error Handling

```python
# ✅ DO: Handle specific exceptions
from src.exceptions import (
    CloudProviderError,
    ResourceNotFoundError,
    QuotaExceededError,
    RateLimitError,
)

try:
    cluster = provider.create_cluster(config)
except ResourceAlreadyExistsError:
    print("Cluster already exists, using existing")
    cluster = provider.get_cluster(config.name)
except QuotaExceededError:
    print("Quota exceeded, clean up old resources")
except RateLimitError:
    print("Rate limited, retry later")
except CloudProviderError as e:
    print(f"Other error: {e}")
```

### 5. Resource Tagging

```python
# ✅ DO: Use tags for organization
config = ClusterConfig(
    name="my-cluster",
    region="NYC1",
    version="1.28.0",
    node_count=3,
    tags={
        "environment": "production",
        "team": "platform",
        "cost-center": "engineering",
        "project": "fawkes",
    }
)
```

### 6. Cleanup

```python
# ✅ DO: Always clean up resources
try:
    cluster = provider.create_cluster(config)
    # Use cluster...
finally:
    provider.delete_cluster(cluster.id)

# ✅ DO: Use context managers
from contextlib import contextmanager

@contextmanager
def temporary_cluster(provider, config):
    cluster = provider.create_cluster(config)
    try:
        yield cluster
    finally:
        provider.delete_cluster(cluster.id)

with temporary_cluster(provider, config) as cluster:
    # Use cluster...
    pass  # Automatically deleted
```

## Troubleshooting

### Issue: "No Civo API key found"

```
AuthenticationError: No Civo API key found.
```

**Solution**:
1. Generate API key in [Civo Dashboard](https://dashboard.civo.com/security)
2. Set environment variable: `export CIVO_TOKEN="your-key"`
3. Or pass to provider: `CivoProvider(api_key="your-key")`

### Issue: "401 Unauthorized"

```
AuthenticationError: Invalid API key
```

**Solution**:
1. Check API key is correct
2. Verify key hasn't expired
3. Ensure key has required permissions
4. Try regenerating key in Civo Dashboard

### Issue: "Rate limit exceeded"

```
RateLimitError: Rate limit timeout exceeded
```

**Solution**:
1. Reduce `rate_limit_calls` parameter
2. Add delays between operations
3. Use list operations instead of multiple gets
4. Cache frequently accessed data

### Issue: "Cluster creation times out"

```
Cluster status stuck at "creating"
```

**Solution**:
1. Check Civo status page: [https://status.civo.com](https://status.civo.com)
2. Wait longer (usually 2-3 minutes for Civo)
3. Check account quota: `provider.get_quota()`
4. Try different region
5. Contact Civo support if issue persists

### Issue: "Database not found"

```
ResourceNotFoundError: Database not found.
Note: Civo databases are deployed as cluster applications.
```

**Solution**:
1. Ensure `cluster_id` is provided in database config
2. Check cluster exists and is active
3. Verify database is in cluster's installed applications:
   ```python
   cluster = provider.get_cluster(cluster_id)
   apps = cluster.metadata.get('installed_applications', [])
   ```

### Issue: "Object storage quota exceeded"

```
QuotaExceededError: Storage quota exceeded
```

**Solution**:
1. Check current usage: `provider.get_quota()`
2. Delete unused buckets
3. Request quota increase from Civo support
4. Use smaller buckets (max 5TB per bucket)

## Additional Resources

- **Civo Documentation**: [https://www.civo.com/docs](https://www.civo.com/docs)
- **Civo API Reference**: [https://www.civo.com/api](https://www.civo.com/api)
- **Civo CLI**: [https://github.com/civo/cli](https://github.com/civo/cli)
- **Civo Python SDK**: [https://github.com/civo/client-python](https://github.com/civo/client-python)
- **Civo Community**: [https://www.civo.com/community](https://www.civo.com/community)
- **Civo Status**: [https://status.civo.com](https://status.civo.com)
- **Pricing**: [https://www.civo.com/pricing](https://www.civo.com/pricing)

## Support

For issues with:
- **This provider implementation**: Open issue in Fawkes repository
- **Civo API/Service**: Contact [Civo Support](https://www.civo.com/contact)
- **Civo Python SDK**: Open issue in [civo/client-python](https://github.com/civo/client-python)
