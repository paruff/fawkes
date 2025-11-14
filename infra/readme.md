# Fawkes Infrastructure Automation

Welcome to the Fawkes Infrastructure Automation repository!
This directory contains the **Infrastructure as Code (IaC)** scripts and automation for the Fawkes platform. It enables rapid, repeatable provisioning of Kubernetes infrastructure and a secure, observable CI/CD pipeline, empowering teams to deliver products quickly and confidently.

---

## 🚀 Getting Started

Follow these steps to set up and use the Fawkes infrastructure:

### 1. Prepare Your Local Environment

Ensure the following tools are installed on your system:

- **Git**: For cloning the repository.
- **Docker**: For containerized development.
- **Terraform**: For infrastructure provisioning.
- **kubectl**: For Kubernetes management.
- **Helm**: For managing Kubernetes applications.
- **Cloud CLI tools**: As needed for your cloud provider (e.g., AWS CLI, Azure CLI, GCloud CLI).

---

### 2. Clone the Repository

Clone the Fawkes repository to your local machine:

```sh
git clone https://github.com/paruff/fawkes.git
cd fawkes/infra
```

---

### 3. Provision Infrastructure

Use the provided scripts to provision infrastructure for your environment:

```sh
./buildinfra.sh -p aws -e dev
```

Replace `aws` with your cloud provider (e.g., `azure`, `gcp`) and `dev` with your environment name.

---

### 4. Deploy Platform Services

Once the infrastructure is ready, deploy platform services (e.g., Jenkins, SonarQube):

```sh
cd platform
./buildplatform.sh
```

Refer to the [Platform Infrastructure Guide](platform/readme.md) for more details.

---

### 5. Access Your Services

After deployment, retrieve service URLs and credentials from the deployment output or using the following commands:

- **Jenkins Admin Password**:
  ```sh
  kubectl get secret --namespace <namespace> jenkins -o jsonpath="{.data.jenkins-admin-password}" | base64 --decode
  ```

- **SonarQube Default Credentials**:
  Username: `admin`
  Password: `admin`

---

### 6. Build and Publish Your Service

To build and publish a Docker image for your service:

```sh
docker build -t paruff/<svcName> .
docker login -u <your-username>
docker push paruff/<svcName>
```

Replace `<svcName>` with your service name.

---

## 🌟 What Does This Infrastructure Provide?

### **1. Kubernetes Cluster Provisioning**
Automated creation of a Kubernetes cluster with namespaces for `platform`, `dev`, `test`, and `prod` to support environment isolation and secure delivery workflows.

### **2. Platform Layer**
Automated deployment of a Jenkins-based CI/CD pipeline, including quality and security gates, to provide visibility and control over your product code base.

### **3. DevSecOps by Design**
Integrates security and quality checks into the pipeline, supporting DORA best practices for elite software delivery performance.

### **4. Rapid Onboarding**
Scripts to bootstrap local developer environments and infrastructure, so teams can get started in minutes.

---

## 📚 Learn More

- [Main Fawkes README](../README.md): Platform overview, goals, and architecture.
- [Workspace Automation](workspace/readme.md): How to set up your local development environment.
- [Platform Infrastructure](platform/readme.md): Details on platform layer and CI/CD pipeline.

---

## 🛠️ Troubleshooting

If you encounter issues during setup or deployment:

1. Check the logs of the deployment scripts for errors.
2. Verify your environment variables in the `.env` file.
3. Refer to the [Troubleshooting Guide](../docs/troubleshooting.md) for common issues and solutions.
4. Open an issue on [GitHub](https://github.com/paruff/fawkes/issues) for further assistance.

---

_Fawkes Infra: Deliver fast, deliver better, deliver with confidence._
