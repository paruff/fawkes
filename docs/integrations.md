# Integrations

This document provides an overview of the integrations supported by the Fawkes Internal Developer Platform (IDP). These integrations enhance the platform's capabilities by connecting it with external tools and services for CI/CD, monitoring, security, and more.

---

## Table of Contents

- [CI/CD Integrations](#cicd-integrations)
- [Monitoring and Logging](#monitoring-and-logging)
- [Security and Compliance](#security-and-compliance)
- [Cloud Provider Integrations](#cloud-provider-integrations)
- [Developer Tools](#developer-tools)
- [Extending Integrations](#extending-integrations)

---

## CI/CD Integrations

Fawkes supports seamless integration with popular CI/CD tools to automate build, test, and deployment pipelines.

- **Jenkins:**  
  Pre-configured pipelines for building and deploying applications.  
  See the [Jenkins integration guide](../platform/jenkins/README.md) for setup instructions.

- **GitHub Actions:**  
  Use GitHub Actions workflows for CI/CD directly from your repository.  
  Example workflows are provided in the `.github/workflows/` directory.

- **Azure DevOps Pipelines:**  
  Integrate with Azure DevOps for end-to-end CI/CD pipelines.  
  Follow Azure best practices for pipeline configuration.

---

## Monitoring and Logging

Fawkes integrates with monitoring and logging tools to provide visibility into your infrastructure and applications.

- **Prometheus and Grafana:**  
  Pre-configured Helm charts for Prometheus and Grafana to monitor Kubernetes clusters and applications.  
  See the [Prometheus setup guide](../platform/k8s/prometheus/README.md).

- **Azure Monitor:**  
  Use Azure Monitor for centralized logging and metrics collection.  
  Follow Azure best practices for configuring Log Analytics and Application Insights.

- **ELK Stack (Elasticsearch, Logstash, Kibana):**  
  Optional integration for advanced log aggregation and visualization.

---

## Security and Compliance

Fawkes includes integrations with tools to ensure security and compliance across your infrastructure and applications.

- **Trivy:**  
  Scan container images for vulnerabilities before deployment.

- **OWASP ZAP:**  
  Perform dynamic application security testing (DAST) on your web applications.

- **Azure Policy:**  
  Enforce compliance policies for Azure resources.  
  Use Azure best practices for configuring and managing policies.

- **Snyk:**  
  Identify and fix vulnerabilities in your dependencies.

---

## Cloud Provider Integrations

Fawkes supports multi-cloud deployments with integrations for major cloud providers.

- **AWS:**  
  Provision infrastructure using Terraform and manage resources with the AWS CLI.  
  See the [AWS integration guide](../infra/platform/aws/README.md).

- **Azure:**  
  Use Azure CLI and Terraform to provision and manage resources.  
  Follow Azure best practices for authentication, resource groups, and networking.

- **Google Cloud Platform (GCP):**  
  Integrate with GCP for Kubernetes (GKE) and other cloud services.

---

## Developer Tools

Fawkes integrates with tools to enhance the developer experience.

- **SonarQube:**  
  Perform static code analysis to ensure code quality and security.

- **Keycloak:**  
  Optional integration for single sign-on (SSO) and identity management.

- **Docker:**  
  Use Docker for local development and containerized applications.

- **Azure Dev Spaces:**  
  Enable collaborative development in Kubernetes clusters.  
  Follow Azure best practices for setting up Dev Spaces.

---

## Extending Integrations

Fawkes is designed to be extensible. You can add new integrations by:

1. Adding configuration files or scripts in the appropriate directory (e.g., `infra/`, `platform/`).
2. Updating the documentation in this file to reflect the new integration.
3. Testing the integration in your environment.

---

## Need Help?

If you encounter issues with any integration, refer to the specific tool's documentation or open an issue on [GitHub](https://github.com/paruff/fawkes/issues).

---