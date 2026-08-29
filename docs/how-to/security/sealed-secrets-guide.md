---
title: Sealed Secrets Developer Guide
description: How to use Bitnami Sealed Secrets for GitOps secret management in Fawkes
---

# Sealed Secrets Developer Guide

This guide explains how to use Bitnami Sealed Secrets to manage secrets securely in Git while maintaining a GitOps workflow.

## Overview

**Sealed Secrets** allows you to encrypt Kubernetes Secrets into `SealedSecret` resources that can be safely committed to Git. Only the Sealed Secrets controller running in your cluster can decrypt them.

```
Plaintext Secret -> kubeseal (encrypt) -> SealedSecret (Git-safe) -> Controller (decrypt) -> Secret (in cluster)
```

## Prerequisites

- Kubernetes cluster with Sealed Secrets controller deployed
- `kubeseal` CLI tool installed locally
- Access to the cluster (kubectl configured)

## Installation

### Install kubeseal CLI

```bash
# macOS
brew install kubeseal

# Linux
curl -OL "https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.28.0/kubeseal-0.28.0-linux-amd64.tar.gz"
tar -xzf kubeseal-0.28.0-linux-amd64.tar.gz
sudo mv kubeseal /usr/local/bin/

# Verify installation
kubeseal --version
```

### Verify Controller Deployment

```bash
# Check if Sealed Secrets controller is running
kubectl get pods -n kube-system -l app.kubernetes.io/name=sealed-secrets

# Check CRD is installed
kubectl get crd sealedsecrets.bitnami.com
```

## Basic Usage

### 1. Create a Plaintext Secret (Locally, Never Commit)

```bash
# Create a secret YAML (do NOT commit this file)
cat > my-secret.yaml <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: my-app-secret
  namespace: fawkes
type: Opaque
stringData:
  api-key: "sk-actual-secret-value"
  database-password: "super-secret-password"
EOF
```

### 2. Seal the Secret

```bash
# Fetch the public key from the cluster and seal
kubeseal --controller-name=sealed-secrets --controller-namespace=kube-system \
  --format yaml < my-secret.yaml > my-sealed-secret.yaml
```

The output `my-sealed-secret.yaml` is safe to commit to Git.

### 3. Apply the SealedSecret

```bash
# Apply to cluster (ArgoCD will also sync this)
kubectl apply -f my-sealed-secret.yaml
```

### 4. Verify Decryption

```bash
# Check the controller created the Secret
kubectl get secret my-app-secret -n fawkes -o yaml
```

## Sealing from a File

```bash
# Seal with explicit namespace and name
kubeseal --controller-name=sealed-secrets --controller-namespace=kube-system \
  --namespace fawkes --name my-app-secret \
  --format yaml < my-secret.yaml > my-sealed-secret.yaml
```

## Sealing Multiple Secrets

```bash
# Create a script to seal multiple secrets
#!/bin/bash
# seal-all.sh

SECRETS_DIR="secrets/plaintext"
OUTPUT_DIR="secrets/sealed"

mkdir -p "$OUTPUT_DIR"

for secret_file in "$SECRETS_DIR"/*.yaml; do
    basename=$(basename "$secret_file" .yaml)
    kubeseal --controller-name=sealed-secrets --controller-namespace=kube-system \
      --format yaml < "$secret_file" > "$OUTPUT_DIR/${basename}-sealed.yaml"
done
```

## Advanced Usage

### Using a Certificate File (Offline Sealing)

```bash
# Fetch certificate once
kubeseal --controller-name=sealed-secrets --controller-namespace=kube-system \
  --fetch-cert > sealed-secrets-cert.pem

# Seal using certificate (no cluster access needed)
kubeseal --cert sealed-secrets-cert.pem --format yaml < my-secret.yaml > my-sealed-secret.yaml
```

### Scope: Strict (Default) vs Namespace-Wide vs Cluster-Wide

```bash
# Strict scope (default) - only works for exact name/namespace
kubeseal --scope strict ...

# Namespace-wide - can be unsealed in any secret with same name in namespace
kubeseal --scope namespace-wide ...

# Cluster-wide - can be unsealed anywhere in cluster
kubeseal --scope cluster-wide ...
```

### Adding Labels and Annotations

```bash
kubeseal --controller-name=sealed-secrets --controller-namespace=kube-system \
  --format yaml \
  --labels 'app=my-app,component=api,managed-by=sealed-secrets' \
  --annotations 'argocd.argoproj.io/sync-wave="10"' \
  < my-secret.yaml > my-sealed-secret.yaml
```

## Integration with Fawkes

### Directory Structure

```
platform/apps/
+-- my-app/
|   +-- deployment.yaml
|   +-- service.yaml
|   +-- kustomization.yaml
|   +-- secrets/
|       +-- my-app-secrets-sealed.yaml    # Committed to Git
|       +-- .gitignore                    # Ignore plaintext secrets
```

### Kustomization Integration

```yaml
# kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - deployment.yaml
  - service.yaml
  - secrets/my-app-secrets-sealed.yaml
```

### ArgoCD Sync Waves

```yaml
# In SealedSecret metadata
metadata:
  annotations:
    argocd.argoproj.io/sync-wave: "10"  # Deploy after CRDs, before apps
```

## Common Patterns

### Database Credentials

```yaml
# Plaintext (never commit)
apiVersion: v1
kind: Secret
metadata:
  name: myapp-db-credentials
  namespace: fawkes
type: Opaque
stringData:
  username: "myapp_user"
  password: "actual-db-password"
  host: "postgres.fawkes.svc.cluster.local"
  port: "5432"
  database: "myapp"
```

```yaml
# Sealed (commit this)
apiVersion: bitnami.com/v1alpha1
kind: SealedSecret
metadata:
  name: myapp-db-credentials
  namespace: fawkes
spec:
  encryptedData:
    username: AgBy3i4OJSWK+PiTySYZZA9rO...
    password: AgBy3i4OJSWK+PiTySYZZA9rO...
    host: AgBy3i4OJSWK+PiTySYZZA9rO...
    port: AgBy3i4OJSWK+PiTySYZZA9rO...
    database: AgBy3i4OJSWK+PiTySYZZA9rO...
  template:
    metadata:
      name: myapp-db-credentials
      namespace: fawkes
      labels:
        app: myapp
        component: database
    type: Opaque
```

### TLS Certificates

```bash
# Seal TLS cert/key pair
kubeseal --controller-name=sealed-secrets --controller-namespace=kube-system \
  --format yaml \
  --from-file=tls.crt=./cert.pem \
  --from-file=tls.key=./key.pem \
  > tls-sealed-secret.yaml
```

### Docker Registry Credentials

```bash
# Create dockerconfigjson secret
kubectl create secret docker-registry my-registry-secret \
  --docker-server=registry.example.com \
  --docker-username=user \
  --docker-password=password \
  --docker-email=email@example.com \
  --dry-run=client -o yaml > docker-secret.yaml

# Seal it
kubeseal --controller-name=sealed-secrets --controller-namespace=kube-system \
  --format yaml < docker-secret.yaml > docker-sealed-secret.yaml
```

## Workflow in Fawkes

### For Developers

1. **Create plaintext secret locally** (in a gitignored directory)
2. **Seal it** using `kubeseal` against the cluster
3. **Commit the SealedSecret** to the appropriate `platform/apps/<app>/secrets/` directory
4. **Create PR** - CI validates the SealedSecret format
5. **Merge** - ArgoCD syncs and controller decrypts

### CI Validation

The pipeline validates SealedSecrets:

```groovy
stage('Validate SealedSecrets') {
    steps {
        container('kubectl') {
            sh '''
            # Validate all SealedSecrets can be parsed
            find platform/apps -name "*-sealed.yaml" -o -name "*sealedsecret*.yaml" | while read f; do
                kubectl apply --dry-run=client -f "$f" || exit 1
            done
            '''
        }
    }
}
```

## Troubleshooting

### "Secret not found" after applying SealedSecret

```bash
# Check controller logs
kubectl logs -n kube-system -l app.kubernetes.io/name=sealed-secrets

# Check SealedSecret status
kubectl get sealedsecret my-app-secret -n fawkes -o yaml
```

### "Invalid scope" error

```bash
# Re-seal with correct scope
kubeseal --scope strict --controller-name=sealed-secrets --controller-namespace=kube-system \
  --format yaml < my-secret.yaml > my-sealed-secret.yaml
```

### Certificate expired / controller rekeyed

```bash
# Fetch new certificate
kubeseal --controller-name=sealed-secrets --controller-namespace=kube-system \
  --fetch-cert > sealed-secrets-cert.pem

# Re-seal all secrets
./seal-all.sh
```

## Security Best Practices

1. **Never commit plaintext secrets** - Use `.gitignore` for local secret files
2. **Use strict scope** (default) for production secrets
3. **Rotate secrets regularly** - See [Rotation Guide](rotate-sealed-secrets.md)
4. **Backup the sealing key** - See [Backup Strategy](sealed-secrets-backup.md)
5. **Limit controller permissions** - Use RBAC to restrict who can create SealedSecrets
6. **Monitor decryption failures** - Alert on SealedSecret status conditions

## Related Documentation

- [Sealed Secrets Rotation](rotate-sealed-secrets.md)
- [Sealed Secrets Backup Strategy](sealed-secrets-backup.md)
- [Secrets Management Overview](secrets-management.md)
- [Bitnami Sealed Secrets Docs](https://github.com/bitnami-labs/sealed-secrets)

---

*Last updated: 2025*
*Part of Fawkes security documentation*