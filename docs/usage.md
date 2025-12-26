# Usage Guide

This guide explains how to use the Fawkes Internal Developer Platform after setup. It covers common workflows, service management, and accessing platform features.

Fawkes is a **metrics-first platform** designed to help teams improve their **software delivery performance** by focusing on the **Four Key Metrics** and supporting the **eight capabilities** needed to enhance those metrics.

---

## Table of Contents

- [Accessing Platform Services](#accessing-platform-services)
- [Managing Infrastructure](#managing-infrastructure)
- [Deploying Platform Services](#deploying-platform-services)
- [Viewing Outputs and Endpoints](#viewing-outputs-and-endpoints)
- [CI/CD and Developer Workflows](#cicd-and-developer-workflows)
- [Measuring and Improving DORA Metrics](#measuring-and-improving-dora-metrics)
- [Configuration Management](#configuration-management)
- [Troubleshooting](#troubleshooting)

---

## Accessing Platform Services

After deployment, you can access services such as Jenkins, SonarQube, and the Kubernetes Dashboard. These services support **Continuous Integration**, **Monitoring and Observability**, and **Streamlining Change Approval**.

- **Jenkins:**
  Access Jenkins via the provided URL (e.g., `http://<jenkins-lb>:8080`).
  Retrieve the admin password using:

  ```sh
  kubectl get secret --namespace <namespace> jenkins -o jsonpath="{.data.jenkins-admin-password}" | base64 --decode
  ```

- **SonarQube:**
  Access SonarQube via the provided URL (e.g., `http://<sonarqube-lb>:9000`).
  Default credentials: `admin` / `admin`.

- **Kubernetes Dashboard:**
  Access the dashboard via the provided URL. Retrieve the admin token using:
  ```sh
  kubectl -n kubernetes-dashboard describe secret $(kubectl -n kubernetes-dashboard get secret | grep admin-user | awk '{print $1}')
  ```

---

## Managing Infrastructure

- **Provisioning Infrastructure:**
  Use the provided scripts in the `infra/` directory to provision or update infrastructure:

  ```sh
  cd infra
  ./scripts/ignite.sh --provider aws dev
  ```

- **Destroying Infrastructure:**
  To tear down infrastructure:

  ```sh
  cd infra
  ./scripts/ignite.sh --provider aws dev  # see docs for destroy guidance
  ```

- **Using Terraform Directly:**
  Advanced users can manage infrastructure directly with Terraform:
  ```sh
  cd infra/platform/aws
  terraform init
  terraform plan
  terraform apply
  ```

---

## Deploying Platform Services

- **Jenkins Deployment:**
  Deploy Jenkins using the provided script:

  ```sh
  cd platform/jenkins
  ./jenkins-delta.sh -i
  ```

- **Other Services:**
  Each service directory contains deployment scripts or Helm charts. Refer to the respective README files for details.

---

## Viewing Outputs and Endpoints

After deployment, service URLs and credentials are displayed in the terminal.
You can also retrieve them using:

- **Terraform Outputs:**

  ```sh
  terraform output
  ```

- **Deployment Script Outputs:**
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

## Measuring and Improving DORA Metrics

Fawkes is designed to help teams measure and improve the [Four Key DORA Metrics](https://www.devops-research.com/research.html):

- **Deployment Frequency**
- **Lead Time for Changes**
- **Change Failure Rate**
- **Mean Time to Restore (MTTR)**

### How Fawkes Helps

- **Automated CI/CD Pipelines:** Jenkins and other integrated tools provide metrics on deployment frequency and lead time.
- **Quality Gates:** SonarQube and automated tests help reduce change failure rate.
- **Monitoring & Alerts:** Integrated monitoring and logging help track and reduce MTTR.
- **Reporting:** Extract and visualize DORA metrics from pipeline logs, test reports, and monitoring dashboards.

> See the [architecture](architecture.md) and [development guide](development.md) for more on how Fawkes supports DORA capabilities and continuous improvement.

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

Thank you for choosing Fawkes! We’re excited to help you build better, faster, and more reliable infrastructure.
