---
title: Service Catalog Reference
description: List of supported service types in the Fawkes platform catalog
---

# Service Catalog Reference

## Overview

This document lists all service types available in the Fawkes platform catalog. Services are organized by category and managed through ArgoCD GitOps workflows.

**Application Definitions Location:** `platform/apps/`

---

## CI/CD Services

| Service | Version | Description                                                | ArgoCD Application         | Status    |
| ------- | ------- | ---------------------------------------------------------- | -------------------------- | --------- |
| Jenkins | 2.426+  | CI/CD automation server with Golden Path pipeline support. | `jenkins-application.yaml` | ✅ Active |
| ArgoCD  | 2.9+    | GitOps continuous delivery for Kubernetes.                 | N/A (Bootstrap)            | ✅ Active |

**Key Features:**

- **Jenkins:** JCasC configuration, Kubernetes agents, GitHub integration, DORA metrics collection.
- **ArgoCD:** Auto-sync, health status monitoring, rollback capabilities.

---

## Developer Portal

| Service     | Version | Description                                         | ArgoCD Application           | Status    |
| ----------- | ------- | --------------------------------------------------- | ---------------------------- | --------- |
| Backstage   | 1.21+   | Software catalog and developer portal with plugins. | `backstage-application.yaml` | ✅ Active |
| Eclipse Che | 7.80+   | Cloud-based IDE with Devfile support.               | N/A                          | ✅ Active |

**Backstage Plugins:**

- **Che Launcher:** Launch Eclipse Che workspaces from Backstage.
- **DevLake Dashboard:** View DORA metrics within Backstage.
- **Catalog:** Service catalog with ownership and dependency tracking.

**Eclipse Che Features:**

- Devfile 2.2.2 support for workspace definitions.
- Golden Path starter projects (Python, AI/ML).
- Integrated debugging and testing.

---

## Observability Services

| Service                 | Version | Description                                               | ArgoCD Application                | Status    |
| ----------------------- | ------- | --------------------------------------------------------- | --------------------------------- | --------- |
| Prometheus              | 2.47+   | Metrics collection and time-series database.              | N/A                               | ✅ Active |
| Grafana                 | 10.2+   | Visualization and analytics platform.                     | N/A                               | ✅ Active |
| OpenSearch              | 2.11+   | Distributed search and analytics for centralized logging. | N/A                               | ✅ Active |
| Grafana Tempo           | 2.3+    | Distributed tracing backend for OpenTelemetry traces.     | `tempo-application.yaml`          | ✅ Active |
| OpenTelemetry Collector | 0.89+   | Vendor-neutral telemetry data collection and export.      | `otel-collector-application.yaml` | ✅ Active |
| Apache DevLake          | 0.20+   | DORA metrics data platform.                               | `devlake-application.yaml`        | ✅ Active |

**Observability Stack Integration:**

```text
Application
    │
    ├─> OpenTelemetry SDK (traces, metrics, logs)
    │       │
    │       ▼
    │   OTel Collector
    │       │
    │       ├─> Tempo (traces)
    │       ├─> Prometheus (metrics)
    │       └─> OpenSearch (logs)
    │               │
    │               ▼
    │           Grafana (unified visualization)
```

---

## Security Services

| Service                   | Version | Description                                           | ArgoCD Application                           | Status    |
| ------------------------- | ------- | ----------------------------------------------------- | -------------------------------------------- | --------- |
| Vault                     | 1.15+   | Secrets management and encryption.                    | N/A                                          | ✅ Active |
| External Secrets Operator | 0.9+    | Sync secrets from Vault to Kubernetes Secrets.        | `external-secrets-operator-application.yaml` | ✅ Active |
| Vault CSI Driver          | 1.3+    | Mount Vault secrets as volumes in Pods.               | `vault-csi-driver-application.yaml`          | ✅ Active |
| SonarQube                 | 10.3+   | Static application security testing (SAST).           | `sonarqube-application.yaml`                 | ✅ Active |
| Trivy                     | 0.47+   | Container image and filesystem vulnerability scanner. | N/A (Jenkins plugin)                         | ✅ Active |
| Kyverno                   | 1.11+   | Kubernetes-native policy engine.                      | `kyverno-application.yaml`                   | ✅ Active |

**Security Workflow:**

1. **Secrets Management:** Vault stores credentials → External Secrets Operator syncs to K8s Secrets.
2. **SAST:** SonarQube scans code during CI pipeline.
3. **Container Scanning:** Trivy scans images during build and runtime.
4. **Policy Enforcement:** Kyverno validates and mutates resources at admission time.

---

## Collaboration Services

| Service    | Version | Description                              | ArgoCD Application            | Status     |
| ---------- | ------- | ---------------------------------------- | ----------------------------- | ---------- |
| Mattermost | 9.2+    | Team collaboration and ChatOps platform. | N/A                           | 🚧 Planned |
| Focalboard | 7.11+   | Open-source project management.          | `focalboard-application.yaml` | ✅ Active  |

**Use Cases:**

- **Mattermost:** ChatOps commands, build notifications, incident response.
- **Focalboard:** Sprint planning, backlog management, roadmaps.

---

## Data Services

| Service    | Version | Description                                       | ArgoCD Application            | Status    |
| ---------- | ------- | ------------------------------------------------- | ----------------------------- | --------- |
| PostgreSQL | 16+     | Relational database (via CloudNativePG operator). | `postgresql-application.yaml` | ✅ Active |

**Supported PostgreSQL Clusters:**

| Cluster Name            | Purpose                     | Application |
| ----------------------- | --------------------------- | ----------- |
| `db-backstage-cluster`  | Backstage catalog database  | Backstage   |
| `db-sonarqube-cluster`  | SonarQube analysis database | SonarQube   |
| `db-focalboard-cluster` | Focalboard data storage     | Focalboard  |

**CloudNativePG Features:**

- Automated backups to S3/GCS/Azure Blob.
- High availability with streaming replication.
- Connection pooling with PgBouncer.

---

## Networking Services

| Service                  | Version | Description                            | ArgoCD Application | Status    |
| ------------------------ | ------- | -------------------------------------- | ------------------ | --------- |
| NGINX Ingress Controller | 1.9+    | HTTP/HTTPS load balancing and routing. | N/A                | ✅ Active |
| Cert-Manager             | 1.13+   | Automated TLS certificate management.  | N/A                | ✅ Active |
| External DNS             | 0.14+   | Automated DNS record synchronization.  | N/A                | ✅ Active |

**Ingress Workflow:**

```text
External Request
    │
    ├─> DNS (managed by External DNS)
    │       │
    │       ▼
    │   NGINX Ingress Controller
    │       │
    │       ├─> TLS Termination (Cert-Manager certificates)
    │       │
    │       ▼
    │   Backend Service (e.g., Jenkins, Backstage)
```

---

## Platform Operators

| Operator         | Version | Description                         | ArgoCD Application                           | Status    |
| ---------------- | ------- | ----------------------------------- | -------------------------------------------- | --------- |
| CloudNativePG    | 1.21+   | PostgreSQL operator for Kubernetes. | `cloudnativepg-operator-application.yaml`    | ✅ Active |
| External Secrets | 0.9+    | External secret store integration.  | `external-secrets-operator-application.yaml` | ✅ Active |
| Kyverno          | 1.11+   | Policy engine operator.             | `kyverno-application.yaml`                   | ✅ Active |

---

## Service Types by Language/Framework

### Supported Application Stacks

| Stack       | Language     | Framework                    | Golden Path Support | Devfile Available           |
| ----------- | ------------ | ---------------------------- | ------------------- | --------------------------- |
| Python Web  | Python 3.11+ | FastAPI, Django, Flask       | ✅ Yes              | ✅ `goldenpath-python.yaml` |
| AI/ML       | Python 3.11+ | TensorFlow, PyTorch, Jupyter | ✅ Yes              | ✅ `goldenpath-ai.yaml`     |
| Java Spring | Java 17+     | Spring Boot                  | 🚧 Planned          | 🚧 Planned                  |
| Node.js     | Node 20+     | Express, NestJS              | 🚧 Planned          | 🚧 Planned                  |
| Go          | Go 1.21+     | Gin, Echo                    | 🚧 Planned          | 🚧 Planned                  |

---

## Service Deployment Patterns

### Pattern 1: ArgoCD Application

For platform services managed via GitOps:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: jenkins
  namespace: fawkes
spec:
  source:
    repoURL: https://charts.jenkins.io
    chart: jenkins
    targetRevision: 5.0.0
  destination:
    server: https://kubernetes.default.svc
    namespace: jenkins
```

### Pattern 2: Helm Release

For services deployed via Helm:

```bash
helm upgrade --install jenkins jenkins/jenkins \
  -f platform/apps/jenkins/values.yaml \
  -n jenkins --create-namespace
```

### Pattern 3: Kustomize

For services using Kustomize overlays:

```bash
kubectl apply -k platform/apps/backstage/overlays/dev
```

---

## Adding a New Service to the Catalog

1. **Define ArgoCD Application:** Create `platform/apps/<service>/<service>-application.yaml`.
2. **Add Helm Values:** Create `platform/apps/<service>/values.yaml` with configuration.
3. **Create Namespace:** Update `platform/apps/namespaces.yaml`.
4. **Document Configuration:** Add Helm values reference to `docs/reference/config/<service>-values.md`.
5. **Commit and Sync:** ArgoCD auto-syncs from Git.

---

## Service Status Legend

| Icon | Status     | Description                                              |
| ---- | ---------- | -------------------------------------------------------- |
| ✅   | Active     | Service is deployed and operational.                     |
| 🚧   | Planned    | Service is in development or planned for future release. |
| ⚠️   | Deprecated | Service is deprecated and will be removed.               |

---

## See Also

- 
- [ArgoCD Sync Guide](../../how-to/gitops/sync-argocd-app.md)
- [Onboard Service to ArgoCD](../../how-to/gitops/onboard-service-argocd.md)
- [Platform Architecture](../../architecture.md)
