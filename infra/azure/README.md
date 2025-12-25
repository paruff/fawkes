# Azure AKS Infrastructure for Fawkes

This directory contains Terraform configuration for provisioning a cost-optimized Azure Kubernetes Service (AKS) cluster for the Fawkes Internal Product Delivery Platform.

## Overview

The infrastructure is designed with the following principles:
- **Cost Optimization**: Uses Spot instances, burstable VMs, and auto-scaling
- **Security**: Private cluster with no public API endpoint exposure
- **GitOps**: All configuration stored in Git, managed by Terraform
- **Cloud Native**: Azure CNI networking with network policies

## Prerequisites

1. **Azure CLI** installed and authenticated
   ```bash
   az login
   az account set --subscription <subscription-id>
   ```

2. **Terraform** >= 1.6.0 installed
   ```bash
   terraform version
   ```

3. **Azure Service Principal or Managed Identity** with appropriate permissions
   - Contributor role on the subscription or resource group
   - Required for Terraform to provision resources

## Quick Start

### 1. Configure Variables

Copy the example configuration and customize it:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` and set your specific values:
- Azure subscription and tenant IDs (or use Azure CLI context)
- Region (default: `eastus2` for cost optimization)
- Cluster name and resource group
- Node pool sizes and autoscaling limits

### 2. Initialize Terraform

```bash
terraform init
```

This will download the required providers and set up the backend.

### 3. Review the Plan

```bash
terraform plan -out=tfplan
```

Review the output to ensure all resources are configured correctly:
- ✅ Private cluster enabled
- ✅ Spot instances configured for user node pool
- ✅ Autoscaling with min=1, max=5 for dev
- ✅ No ACR or Key Vault resources (Harbor and Vault used instead)

### 4. Apply the Configuration

```bash
terraform apply tfplan
```

This will provision:
- Resource Group
- Virtual Network and Subnet
- AKS Cluster with system and user node pools
- Log Analytics workspace for monitoring
- Storage account for Terraform state

### 5. Get Cluster Credentials

```bash
az aks get-credentials --name fawkes-dev-aks --resource-group fawkes-dev-rg --overwrite-existing
```

### 6. Verify Cluster

```bash
kubectl get nodes
kubectl get pods --all-namespaces
```

## Architecture

### Network Configuration
- **VNet CIDR**: `10.0.0.0/16`
- **AKS Subnet**: `10.0.1.0/24`
- **Service CIDR**: `10.1.0.0/16`
- **DNS Service IP**: `10.1.0.10`
- **Network Plugin**: Azure CNI
- **Network Policy**: Azure Network Policy (or Calico)

### Node Pools

#### System Node Pool
- **Purpose**: Critical system workloads (CoreDNS, metrics-server, etc.)
- **VM Size**: `Standard_B2s` (burstable, cost-optimized)
- **Count**: 1 node (fixed)
- **Priority**: Regular (not Spot)

#### User Node Pool
- **Purpose**: Application workloads
- **VM Size**: `Standard_D2s_v3`
- **Autoscaling**: Enabled
  - **Min Count**: 1 node
  - **Max Count**: 5 nodes (strict limit for dev)
- **Priority**: Spot instances for cost savings
- **Eviction Policy**: Delete

### Security Features
- **Private Cluster**: API server not exposed to public internet
- **Managed Identity**: System-assigned managed identity for the cluster
- **RBAC**: Azure RBAC enabled
- **Network Policies**: Enabled for future Zero-trust enforcement

## Cost Optimization Features

### 1. Spot Instances
The user node pool uses Azure Spot VMs, which can save up to 90% compared to regular VMs:
- **Eviction Policy**: Delete (no charges when evicted)
- **Max Price**: -1 (capped at on-demand price)
- Suitable for dev/test workloads that can tolerate interruptions

### 2. Autoscaling
The cluster automatically scales based on resource requests:
- Scales down to 1 node during low usage
- Scales up to 5 nodes maximum during high usage
- Cluster Autoscaler evaluates every 10 seconds

### 3. Burstable VMs
System node pool uses `Standard_B2s` which provides:
- Low baseline CPU usage with burst capability
- Significant cost savings for workloads with variable CPU needs

### 4. Automated Shutdown (Manual Setup Required)

The cluster supports Azure AKS Start/Stop feature for additional cost savings during off-hours.

#### Manual Stop/Start Commands

Stop the cluster (no charges for compute, only storage):
```bash
az aks stop --name fawkes-dev-aks --resource-group fawkes-dev-rg
```

Start the cluster:
```bash
az aks start --name fawkes-dev-aks --resource-group fawkes-dev-rg
```

Check cluster state:
```bash
az aks show --name fawkes-dev-aks --resource-group fawkes-dev-rg --query "powerState"
```

#### Automated Shutdown Setup

For automated shutdown schedules, use one of these approaches:

**Option 1: Azure Automation Runbooks**
1. Create an Azure Automation Account
2. Create PowerShell runbooks to stop/start the cluster
3. Schedule runbooks to run at specific times (e.g., 8 PM stop, 8 AM start)
4. Example runbook script:
   ```powershell
   Connect-AzAccount -Identity
   Stop-AzAksCluster -Name "fawkes-dev-aks" -ResourceGroupName "fawkes-dev-rg"
   ```

**Option 2: GitHub Actions**
1. Create a GitHub Actions workflow with schedule triggers
2. Use Azure login action with service principal
3. Run `az aks stop/start` commands
4. Example workflow snippet:
   ```yaml
   on:
     schedule:
       - cron: '0 1 * * 1-5'  # 8 PM EST Mon-Fri (UTC 01:00)
   jobs:
     stop-cluster:
       runs-on: ubuntu-latest
       steps:
         - uses: azure/login@v1
           with:
             creds: ${{ secrets.AZURE_CREDENTIALS }}
         - run: az aks stop --name fawkes-dev-aks --resource-group fawkes-dev-rg
   ```

**Option 3: Azure Logic Apps**
1. Create a Logic App with a schedule trigger
2. Use Azure Resource Manager connector to stop/start AKS
3. Configure daily schedules for business hours

## Resource Tagging

All resources are tagged according to Fawkes standards:

```hcl
tags = {
  Project     = "Fawkes"
  Environment = "Dev"
  CostCenter  = "Platform"
  Schedule    = "BusinessHours"
  ManagedBy   = "Terraform"
  Owner       = "platform-team"
}
```

These tags enable:
- Cost tracking and allocation
- Automated policy enforcement
- Resource organization and filtering

## Harbor Integration (No ACR)

Fawkes uses a self-hosted Harbor instance instead of Azure Container Registry (ACR):

- Harbor provides vulnerability scanning, image signing, and replication
- No ACR resources are provisioned by this Terraform configuration
- Container images are pulled from Harbor registry
- Configure imagePullSecrets in Kubernetes for private registries

## Vault Integration (No Key Vault)

Fawkes uses HashiCorp Vault instead of Azure Key Vault:

- Vault provides centralized secret management
- No Azure Key Vault resources are provisioned by this Terraform configuration
- Use Vault Agent Injector or External Secrets Operator to inject secrets into pods

## Maintenance

### Updating Terraform Configuration

1. Make changes to `.tf` files
2. Format the code: `terraform fmt`
3. Validate the configuration: `terraform validate`
4. Review the plan: `terraform plan`
5. Apply the changes: `terraform apply`

### Upgrading Kubernetes Version

Update the `kubernetes_version` variable in `terraform.tfvars`:
```hcl
kubernetes_version = "1.29.0"  # Set to desired version
```

Then apply the change:
```bash
terraform plan
terraform apply
```

### Scaling Node Pools

To adjust autoscaling limits, update `terraform.tfvars`:
```hcl
user_node_pool_min_count = 2
user_node_pool_max_count = 10
```

## Troubleshooting

### Private Cluster Access Issues

Since the cluster is private, you need network connectivity to the VNet:
- Use Azure Bastion or VPN Gateway for access
- Or run `kubectl` commands from a VM within the VNet
- Or add authorized IP ranges (reduces security)

### Spot Instance Evictions

If Spot instances are evicted frequently:
1. Check Azure's Spot eviction rate for your region/SKU
2. Consider switching to Regular priority for user pool
3. Or increase the `spot_max_price` to be more competitive

### Autoscaler Not Scaling

Check autoscaler logs:
```bash
kubectl logs -n kube-system -l app=cluster-autoscaler
```

Common issues:
- Insufficient quota in subscription
- Pod resource requests not specified
- Node pool at maximum count

## Cost Estimation

Estimated monthly costs for dev environment (eastus2 region):

| Resource | Configuration | Estimated Cost |
|----------|--------------|----------------|
| System Node Pool | 1x Standard_B2s | ~$15/month |
| User Node Pool | 1-5x Standard_D2s_v3 Spot | ~$20-100/month |
| Log Analytics | 30-day retention | ~$5-20/month |
| Storage Account | LRS | ~$1-5/month |
| Network | VNet, Load Balancer | ~$10-20/month |
| **Total** | | **~$51-160/month** |

With automated shutdown (12 hours/day, 5 days/week):
- **Savings**: ~65% on compute costs
- **Estimated Total**: ~$30-80/month

*Note: Costs vary based on actual usage, data transfer, and spot instance availability.*

## Compliance and Security

### InSpec Validation

Run InSpec compliance tests:
```bash
cd inspec
inspec exec . -t azure:// \
  --input resource_group=fawkes-dev-rg \
  --input cluster_name=fawkes-dev-aks \
  --reporter cli json:../../reports/aks-inspec.json
```

### Security Best Practices

✅ Private cluster enabled (no public API endpoint)
✅ Network policies enabled for pod-to-pod segmentation
✅ Managed identity (no service principal credentials)
✅ Azure RBAC for Kubernetes authorization
✅ Log Analytics for audit logging and monitoring
✅ Regular VM images with automatic security patches

## References

- [Azure AKS Documentation](https://docs.microsoft.com/en-us/azure/aks/)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [AKS Cost Optimization](https://docs.microsoft.com/en-us/azure/aks/best-practices-cost)
- [AKS Start/Stop Feature](https://docs.microsoft.com/en-us/azure/aks/start-stop-cluster)
- [Azure Spot VMs](https://docs.microsoft.com/en-us/azure/virtual-machines/spot-vms)

## Support

For issues or questions:
1. Check the [troubleshooting section](#troubleshooting) above
2. Review [Fawkes documentation](../../docs/)
3. Open an issue on [GitHub](https://github.com/paruff/fawkes/issues)
4. Contact the platform team
