# Azure AKS Setup Validation Checklist (AT-E1-001)

This checklist validates that the Azure AKS setup meets all acceptance criteria for issue #1.

## Pre-Deployment Validation

### Prerequisites Check

- [ ] Azure CLI installed (`az --version`)
- [ ] Terraform installed (`terraform --version`)
- [ ] kubectl installed (`kubectl version --client`)
- [ ] Authenticated to Azure (`az account show`)
- [ ] Correct subscription selected

### Configuration Validation

- [ ] Copied `terraform.tfvars.example` to `terraform.tfvars`
- [ ] Updated resource names to be globally unique (ACR, Key Vault, Storage Account)
- [ ] Reviewed and adjusted VM sizes for budget
- [ ] Reviewed network CIDR ranges (no conflicts)
- [ ] Set appropriate environment value (dev/stage/prod)
- [ ] Configured Key Vault security settings for environment

### Terraform Validation

```bash
cd infra/azure
terraform init
terraform validate
terraform fmt -check
```

- [ ] Terraform init succeeds
- [ ] Terraform validate passes
- [ ] Terraform formatting is correct

## Deployment Validation

### Infrastructure Deployment

```bash
# Method 1: Using ignite.sh
./scripts/ignite.sh --provider azure --only-cluster dev

# Method 2: Direct Terraform
cd infra/azure
terraform plan -out=tfplan
terraform apply tfplan
```

- [ ] Deployment completes without errors (10-15 minutes)
- [ ] Resource Group created
- [ ] Virtual Network created with correct CIDR
- [ ] AKS cluster created
- [ ] System node pool created (2 nodes)
- [ ] User node pool created (2+ nodes with auto-scaling)
- [ ] Azure Container Registry created
- [ ] Azure Key Vault created
- [ ] Storage Account created
- [ ] Log Analytics workspace created

### Cluster Access

```bash
az aks get-credentials \
  --resource-group fawkes-rg \
  --name fawkes-aks \
  --overwrite-existing

kubectl cluster-info
kubectl get nodes
```

- [ ] kubectl credentials retrieved
- [ ] Cluster info displays correctly
- [ ] All nodes visible and in Ready state
- [ ] At least 4 nodes present (2 system + 2 user minimum)

## Acceptance Criteria Validation (AT-E1-001)

### 1. AKS cluster deployed in Azure

```bash
az aks show \
  --resource-group fawkes-rg \
  --name fawkes-aks \
  --output table
```

- [ ] Cluster exists
- [ ] Provisioning state is "Succeeded"
- [ ] Power state is "Running"

### 2. 3-5 nodes running and schedulable

```bash
kubectl get nodes
kubectl get nodes -o json | jq '.items | length'
```

- [ ] Total node count is 4+ (2 system + 2+ user)
- [ ] All nodes show STATUS=Ready
- [ ] Nodes are schedulable (not cordoned)

### 3. Azure CNI networking configured

```bash
az aks show \
  --resource-group fawkes-rg \
  --name fawkes-aks \
  --query "networkProfile.networkPlugin" \
  --output tsv
```

- [ ] Network plugin is "azure"
- [ ] Network policy is configured (azure or calico)
- [ ] Service CIDR is 10.1.0.0/16

### 4. System node pool and user node pool separated

```bash
kubectl get nodes --show-labels | grep nodepool-type
az aks nodepool list \
  --resource-group fawkes-rg \
  --cluster-name fawkes-aks \
  --output table
```

- [ ] System pool exists with mode=System
- [ ] User pool exists with mode=User
- [ ] Nodes have appropriate labels (nodepool-type)
- [ ] System pool has 2 nodes (fixed)
- [ ] User pool has auto-scaling enabled

### 5. kubectl configured and working

```bash
kubectl get pods -A
kubectl get services -A
kubectl cluster-info
```

- [ ] Can list all pods
- [ ] Can list all services
- [ ] API server is reachable
- [ ] System pods are Running

### 6. Cluster metrics available via Azure Monitor

```bash
az aks show \
  --resource-group fawkes-rg \
  --name fawkes-aks \
  --query "addonProfiles.omsagent.enabled" \
  --output tsv
```

- [ ] OMS agent addon is enabled
- [ ] Log Analytics workspace exists
- [ ] Container insights collecting data
- [ ] Can view metrics in Azure Portal

### 7. Azure AD integration configured

```bash
az aks show \
  --resource-group fawkes-rg \
  --name fawkes-aks \
  --query "aadProfile" \
  --output json
```

- [ ] AAD profile exists
- [ ] Managed AAD is enabled
- [ ] Azure RBAC is enabled
- [ ] RBAC is enabled on cluster

### 8. Cluster passes AT-E1-001

Run all validation checks - this is the comprehensive validation.

## Resource Integration Validation

### Azure Container Registry Integration

```bash
az aks check-acr \
  --resource-group fawkes-rg \
  --name fawkes-aks \
  --acr fawkesacr.azurecr.io

az role assignment list \
  --scope $(az acr show -n fawkesacr --query id -o tsv) \
  --output table
```

- [ ] ACR check passes
- [ ] AcrPull role assigned to AKS kubelet identity
- [ ] Can pull images from ACR

### Key Vault Integration

```bash
az keyvault show --name fawkes-kv --output table

az keyvault show --name fawkes-kv \
  --query "properties.enableSoftDelete" \
  --output tsv
```

- [ ] Key Vault exists
- [ ] Soft delete is enabled
- [ ] Access policies configured for deployer
- [ ] Access policies configured for AKS
- [ ] Network ACLs configured appropriately

### Storage Account

```bash
az storage account show \
  --name fawkestfstate \
  --resource-group fawkes-rg \
  --output table

az storage container list \
  --account-name fawkestfstate \
  --output table
```

- [ ] Storage account exists
- [ ] Container "tfstate" exists
- [ ] Replication type is correct (LRS/GRS)
- [ ] Terraform state is stored there

### Log Analytics

```bash
az monitor log-analytics workspace show \
  --resource-group fawkes-rg \
  --workspace-name fawkes-aks-logs \
  --output table
```

- [ ] Log Analytics workspace exists
- [ ] Retention period is configured
- [ ] Linked to AKS cluster
- [ ] Receiving container logs

## Compliance Testing

### InSpec Tests

```bash
# Install InSpec and Azure plugin if needed
# curl https://omnitruck.chef.io/install.sh | sudo bash -s -- -P inspec
# inspec plugin install inspec-azure

cd /path/to/fawkes
inspec exec infra/azure/inspec/ \
  -t azure:// \
  --input resource_group=fawkes-rg \
  --input cluster_name=fawkes-aks \
  --reporter cli json:reports/aks-inspec.json
```

Critical controls that must pass:

- [ ] aks-cluster-exists: Cluster exists and running
- [ ] aks-node-count: Minimum 2+ nodes
- [ ] aks-node-pool-separation: System and user pools separated
- [ ] aks-azure-cni: Azure CNI configured
- [ ] aks-managed-identity: Managed identity enabled
- [ ] aks-rbac-enabled: RBAC enabled
- [ ] k8s-nodes-ready: All nodes Ready
- [ ] k8s-system-pods-running: System pods Running

### BDD Tests

```bash
# From repository root
pytest tests/bdd/features/azure_aks_provisioning.feature -v

# Or run specific scenarios
pytest tests/bdd/features/azure_aks_provisioning.feature -k "AT-E1-001"
```

- [ ] All test scenarios pass
- [ ] No skipped tests (if authenticated)

## Cost Validation

### Cost Estimation

```bash
./scripts/azure-cost-estimate.sh
```

- [ ] Script completes successfully
- [ ] Cost breakdown displayed
- [ ] Total cost within budget expectations
- [ ] Optimization suggestions reviewed (if over budget)

### Actual Cost Check

```bash
az consumption usage list \
  --start-date $(date -d '1 day ago' +%Y-%m-%d) \
  --end-date $(date +%Y-%m-%d) \
  --output table
```

- [ ] Can view usage data
- [ ] Costs align with estimates
- [ ] Resource tags present for cost tracking

## Operational Validation

### Scaling Tests

```bash
# Scale user pool
az aks nodepool scale \
  --resource-group fawkes-rg \
  --cluster-name fawkes-aks \
  --name user \
  --node-count 3

kubectl get nodes
```

- [ ] User pool scales up successfully
- [ ] New nodes become Ready
- [ ] Auto-scaler works within min/max limits

### Pod Scheduling

```bash
# Deploy a test workload
kubectl create deployment nginx --image=nginx --replicas=3
kubectl get pods -o wide
```

- [ ] Pods schedule across nodes
- [ ] Pods run successfully
- [ ] Can access pod logs

### Network Connectivity

```bash
# Test pod-to-pod connectivity
kubectl run test-pod --image=busybox -it --rm -- /bin/sh
# In pod: nslookup kubernetes.default
# In pod: wget -O- kubernetes.default
```

- [ ] DNS resolution works
- [ ] Pod can reach Kubernetes API
- [ ] Network policy allows expected traffic

### Monitoring

```bash
# Check metrics
kubectl top nodes
kubectl top pods -A
```

- [ ] Metrics server working
- [ ] Node metrics available
- [ ] Pod metrics available

## Security Validation

### RBAC

```bash
kubectl auth can-i list pods --as=system:anonymous
kubectl auth can-i list pods --as=system:serviceaccount:default:default
```

- [ ] Anonymous access properly restricted
- [ ] Service account permissions appropriate
- [ ] Azure RBAC enforced

### Network Security

```bash
kubectl get networkpolicies -A
az network nsg list --resource-group MC_fawkes-rg_*
```

- [ ] Network policies configured (if using)
- [ ] NSGs created by AKS
- [ ] Only required ports open

### Secrets Management

```bash
kubectl get secrets -A
az keyvault secret list --vault-name fawkes-kv
```

- [ ] No plaintext secrets in cluster
- [ ] Secrets stored in Key Vault
- [ ] CSI driver configured (optional)

## Documentation Validation

### Runbook

- [ ] Read through `docs/runbooks/azure-aks-setup.md`
- [ ] All commands work as documented
- [ ] Architecture diagram matches deployment
- [ ] Troubleshooting section helpful

### Terraform Documentation

- [ ] All variables documented
- [ ] Outputs are useful
- [ ] Examples are clear
- [ ] Comments explain complex logic

## Cleanup (Optional for Dev Environments)

If you need to tear down the environment:

```bash
# Option 1: Terraform destroy
cd infra/azure
terraform destroy

# Option 2: Delete resource group
az group delete --name fawkes-rg --yes --no-wait
```

**WARNING**: This will delete all resources. Ensure you have backups if needed.

## Sign-Off

Validated by: **\*\*\*\***\_**\*\*\*\***
Date: **\*\*\*\***\_**\*\*\*\***
Environment: [ ] Dev [ ] Stage [ ] Prod
All critical checks passed: [ ] Yes [ ] No

Notes:

---

---

---

---

## References

- Issue: https://github.com/paruff/fawkes/issues/1
- PR: https://github.com/paruff/fawkes/pull/[NUMBER]
- Runbook: docs/runbooks/azure-aks-setup.md
- InSpec Tests: infra/azure/inspec/
- BDD Tests: tests/bdd/features/azure_aks_provisioning.feature
