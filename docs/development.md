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
   ./buildinfra.sh -p aws -e dev
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

- **Language**: Follow the conventions of the language used in the respective module (e.g., Java, Python, Bash).
- **Linting**: Use linters to ensure code quality:
  - YAML: `yamllint`
  - Shell: `shellcheck`
  - Python: `flake8`
  - Java: Checkstyle or SonarQube
- **Documentation**: Add comments and update relevant documentation for any changes.

---

## Branching and Workflow

1. **Create a Feature Branch**:
   ```sh
   git checkout -b feature/<feature-name>
   ```

2. **Commit Changes**:
   Write clear and concise commit messages:
   ```sh
   git commit -m "Add <feature-name>: <short description>"
   ```

3. **Push Changes**:
   ```sh
   git push origin feature/<feature-name>
   ```

4. **Submit a Pull Request**:
   Open a pull request (PR) on GitHub and request a review.

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
   Create a fork of the repository on GitHub.

2. **Make Changes**:
   Work on your feature branch and ensure all tests pass.

3. **Submit a Pull Request**:
   Open a PR with a detailed description of your changes.

4. **Address Feedback**:
   Respond to reviewer comments and make necessary updates.

---

## Need Help?

If you encounter any issues, refer to the [troubleshooting guide](troubleshooting.md) or open an issue on [GitHub](https://github.com/paruff/fawkes/issues).

---