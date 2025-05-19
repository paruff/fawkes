# Getting Started with Fawkes

Welcome to the Fawkes Internal Developer Platform! This guide will help you understand and implement the GitOps-based approach to platform management and delivery excellence.

## Repository Structure

```
fawkes/
├── docs/              # Documentation and guides
├── platform/          # Platform components
│   ├── iac/          # Infrastructure as Code
│   │   ├── azure/    # Azure-specific resources
│   │   ├── aws/      # AWS-specific resources
│   │   └── gcp/      # GCP-specific resources
│   ├── services/     # Platform services
│   └── tests/        # Test suites and quality checks
└── mkdocs.yml        # Documentation configuration
```

## Prerequisites

Before you begin, ensure you have:

- **Git**: For repository management
- **kubectl**: For Kubernetes interaction
- **Flux** or **ArgoCD**: For GitOps operations
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

Services are deployed automatically via GitOps controllers. To add a new service:

1. Define the service in `platform/services/`:
```yaml
# Example service manifest
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: jenkins
spec:
  source:
    repoURL: https://github.com/paruff/fawkes.git
    path: platform/services/jenkins
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

Tests are now located in the platform directory:

```bash
cd platform/tests
# Run unit tests
go test ./...
# Run integration tests
make integration-tests
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