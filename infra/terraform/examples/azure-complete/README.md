# Complete Azure Infrastructure Example using Fawkes Terraform Modules

This example demonstrates how to use all the Fawkes Terraform modules together to create a complete Azure infrastructure with AKS and ArgoCD.

## Architecture

```
Azure Subscription
└── Resource Group (fawkes-rg)
    ├── Virtual Network (fawkes-vnet: 10.0.0.0/16)
    │   └── Subnet (aks-subnet: 10.0.1.0/24)
    └── AKS Cluster (fawkes-aks)
        └── ArgoCD (deployed via Helm)
```

## Prerequisites

- Azure CLI installed and authenticated
- Terraform >= 1.6.0
- kubectl installed
- Valid Azure subscription

## Directory Structure

```
examples/azure-complete/
├── main.tf              # Main configuration
├── variables.tf         # Input variables
├── outputs.tf           # Output values
├── providers.tf         # Provider configuration
├── terraform.tfvars.example
└── README.md
```

## Usage

### Step 1: Configure Variables

Copy the example file and fill in your values:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars`:

```hcl
subscription_id = "00000000-0000-0000-0000-000000000000"
tenant_id       = "00000000-0000-0000-0000-000000000000"
location        = "eastus2"
environment     = "dev"

# Your public IP for API server access
api_server_authorized_ip_ranges = ["203.0.113.0/24"]
```

### Step 2: Initialize Terraform

```bash
terraform init
```

### Step 3: Plan the Deployment

```bash
terraform plan -out=tfplan
```

Review the plan to ensure all resources will be created as expected.

### Step 4: Apply the Configuration

```bash
terraform apply tfplan
```

This will create:
- Azure Resource Group
- Virtual Network with subnet
- AKS cluster with 3 nodes
- ArgoCD deployed to the cluster

### Step 5: Access AKS Cluster

```bash
# Get AKS credentials
az aks get-credentials \
  --resource-group $(terraform output -raw resource_group_name) \
  --name $(terraform output -raw cluster_name)

# Verify cluster access
kubectl get nodes
```

### Step 6: Access ArgoCD

```bash
# Port forward to ArgoCD server
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Get admin password
terraform output -raw argocd_admin_password

# Access ArgoCD UI at https://localhost:8080
# Username: admin
# Password: <output from above>
```

## Module Configuration

See `main.tf` for complete configuration of all modules.

## Cost Optimization

For development environments:

- Use `Standard_B2ms` or `Standard_B2s` for node pools (cheaper)
- Reduce node count to 1-2 nodes for testing
- Stop AKS cluster during off-hours: `az aks stop`

## Cleanup

To destroy all resources:

```bash
terraform destroy
```

## Additional Resources

- [Fawkes Architecture Documentation](../../../../docs/architecture.md)
- [Azure AKS Documentation](https://learn.microsoft.com/en-us/azure/aks/)
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
