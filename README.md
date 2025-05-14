# Fawkes

**Fawkes** is an open-source platform for rapidly provisioning secure, automated workspaces and Kubernetes-based continuous delivery pipelines across multiple cloud environments. It is designed for modern DevSecOps teams who want to leverage Infrastructure as Code (IaC), platform automation, and robust testing to accelerate delivery while maintaining security and compliance.

> **Influences:**  
> Fawkes is heavily inspired by the research and best practices from the [Accelerate](https://itrevolution.com/accelerate-book/) book, the [DORA](https://dora.dev/) (DevOps Research and Assessment) reports, and the State of DevOps reports. The platform is designed to help teams improve the [Four Key Metrics](https://www.devops-research.com/research.html) (Deployment Frequency, Lead Time for Changes, Change Failure Rate, and Mean Time to Restore) and to implement the [24 DORA capabilities](https://dora.dev/), with a particular focus on the 8 capabilities related to Continuous Delivery.

---

## Overview

Fawkes provides:

- **Automated Infrastructure Provisioning**: Uses Terraform and modular scripts to provision Kubernetes clusters and supporting cloud infrastructure on AWS (with plans for Azure, Google Cloud, VMware, and more).
- **DevSecOps by Design**: Integrates security best practices, policy-as-code, and automated compliance checks into the platform and CI/CD pipelines.
- **Workspace Automation**: Supports developer workspaces on Windows and macOS using Chocolatey and Homebrew, with future plans for browser-based workspaces (e.g., Eclipse Che).
- **Platform as Code**: All platform components (CI/CD, artifact management, monitoring, etc.) are deployed and managed as code for repeatability and auditability.
- **Testing and Validation**: Includes automated tests for infrastructure, platform components, and developer environments to ensure reliability and security.
- **Open Source Collaboration**: Contributions are welcome! See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

---

## Features

- **Multi-Cloud Ready**: AWS support today; Azure, GCP, and VMware coming soon.
- **IaC & GitOps**: Declarative infrastructure and platform management using Terraform, Helm, and GitOps workflows.
- **Security & Compliance**: Built-in security group management, IAM controls, and support for policy-as-code.
- **Developer Experience**: Automated setup for local and remote workspaces, including all required tools and extensions.
- **Extensible Platform**: Starter templates for Java Spring Boot and other languages; easy to add your own.
- **DORA Metrics & Capabilities**: Platform design and included tools help you measure and improve the Four Key Metrics and implement DORA’s 24 capabilities, especially for Continuous Delivery.

---

## 🚀 Getting Started

Follow these steps to set up and use Fawkes:

1. **Clone the Repository**:
   ```sh
   git clone https://github.com/paruff/fawkes.git
   cd fawkes
   ```

2. **Provision Infrastructure**:
   - Navigate to the `infra/` directory and use the provided scripts to provision your Kubernetes cluster and supporting resources:
     ```sh
     ./buildinfra.sh -p aws -e dev
     ```
   - Replace `aws` with your cloud provider (e.g., `azure`, `gcp`) and `dev` with your environment name.

3. **Set Up Your Workspace**:
   - Use the scripts in `infra/workspace/` to automate your local development environment setup (Windows/macOS):
     ```sh
     ./setup-OS-space.sh
     ```

4. **Deploy Platform Components**:
   - Deploy CI/CD, artifact management, monitoring, and more via Helm charts:
     ```sh
     ./buildplatform.sh
     ```

5. **Test & Validate**:
   - Run included InSpec and integration tests to validate your environment:
     ```sh
     ./run-tests.sh
     ```

For detailed instructions, see the [Getting Started Guide](docs/getting-started.md).

---

## Roadmap

- [ ] **Azure, Google Cloud, and VMware Support**: Expand multi-cloud capabilities.
- [ ] **Browser-Based Workspaces**: Add support for Eclipse Che and similar tools.
- [ ] **Enhanced Policy-as-Code**: Strengthen compliance automation and policy enforcement.
- [ ] **Additional Starter Templates**: Include templates for Python, Node.js, and Go.

---

## Contributing

Fawkes is open source and community-driven. Issues, feature requests, and pull requests are welcome!

See [CONTRIBUTING.md](CONTRIBUTING.md) for details.

---

## License

This project is licensed under the [MIT License](LICENSE).

---

Fawkes is named after Dumbledore's phoenix, symbolizing resilience and renewal, and inspired by [Guy Fawkes](https://en.wikipedia.org/wiki/Guy_Fawkes) from British history.

---

## Learn More

- [Documentation](docs/index.md): Explore detailed guides and references.
- [Troubleshooting Guide](docs/troubleshooting.md): Resolve common issues.
- [Development Guide](docs/development.md): Contribute to Fawkes or customize it for your needs.
