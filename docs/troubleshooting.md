# Troubleshooting Guide

This guide provides solutions to common issues encountered while using the Fawkes Internal Developer Platform. It is organized by category to help you quickly identify and resolve problems.

---

## Table of Contents

- [General Issues](#general-issues)
- [Infrastructure Issues](#infrastructure-issues)
- [Kubernetes Issues](#kubernetes-issues)
- [CI/CD Issues](#cicd-issues)
- [Azure-Specific Issues](#azure-specific-issues)
- [Testing Issues](#testing-issues)
- [Getting Help](#getting-help)

---

## General Issues

### 1. **Environment Variables Not Loaded**
- **Symptom:** Commands fail due to missing environment variables.
- **Solution:**
  - Ensure you have a `.env` file in the root directory.
  - Load the environment variables:
    ```sh
    source .env
    ```

### 2. **Permission Denied Errors**
- **Symptom:** You encounter `Permission Denied` errors when running scripts.
- **Solution:**
  - Ensure the script has executable permissions:
    ```sh
    chmod +x <script-name>.sh
    ```
  - Run the script with appropriate privileges (e.g., `sudo` if required).

---

## Infrastructure Issues

### 1. **Terraform Apply Fails**
- **Symptom:** Terraform fails with errors like "resource already exists" or "authentication failed."
- **Solution:**
  - Run `terraform plan` to identify conflicting resources.
  - Ensure your cloud provider credentials are valid and loaded:
    ```sh
    export AWS_ACCESS_KEY_ID=your-access-key
    export AWS_SECRET_ACCESS_KEY=your-secret-key
    ```

### 2. **Infrastructure Not Destroyed Properly**
- **Symptom:** Resources remain after running the destroy script.
- **Solution:**
  - Manually inspect the resources in your cloud provider's console.
  - Run `terraform destroy` directly in the affected directory:
    ```sh
    terraform destroy
    ```

---

## Kubernetes Issues

### 1. **Kubernetes Cluster Unreachable**
- **Symptom:** `kubectl` commands fail with "Unable to connect to the server."
- **Solution:**
  - Ensure your `kubeconfig` is set correctly:
    ```sh
    export KUBECONFIG=/path/to/kubeconfig
    ```
  - Verify the cluster status:
    ```sh
    kubectl cluster-info
    ```

### 2. **Pods Stuck in Pending State**
- **Symptom:** Pods remain in the `Pending` state.
- **Solution:**
  - Check for insufficient resources:
    ```sh
    kubectl describe pod <pod-name>
    ```
  - Scale up your cluster or free up resources.

---

## CI/CD Issues

### 1. **Jenkins Pipeline Fails**
- **Symptom:** Jenkins pipelines fail with errors related to missing credentials or tools.
- **Solution:**
  - Verify that the required credentials are configured in Jenkins.
  - Ensure the Jenkins agent has the necessary tools installed.

### 2. **GitHub Actions Workflow Fails**
- **Symptom:** GitHub Actions fail with errors like "command not found" or "authentication failed."
- **Solution:**
  - Check the workflow logs for detailed error messages.
  - Ensure secrets are configured correctly in the repository settings.

---

## Azure-Specific Issues

### 1. **Azure CLI Authentication Fails**
- **Symptom:** Azure CLI commands fail with "not logged in" or "authentication failed."
- **Solution:**
  - Log in to Azure CLI:
    ```sh
    az login
    ```
  - Set the correct subscription:
    ```sh
    az account set --subscription <subscription-id>
    ```

### 2. **Resource Group Not Found**
- **Symptom:** Terraform or Azure CLI commands fail with "resource group not found."
- **Solution:**
  - Verify the resource group exists:
    ```sh
    az group list --query "[].name"
    ```
  - Create the resource group if necessary:
    ```sh
    az group create --name <resource-group> --location <location>
    ```

---

## Testing Issues

### 1. **Tests Fail Due to Missing Dependencies**
- **Symptom:** Tests fail with errors like "module not found" or "dependency missing."
- **Solution:**
  - Install the required dependencies:
    ```sh
    mvn clean install
    ```

### 2. **Performance Tests Fail**
- **Symptom:** Performance tests fail with timeout or resource errors.
- **Solution:**
  - Ensure the test environment has sufficient resources.
  - Adjust the test parameters (e.g., reduce load or increase timeouts).

---

## Getting Help

If you are unable to resolve an issue, you can:

1. Check the [FAQ](faq.md) for additional guidance.
2. Open an issue on [GitHub](https://github.com/paruff/fawkes/issues) with detailed information about the problem.
3. Reach out to the community for support.

---