# Configuration

This document provides an overview of the configuration options for the Fawkes Internal Developer Platform. It explains how to set up and manage environment variables, secrets, and other configuration files to customize the platform for your needs.

---

## Table of Contents

- [Environment Variables](#environment-variables)
- [Secrets Management](#secrets-management)
- [Configuration Files](#configuration-files)
- [Cloud Provider Configuration](#cloud-provider-configuration)
- [Kubernetes Configuration](#kubernetes-configuration)
- [Best Practices](#best-practices)

---

## Environment Variables

Environment variables are used to configure various aspects of the platform. These variables can be set in a `.env` file or directly in your CI/CD pipeline.

### Example `.env` File

```env
# General settings
ENVIRONMENT=dev
REGION=us-east-1

# AWS-specific settings
AWS_ACCESS_KEY_ID=your-access-key
AWS_SECRET_ACCESS_KEY=your-secret-key

# Kubernetes settings
KUBECONFIG=/path/to/kubeconfig
```

### How to Use

- Copy the provided `.env.example` file to `.env` and update the values as needed.
- Load the environment variables using a script or your CI/CD pipeline.

---

## Secrets Management

Secrets should **never** be committed to version control. Use a secrets management tool to securely store and inject secrets at runtime.

### Recommended Tools

- **AWS Secrets Manager** (for AWS deployments)
- **Azure Key Vault** (for Azure deployments)
- **GCP Secret Manager** (for GCP deployments)
- **Kubernetes Secrets** (for cluster-specific secrets)

### Example Kubernetes Secret

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: my-secret
  namespace: default
type: Opaque
data:
  username: bXktdXNlcm5hbWU= # Base64 encoded
  password: cGFzc3dvcmQ= # Base64 encoded
```

---

## Configuration Files

Configuration files are used to define infrastructure, platform services, and application settings. These files are located in the `infra/` and `platform/` directories.

### Key Configuration Files

- **Terraform Variables:** Located in `infra/terraform/variables.tf`.
- **Helm Values:** Located in `platform/helm/values.yaml`.
- **Kubernetes Manifests:** Located in `platform/k8s/`.

### Example Helm Values

```yaml
replicaCount: 2
image:
  repository: nginx
  tag: "1.21.0"
  pullPolicy: IfNotPresent
```

---

## Cloud Provider Configuration

Each cloud provider requires specific configuration for authentication and resource provisioning.

### AWS

- Set `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` in your environment.
- Configure the region using `AWS_DEFAULT_REGION`.

### Azure

- Use the Azure CLI to authenticate:
  ```sh
  az login
  ```
- Set the subscription ID:
  ```sh
  az account set --subscription <subscription-id>
  ```

### GCP

- Authenticate using a service account key:
  ```sh
  gcloud auth activate-service-account --key-file=/path/to/key.json
  ```
- Set the project ID:
  ```sh
  gcloud config set project <project-id>
  ```

---

## Kubernetes Configuration

Kubernetes clusters require a valid `kubeconfig` file for authentication and management.

### Setting Up `kubeconfig`

- Use your cloud provider CLI to generate the `kubeconfig` file:

  - **AWS:** `aws eks update-kubeconfig --name <cluster-name>`
  - **Azure:** `az aks get-credentials --resource-group <resource-group> --name <cluster-name>`
  - **GCP:** `gcloud container clusters get-credentials <cluster-name>`

- Export the `KUBECONFIG` environment variable:
  ```sh
  export KUBECONFIG=/path/to/kubeconfig
  ```

---

## Best Practices

1. **Do Not Hardcode Secrets:** Always use a secrets management tool.
2. **Use Separate Environments:** Maintain separate configurations for `dev`, `staging`, and `prod`.
3. **Version Control Configuration Files:** Track non-sensitive configuration files in version control.
4. **Validate Configurations:** Use tools like `kubeval` or `terraform validate` to ensure configurations are valid.
5. **Automate Configuration Management:** Use CI/CD pipelines to manage and apply configurations.

---

For more details, refer to the specific documentation in the `infra/` and `platform/` directories.
