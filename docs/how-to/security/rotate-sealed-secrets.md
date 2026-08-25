---
title: Rotate Sealed Secrets
description: How to rotate secrets managed by Bitnami Sealed Secrets in Fawkes
---

# Rotate Sealed Secrets

This guide explains how to rotate secrets that are managed by Bitnami Sealed Secrets in Fawkes.

## Overview

Sealed Secrets rotation involves:
1. Generating new secret values
2. Re-sealing with the current public key
3. Updating the SealedSecret in Git
4. ArgoCD syncing the change
5. Controller decrypting the new value

## When to Rotate

| Secret Type | Frequency | Trigger |
|-------------|-----------|---------|
| Database passwords | Every 90 days | Scheduled rotation |
| API keys | Every 90 days or on breach | Scheduled or incident |
| TLS certificates | Every 90 days (automated) | cert-manager renewal |
| Service account tokens | Every 30 days | Scheduled rotation |
| Root credentials | Annually or on personnel change | Offboarding |

## Prerequisites

- Access to the cluster with Sealed Secrets controller
- `kubeseal` CLI installed
- Permissions to update the target namespace
- New secret values ready (generated or from provider)

## Rotation Process

### Method 1: Re-seal with New Values (Standard)

#### Step 1: Generate New Secret Values

```bash
# For passwords
NEW_PASSWORD=$(openssl rand -base64 32)

# For API keys - get from provider (e.g., GitHub, AWS, Stripe)
# For database - update in database first, then seal new password
```

#### Step 2: Create Updated Plaintext Secret

```bash
cat > my-secret-new.yaml <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: my-app-secret
  namespace: fawkes
type: Opaque
stringData:
  api-key: "sk-new-api-key-from-provider"
  database-password: "new-generated-password"
EOF
```

#### Step 3: Re-seal with Current Certificate

```bash
# Option A: Seal directly against cluster (recommended)
kubeseal --controller-name=sealed-secrets --controller-namespace=kube-system \
  --format yaml < my-secret-new.yaml > my-sealed-secret.yaml

# Option B: Use cached certificate (offline)
kubeseal --cert sealed-secrets-cert.pem --format yaml < my-secret-new.yaml > my-sealed-secret.yaml
```

#### Step 4: Commit and Push

```bash
git add platform/apps/my-app/secrets/my-sealed-secret.yaml
git commit -m "feat(secrets): Rotate my-app-secret credentials"
git push
```

#### Step 5: Verify Rotation

```bash
# Watch ArgoCD sync
argocd app wait my-app --sync --timeout 300

# Verify new secret in cluster
kubectl get secret my-app-secret -n fawkes -o yaml

# Check application health
kubectl logs -n fawkes deployment/my-app --tail=50
```

### Method 2: Controller Re-key Rotation (Key Compromise)

If the Sealed Secrets private key is compromised or needs rotation:

#### Step 1: Backup Current Key

```bash
# Backup the current private key
kubectl get secret -n kube-system -l sealedsecrets.bitnami.com/sealed-secrets-key \
  -o yaml > sealed-secrets-key-backup-$(date +%Y%m%d).yaml
```

#### Step 2: Generate New Key Pair

```bash
# Delete existing key (controller will generate new one)
kubectl delete secret -n kube-system -l sealedsecrets.bitnami.com/sealed-secrets-key

# Or use Helm to force rekey
helm upgrade sealed-secrets oci://registry-1.docker.io/bitnamicharts/sealed-secrets \
  --namespace kube-system \
  --set keyRenewalPeriod=0
```

#### Step 3: Fetch New Certificate

```bash
kubeseal --controller-name=sealed-secrets --controller-namespace=kube-system \
  --fetch-cert > sealed-secrets-cert-new.pem
```

#### Step 4: Re-seal ALL Secrets

```bash
# This MUST be done for ALL SealedSecrets in the cluster
#!/bin/bash
# reseal-all.sh

CERT="sealed-secrets-cert-new.pem"
SECRETS_DIR="platform/apps"

find "$SECRETS_DIR" -name "*-sealed.yaml" -o -name "*sealedsecret*.yaml" | while read sealed_file; do
    # Extract the original secret name/namespace from the SealedSecret
    name=$(yq '.metadata.name' "$sealed_file")
    namespace=$(yq '.metadata.namespace' "$sealed_file")
    
    # Get the decrypted secret from cluster
    kubectl get secret "$name" -n "$namespace" -o yaml > /tmp/original-secret.yaml
    
    # Re-seal with new certificate
    kubeseal --cert "$CERT" --format yaml < /tmp/original-secret.yaml > "$sealed_file"
    
    echo "Re-sealed: $sealed_file"
done
```

#### Step 5: Commit and Push All Changes

```bash
git add platform/apps/**/secrets/*-sealed.yaml
git commit -m "feat(secrets): Re-seal all secrets after controller re-key"
git push
```

## Zero-Downtime Rotation

For secrets used by running applications, use overlapping validity:

### Database Passwords

```bash
# 1. Add new password to database (keep old one working)
# ALTER USER myapp_user WITH PASSWORD 'new_password';

# 2. Update SealedSecret with BOTH passwords
cat > db-secret-rotation.yaml <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: myapp-db-credentials
  namespace: fawkes
type: Opaque
stringData:
  username: "myapp_user"
  password: "new_password"      # New primary
  password_old: "old_password"  # Keep for transition
  host: "postgres.fawkes.svc.cluster.local"
EOF

# 3. Deploy updated application to use new password
# 4. Monitor logs for old password usage (7 days)
# 5. Remove old password from database and SealedSecret
```

### API Keys

```bash
# 1. Generate new API key from provider
# 2. Add new key to application config (support multiple keys)
# 3. Deploy application
# 4. Revoke old key in provider dashboard
# 5. Remove old key from SealedSecret
```

## Automation

### Scheduled Rotation with CronJob

```yaml
# platform/apps/sealed-secrets/rotation-cronjob.yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: sealed-secrets-rotation
  namespace: kube-system
spec:
  schedule: "0 0 1 */3 *"  # Quarterly
  jobTemplate:
    spec:
      template:
        spec:
          serviceAccountName: sealed-secrets-rotator
          containers:
          - name: rotator
            image: bitnami/kubectl:latest
            command:
            - /bin/bash
            - -c
            - |
              # Rotation logic here
              # Use kubeseal to re-seal secrets
              # Commit changes via GitOps
          restartPolicy: OnFailure
```

### GitOps-Based Rotation

Use a GitOps workflow for rotation:

1. **Automation PR** - Bot creates PR with re-sealed secrets
2. **Review** - Security team reviews
3. **Merge** - ArgoCD applies

## Verification Checklist

After rotation, verify:

- [ ] ArgoCD shows synced status
- [ ] SealedSecret status shows `SealedSecretDecrypted` condition
- [ ] Application pods are healthy (no CrashLoopBackOff)
- [ ] Application logs show successful connections
- [ ] No authentication errors in logs
- [ ] Health endpoints return 200 OK

```bash
# Quick verification script
#!/bin/bash
APP_NAMESPACE="fawkes"
APP_NAME="my-app"

echo "=== ArgoCD Status ==="
argocd app get "$APP_NAME" --refresh

echo "=== SealedSecret Status ==="
kubectl get sealedsecret -n "$APP_NAMESPACE" -o wide

echo "=== Pod Status ==="
kubectl get pods -n "$APP_NAMESPACE" -l app="$APP_NAME"

echo "=== Recent Logs ==="
kubectl logs -n "$APP_NAMESPACE" deployment/"$APP_NAME" --tail=20 | grep -i "error\|auth\|connect"
```

## Rollback Procedure

If rotation causes issues:

```bash
# 1. Revert Git commit
git revert HEAD
git push

# 2. Or manually re-apply previous SealedSecret
kubectl apply -f previous-sealed-secret.yaml

# 3. Force ArgoCD sync
argocd app sync "$APP_NAME" --prune

# 4. Verify rollback
kubectl rollout status deployment/"$APP_NAME" -n "$APP_NAMESPACE"
```

## Troubleshooting

### Application Fails After Rotation

```bash
# 1. Check new secret value
kubectl get secret my-app-secret -n fawkes -o jsonpath='{.data.password}' | base64 -d

# 2. Test connectivity manually
kubectl run -it --rm test-connection --image=postgres:15 --restart=Never -- \
  psql -h postgres.fawkes.svc.cluster.local -U myapp_user -d myapp -c "SELECT 1"

# 3. If failed, revert (see Rollback Procedure)
```

### SealedSecret Stuck in "Not Decrypted"

```bash
# Check controller logs
kubectl logs -n kube-system deployment/sealed-secrets-controller

# Check SealedSecret events
kubectl describe sealedsecret my-app-secret -n fawkes

# Common causes:
# - Wrong scope (strict vs namespace-wide)
# - Certificate mismatch
# - Controller not running
```

### Certificate Mismatch

```bash
# Fetch current certificate and compare
kubeseal --controller-name=sealed-secrets --controller-namespace=kube-system \
  --fetch-cert > current-cert.pem

diff sealed-secrets-cert.pem current-cert.pem
# If different, re-seal with current certificate
```

## Related Documentation

- [Sealed Secrets Developer Guide](sealed-secrets-guide.md)
- [Sealed Secrets Backup Strategy](sealed-secrets-backup.md)
- [Rotate Vault Secrets](rotate-vault-secrets.md)
- [Secrets Management Overview](secrets-management.md)

---

*Last updated: 2025*
*Part of Fawkes security documentation*