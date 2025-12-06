---
title: Onboard a Service to ArgoCD
description: Step-by-step guide to deploy a new microservice using ArgoCD and GitOps
---

# Onboard a Service to ArgoCD

## Goal

Deploy a new microservice to the Fawkes platform using ArgoCD's GitOps workflow, ensuring the service is automatically synchronized from your Git repository.

## Prerequisites

Before you begin, ensure you have:

- [ ] Git repository containing your service's Kubernetes manifests or Helm chart
- [ ] Access to the `platform-root` repository with write permissions
- [ ] `kubectl` configured with access to the target Kubernetes cluster
- [ ] ArgoCD CLI installed (optional, for CLI-based workflow)
- [ ] Basic understanding of Kubernetes resources (Deployments, Services, ConfigMaps)

## Steps

### 1. Prepare Your Service Manifests

Organize your Kubernetes manifests in your Git repository:

```text
my-service/
├── base/
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── configmap.yaml
│   └── kustomization.yaml
└── overlays/
    ├── dev/
    │   └── kustomization.yaml
    ├── staging/
    │   └── kustomization.yaml
    └── production/
        └── kustomization.yaml
```

**Example `base/kustomization.yaml`:**

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - deployment.yaml
  - service.yaml
  - configmap.yaml

commonLabels:
  app: my-service
  component: backend
```

### 2. Create ArgoCD Application Manifest

Create a new ArgoCD Application manifest in the `platform-root` repository:

**File:** `platform-root/manifests/argocd/apps/my-service-dev.yaml`

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: my-service-dev
  namespace: argocd
  # Add finalizer to ensure proper cleanup
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: default
  
  # Source: Your service Git repository
  source:
    repoURL: https://github.com/your-org/my-service.git
    targetRevision: main
    path: overlays/dev
  
  # Destination: Target cluster and namespace
  destination:
    server: https://kubernetes.default.svc
    namespace: my-service-dev
  
  # Sync policy: Automatic synchronization
  syncPolicy:
    automated:
      prune: true        # Delete resources that are no longer in Git
      selfHeal: true     # Force sync when cluster state deviates
      allowEmpty: false
    syncOptions:
      - CreateNamespace=true  # Auto-create namespace if it doesn't exist
    retry:
      limit: 5
      backoff:
        duration: 5s
        factor: 2
        maxDuration: 3m
  
  # Health assessment
  ignoreDifferences:
    - group: apps
      kind: Deployment
      jsonPointers:
        - /spec/replicas  # Ignore replica count changes (for HPA)
```

### 3. Add Application to Kustomization

Add your new Application to the ArgoCD apps kustomization:

**File:** `platform-root/manifests/argocd/apps/kustomization.yaml`

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - existing-app-1.yaml
  - existing-app-2.yaml
  - my-service-dev.yaml  # Add this line
```

### 4. Commit and Push to Git

```bash
# Navigate to platform-root repository
cd platform-root

# Add the new Application manifest
git add manifests/argocd/apps/my-service-dev.yaml
git add manifests/argocd/apps/kustomization.yaml

# Commit with descriptive message
git commit -m "feat: onboard my-service to ArgoCD (dev environment)"

# Push to remote
git push origin main
```

### 5. Wait for ArgoCD Sync

ArgoCD automatically detects changes in the `platform-root` repository. Wait 1-3 minutes for the sync.

Alternatively, trigger manual sync:

```bash
# Using ArgoCD CLI
argocd app sync argocd/my-service-dev

# Or using kubectl
kubectl patch app my-service-dev -n argocd \
  --type merge \
  -p '{"operation":{"initiatedBy":{"username":"admin"},"sync":{}}}'
```

### 6. Monitor Deployment Progress

Watch the deployment status:

```bash
# View ArgoCD Application status
argocd app get my-service-dev

# Watch pod creation
kubectl get pods -n my-service-dev --watch

# Check ArgoCD sync status
kubectl get application my-service-dev -n argocd -o jsonpath='{.status.sync.status}'
```

## Verification

Verify your service is successfully onboarded and healthy:

### 1. Check ArgoCD Application Status

```bash
argocd app get my-service-dev
```

Expected output:

```text
Name:               my-service-dev
Project:            default
Server:             https://kubernetes.default.svc
Namespace:          my-service-dev
URL:                https://argocd.127.0.0.1.nip.io/applications/my-service-dev
Repo:               https://github.com/your-org/my-service.git
Target:             main
Path:               overlays/dev
SyncWindow:         Sync Allowed
Sync Policy:        Automated (Prune)
Sync Status:        Synced to main (abc123)
Health Status:      Healthy
```

### 2. Verify Application Health in ArgoCD UI

1. Navigate to ArgoCD UI: `https://argocd.127.0.0.1.nip.io`
2. Log in with your credentials
3. Find your application `my-service-dev`
4. Verify:
   - **Sync Status**: `Synced` (green checkmark)
   - **Health Status**: `Healthy` (green heart icon)
   - All resources show green status

### 3. Test Service Endpoints

```bash
# Port-forward to test the service locally
kubectl port-forward -n my-service-dev svc/my-service 8080:80

# Test the endpoint
curl http://localhost:8080/health

# Expected: HTTP 200 OK with health check response
```

### 4. Verify GitOps Workflow

Test the GitOps workflow by making a change:

```bash
# In your service repository, update an environment variable
# Edit overlays/dev/kustomization.yaml

git add .
git commit -m "test: update environment variable"
git push origin main

# Wait 1-3 minutes and verify ArgoCD auto-synced
argocd app get my-service-dev
# Check "Sync Status" shows new commit SHA
```

## Troubleshooting

### Application Shows "OutOfSync" Status

**Cause**: ArgoCD detected differences between Git and cluster state.

**Solution**:

```bash
# View differences
argocd app diff my-service-dev

# Force sync
argocd app sync my-service-dev --force
```

### Application Shows "Degraded" Health

**Cause**: Kubernetes resources are not healthy (e.g., CrashLoopBackOff).

**Solution**:

```bash
# Check pod logs
kubectl logs -n my-service-dev -l app=my-service --tail=100

# Describe pods for events
kubectl describe pods -n my-service-dev -l app=my-service

# Check deployment status
kubectl get deployment -n my-service-dev
```

### Application Not Appearing in ArgoCD

**Cause**: ArgoCD hasn't synced the `platform-root` repository yet.

**Solution**:

```bash
# Check if Application resource exists
kubectl get application -n argocd | grep my-service

# If missing, verify the manifest is in Git
# Then manually sync the platform-root app
argocd app sync platform-root
```

## Next Steps

After successfully onboarding your service:

- [Configure Ingress for External Access](../networking/configure-ingress-tls.md)
- [Set Up Monitoring Dashboards](../observability/view-dora-metrics-devlake.md)
- [Implement Security Scanning](../../security.md)
- [Configure Policy Enforcement](../policy/troubleshoot-kyverno-violation.md)

## Related Documentation

- [Continuous Delivery Pattern](../../patterns/continuous-delivery.md) - Understand the CD workflow
- [ArgoCD Architecture](../../architecture.md) - Learn how ArgoCD works
- [GitOps Explanation](../../explanation/index.md) - Conceptual background
- [Green Belt Module: GitOps with ArgoCD](../../dojo/modules/green-belt/module-09-gitops-argocd.md)
