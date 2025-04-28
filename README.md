# Fawkes

**Fawkes** is an open source platform for rapidly provisioning secure, automated workspaces and Kubernetes-based continuous delivery pipelines across multiple cloud environments. It is designed for modern DevSecOps teams who want to leverage Infrastructure as Code (IaC), platform automation, and robust testing to accelerate delivery while maintaining security and compliance.

## Overview

Fawkes provides:

- **Automated Infrastructure Provisioning:** Uses Terraform and modular scripts to provision Kubernetes clusters and supporting cloud infrastructure on AWS (with plans for Azure, Google Cloud, VMware, and more).
- **DevSecOps by Design:** Integrates security best practices, policy-as-code, and automated compliance checks into the platform and CI/CD pipelines.
- **Workspace Automation:** Supports developer workspaces on Windows and macOS using Chocolatey and Homebrew, with future plans for browser-based workspaces (e.g., Eclipse Che).
- **Platform as Code:** All platform components (CI/CD, artifact management, monitoring, etc.) are deployed and managed as code for repeatability and auditability.
- **Testing and Validation:** Includes automated tests for infrastructure, platform components, and developer environments to ensure reliability and security.
- **Open Source Collaboration:** Contributions are welcome! See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## Features

- **Multi-Cloud Ready:** AWS support today; Azure, GCP, and VMware coming soon.
- **IaC & GitOps:** Declarative infrastructure and platform management using Terraform, Helm, and GitOps workflows.
- **Security & Compliance:** Built-in security group management, IAM controls, and support for policy-as-code.
- **Developer Experience:** Automated setup for local and remote workspaces, including all required tools and extensions.
- **Extensible Platform:** Starter templates for Java Spring Boot and other languages; easy to add your own.

## Getting Started

1. **Clone the repository:**

   ```sh
   git clone https://github.com/paruff/fawkes.git
   cd fawkes
   ```

2. **Provision Infrastructure:**

   - See [`infra/platform/`](infra/platform/) for scripts and Terraform modules to provision your Kubernetes cluster and supporting resources.

3. **Set Up Your Workspace:**

   - Use the scripts in [`infra/workspace/`](infra/workspace/) to automate your local development environment setup (Windows/macOS).

4. **Deploy Platform Components:**

   - Automated deployment of CI/CD, artifact management, monitoring, and more via Helm charts.

5. **Test & Validate:**
   - Run included InSpec and integration tests to validate your environment.

## Roadmap

- [ ] Azure, Google Cloud, and VMware support
- [ ] Browser-based workspaces (Eclipse Che)
- [ ] More language/framework starter templates
- [ ] Enhanced policy-as-code and compliance automation

## Contributing

Fawkes is open source and community-driven. Issues, feature requests, and pull requests are welcome!

See [CONTRIBUTING.md](CONTRIBUTING.md) for details.

## License

This project is licensed under the [MIT License](LICENSE).

---

Fawkes is named after Dumbledore's phoenix, symbolizing resilience and renewal, and inspired by [Guy Fawkes](https://en.wikipedia.org/wiki/Guy_Fawkes) from British history.
