# Getting Started with Fawkes

Welcome to the Fawkes Internal Developer Platform! This guide will help you set up your environment, deploy the platform, and start using its features.

---

## Prerequisites

- **Git** (for cloning the repository)
- **Docker** (for local development and container builds)
- **Terraform** (for infrastructure provisioning)
- **kubectl** (for Kubernetes management)
- **Helm** (for managing Kubernetes applications)
- Cloud CLI tools as needed (e.g., AWS CLI, Azure CLI, GCloud CLI)

---

## 1. Clone the Repository

```sh
git clone https://github.com/paruff/fawkes.git
cd fawkes
```

---

## 2. Review the Directory Structure

- `infra/` – Infrastructure as Code (Terraform, Kubernetes, scripts)
- `platform/` – Platform services, APIs, and UI
- `workspace/` – Developer environment automation
- `qa/` – Quality assurance and test suites
- `docs/` – Documentation

---

## 3. Configure Your Environment

- Copy and edit any example configuration files (e.g., `.env.example`).
- Set up required secrets and environment variables as described in [configuration.md](configuration.md).

---

## 4. Provision Infrastructure

Navigate to the `infra/` directory and follow the instructions for your cloud provider:

```sh
cd infra
# Example for AWS
./infra-boot.sh -p aws -e dev
```

See [architecture.md](architecture.md) for more details on supported platforms and environments.

---

## 5. Deploy Platform Services

After infrastructure is ready, deploy platform services (e.g., Jenkins, SonarQube):

```sh
cd platform
# Example: Deploy Jenkins
./jenkins-delta.sh -i
```

Refer to the [usage guide](usage.md) for more service deployment options.

---

## 6. Access the Platform

- Find service endpoints and credentials in the output of your deployment scripts or in the [show outputs](usage.md#showing-outputs) section.
- Access the developer dashboard, CI/CD tools, and other services via your browser.

---

## 7. Next Steps

- Explore the [usage guide](usage.md) for workflows and examples.
- Review [development.md](development.md) if you want to contribute.
- Check [troubleshooting.md](troubleshooting.md) for help with common issues.

---

## Need Help?

- See the [FAQ](faq.md)
- Open an issue on [GitHub](https://github.com/paruff/fawkes/issues)

---
```<!-- filepath: /Users/philruff/projects/github/paruff/fawkes/docs/getting-started.md -->
# Getting Started with Fawkes

Welcome to the Fawkes Internal Developer Platform! This guide will help you set up your environment, deploy the platform, and start using its features.

---

## Prerequisites

- **Git** (for cloning the repository)
- **Docker** (for local development and container builds)
- **Terraform** (for infrastructure provisioning)
- **kubectl** (for Kubernetes management)
- **Helm** (for managing Kubernetes applications)
- Cloud CLI tools as needed (e.g., AWS CLI, Azure CLI, GCloud CLI)

---

## 1. Clone the Repository

```sh
git clone https://github.com/paruff/fawkes.git
cd fawkes
```

---

## 2. Review the Directory Structure

- `infra/` – Infrastructure as Code (Terraform, Kubernetes, scripts)
- `platform/` – Platform services, APIs, and UI
- `workspace/` – Developer environment automation
- `qa/` – Quality assurance and test suites
- `docs/` – Documentation

---

## 3. Configure Your Environment

- Copy and edit any example configuration files (e.g., `.env.example`).
- Set up required secrets and environment variables as described in [configuration.md](configuration.md).

---

## 4. Provision Infrastructure

Navigate to the `infra/` directory and follow the instructions for your cloud provider:

```sh
cd infra
# Example for AWS
./infra-boot.sh -p aws -e dev
```

See [architecture.md](architecture.md) for more details on supported platforms and environments.

---

## 5. Deploy Platform Services

After infrastructure is ready, deploy platform services (e.g., Jenkins, SonarQube):

```sh
cd platform
# Example: Deploy Jenkins
./jenkins-delta.sh -i
```

Refer to the [usage guide](usage.md) for more service deployment options.

---

## 6. Access the Platform

- Find service endpoints and credentials in the output of your deployment scripts or in the [show outputs](usage.md#showing-outputs) section.
- Access the developer dashboard, CI/CD tools, and other services via your browser.

---

## 7. Next Steps

- Explore the [usage guide](usage.md) for workflows and examples.
- Review [development.md](development.md) if you want to contribute.
- Check [troubleshooting.md](troubleshooting.md) for help with common issues.

---

## Need Help?

- See the [FAQ](faq.md)
- Open an issue on [GitHub](https://github.com/paruff/fawkes/issues)

---