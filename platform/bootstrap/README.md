# Fawkes Platform Bootstrap

This directory contains the bootstrap configuration for the Fawkes platform using the **App-of-Apps** pattern.

## Overview

The app-of-apps pattern is an ArgoCD best practice where a single "root" Application manages all other platform Applications. This provides:

- **Centralized Management**: One place to manage all platform components
- **Automated Discovery**: ApplicationSet automatically discovers new apps
- **Ordered Deployment**: Sync waves ensure proper deployment ordering
- **GitOps Native**: All configuration in Git, ArgoCD reconciles

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    platform-bootstrap                        │
│              (Root App-of-Apps Application)                  │
└───────────────────────────┬─────────────────────────────────┘
                            │
                ┌───────────┴───────────┐
                │                       │
                ▼                       ▼
    ┌──────────────────┐    ┌──────────────────────┐
    │  root-apps.yaml  │    │ ApplicationSet       │
    │                  │    │ (Auto-discovery)     │
    │ • fawkes-app     │    └──────────┬───────────┘
    │ • fawkes-infra   │               │
    │ • fawkes-network │               │
    └──────────────────┘               │
                                       ▼
                        ┌──────────────────────────┐
                        │  Platform Applications   │
                        │  (from platform/apps/)   │
                        │                          │
                        │ • argocd                 │
                        │ • backstage              │
                        │ • jenkins                │
                        │ • prometheus             │
                        │ • vault                  │
                        │ • ... (auto-discovered)  │
                        └──────────────────────────┘
```

## Files

### Core Bootstrap Files

| File                   | Purpose                                      |
| ---------------------- | -------------------------------------------- |
| `app-of-apps.yaml`     | Root Application that manages the platform   |
| `applicationset.yaml`  | Auto-discovers apps in platform/apps/        |
| `root-apps.yaml`       | Static root Applications (networking, infra) |
| `project-default.yaml` | Default ArgoCD Project definition            |
| `kustomization.yaml`   | Kustomize configuration for bootstrap        |
| `README.md`            | This documentation                           |

### app-of-apps.yaml

The root Application that implements the app-of-apps pattern:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: platform-bootstrap
  namespace: fawkes
spec:
  project: default
  source:
    repoURL: https://github.com/paruff/fawkes.git
    path: platform/bootstrap
    targetRevision: HEAD
  destination:
    server: https://kubernetes.default.svc
    namespace: fawkes
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

### applicationset.yaml

Automatically discovers and creates Applications for all directories in `platform/apps/`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: platform-applications
  namespace: fawkes
spec:
  generators:
    - git:
        repoURL: https://github.com/paruff/fawkes.git
        directories:
          - path: platform/apps/*
```

## Sync Waves

Applications deploy in phases using sync waves:

| Wave  | Phase                | Components                           |
| ----- | -------------------- | ------------------------------------ |
| `-10` | Infrastructure       | ingress-nginx, storage, cert-manager |
| `-5`  | Core Services        | postgresql-operator                  |
| `-4`  | Security             | kyverno                              |
| `-3`  | Secrets & Monitoring | vault, prometheus, cert-manager      |
| `-2`  | Platform Services    | vault-csi-driver, ingress, tempo     |
| `0`   | Default              | Most platform apps                   |
| `5`   | Developer Tools      | backstage, eclipse-che               |
| `10`  | Applications         | User applications                    |

## Usage

### Prerequisites

1. **Kubernetes cluster** running (1.28+)
2. **ArgoCD installed** in the `fawkes` namespace
3. **kubectl** configured to access the cluster
4. **Network connectivity** to GitHub

### Bootstrap the Platform

Using the bootstrap script (recommended):

```bash
# Bootstrap with default settings
./scripts/bootstrap.sh

# Dry run to see what would be applied
./scripts/bootstrap.sh --dry-run

# Bootstrap and wait for sync
./scripts/bootstrap.sh --wait --timeout 600

# Use custom ArgoCD namespace
./scripts/bootstrap.sh --namespace argocd
```

Using kubectl directly:

```bash
# Apply the bootstrap kustomization
kubectl apply -k platform/bootstrap

# Verify applications are created
kubectl get applications -n fawkes

# Watch sync status
kubectl get applications -n fawkes -w
```

Using the ignite script (full bootstrap):

```bash
# Local environment (includes cluster creation)
./scripts/ignite.sh local

# Existing cluster
./scripts/ignite.sh dev
```

### Verify Bootstrap

Check that the root application is created:

```bash
# Check app-of-apps
kubectl get application platform-bootstrap -n fawkes

# Check ApplicationSet
kubectl get applicationset platform-applications -n fawkes

# List all applications
kubectl get applications -n fawkes

# Check sync status
argocd app list
```

Expected output:

```
NAME                  SYNC STATUS   HEALTH STATUS
platform-bootstrap    Synced        Healthy
fawkes-app           Synced        Healthy
fawkes-infra         Synced        Healthy
fawkes-networking    Synced        Healthy
backstage            Synced        Healthy
jenkins              Synced        Healthy
...
```

## Adding New Applications

### Using ApplicationSet Auto-Discovery

The ApplicationSet automatically discovers applications in `platform/apps/`. To add a new app:

1. **Create app directory**:

   ```bash
   mkdir -p platform/apps/my-app
   ```

2. **Add application manifest**:

   ```bash
   cat > platform/apps/my-app/my-app-application.yaml <<EOF
   apiVersion: argoproj.io/v1alpha1
   kind: Application
   metadata:
     name: my-app
     namespace: fawkes
     annotations:
       argocd.argoproj.io/sync-wave: "0"
   spec:
     project: default
     source:
       repoURL: https://charts.example.com
       chart: my-app
       targetRevision: 1.0.0
     destination:
       server: https://kubernetes.default.svc
       namespace: my-app
     syncPolicy:
       automated:
         prune: true
         selfHeal: true
       syncOptions:
         - CreateNamespace=true
   EOF
   ```

3. **Commit and push**:

   ```bash
   git add platform/apps/my-app/
   git commit -m "Add my-app application"
   git push
   ```

4. **ApplicationSet discovers automatically**:
   - Within 3 minutes (default refresh interval)
   - Or force refresh: `argocd appset refresh platform-applications`

### Sync Wave Best Practices

Choose the appropriate sync wave for your application:

- **Wave -10**: Infrastructure dependencies (storage, networking)
- **Wave -5**: Operators and CRD providers
- **Wave -3**: Core platform services (vault, monitoring)
- **Wave 0**: Standard platform services (default)
- **Wave 5**: Developer-facing tools
- **Wave 10+**: User applications

Example:

```yaml
metadata:
  annotations:
    argocd.argoproj.io/sync-wave: "-5" # Deploy early
```

## Troubleshooting

### Applications Not Appearing

Check ApplicationSet status:

```bash
kubectl describe applicationset platform-applications -n fawkes
```

Force ApplicationSet refresh:

```bash
argocd appset refresh platform-applications
```

### Sync Failures

Check application status:

```bash
kubectl describe application <app-name> -n fawkes
```

View sync errors:

```bash
argocd app get <app-name>
```

Manual sync:

```bash
argocd app sync <app-name>
```

### Bootstrap Failed

Check if ArgoCD is running:

```bash
kubectl get pods -n fawkes -l app.kubernetes.io/name=argocd-server
```

Check bootstrap kustomization:

```bash
kubectl kustomize platform/bootstrap
```

Re-apply bootstrap:

```bash
kubectl apply -k platform/bootstrap
```

### ApplicationSet Not Creating Apps

Verify ApplicationSet exists:

```bash
kubectl get applicationset -n fawkes
```

Check ApplicationSet logs:

```bash
kubectl logs -n fawkes -l app.kubernetes.io/name=argocd-applicationset-controller
```

Verify git generator configuration:

```bash
kubectl get applicationset platform-applications -n fawkes -o yaml
```

## Advanced Configuration

### Customizing Sync Policy

Edit `applicationset.yaml` to change default sync policy:

```yaml
spec:
  template:
    spec:
      syncPolicy:
        automated:
          prune: true # Auto-delete resources
          selfHeal: true # Auto-revert manual changes
        syncOptions:
          - CreateNamespace=true
```

### Excluding Directories

Exclude specific directories from auto-discovery:

```yaml
spec:
  generators:
    - git:
        directories:
          - path: platform/apps/*
            exclude:
              - path: platform/apps/templates
              - path: platform/apps/deprecated
```

### Multiple ApplicationSets

Create additional ApplicationSets for different app groups:

```bash
# Create ApplicationSet for team apps
cat > platform/bootstrap/team-apps-applicationset.yaml <<EOF
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: team-applications
  namespace: fawkes
spec:
  generators:
    - git:
        repoURL: https://github.com/paruff/fawkes.git
        directories:
          - path: apps/team-*/*
EOF
```

## Monitoring

### ArgoCD UI

Access the ArgoCD UI to view application status:

```bash
kubectl -n fawkes port-forward svc/argocd-server 8080:80
```

Open http://localhost:8080

### CLI Monitoring

List all applications:

```bash
argocd app list
```

Watch application sync:

```bash
argocd app sync platform-bootstrap --async
argocd app wait platform-bootstrap
```

### Metrics

ArgoCD exposes Prometheus metrics:

```bash
# View ArgoCD metrics
kubectl port-forward -n fawkes svc/argocd-metrics 8082:8082
curl http://localhost:8082/metrics
```

Key metrics:

- `argocd_app_sync_total`: Number of syncs
- `argocd_app_health_status`: Application health
- `argocd_app_sync_status`: Sync status

## Security

### RBAC

The `default` project allows access to all resources. For production, create restricted projects:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: platform-restricted
  namespace: fawkes
spec:
  destinations:
    - namespace: "fawkes-*"
      server: https://kubernetes.default.svc
  sourceRepos:
    - https://github.com/paruff/fawkes.git
  clusterResourceWhitelist:
    - group: "*"
      kind: "Namespace"
```

### Secrets Management

Applications should use Vault or External Secrets Operator, not inline secrets:

```yaml
# Bad: Inline secret
stringData:
  password: mypassword

# Good: External secret reference
valueFrom:
  secretKeyRef:
    name: app-credentials
    key: password
```

## Related Documentation

- [ArgoCD App-of-Apps Pattern](https://argo-cd.readthedocs.io/en/stable/operator-manual/cluster-bootstrapping/)
- [ApplicationSet Documentation](https://argo-cd.readthedocs.io/en/stable/user-guide/application-set/)
- [Sync Waves and Phases](https://argo-cd.readthedocs.io/en/stable/user-guide/sync-waves/)
- [Platform Apps README](../apps/README.md)
- [Fawkes Architecture](../../docs/architecture.md)
- [Implementation Plan](../../docs/implementation-plan/week1-detailed-tasks.md)

## Support

For issues with bootstrap:

1. Check [Troubleshooting](#troubleshooting) section
2. Review ArgoCD logs: `kubectl logs -n fawkes -l app.kubernetes.io/name=argocd-server`
3. Open issue: https://github.com/paruff/fawkes/issues
4. Discussion: https://github.com/paruff/fawkes/discussions
