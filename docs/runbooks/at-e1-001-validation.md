# AT-E1-001 Validation Tests

This document describes how to run the AT-E1-001 acceptance test validation for the Azure AKS cluster infrastructure.

## Overview

AT-E1-001 validates that the Azure AKS cluster meets all acceptance criteria required for the Fawkes platform:

- ✅ K8s cluster running (Azure AKS)
- ✅ 4 worker nodes healthy and schedulable
- ✅ Cluster metrics available (kubelet, cAdvisor)
- ✅ StorageClass configured for persistent volumes
- ✅ Ingress controller deployed (nginx/traefik)
- ✅ Cluster resource limits: CPU <70%, Memory <70%, Disk <80%

## Prerequisites

Before running the validation tests, ensure you have:

1. **Azure CLI** installed and configured
   ```bash
   az --version
   az login
   ```

2. **kubectl** installed
   ```bash
   kubectl version --client
   ```

3. **Python 3.8+** (for pytest-based tests)
   ```bash
   python --version
   pip install -r requirements-dev.txt
   ```

4. **Azure AKS cluster** deployed
   - Cluster should be deployed using the terraform configuration in `infra/azure/`
   - Or deployed using the ignite script: `./scripts/ignite.sh --provider azure --only-cluster dev`

## Running Validation Tests

### Method 1: Using the Validation Script (Recommended)

The validation script is a standalone bash script that performs all checks and generates a JSON report.

**Basic usage:**
```bash
./scripts/validate-at-e1-001.sh
```

**With custom cluster:**
```bash
./scripts/validate-at-e1-001.sh \
  --resource-group my-rg \
  --cluster-name my-aks
```

**With environment variables:**
```bash
export AZURE_RESOURCE_GROUP=fawkes-rg
export AZURE_CLUSTER_NAME=fawkes-aks
./scripts/validate-at-e1-001.sh --verbose
```

**Options:**
- `-g, --resource-group` - Azure resource group name (default: fawkes-rg)
- `-c, --cluster-name` - AKS cluster name (default: fawkes-aks)
- `-m, --min-nodes` - Minimum required nodes (default: 4)
- `-v, --verbose` - Verbose output
- `-h, --help` - Show help message

**Output:**

The script will:
1. Run all validation checks
2. Display results with color-coded output
3. Generate a JSON report in `reports/at-e1-001-validation-<timestamp>.json`
4. Print a summary of passed/failed tests
5. Exit with code 0 (success) or 1 (failure)

### Method 2: Using pytest Integration Tests

The pytest integration tests wrap the validation script and provide additional test assertions.

**Run all AT-E1-001 tests:**
```bash
pytest tests/integration/test_at_e1_001_validation.py -v
```

**Run with custom cluster:**
```bash
pytest tests/integration/test_at_e1_001_validation.py -v \
  --resource-group my-rg \
  --cluster-name my-aks
```

**Run specific test:**
```bash
pytest tests/integration/test_at_e1_001_validation.py::TestATE1001Validation::test_all_nodes_ready -v
```

**Run with markers:**
```bash
# Run all smoke tests
pytest tests/integration/test_at_e1_001_validation.py -v -m smoke

# Run all Azure integration tests
pytest tests/integration/ -v -m "azure and integration"
```

### Method 3: Using BDD Tests

The existing BDD feature file includes scenarios for AT-E1-001 validation.

**Run BDD tests:**
```bash
pytest tests/bdd/features/azure_aks_provisioning.feature -v -k "AT-E1-001"
```

**Or with behave:**
```bash
behave tests/bdd/features/azure_aks_provisioning.feature --tags=AT-E1-001
```

### Method 4: Using InSpec

For compliance testing, use InSpec with the Azure plugin:

```bash
# Install InSpec and Azure plugin (if not already installed)
# gem install inspec
# inspec plugin install inspec-azure

# Run InSpec tests
inspec exec infra/azure/inspec/ \
  -t azure:// \
  --input resource_group=fawkes-rg \
  --input cluster_name=fawkes-aks \
  --reporter cli json:reports/aks-inspec.json
```

## Understanding Test Results

### Validation Script Output

The validation script provides:

1. **Real-time Progress**: Each test shows PASS/FAIL status with colored output
2. **Summary Statistics**: Total tests, passed, failed, and success rate
3. **JSON Report**: Detailed results saved to `reports/` directory

Example output:
```
[INFO] Checking prerequisites...
[✓] Prerequisites - Azure CLI: Azure CLI installed
[✓] Prerequisites - kubectl: kubectl installed
[✓] Prerequisites - Azure Auth: Authenticated to Azure
[INFO] Checking if AKS cluster exists...
[✓] Cluster Exists: Cluster is provisioned and running
...
========================================
  AT-E1-001 Validation Summary
========================================
Cluster: fawkes-aks (fawkes-rg)
Total Tests: 11
Passed: 11
Failed: 0
Success Rate: 100.0%
========================================
```

### JSON Report Format

The JSON report includes:
```json
{
  "test_suite": "AT-E1-001",
  "timestamp": "2024-12-13T12:00:00Z",
  "cluster": {
    "resource_group": "fawkes-rg",
    "name": "fawkes-aks"
  },
  "summary": {
    "total": 11,
    "passed": 11,
    "failed": 0,
    "success_rate": 100.0
  },
  "tests": [
    {
      "test": "Cluster Exists",
      "status": "PASS",
      "message": "Cluster is provisioned and running"
    }
    // ... more tests
  ]
}
```

## Troubleshooting

### Common Issues

**Issue: Azure CLI not authenticated**
```
[✗] Prerequisites - Azure Auth: Not authenticated to Azure
```
Solution:
```bash
az login
az account set --subscription <your-subscription-id>
```

**Issue: Cluster not found**
```
[✗] Cluster Exists: Cluster fawkes-aks not found in fawkes-rg
```
Solution:
- Verify cluster name and resource group
- Check that cluster is deployed: `az aks list -o table`
- Deploy cluster if needed: `./scripts/ignite.sh --provider azure --only-cluster dev`

**Issue: kubectl cannot connect**
```
[✗] kubectl Configuration: kubectl cannot connect to cluster
```
Solution:
```bash
az aks get-credentials \
  --resource-group fawkes-rg \
  --name fawkes-aks \
  --overwrite-existing
kubectl cluster-info
```

**Issue: Metrics not available**
```
[✗] Cluster Metrics: metrics-server deployed but not returning data
```
Solution:
- Wait a few minutes for metrics-server to collect data
- Check metrics-server pod status: `kubectl get pods -n kube-system -l k8s-app=metrics-server`
- Check metrics-server logs: `kubectl logs -n kube-system -l k8s-app=metrics-server`

**Issue: Ingress controller not found**
```
[✗] Ingress Controller: No ingress controller (nginx/traefik) found
```
Solution:
- Deploy ingress controller (see issue #2 in epic1-local.json)
- For nginx: `kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/cloud/deploy.yaml`
- Wait for deployment: `kubectl wait --namespace ingress-nginx --for=condition=ready pod --selector=app.kubernetes.io/component=controller --timeout=120s`

**Issue: Nodes over resource limits**
```
[✗] Resource Limits: 1 node(s) over resource limits
```
Solution:
- Check node metrics: `kubectl top nodes`
- Scale down resource-intensive workloads
- Consider adding more nodes or upgrading node SKUs
- For development: This warning can sometimes be ignored if non-critical

## Integration with CI/CD

### GitHub Actions

Add to your workflow:

```yaml
- name: Run AT-E1-001 Validation
  run: |
    az login --service-principal -u ${{ secrets.AZURE_CLIENT_ID }} -p ${{ secrets.AZURE_CLIENT_SECRET }} --tenant ${{ secrets.AZURE_TENANT_ID }}
    ./scripts/validate-at-e1-001.sh --resource-group fawkes-rg --cluster-name fawkes-aks
  
- name: Upload Validation Report
  if: always()
  uses: actions/upload-artifact@v3
  with:
    name: at-e1-001-report
    path: reports/at-e1-001-validation-*.json
```

### Jenkins

Add to your Jenkinsfile:

```groovy
stage('AT-E1-001 Validation') {
    steps {
        withCredentials([azureServicePrincipal('azure-sp')]) {
            sh '''
                az login --service-principal -u $AZURE_CLIENT_ID -p $AZURE_CLIENT_SECRET --tenant $AZURE_TENANT_ID
                ./scripts/validate-at-e1-001.sh --resource-group fawkes-rg --cluster-name fawkes-aks
            '''
        }
    }
    post {
        always {
            archiveArtifacts artifacts: 'reports/at-e1-001-validation-*.json', allowEmptyArchive: true
        }
    }
}
```

## Acceptance Criteria Mapping

| Criterion | Test Name | Script Check |
|-----------|-----------|--------------|
| K8s cluster running (azure aks) | `check_cluster_exists` | ✅ Verifies cluster exists and is in Running state |
| 4 worker nodes healthy and schedulable | `check_node_count`, `check_nodes_ready`, `check_nodes_schedulable` | ✅ Counts nodes, checks Ready status, verifies schedulable |
| Cluster metrics available | `check_metrics_available` | ✅ Verifies metrics-server is deployed and returning data |
| StorageClass configured | `check_storage_class` | ✅ Checks for StorageClass and default SC |
| Ingress controller deployed | `check_ingress_controller` | ✅ Looks for nginx-ingress or traefik |
| Cluster resource limits | `check_resource_limits` | ✅ Validates CPU <70%, Memory <70% on all nodes |

## Related Documentation

- [Azure AKS Setup](azure-aks-setup.md)
- [Azure AKS Validation Checklist](azure-aks-validation-checklist.md)
- [BDD Feature: Azure AKS Provisioning](../../tests/bdd/features/azure_aks_provisioning.feature)
- [InSpec Controls](../../infra/azure/inspec/controls/aks.rb)

## Support

For issues or questions:
1. Check the [troubleshooting section](#troubleshooting) above
2. Review the [Azure AKS validation checklist](azure-aks-validation-checklist.md)
3. Open an issue on GitHub with the validation report attached
