# Fawkes Platform Applications

This directory contains all platform components deployed on the Fawkes Internal Delivery Platform. Each component is organized in its own subdirectory with configuration files and documentation.

## Directory Structure

```text
platform/apps/
├── README.md                           # This file
├── namespaces.yaml                     # Namespace definitions
├── *-application.yaml                  # ArgoCD Application manifests
├── argocd/                            # GitOps continuous delivery
├── backstage/                         # Developer portal
├── cert-manager/                      # Certificate management
├── dashboard/                         # Kubernetes dashboard
├── datahub/                          # Data catalog and lineage
├── devlake/                          # DORA metrics collection
├── eclipse-che/                       # Cloud development environments
├── external-secrets/                  # Cloud secrets integration
├── fluent-bit/                       # Log collection
├── focalboard/                       # Project management
├── grafana/                          # Metrics visualization
├── harbor/                           # Container registry
├── ingress-nginx/                    # Ingress controller
├── jenkins/                          # CI/CD pipelines
├── kyverno/                          # Policy enforcement
├── mattermost/                       # Team collaboration
├── opensearch/                       # Log aggregation
├── opentelemetry/                    # Observability pipeline
├── postgresql/                       # Database
├── prometheus/                       # Metrics monitoring
├── sonarqube/                        # Code quality & security
├── storage/                          # Storage classes
├── tempo/                            # Distributed tracing
├── trivy/                            # Security scanning
├── vault/                            # Secrets management
├── vault-csi-driver/                 # Vault CSI integration
└── weaviate/                         # Vector database
```

## Component Categories

### Core Platform

| Component | Purpose | Namespace |
|-----------|---------|-----------|
| [ArgoCD](argocd/) | GitOps continuous delivery | `argocd` |
| [Ingress NGINX](ingress-nginx/) | Ingress controller | `ingress-nginx` |
| [Cert Manager](cert-manager/) | TLS certificate management | `cert-manager` |
| [Storage](storage/) | Storage classes and provisioners | `kube-system` |

### Developer Experience

| Component | Purpose | Namespace |
|-----------|---------|-----------|
| [Backstage](backstage/) | Developer portal and service catalog | `fawkes` |
| [Eclipse Che](eclipse-che/) | Cloud development environments | `eclipse-che` |
| [Dashboard](dashboard/) | Kubernetes web UI | `kubernetes-dashboard` |

### CI/CD

| Component | Purpose | Namespace |
|-----------|---------|-----------|
| [Jenkins](jenkins/) | Build and deployment automation | `fawkes` |
| [Harbor](harbor/) | Container registry with scanning | `harbor` |
| [SonarQube](sonarqube/) | Code quality and security analysis | `fawkes` |
| [Trivy](trivy/) | Container security scanning | `fawkes` |

### Observability

| Component | Purpose | Namespace |
|-----------|---------|-----------|
| [Prometheus](prometheus/) | Metrics collection and alerting | `monitoring` |
| [Grafana](grafana/) | Metrics visualization | `monitoring` |
| [OpenTelemetry](opentelemetry/) | Telemetry data pipeline | `monitoring` |
| [OpenSearch](opensearch/) | Log aggregation and search | `logging` |
| [Fluent Bit](fluent-bit/) | Log collection | `logging` |
| [Tempo](tempo/) | Distributed tracing | `monitoring` |

### Security

| Component | Purpose | Namespace |
|-----------|---------|-----------|
| [Vault](vault/) | Secrets management | `vault` |
| [Vault CSI Driver](vault-csi-driver/) | Vault CSI integration | `kube-system` |
| [External Secrets](external-secrets/) | Cloud secrets sync | `external-secrets` |
| [Kyverno](kyverno/) | Policy enforcement | `kyverno` |

### Data & AI

| Component | Purpose | Namespace |
|-----------|---------|-----------|
| [DevLake](devlake/) | DORA metrics collection | `devlake` |
| [DataHub](datahub/) | Data catalog and lineage | `datahub` |
| [Weaviate](weaviate/) | Vector database for AI/ML | `weaviate` |
| [PostgreSQL](postgresql/) | Relational database | `fawkes` |

### Collaboration

| Component | Purpose | Namespace |
|-----------|---------|-----------|
| [Mattermost](mattermost/) | Team messaging and ChatOps | `mattermost` |
| [Focalboard](focalboard/) | Project management | `focalboard` |

## Deployment

### Prerequisites

1. Kubernetes cluster (1.28+)
2. kubectl configured
3. Sufficient cluster resources (see [resource requirements](../../docs/getting-started.md#resources))

### Deploy All Platform Components

Using ArgoCD App-of-Apps pattern:

```bash
# Deploy ArgoCD first
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Deploy platform apps
kubectl apply -f platform/bootstrap/platform-apps.yaml
```

### Deploy Individual Components

Each component can be deployed independently:

```bash
# Example: Deploy Jenkins
kubectl apply -f platform/apps/jenkins-application.yaml

# Wait for sync
kubectl wait --for=condition=Synced application/jenkins -n argocd --timeout=5m
```

## Configuration

### ArgoCD Application Pattern

All components follow this ArgoCD Application pattern:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: component-name
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/paruff/fawkes
    targetRevision: main
    path: platform/apps/component-name
  destination:
    server: https://kubernetes.default.svc
    namespace: component-namespace
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```

### Component Structure

Each component directory typically contains:

```text
component-name/
├── README.md                    # Component documentation
├── kustomization.yaml          # Kustomize configuration (optional)
├── values.yaml                 # Helm values (if using Helm)
├── *.yaml                      # Kubernetes manifests
└── configs/                    # Additional configuration files
```

## Adding New Components

See [templates/new-app/](../../templates/new-app/) for templates to create new platform applications.

### Steps to Add a Component

1. Create directory: `platform/apps/my-component/`
2. Add manifests or Helm values
3. Create README.md (use [template](../../templates/new-app/README.template.md))
4. Create ArgoCD Application manifest
5. Update this README to list the new component
6. Commit and push to trigger deployment

## Accessing Components

All components are accessible via ingress:

```text
http://component-name.127.0.0.1.nip.io    # Local development
https://component-name.fawkes.idp         # Production
```

Default credentials are documented in each component's README.

## Monitoring

All components expose metrics for Prometheus:

```bash
# View all ServiceMonitors
kubectl get servicemonitors -A

# Check component health
kubectl get pods -n <namespace>
```

## Troubleshooting

### Component Not Starting

```bash
# Check ArgoCD sync status
kubectl get application -n argocd

# View sync errors
kubectl describe application component-name -n argocd

# Check pod status
kubectl get pods -n component-namespace

# View pod logs
kubectl logs -n component-namespace deployment/component-name
```

### Sync Failures

```bash
# Manual sync
argocd app sync component-name

# View diff
argocd app diff component-name

# Refresh without sync
argocd app get component-name --refresh
```

## Resource Management

### Resource Quotas

Each namespace has resource quotas to prevent over-allocation:

```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: compute-quota
  namespace: fawkes
spec:
  hard:
    requests.cpu: "20"
    requests.memory: 40Gi
    limits.cpu: "40"
    limits.memory: 80Gi
```

### Monitoring Resource Usage

```bash
# View resource usage by namespace
kubectl top nodes
kubectl top pods -A

# Check quota usage
kubectl describe quota -n fawkes
```

## Security

### Network Policies

All components have network policies restricting traffic:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: component-network-policy
spec:
  podSelector:
    matchLabels:
      app: component-name
  policyTypes:
    - Ingress
    - Egress
  ingress:
    - from:
        - namespaceSelector:
            matchLabels:
              name: ingress-nginx
  egress:
    - to:
        - namespaceSelector: {}
```

### Pod Security Standards

All namespaces enforce Pod Security Standards:

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: fawkes
  labels:
    pod-security.kubernetes.io/enforce: restricted
    pod-security.kubernetes.io/audit: restricted
    pod-security.kubernetes.io/warn: restricted
```

## Backup and Disaster Recovery

### Backup Strategy

- **Manifests**: All in Git (GitOps)
- **Secrets**: Backed up in Vault
- **Data**: PostgreSQL automated backups
- **Configs**: Stored in Git

### Recovery Procedure

1. Restore Git repository
2. Redeploy ArgoCD
3. Sync all applications
4. Restore databases from backup
5. Verify all components healthy

## Related Documentation

- [Architecture Overview](../../docs/architecture.md)
- [Getting Started Guide](../../docs/getting-started.md)
- [Deployment Guide](../../docs/how-to/deploy-platform.md)
- [Troubleshooting Guide](../../docs/troubleshooting.md)
- [ADR Index](../../docs/adr/)

## Contributing

To add or modify platform components:

1. Follow [contribution guidelines](../../docs/contributing.md)
2. Use provided templates for consistency
3. Update documentation
4. Test in local environment
5. Submit pull request

## Support

- **Documentation**: See component README files
- **Issues**: [GitHub Issues](https://github.com/paruff/fawkes/issues)
- **Discussions**: [GitHub Discussions](https://github.com/paruff/fawkes/discussions)
- **Chat**: #platform-help in Mattermost
