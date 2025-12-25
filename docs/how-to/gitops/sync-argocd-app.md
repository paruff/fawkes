---
title: Sync an ArgoCD Application
description: Manual and automated synchronization of ArgoCD applications with Git
---

# Sync an ArgoCD Application

## Goal

Synchronize an ArgoCD Application to apply changes from Git to your Kubernetes cluster, either manually on-demand or by configuring automated sync policies.

## Prerequisites

Before you begin, ensure you have:

- [ ] An existing ArgoCD Application deployed
- [ ] ArgoCD CLI installed or access to the ArgoCD UI
- [ ] `kubectl` configured with access to the cluster
- [ ] Changes committed to your Git repository

## Steps

### Method 1: Manual Sync via ArgoCD UI

#### 1. Access ArgoCD UI

Navigate to the ArgoCD web interface:

```bash
# Get ArgoCD URL
echo "https://argocd.127.0.0.1.nip.io"

# Get admin password (if needed)
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d
```

#### 2. Locate Your Application

1. Log in to the ArgoCD UI
2. Find your application in the Applications list
3. Click on the application name to view details

#### 3. Trigger Synchronization

1. Click the **"SYNC"** button in the top toolbar
2. Review the sync options:
   - **Prune**: Delete resources not in Git
   - **Dry Run**: Preview changes without applying
   - **Apply Only**: Skip pre-sync hooks
3. Select resources to sync (or select all)
4. Click **"SYNCHRONIZE"**

#### 4. Monitor Sync Progress

Watch the application tile as resources are synchronized:

- Blue (pulsing): Sync in progress
- Green: Healthy and synced
- Yellow/Orange: Progressing
- Red: Failed or degraded

### Method 2: Manual Sync via ArgoCD CLI

#### 1. Sync Application

```bash
# Basic sync
argocd app sync my-service-dev

# Sync with prune (delete extra resources)
argocd app sync my-service-dev --prune

# Dry run to preview changes
argocd app sync my-service-dev --dry-run

# Sync specific resources only
argocd app sync my-service-dev --resource apps:Deployment:my-service
```

#### 2. Monitor Sync Progress

```bash
# Watch sync status in real-time
argocd app wait my-service-dev --timeout 300

# View sync operation details
argocd app get my-service-dev
```

### Method 3: Manual Sync via kubectl

```bash
# Trigger sync using kubectl patch
kubectl patch application my-service-dev -n argocd \
  --type merge \
  -p '{"operation":{"initiatedBy":{"username":"admin"},"sync":{}}}'

# Check sync status
kubectl get application my-service-dev -n argocd \
  -o jsonpath='{.status.sync.status}'
```

### Method 4: Enable Automated Sync

Configure your Application to automatically sync on Git changes:

#### 1. Update Application Manifest

Edit your ArgoCD Application manifest:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: my-service-dev
  namespace: argocd
spec:
  # ... other fields ...

  syncPolicy:
    automated:
      prune: true        # Automatically delete resources removed from Git
      selfHeal: true     # Automatically sync when cluster state drifts
      allowEmpty: false  # Prevent sync if Git directory is empty

    syncOptions:
      - CreateNamespace=true
      - PrunePropagationPolicy=foreground
      - PruneLast=true   # Prune after all resources are synced

    retry:
      limit: 5           # Retry failed syncs up to 5 times
      backoff:
        duration: 5s     # Initial retry delay
        factor: 2        # Exponential backoff multiplier
        maxDuration: 3m  # Maximum retry delay
```

#### 2. Apply the Updated Configuration

```bash
kubectl apply -f my-service-dev.yaml
```

#### 3. Verify Automated Sync is Enabled

```bash
argocd app get my-service-dev | grep "Sync Policy"
# Expected: "Sync Policy:        Automated (Prune)"
```

### Method 5: Sync with Hooks and Waves

For complex deployments, use sync phases and waves:

#### 1. Add Sync Wave Annotations

In your Kubernetes manifests, control sync order:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: database-config
  annotations:
    argocd.argoproj.io/sync-wave: "0"  # Sync first
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-service
  annotations:
    argocd.argoproj.io/sync-wave: "1"  # Sync after ConfigMap
```

#### 2. Add Sync Hooks

For tasks that run before or after sync:

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: database-migration
  annotations:
    argocd.argoproj.io/hook: PreSync     # Run before sync
    argocd.argoproj.io/hook-delete-policy: HookSucceeded
spec:
  template:
    spec:
      containers:
      - name: migrate
        image: my-app:latest
        command: ["./migrate-db.sh"]
      restartPolicy: Never
```

#### 3. Sync with Hooks

```bash
# Sync will automatically respect waves and hooks
argocd app sync my-service-dev
```

## Verification

### 1. Verify Sync Completed Successfully

```bash
# Check sync status
argocd app get my-service-dev

# Expected output includes:
# Sync Status:        Synced to main (abc123)
# Health Status:      Healthy
```

### 2. Verify Resource Changes Applied

```bash
# Compare Git commit with deployed version
argocd app manifests my-service-dev | kubectl diff -f -

# No output means cluster matches Git
```

### 3. Check Application Health

```bash
# View application health
kubectl get application my-service-dev -n argocd \
  -o jsonpath='{.status.health.status}'

# Expected: "Healthy"
```

### 4. Verify Pods are Running

```bash
# List pods in the namespace
kubectl get pods -n my-service-dev

# All pods should be Running/Completed
```

### 5. Test Automated Sync (if enabled)

```bash
# Make a change in Git (e.g., update image tag)
# Edit your deployment.yaml and commit

# Wait 1-3 minutes (default polling interval)
# Then verify ArgoCD detected and synced the change
argocd app get my-service-dev

# Check the "Synced to" commit SHA matches your latest commit
```

## Sync Policies Explained

### Automated Sync Options

| Option | Description | Use Case |
|--------|-------------|----------|
| `prune: true` | Delete resources removed from Git | Keep cluster clean, enforce Git as source of truth |
| `prune: false` | Keep resources not in Git | Safer for testing, prevents accidental deletion |
| `selfHeal: true` | Revert manual kubectl changes | Enforce GitOps, prevent configuration drift |
| `selfHeal: false` | Allow manual changes | Useful for debugging, manual hotfixes |
| `allowEmpty: false` | Prevent sync if Git path is empty | Safety check against accidental deletion |

### Sync Windows

Restrict when applications can sync (e.g., only during business hours):

```yaml
spec:
  syncPolicy:
    syncWindows:
    - kind: allow
      schedule: '0 9 * * 1-5'  # Mon-Fri, 9 AM
      duration: 8h             # 8-hour window
      applications:
      - my-service-dev
```

## Troubleshooting

### Sync Fails with "ComparisonError"

**Cause**: ArgoCD cannot generate manifests from your Git repository.

**Solution**:

```bash
# View detailed error
argocd app get my-service-dev

# Common causes:
# 1. Invalid Kustomize/Helm syntax
# 2. Missing files in Git
# 3. Incorrect path in Application spec

# Test manifest generation locally
kubectl kustomize overlays/dev
```

### Sync Stuck in "Progressing" State

**Cause**: Resources are deploying but not reaching healthy state.

**Solution**:

```bash
# Check resource status
argocd app resources my-service-dev

# View pod events
kubectl describe pods -n my-service-dev

# Check for image pull errors, CrashLoopBackOff
kubectl get events -n my-service-dev --sort-by='.lastTimestamp'
```

### Automated Sync Not Triggering

**Cause**: ArgoCD hasn't detected Git changes yet.

**Solution**:

```bash
# Force refresh application from Git
argocd app get my-service-dev --refresh

# Check last sync attempt time
argocd app get my-service-dev | grep "Last Sync"

# Verify webhook is configured (optional)
# For faster sync, configure Git webhook to ArgoCD
```

### Sync Fails Due to Resource Conflicts

**Cause**: Resource already exists (not managed by ArgoCD).

**Solution**:

```bash
# Option 1: Add ArgoCD annotation to existing resource
kubectl annotate <resource-type> <resource-name> -n <namespace> \
  argocd.argoproj.io/tracking-id=my-service-dev:/<resource-type>/<namespace>/<resource-name>

# Option 2: Delete existing resource and let ArgoCD recreate
kubectl delete <resource-type> <resource-name> -n <namespace>
argocd app sync my-service-dev
```

## Next Steps

After mastering ArgoCD sync:

- [Configure Ingress for External Access](../networking/configure-ingress-tls.md)
- [View DORA Metrics in DevLake](../observability/view-dora-metrics-devlake.md)
- [Troubleshoot Kyverno Policy Violations](../policy/troubleshoot-kyverno-violation.md)
- [Debug Deployment Failures](../../troubleshooting.md)

## Related Documentation

- [Onboard a Service to ArgoCD](onboard-service-argocd.md) - Create a new ArgoCD Application
- [ArgoCD Sync Phases Documentation](https://argo-cd.readthedocs.io/en/stable/user-guide/sync-waves/)
- [GitOps Pattern Explanation](../../explanation/index.md)
- [Green Belt Module: GitOps with ArgoCD](../../dojo/modules/green-belt/module-09-gitops-argocd.md)
