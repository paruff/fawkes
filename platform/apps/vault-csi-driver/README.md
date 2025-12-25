# Vault CSI Driver - Secret Volume Mounting

## Purpose

The Secrets Store CSI Driver integrates Vault with Kubernetes, allowing secrets to be mounted as volumes in pods without requiring Vault Agent sidecars.

## Key Features

- **Volume Mount**: Mount secrets as files in pod volumes
- **No Sidecar**: Lower resource overhead than Agent injection
- **Automatic Rotation**: Secrets update when changed in Vault
- **Sync to K8s Secret**: Optionally create Kubernetes secrets
- **Multiple Secrets**: Mount multiple secrets in one volume

## Architecture

```text
Pod → CSI Driver → Vault → Secret as Volume
```

## Quick Start

### Create SecretProviderClass

```yaml
apiVersion: secrets-store.csi.x-k8s.io/v1
kind: SecretProviderClass
metadata:
  name: vault-database-creds
  namespace: fawkes
spec:
  provider: vault
  parameters:
    vaultAddress: "http://vault.vault.svc:8200"
    roleName: "database-reader"
    objects: |
      - objectName: "username"
        secretPath: "secret/data/fawkes/database"
        secretKey: "username"
      - objectName: "password"
        secretPath: "secret/data/fawkes/database"
        secretKey: "password"
```

### Mount Secret in Pod

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: my-app
spec:
  serviceAccountName: vault-secrets-reader
  containers:
    - name: app
      image: my-app:latest
      volumeMounts:
        - name: secrets
          mountPath: "/mnt/secrets"
          readOnly: true
  volumes:
    - name: secrets
      csi:
        driver: secrets-store.csi.k8s.io
        readOnly: true
        volumeAttributes:
          secretProviderClass: "vault-database-creds"
```

### Access Secrets

```bash
# Inside container
cat /mnt/secrets/username
cat /mnt/secrets/password
```

## Sync to Kubernetes Secret

Optionally sync to a Kubernetes secret for env var usage:

```yaml
apiVersion: secrets-store.csi.x-k8s.io/v1
kind: SecretProviderClass
metadata:
  name: vault-database-creds
spec:
  provider: vault
  secretObjects:
    - secretName: database-credentials
      type: Opaque
      data:
        - objectName: username
          key: username
        - objectName: password
          key: password
  parameters:
    vaultAddress: "http://vault.vault.svc:8200"
    roleName: "database-reader"
    objects: |
      - objectName: "username"
        secretPath: "secret/data/fawkes/database"
        secretKey: "username"
      - objectName: "password"
        secretPath: "secret/data/fawkes/database"
        secretKey: "password"
```

Then use as environment variables:

```yaml
env:
  - name: DB_USERNAME
    valueFrom:
      secretKeyRef:
        name: database-credentials
        key: username
  - name: DB_PASSWORD
    valueFrom:
      secretKeyRef:
        name: database-credentials
        key: password
```

## Automatic Rotation

The CSI driver polls Vault for changes and updates mounted secrets automatically:

```yaml
parameters:
  # Check for updates every 5 minutes
  vaultSyncInterval: "5m"
```

## Comparison with Vault Agent

| Feature         | CSI Driver         | Vault Agent              |
| --------------- | ------------------ | ------------------------ |
| Resource Usage  | Lower (no sidecar) | Higher (sidecar per pod) |
| Secret Location | File mount         | File mount + template    |
| Rotation        | Automatic          | Automatic                |
| Ease of Use     | Simple             | More flexible            |
| Use Case        | File-based config  | Complex templating       |

## Troubleshooting

### Volume Mount Fails

```bash
# Check CSI driver logs
kubectl logs -n kube-system daemonset/csi-secrets-store -f

# Check SecretProviderClass
kubectl describe secretproviderclass vault-database-creds -n fawkes
```

### Authentication Errors

```bash
# Verify service account has Vault role
kubectl exec vault-0 -n vault -- \
  vault read auth/kubernetes/role/database-reader
```

## Related Documentation

- [Secrets Store CSI Driver](https://secrets-store-csi-driver.sigs.k8s.io/)
- [Vault CSI Provider](https://developer.hashicorp.com/vault/docs/platform/k8s/csi)
- [ADR-009: Secrets Management](../../../docs/adr/ADR-009-secrets-management.md)
