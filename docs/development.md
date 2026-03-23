# Development Guide

This document provides guidelines for contributing to the Fawkes Internal Developer Platform (IDP). It includes instructions for setting up a local development environment, coding standards, and best practices for contributing to the project.

---

## Table of Contents

- [Setting Up Your Development Environment](#setting-up-your-development-environment)
- [Coding Standards](#coding-standards)
- [Branching and Workflow](#branching-and-workflow)
- [Testing](#testing)
- [Azure Development Best Practices](#azure-development-best-practices)
- [Submitting Contributions](#submitting-contributions)

---

## Setting Up Your Development Environment

### Prerequisites

Ensure you have the following tools installed:

- **Git**: Version control system
- **Docker**: For containerized development
- **Terraform**: For infrastructure provisioning
- **kubectl**: For managing Kubernetes clusters
- **Helm**: For managing Kubernetes applications
- **Azure CLI** (if working with Azure):
  Install using:
  ```sh
  curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
  ```

### Steps to Set Up

1. **Clone the Repository**:

   ```sh
   git clone https://github.com/paruff/fawkes.git
   cd fawkes
   ```

2. **Set Up Environment Variables**:
   Copy the `.env.example` file to `.env` and update the values:

   ```sh
   cp .env.example .env
   ```

3. **Provision Infrastructure**:
   Use the scripts in the `infra/` directory to provision the required infrastructure:

   ```sh
   cd infra
   ./scripts/ignite.sh --provider aws dev
   ```

4. **Deploy Platform Services**:
   Navigate to the `platform/` directory and deploy services:

   ```sh
   cd platform
   ./deploy-services.sh
   ```

5. **Run Tests**:
   Execute the test suite to validate your setup:
   ```sh
   cd qa
   ./run-tests.sh
   ```

---

## Coding Standards

Fawkes enforces comprehensive code quality standards for all languages. All code must pass automated linting before merge.

### Quick Start

```bash
# Install pre-commit hooks (one-time setup)
make pre-commit-setup

# Run all linters on your changes
make lint

# Run specific linter
pre-commit run shellcheck --all-files
```

### Language-Specific Linters

- **Bash**: ShellCheck - Shell script linting
- **Python**: Black (formatter) + Flake8 (linter)
- **Go**: golangci-lint - Comprehensive Go linting
- **YAML**: yamllint - YAML syntax and style
- **JSON**: check-json - JSON validation
- **Markdown**: markdownlint - Documentation linting
- **Terraform**: terraform fmt, TFLint, tfsec - IaC linting and security

### IDE Integration

Configure your IDE for automatic linting:

**VS Code**: Install recommended extensions

```bash
make setup-vscode
```

**Other IDEs**: See [Code Quality Standards](how-to/development/code-quality-standards.md#ide-integration)

### Detailed Documentation

For comprehensive coding standards, linting rules, and troubleshooting:

📖 **[Code Quality Standards](how-to/development/code-quality-standards.md)**

This includes:

- Language-specific style guides
- Security scanning requirements
- IDE integration guides
- Common issues and solutions

---

## Branching and Workflow

Fawkes uses a **fork → feature branch → PR against `main`** model.

### Step-by-Step Git Workflow

1. **Fork the repository** on GitHub (click "Fork" on the [fawkes repo](https://github.com/paruff/fawkes)):

2. **Clone your fork and add the upstream remote**:

   ```sh
   git clone https://github.com/<your-username>/fawkes.git
   cd fawkes
   git remote add upstream https://github.com/paruff/fawkes.git
   ```

3. **Create a Feature Branch** from the latest `main`:

   ```sh
   git fetch upstream
   git checkout -b feature/<feature-name> upstream/main
   ```

4. **Make changes and commit** using [Conventional Commits](https://www.conventionalcommits.org/):

   ```sh
   git commit -m "feat(scope): short description of the change"
   ```

   Commit prefixes: `feat`, `fix`, `docs`, `test`, `chore`.

5. **Push your branch** to your fork:

   ```sh
   git push origin feature/<feature-name>
   ```

6. **Open a Pull Request against `main`** on the upstream repository:
   - Fill in the PR template fully.
   - Reference the issue with `Closes #NNN`.
   - Keep the PR small (< 400 lines); CI enforces this limit.

7. **Address review feedback** by pushing additional commits to the same branch.

8. **Merge** — a maintainer merges once all status checks pass and approval is given.

> **Never push directly to `main`.** Branch protection requires all changes to go through a pull request with at least one maintainer approval (two approvals for changes in `infra/`) and passing CI checks.

---

## Testing

Fawkes includes multiple layers of testing:

- **Static Analysis**: Run tools like SonarQube or Trivy to check for vulnerabilities.
- **Unit Tests**: Located in the `qa/unit/` directory.
- **Integration Tests**: Located in the `qa/integration/` directory.
- **Acceptance Tests**: Located in the `qa/acceptance/` directory.
- **Performance Tests**: Located in the `qa/performance/` directory.

Run all tests before submitting a PR:

```sh
cd qa
./run-all-tests.sh
```

---

## Azure Development Best Practices

If you are working with Azure, follow these best practices:

1. **Use Azure CLI for Authentication**:

   ```sh
   az login
   ```

2. **Set the Active Subscription**:

   ```sh
   az account set --subscription <subscription-id>
   ```

3. **Follow Azure Resource Naming Conventions**:
   Use consistent and descriptive names for resources.

4. **Use Infrastructure as Code (IaC)**:
   Use Terraform or Bicep for provisioning Azure resources.

5. **Enable Logging and Monitoring**:
   Configure Azure Monitor and Log Analytics for all deployed resources.

6. **Secure Secrets**:
   Store secrets in Azure Key Vault and reference them in your deployments.

---

## Submitting Contributions

1. **Fork the Repository**:
   Create a fork of the repository on GitHub and clone it locally.

2. **Branch from `main`**:
   Always create a feature branch from the latest `main` (see [Branching and Workflow](#branching-and-workflow) above).

3. **Make Changes**:
   Work on your feature branch and ensure all tests pass.

4. **Run Linters**:
   ```sh
   make lint
   ```

5. **Submit a Pull Request against `main`**:
   Open a PR on the upstream repository with a detailed description of your changes and `Closes #NNN` referencing the issue.

6. **Address Feedback**:
   Respond to reviewer comments and make necessary updates.

---

## Need Help?

If you encounter any issues, refer to the [troubleshooting guide](troubleshooting.md) or open an issue on [GitHub](https://github.com/paruff/fawkes/issues).

---
