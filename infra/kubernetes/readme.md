# Fawkes Platform Infrastructure

This directory contains the **Infrastructure as Code (IaC)** and automation scripts for provisioning and managing the Fawkes platform layer across multiple cloud providers.

## Structure

- **Cloud Providers:**
  Subdirectories for each supported cloud (e.g., `aws/`, `azure/`, `gcp/`) contain Terraform modules and scripts to provision Kubernetes clusters and supporting infrastructure.
- **k8s/**
  Contains configuration and manifests for platform tools deployed into Kubernetes (e.g., Jenkins, monitoring, security tools).

## What Does This Provide?

- **Kubernetes Infrastructure:**
  Automated creation of a Kubernetes cluster with namespaces for `platform`, `dev`, `test`, and `prod` to support environment isolation and secure delivery workflows.
- **Platform Layer:**
  Automated deployment of a Jenkins-based CI/CD pipeline in the `platform` namespace, including quality and security gates for visibility and control over your product code base.
- **DevSecOps by Design:**
  Integrates security and quality checks into the pipeline, supporting DORA best practices for elite software delivery performance.
- **Rapid, Repeatable Delivery:**
  Enables teams to provision infrastructure and deploy products quickly, reliably, and with confidence.

## Key Features

- **Multi-Cloud Ready:**
  Modular scripts and Terraform modules for AWS, Azure, GCP, and more.
- **Environment Isolation:**
  Namespaces for platform services, development, testing, and production.
- **CI/CD Automation:**
  Jenkins pipelines with built-in quality and security testing.
- **Observability & Compliance:**
  Integrated monitoring and policy-as-code for visibility and governance.

## Secret Management (GitOps-Friendly)

Fawkes uses **External Secrets Operator** to pull secrets from cloud vaults (AWS Secrets Manager, Azure Key Vault) instead of committing Kubernetes `Secret` objects with inline data:

### Pattern

1. Define a `ClusterSecretStore` per cloud provider (e.g. `aws-secrets-manager`, `azure-keyvault`).
2. Reference the store from `ExternalSecret` objects (e.g. `externalsecret-jenkins-admin.yaml`).
3. Helm-managed operator reconciles remote keys into Kubernetes `Secret`s.
4. Service workloads mount only the synthesized in-cluster secret.

### Benefits

- Zero plaintext secrets in Git (audit-safe).
- Rotation handled at source; operator refreshes on interval.
- Multi-cloud abstraction with consistent Kubernetes API.
- Enables IRSA (AWS) / Workload Identity (Azure) for vault access without static credentials.

### Example (Jenkins Admin Password)

`infra/kubernetes/external-secrets/externalsecret-jenkins-admin.yaml` pulls `jenkins/admin/password` from the selected store and creates `Secret jenkins-admin` consumed by the Jenkins chart.

### Migration Guide

| Legacy | New | Action |
|--------|-----|--------|
| Inline base64 `Secret` | `ExternalSecret` + remote key | Replace file, commit |
| SealedSecret | ExternalSecret | Optional: decrypt and move key to vault |

### AWS Setup Notes

- Annotate operator service account with IAM role granting `secretsmanager:GetSecretValue`.
- Use OIDC provider output from Terraform (`cluster_oidc_issuer_url`) when configuring IRSA.

### Azure Setup Notes

- Enable AKS workload identity outputs (`oidc_issuer_url`).
- Grant Key Vault `get` permissions to the operator's managed identity.

See directory: `infra/kubernetes/external-secrets/` for manifests and ArgoCD Application.

## Getting Started

1. **Choose your cloud provider directory** (e.g., `aws/`) and follow the instructions in its README to provision infrastructure.
2. **Deploy platform tools** using the scripts and manifests in the `k8s/` directory.
3. **Run the pipeline** to build, test, and deploy your product with full visibility and quality/security gates.

## Why Fawkes Platform Infra?

- **DORA-Aligned:**
  Designed to help teams achieve high deployment frequency, fast lead time, low change failure rate, and quick recovery.
- **Empowers Teams:**
  Delivery teams can provision, test, and deploy infrastructure and applications with confidence and speed.
- **Open Source & Extensible:**
  Easily adapt the scripts and modules to your organization's needs.

---

_Fawkes Platform Infra: Deliver fast, deliver better, deliver with confidence._
