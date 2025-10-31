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
