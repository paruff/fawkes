# Getting Started with Fawkes

Welcome to the Fawkes Internal Developer Platform! This guide will help you understand and implement the GitOps-based approach to platform management and delivery excellence.

## Repository Structure

```
fawkes/
├── docs/                          # Documentation (Diátaxis framework)
│   ├── tutorials/                 # Learning-oriented guides
│   ├── how-to/                    # Task-oriented guides
│   ├── explanation/               # Understanding-oriented discussions
│   ├── reference/                 # Information-oriented specifications
│   │   ├── api/                   # API specifications (OpenAPI, REST)
│   │   ├── crds/                  # Custom Resource Definitions
│   │   ├── config/                # Configuration tables (Helm values)
│   │   ├── policies/              # Policy listings (Kyverno)
│   │   ├── catalogue/             # Service catalog reference
│   │   └── glossary.md            # Fawkes terminology
│   └── dojo/                      # Belt-based learning modules
├── platform/                      # Platform components
│   ├── apps/                      # ArgoCD applications (Jenkins, Backstage, etc.)
│   ├── policies/                  # Kyverno policies (security, mutation, generation)
│   ├── devfiles/                  # Eclipse Che development environments
│   ├── networking/                # Ingress, cert-manager, external-dns
│   └── bootstrap/                 # Platform initialization scripts
├── infra/                         # Infrastructure as Code
│   ├── local-dev/                 # Local Kubernetes (kind, minikube)
│   ├── kubernetes/                # Kubernetes manifests
│   └── terraform/                 # Cloud infrastructure (AWS, Azure, GCP)
├── jenkins-shared-library/        # Golden Path pipeline library
├── services/                      # Platform-specific services
│   └── mcp-k8s-server/            # Model Context Protocol server
├── tests/                         # Test suites
│   ├── bdd/                       # BDD/Gherkin acceptance tests
│   ├── unit/                      # Unit tests
│   └── integration/               # Integration tests
└── mkdocs.yml                     # Documentation site configuration
```

## Prerequisites

Before you begin, ensure you have:

- **Git**: For repository management
- **kubectl**: For Kubernetes interaction
- **ArgoCD**: For GitOps operations
- **Cloud CLI**: For your chosen cloud provider

## 1. Clone the Repository

```bash
git clone https://github.com/paruff/fawkes.git
cd fawkes
```

## 2. Choose Your Implementation Path

Fawkes supports multiple implementation paths based on your cloud provider:

| Cloud | Implementation | Documentation |
|-------|---------------|---------------|
| Azure | AKS + Flux | [Azure Guide](platform/iac/azure/README.md) |
| AWS | EKS + ArgoCD | [AWS Guide](platform/iac/aws/README.md) |
| GCP | GKE + Cloud Build | [GCP Guide](platform/iac/gcp/README.md) |

## 3. Infrastructure Deployment

We use a GitOps approach for infrastructure management. Changes are made through pull requests:

1. Create a feature branch:
```bash
git checkout -b feature/add-new-service
```

2. Make changes to infrastructure definitions in `platform/iac/`:
```yaml
# Example service definition
apiVersion: apps/v1
kind: Deployment
metadata:
  name: fawkes-service
spec:
  replicas: 3
  ...
```

3. Commit and push changes:
```bash
git add .
git commit -m "feat: add new service deployment"
git push origin feature/add-new-service
```

4. Create a pull request and wait for CI checks and review

## 4. Platform Services

### Deploy Core Services

Services are deployed automatically via GitOps controllers. The core platform includes:

- **Backstage** - Developer portal (requires GitHub OAuth)
- **Jenkins** - CI/CD pipelines
- **ArgoCD** - GitOps deployment
- **Prometheus/Grafana** - Observability
- **SonarQube** - Code quality

### Configure GitHub OAuth for Backstage

Before accessing Backstage, configure GitHub OAuth authentication:

**Quick Setup:**

1. Create GitHub OAuth App at https://github.com/settings/developers
2. Configure callback URL: `https://backstage.fawkes.idp/api/auth/github/handler/frame`
3. Update secrets in `platform/apps/backstage/secrets.yaml`
4. Apply: `kubectl apply -f platform/apps/backstage/secrets.yaml`

**For detailed instructions, see**: [GitHub OAuth Setup Guide](how-to/security/github-oauth-setup.md)

### Deploy Services

To deploy or add a new service:

1. Define the service in `platform/apps/`:
```yaml
# Example service manifest
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: jenkins
spec:
  source:
    repoURL: https://github.com/paruff/fawkes.git
    path: platform/apps/jenkins
    targetRevision: HEAD
  destination:
    server: https://kubernetes.default.svc
    namespace: jenkins
```

2. Commit and push through the GitOps workflow

## 5. Verify Deployment

Monitor deployments through:

- GitOps dashboard (ArgoCD/Flux)
- Kubernetes dashboard
- Platform monitoring tools

## 6. Running Tests

Tests are executed using pytest:

```bash
# Run unit tests
pytest tests/unit -v

# Run BDD tests
pytest tests/bdd -v

# Run all tests
pytest tests/ -v
```

## Next Steps

1. [Assess your capabilities](capabilities/assessment.md)
2. [Review implementation patterns](patterns/index.md)
3. [Explore available tools](tools/index.md)

## Need Help?

- Check our [troubleshooting guide](troubleshooting.md)
- Open an issue on [GitHub](https://github.com/paruff/fawkes/issues)
- Join our [community discussions](https://github.com/paruff/fawkes/discussions)

[Start Assessment :clipboard:](capabilities/assessment.md){ .md-button .md-button--primary }
[View Patterns :books:](patterns/index.md){ .md-button }
[Explore Tools :wrench:](tools/index.md){ .md-button }