# GCP Provider Setup Guide

This guide covers setting up and using the GCP (Google Cloud Platform) provider for the Cloud Provider Service.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Authentication Methods](#authentication-methods)
- [Quick Start](#quick-start)
- [Multi-Project Configuration](#multi-project-configuration)
- [Workload Identity Setup](#workload-identity-setup)
- [Usage Examples](#usage-examples)
- [Best Practices](#best-practices)
- [Troubleshooting](#troubleshooting)

## Prerequisites

### Required GCP APIs

Enable the following APIs in your GCP project:

```bash
gcloud services enable container.googleapis.com         # GKE
gcloud services enable sqladmin.googleapis.com          # Cloud SQL
gcloud services enable storage-api.googleapis.com       # Cloud Storage
gcloud services enable monitoring.googleapis.com        # Cloud Monitoring
gcloud services enable cloudbilling.googleapis.com      # Cloud Billing
gcloud services enable iam.googleapis.com               # IAM
gcloud services enable cloudresourcemanager.googleapis.com
```

### Required IAM Permissions

The service account or user needs the following roles:

- **Kubernetes Engine Admin** (`roles/container.admin`) - For GKE operations
- **Cloud SQL Admin** (`roles/cloudsql.admin`) - For Cloud SQL operations
- **Storage Admin** (`roles/storage.admin`) - For Cloud Storage operations
- **Monitoring Viewer** (`roles/monitoring.viewer`) - For metrics
- **Billing Account Viewer** (`roles/billing.viewer`) - For cost data
- **Service Account Admin** (`roles/iam.serviceAccountAdmin`) - For Workload Identity
- **Project IAM Admin** (`roles/resourcemanager.projectIamAdmin`) - For IAM bindings

### Python Dependencies

```bash
pip install google-cloud-container
pip install google-cloud-sql-connector
pip install google-cloud-storage
pip install google-cloud-monitoring
pip install google-cloud-billing
pip install google-auth
```

## Authentication Methods

### 1. Application Default Credentials (Recommended for Development)

The easiest method for local development:

```bash
gcloud auth application-default login
```

Then in Python:

```python
from src.providers.gcp_provider import GCPProvider

# Project ID will be auto-detected
provider = GCPProvider()
```

### 2. Service Account Key File

For production or CI/CD:

1. Create a service account:
```bash
gcloud iam service-accounts create fawkes-cloud-provider \
    --display-name="Fawkes Cloud Provider Service Account"
```

2. Grant required roles:
```bash
PROJECT_ID="your-project-id"
SA_EMAIL="fawkes-cloud-provider@${PROJECT_ID}.iam.gserviceaccount.com"

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --member="serviceAccount:${SA_EMAIL}" \
    --role="roles/container.admin"

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --member="serviceAccount:${SA_EMAIL}" \
    --role="roles/cloudsql.admin"

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --member="serviceAccount:${SA_EMAIL}" \
    --role="roles/storage.admin"

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --member="serviceAccount:${SA_EMAIL}" \
    --role="roles/monitoring.viewer"

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --member="serviceAccount:${SA_EMAIL}" \
    --role="roles/billing.viewer"
```

3. Create and download key:
```bash
gcloud iam service-accounts keys create ~/fawkes-sa-key.json \
    --iam-account=${SA_EMAIL}
```

4. Use in Python:
```python
from src.providers.gcp_provider import GCPProvider

provider = GCPProvider(
    project_id="your-project-id",
    credentials_path="/path/to/fawkes-sa-key.json"
)
```

### 3. Workload Identity (Recommended for GKE)

For applications running in GKE, use Workload Identity (no key files needed):

```python
from src.providers.gcp_provider import GCPProvider

provider = GCPProvider(
    project_id="your-project-id",
    service_account_email="fawkes-cloud-provider@your-project-id.iam.gserviceaccount.com"
)
```

See [Workload Identity Setup](#workload-identity-setup) for detailed configuration.

## Quick Start

### Basic Usage

```python
from src.providers.gcp_provider import GCPProvider
from src.interfaces.provider import ClusterConfig, DatabaseConfig, StorageConfig

# Initialize provider
provider = GCPProvider(project_id="your-project-id")

# Create a GCS bucket
storage_config = StorageConfig(
    name="my-application-bucket",
    region="us-central1",
    versioning_enabled=True,
    encryption_enabled=True,
    public_access_blocked=True,
    tags={"environment": "production", "team": "platform"}
)

bucket = provider.create_storage(storage_config)
print(f"Created bucket: {bucket.name}")

# List existing clusters
clusters = provider.list_clusters(region="us-central1")
for cluster in clusters:
    print(f"Cluster: {cluster.name}, Status: {cluster.status}")

# Get cost data
cost_data = provider.get_cost_data("LAST_30_DAYS", "MONTHLY")
print(f"Total cost: ${cost_data.total_cost:.2f}")
```

### Creating a GKE Cluster

```python
from src.interfaces.provider import ClusterConfig

cluster_config = ClusterConfig(
    name="my-gke-cluster",
    region="us-central1",
    version="1.28",
    node_count=3,
    node_instance_type="n1-standard-2",
    subnet_ids=["projects/your-project/regions/us-central1/subnetworks/your-subnet"],
    tags={
        "environment": "production",
        "managed-by": "fawkes"
    },
    metadata={
        "enable_workload_identity": True
    }
)

cluster = provider.create_cluster(cluster_config)
print(f"Cluster created: {cluster.name}, Status: {cluster.status}")
```

### Creating a Cloud SQL Database

```python
from src.interfaces.provider import DatabaseConfig

db_config = DatabaseConfig(
    name="my-postgres-db",
    engine="postgres",
    engine_version="14",
    instance_class="db-n1-standard-1",
    region="us-central1",
    allocated_storage=20,
    master_username="admin",
    master_password="your-secure-password",
    multi_az=True,
    backup_retention_days=7,
    tags={
        "environment": "production",
        "team": "platform"
    }
)

database = provider.create_database(db_config)
print(f"Database created: {database.name}, Status: {database.status}")
```

## Multi-Project Configuration

To work with multiple GCP projects, create separate provider instances:

```python
# Production project
prod_provider = GCPProvider(project_id="prod-project-id")

# Development project
dev_provider = GCPProvider(project_id="dev-project-id")

# Staging project with different credentials
staging_provider = GCPProvider(
    project_id="staging-project-id",
    credentials_path="/path/to/staging-sa-key.json"
)

# Use each provider independently
prod_clusters = prod_provider.list_clusters(region="us-central1")
dev_clusters = dev_provider.list_clusters(region="us-east1")
```

## Workload Identity Setup

Workload Identity allows GKE pods to authenticate to GCP services without using service account keys.

### 1. Enable Workload Identity on GKE Cluster

```bash
# For new cluster
gcloud container clusters create my-cluster \
    --workload-pool=PROJECT_ID.svc.id.goog

# For existing cluster
gcloud container clusters update my-cluster \
    --workload-pool=PROJECT_ID.svc.id.goog
```

### 2. Create GCP Service Account

```python
from src.providers.gcp_provider import GCPProvider

provider = GCPProvider(project_id="your-project-id")

# Create service account
sa_info = provider.create_service_account(
    name="fawkes-app",
    display_name="Fawkes Application Service Account",
    description="Service account for Fawkes application"
)

print(f"Created service account: {sa_info['email']}")
```

### 3. Bind Workload Identity

```python
# Bind GCP service account to Kubernetes service account
result = provider.bind_workload_identity(
    service_account_email="fawkes-app@your-project-id.iam.gserviceaccount.com",
    namespace="default",
    k8s_service_account="fawkes-app-ksa"
)
```

### 4. Configure Kubernetes Service Account

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: fawkes-app-ksa
  namespace: default
  annotations:
    iam.gke.io/gcp-service-account: fawkes-app@your-project-id.iam.gserviceaccount.com
```

### 5. Use in Pod

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: fawkes-app
  namespace: default
spec:
  serviceAccountName: fawkes-app-ksa
  containers:
  - name: app
    image: your-app-image
    env:
    - name: GCP_PROJECT_ID
      value: "your-project-id"
```

## Usage Examples

### Retrieving Metrics

```python
from datetime import datetime, timedelta

# Get CPU utilization for a GCE instance
end_time = datetime.now()
start_time = end_time - timedelta(hours=1)

metrics = provider.get_metrics(
    resource_id="instance-123",
    metric_name="compute.googleapis.com/instance/cpu/utilization",
    start_time=start_time.isoformat(),
    end_time=end_time.isoformat(),
    resource_type="gce_instance",
    resource_labels={"instance_id": "instance-123", "zone": "us-central1-a"},
    region="us-central1"
)

print(f"Retrieved {len(metrics['datapoints'])} datapoints")
```

### Cost Analysis

```python
# Get cost data for different time periods
last_week = provider.get_cost_data("LAST_7_DAYS", "DAILY")
print(f"Last 7 days: ${last_week.total_cost:.2f}")

this_month = provider.get_cost_data("THIS_MONTH", "MONTHLY")
print(f"This month: ${this_month.total_cost:.2f}")

# Note: For detailed cost breakdown, enable BigQuery billing export
# See: https://cloud.google.com/billing/docs/how-to/export-data-bigquery
```

### Error Handling

```python
from src.exceptions import (
    CloudProviderError,
    ResourceNotFoundError,
    ResourceAlreadyExistsError,
    AuthenticationError,
    ValidationError
)

try:
    cluster = provider.get_cluster("my-cluster", "us-central1")
except ResourceNotFoundError:
    print("Cluster not found")
except AuthenticationError as e:
    print(f"Authentication failed: {str(e)}")
except ValidationError as e:
    print(f"Invalid parameters: {str(e)}")
except CloudProviderError as e:
    print(f"GCP API error: {str(e)}")
```

## Best Practices

### 1. Use Workload Identity

Avoid service account keys whenever possible. Use Workload Identity for GKE workloads.

### 2. Enable Rate Limiting

```python
# Configure rate limiting to avoid quota exhaustion
provider = GCPProvider(
    project_id="your-project-id",
    rate_limit_calls=100,  # Max 100 calls per window
    rate_limit_window=60.0  # 60 second window
)
```

### 3. Use Labels/Tags

Always tag resources for better organization and cost tracking:

```python
config = StorageConfig(
    name="my-bucket",
    region="us-central1",
    tags={
        "environment": "production",
        "team": "platform",
        "cost-center": "engineering",
        "managed-by": "fawkes"
    }
)
```

### 4. Enable Logging

```python
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("src.providers.gcp_provider")
logger.setLevel(logging.DEBUG)
```

### 5. Use Secrets Management

Never hardcode credentials. Use Secret Manager:

```python
from google.cloud import secretmanager

def get_db_password(project_id, secret_id):
    client = secretmanager.SecretManagerServiceClient()
    name = f"projects/{project_id}/secrets/{secret_id}/versions/latest"
    response = client.access_secret_version(request={"name": name})
    return response.payload.data.decode("UTF-8")

db_config = DatabaseConfig(
    name="my-db",
    engine="postgres",
    engine_version="14",
    instance_class="db-n1-standard-1",
    region="us-central1",
    master_username="admin",
    master_password=get_db_password("your-project-id", "db-admin-password")
)
```

## Troubleshooting

### Authentication Issues

**Problem**: `AuthenticationError: No GCP credentials found`

**Solution**:
1. Run `gcloud auth application-default login`
2. Or set `GOOGLE_APPLICATION_CREDENTIALS` environment variable
3. Or provide `credentials_path` parameter

### Permission Denied

**Problem**: `403 Permission denied` errors

**Solution**:
1. Verify service account has required roles
2. Check if APIs are enabled
3. Ensure project ID is correct

```bash
# Check enabled APIs
gcloud services list --enabled

# Enable missing APIs
gcloud services enable container.googleapis.com sqladmin.googleapis.com
```

### Quota Exhausted

**Problem**: `429 Quota exceeded` errors

**Solution**:
1. Increase rate limiting configuration
2. Request quota increase from GCP Console
3. Implement exponential backoff (already included)

### Region/Zone Issues

**Problem**: Resources not found in specified region

**Solution**:
- For clusters, use full location (e.g., `us-central1` or `us-central1-a`)
- For databases, use region only (e.g., `us-central1`)
- Use `-` for all regions: `provider.list_clusters(region="-")`

### Cost Data Not Available

**Problem**: `get_cost_data()` returns $0.00

**Solution**:
1. Enable BigQuery billing export
2. Configure export dataset
3. Query BigQuery directly for detailed costs

```bash
# Enable billing export
gcloud billing accounts list
gcloud billing projects link YOUR_PROJECT --billing-account=BILLING_ACCOUNT_ID
```

See: https://cloud.google.com/billing/docs/how-to/export-data-bigquery

## Additional Resources

- [GCP Cloud Provider API Documentation](../README.md)
- [Google Cloud Documentation](https://cloud.google.com/docs)
- [Workload Identity Guide](https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity)
- [GCP IAM Best Practices](https://cloud.google.com/iam/docs/best-practices)
- [GCP Cost Management](https://cloud.google.com/cost-management)

## Support

For issues or questions:
1. Check the [main README](../README.md)
2. Review [AWS Provider docs](./AWS_SETUP.md) for comparison
3. File an issue in the repository
