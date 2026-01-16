# Cloud Provider Service

A unified abstraction layer for interacting with multiple cloud providers, including AWS and Azure support.

## Features

- **Multi-cloud abstraction**: Common interface for cloud operations across providers
- **AWS Support**: Full implementation for EKS, RDS, S3, CloudWatch, and Cost Explorer
- **Azure Support**: Full implementation for AKS, Azure Database, Blob Storage, Azure Monitor, and Cost Management
- **Flexible Authentication**: 
  - **AWS**: IAM roles, STS assume role, access keys, AWS profile, environment variables, instance metadata
  - **Azure**: Managed Identity, Service Principal, Azure CLI, DefaultAzureCredential
- **Error Handling**: Comprehensive error handling with retries and exponential backoff
- **Rate Limiting**: Built-in rate limiting to prevent API throttling
- **Logging**: Detailed logging of all API calls
- **Type Safety**: Full type hints for better IDE support and type checking

## Installation

```bash
pip install -r requirements.txt
```

For development:

```bash
pip install -r requirements-dev.txt
```

## Quick Start

### Basic Usage

```python
from src.providers.aws_provider import AWSProvider
from src.interfaces.provider import StorageConfig

# Initialize provider (uses IAM role or environment credentials)
provider = AWSProvider(region="us-west-2")

# Create an S3 bucket
config = StorageConfig(
    name="my-application-bucket",
    region="us-west-2",
    versioning_enabled=True,
    encryption_enabled=True,
    tags={"Environment": "production", "Team": "platform"}
)

bucket = provider.create_storage(config)
print(f"Created bucket: {bucket.name}")

# List all buckets
buckets = provider.list_storage()
for bucket in buckets:
    print(f"- {bucket.name} ({bucket.region})")

# Get cost data
cost_data = provider.get_cost_data("LAST_30_DAYS", "DAILY")
print(f"Total cost: ${cost_data.total_cost:.2f}")
for service, cost in cost_data.breakdown.items():
    print(f"  {service}: ${cost:.2f}")
```

### Azure Basic Usage

```python
from src.providers.azure_provider import AzureProvider
from src.interfaces.provider import StorageConfig

# Initialize provider (uses managed identity or Azure CLI)
provider = AzureProvider(subscription_id="your-subscription-id")

# Create a storage account
config = StorageConfig(
    name="mystorageaccount123",  # Must be globally unique, lowercase
    region="eastus",
    versioning_enabled=False,
    encryption_enabled=True,
    metadata={
        "resource_group": "my-resource-group",
        "sku": "Standard_LRS",
        "kind": "StorageV2",
    },
    tags={"Environment": "production", "Team": "platform"}
)

storage = provider.create_storage(config)
print(f"Created storage account: {storage.name}")

# List all storage accounts
storage_accounts = provider.list_storage(resource_group="my-resource-group")
for account in storage_accounts:
    print(f"- {account.name} ({account.region})")

# Get cost data
cost_data = provider.get_cost_data("LAST_30_DAYS", "DAILY")
print(f"Total cost: ${cost_data.total_cost:.2f}")
for service, cost in cost_data.breakdown.items():
    print(f"  {service}: ${cost:.2f}")
```

## Authentication

### AWS Authentication

#### IAM Role (Recommended)

When running on AWS (EC2, ECS, Lambda), use IAM roles:

```python
provider = AWSProvider(region="us-west-2")
```

### Assume Role

Assume a specific IAM role:

```python
provider = AWSProvider(
    region="us-west-2",
    role_arn="arn:aws:iam::123456789012:role/MyRole"
)
```

### Access Keys

Use explicit credentials (least preferred for security):

```python
provider = AWSProvider(
    region="us-west-2",
    access_key_id="AKIAIOSFODNN7EXAMPLE",
    secret_access_key="wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
)
```

### AWS Profile

Use a named profile from `~/.aws/credentials`:

```python
provider = AWSProvider(
    region="us-west-2",
    profile_name="production"
)
```

### Environment Variables

Set environment variables:

```bash
export AWS_ACCESS_KEY_ID=your_access_key
export AWS_SECRET_ACCESS_KEY=your_secret_key
export AWS_DEFAULT_REGION=us-west-2
```

### Azure Authentication

#### Managed Identity (Recommended)

When running in Azure (VM, Container Instance, App Service, Functions), use managed identity:

```python
provider = AzureProvider(
    subscription_id="your-subscription-id",
    use_managed_identity=True
)
```

#### Service Principal

Use a service principal for programmatic access:

```python
provider = AzureProvider(
    subscription_id="your-subscription-id",
    tenant_id="your-tenant-id",
    client_id="your-client-id",
    client_secret="your-client-secret"
)
```

#### Azure CLI

Use Azure CLI authentication (for local development):

```python
provider = AzureProvider(
    subscription_id="your-subscription-id",
    use_cli=True
)
```

#### DefaultAzureCredential

Let Azure SDK try multiple authentication methods automatically:

```python
provider = AzureProvider(subscription_id="your-subscription-id")
# Tries: environment variables → managed identity → Azure CLI → interactive browser
```

#### Environment Variables

Set environment variables:

```bash
export AZURE_SUBSCRIPTION_ID=your_subscription_id
export AZURE_TENANT_ID=your_tenant_id
export AZURE_CLIENT_ID=your_client_id
export AZURE_CLIENT_SECRET=your_client_secret
```

## Usage Examples

### EKS Cluster Management

```python
from src.interfaces.provider import ClusterConfig

# Create EKS cluster
config = ClusterConfig(
    name="production-cluster",
    region="us-west-2",
    version="1.28",
    node_count=3,
    node_instance_type="t3.medium",
    subnet_ids=["subnet-abc123", "subnet-def456"],
    metadata={
        "role_arn": "arn:aws:iam::123456789012:role/eks-cluster-role"
    },
    tags={"Environment": "production"}
)

cluster = provider.create_cluster(config)
print(f"Cluster {cluster.name} status: {cluster.status}")

# Get cluster details
cluster = provider.get_cluster("production-cluster", "us-west-2")
print(f"Endpoint: {cluster.endpoint}")
print(f"Version: {cluster.version}")
print(f"Nodes: {cluster.node_count}")

# List all clusters
clusters = provider.list_clusters("us-west-2")
for cluster in clusters:
    print(f"- {cluster.name}: {cluster.status}")

# Delete cluster
provider.delete_cluster("production-cluster", "us-west-2")
```

### RDS Database Management

```python
from src.interfaces.provider import DatabaseConfig

# Create database
config = DatabaseConfig(
    name="production-db",
    engine="postgres",
    engine_version="14.7",
    instance_class="db.t3.medium",
    region="us-west-2",
    allocated_storage=100,
    master_username="admin",
    master_password="SuperSecretPassword123!",
    multi_az=True,
    backup_retention_days=7,
    tags={"Environment": "production"}
)

database = provider.create_database(config)
print(f"Database {database.name} status: {database.status}")

# Get database details
database = provider.get_database("production-db", "us-west-2")
print(f"Endpoint: {database.endpoint}:{database.port}")
print(f"Engine: {database.engine} {database.engine_version}")

# List all databases
databases = provider.list_databases("us-west-2")
for db in databases:
    print(f"- {db.name}: {db.status}")

# Delete database
provider.delete_database("production-db", "us-west-2", skip_final_snapshot=False)
```

### S3 Storage Management

```python
from src.interfaces.provider import StorageConfig

# Create bucket with advanced configuration
config = StorageConfig(
    name="my-data-lake",
    region="us-west-2",
    versioning_enabled=True,
    encryption_enabled=True,
    public_access_blocked=True,
    lifecycle_rules=[
        {
            "Id": "archive-old-data",
            "Status": "Enabled",
            "Transitions": [
                {"Days": 90, "StorageClass": "GLACIER"}
            ]
        }
    ],
    tags={"Project": "data-platform", "CostCenter": "engineering"}
)

bucket = provider.create_storage(config)
print(f"Created bucket: {bucket.name}")

# Get bucket details
bucket = provider.get_storage("my-data-lake", "us-west-2")
print(f"Size: {bucket.size_bytes / (1024**3):.2f} GB")
print(f"Objects: {bucket.object_count}")
print(f"Versioning: {bucket.versioning_enabled}")

# List all buckets
buckets = provider.list_storage()
for bucket in buckets:
    print(f"- {bucket.name} ({bucket.region})")

# Delete bucket (with force to delete contents)
provider.delete_storage("my-data-lake", "us-west-2", force=True)
```

### Cost Monitoring

```python
# Get cost data for last 30 days
cost_data = provider.get_cost_data("LAST_30_DAYS", "DAILY")
print(f"Period: {cost_data.start_date} to {cost_data.end_date}")
print(f"Total cost: ${cost_data.total_cost:.2f} {cost_data.currency}")

# Print cost breakdown by service
print("\nCost by service:")
for service, cost in sorted(cost_data.breakdown.items(), key=lambda x: x[1], reverse=True):
    percentage = (cost / cost_data.total_cost) * 100
    print(f"  {service:30s}: ${cost:10.2f} ({percentage:5.1f}%)")

# Get cost forecast
forecast = provider.get_cost_forecast(days=30)
print(f"\n30-day forecast: ${forecast['forecast_amount']:.2f}")
```

### CloudWatch Metrics

```python
from datetime import datetime, timedelta

# Get metrics for a specific resource
end_time = datetime.utcnow()
start_time = end_time - timedelta(hours=24)

metrics = provider.get_metrics(
    resource_id="i-1234567890abcdef0",
    metric_name="CPUUtilization",
    start_time=start_time.isoformat() + "Z",
    end_time=end_time.isoformat() + "Z",
    namespace="AWS/EC2",
    dimensions=[{"Name": "InstanceId", "Value": "i-1234567890abcdef0"}],
    region="us-west-2"
)

print(f"Metric: {metrics['metric_name']}")
print(f"Datapoints: {len(metrics['datapoints'])}")
for dp in metrics['datapoints'][:5]:
    print(f"  {dp['Timestamp']}: {dp.get('Average', 0):.2f}")
```

### Azure Usage Examples

#### AKS Cluster Management

```python
from src.interfaces.provider import ClusterConfig

# Create AKS cluster
config = ClusterConfig(
    name="production-cluster",
    region="eastus",
    version="1.28",
    node_count=3,
    node_instance_type="Standard_DS2_v2",
    metadata={
        "resource_group": "my-resource-group",
        "dns_prefix": "production-cluster-dns",
        "identity": {"type": "SystemAssigned"},
        "network_plugin": "kubenet",
        "enable_rbac": True,
    },
    tags={"Environment": "production"}
)

cluster = provider.create_cluster(config)
print(f"Cluster {cluster.name} status: {cluster.status}")

# Get cluster details
cluster = provider.get_cluster("production-cluster", resource_group="my-resource-group")
print(f"Endpoint: {cluster.endpoint}")
print(f"Version: {cluster.version}")
print(f"Nodes: {cluster.node_count}")

# List all clusters in resource group
clusters = provider.list_clusters(resource_group="my-resource-group")
for cluster in clusters:
    print(f"- {cluster.name}: {cluster.status}")

# Delete cluster
provider.delete_cluster("production-cluster", resource_group="my-resource-group")
```

#### Azure Database Management

```python
from src.interfaces.provider import DatabaseConfig

# Create PostgreSQL database
config = DatabaseConfig(
    name="production-db",
    engine="postgres",
    engine_version="14",
    instance_class="GP_Gen5_2",
    region="eastus",
    allocated_storage=100,
    master_username="adminuser",
    master_password="SuperSecretPassword123!",
    metadata={
        "resource_group": "my-resource-group",
        "sku_tier": "GeneralPurpose",
        "sku_family": "Gen5",
        "sku_capacity": 2,
        "backup_retention_days": 7,
        "geo_redundant_backup": False,
        "ssl_enforcement": True,
    },
    tags={"Environment": "production"}
)

database = provider.create_database(config)
print(f"Database {database.name} status: {database.status}")

# Get database details
database = provider.get_database("production-db", resource_group="my-resource-group")
print(f"Endpoint: {database.endpoint}:{database.port}")
print(f"Engine: {database.engine} {database.engine_version}")

# List all databases
databases = provider.list_databases(resource_group="my-resource-group")
for db in databases:
    print(f"- {db.name}: {db.status}")

# Delete database
provider.delete_database("production-db", resource_group="my-resource-group")
```

#### Azure Storage Management

```python
from src.interfaces.provider import StorageConfig

# Create storage account with blob container
config = StorageConfig(
    name="mydatalake2024",  # Must be globally unique, lowercase, no hyphens
    region="eastus",
    versioning_enabled=False,
    encryption_enabled=True,
    public_access_blocked=True,
    metadata={
        "resource_group": "my-resource-group",
        "sku": "Standard_LRS",
        "kind": "StorageV2",
        "container_name": "data",  # Optional: creates a blob container
    },
    tags={"Project": "data-platform", "CostCenter": "engineering"}
)

storage = provider.create_storage(config)
print(f"Created storage account: {storage.name}")

# Get storage account details
storage = provider.get_storage("mydatalake2024", resource_group="my-resource-group")
print(f"Region: {storage.region}")
print(f"Encryption: {storage.encryption_enabled}")

# List all storage accounts
storage_accounts = provider.list_storage(resource_group="my-resource-group")
for account in storage_accounts:
    print(f"- {account.name} ({account.region})")

# Delete storage account
provider.delete_storage("mydatalake2024", resource_group="my-resource-group", force=True)
```

#### Azure Cost Monitoring

```python
# Get cost data for last 30 days
cost_data = provider.get_cost_data("LAST_30_DAYS", "DAILY")
print(f"Period: {cost_data.start_date} to {cost_data.end_date}")
print(f"Total cost: ${cost_data.total_cost:.2f} {cost_data.currency}")

# Print cost breakdown by service
print("\nCost by service:")
for service, cost in sorted(cost_data.breakdown.items(), key=lambda x: x[1], reverse=True):
    percentage = (cost / cost_data.total_cost) * 100
    print(f"  {service:30s}: ${cost:10.2f} ({percentage:5.1f}%)")

# Get cost forecast
forecast = provider.get_cost_forecast(days=30)
print(f"\n30-day forecast: ${forecast['forecast_amount']:.2f}")
```

#### Azure Monitor Metrics

```python
from datetime import datetime, timedelta

# Get metrics for a specific resource
end_time = datetime.utcnow()
start_time = end_time - timedelta(hours=24)

# Full Azure resource ID required
resource_id = "/subscriptions/{subscription_id}/resourceGroups/{rg}/providers/Microsoft.Compute/virtualMachines/{vm_name}"

metrics = provider.get_metrics(
    resource_id=resource_id,
    metric_name="Percentage CPU",
    start_time=start_time.isoformat() + "Z",
    end_time=end_time.isoformat() + "Z",
    aggregation="Average"
)

print(f"Metric: {metrics['metric_name']}")
print(f"Datapoints: {len(metrics['datapoints'])}")
for dp in metrics['datapoints'][:5]:
    print(f"  {dp['timestamp']}: {dp['average']:.2f}%")
```

## Error Handling

The library provides specific exception types for different error scenarios:

```python
from src.exceptions import (
    CloudProviderError,
    AuthenticationError,
    ResourceNotFoundError,
    ResourceAlreadyExistsError,
    QuotaExceededError,
    RateLimitError,
    ValidationError,
)

try:
    bucket = provider.get_storage("non-existent-bucket", "us-west-2")
except ResourceNotFoundError as e:
    print(f"Bucket not found: {e}")
except AuthenticationError as e:
    print(f"Authentication failed: {e}")
except RateLimitError as e:
    print(f"Rate limit exceeded: {e}")
except CloudProviderError as e:
    print(f"Cloud provider error: {e}")
```

## Rate Limiting

The provider includes built-in rate limiting to prevent API throttling:

```python
# Customize rate limiting
provider = AWSProvider(
    region="us-west-2",
    rate_limit_calls=20,  # Max 20 calls
    rate_limit_window=1.0  # Per 1 second
)
```

## Configuration

### Environment Variables

- `AWS_ACCESS_KEY_ID`: AWS access key ID
- `AWS_SECRET_ACCESS_KEY`: AWS secret access key
- `AWS_SESSION_TOKEN`: AWS session token (for temporary credentials)
- `AWS_DEFAULT_REGION`: Default AWS region
- `AWS_PROFILE`: AWS profile name

### Logging

Configure logging to see detailed API calls:

```python
import logging

logging.basicConfig(
    level=logging.DEBUG,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)

# Now all AWS API calls will be logged
provider = AWSProvider(region="us-west-2")
```

## Testing

### Unit Tests

Run unit tests with moto (AWS mocking):

```bash
pytest tests/unit -v --cov=src
```

### Integration Tests

Integration tests run against real AWS services and require valid credentials:

```bash
# Set credentials
export AWS_ACCESS_KEY_ID=your_key
export AWS_SECRET_ACCESS_KEY=your_secret
export AWS_TEST_REGION=us-west-2

# Run integration tests
pytest tests/integration -v
```

To skip integration tests:

```bash
export SKIP_INTEGRATION_TESTS=1
pytest tests/integration -v
```

### Coverage

Generate coverage report:

```bash
pytest --cov=src --cov-report=html
open htmlcov/index.html
```

## Architecture

### Project Structure

```
services/cloud-provider/
├── src/
│   ├── __init__.py
│   ├── exceptions.py          # Custom exception classes
│   ├── utils.py                # Utility functions (retry, rate limiting)
│   ├── interfaces/             # Abstract interfaces
│   │   ├── __init__.py
│   │   ├── provider.py         # CloudProvider interface and configs
│   │   └── models.py           # Data models (Cluster, Database, etc.)
│   └── providers/              # Provider implementations
│       ├── __init__.py
│       ├── aws_provider.py     # Main AWS provider class
│       └── aws/                # AWS-specific implementations
│           ├── __init__.py
│           ├── eks.py          # EKS operations
│           ├── rds.py          # RDS operations
│           ├── s3.py           # S3 operations
│           ├── cloudwatch.py   # CloudWatch operations
│           └── cost_explorer.py # Cost Explorer operations
├── tests/
│   ├── unit/                   # Unit tests with mocking
│   └── integration/            # Integration tests (real AWS)
├── requirements.txt
├── requirements-dev.txt
├── pytest.ini
└── README.md
```

### Design Principles

1. **Abstraction**: Common interface across cloud providers
2. **Composition**: Provider composed of specialized service classes
3. **Retry Logic**: Automatic retry with exponential backoff
4. **Rate Limiting**: Token bucket algorithm to prevent throttling
5. **Type Safety**: Full type hints throughout
6. **Error Handling**: Specific exceptions for different error scenarios
7. **Logging**: Comprehensive logging at appropriate levels

## Security Best Practices

1. **Use IAM Roles**: Prefer IAM roles over access keys
2. **Least Privilege**: Grant minimum required permissions
3. **Rotate Credentials**: Regularly rotate access keys if used
4. **Encrypt Secrets**: Never hardcode credentials in code
5. **Enable MFA**: Use MFA for sensitive operations
6. **Audit Logging**: Enable CloudTrail for audit logging

### Required IAM Permissions

Minimum permissions for each service:

**EKS:**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "eks:CreateCluster",
        "eks:DescribeCluster",
        "eks:DeleteCluster",
        "eks:ListClusters",
        "eks:ListNodegroups",
        "eks:DescribeNodegroup"
      ],
      "Resource": "*"
    }
  ]
}
```

**RDS:**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "rds:CreateDBInstance",
        "rds:DescribeDBInstances",
        "rds:DeleteDBInstance",
        "rds:ListTagsForResource"
      ],
      "Resource": "*"
    }
  ]
}
```

**S3:**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:CreateBucket",
        "s3:GetBucketLocation",
        "s3:GetBucketVersioning",
        "s3:GetEncryptionConfiguration",
        "s3:ListBucket",
        "s3:ListAllMyBuckets",
        "s3:DeleteBucket",
        "s3:DeleteObject",
        "s3:DeleteObjectVersion",
        "s3:PutBucketVersioning",
        "s3:PutEncryptionConfiguration",
        "s3:PutBucketPublicAccessBlock",
        "s3:PutBucketTagging"
      ],
      "Resource": "*"
    }
  ]
}
```

**Cost Explorer & CloudWatch:**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ce:GetCostAndUsage",
        "ce:GetCostForecast",
        "cloudwatch:GetMetricStatistics",
        "cloudwatch:ListMetrics"
      ],
      "Resource": "*"
    }
  ]
}
```

## Troubleshooting

### Authentication Issues

```
AuthenticationError: No AWS credentials found
```

**Solution**: Configure credentials using one of the authentication methods above.

### Rate Limiting

```
RateLimitError: Rate limit timeout exceeded
```

**Solution**: Increase rate limit settings or implement backoff in your application.

### Resource Not Found

```
ResourceNotFoundError: Cluster my-cluster not found
```

**Solution**: Verify the resource exists and you have permission to access it.

## Contributing

1. Follow existing code style (Black formatting, type hints)
2. Add unit tests for new features
3. Update documentation
4. Run linters and tests before submitting

```bash
# Format code
black src tests

# Run linters
flake8 src tests
mypy src

# Run tests
pytest tests/unit -v
```

## License

See LICENSE file for details.

## Support

For issues and questions:
- GitHub Issues: https://github.com/paruff/fawkes/issues
- Documentation: See `docs/` directory
