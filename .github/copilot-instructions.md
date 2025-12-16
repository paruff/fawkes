# GitHub Copilot Instructions for Fawkes

## Repository Context

This is **Fawkes**, an Internal Product Delivery Platform with integrated dojo learning.

### Architecture Principles
- **GitOps-first**: All configuration in Git, ArgoCD reconciles
- **Declarative**: Describe desired state, not procedures
- **Multi-cloud**: Abstract cloud differences with Terraform/Crossplane
- **Immutable**: Containers and infrastructure are immutable
- **Observable**: Every component emits metrics, logs, traces

### Technology Stack
- **Orchestration**: Kubernetes
- **IaC**: Terraform (migrating to Crossplane)
- **GitOps**: ArgoCD
- **CI/CD**: Jenkins with Groovy pipelines
- **Portal**: Backstage (TypeScript/React)
- **Collaboration**: Mattermost (Go)
- **Project Management**: Focalboard (Go/React)
- **Observability**: Prometheus, Grafana, OpenTelemetry

### Code Generation Guidelines

#### For Terraform
- Use Terraform 1.6+ syntax
- Always include `required_providers` block
- Use variables for all configurable values
- Include `outputs.tf` for important values
- Add `terraform.tfvars.example` for documentation
- Comment complex logic

#### For Kubernetes Manifests
- Use apiVersion appropriate for K8s 1.28+
- Always include namespace
- Use Kustomize overlays for environment differences
- Include resource requests and limits
- Add labels for observability (app, component, version)
- Prefer Deployments over ReplicaSets

#### For Helm Values
- Document all values with comments
- Provide sensible defaults
- Group related settings
- Include examples for common use cases

#### For Python Scripts
- Type hints for all functions
- Docstrings in Google style
- Use Click for CLI
- Handle errors gracefully
- Log meaningful messages

#### For Gherkin Features
- Use business language, not technical jargon
- One feature per file
- Background for common setup
- Scenario Outline for parameterized tests
- Tag with @local, @dev, @prod for environment-specific tests

### Common Patterns

#### Deploying a new component
1. Create Helm chart or raw manifests in `manifests/base/`
2. Create Kustomization for environment overlays
3. Create ArgoCD Application in `manifests/argocd/apps/.yaml`
4. Add BDD feature for acceptance tests
5. Deploy locally first, then sync to GitOps

#### Adding DORA metrics
- Emit events to Prometheus Pushgateway
- Use standard metric names: `dora_deployment_frequency`, etc.
- Include labels: team, service, environment
- Create Grafana dashboard JSON

#### Security scanning
- SonarQube for SAST (Java, Python, Go)
- Trivy for container images
- Fail builds on HIGH/CRITICAL vulnerabilities
- Store reports as artifacts

### Avoid
- ❌ Imperative `kubectl` commands in production
- ❌ Secrets in Git (use External Secrets Operator)
- ❌ Hardcoded values (use ConfigMaps/variables)
- ❌ Mutable tags (use SHA or semantic version)
- ❌ Root containers (use security contexts)
- ❌ Privileged containers (unless absolutely necessary)

### When Suggesting Code
- Prefer existing patterns in codebase
- Reference similar existing implementations
- Include validation/testing approach
- Explain trade-offs if multiple approaches exist
- Link to relevant documentation

## Project Structure

```
fawkes/
├── charts/              # Helm charts for deployments
├── docs/                # Comprehensive documentation
│   ├── adr/            # Architecture Decision Records
│   ├── dojo/           # Dojo learning materials
│   ├── how-to/         # Step-by-step guides
│   ├── reference/      # API and configuration references
│   └── tutorials/      # Learning tutorials
├── infra/               # Infrastructure as Code
│   ├── aws/            # AWS-specific resources
│   ├── azure/          # Azure-specific resources
│   ├── kubernetes/     # K8s manifests
│   ├── local-dev/      # Local development scripts
│   └── terraform/      # Terraform configurations
├── jenkins-shared-library/ # Shared Jenkins pipeline code
├── platform/            # Platform components
│   ├── apps/           # ArgoCD applications
│   ├── bootstrap/      # Bootstrap configurations
│   ├── devfiles/       # Developer workspace definitions
│   └── policies/       # OPA policies
├── scripts/             # Utility scripts
├── services/            # Microservices
│   ├── mcp-k8s-server/ # MCP Kubernetes server
│   └── samples/        # Sample applications
├── templates/           # Golden path templates
│   ├── java-service/   # Java service template
│   ├── nodejs-service/ # Node.js service template
│   └── python-service/ # Python service template
└── tests/               # All test types
    ├── acceptance/     # Acceptance tests
    ├── bdd/            # BDD/Gherkin features
    ├── e2e/            # End-to-end tests
    ├── integration/    # Integration tests
    └── unit/           # Unit tests
```

## Development Workflow

### Initial Setup
```bash
# Install pre-commit hooks
make pre-commit-setup

# Verify local K8s cluster
make k8s-status
```

### Development Loop
```bash
# 1. Write BDD feature first
vim tests/bdd/features/my-feature.feature

# 2. Implement the feature
# Use Copilot to generate code

# 3. Deploy locally
make deploy-local COMPONENT=my-component

# 4. Run tests
make test-bdd COMPONENT=my-component

# 5. Iterate until passing
# Repeat steps 2-4

# 6. Sync to GitOps (when ready)
make sync ENVIRONMENT=dev
```

### Quick Commands
- `make help` - Show all available commands
- `make deploy-local` - Deploy to local K8s
- `make test-bdd` - Run BDD tests
- `make lint` - Run all linters
- `make validate` - Validate manifests and policies

## Testing

### Test Types and Commands

#### Unit Tests (Fast)
```bash
make test-unit
# Or directly: pytest tests/unit -v
```

#### BDD/Acceptance Tests
```bash
make test-bdd COMPONENT=backstage
# Or with behave: behave tests/bdd/features --tags=@local
```

#### Integration Tests
```bash
make test-integration
# Or: pytest tests/integration -v
```

#### E2E Tests
```bash
# All E2E tests
make test-e2e-all

# Individual E2E tests
make test-e2e-argocd
make test-e2e-integration
```

#### Acceptance Test Validations
```bash
# Validate specific AT-E1-* tests
make validate-at-e1-001  # AKS cluster
make validate-at-e1-002  # GitOps/ArgoCD
make validate-at-e1-003  # Backstage
make validate-at-e1-004  # Jenkins
make validate-at-e1-005  # Security scanning
make validate-at-e1-006  # Observability
make validate-at-e1-007  # DORA metrics
```

### Test Markers
- `@local` - Tests that run on local K8s
- `@dev` - Tests for dev environment
- `@prod` - Tests for production environment
- `@smoke` - Quick smoke tests

## Building and Deployment

### Local Development
```bash
# Deploy all components locally
make deploy-local COMPONENT=all

# Deploy specific component
make deploy-local COMPONENT=backstage

# Check deployment status
kubectl get pods -n fawkes-local

# View logs
make k8s-logs COMPONENT=backstage
```

### Validation
```bash
# Validate all manifests
make validate

# Validate resource usage (70% target)
make validate-resources

# Validate Terraform
make terraform-validate

# Validate Kubernetes manifests
make k8s-validate

# Validate Jenkins configuration
make validate-jenkins
```

### GitOps Sync
```bash
# Sync to dev
make sync ENVIRONMENT=dev

# Sync to prod
make sync ENVIRONMENT=prod

# Check ArgoCD status
make argocd-status

# View ArgoCD diff
make argocd-diff
```

## Documentation

### Serving Docs Locally
```bash
make docs-serve
# Opens at http://localhost:8000
```

### Building Docs
```bash
make docs-build
```

## Troubleshooting

### Common Issues

#### Pods not starting
```bash
# Check pod status
kubectl get pods -n fawkes-local

# Describe pod for events
kubectl describe pod <pod-name> -n fawkes-local

# Check logs
kubectl logs <pod-name> -n fawkes-local
```

#### ArgoCD sync issues
```bash
# Check application status
argocd app get fawkes-dev

# View diff between Git and cluster
make argocd-diff ENVIRONMENT=dev

# Force sync
make argocd-sync ENVIRONMENT=dev
```

#### Resource constraints
```bash
# Check resource usage
kubectl top pods -n fawkes-local

# Validate against 70% target
make validate-resources
```

### Debug Mode
- Set `VERBOSE=true` for detailed output
- Use `--verbose` flag with E2E tests
- Check `kubectl describe` for events
- Review application logs with `kubectl logs`

## Important Files

- **Makefile** - All development commands
- **.pre-commit-config.yaml** - Pre-commit hook configuration
- **catalog-info.yaml** - Backstage catalog entry
- **mkdocs.yml** - Documentation site configuration
- **tests/pytest.ini** - Pytest configuration
- **env.example** - Environment variables template

## Best Practices

### Before Committing
1. Run linters: `make lint`
2. Run tests: `make test-all`
3. Validate manifests: `make validate`
4. Check pre-commit hooks pass

### For New Features
1. Write BDD feature first
2. Add acceptance criteria
3. Implement with TDD approach
4. Validate resource usage
5. Update documentation
6. Add metrics/observability
