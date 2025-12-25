# Frequently Asked Questions (FAQ)

This document addresses common questions about the Fawkes Internal Developer Platform (IDP). If your question is not answered here, feel free to open an issue on [GitHub](https://github.com/paruff/fawkes/issues).

---

## General Questions

### 1. **What is Fawkes?**

Fawkes is an open source platform for provisioning secure, automated workspaces and Kubernetes-based continuous delivery pipelines across multiple cloud environments. It is designed to help teams adopt DevSecOps practices and improve their software delivery performance.

### 2. **What are the key influences behind Fawkes?**

Fawkes is heavily inspired by the [Accelerate](https://itrevolution.com/accelerate-book/) book, the [DORA](https://dora.dev/) (DevOps Research and Assessment) reports, and the State of DevOps reports. The platform focuses on improving the Four Key Metrics and implementing the 24 DORA capabilities, especially those related to Continuous Delivery.

---

## Setup and Configuration

### 3. **How do I set up Fawkes?**

Follow the [Getting Started Guide](getting-started.md) to set up your environment, provision infrastructure, and deploy platform services.

### 4. **What cloud providers are supported?**

Currently, Fawkes supports AWS. Azure, GCP, and VMware support are planned for future releases.

### 5. **How do I configure secrets?**

Secrets should be managed using tools like AWS Secrets Manager, Azure Key Vault, or Kubernetes Secrets. Refer to the [Configuration Guide](configuration.md) for details.

---

## Infrastructure and Platform

### 6. **What tools are used for infrastructure provisioning?**

Fawkes uses Terraform for Infrastructure as Code (IaC) and Helm for managing Kubernetes applications.

### 7. **How do I monitor my infrastructure and applications?**

Fawkes integrates with Prometheus and Grafana for monitoring. Additional integrations like Azure Monitor and the ELK stack are also supported. See the [Integrations Guide](integrations.md) for more details.

---

## CI/CD and Testing

### 8. **What CI/CD tools are supported?**

Fawkes supports Jenkins, GitHub Actions, and Azure DevOps Pipelines. Pre-configured pipelines and workflows are included to help you get started quickly.

### 9. **What types of testing are included?**

Fawkes includes static analysis, unit testing, integration testing, acceptance testing, performance testing, and security testing. Refer to the [QA Directory](../qa/readme.md) for more information.

---

## Troubleshooting

### 10. **What should I do if I encounter an issue?**

Refer to the [Troubleshooting Guide](troubleshooting.md) for solutions to common problems. If the issue persists, open an issue on [GitHub](https://github.com/paruff/fawkes/issues).

### 11. **How do I debug Kubernetes issues?**

Use `kubectl` to inspect resources and logs. For example:

```sh
kubectl describe pod <pod-name>
kubectl logs <pod-name>
```

Refer to the [Kubernetes Configuration](configuration.md#kubernetes-configuration) section for more details.

---

## Contributions

### 12. **How can I contribute to Fawkes?**

We welcome contributions! See the [Development Guide](development.md) for instructions on setting up your development environment and submitting pull requests.

### 13. **Are there any coding standards I should follow?**

Yes, Fawkes follows best practices for coding, testing, and documentation. Refer to the [Development Guide](development.md#coding-standards) for details.

---

## Azure-Specific Questions

### 14. **How do I authenticate with Azure?**

Use the Azure CLI to log in and set your subscription:

```sh
az login
az account set --subscription <subscription-id>
```

Follow Azure best practices for authentication and resource management. Refer to the [Azure Development Best Practices](development.md#azure-development-best-practices) section for more details.

### 15. **Does Fawkes support Azure DevOps?**

Yes, Fawkes supports Azure DevOps Pipelines for CI/CD. Pre-configured templates and best practices are included.

---

## Need More Help?

If your question is not answered here, you can:

1. Check the [Documentation](index.md) for additional resources.
2. Open an issue on [GitHub](https://github.com/paruff/fawkes/issues).
3. Reach out to the community for support.

---
