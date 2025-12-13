# Azure Storage Classes for Fawkes Platform

This directory contains Kubernetes StorageClass definitions for Azure persistent storage.

## Storage Classes

### 1. azure-disk-premium (Default)
- **Purpose**: High-performance workloads (databases, critical applications)
- **Type**: Azure Premium SSD (Premium_LRS)
- **Access Mode**: ReadWriteOnce
- **Features**:
  - Volume expansion enabled
  - ReadOnly caching for better performance
  - Automatic backup via tags
  - WaitForFirstConsumer binding mode

### 2. azure-disk-standard
- **Purpose**: General workloads (less critical applications)
- **Type**: Azure Standard SSD (StandardSSD_LRS)
- **Access Mode**: ReadWriteOnce
- **Features**:
  - Volume expansion enabled
  - Cost-effective alternative to Premium
  - Automatic backup via tags
  - WaitForFirstConsumer binding mode

### 3. azure-file
- **Purpose**: Shared storage across multiple pods
- **Type**: Azure Files (Standard_LRS)
- **Access Mode**: ReadWriteMany
- **Features**:
  - Volume expansion enabled
  - SMB protocol
  - Immediate binding mode
  - Suitable for shared data scenarios

## Usage

### Create a PVC with Premium Disk (Default)

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
  # storageClassName not needed - azure-disk-premium is default
```

### Create a PVC with Azure Files

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-shared-pvc
spec:
  accessModes:
    - ReadWriteMany
  storageClassName: azure-file
  resources:
    requests:
      storage: 100Gi
```

## Backup Configuration

All StorageClasses are tagged with `backup=enabled`. The Azure Backup configuration
is managed through Terraform in `infra/azure/backup.tf`.

Backup policies:
- Daily backups retained for 7 days
- Weekly backups retained for 4 weeks
- Automatic backup for all tagged persistent volumes

## Volume Expansion

To expand a volume:

1. Edit the PVC and increase the storage size:
   ```bash
   kubectl edit pvc my-pvc
   ```

2. Update the storage request:
   ```yaml
   spec:
     resources:
       requests:
         storage: 20Gi  # Increased from 10Gi
   ```

3. The volume will be automatically expanded

## Testing

See `tests/integration/azure-storage-test.yaml` for comprehensive storage tests.

## Deployment

This is deployed via ArgoCD using the `storage-application.yaml` manifest.

```bash
kubectl apply -f storage-application.yaml
```

## Performance Considerations

### Premium SSD
- Best for: Databases (PostgreSQL, MySQL), high I/O applications
- IOPS: Up to 20,000 IOPS (depending on size)
- Throughput: Up to 900 MB/s

### Standard SSD
- Best for: Web servers, dev/test environments
- IOPS: Up to 6,000 IOPS (depending on size)
- Throughput: Up to 750 MB/s

### Azure Files
- Best for: Shared storage, content management
- IOPS: Based on share size
- Performance tier available for high-performance needs

## Cost Optimization

- Use Standard SSD for non-critical workloads
- Right-size volumes (start small, expand as needed)
- Monitor unused PVCs and delete when no longer needed
- Consider Azure Files Premium for high-performance shared storage needs

## Related Documentation

- [Azure Disk CSI Driver](https://github.com/kubernetes-sigs/azuredisk-csi-driver)
- [Azure File CSI Driver](https://github.com/kubernetes-sigs/azurefile-csi-driver)
- [Kubernetes Storage Classes](https://kubernetes.io/docs/concepts/storage/storage-classes/)
