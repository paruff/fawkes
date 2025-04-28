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
