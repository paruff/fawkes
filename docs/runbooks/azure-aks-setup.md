# Azure AKS Setup Guide for Fawkes

**Document Purpose**: Complete guide for deploying Fawkes platform on Azure Kubernetes Service (AKS)
**Target Audience**: DevOps engineers, Platform engineers, System administrators
**Estimated Time**: 2-3 hours for full deployment
**Last Updated**: December 2024

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Cost Considerations](#cost-considerations)
3. [Architecture Overview](#architecture-overview)
4. [Step-by-Step Deployment](#step-by-step-deployment)
5. [Access Management](#access-management)
6. [Scaling Considerations](#scaling-considerations)
7. [Backup and Disaster Recovery](#backup-and-disaster-recovery)
8. [Troubleshooting](#troubleshooting)
9. [Cost Optimization](#cost-optimization)
10. [Upgrade Procedures](#upgrade-procedures)

---

## Prerequisites

### Azure Subscription

- Active Azure subscription with sufficient quota
- Owner or Contributor role on the subscription
- Resource Provider registrations:
  - Microsoft.ContainerService
  - Microsoft.Storage
  - Microsoft.Network
  - Microsoft.KeyVault
  - Microsoft.OperationalInsights

### Required Tools

Install the following tools on your local machine:

```bash
# Azure CLI (version 2.50.0 or later)
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
az --version

# kubectl (Kubernetes CLI)
az aks install-cli

# Terraform (1.6.0 or later)
wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
unzip terraform_1.6.0_linux_amd64.zip
sudo mv terraform /usr/local/bin/
terraform --version

# jq (for JSON processing)
sudo apt-get install jq

# Helm (optional, for manual operations)
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

### Azure Permissions

Ensure you have the following permissions:

- Create and manage Resource Groups
- Create and manage AKS clusters
- Create and manage Virtual Networks
- Create and manage Azure Container Registry
- Create and manage Key Vaults
- Create and manage Storage Accounts
- Create and manage Log Analytics workspaces
- Assign Azure RBAC roles

---

## Cost Considerations

### Budget Planning

Expected monthly costs for the default configuration:

| Service | Configuration | Est. Monthly Cost |
|---------|--------------|-------------------|
| AKS Control Plane | Standard tier | $0 (Free) |
| System Node Pool | 2x Standard_D4s_v3 | $280 |
| User Node Pool | 2-10x Standard_D4s_v3 (avg 4) | $560 |
| Storage (OS Disks) | 6x 128GB Premium SSD | $118 |
| Container Registry | Standard tier | $20 |
| Load Balancer | Standard tier | $18 |
| Public IP | Static | $4 |
| Log Analytics | ~5GB/month | $14 |
| Key Vault | Standard | $1 |
| Storage Account | ~50GB LRS | $1 |
| Data Transfer | ~100GB | $8 |
| **Total** | | **~$1,024/month** |

### Cost Optimization Options

For development/testing environments, consider:

1. **Reduced VM sizes**: Use Standard_D2s_v3 (~$500/month savings)
2. **Fewer nodes**: Min 2, Max 5 for user pool (~$280/month savings)
3. **Basic ACR**: Use Basic tier (~$15/month savings)
4. **Spot instances**: Use Azure Spot VMs for non-critical workloads (up to 90% savings)
5. **Azure Reservations**: Commit to 1 or 3 years for significant savings

**Recommended budget**: $300-500/month for dev, $800-1500/month for production

Run the cost estimation script:
```bash
./scripts/azure-cost-estimate.sh
```

---

## Architecture Overview

### Infrastructure Components

```
┌─────────────────────────────────────────────────────────────┐
│                     Azure Subscription                       │
│                                                               │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  Resource Group: fawkes-rg                            │  │
│  │                                                        │  │
│  │  ┌──────────────────────────────────────────────┐   │  │
│  │  │  Virtual Network: fawkes-aks-vnet             │   │  │
│  │  │  Address Space: 10.0.0.0/16                   │   │  │
│  │  │                                                 │   │  │
│  │  │  ┌────────────────────────────────────────┐  │   │  │
│  │  │  │  AKS Subnet: 10.0.1.0/24                │  │   │  │
│  │  │  │                                          │  │   │  │
│  │  │  │  ┌──────────────────────────────────┐  │  │   │  │
│  │  │  │  │  AKS Cluster: fawkes-aks          │  │  │   │  │
│  │  │  │  │  - Control Plane (Managed)        │  │  │   │  │
│  │  │  │  │  - System Pool: 2 nodes           │  │  │   │  │
│  │  │  │  │  - User Pool: 2-10 nodes (auto)   │  │  │   │  │
│  │  │  │  │  - Azure CNI networking           │  │  │   │  │
│  │  │  │  │  - Managed Identity               │  │  │   │  │
│  │  │  │  └──────────────────────────────────┘  │  │   │  │
│  │  │  └────────────────────────────────────────┘  │   │  │
│  │  └──────────────────────────────────────────────┘   │  │
│  │                                                        │  │
│  │  ┌──────────────────────────────────────────────┐   │  │
│  │  │  Azure Container Registry (ACR)               │   │  │
│  │  │  fawkesacr.azurecr.io                         │   │  │
│  │  └──────────────────────────────────────────────┘   │  │
│  │                                                        │  │
│  │  ┌──────────────────────────────────────────────┐   │  │
│  │  │  Azure Key Vault                              │   │  │
│  │  │  fawkes-kv                                    │   │  │
│  │  └──────────────────────────────────────────────┘   │  │
│  │                                                        │  │
│  │  ┌──────────────────────────────────────────────┐   │  │
│  │  │  Storage Account (Terraform State)            │   │  │
│  │  │  fawkestfstate                                │   │  │
│  │  └──────────────────────────────────────────────┘   │  │
│  │                                                        │  │
│  │  ┌──────────────────────────────────────────────┐   │  │
│  │  │  Log Analytics Workspace                      │   │  │
│  │  │  fawkes-aks-logs                              │   │  │
│  │  └──────────────────────────────────────────────┘   │  │
│  │                                                        │  │
│  │  ┌──────────────────────────────────────────────┐   │  │
│  │  │  Azure Load Balancer + Public IP              │   │  │
│  │  └──────────────────────────────────────────────┘   │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

### Network Architecture

- **VNet CIDR**: 10.0.0.0/16
- **AKS Subnet**: 10.0.1.0/24 (for nodes)
- **Service CIDR**: 10.1.0.0/16 (for Kubernetes services)
- **DNS Service IP**: 10.1.0.10
- **Network Plugin**: Azure CNI (Container Networking Interface)
- **Network Policy**: Azure Network Policy

### Node Pool Strategy

**System Node Pool**:
- Purpose: Critical system components (kube-system, ArgoCD, monitoring)
- VM Size: Standard_D4s_v3 (4 vCPU, 16 GB RAM)
- Node Count: 2 (fixed, no auto-scaling)
- OS Disk: 128 GB Premium SSD

**User Node Pool**:
- Purpose: Application workloads (Backstage, Jenkins, Focalboard, etc.)
- VM Size: Standard_D4s_v3 (4 vCPU, 16 GB RAM)
- Node Count: 2-10 (auto-scaling enabled)
- OS Disk: 128 GB Premium SSD

---

## Step-by-Step Deployment

### Phase 1: Azure Authentication

```bash
# Login to Azure
az login

# Set your subscription
az account set --subscription "YOUR_SUBSCRIPTION_ID"

# Verify current subscription
az account show --output table

# Register required resource providers
az provider register --namespace Microsoft.ContainerService
az provider register --namespace Microsoft.Storage
az provider register --namespace Microsoft.Network
az provider register --namespace Microsoft.KeyVault
az provider register --namespace Microsoft.OperationalInsights
```

### Phase 2: Customize Configuration

```bash
# Navigate to infrastructure directory
cd infra/azure

# Copy example configuration
cp terraform.tfvars.example terraform.tfvars

# Edit configuration (update globally unique names)
nano terraform.tfvars
```

**Important**: Update these values to be globally unique:
- `acr_name`: Must be globally unique (lowercase alphanumeric only)
- `key_vault_name`: Must be globally unique (alphanumeric and hyphens)
- `storage_account_name`: Must be globally unique (lowercase alphanumeric only)

Example customization:
```hcl
acr_name             = "fawkesacr20241213"
key_vault_name       = "fawkes-kv-20241213"
storage_account_name = "fawkestfstate20241213"
```

**Production Security Settings**:

For production environments, update these security-critical settings:

```hcl
environment = "prod"

# Key Vault security (production-ready)
key_vault_soft_delete_retention_days    = 90      # Longer retention for recovery
key_vault_purge_protection_enabled      = true    # Prevent permanent deletion
key_vault_network_acls_default_action   = "Deny"  # Restrict network access

# Then configure allowed IP ranges or VNets in main.tf:
# network_acls {
#   ip_rules = ["YOUR_OFFICE_IP/32", "YOUR_CI_IP/32"]
#   virtual_network_subnet_ids = [azurerm_subnet.aks_subnet.id]
# }
```

**Note**: The default configuration is optimized for development/testing. Production environments should enable additional security controls as shown above.

### Phase 3: Initialize Terraform

```bash
# Initialize Terraform
terraform init

# Validate configuration
terraform validate

# Review planned changes
terraform plan -out=tfplan
```

### Phase 4: Deploy Infrastructure

```bash
# Apply Terraform configuration
terraform apply tfplan

# This will create:
# - Resource Group
# - Virtual Network and Subnet
# - AKS Cluster with system and user node pools
# - Azure Container Registry
# - Azure Key Vault
# - Storage Account
# - Log Analytics Workspace
# - All necessary IAM role assignments

# Deployment typically takes 10-15 minutes
```

### Phase 5: Configure kubectl

```bash
# Get AKS credentials
az aks get-credentials \
  --resource-group fawkes-rg \
  --name fawkes-aks \
  --overwrite-existing

# Verify cluster access
kubectl cluster-info

# Check nodes
kubectl get nodes

# Expected output: 4 nodes (2 system + 2 user)
# NAME                                STATUS   ROLE    AGE   VERSION
# aks-system-12345678-vmss000000     Ready    agent   5m    v1.28.x
# aks-system-12345678-vmss000001     Ready    agent   5m    v1.28.x
# aks-user-12345678-vmss000000       Ready    agent   4m    v1.28.x
# aks-user-12345678-vmss000001       Ready    agent   4m    v1.28.x

# Check system pods
kubectl get pods -A

# Verify all system pods are running
```

### Phase 6: Verify Azure Integrations

```bash
# Verify ACR integration
az aks check-acr \
  --resource-group fawkes-rg \
  --name fawkes-aks \
  --acr fawkesacr.azurecr.io

# Verify Azure Monitor integration
az aks show \
  --resource-group fawkes-rg \
  --name fawkes-aks \
  --query "addonProfiles.omsagent.enabled"

# Should return: true

# View cluster details
az aks show \
  --resource-group fawkes-rg \
  --name fawkes-aks \
  --output table
```

### Phase 7: Deploy Fawkes Platform

```bash
# Navigate back to repository root
cd ../..

# Deploy Fawkes platform components via ignite script
./scripts/ignite.sh --provider azure --skip-cluster dev

# This will:
# - Deploy ArgoCD
# - Deploy platform applications
# - Configure GitOps sync
```

---

## Access Management

### Azure RBAC

The cluster is configured with Azure RBAC for Kubernetes authorization:

```bash
# Grant user AKS admin role
az role assignment create \
  --assignee user@example.com \
  --role "Azure Kubernetes Service RBAC Cluster Admin" \
  --scope $(az aks show -g fawkes-rg -n fawkes-aks --query id -o tsv)

# Grant user AKS reader role
az role assignment create \
  --assignee user@example.com \
  --role "Azure Kubernetes Service RBAC Reader" \
  --scope $(az aks show -g fawkes-rg -n fawkes-aks --query id -o tsv)
```

### Container Registry Access

```bash
# Login to ACR
az acr login --name fawkesacr

# Grant push permissions to CI/CD service principal
az role assignment create \
  --assignee <service-principal-id> \
  --role AcrPush \
  --scope $(az acr show -n fawkesacr --query id -o tsv)
```

### Key Vault Access

```bash
# Grant user access to secrets
az keyvault set-policy \
  --name fawkes-kv \
  --upn user@example.com \
  --secret-permissions get list set delete
```

---

## Scaling Considerations

### Node Pool Auto-Scaling

The user node pool automatically scales between 2-10 nodes:

```bash
# Check current node count
kubectl get nodes -l nodepool-type=user

# View auto-scaler events
kubectl get events -A | grep cluster-autoscaler

# Manually adjust scaling limits
az aks nodepool update \
  --resource-group fawkes-rg \
  --cluster-name fawkes-aks \
  --name user \
  --min-count 3 \
  --max-count 8
```

### Horizontal Pod Autoscaling

Configure HPA for your applications:

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: app-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: my-app
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
```

### Vertical Pod Autoscaling

Enable VPA addon:

```bash
# Install VPA
kubectl apply -f https://github.com/kubernetes/autoscaler/releases/download/vertical-pod-autoscaler-0.13.0/vpa-v0.13.0.yaml
```

---

## Backup and Disaster Recovery

### Cluster Backups

Use Azure Backup for AKS:

```bash
# Enable backup extension
az aks enable-addons \
  --resource-group fawkes-rg \
  --name fawkes-aks \
  --addons azure-backup

# Configure backup policy (via Azure Portal or ARM template)
```

### Persistent Volume Backups

Azure automatically creates volume snapshots. Configure retention:

```yaml
apiVersion: snapshot.storage.k8s.io/v1
kind: VolumeSnapshotClass
metadata:
  name: default-snapshot-class
driver: disk.csi.azure.com
deletionPolicy: Retain
```

### GitOps State Recovery

All platform configuration is in Git:

```bash
# Full platform recovery
git clone https://github.com/paruff/fawkes.git
cd fawkes
./scripts/ignite.sh --provider azure dev
```

### Disaster Recovery Plan

1. **Infrastructure**: Terraform state in Azure Storage (with versioning)
2. **Applications**: ArgoCD syncs from Git (declarative)
3. **Data**: Regular volume snapshots + external database backups
4. **Secrets**: Azure Key Vault (with soft delete enabled)

**RTO**: 2-4 hours (new cluster + ArgoCD sync)
**RPO**: 1 hour (snapshot frequency)

---

## Troubleshooting

### Common Issues

#### Issue: Terraform fails with "name not available"

**Symptom**: ACR, Key Vault, or Storage Account name already taken

**Solution**: Update names in `terraform.tfvars` to be globally unique:
```bash
acr_name             = "fawkesacr$(date +%s)"
key_vault_name       = "fawkes-kv-$(date +%s)"
storage_account_name = "tfstate$(date +%s)"
```

#### Issue: Nodes not joining cluster

**Symptom**: `kubectl get nodes` shows NotReady or missing nodes

**Solution**:
```bash
# Check node pool status
az aks nodepool list \
  --resource-group fawkes-rg \
  --cluster-name fawkes-aks \
  --output table

# Check Azure activity logs
az monitor activity-log list \
  --resource-group fawkes-rg \
  --offset 1h

# Restart node pool
az aks nodepool stop \
  --resource-group fawkes-rg \
  --cluster-name fawkes-aks \
  --name user

az aks nodepool start \
  --resource-group fawkes-rg \
  --cluster-name fawkes-aks \
  --name user
```

#### Issue: Cannot pull images from ACR

**Symptom**: Pods stuck in ImagePullBackOff

**Solution**:
```bash
# Verify ACR integration
az aks check-acr \
  --resource-group fawkes-rg \
  --name fawkes-aks \
  --acr fawkesacr.azurecr.io

# Re-attach ACR if needed
az aks update \
  --resource-group fawkes-rg \
  --name fawkes-aks \
  --attach-acr fawkesacr
```

#### Issue: High costs

**Symptom**: Azure bill exceeds budget

**Solution**:
```bash
# Check current costs
az cost-management query \
  --type Usage \
  --dataset-filter "{\"and\":[{\"dimensions\":{\"name\":\"ResourceGroup\",\"operator\":\"In\",\"values\":[\"fawkes-rg\"]}}]}" \
  --timeframe MonthToDate

# Scale down user pool
az aks nodepool scale \
  --resource-group fawkes-rg \
  --cluster-name fawkes-aks \
  --name user \
  --node-count 2

# Run cost estimation
./scripts/azure-cost-estimate.sh
```

#### Issue: Pods evicted due to disk pressure

**Symptom**: Pods restarting, kubelet reporting disk pressure

**Solution**:
```bash
# Check disk usage on nodes
kubectl get nodes -o custom-columns=NAME:.metadata.name,DISK:.status.allocatable.ephemeral-storage

# Clean up unused images
kubectl debug node/aks-user-12345678-vmss000000 -it --image=alpine
# In debug pod:
# crictl rmi --prune

# Increase OS disk size (requires recreation)
# Update terraform.tfvars and re-apply
```

### Diagnostic Commands

```bash
# View cluster health
az aks show \
  --resource-group fawkes-rg \
  --name fawkes-aks \
  --query "{provisioningState:provisioningState,powerState:powerState.code}"

# View node pool health
az aks nodepool show \
  --resource-group fawkes-rg \
  --cluster-name fawkes-aks \
  --name user \
  --query "{provisioningState:provisioningState,powerState:powerState.code}"

# Check Azure Monitor logs
az monitor log-analytics query \
  --workspace <workspace-id> \
  --analytics-query "ContainerLog | where TimeGenerated > ago(1h) | limit 100"

# Get kubectl diagnostics
kubectl get events -A --sort-by='.lastTimestamp'
kubectl top nodes
kubectl top pods -A
```

---

## Cost Optimization

### Development Environment Optimizations

```hcl
# terraform.tfvars for dev environment
system_node_pool_vm_size = "Standard_D2s_v3"
system_node_pool_count   = 1

user_node_pool_vm_size   = "Standard_D2s_v3"
user_node_pool_min_count = 1
user_node_pool_max_count = 3

acr_sku = "Basic"
log_retention_days = 7
```

Estimated savings: ~$550/month

### Auto-Shutdown for Dev Clusters

```bash
# Stop cluster (nodes only, control plane remains)
az aks stop \
  --resource-group fawkes-rg \
  --name fawkes-aks

# Start cluster
az aks start \
  --resource-group fawkes-rg \
  --name fawkes-aks

# Schedule with cron or Azure Automation
```

### Use Azure Spot Instances

Add a spot node pool for batch workloads:

```bash
az aks nodepool add \
  --resource-group fawkes-rg \
  --cluster-name fawkes-aks \
  --name spot \
  --priority Spot \
  --eviction-policy Delete \
  --spot-max-price -1 \
  --enable-cluster-autoscaler \
  --min-count 0 \
  --max-count 5 \
  --node-vm-size Standard_D4s_v3 \
  --node-taints kubernetes.azure.com/scalesetpriority=spot:NoSchedule \
  --labels kubernetes.azure.com/scalesetpriority=spot
```

Schedule workloads on spot nodes:

```yaml
spec:
  tolerations:
  - key: "kubernetes.azure.com/scalesetpriority"
    operator: "Equal"
    value: "spot"
    effect: "NoSchedule"
  nodeSelector:
    kubernetes.azure.com/scalesetpriority: spot
```

### Reserved Instances

Purchase reserved instances for predictable workloads:

```bash
# View reservation options
az reservations catalog show \
  --subscription-id <subscription-id> \
  --reserved-resource-type VirtualMachines \
  --location eastus
```

Expected savings: 38% (1-year) or 62% (3-year)

---

## Upgrade Procedures

### Kubernetes Version Upgrade

```bash
# Check available versions
az aks get-upgrades \
  --resource-group fawkes-rg \
  --name fawkes-aks \
  --output table

# Upgrade control plane
az aks upgrade \
  --resource-group fawkes-rg \
  --name fawkes-aks \
  --kubernetes-version 1.29.0

# Upgrade node pools
az aks nodepool upgrade \
  --resource-group fawkes-rg \
  --cluster-name fawkes-aks \
  --name system \
  --kubernetes-version 1.29.0

az aks nodepool upgrade \
  --resource-group fawkes-rg \
  --cluster-name fawkes-aks \
  --name user \
  --kubernetes-version 1.29.0
```

### Terraform State Upgrade

```bash
# Backup state
az storage blob download \
  --account-name fawkestfstate \
  --container-name tfstate \
  --name terraform.tfstate \
  --file terraform.tfstate.backup

# Update Terraform
terraform init -upgrade

# Apply changes
terraform plan
terraform apply
```

### Rolling Node Upgrades

```bash
# Cordon and drain nodes one at a time
kubectl cordon aks-user-12345678-vmss000000
kubectl drain aks-user-12345678-vmss000000 --ignore-daemonsets --delete-emptydir-data

# Upgrade via Azure
az aks nodepool upgrade \
  --resource-group fawkes-rg \
  --cluster-name fawkes-aks \
  --name user \
  --node-image-only

# Uncordon when complete
kubectl uncordon aks-user-12345678-vmss000000
```

---

## Additional Resources

- [Azure AKS Documentation](https://learn.microsoft.com/en-us/azure/aks/)
- [Fawkes Architecture](../architecture.md)
- [Fawkes AWS Deployment Guide](../AWS_deployment_guide.md)
- [Azure Pricing Calculator](https://azure.microsoft.com/en-us/pricing/calculator/)
- [Terraform AzureRM Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)

---

## Support

For issues or questions:

1. Check this documentation and troubleshooting section
2. Review [Fawkes Troubleshooting Guide](../troubleshooting.md)
3. Search existing [GitHub Issues](https://github.com/paruff/fawkes/issues)
4. Open a new issue with the `comp-azure` label

---

**Document Version**: 1.0
**Last Review**: December 2024
**Next Review**: March 2025
