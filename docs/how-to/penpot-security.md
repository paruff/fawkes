# Penpot Security Configuration

## Secret Management

### Default Placeholder Values

All secrets in the Penpot deployment use placeholder values prefixed with `CHANGE_ME_`. These **MUST** be changed before deploying to any environment.

### Secrets to Configure

1. **Database Password** (`platform/apps/postgresql/db-penpot-credentials.yaml`)
   - Location: `stringData.password`
   - Default: `CHANGE_ME_penpot_db_password`
   - Requirements: Minimum 16 characters, alphanumeric + special chars

2. **Penpot Secret Key** (`platform/apps/penpot/deployment.yaml`)
   - Location: `penpot-secrets.stringData.PENPOT_SECRET_KEY`
   - Default: `CHANGE_ME_penpot_secret_key_min_16_chars`
   - Requirements: Minimum 16 characters, used for session encryption

3. **Database Connection String** (`platform/apps/penpot/deployment.yaml`)
   - Location: `penpot-secrets.stringData.PENPOT_DATABASE_URI`
   - Default: Contains `CHANGE_ME_penpot_db_password`
   - Must match password from db-penpot-credentials.yaml

### Quick Setup for Local/Dev

```bash
# Generate random password
PASSWORD=$(openssl rand -base64 24)

# Update database credentials
kubectl create secret generic penpot-db-credentials \
  --from-literal=username=penpot \
  --from-literal=password="$PASSWORD" \
  -n fawkes \
  --dry-run=client -o yaml | kubectl apply -f -

# Generate secret key
SECRET_KEY=$(openssl rand -base64 32)

# Update Penpot secrets
kubectl create secret generic penpot-secrets \
  --from-literal=PENPOT_DATABASE_URI="postgresql://penpot:$PASSWORD@penpot-db-rw.fawkes.svc:5432/penpot" \
  --from-literal=PENPOT_REDIS_URI="redis://penpot-redis.fawkes.svc:6379/0" \
  --from-literal=PENPOT_SECRET_KEY="$SECRET_KEY" \
  -n fawkes \
  --dry-run=client -o yaml | kubectl apply -f -
```

### Production Setup with External Secrets Operator

For production environments, use External Secrets Operator to pull credentials from a secret manager (AWS Secrets Manager, Azure Key Vault, HashiCorp Vault, etc.).

#### Example: AWS Secrets Manager

```yaml
# Create secrets in AWS Secrets Manager first
# aws secretsmanager create-secret --name penpot/database-password --secret-string "your-strong-password"
# aws secretsmanager create-secret --name penpot/secret-key --secret-string "your-secret-key"

---
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: penpot-db-credentials
  namespace: fawkes
spec:
  secretStoreRef:
    name: aws-secrets-manager
    kind: ClusterSecretStore
  target:
    name: penpot-db-credentials
    template:
      type: kubernetes.io/basic-auth
  data:
    - secretKey: username
      remoteRef:
        key: penpot/database-username
    - secretKey: password
      remoteRef:
        key: penpot/database-password
---
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: penpot-secrets
  namespace: fawkes
spec:
  secretStoreRef:
    name: aws-secrets-manager
    kind: ClusterSecretStore
  target:
    name: penpot-secrets
  data:
    - secretKey: PENPOT_DATABASE_URI
      remoteRef:
        key: penpot/database-uri
    - secretKey: PENPOT_REDIS_URI
      remoteRef:
        key: penpot/redis-uri
    - secretKey: PENPOT_SECRET_KEY
      remoteRef:
        key: penpot/secret-key
```

#### Example: Azure Key Vault

```yaml
---
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: penpot-db-credentials
  namespace: fawkes
spec:
  secretStoreRef:
    name: azure-keyvault
    kind: ClusterSecretStore
  target:
    name: penpot-db-credentials
    template:
      type: kubernetes.io/basic-auth
  data:
    - secretKey: username
      remoteRef:
        key: penpot-database-username
    - secretKey: password
      remoteRef:
        key: penpot-database-password
---
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: penpot-secrets
  namespace: fawkes
spec:
  secretStoreRef:
    name: azure-keyvault
    kind: ClusterSecretStore
  target:
    name: penpot-secrets
  data:
    - secretKey: PENPOT_DATABASE_URI
      remoteRef:
        key: penpot-database-uri
    - secretKey: PENPOT_REDIS_URI
      remoteRef:
        key: penpot-redis-uri
    - secretKey: PENPOT_SECRET_KEY
      remoteRef:
        key: penpot-secret-key
```

### Security Best Practices

1. **Never commit real secrets to Git**
   - Always use placeholder values (CHANGE_ME_*)
   - Use External Secrets Operator for production

2. **Rotate secrets regularly**
   - Database passwords: Every 90 days
   - Secret keys: Every 180 days
   - Use automated rotation where possible

3. **Use strong passwords**
   - Minimum 16 characters
   - Mix of uppercase, lowercase, numbers, special characters
   - Use password generator: `openssl rand -base64 32`

4. **Restrict secret access**
   - Use Kubernetes RBAC to limit who can read secrets
   - Enable audit logging for secret access
   - Monitor for unauthorized access attempts

5. **Encrypt secrets at rest**
   - Enable encryption at rest in Kubernetes
   - Use encrypted storage for secret manager

### Validation

Check that secrets are configured correctly:

```bash
# Verify placeholder values are not in use (should return nothing)
kubectl get secret penpot-secrets -n fawkes -o yaml | grep "CHANGE_ME_"
kubectl get secret penpot-db-credentials -n fawkes -o yaml | grep "CHANGE_ME_"

# If either command returns results, secrets are NOT properly configured!
```

### Troubleshooting

#### Penpot fails to start with authentication errors

**Symptom**: Backend pod logs show database authentication failures

**Solution**: Verify database password matches in both secrets:
```bash
# Get password from db credentials
kubectl get secret penpot-db-credentials -n fawkes -o jsonpath='{.data.password}' | base64 -d

# Get password from connection string
kubectl get secret penpot-secrets -n fawkes -o jsonpath='{.data.PENPOT_DATABASE_URI}' | base64 -d
```

The passwords must match!

#### Secret key errors

**Symptom**: Penpot backend logs show "Invalid secret key" or session errors

**Solution**: Ensure PENPOT_SECRET_KEY is at least 16 characters:
```bash
kubectl get secret penpot-secrets -n fawkes -o jsonpath='{.data.PENPOT_SECRET_KEY}' | base64 -d | wc -c
```

Should return at least 16.

## Related Documentation

- [Access Controls](./penpot-access-controls.md)
- [Deployment Guide](../apps/penpot/README.md)
- [External Secrets Operator](../apps/external-secrets/README.md)

## Support

For security issues, contact: security@fawkes.io

**Do NOT post secrets or passwords in GitHub issues or public channels!**
