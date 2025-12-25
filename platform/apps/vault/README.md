# HashiCorp Vault - Secrets Management for Fawkes Platform

This directory contains the deployment manifests and configuration for HashiCorp
Vault, providing centralized secrets management for the Fawkes Internal Delivery
Platform.

## Architecture

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│                           Vault HA Cluster                                   │
│                                                                              │
│  ┌────────────┐    ┌────────────┐    ┌────────────┐                         │
│  │  vault-0   │◄──►│  vault-1   │◄──►│  vault-2   │  Raft Consensus         │
│  │ (Primary)  │    │ (Standby)  │    │ (Standby)  │                         │
│  └────────────┘    └────────────┘    └────────────┘                         │
│        │                 │                 │                                 │
│        └─────────────────┴─────────────────┘                                 │
│                          │                                                   │
│              ┌───────────┴───────────┐                                       │
│              │    Vault Service      │                                       │
│              │  (vault.vault.svc)    │                                       │
│              └───────────┬───────────┘                                       │
└──────────────────────────┼──────────────────────────────────────────────────┘
                           │
           ┌───────────────┼───────────────┐
           │               │               │
           ▼               ▼               ▼
    ┌──────────────┐ ┌──────────────┐ ┌──────────────┐
    │ Vault Agent  │ │ Vault Agent  │ │   CSI        │
    │ Sidecar      │ │ Sidecar      │ │   Driver     │
    │ (Jenkins)    │ │ (Backstage)  │ │   Provider   │
    └──────────────┘ └──────────────┘ └──────────────┘
           │               │               │
           ▼               ▼               ▼
    ┌──────────────┐ ┌──────────────┐ ┌──────────────┐
    │  /vault/     │ │  /vault/     │ │   Mounted    │
    │  secrets/    │ │  secrets/    │ │   Volume     │
    └──────────────┘ └──────────────┘ └──────────────┘
```

## Components

| File                     | Purpose                                    |
| ------------------------ | ------------------------------------------ |
| `vault-application.yaml` | ArgoCD Application for Vault HA deployment |
| `vault-auth-config.yaml` | Kubernetes Auth method configuration       |
| `vault-policies.yaml`    | Access policies and service accounts       |
| `kustomization.yaml`     | Kustomize configuration                    |

## Quick Start

### 1. Deploy Vault

Vault is deployed automatically via ArgoCD when you apply the application manifest:

```bash
kubectl apply -f platform/apps/vault/vault-application.yaml
```

### 2. Initialize Vault

After deployment, initialize and unseal Vault:

```bash
# Initialize Vault (only once, save the unseal keys and root token securely!)
kubectl exec -it vault-0 -n vault -- vault operator init

# Unseal each Vault node (requires 3 of 5 unseal keys by default)
kubectl exec -it vault-0 -n vault -- vault operator unseal
kubectl exec -it vault-1 -n vault -- vault operator unseal
kubectl exec -it vault-2 -n vault -- vault operator unseal
```

### 3. Configure Kubernetes Auth

Apply the auth configuration after Vault is unsealed:

```bash
kubectl apply -k platform/apps/vault/

# Run the configuration script
kubectl exec -it vault-0 -n vault -- /bin/sh /vault/config/configure-vault.sh
```

## Developer Integration Guide

### Option 1: Vault Agent Sidecar (Recommended)

Add annotations to your Pod spec for automatic secret injection:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
spec:
  template:
    metadata:
      annotations:
        # Enable Vault Agent injection
        vault.hashicorp.com/agent-inject: "true"
        # Vault role for authentication
        vault.hashicorp.com/role: "platform-service"
        # Inject secret at /vault/secrets/db-creds
        vault.hashicorp.com/agent-inject-secret-db-creds: "secret/data/fawkes/databases/my-app"
        # Template for formatting (optional)
        vault.hashicorp.com/agent-inject-template-db-creds: |
          {{- with secret "secret/data/fawkes/databases/my-app" -}}
          DB_URL=postgresql://{{ .Data.data.username }}:{{ .Data.data.password }}@db:5432/mydb
          {{- end }}
    spec:
      serviceAccountName: vault-secrets-reader
      containers:
        - name: app
          image: my-app:latest
          # Secret available at /vault/secrets/db-creds
```

### Option 2: CSI Secret Store Driver

Use the CSI driver to mount secrets as volumes:

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
          mountPath: /mnt/secrets
          readOnly: true
  volumes:
    - name: secrets
      csi:
        driver: secrets-store.csi.k8s.io
        readOnly: true
        volumeAttributes:
          secretProviderClass: vault-database-creds
```

### Option 3: Direct API Access (CI/CD)

For Jenkins pipelines, use the Vault plugin or direct API calls:

```groovy
// In Jenkinsfile
withVault(
    configuration: [
        vaultUrl: 'http://vault.vault.svc:8200',
        vaultCredentialId: 'vault-approle'
    ],
    vaultSecrets: [
        [path: 'secret/data/fawkes/cicd/jenkins', secretValues: [
            [vaultKey: 'github_token', envVar: 'GITHUB_TOKEN']
        ]]
    ]
) {
    // Use GITHUB_TOKEN in your pipeline
    sh 'echo "Token available"'
}
```

## Secret Path Convention

Secrets are organized in Vault using the following path structure:

```text
secret/
└── data/
    └── fawkes/
        ├── core/               # Core platform services
        │   ├── backstage/
        │   ├── argocd/
        │   └── postgres/
        ├── cicd/               # CI/CD pipeline secrets
        │   ├── jenkins/
        │   └── harbor/
        ├── databases/          # Database credentials
        │   ├── sonarqube/
        │   ├── backstage/
        │   └── mattermost/
        ├── observability/      # Monitoring stack
        │   ├── grafana/
        │   └── prometheus/
        ├── apps/               # Application-specific secrets
        │   └── {app-name}/
        └── shared/             # Shared across services
            ├── github-token
            └── docker-registry
```

## Policies

| Policy                 | Bound Service Accounts    | Access                         |
| ---------------------- | ------------------------- | ------------------------------ |
| `platform-policy`      | All in `fawkes` namespace | Own namespace secrets + shared |
| `jenkins-policy`       | `jenkins`                 | CI/CD + apps + shared          |
| `backstage-policy`     | `backstage`               | Core/backstage + shared        |
| `database-policy`      | Database consumers        | Database credentials           |
| `observability-policy` | `grafana`, `prometheus`   | Observability + shared         |

## Secret Rotation

Vault Agent automatically detects secret changes and updates the injected files.
Applications reading from files will get updated secrets without pod restart.

For environment variable-based secrets, use a sidecar that watches for file
changes and restarts the application, or use the Reloader operator.

### Automatic Rotation Example

```yaml
annotations:
  # Keep the agent running to watch for changes
  vault.hashicorp.com/agent-pre-populate-only: "false"
  # Check for updates every 5 minutes
  vault.hashicorp.com/agent-cache-enable: "true"
  vault.hashicorp.com/agent-cache-listener-addr: "127.0.0.1:8100"
```

## HA Failover

The Vault cluster runs in HA mode with 3 replicas using Raft consensus:

- **Primary**: Handles all read/write operations
- **Standby**: Ready for automatic promotion if primary fails
- **RTO**: < 120 seconds for automatic failover

To test failover:

```bash
# Delete the primary pod
kubectl delete pod vault-0 -n vault

# Watch the logs for leader election
kubectl logs -f vault-1 -n vault
```

## Monitoring

Vault exposes Prometheus metrics at `/v1/sys/metrics`:

```yaml
# ServiceMonitor for Prometheus
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: vault
  namespace: vault
spec:
  selector:
    matchLabels:
      app.kubernetes.io/name: vault
  endpoints:
    - port: http
      path: /v1/sys/metrics
      params:
        format: [prometheus]
```

Key metrics to monitor:

- `vault_core_unsealed` - Vault seal status
- `vault_core_active` - Active node status
- `vault_token_count` - Token usage
- `vault_secret_lease_creation` - Secret access patterns

## Audit Logging

Vault audit logs are enabled and written to `/vault/audit/vault-audit.log`.
These logs capture all API requests for security compliance.

To view audit logs:

```bash
kubectl exec -it vault-0 -n vault -- cat /vault/audit/vault-audit.log
```

## Troubleshooting

### Vault is Sealed

```bash
# Check seal status
kubectl exec vault-0 -n vault -- vault status

# Unseal (requires 3 of 5 keys)
kubectl exec -it vault-0 -n vault -- vault operator unseal
```

### Agent Injection Not Working

1. Check injector pods are running:

   ```bash
   kubectl get pods -n vault -l app.kubernetes.io/name=vault-agent-injector
   ```

2. Verify webhook configuration:

   ```bash
   kubectl get mutatingwebhookconfiguration vault-agent-injector-cfg
   ```

3. Check pod annotations are correct
4. Verify service account has proper Vault role binding

### Authentication Failures

```bash
# Check Kubernetes auth configuration
kubectl exec vault-0 -n vault -- vault read auth/kubernetes/config

# List configured roles
kubectl exec vault-0 -n vault -- vault list auth/kubernetes/role
```

## Security Considerations

1. **Unseal Keys**: Store unseal keys securely (use auto-unseal with cloud KMS
   in production)
2. **Root Token**: Revoke root token after initial setup, use limited policies
3. **Audit Logs**: Enable and monitor audit logs for compliance
4. **Network Policies**: Restrict access to Vault API
5. **TLS**: Enable TLS for production deployments

## Related Documentation

- [ADR-009: Secrets Management](../../../docs/adr/ADR-009%20secrets%20managment.md)
- [HashiCorp Vault Documentation](https://developer.hashicorp.com/vault/docs)
- [Vault Agent Injector](https://developer.hashicorp.com/vault/docs/platform/k8s/injector)
- [CSI Provider](https://developer.hashicorp.com/vault/docs/platform/k8s/csi)
