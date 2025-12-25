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

---

## Epic 1 Platform Component Issues

### ArgoCD Issues

#### Application Won't Sync

- **Symptom:** ArgoCD application shows `OutOfSync` status and won't sync.
- **Solution:**
  - Check application details:
    ```sh
    argocd app get <app-name>
    argocd app diff <app-name>
    ```
  - Force sync if needed:
    ```sh
    argocd app sync <app-name> --force
    ```
  - Check ArgoCD logs:
    ```sh
    kubectl logs -n argocd -l app.kubernetes.io/name=argocd-server --tail=100
    ```

#### ArgoCD UI Not Accessible

- **Symptom:** Cannot access ArgoCD dashboard.
- **Solution:**
  - Check ArgoCD pods are running:
    ```sh
    kubectl get pods -n argocd
    ```
  - Port-forward to access UI:
    ```sh
    kubectl port-forward svc/argocd-server -n argocd 8080:443
    ```
  - Check ingress configuration:
    ```sh
    kubectl get ingress -n argocd
    ```

### Backstage Issues

#### Backstage Won't Start

- **Symptom:** Backstage pods in `CrashLoopBackOff` or `Error` state.
- **Solution:**
  - Check pod logs:
    ```sh
    kubectl logs -n backstage -l app=backstage --tail=100
    ```
  - Verify PostgreSQL database is running:
    ```sh
    kubectl get pods -n backstage -l cnpg.io/cluster=db-backstage-dev
    ```
  - Check database connection:
    ```sh
    kubectl exec -n backstage db-backstage-dev-1 -- psql -U postgres -c "SELECT 1"
    ```

#### Catalog Not Loading

- **Symptom:** Service catalog shows no entities or fails to load.
- **Solution:**
  - Check Backstage logs for catalog errors:
    ```sh
    kubectl logs -n backstage -l app=backstage | grep -i catalog
    ```
  - Verify GitHub token is valid:
    ```sh
    kubectl get secret -n backstage backstage-secrets -o yaml
    ```
  - Manually trigger catalog refresh from Backstage UI

### Jenkins Issues

#### Jenkins Builds Stuck in Queue

- **Symptom:** Builds queue but never start.
- **Solution:**
  - Check if Jenkins agents can be created:
    ```sh
    kubectl get pods -n jenkins -l jenkins/label
    ```
  - Check Jenkins controller logs:
    ```sh
    kubectl logs -n jenkins -l app.kubernetes.io/component=jenkins-controller --tail=200
    ```
  - Verify Jenkins has permissions to create pods:
    ```sh
    kubectl auth can-i create pods -n jenkins --as=system:serviceaccount:jenkins:jenkins
    ```

#### Quality Gate Failures

- **Symptom:** Builds fail at SonarQube quality gate stage.
- **Solution:**
  - Check SonarQube analysis results:
    ```sh
    # Access SonarQube UI
    kubectl port-forward svc/sonarqube-sonarqube -n sonarqube 9000:9000
    ```
  - Review quality gate conditions in SonarQube dashboard
  - Check if issues are legitimate or need quality gate adjustment
  - See [Quality Gates Configuration Guide](how-to/security/quality-gates-configuration.md)

### Vault Issues

#### Vault Pod Sealed

- **Symptom:** Vault pods show "Sealed" status.
- **Solution:**
  - Check vault status:
    ```sh
    kubectl exec -n vault vault-0 -- vault status
    ```
  - Unseal vault (requires unseal keys):
    ```sh
    kubectl exec -n vault vault-0 -- vault operator unseal <key-1>
    kubectl exec -n vault vault-0 -- vault operator unseal <key-2>
    kubectl exec -n vault vault-0 -- vault operator unseal <key-3>
    ```
  - Repeat for each vault pod (vault-0, vault-1, vault-2)

#### Application Can't Access Secrets

- **Symptom:** Application pods fail to start with secret-related errors.
- **Solution:**
  - Verify Vault is unsealed:
    ```sh
    kubectl exec -n vault vault-0 -- vault status
    ```
  - Check External Secrets Operator:
    ```sh
    kubectl get externalsecrets -n <namespace>
    kubectl describe externalsecret <name> -n <namespace>
    ```
  - Check service account has proper Vault role:
    ```sh
    kubectl exec -n vault vault-0 -- vault read auth/kubernetes/role/<role-name>
    ```

### Prometheus/Grafana Issues

#### Metrics Not Showing in Grafana

- **Symptom:** Dashboards show "No data" or empty graphs.
- **Solution:**
  - Check Prometheus is scraping targets:
    ```sh
    kubectl port-forward svc/prometheus-kube-prometheus-prometheus -n prometheus 9090:9090
    # Navigate to http://localhost:9090/targets
    ```
  - Verify ServiceMonitor exists:
    ```sh
    kubectl get servicemonitors -n <namespace>
    ```
  - Check Prometheus logs:
    ```sh
    kubectl logs -n prometheus prometheus-kube-prometheus-prometheus-0
    ```
  - Verify Grafana data source configuration

#### Prometheus Out of Storage

- **Symptom:** Prometheus pod fails with storage errors.
- **Solution:**
  - Check PVC usage:
    ```sh
    kubectl exec -n prometheus prometheus-kube-prometheus-prometheus-0 -- df -h
    ```
  - Increase PVC size:
    ```sh
    kubectl patch pvc prometheus-kube-prometheus-prometheus-db-prometheus-kube-prometheus-prometheus-0 -n prometheus -p '{"spec":{"resources":{"requests":{"storage":"100Gi"}}}}'
    ```
  - Or reduce retention period in Prometheus configuration

### Harbor Issues

#### Can't Push Images to Harbor

- **Symptom:** Docker push fails with authentication or permission errors.
- **Solution:**
  - Verify Harbor is accessible:
    ```sh
    curl -k https://harbor.fawkes.local
    ```
  - Login to Harbor:
    ```sh
    docker login harbor.fawkes.local
    ```
  - Check Harbor project permissions in UI
  - Verify TLS certificate is trusted

#### Harbor Scan Failing

- **Symptom:** Vulnerability scanning fails or shows errors.
- **Solution:**
  - Check Trivy scanner logs:
    ```sh
    kubectl logs -n harbor -l component=trivy --tail=100
    ```
  - Verify Trivy database is updated:
    ```sh
    kubectl exec -n harbor <trivy-pod> -- trivy --version
    ```
  - Check network connectivity to vulnerability database

### DevLake Issues

#### DORA Metrics Not Updating

- **Symptom:** DevLake dashboards show stale or missing data.
- **Solution:**
  - Check DevLake pods:
    ```sh
    kubectl get pods -n devlake
    ```
  - Check data collection logs:
    ```sh
    kubectl logs -n devlake -l app.kubernetes.io/name=devlake --tail=100
    ```
  - Verify connections to data sources (GitHub, ArgoCD, Jenkins):
    ```sh
    # Access DevLake UI
    kubectl port-forward svc/devlake-ui -n devlake 4000:4000
    # Navigate to http://localhost:4000 and check connections
    ```
  - Manually trigger data collection if needed

### Kyverno Policy Issues

#### Pods Blocked by Policy

- **Symptom:** Pods fail to create with policy violation errors.
- **Solution:**
  - Check policy reports:
    ```sh
    kubectl get policyreports -n <namespace>
    kubectl describe policyreport <report-name> -n <namespace>
    ```
  - Review specific violation:
    ```sh
    kubectl get events -n <namespace> | grep -i policy
    ```
  - Fix pod manifest to comply with policy or request policy exception
  - See [Troubleshoot Kyverno Violations](how-to/policy/troubleshoot-kyverno-violation.md)

### Certificate Issues

#### TLS Certificate Errors

- **Symptom:** Services show certificate errors or invalid certificates.
- **Solution:**
  - Check certificate status:
    ```sh
    kubectl get certificates -A
    kubectl describe certificate <cert-name> -n <namespace>
    ```
  - Check cert-manager logs:
    ```sh
    kubectl logs -n cert-manager -l app=cert-manager --tail=100
    ```
  - Force certificate renewal:
    ```sh
    kubectl delete secret <tls-secret-name> -n <namespace>
    ```
  - Check ACME challenge (for Let's Encrypt):
    ```sh
    kubectl get challenges -A
    ```

### Resource Exhaustion

#### Cluster Running Out of Resources

- **Symptom:** Pods stuck in `Pending` state, nodes showing high CPU/memory.
- **Solution:**
  - Check node resource usage:
    ```sh
    kubectl top nodes
    kubectl describe nodes | grep -A 5 "Allocated resources"
    ```
  - Identify resource-hungry pods:
    ```sh
    kubectl top pods -A | sort -k 3 -rn | head -20
    ```
  - Scale down non-critical workloads:
    ```sh
    kubectl scale deployment <deployment-name> -n <namespace> --replicas=1
    ```
  - Delete completed/failed pods:
    ```sh
    kubectl delete pod --field-selector status.phase=Succeeded -A
    kubectl delete pod --field-selector status.phase=Failed -A
    ```
  - Consider adding nodes or increasing node resources

---

## Getting Help

If you are unable to resolve an issue, you can:

1. Check the [Epic 1 Platform Operations Runbook](runbooks/epic-1-platform-operations.md) for detailed procedures
2. Check the [FAQ](faq.md) for additional guidance
3. Open an issue on [GitHub](https://github.com/paruff/fawkes/issues) with detailed information about the problem
4. Reach out to the community for support

---
