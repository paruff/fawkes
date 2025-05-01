# Fawkes Infrastructure Automation

This directory contains the **Infrastructure as Code (IaC)** scripts and automation for the Fawkes platform. It enables rapid, repeatable provisioning of Kubernetes infrastructure and a secure, observable CI/CD pipeline, empowering teams to deliver products quickly and confidently.

## Getting Started

### 1. Prepare Your Local Environment

- **Windows:**  
  Run as administrator:
  ```bat
  infra/workspace/space-setup.bat
  ```
  This will install required tools such as Git, Docker, VirtualBox, and more.

### 2. Clone the Repository

```sh
git clone https://github.com/paruff/fawkes.git
cd fawkes/infra
```

### 3. Set Up Docker Environment (if using Docker Machine)

```bat
set-env.bat
docker-machine ip
```

_Note the IP address for accessing your app._

### 4. Build and Run Locally

```bat
docker-compose up
```

Wait a few minutes, then browse to the IP address provided by `docker-machine ip`.

### 5. Build and Publish Your Service

```bat
docker build -t paruff/<svcName> .
docker login -u <your-username>
docker push paruff/<svcName>
```

Some text.

```sh
echo "Hello"
```

## What Does This Infrastructure Provide?

- **Kubernetes Cluster Provisioning:**  
  Automated creation of a Kubernetes cluster with namespaces for `platform`, `dev`, `test`, and `prod` to support environment isolation and secure delivery workflows.
- **Platform Layer:**  
  Automated deployment of a Jenkins-based CI/CD pipeline, including quality and security gates, to provide visibility and control over your product code base.
- **DevSecOps by Design:**  
  Integrates security and quality checks into the pipeline, supporting DORA best practices for elite software delivery performance.
- **Rapid Onboarding:**  
  Scripts to bootstrap local developer environments and infrastructure, so teams can get started in minutes.

## Learn More

- [Main Fawkes README](../README.md) – Platform overview, goals, and architecture.
- [Workspace Automation](workspace/readme.md) – How to set up your local development environment.
- [Platform Infrastructure](platform/readme.md) – Details on platform layer and CI/CD pipeline.

---

_Fawkes Infra: Deliver fast, deliver better, deliver with confidence._
