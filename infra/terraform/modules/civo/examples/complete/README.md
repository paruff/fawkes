# Complete Civo Infrastructure Example

This example demonstrates deploying a complete Civo infrastructure stack including:
- Network with firewall rules
- Kubernetes cluster with marketplace apps
- PostgreSQL database with backups
- S3-compatible object storage with CORS

## Prerequisites

1. Civo account and API token
2. Terraform >= 1.6.0
3. Civo CLI (optional, for verification)

## Usage

1. Set your Civo API token:
```bash
export TF_VAR_civo_token="your-civo-api-token"
```

2. Initialize Terraform:
```bash
terraform init
```

3. Review the plan:
```bash
terraform plan
```

4. Apply the configuration:
```bash
terraform apply
```

5. Get outputs:
```bash
terraform output
terraform output -json > outputs.json
```

## Customization

You can customize the deployment by modifying variables:

```bash
terraform apply \
  -var="project_name=myproject" \
  -var="region=LON1" \
  -var="cluster_size=large" \
  -var="environment=production"
```

## Accessing Resources

### Kubernetes Cluster

```bash
# Save kubeconfig
terraform output -raw kubeconfig > kubeconfig.yaml
export KUBECONFIG=./kubeconfig.yaml

# Verify access
kubectl get nodes
kubectl get pods -A
```

### Database

```bash
# Get connection details
terraform output database_host
terraform output -raw database_uri

# Connect with psql
PGPASSWORD=$(terraform output -raw database_password) \
  psql -h $(terraform output -raw database_host) \
       -U $(terraform output -raw database_username) \
       -d postgres
```

### Object Storage

```bash
# Get S3 configuration
terraform output -json s3_configuration

# Use with AWS CLI
aws s3 ls \
  --endpoint-url=$(terraform output -raw bucket_url) \
  --profile civo
```

## Cost Estimation

Approximate monthly costs for default configuration (medium cluster, small database):
- Kubernetes Cluster: ~$60-90
- Database: ~$20-30
- Object Storage: ~$5 (base) + usage
- Network: Free
- **Total: ~$85-125/month**

## Clean Up

```bash
terraform destroy
```

**Note:** Make sure to backup any data before destroying resources.

## Verification

Verify all resources are created:

```bash
# Using Civo CLI
civo network list
civo kubernetes list
civo database list
civo objectstore list

# Check resource status
civo kubernetes show $(terraform output -raw cluster_id)
civo database show $(terraform output -raw database_id)
```
