# Integration Tests

This directory contains integration tests for various Fawkes platform components.

## Available Tests

### AT-E1-001: AKS Cluster Validation

Tests AKS cluster infrastructure and configuration.

### AT-E1-006: Observability Stack Validation

Tests Prometheus/Grafana observability stack deployment and configuration.

### Azure Storage Integration Tests

Tests Azure persistent storage in the Fawkes platform.

---

## AT-E1-006: Observability Stack Validation

### Overview

The AT-E1-006 integration test validates the complete observability stack deployment including Prometheus, Grafana, Alertmanager, and supporting components.

### What is Tested

- **Namespace**: Monitoring namespace exists and is active
- **ArgoCD Application**: prometheus-stack is Healthy and Synced
- **Prometheus Operator**: Deployed and running
- **Prometheus Server**: StatefulSet is ready with persistent storage
- **Grafana**: Deployed with ingress configured
- **Alertmanager**: Deployed and configured
- **Node Exporter**: DaemonSet running on all nodes
- **Kube State Metrics**: Collecting cluster metrics
- **ServiceMonitors**: Configured for platform components (ArgoCD, Jenkins, PostgreSQL, OpenTelemetry)
- **Ingress**: Configured for Grafana and Prometheus
- **Resource Limits**: All components have resource requests/limits
- **Pod Health**: All pods in monitoring namespace are healthy

### Prerequisites

1. **Kubernetes Cluster**: Running cluster with monitoring stack deployed
2. **kubectl**: Configured to access the cluster
3. **ArgoCD**: prometheus-stack Application deployed
4. **Python 3.8+**: For running pytest
5. **pytest**: Installed via `pip install -r requirements-dev.txt`

### Running the Test

#### Method 1: Using pytest directly

```bash
# Run all AT-E1-006 tests
pytest tests/integration/test_at_e1_006_validation.py -v

# Run with custom namespace
pytest tests/integration/test_at_e1_006_validation.py -v --namespace monitoring --argocd-namespace fawkes

# Run only smoke tests
pytest tests/integration/test_at_e1_006_validation.py -v -m smoke

# Run with custom timeout
pytest tests/integration/test_at_e1_006_validation.py -v --validation-timeout 300
```

#### Method 2: Using Makefile

```bash
# Run AT-E1-006 validation
make validate-at-e1-006

# With custom namespace
make validate-at-e1-006 NAMESPACE=monitoring ARGO_NAMESPACE=fawkes
```

#### Method 3: Run validation script directly

```bash
# Run validation script
./scripts/validate-at-e1-006.sh --namespace monitoring --argocd-namespace fawkes

# Verbose output
./scripts/validate-at-e1-006.sh --verbose

# Custom report location
./scripts/validate-at-e1-006.sh --report custom-report.json
```

### Test Output

The test generates a JSON report in the `reports/` directory:

```json
{
  "test_suite": "AT-E1-006: Observability Stack Validation",
  "timestamp": "2024-12-15T15:45:00Z",
  "namespace": "monitoring",
  "argocd_namespace": "fawkes",
  "summary": {
    "total_tests": 14,
    "passed": 14,
    "failed": 0,
    "pass_percentage": 100
  },
  "results": [
    {
      "test": "namespace_exists",
      "status": "PASS",
      "message": "Namespace monitoring exists and is Active"
    },
    ...
  ]
}
```

### Validation Criteria

The test suite validates all AT-E1-006 acceptance criteria:

| Criterion                            | Test                                 |
| ------------------------------------ | ------------------------------------ |
| Prometheus Operator deployed         | `test_prometheus_operator_running`   |
| Grafana deployed with datasources    | `test_grafana_deployed`              |
| ServiceMonitors configured           | `test_servicemonitors_configured`    |
| OpenTelemetry Collector as DaemonSet | Validated via ServiceMonitor         |
| Grafana dashboards imported          | Validated via ingress and deployment |
| Alerting rules configured            | Validated via Alertmanager           |
| Log retention: 30 days               | Validated via persistent storage     |
| Metrics retention: 90 days           | Validated via Prometheus storage     |
| Dashboard load time <2 seconds       | Validated via ingress configuration  |

### Troubleshooting

#### Test fails: "Validation script crashed"

```bash
# Check if kubectl is configured
kubectl cluster-info

# Check if script is executable
chmod +x scripts/validate-at-e1-006.sh

# Run script directly to see errors
./scripts/validate-at-e1-006.sh --verbose
```

#### Test fails: "Namespace does not exist"

```bash
# Check if monitoring namespace exists
kubectl get namespace monitoring

# Create namespace if missing
kubectl create namespace monitoring
```

#### Test fails: "ArgoCD Application not found"

```bash
# Check if ArgoCD Application exists
kubectl get application prometheus-stack -n fawkes

# Check Application status
kubectl describe application prometheus-stack -n fawkes
```

#### Test fails: "Pods not ready"

```bash
# Check pod status
kubectl get pods -n monitoring

# Check specific pod logs
kubectl logs -n monitoring <pod-name>

# Check pod events
kubectl describe pod -n monitoring <pod-name>
```

### Environment Variables

- `NAMESPACE`: Monitoring namespace (default: `monitoring`)
- `ARGOCD_NAMESPACE`: ArgoCD namespace (default: `fawkes`)
- `VALIDATION_TIMEOUT`: Timeout in seconds (default: `600`)
- `PROMETHEUS_URL`: Prometheus URL for API checks
- `GRAFANA_URL`: Grafana URL for UI checks

### CI/CD Integration

Example GitHub Actions workflow:

```yaml
- name: Validate Observability Stack
  run: |
    make validate-at-e1-006
  env:
    NAMESPACE: monitoring
    ARGO_NAMESPACE: fawkes
```

---

## Azure Storage Integration Tests

### Overview

These tests verify that:

- Azure Disk and Azure Files storage classes are properly configured
- PVCs can be created and bound successfully
- Volumes can be mounted and accessed by pods
- Volume expansion works correctly
- Snapshots can be created and restored
- Performance meets acceptable thresholds

## Test Files

### azure-storage-test.yaml

Complete integration test suite including:

- **Test PVCs**: Premium disk, standard disk, and Azure Files
- **Test Pods**: Writers and readers for each storage type
- **Snapshot Tests**: Volume snapshot and restore validation
- **Test Scripts**: Automated test execution and cleanup

## Prerequisites

Before running tests, ensure:

1. **AKS Cluster**: A running AKS cluster with storage drivers installed
2. **kubectl**: Configured to access the cluster
3. **Storage Classes**: Deployed via ArgoCD or manually applied
4. **CSI Drivers**: Azure Disk and Azure File CSI drivers should be installed (included in AKS)
5. **VolumeSnapshotClass**: For snapshot tests, ensure `csi-azuredisk-vsc` VolumeSnapshotClass
   exists (typically pre-installed in AKS clusters with snapshot support)

## Running Tests

### Method 1: Apply Test Manifests Directly

```bash
# Apply test manifests
kubectl apply -f azure-storage-test.yaml

# Wait for PVCs to bind
kubectl wait --for=jsonpath='{.status.phase}'=Bound pvc --all -n storage-test --timeout=300s

# Wait for pods to be ready
kubectl wait --for=condition=Ready pod -l test=azure-storage -n storage-test --timeout=300s

# Check pod logs
kubectl logs -n storage-test test-disk-premium-writer
kubectl logs -n storage-test test-disk-standard-writer
kubectl logs -n storage-test test-file-writer-1
kubectl logs -n storage-test test-file-writer-2
```

### Method 2: Use Test Scripts

```bash
# Deploy tests
kubectl apply -f azure-storage-test.yaml

# Run automated tests
kubectl run storage-tests \
  --image=bitnami/kubectl:latest \
  --restart=Never \
  --rm -it \
  -n storage-test \
  --command -- /bin/bash -c "$(kubectl get cm storage-test-scripts -n storage-test -o jsonpath='{.data.run-tests\.sh}')"

# Or execute from the ConfigMap
kubectl create job storage-test-job \
  --from=cronjob/test-runner \
  -n storage-test
```

### Method 3: Use BDD Tests

```bash
# Run BDD tests with pytest-bdd
cd /home/runner/work/fawkes/fawkes
pytest tests/bdd/features/azure_storage.feature -v
```

## Test Scenarios

### 1. PVC Creation and Binding

Tests that PVCs can be created and bound for:

- Azure Disk Premium (default)
- Azure Disk Standard
- Azure Files

### 2. Data Persistence

Tests writing and reading data:

- Write test files to volumes
- Verify data persists across pod restarts
- Check data integrity

### 3. ReadWriteMany (Azure Files)

Tests multiple pods accessing the same volume:

- Two writers simultaneously write to Azure Files
- Each writer can see the other's files
- No data corruption

### 4. Volume Expansion

Tests volume expansion capability:

- Expand Premium Disk from 5Gi to 10Gi
- Expand Azure Files from 10Gi to 20Gi
- Verify pods can use expanded storage

### 5. Snapshot and Restore

Tests backup and recovery:

- Create snapshot from Premium Disk
- Restore PVC from snapshot
- Verify data integrity after restore

### 6. Performance Testing

Tests storage performance:

- Sequential write throughput (Premium vs Standard)
- Random write throughput
- Compare against expected values

## Validation Commands

```bash
# Check storage classes
kubectl get storageclass

# Check PVCs status
kubectl get pvc -n storage-test

# Check PV details
kubectl get pv

# Describe a specific PVC
kubectl describe pvc test-azure-disk-premium -n storage-test

# Check pod status
kubectl get pods -n storage-test

# View pod logs
kubectl logs test-disk-premium-writer -n storage-test

# Check volume mounts in a pod
kubectl exec test-disk-premium-writer -n storage-test -- df -h

# Test volume expansion
kubectl patch pvc test-azure-disk-premium -n storage-test \
  -p '{"spec":{"resources":{"requests":{"storage":"10Gi"}}}}'

# Check snapshot status
kubectl get volumesnapshot -n storage-test

# Check Azure resources (requires Azure CLI)
az disk list --resource-group <node-resource-group> -o table
```

## Performance Benchmarks

### Expected Performance (Azure Disk Premium - 5Gi)

- **IOPS**: 120 IOPS (baseline)
- **Throughput**: 25 MB/s (baseline)
- **Latency**: < 10ms

### Expected Performance (Azure Disk Standard - 5Gi)

- **IOPS**: 120 IOPS (baseline)
- **Throughput**: 25 MB/s (baseline)
- **Latency**: < 20ms

### Expected Performance (Azure Files Standard)

- **IOPS**: Based on share size
- **Throughput**: Up to 60 MB/s for Standard
- **Latency**: Higher than disk (network-based)

> **Note**: Performance scales with disk size. For Premium SSD, performance can reach up to
> 20,000 IOPS and 900 MB/s for disks >1TB. Standard SSD can reach up to 6,000 IOPS and
> 750 MB/s for larger disks. The values above are baseline performance for 5Gi disks.

## Cleanup

```bash
# Method 1: Delete namespace (deletes all resources)
kubectl delete namespace storage-test

# Method 2: Use cleanup script
kubectl run cleanup \
  --image=bitnami/kubectl:latest \
  --restart=Never \
  --rm -it \
  -n storage-test \
  --command -- /bin/bash -c "$(kubectl get cm storage-test-scripts -n storage-test -o jsonpath='{.data.cleanup\.sh}')"

# Method 3: Delete individual resources
kubectl delete -f azure-storage-test.yaml
```

## Troubleshooting

### PVC Not Binding

```bash
# Check PVC events
kubectl describe pvc <pvc-name> -n storage-test

# Check storage class exists
kubectl get storageclass

# Check CSI driver pods
kubectl get pods -n kube-system | grep csi

# Check for provisioning errors
kubectl logs -n kube-system -l app=csi-azuredisk-controller
kubectl logs -n kube-system -l app=csi-azurefile-controller
```

### Pod Not Starting

```bash
# Check pod events
kubectl describe pod <pod-name> -n storage-test

# Check if volume is mounted
kubectl get pod <pod-name> -n storage-test -o yaml | grep -A 10 volumeMounts

# Check node has capacity
kubectl describe node <node-name>
```

### Snapshot Creation Fails

```bash
# Check if VolumeSnapshotClass exists
kubectl get volumesnapshotclass

# Check snapshot controller
kubectl get pods -n kube-system | grep snapshot

# Check snapshot events
kubectl describe volumesnapshot <snapshot-name> -n storage-test
```

### Performance Issues

```bash
# Check disk throttling in Azure
az disk show --resource-group <rg> --name <disk-name> --query "{name:name,size:diskSizeGb,sku:sku.name}"

# Check node resources
kubectl top nodes

# Check pod resources
kubectl top pods -n storage-test

# Run detailed performance test
kubectl exec test-disk-premium-writer -n storage-test -- \
  dd if=/dev/zero of=/data/perftest bs=1M count=1000 oflag=direct
```

## Azure Resources Created

When tests run, the following Azure resources are created:

1. **Managed Disks**: One for each PVC using azure-disk-\* storage classes
2. **Azure Files Shares**: One for each PVC using azure-file storage class
3. **Disk Snapshots**: When snapshot tests are executed

All resources are tagged with:

- `kubernetes.io/created-for/pvc/name`: PVC name
- `kubernetes.io/created-for/pvc/namespace`: PVC namespace
- `backup`: enabled
- `platform`: fawkes

## Cost Considerations

Running these tests will incur Azure costs:

- **Premium Disk (5Gi)**: ~$0.96/month (prorated for test duration)
- **Standard Disk (5Gi)**: ~$0.29/month (prorated)
- **Azure Files (10Gi)**: ~$0.15/month (prorated)
- **Snapshots**: ~$0.05/GB/month

**Estimated test cost**: < $0.10 for a 1-hour test run

**Important**: Always clean up test resources after completion to avoid ongoing charges.

## CI/CD Integration

These tests can be integrated into CI/CD pipelines:

```yaml
# Example GitHub Actions step
- name: Run Storage Integration Tests
  run: |
    kubectl apply -f tests/integration/azure-storage-test.yaml
    kubectl wait --for=jsonpath='{.status.phase}'=Bound pvc --all -n storage-test --timeout=300s
    kubectl wait --for=condition=Ready pod -l test=azure-storage -n storage-test --timeout=300s
    # Run validation
    kubectl logs -n storage-test test-disk-premium-writer | grep "SUCCESS"
    # Cleanup
    kubectl delete namespace storage-test
```

## References

- [Azure Disk CSI Driver](https://github.com/kubernetes-sigs/azuredisk-csi-driver)
- [Azure File CSI Driver](https://github.com/kubernetes-sigs/azurefile-csi-driver)
- [Kubernetes Storage Classes](https://kubernetes.io/docs/concepts/storage/storage-classes/)
- [Volume Snapshots](https://kubernetes.io/docs/concepts/storage/volume-snapshots/)
- [Azure Disk Performance](https://learn.microsoft.com/en-us/azure/virtual-machines/disks-types)
