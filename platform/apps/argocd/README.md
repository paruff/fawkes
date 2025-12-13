# ArgoCD - GitOps Continuous Delivery

## Purpose

ArgoCD provides declarative GitOps-based continuous delivery for Kubernetes. It automatically syncs application definitions from Git repositories to the cluster, ensuring the actual state matches the desired state.

## Architecture

```text
┌─────────────────────────────────────────────────────────────────┐
│                     Git Repository (Source of Truth)             │
│  ├─ platform/apps/                  Platform components         │
│  ├─ services/                       Application services         │
│  └─ infrastructure/                 Infrastructure config        │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                     ArgoCD Server                                │
│  ├─ Application Controller          Sync engine                 │
│  ├─ Repository Server                Git/Helm processor         │
│  ├─ API Server                       REST/gRPC API              │
│  └─ Dex (Optional)                   SSO/RBAC                   │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                     Kubernetes Cluster                           │
│  ├─ Namespaces                       Deployed applications      │
│  ├─ Workloads                        Running services           │
│  └─ Resources                        ConfigMaps, Secrets, etc.  │
└─────────────────────────────────────────────────────────────────┘
```

## Key Features

- **GitOps Workflow**: Git as the single source of truth
- **Auto-Sync**: Automatic deployment of changes from Git
- **App-of-Apps Pattern**: Hierarchical application management
- **Multi-Cluster**: Manage multiple clusters from single control plane
- **Rollback**: Easy rollback to previous Git commits
- **Health Assessment**: Built-in health checks for resources
- **Sync Hooks**: Pre/post-sync operations
- **Progressive Delivery**: Blue-green and canary deployments

## Quick Start

### Accessing ArgoCD

Local development:
```bash
# Get admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Access UI
http://argocd.127.0.0.1.nip.io
```

Default credentials:
- Username: `admin`
- Password: From secret above

### Creating an Application

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: my-app
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/paruff/fawkes
    targetRevision: main
    path: services/my-app
  destination:
    server: https://kubernetes.default.svc
    namespace: my-app
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

### App-of-Apps Pattern

The platform uses the App-of-Apps pattern to manage all components:

```text
platform-apps (root)
├── backstage
├── jenkins
├── prometheus
├── grafana
└── ... (all platform components)
```

## Integration Points

### With Jenkins

Jenkins pipelines update Git repositories, triggering ArgoCD syncs:

```groovy
stage('Update GitOps Repo') {
    steps {
        sh '''
            git clone https://github.com/paruff/fawkes-gitops
            cd fawkes-gitops
            yq eval '.spec.template.spec.containers[0].image = "myapp:${BUILD_NUMBER}"' -i services/myapp/deployment.yaml
            git commit -am "Update myapp to ${BUILD_NUMBER}"
            git push
        '''
    }
}
```

### With Backstage

Backstage displays ArgoCD deployment status via the ArgoCD plugin:

```yaml
# In catalog-info.yaml
metadata:
  annotations:
    argocd/app-name: my-app
```

## DORA Metrics

ArgoCD is the primary source for deployment frequency metrics:

- Each sync represents a deployment
- Sync status determines change failure rate
- DevLake plugin tracks deployments and failures

## Troubleshooting

### Application Out of Sync

```bash
# View sync status
argocd app get my-app

# Sync manually
argocd app sync my-app

# View diff between Git and cluster
argocd app diff my-app
```

### Sync Failures

```bash
# View application events
kubectl describe application my-app -n argocd

# View controller logs
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-application-controller -f
```

## Related Documentation

- [ADR-003: ArgoCD for GitOps](../../../docs/adr/003-argocd.md)
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [GitOps Principles](https://opengitops.dev/)
