# Usage Guide

This guide explains how to use the Fawkes Internal Developer Platform after setup. It covers common workflows, service management, and accessing platform features.

---

## Table of Contents

- [Accessing Platform Services](#accessing-platform-services)
- [Managing Infrastructure](#managing-infrastructure)
- [Deploying Platform Services](#deploying-platform-services)
- [Viewing Outputs and Endpoints](#viewing-outputs-and-endpoints)
- [CI/CD and Developer Workflows](#cicd-and-developer-workflows)
- [Configuration Management](#configuration-management)
- [Troubleshooting](#troubleshooting)

---

## Accessing Platform Services

After deployment, you can access services such as Jenkins, SonarQube, and the Kubernetes Dashboard:

- **Jenkins:**  
  Open the Jenkins URL provided in the deployment output (e.g., `http://<jenkins-lb>:8080`).  
  Login credentials are shown in the output or can be retrieved using:
  ```sh
  kubectl get secret --namespace <namespace> jenkins -o jsonpath="{.data.jenkins-admin-password}" | base64 --decode
  ```

- **SonarQube:**  
  Access via the provided load balancer URL (e.g., `http://<sonarqube-lb>:9000`).  
  Default credentials: `admin` / `admin`.

- **Kubernetes Dashboard:**  
  Access via the dashboard URL. Retrieve the admin token as described in [configuration.md](configuration.md).

---

## Managing Infrastructure

- **Provisioning:**  
  Use scripts in the `infra/` directory to provision or update infrastructure:
  ```sh
  cd infra
  ./infra-boot.sh -p aws -e dev
  ```

- **Destroying:**  
  To tear down infrastructure:
  ```sh
  cd infra
  ./infra-boot.sh -p aws -e dev --destroy
  ```

- **Terraform:**  
  You can also use Terraform directly:
  ```sh
  cd infra/platform/aws
  terraform init
  terraform plan
  terraform apply
  ```

---

## Deploying Platform Services

- **Jenkins:**  
  ```sh
  cd platform/jenkins
  ./jenkins-delta.sh -i
  ```

- **Other Services:**  
  Each service directory contains scripts or Helm charts for deployment. See the respective README files.

---

## Viewing Outputs and Endpoints

After deployment, outputs such as service URLs and credentials are displayed in the terminal.  
You can also retrieve them using:

```sh
terraform output
```
or by running the `show` command in deployment scripts:

```sh
./jenkins-delta.sh -s
```

---

## CI/CD and Developer Workflows

- **Pipelines:**  
  Jenkins is pre-configured for CI/CD. Add your repositories and configure pipelines as needed.

- **Workspace Automation:**  
  Use scripts in the `workspace/` directory to set up local development environments.

---

## Configuration Management

- All configuration files are located in the `infra/` and `platform/` directories.
- Secrets should **not** be committed to version control. Use templates and inject secrets at deploy time.
- See [configuration.md](configuration.md) for details on environment variables and secret management.

---

## Troubleshooting

- See [troubleshooting.md](troubleshooting.md) for common issues and solutions.
- For further help, open an issue on [GitHub](https://github.com/paruff/fawkes/issues).

---
```<!-- filepath: /Users/philruff/projects/github/paruff/fawkes/docs/usage.md -->
# Usage Guide

This guide explains how to use the Fawkes Internal Developer Platform after setup. It covers common workflows, service management, and accessing platform features.

---

## Table of Contents

- [Accessing Platform Services](#accessing-platform-services)
- [Managing Infrastructure](#managing-infrastructure)
- [Deploying Platform Services](#deploying-platform-services)
- [Viewing Outputs and Endpoints](#viewing-outputs-and-endpoints)
- [CI/CD and Developer Workflows](#cicd-and-developer-workflows)
- [Configuration Management](#configuration-management)
- [Troubleshooting](#troubleshooting)

---

## Accessing Platform Services

After deployment, you can access services such as Jenkins, SonarQube, and the Kubernetes Dashboard:

- **Jenkins:**  
  Open the Jenkins URL provided in the deployment output (e.g., `http://<jenkins-lb>:8080`).  
  Login credentials are shown in the output or can be retrieved using:
  ```sh
  kubectl get secret --namespace <namespace> jenkins -o jsonpath="{.data.jenkins-admin-password}" | base64 --decode
  ```

- **SonarQube:**  
  Access via the provided load balancer URL (e.g., `http://<sonarqube-lb>:9000`).  
  Default credentials: `admin` / `admin`.

- **Kubernetes Dashboard:**  
  Access via the dashboard URL. Retrieve the admin token as described in [configuration.md](configuration.md).

---

## Managing Infrastructure

- **Provisioning:**  
  Use scripts in the `infra/` directory to provision or update infrastructure:
  ```sh
  cd infra
  ./infra-boot.sh -p aws -e dev
  ```

- **Destroying:**  
  To tear down infrastructure:
  ```sh
  cd infra
  ./infra-boot.sh -p aws -e dev --destroy
  ```

- **Terraform:**  
  You can also use Terraform directly:
  ```sh
  cd infra/platform/aws
  terraform init
  terraform plan
  terraform apply
  ```

---

## Deploying Platform Services

- **Jenkins:**  
  ```sh
  cd platform/jenkins
  ./jenkins-delta.sh -i
  ```

- **Other Services:**  
  Each service directory contains scripts or Helm charts for deployment. See the respective README files.

---

## Viewing Outputs and Endpoints

After deployment, outputs such as service URLs and credentials are displayed in the terminal.  
You can also retrieve them using:

```sh
terraform output
```
or by running the `show` command in deployment scripts:

```sh
./jenkins-delta.sh -s
```

---

## CI/CD and Developer Workflows

- **Pipelines:**  
  Jenkins is pre-configured for CI/CD. Add your repositories and configure pipelines as needed.

- **Workspace Automation:**  
  Use scripts in the `workspace/` directory to set up local development environments.

---

## Configuration Management

- All configuration files are located in the `infra/` and `platform/` directories.
- Secrets should **not** be committed to version control. Use templates and inject secrets at deploy time.
- See [configuration.md](configuration.md) for details on environment variables and secret management.

---

## Troubleshooting

- See [troubleshooting.md](troubleshooting.md) for common issues and solutions.
- For further help, open an issue on [GitHub](https://github.com/paruff/fawkes/issues).

---