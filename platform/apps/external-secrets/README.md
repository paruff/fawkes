# External Secrets Operator - Cloud Secrets Integration

## Purpose

External Secrets Operator synchronizes secrets from external secret management systems (AWS Secrets Manager, Azure Key Vault, GCP Secret Manager) into Kubernetes secrets.

## Key Features

- **Multi-Provider**: AWS, Azure, GCP, Vault
- **Automatic Sync**: Periodic secret refresh
- **Secret Rotation**: Automatic updates on change
- **Template Support**: Transform secrets before sync
- **Namespace Isolation**: Scoped access control

## Architecture

```text
Cloud Secret Store → External Secrets Operator → Kubernetes Secret → Pod
```

## Quick Start

### Create SecretStore

```yaml
apiVersion: external-secrets.io/v1beta1
kind: SecretStore
metadata:
  name: aws-secrets
  namespace: fawkes
spec:
  provider:
    aws:
      service: SecretsManager
      region: us-east-1
      auth:
        jwt:
          serviceAccountRef:
            name: external-secrets
```

### Create ExternalSecret

```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: database-credentials
  namespace: fawkes
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: aws-secrets
    kind: SecretStore
  target:
    name: db-credentials
    creationPolicy: Owner
  data:
    - secretKey: username
      remoteRef:
        key: fawkes/database
        property: username
    - secretKey: password
      remoteRef:
        key: fawkes/database
        property: password
```

## Integration with Vault

For Vault integration, use ClusterSecretStore:

```yaml
apiVersion: external-secrets.io/v1beta1
kind: ClusterSecretStore
metadata:
  name: vault-backend
spec:
  provider:
    vault:
      server: "http://vault.vault.svc:8200"
      path: "secret"
      version: "v2"
      auth:
        kubernetes:
          mountPath: "kubernetes"
          role: "external-secrets"
```

## Secret Templates

Transform secrets before creating Kubernetes secret:

```yaml
spec:
  target:
    template:
      engineVersion: v2
      data:
        config.yaml: |
          database:
            host: {{ .host }}
            port: {{ .port }}
            username: {{ .username }}
            password: {{ .password }}
```

## Monitoring

Check ExternalSecret status:

```bash
kubectl get externalsecrets -A
kubectl describe externalsecret database-credentials -n fawkes
```

## Troubleshooting

### Secret Not Syncing

```bash
# Check operator logs
kubectl logs -n external-secrets deployment/external-secrets -f

# Check ExternalSecret status
kubectl get externalsecret -n fawkes -o yaml
```

## Related Documentation

- [External Secrets Documentation](https://external-secrets.io/)
- [ADR-009: Secrets Management](../../../docs/adr/ADR-009-secrets-management.md)
