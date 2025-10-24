# Copilot Instructions for Fawkes GitOps & Trunk-Based Development

## Overview

This document provides guidance for using Copilot effectively within the Fawkes platform, ensuring **trunk-based development**, **declarative infrastructure management**, and **GitOps workflows** while aligning with the **24 key capabilities** from the DORA reports. These instructions are tailored to support the workflows and practices in the Fawkes workspace.

---

## Best Practices for Copilot

### 1. Trunk-Based Development

- Maintain **fewer than three active branches** in the repository.
- Merge branches **within a day** to avoid long-lived feature branches.
- Avoid **code lock periods** (e.g., stabilization phases or freezes).
- Use **feature flags** to enable incremental delivery of incomplete features.
- Example workflow:
  ```sh
  git checkout -b feature/update-config
  git commit -am "Updated deployment config"
  git push origin feature/update-config
  git merge feature/update-config main
  ```

---

### 2. Writing Declarative Configurations

- Use YAML or JSON to define infrastructure and application states.
- Store configurations in version-controlled repositories to maintain consistency.
- Use **GitOps tools** like ArgoCD or Flux for automated deployment of configurations.
- Example Kubernetes Deployment:
  ```yaml
  apiVersion: apps/v1
  kind: Deployment
  metadata:
    name: fawkes-app
  spec:
    replicas: 3
    selector:
      matchLabels:
        app: fawkes-app
    template:
      metadata:
        labels:
          app: fawkes-app
      spec:
        containers:
          - name: app-container
            image: fawkes/app:v1
  ```

---

### 3. Leveraging Copilot for Code & Configurations

- Use meaningful comments to guide Copilot when generating code or configurations.
- Review Copilot-generated suggestions carefully before applying them.
- Use Copilot to scaffold repetitive configurations, such as Kubernetes manifests or Terraform modules.
- Example prompt for Copilot:
  ```yaml
  # Define an ArgoCD Application resource for Helm-based deployment
  ```

---

### 4. Writing Well-Tested Code

- Implement **unit tests**, **integration tests**, and **end-to-end tests** for declarative configurations.
- Validate Kubernetes manifests using tools such as:
  - **kube-score** for best practices.
  - **OPA Gatekeeper** for policy enforcement.
- Example validation using `kube-score`:
  ```sh
  kube-score score fawkes-deployment.yaml
  ```

---

### 5. Security Considerations

- Scan dependencies regularly for vulnerabilities using tools like **Trivy** or **Snyk**.
- Use **Role-Based Access Control (RBAC)** to enforce least privilege access.
- Encrypt sensitive data using tools like **Sealed Secrets** or **Azure Key Vault**.
- Example RBAC policy:
  ```yaml
  apiVersion: rbac.authorization.k8s.io/v1
  kind: Role
  metadata:
    name: read-only-role
  rules:
      - apiGroups: [""]
        resources: ["pods"]
        verbs: ["get", "list"]
  ```

---

### 6. Lean Management & Monitoring

- Implement observability with tools like **Prometheus**, **Grafana**, and **Azure Monitor**.
- Use streamlined change approval processes (e.g., peer reviews instead of heavy change boards).
- Example Prometheus monitoring setup:
  ```yaml
  apiVersion: monitoring.coreos.com/v1
  kind: ServiceMonitor
  metadata:
    name: fawkes-monitor
  spec:
    selector:
      matchLabels:
        app: fawkes-app
  ```

---

### 7. Azure Best Practices

- Use **Azure Resource Manager (ARM)** templates or **Bicep** for declarative infrastructure management.
- Leverage **Azure DevOps Pipelines** for CI/CD workflows.
- Use **Azure Key Vault** for secure storage of secrets.
- Example Azure CLI command to set up a Kubernetes cluster:
  ```sh
  az aks create --resource-group fawkes-rg --name fawkes-cluster --node-count 3 --enable-addons monitoring --generate-ssh-keys
  ```

---

### 8. Continuous Improvement with DORA Metrics

- Measure and improve the **Four Key Metrics**:
  - **Deployment Frequency**
  - **Lead Time for Changes**
  - **Change Failure Rate**
  - **Mean Time to Restore (MTTR)**
- Use tools like **Azure Monitor**, **Datadog**, or **New Relic** to track metrics.
- Automate reporting of DORA metrics in CI/CD pipelines.

---

### 9. GitOps Workflow for Fawkes

- Use **ArgoCD** or **Flux** to implement GitOps workflows.
- Store all infrastructure and application configurations in Git repositories.
- Example ArgoCD Application resource:
  ```yaml
  apiVersion: argoproj.io/v1alpha1
  kind: Application
  metadata:
    name: fawkes-app
    namespace: argocd
  spec:
    source:
      repoURL: https://github.com/paruff/fawkes.git
      path: infra/platform/k8s
      targetRevision: main
    destination:
      server: https://kubernetes.default.svc
      namespace: fawkes
    project: default
  ```

---

### 10. Collaboration and Documentation

- Use **Markdown** files in the repository to document configurations and workflows.
- Maintain a **CHANGELOG.md** to track changes in the repository.
- Use **README.md** files in each directory to explain its purpose and contents.

---

### 11. Automation with Copilot

- Use Copilot to automate repetitive tasks, such as:
  - Generating Kubernetes manifests.
  - Writing Terraform modules.
  - Creating CI/CD pipeline configurations.
- Example prompt for Copilot:
  ```yaml
  # Generate a Terraform module for an Azure Kubernetes Service (AKS) cluster
  ```

  ### 15. BDD Testing for IDP Capabilities

#### Gherkin Feature Files
Write features that describe IDP capabilities from user perspective:
```gherkin
Feature: [Capability Name]
  As a [role]
  I want to [action]
  So that [benefit]
  
  @smoke @dora-[metric]
  Scenario: [Specific capability]
    Given [precondition]
    When [action]
    Then [expected outcome]
    And [additional validation]
```

#### Test Organization
- `/tests/e2e/features/` - Gherkin feature files organized by service
- `/tests/e2e/step_definitions/` - Step implementations
- `/tests/e2e/support/` - Helper classes and utilities

#### DORA Metrics Tagging
Tag scenarios with relevant DORA metrics:
- `@dora-deployment-frequency` - Tests affecting deployment frequency
- `@dora-lead-time` - Tests affecting lead time for changes
- `@dora-mttr` - Tests affecting mean time to restore
- `@dora-change-failure-rate` - Tests affecting change failure rate

#### Running Tests
```bash
# Run all E2E tests
pytest tests/e2e/

# Run smoke tests only
pytest tests/e2e/ -m smoke

# Run tests for specific service
pytest tests/e2e/ -k jenkins

# Run with coverage
pytest tests/e2e/ --cov=infra/platform
```

---

By following these best practices, you can ensure that your work within the Fawkes platform aligns with GitOps principles, trunk-based development, and the DORA capabilities, while leveraging Copilot effectively to streamline workflows.
