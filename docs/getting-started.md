# Getting Started with Fawkes

Welcome to the Fawkes Internal Developer Platform! This guide will help you set up your environment, deploy the platform, and start using its features.

---

## Prerequisites

Before you begin, ensure you have the following tools installed:

- **Git**: For cloning the repository.
- **Docker**: For local development and container builds.
- **Terraform**: For infrastructure provisioning.
- **kubectl**: For Kubernetes management.
- **Helm**: For managing Kubernetes applications.
- **Cloud CLI tools**: As needed for your cloud provider (e.g., AWS CLI, Azure CLI, GCloud CLI).

---

## 1. Clone the Repository

Start by cloning the Fawkes repository:

```sh
git clone https://github.com/paruff/fawkes.git
cd fawkes
```

---

## 2. Review the Directory Structure

Familiarize yourself with the repository structure:

- `infra/`: Infrastructure as Code (Terraform, Kubernetes, scripts).
- `platform/`: Platform services, APIs, and UI.
- `workspace/`: Developer environment automation.
- `qa/`: Quality assurance and test suites.
- `docs/`: Documentation.

---

## 3. Configure Your Environment

1. Copy and edit any example configuration files:
   ```sh
   cp .env.example .env
   ```
2. Set up required secrets and environment variables as described in [configuration.md](configuration.md).

---

## 4. Provision Infrastructure

Navigate to the `infra/` directory and follow the instructions for your cloud provider:

```sh
cd infra
# Example for AWS
./buildinfra.sh -p aws -e dev
```

For more details on supported platforms and environments, see [architecture.md](architecture.md).

---

## 5. Deploy Platform Services

Once the infrastructure is ready, deploy platform services (e.g., Jenkins, SonarQube):

```sh
cd platform
# Example: Deploy Jenkins
./jenkins-delta.sh -i
```

Refer to the [usage guide](usage.md) for additional service deployment options.

---

## 6. Access the Platform

1. Find service endpoints and credentials in the output of your deployment scripts or in the [show outputs](usage.md#showing-outputs) section.
2. Access the developer dashboard, CI/CD tools, and other services via your browser.

---

## 7. Next Steps

- Explore the [usage guide](usage.md) for workflows and examples.
- Review [development.md](development.md) if you want to contribute.
- Check [troubleshooting.md](troubleshooting.md) for help with common issues.

---

## Need Help?

If you encounter any issues or have questions:

- See the [FAQ](faq.md) for common questions.
- Open an issue on [GitHub](https://github.com/paruff/fawkes/issues).

---

Thank you for choosing Fawkes! We’re excited to help you build better, faster, and more reliable infrastructure.