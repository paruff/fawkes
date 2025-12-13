# Azure AKS InSpec Tests

This directory contains InSpec compliance tests for validating the Azure AKS cluster deployment.

## Prerequisites

```bash
# Install InSpec
curl https://omnitruck.chef.io/install.sh | sudo bash -s -- -P inspec

# Install Azure plugin
inspec plugin install inspec-azure

# Authenticate to Azure
az login
```

## Running Tests

### Run all tests

```bash
# From repository root
inspec exec infra/azure/inspec/ -t azure://

# With custom attributes
inspec exec infra/azure/inspec/ -t azure:// \
  --input resource_group=my-rg \
  --input cluster_name=my-aks
```

### Run specific control

```bash
inspec exec infra/azure/inspec/ -t azure:// \
  --controls aks-cluster-exists
```

### Generate reports

```bash
# JSON report
inspec exec infra/azure/inspec/ -t azure:// \
  --reporter json:reports/aks-inspec.json

# HTML report
inspec exec infra/azure/inspec/ -t azure:// \
  --reporter html:reports/aks-inspec.html

# CLI + JSON
inspec exec infra/azure/inspec/ -t azure:// \
  --reporter cli json:reports/aks-inspec.json
```

## Test Coverage

### Infrastructure Tests (Azure-level)

- **aks-cluster-exists**: Cluster exists and is running
- **aks-node-count**: Minimum node count (2+)
- **aks-node-pool-separation**: System and user pools separated
- **aks-azure-cni**: Azure CNI networking configured
- **aks-managed-identity**: Managed identity enabled
- **aks-network-policy**: Network policy configured
- **aks-rbac-enabled**: Kubernetes RBAC enabled
- **aks-azure-rbac**: Azure RBAC for Kubernetes enabled
- **aks-autoscaling-enabled**: User pool auto-scaling enabled
- **aks-monitoring-enabled**: Azure Monitor integration enabled
- **aks-oidc-issuer**: OIDC issuer enabled
- **aks-vm-sizes**: Appropriate VM sizes
- **aks-os-disk-size**: Adequate OS disk space
- **aks-load-balancer-sku**: Standard load balancer

### Kubernetes Tests (K8s API-level)

These tests require kubectl access to the cluster:

- **k8s-nodes-ready**: All nodes in Ready state
- **k8s-system-pods-running**: System pods running
- **k8s-coredns-running**: CoreDNS operational
- **k8s-storage-class**: Default storage class exists
- **k8s-azure-cni-running**: Azure CNI pods running
- **k8s-metrics-server**: Metrics server available

## Test Tags

Filter tests by tags:

```bash
# Run only Kubernetes-level tests
inspec exec infra/azure/inspec/ -t azure:// \
  --controls '/^k8s-/'
```

## Acceptance Test AT-E1-001

The test suite validates acceptance criteria for AT-E1-001:

- ✅ AKS cluster deployed in Azure
- ✅ 2+ nodes running and schedulable
- ✅ Azure CNI networking configured
- ✅ System and user node pools separated
- ✅ kubectl configured and working
- ✅ Azure Monitor integration (if enabled)
- ✅ Azure AD/RBAC integration (if enabled)

## Integration with CI/CD

### GitHub Actions

```yaml
- name: Run InSpec Tests
  run: |
    az login --service-principal -u ${{ secrets.AZURE_CLIENT_ID }} \
      -p ${{ secrets.AZURE_CLIENT_SECRET }} \
      --tenant ${{ secrets.AZURE_TENANT_ID }}
    
    inspec exec infra/azure/inspec/ -t azure:// \
      --reporter cli json:aks-inspec-results.json
    
- name: Upload Test Results
  uses: actions/upload-artifact@v3
  with:
    name: inspec-results
    path: aks-inspec-results.json
```

### Jenkins

```groovy
stage('InSpec Tests') {
    steps {
        withCredentials([azureServicePrincipal('azure-credentials')]) {
            sh '''
                az login --service-principal -u $AZURE_CLIENT_ID \
                  -p $AZURE_CLIENT_SECRET --tenant $AZURE_TENANT_ID
                
                inspec exec infra/azure/inspec/ -t azure:// \
                  --reporter cli junit:reports/aks-inspec.xml
            '''
        }
    }
    post {
        always {
            junit 'reports/aks-inspec.xml'
        }
    }
}
```

## Troubleshooting

### Authentication Issues

```bash
# Verify Azure authentication
az account show

# Check InSpec Azure connection
inspec detect -t azure://
```

### Kubectl Context Issues

If Kubernetes tests fail, ensure kubectl is configured:

```bash
az aks get-credentials \
  --resource-group fawkes-rg \
  --name fawkes-aks \
  --overwrite-existing

kubectl cluster-info
```

### Missing Dependencies

```bash
# Update InSpec plugins
inspec plugin list
inspec plugin install inspec-azure --force
```

## Continuous Compliance

Schedule regular compliance checks:

```bash
# Cron job (daily at 2 AM)
0 2 * * * /usr/bin/inspec exec /path/to/fawkes/infra/azure/inspec/ \
  -t azure:// --reporter json:/var/log/aks-compliance.json
```

## Resources

- [InSpec Documentation](https://docs.chef.io/inspec/)
- [InSpec Azure Resources](https://github.com/inspec/inspec-azure)
- [Azure AKS Best Practices](https://learn.microsoft.com/en-us/azure/aks/best-practices)
