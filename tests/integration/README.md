# Azure Storage Integration Tests

This directory contains integration tests for Azure persistent storage in the Fawkes platform.

## Overview

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

1. **Managed Disks**: One for each PVC using azure-disk-* storage classes
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
