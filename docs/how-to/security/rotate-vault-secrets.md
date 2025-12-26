---
title: Rotate Vault Secrets
description: Safely rotate secrets in HashiCorp Vault and update applications
---

# Rotate Vault Secrets

## Goal

Rotate a secret stored in HashiCorp Vault (such as a database password or API key) and ensure all applications using that secret are updated without downtime.

## Prerequisites

Before you begin, ensure you have:

- [ ] HashiCorp Vault deployed and configured
- [ ] Vault CLI installed (`vault` command)
- [ ] Authentication credentials for Vault (token or role)
- [ ] Knowledge of which secret to rotate and which applications use it
- [ ] Applications configured with Vault Agent or External Secrets Operator

## Steps

### 1. Authenticate to Vault

#### Login with Token

```bash
# Set Vault address
export VAULT_ADDR="https://vault.127.0.0.1.nip.io"

# Login with token
vault login <your-vault-token>

# Verify authentication
vault token lookup
```

#### Login with Kubernetes Service Account (Recommended)

```bash
# Login using Kubernetes auth
vault login -method=kubernetes role=my-app-role

# Verify authentication
vault token lookup
```

### 2. Identify the Secret to Rotate

#### List Existing Secrets

```bash
# List secret engines
vault secrets list

# List secrets in a KV path
vault kv list secret/database

# Read current secret value (to verify)
vault kv get secret/database/postgres-credentials
```

Example output:

```text
====== Data ======
Key         Value
---         -----
username    dbuser
password    oldPassword123
host        postgres.database.svc.cluster.local
port        5432
```

### 3. Identify Dependent Applications

#### Find Pods Using the Secret

```bash
# Search for pods with Vault annotations
kubectl get pods --all-namespaces -o json | \
  jq '.items[] | select(.metadata.annotations["vault.hashicorp.com/agent-inject-secret-db"] != null) | .metadata.name'

# Or search by External Secrets
kubectl get externalsecret --all-namespaces -o json | \
  jq '.items[] | select(.spec.data[].remoteRef.key == "secret/database/postgres-credentials")'
```

### 4. Rotate the Secret

#### Method 1: Update Secret in Vault (Simple Rotation)

Update the secret value in Vault:

```bash
# Read current secret
vault kv get -format=json secret/database/postgres-credentials > current-secret.json

# Generate new password
NEW_PASSWORD=$(openssl rand -base64 32)

# Update secret with new password
vault kv put secret/database/postgres-credentials \
  username=dbuser \
  password="${NEW_PASSWORD}" \
  host=postgres.database.svc.cluster.local \
  port=5432

# Verify new secret
vault kv get secret/database/postgres-credentials
```

#### Method 2: Use Vault Database Secrets Engine (Dynamic Rotation)

For database credentials, use Vault's database secrets engine:

```bash
# Configure database connection
vault write database/config/postgres \
  plugin_name=postgresql-database-plugin \
  connection_url="postgresql://{{username}}:{{password}}@postgres.database.svc.cluster.local:5432/mydb" \
  allowed_roles="my-app-role" \
  username="vault-admin" \
  password="admin-password"

# Create role for application
vault write database/roles/my-app-role \
  db_name=postgres \
  creation_statements="CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; \
    GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO \"{{name}}\";" \
  default_ttl="1h" \
  max_ttl="24h"

# Rotate root credentials
vault write -force database/rotate-root/postgres
```

### 5. Update the External System

#### Update Database Password

```bash
# Connect to database as admin
kubectl exec -it -n database postgres-0 -- psql -U postgres

# Change password for application user
ALTER USER dbuser WITH PASSWORD 'newPassword123';

# Verify connection with new password
psql -h postgres.database.svc.cluster.local -U dbuser -d mydb -c "SELECT 1"
```

#### Update Third-Party API Key

For API keys, follow the provider's process:

1. Log in to the third-party service (e.g., Stripe, SendGrid)
2. Generate a new API key
3. Update the key in Vault (see Step 4)
4. Revoke the old API key (after verification in Step 7)

### 6. Trigger Application Secret Refresh

#### Method A: Vault Agent Auto-Refresh (Recommended)

If using Vault Agent injector, secrets auto-refresh:

```yaml
# Vault Agent annotation in Pod spec
annotations:
  vault.hashicorp.com/agent-inject: "true"
  vault.hashicorp.com/role: "my-app-role"
  vault.hashicorp.com/agent-inject-secret-db: "secret/database/postgres-credentials"
  vault.hashicorp.com/agent-inject-template-db: |
    {{- with secret "secret/database/postgres-credentials" -}}
    export DB_PASSWORD="{{ .Data.data.password }}"
    {{- end }}
```

Wait for Vault Agent to refresh (default: 5 minutes) or force refresh:

```bash
# Restart pods to trigger immediate refresh
kubectl rollout restart deployment/my-app -n my-namespace
```

#### Method B: External Secrets Operator Refresh

If using External Secrets Operator:

```bash
# Check External Secret refresh interval
kubectl get externalsecret my-app-db-secret -n my-namespace -o yaml | grep refreshInterval

# Force immediate refresh by annotating
kubectl annotate externalsecret my-app-db-secret -n my-namespace \
  force-sync="$(date +%s)" --overwrite

# Wait for sync (usually 1-2 minutes)
kubectl get externalsecret my-app-db-secret -n my-namespace -w
```

#### Method C: Manual Pod Restart

If secrets are mounted as environment variables (not recommended for rotation):

```bash
# Restart deployment to pick up new secret
kubectl rollout restart deployment/my-app -n my-namespace

# Wait for rollout to complete
kubectl rollout status deployment/my-app -n my-namespace
```

#### Method D: Reloader (Automated Restart)

If using Reloader for automatic pod restarts on secret changes:

```yaml
# Deployment annotation to enable Reloader
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
  annotations:
    reloader.stakater.com/auto: "true"
```

Reloader automatically restarts pods when secrets change.

### 7. Verify Secret Rotation

#### Verify Vault Secret Updated

```bash
# Confirm new secret value in Vault
vault kv get secret/database/postgres-credentials

# Check version history
vault kv metadata get secret/database/postgres-credentials
```

#### Verify Applications Using New Secret

```bash
# Check pod logs for successful connection
kubectl logs -n my-namespace deployment/my-app --tail=50 | grep -i "database"

# Verify no authentication errors
kubectl logs -n my-namespace deployment/my-app --tail=100 | grep -i "auth"

# Test application endpoint
curl https://my-app.127.0.0.1.nip.io/health
```

#### Verify Database Connection

```bash
# Check active database connections
kubectl exec -it -n database postgres-0 -- psql -U postgres -c \
  "SELECT usename, application_name, client_addr FROM pg_stat_activity WHERE usename = 'dbuser';"

# Should show connections from your application pods
```

## Verification

### 1. Verify Secret Rotation Completed

```bash
# Get secret version
vault kv metadata get secret/database/postgres-credentials

# Confirm version incremented and updated timestamp matches rotation time
```

Expected output:

```text
======= Metadata =======
Key                Value
---                -----
created_time       2024-12-06T10:30:00Z
current_version    2
oldest_version     1
updated_time       2024-12-06T14:45:00Z  ← Should match rotation time
```

### 2. Verify Application Health

```bash
# Check deployment status
kubectl get deployment my-app -n my-namespace

# All pods should be Running
kubectl get pods -n my-namespace -l app=my-app

# Check for CrashLoopBackOff or authentication errors
kubectl describe pods -n my-namespace -l app=my-app | grep -A 10 Events
```

### 3. Test Application Functionality

```bash
# Port-forward to application
kubectl port-forward -n my-namespace svc/my-app 8080:80

# Test endpoints requiring database access
curl http://localhost:8080/api/users
curl http://localhost:8080/api/orders

# Should return data (not 401/500 errors)
```

### 4. Verify No Errors in Logs

```bash
# Check for authentication errors
kubectl logs -n my-namespace -l app=my-app --since=10m | grep -i "authentication\|password\|credential"

# No errors should appear after rotation time
```

### 5. Revoke Old Secret (if applicable)

After confirming the new secret works:

```bash
# For database: Drop old user or revoke permissions
kubectl exec -it -n database postgres-0 -- psql -U postgres -c \
  "REVOKE ALL PRIVILEGES ON DATABASE mydb FROM old_user;"

# For API keys: Revoke old key in third-party service
# (Do this manually via provider's dashboard)

# For Vault dynamic secrets: Old leases auto-expire based on TTL
vault list sys/leases/lookup/database/creds/my-app-role
```

## Secret Rotation Best Practices

### 1. Rotation Frequency

| Secret Type            | Recommended Frequency                       |
| ---------------------- | ------------------------------------------- |
| Database passwords     | Every 90 days                               |
| API keys               | Every 90 days or on breach                  |
| TLS certificates       | Every 90 days (automated with cert-manager) |
| Service account tokens | Every 30 days                               |
| Root credentials       | Annually or on personnel change             |

### 2. Zero-Downtime Rotation

Use overlapping validity periods:

1. Add new secret alongside old secret
2. Deploy applications to accept both secrets
3. Monitor for old secret usage
4. Revoke old secret after no usage for 7 days

### 3. Automate Rotation

Configure automatic rotation:

```bash
# Vault database secrets engine handles automatic rotation
vault write database/config/postgres \
  password_policy="complex-password-policy" \
  rotation_period="2160h"  # 90 days

# Set up cron job for manual secrets
kubectl create cronjob rotate-api-keys \
  --schedule="0 0 1 */3 *" \  # First day of every quarter
  --image=vault:latest \
  -- vault kv put secret/api-keys/stripe api_key=<new-key>
```

## Troubleshooting

### Applications Fail After Rotation

**Cause**: Applications haven't refreshed secret or new secret is invalid.

**Solution**:

```bash
# Verify new secret is valid
vault kv get secret/database/postgres-credentials

# Test database connection manually
kubectl run -it --rm test-db-connection --image=postgres:15 --restart=Never -- \
  psql -h postgres.database.svc.cluster.local -U dbuser -d mydb -c "SELECT 1"

# If connection fails, revert secret
vault kv rollback -version=1 secret/database/postgres-credentials

# Restart pods to pick up reverted secret
kubectl rollout restart deployment/my-app -n my-namespace
```

### Vault Agent Not Refreshing

**Cause**: Vault Agent lease renewal failing or annotation missing.

**Solution**:

```bash
# Check Vault Agent sidecar logs
kubectl logs -n my-namespace my-app-pod vault-agent

# Verify annotations
kubectl get pod my-app-pod -n my-namespace -o yaml | grep vault.hashicorp.com

# Restart pod to force re-injection
kubectl delete pod my-app-pod -n my-namespace
```

### External Secrets Not Syncing

**Cause**: External Secrets Operator not polling or insufficient permissions.

**Solution**:

```bash
# Check External Secrets Operator logs
kubectl logs -n external-secrets-operator deployment/external-secrets-operator

# Verify ExternalSecret status
kubectl get externalsecret my-app-db-secret -n my-namespace -o yaml

# Check sync status
kubectl describe externalsecret my-app-db-secret -n my-namespace | grep -A 5 Status

# Force sync
kubectl annotate externalsecret my-app-db-secret -n my-namespace \
  force-sync="$(date +%s)" --overwrite
```

## Next Steps

After rotating secrets:

- [Configure Ingress TLS](../networking/configure-ingress-tls.md) - Rotate TLS certificates
- [Troubleshoot Kyverno Violations](../policy/troubleshoot-kyverno-violation.md) - Enforce secret policies
- [Security Documentation](../../security.md) - Review security best practices
- [Vault Configuration Reference](../../reference/index.md) - Advanced Vault setup

## Related Documentation

- [HashiCorp Vault](../../platform/apps/vault/README.md) - Vault setup guide
- [Security](../../security.md) - Platform security practices
- [External Secrets Operator](https://external-secrets.io/) - External documentation
- [Vault Database Secrets Engine](https://developer.hashicorp.com/vault/docs/secrets/databases) - Vault docs
