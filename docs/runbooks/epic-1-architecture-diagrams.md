# Epic 1: Architecture Diagrams

**Version**: 1.0
**Last Updated**: December 2024
**Status**: Production Ready

---

## Table of Contents

1. [Infrastructure Architecture](#infrastructure-architecture)
2. [GitOps Flow](#gitops-flow)
3. [DORA Metrics Architecture](#dora-metrics-architecture)
4. [CI/CD Pipeline](#cicd-pipeline)
5. [Security Scanning Pipeline](#security-scanning-pipeline)
6. [Observability Stack](#observability-stack)
7. [Network Architecture](#network-architecture)
8. [Data Flow Diagrams](#data-flow-diagrams)

---

## Infrastructure Architecture

### Epic 1 Platform Components Overview

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                         Fawkes Epic 1 Platform                                │
│                        4-Node Kubernetes Cluster                              │
├──────────────────────────────────────────────────────────────────────────────┤
│                                                                               │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │                     Ingress & TLS (ingress-nginx)                    │    │
│  │              cert-manager for automatic TLS certificates             │    │
│  └────────────────────────────┬─────────────────────────────────────────┘    │
│                               │                                               │
│           ┌───────────────────┼───────────────────┐                          │
│           │                   │                   │                          │
│  ┌────────▼─────────┐ ┌──────▼────────┐ ┌───────▼────────┐                 │
│  │   Developer      │ │    GitOps     │ │     CI/CD      │                 │
│  │   Experience     │ │   ArgoCD      │ │    Jenkins     │                 │
│  │   (Backstage)    │ │               │ │                │                 │
│  │                  │ │ - Applications│ │ - Pipelines    │                 │
│  │ - Service Catalog│ │ - Auto-sync   │ │ - Agents       │                 │
│  │ - Templates      │ │ - Rollbacks   │ │ - Webhooks     │                 │
│  │ - TechDocs       │ │               │ │                │                 │
│  │ - CDE Launcher   │ │               │ │                │                 │
│  └──────────────────┘ └───────────────┘ └────────────────┘                 │
│                                                                               │
│  ┌────────────────────────────────────────────────────────────────────┐     │
│  │                    Security Layer                                   │     │
│  │  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ │     │
│  │  │ SonarQube   │ │   Trivy     │ │    Vault    │ │   Kyverno   │ │     │
│  │  │    SAST     │ │  Container  │ │  Secrets    │ │   Policy    │ │     │
│  │  │             │ │   Scanning  │ │  Management │ │  Enforcement│ │     │
│  │  └─────────────┘ └─────────────┘ └─────────────┘ └─────────────┘ │     │
│  └────────────────────────────────────────────────────────────────────┘     │
│                                                                               │
│  ┌────────────────────────────────────────────────────────────────────┐     │
│  │                  Observability Stack                                │     │
│  │  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ │     │
│  │  │ Prometheus  │ │   Grafana   │ │ OpenTelemetry│ │ Fluent Bit  │ │     │
│  │  │   Metrics   │ │ Dashboards  │ │   Collector  │ │    Logs     │ │     │
│  │  └─────────────┘ └─────────────┘ └─────────────┘ └─────────────┘ │     │
│  └────────────────────────────────────────────────────────────────────┘     │
│                                                                               │
│  ┌────────────────────────────────────────────────────────────────────┐     │
│  │              DORA Metrics & Registry                                │     │
│  │  ┌──────────────────────┐          ┌──────────────────────┐       │     │
│  │  │      DevLake         │          │       Harbor         │       │     │
│  │  │   DORA Metrics       │          │  Container Registry  │       │     │
│  │  │   - Deployment Freq  │          │  - Image Scanning    │       │     │
│  │  │   - Lead Time        │          │  - SBOM Generation   │       │     │
│  │  │   - Change Failure   │          │                      │       │     │
│  │  │   - MTTR             │          │                      │       │     │
│  │  └──────────────────────┘          └──────────────────────┘       │     │
│  └────────────────────────────────────────────────────────────────────┘     │
│                                                                               │
│  ┌────────────────────────────────────────────────────────────────────┐     │
│  │                  Data Persistence Layer                             │     │
│  │  ┌────────────────────┐  ┌────────────────────┐                    │     │
│  │  │   PostgreSQL (HA)  │  │   MySQL (HA)       │                    │     │
│  │  │ - Backstage DB     │  │ - DevLake DB       │                    │     │
│  │  │ - SonarQube DB     │  │                    │                    │     │
│  │  │ - CloudNativePG    │  │                    │                    │     │
│  │  └────────────────────┘  └────────────────────┘                    │     │
│  └────────────────────────────────────────────────────────────────────┘     │
│                                                                               │
│  ┌────────────────────────────────────────────────────────────────────┐     │
│  │                  Storage Layer                                      │     │
│  │  - Persistent Volumes for databases                                 │     │
│  │  - Prometheus metrics storage                                       │     │
│  │  - Harbor image storage                                             │     │
│  │  - Jenkins workspace volumes                                        │     │
│  └────────────────────────────────────────────────────────────────────┘     │
│                                                                               │
└──────────────────────────────────────────────────────────────────────────────┘
```

### Kubernetes Cluster Architecture

```
┌──────────────────────────────────────────────────────────────────┐
│                    4-Node Kubernetes Cluster                      │
│                          (Kind/K3s/AKS)                          │
├──────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌────────────────┐  ┌────────────────┐  ┌────────────────┐    │
│  │   Node 1       │  │   Node 2       │  │   Node 3       │    │
│  │  (Control)     │  │   (Worker)     │  │   (Worker)     │    │
│  │                │  │                │  │                │    │
│  │ - API Server   │  │ - Backstage    │  │ - Jenkins      │    │
│  │ - etcd         │  │ - ArgoCD       │  │ - SonarQube    │    │
│  │ - Scheduler    │  │ - Prometheus   │  │ - Harbor       │    │
│  │ - Controller   │  │ - Grafana      │  │ - DevLake      │    │
│  │                │  │ - Vault        │  │                │    │
│  └────────────────┘  └────────────────┘  └────────────────┘    │
│                                                                   │
│  ┌────────────────┐                                              │
│  │   Node 4       │                                              │
│  │   (Worker)     │                                              │
│  │                │                                              │
│  │ - Application  │                                              │
│  │   Workloads    │                                              │
│  │ - Jenkins      │                                              │
│  │   Agents       │                                              │
│  │ - Kyverno      │                                              │
│  │                │                                              │
│  └────────────────┘                                              │
│                                                                   │
│  Resources per Node:                                             │
│  - CPU: 4 cores                                                  │
│  - Memory: 16 GB                                                 │
│  - Storage: 100 GB                                               │
│  - Target Utilization: <70% CPU/Memory                          │
│                                                                   │
└──────────────────────────────────────────────────────────────────┘
```

---

## GitOps Flow

### ArgoCD GitOps Architecture

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                          GitOps with ArgoCD                                   │
└──────────────────────────────────────────────────────────────────────────────┘

Developer Workflow:
─────────────────

┌──────────────┐
│  Developer   │
│  Local Dev   │
└──────┬───────┘
       │
       │ 1. Code + Commit
       ▼
┌──────────────────────┐
│   GitHub Repository  │
│   (Application Code) │
└──────────┬───────────┘
           │
           │ 2. Webhook triggers CI
           ▼
┌───────────────────────────────────────────────────────────────┐
│                       Jenkins Pipeline                         │
│                                                                │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐    │
│  │  Build   │→ │  Test    │→ │  Scan    │→ │  Package │    │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘    │
│                                                                │
│  ┌──────────────────────────────────────────────────────┐    │
│  │ 3. Build container image                              │    │
│  │ 4. Push to Harbor registry                            │    │
│  │ 5. Update image tag in GitOps repo                    │    │
│  └──────────────────────────────────────────────────────┘    │
└───────────────────────────┬───────────────────────────────────┘
                            │
                            │ 6. Git commit (new image tag)
                            ▼
┌──────────────────────────────────────────────────────────────┐
│          GitHub Repository (GitOps/Manifests)                 │
│                                                               │
│  platform/                                                    │
│  ├── apps/                                                    │
│  │   ├── backstage/                                          │
│  │   │   ├── base/                                           │
│  │   │   │   ├── deployment.yaml                             │
│  │   │   │   ├── service.yaml                                │
│  │   │   │   └── kustomization.yaml                          │
│  │   │   └── overlays/                                       │
│  │   │       └── production/                                 │
│  │   │           ├── kustomization.yaml                      │
│  │   │           └── values.yaml  # image.tag updated        │
│  │   ├── jenkins/                                            │
│  │   └── prometheus/                                         │
│  └── argocd/                                                 │
│      └── applications/                                       │
│          └── backstage-app.yaml                              │
└───────────────────────────┬──────────────────────────────────┘
                            │
                            │ 7. ArgoCD detects change (every 3 min)
                            ▼
┌──────────────────────────────────────────────────────────────┐
│                         ArgoCD                                │
│                                                               │
│  ┌────────────────────────────────────────────────────┐     │
│  │  Reconciliation Loop:                               │     │
│  │  1. Fetch manifests from Git                        │     │
│  │  2. Compare desired vs actual state                 │     │
│  │  3. Calculate diff                                   │     │
│  │  4. Apply changes to cluster                        │     │
│  │  5. Monitor rollout status                          │     │
│  │  6. Update application status                       │     │
│  └────────────────────────────────────────────────────┘     │
└───────────────────────────┬──────────────────────────────────┘
                            │
                            │ 8. Apply manifests
                            ▼
┌──────────────────────────────────────────────────────────────┐
│                    Kubernetes Cluster                         │
│                                                               │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  Deployment Rolling Update:                           │   │
│  │  1. Create new ReplicaSet with new image             │   │
│  │  2. Scale up new pods                                 │   │
│  │  3. Wait for pods to be ready                         │   │
│  │  4. Scale down old pods                               │   │
│  │  5. Delete old ReplicaSet                             │   │
│  └──────────────────────────────────────────────────────┘   │
│                                                               │
│  ┌──────────────┐     ┌──────────────┐                      │
│  │  backstage   │     │  backstage   │                      │
│  │  pod-abc123  │     │  pod-xyz789  │                      │
│  │  (old)       │  →  │  (new)       │                      │
│  └──────────────┘     └──────────────┘                      │
└───────────────────────────┬──────────────────────────────────┘
                            │
                            │ 9. Deployment complete
                            ▼
┌──────────────────────────────────────────────────────────────┐
│                    DORA Metrics Service                       │
│                       (DevLake)                               │
│                                                               │
│  10. Record deployment event:                                │
│      - Timestamp                                              │
│      - Service name                                           │
│      - Status (success/failure)                              │
│      - Commit SHA                                            │
│      - Lead time calculation                                 │
└──────────────────────────────────────────────────────────────┘

Key Principles:
─────────────
✓ Git as single source of truth
✓ Declarative desired state
✓ Automated reconciliation
✓ Self-healing on drift
✓ Easy rollbacks via Git revert
✓ Audit trail through Git history
```

### ArgoCD Application Relationships

```
┌──────────────────────────────────────────────────────────────┐
│                   ArgoCD Applications                         │
├──────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌─────────────────────────────────────────────────┐        │
│  │           App-of-Apps Pattern                    │        │
│  │                                                  │        │
│  │  ┌───────────────────────────────────────┐     │        │
│  │  │  root-application (bootstrap)         │     │        │
│  │  │  - Manages all other ArgoCD apps      │     │        │
│  │  └───────────┬───────────────────────────┘     │        │
│  │              │                                  │        │
│  │      ┌───────┴───────┬──────────┬──────────┐  │        │
│  │      │               │          │          │  │        │
│  │  ┌───▼────┐   ┌─────▼───┐  ┌──▼─────┐ ┌─▼──────┐     │
│  │  │Platform│   │  Apps   │  │Security│ │Observ. │     │
│  │  │  Core  │   │         │  │        │ │        │     │
│  │  └────────┘   └─────────┘  └────────┘ └────────┘     │
│  └─────────────────────────────────────────────────┘        │
│                                                               │
│  Platform Core Applications:                                 │
│  ├── argocd (self-managed)                                   │
│  ├── ingress-nginx                                           │
│  ├── cert-manager                                            │
│  └── external-secrets                                        │
│                                                               │
│  Developer Experience Applications:                          │
│  ├── backstage                                               │
│  ├── jenkins                                                 │
│  └── eclipse-che                                             │
│                                                               │
│  Security Applications:                                      │
│  ├── vault                                                   │
│  ├── kyverno                                                 │
│  ├── sonarqube                                               │
│  └── trivy-operator                                          │
│                                                               │
│  Observability Applications:                                 │
│  ├── prometheus-stack                                        │
│  ├── grafana                                                 │
│  ├── opentelemetry-collector                                │
│  └── fluent-bit                                              │
│                                                               │
│  DORA & Registry Applications:                               │
│  ├── devlake                                                 │
│  └── harbor                                                  │
│                                                               │
└──────────────────────────────────────────────────────────────┘
```

---

## DORA Metrics Architecture

### DevLake DORA Metrics Collection

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                     DORA Metrics Data Collection Flow                         │
└──────────────────────────────────────────────────────────────────────────────┘

Data Sources:
────────────

┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   GitHub    │    │   ArgoCD    │    │   Jenkins   │    │ Prometheus  │
│             │    │             │    │             │    │             │
│ - Commits   │    │ - Syncs     │    │ - Builds    │    │ - Incidents │
│ - PRs       │    │ - Deploys   │    │ - Tests     │    │ - Alerts    │
│ - Reviews   │    │ - Status    │    │ - Results   │    │ - Uptime    │
└──────┬──────┘    └──────┬──────┘    └──────┬──────┘    └──────┬──────┘
       │                  │                   │                   │
       │                  │                   │                   │
       └──────────────────┼───────────────────┼───────────────────┘
                          │                   │
                          ▼                   ▼
┌──────────────────────────────────────────────────────────────────┐
│                        DevLake Platform                           │
│                                                                   │
│  ┌────────────────────────────────────────────────────────┐     │
│  │               Data Collection Plugins                   │     │
│  │                                                         │     │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌────────┐│     │
│  │  │  GitHub  │  │  ArgoCD  │  │ Jenkins  │  │Webhook ││     │
│  │  │  Plugin  │  │  Plugin  │  │  Plugin  │  │ Plugin ││     │
│  │  └──────────┘  └──────────┘  └──────────┘  └────────┘│     │
│  └────────────────────────┬───────────────────────────────┘     │
│                           │                                      │
│                           ▼                                      │
│  ┌────────────────────────────────────────────────────────┐    │
│  │              Data Transformation Layer                  │    │
│  │  - Normalize data from different sources               │    │
│  │  - Map events to deployments                           │    │
│  │  - Calculate time differences                          │    │
│  │  - Identify failures and incidents                     │    │
│  └────────────────────────┬───────────────────────────────┘    │
│                           │                                      │
│                           ▼                                      │
│  ┌────────────────────────────────────────────────────────┐    │
│  │               DORA Metrics Calculations                 │    │
│  │                                                         │    │
│  │  ┌─────────────────────────────────────────────────┐  │    │
│  │  │ Deployment Frequency                            │  │    │
│  │  │ = ArgoCD syncs / time period                    │  │    │
│  │  │ Source: ArgoCD sync events                      │  │    │
│  │  └─────────────────────────────────────────────────┘  │    │
│  │                                                         │    │
│  │  ┌─────────────────────────────────────────────────┐  │    │
│  │  │ Lead Time for Changes                           │  │    │
│  │  │ = Deploy time - Commit time                     │  │    │
│  │  │ Source: GitHub commits → ArgoCD syncs           │  │    │
│  │  └─────────────────────────────────────────────────┘  │    │
│  │                                                         │    │
│  │  ┌─────────────────────────────────────────────────┐  │    │
│  │  │ Change Failure Rate                             │  │    │
│  │  │ = Failed syncs / Total syncs                    │  │    │
│  │  │ Source: ArgoCD sync status + incidents          │  │    │
│  │  └─────────────────────────────────────────────────┘  │    │
│  │                                                         │    │
│  │  ┌─────────────────────────────────────────────────┐  │    │
│  │  │ Mean Time to Restore (MTTR)                     │  │    │
│  │  │ = Restore time - Incident time                  │  │    │
│  │  │ Source: Incident creation → successful sync     │  │    │
│  │  └─────────────────────────────────────────────────┘  │    │
│  │                                                         │    │
│  │  ┌─────────────────────────────────────────────────┐  │    │
│  │  │ Operational Performance                         │  │    │
│  │  │ = SLO adherence from Prometheus                 │  │    │
│  │  │ Source: Prometheus metrics                      │  │    │
│  │  └─────────────────────────────────────────────────┘  │    │
│  └────────────────────────┬───────────────────────────────┘    │
│                           │                                      │
│                           ▼                                      │
│  ┌────────────────────────────────────────────────────────┐    │
│  │                  MySQL Database                         │    │
│  │  - Historical metrics storage                          │    │
│  │  - Aggregated data                                     │    │
│  │  - Trend analysis                                      │    │
│  └────────────────────────────────────────────────────────┘    │
└───────────────────────────┬────────────────────────────────────┘
                            │
                            ▼
┌──────────────────────────────────────────────────────────────────┐
│                      Visualization Layer                          │
│                                                                   │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐      │
│  │   Grafana    │    │  Backstage   │    │  DevLake UI  │      │
│  │  Dashboards  │    │   Plugin     │    │              │      │
│  │              │    │              │    │              │      │
│  │ - Team view  │    │ - Service    │    │ - Admin      │      │
│  │ - Trends     │    │   metrics    │    │   view       │      │
│  │ - Alerts     │    │              │    │              │      │
│  └──────────────┘    └──────────────┘    └──────────────┘      │
└──────────────────────────────────────────────────────────────────┘
```

### DORA Metrics Data Model

```
Deployment Event:
─────────────────
┌────────────────────────────────────────┐
│ deployment_id                          │
│ service_name                           │
│ timestamp                              │
│ commit_sha                             │
│ commit_timestamp                       │
│ lead_time (calculated)                 │
│ status (success/failure)               │
│ argocd_sync_id                         │
│ jenkins_build_id (optional)            │
│ deployed_by                            │
│ environment                            │
└────────────────────────────────────────┘

Incident Event:
──────────────
┌────────────────────────────────────────┐
│ incident_id                            │
│ service_name                           │
│ created_at                             │
│ resolved_at                            │
│ mttr (calculated)                      │
│ severity                               │
│ caused_by_deployment_id (optional)     │
│ resolution_deployment_id               │
└────────────────────────────────────────┘

Aggregated Metrics:
──────────────────
┌────────────────────────────────────────┐
│ service_name                           │
│ date                                   │
│ deployment_frequency                   │
│ avg_lead_time                          │
│ change_failure_rate                    │
│ avg_mttr                               │
│ operational_performance                │
│ dora_level (elite/high/medium/low)     │
└────────────────────────────────────────┘
```

---

## CI/CD Pipeline

### Jenkins Pipeline Architecture

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                         Jenkins CI/CD Pipeline                                │
└──────────────────────────────────────────────────────────────────────────────┘

Trigger:
───────
Git commit/PR → GitHub Webhook → Jenkins

Pipeline Stages:
───────────────

┌────────────────────────────────────────────────────────────────────────┐
│ Stage 1: Checkout                                           │ ~30s     │
│────────────────────────────────────────────────────────────────────────│
│ ┌────────────────────────────────────────────────────────────────┐    │
│ │ - Clone repository                                             │    │
│ │ - Checkout specific commit/branch                             │    │
│ │ - Initialize submodules (if any)                              │    │
│ └────────────────────────────────────────────────────────────────┘    │
└────────────────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌────────────────────────────────────────────────────────────────────────┐
│ Stage 2: Build & Test                                       │ ~2-5min  │
│────────────────────────────────────────────────────────────────────────│
│ ┌────────────────────────────────────────────────────────────────┐    │
│ │ Parallel Tasks:                                                │    │
│ │                                                                │    │
│ │  ┌──────────────────┐    ┌──────────────────┐                │    │
│ │  │   Build          │    │   Unit Tests     │                │    │
│ │  │   - Compile      │    │   - Run tests    │                │    │
│ │  │   - Dependencies │    │   - Coverage     │                │    │
│ │  └──────────────────┘    └──────────────────┘                │    │
│ │                                                                │    │
│ │  ┌──────────────────┐    ┌──────────────────┐                │    │
│ │  │   Lint           │    │   Type Check     │                │    │
│ │  │   - Code style   │    │   - Static types │                │    │
│ │  └──────────────────┘    └──────────────────┘                │    │
│ └────────────────────────────────────────────────────────────────┘    │
└────────────────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌────────────────────────────────────────────────────────────────────────┐
│ Stage 3: Security Scanning                                  │ ~3-5min  │
│────────────────────────────────────────────────────────────────────────│
│ ┌────────────────────────────────────────────────────────────────┐    │
│ │ Parallel Security Scans:                                       │    │
│ │                                                                │    │
│ │  ┌─────────────────────────────────────────────────┐          │    │
│ │  │ 1. Gitleaks (Secrets Scanning)                  │          │    │
│ │  │    Quality Gate: Zero tolerance                 │          │    │
│ │  │    ⚠️  FAIL → Pipeline stops immediately        │          │    │
│ │  └─────────────────────────────────────────────────┘          │    │
│ │                                                                │    │
│ │  ┌─────────────────────────────────────────────────┐          │    │
│ │  │ 2. SonarQube (SAST)                             │          │    │
│ │  │    - Code quality analysis                      │          │    │
│ │  │    - Security vulnerabilities                   │          │    │
│ │  │    - Technical debt tracking                    │          │    │
│ │  │    Quality Gate: Zero new vulnerabilities       │          │    │
│ │  │    ⚠️  Main branch: MUST pass                   │          │    │
│ │  └─────────────────────────────────────────────────┘          │    │
│ │                                                                │    │
│ │  ┌─────────────────────────────────────────────────┐          │    │
│ │  │ 3. Dependency Check (OWASP)                     │          │    │
│ │  │    - Known vulnerabilities in dependencies      │          │    │
│ │  │    Quality Gate: CVSS ≥7 blocks build          │          │    │
│ │  └─────────────────────────────────────────────────┘          │    │
│ └────────────────────────────────────────────────────────────────┘    │
└────────────────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌────────────────────────────────────────────────────────────────────────┐
│ Stage 4: Build Container Image                             │ ~2-3min  │
│────────────────────────────────────────────────────────────────────────│
│ ┌────────────────────────────────────────────────────────────────┐    │
│ │ - Build Docker image with Dockerfile or Buildpack          │    │
│ │ - Tag with commit SHA and semantic version                 │    │
│ │ - Multi-stage build for optimization                       │    │
│ │                                                             │    │
│ │   Example tags:                                            │    │
│ │   - harbor.fawkes.local/fawkes/service:v1.2.3             │    │
│ │   - harbor.fawkes.local/fawkes/service:abc123def          │    │
│ │   - harbor.fawkes.local/fawkes/service:latest             │    │
│ └────────────────────────────────────────────────────────────────┘    │
└────────────────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌────────────────────────────────────────────────────────────────────────┐
│ Stage 5: Container Scanning                                │ ~2min    │
│────────────────────────────────────────────────────────────────────────│
│ ┌────────────────────────────────────────────────────────────────┐    │
│ │ Trivy Container Scan:                                          │    │
│ │ - OS package vulnerabilities                                   │    │
│ │ - Application dependencies                                     │    │
│ │ - Misconfigurations                                            │    │
│ │ - Generate SBOM (CycloneDX/SPDX)                             │    │
│ │                                                                │    │
│ │ Quality Gate: HIGH/CRITICAL = FAIL                            │    │
│ │ ⚠️  Severity: HIGH, CRITICAL                                  │    │
│ │                                                                │    │
│ │ Override: .trivyignore with expiry dates                      │    │
│ └────────────────────────────────────────────────────────────────┘    │
└────────────────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌────────────────────────────────────────────────────────────────────────┐
│ Stage 6: Push to Registry                                  │ ~1min    │
│────────────────────────────────────────────────────────────────────────│
│ ┌────────────────────────────────────────────────────────────────┐    │
│ │ - Push image to Harbor registry                                │    │
│ │ - Harbor automatically scans image again                       │    │
│ │ - Generate SBOM and sign image (optional)                      │    │
│ └────────────────────────────────────────────────────────────────┘    │
└────────────────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌────────────────────────────────────────────────────────────────────────┐
│ Stage 7: Update GitOps Repository                          │ ~30s     │
│────────────────────────────────────────────────────────────────────────│
│ ┌────────────────────────────────────────────────────────────────┐    │
│ │ - Clone GitOps repository                                      │    │
│ │ - Update image tag in kustomization.yaml or values.yaml       │    │
│ │ - Commit and push changes                                      │    │
│ │ - This triggers ArgoCD to sync and deploy                      │    │
│ └────────────────────────────────────────────────────────────────┘    │
└────────────────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌────────────────────────────────────────────────────────────────────────┐
│ Stage 8: Notify & Record                                   │ ~10s     │
│────────────────────────────────────────────────────────────────────────│
│ ┌────────────────────────────────────────────────────────────────┐    │
│ │ - Send webhook to DevLake for DORA metrics                     │    │
│ │ - Notify team (Slack, email, etc.)                             │    │
│ │ - Archive artifacts and reports                                │    │
│ │ - Update build status in GitHub                                │    │
│ └────────────────────────────────────────────────────────────────┘    │
└────────────────────────────────────────────────────────────────────────┘

Total Pipeline Time: ~10-15 minutes (for typical service)
```

---

## Security Scanning Pipeline

See the comprehensive security scanning pipeline diagram in [Architecture Documentation](../architecture.md#security-scanning-pipeline) section.

Key security gates enforced in Epic 1:
1. **Gitleaks**: Zero tolerance for hardcoded secrets
2. **SonarQube**: Zero new vulnerabilities on main branch
3. **OWASP Dependency Check**: CVSS ≥7 blocks build
4. **Trivy**: HIGH/CRITICAL vulnerabilities block deployment
5. **Kyverno**: Runtime policy enforcement

---

## Observability Stack

### Telemetry Collection Architecture

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                       Observability Stack Architecture                        │
└──────────────────────────────────────────────────────────────────────────────┘

Application Layer:
─────────────────

┌────────────┐  ┌────────────┐  ┌────────────┐  ┌────────────┐
│Application │  │Application │  │Application │  │Application │
│   Pod 1    │  │   Pod 2    │  │   Pod 3    │  │   Pod 4    │
└─────┬──────┘  └─────┬──────┘  └─────┬──────┘  └─────┬──────┘
      │               │               │               │
      │ Metrics       │ Logs          │ Traces        │ All Three
      │ :8080/metrics │ stdout/stderr │ OTLP          │
      │               │               │               │
┌─────▼───────────────▼───────────────▼───────────────▼─────────┐
│                  Telemetry Collection                          │
│                                                                │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────┐   │
│  │  Prometheus  │  │  Fluent Bit  │  │  OpenTelemetry   │   │
│  │   (Scrape)   │  │ (DaemonSet)  │  │    Collector     │   │
│  │              │  │              │  │                  │   │
│  │ - Pull model │  │ - Log files  │  │ - Traces (OTLP)  │   │
│  │ - /metrics   │  │ - Container  │  │ - Metrics (OTLP) │   │
│  │ - Every 15s  │  │   logs       │  │ - Logs (OTLP)    │   │
│  └──────┬───────┘  └──────┬───────┘  └────────┬─────────┘   │
│         │                  │                    │             │
└─────────┼──────────────────┼────────────────────┼─────────────┘
          │                  │                    │
          ▼                  ▼                    ▼
┌──────────────────────────────────────────────────────────────┐
│                    Storage Layer                              │
│                                                               │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │  Prometheus  │  │  OpenSearch  │  │ Grafana Tempo│      │
│  │   (TSDB)     │  │              │  │              │      │
│  │              │  │ - Logs       │  │ - Traces     │      │
│  │ - Metrics    │  │ - Full-text  │  │ - Sampling   │      │
│  │ - Retention: │  │   search     │  │ - Retention: │      │
│  │   30 days    │  │ - Retention: │  │   7 days     │      │
│  │              │  │   7 days     │  │              │      │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘      │
│         │                  │                  │              │
└─────────┼──────────────────┼──────────────────┼──────────────┘
          │                  │                  │
          └──────────────────┼──────────────────┘
                             │
                             ▼
┌──────────────────────────────────────────────────────────────┐
│                  Visualization & Analysis                     │
│                                                               │
│  ┌────────────────────────────────────────────────────┐     │
│  │                    Grafana                          │     │
│  │                                                     │     │
│  │  Data Sources:                                     │     │
│  │  - Prometheus (metrics)                            │     │
│  │  - OpenSearch (logs)                               │     │
│  │  - Tempo (traces)                                  │     │
│  │                                                     │     │
│  │  Dashboards:                                       │     │
│  │  - DORA Metrics                                    │     │
│  │  - Cluster Health                                  │     │
│  │  - Application Performance                         │     │
│  │  - Service Dependencies                            │     │
│  │                                                     │     │
│  │  Alerting:                                         │     │
│  │  - Threshold alerts                                │     │
│  │  - Anomaly detection                               │     │
│  │  - Multi-channel notifications                     │     │
│  └────────────────────────────────────────────────────┘     │
└──────────────────────────────────────────────────────────────┘
```

---

## Network Architecture

### Ingress and Traffic Flow

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                        Network Architecture                                   │
└──────────────────────────────────────────────────────────────────────────────┘

External Traffic:
────────────────

        Internet
            │
            │ HTTPS (443)
            ▼
┌───────────────────────────────────────────────────────────┐
│               Load Balancer / Cloud Provider               │
│                 (AWS ALB / Azure LB)                       │
└─────────────────────────┬─────────────────────────────────┘
                          │
                          │ Forward to Ingress
                          ▼
┌───────────────────────────────────────────────────────────┐
│            Ingress Controller (ingress-nginx)             │
│                  Namespace: ingress-nginx                 │
│                                                           │
│  ┌─────────────────────────────────────────────────┐    │
│  │ TLS Termination (cert-manager)                  │    │
│  │ - Let's Encrypt certificates                    │    │
│  │ - Automatic renewal                             │    │
│  └─────────────────────────────────────────────────┘    │
│                                                           │
│  ┌─────────────────────────────────────────────────┐    │
│  │ Routing Rules:                                  │    │
│  │                                                 │    │
│  │ backstage.fawkes.local    → backstage:7007     │    │
│  │ argocd.fawkes.local       → argocd-server:443  │    │
│  │ jenkins.fawkes.local      → jenkins:8080       │    │
│  │ grafana.fawkes.local      → grafana:80         │    │
│  │ harbor.fawkes.local       → harbor:443         │    │
│  │ sonarqube.fawkes.local    → sonarqube:9000     │    │
│  │ devlake.fawkes.local      → devlake-ui:4000    │    │
│  └─────────────────────────────────────────────────┘    │
└─────────────────────────┬─────────────────────────────────┘
                          │
            ┌─────────────┼─────────────┐
            │             │             │
            ▼             ▼             ▼
┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│  backstage   │  │   argocd     │  │   jenkins    │
│  Service     │  │   Service    │  │   Service    │
│  (ClusterIP) │  │  (ClusterIP) │  │  (ClusterIP) │
└──────┬───────┘  └──────┬───────┘  └──────┬───────┘
       │                 │                  │
       ▼                 ▼                  ▼
┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│  backstage   │  │  argocd-     │  │   jenkins    │
│  Pods        │  │  server Pods │  │   Pods       │
└──────────────┘  └──────────────┘  └──────────────┘


Internal Traffic:
────────────────

Service-to-Service Communication (within cluster):

┌────────────────┐         ┌────────────────┐
│   Backstage    │────────>│    ArgoCD      │
│                │  HTTP   │                │
│  Triggers      │         │  Create/Sync   │
│  Deployments   │         │  Applications  │
└────────────────┘         └────────────────┘

┌────────────────┐         ┌────────────────┐
│    Jenkins     │────────>│    Harbor      │
│                │  HTTPS  │                │
│  Push Images   │         │  Container     │
│                │         │  Registry      │
└────────────────┘         └────────────────┘

┌────────────────┐         ┌────────────────┐
│   Jenkins      │────────>│   SonarQube    │
│                │  HTTP   │                │
│  Send Analysis │         │  Code Quality  │
│  Results       │         │  Gates         │
└────────────────┘         └────────────────┘

┌────────────────┐         ┌────────────────┐
│   Application  │────────>│   Prometheus   │
│   Pods         │  Scrape │                │
│                │  :9090  │  Metrics       │
│  /metrics      │         │  Collection    │
└────────────────┘         └────────────────┘

┌────────────────┐         ┌────────────────┐
│   Fluent Bit   │────────>│   OpenSearch   │
│   (DaemonSet)  │  HTTP   │                │
│                │         │  Log           │
│  Forward Logs  │         │  Aggregation   │
└────────────────┘         └────────────────┘


Network Policies:
────────────────

Default Deny + Explicit Allow:

┌──────────────────────────────────────────────────────┐
│ Policy: Allow backstage → argocd                     │
│ - Namespace: backstage                               │
│ - To: argocd-server.argocd.svc:443                  │
└──────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────┐
│ Policy: Allow jenkins → harbor                       │
│ - Namespace: jenkins                                 │
│ - To: harbor.harbor.svc:443                         │
└──────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────┐
│ Policy: Allow prometheus → all namespaces            │
│ - Namespace: prometheus                              │
│ - To: *.*.svc:*/metrics                             │
└──────────────────────────────────────────────────────┘
```

---

## Data Flow Diagrams

### End-to-End Deployment Flow

```
Developer commits code
         │
         ▼
GitHub (source control)
         │
         ▼ Webhook triggers
Jenkins Pipeline
         │
         ├─> Build & Test
         ├─> Security Scans (SonarQube, Trivy)
         ├─> Build Container Image
         ├─> Push to Harbor
         └─> Update GitOps repo
                   │
                   ▼
         GitOps Repository (updated)
                   │
                   ▼ ArgoCD detects change
         ArgoCD Sync
                   │
                   ├─> Fetch manifests
                   ├─> Apply to Kubernetes
                   └─> Monitor rollout
                         │
                         ▼
                Kubernetes Cluster
                         │
                         ├─> New pods created
                         ├─> Old pods terminated
                         └─> Service updated
                               │
                               ▼
                     Application Running
                               │
                               ├─> Metrics → Prometheus
                               ├─> Logs → Fluent Bit → OpenSearch
                               ├─> Traces → OpenTelemetry Collector
                               └─> Deployment event → DevLake
                                                         │
                                                         ▼
                                                 DORA Metrics Updated
                                                         │
                                                         ▼
                                                   Grafana Dashboards
```

---

## Component Dependencies

```
┌──────────────────────────────────────────────────────────────┐
│              Component Dependency Graph                       │
├──────────────────────────────────────────────────────────────┤
│                                                               │
│  Foundation Layer (Must be deployed first):                  │
│  ┌─────────────────────────────────────────────────────┐    │
│  │  1. Kubernetes Cluster                               │    │
│  │  2. Storage Classes                                  │    │
│  │  3. Ingress Controller (ingress-nginx)              │    │
│  │  4. Cert Manager (TLS certificates)                 │    │
│  └─────────────────────────────────────────────────────┘    │
│                         │                                     │
│  Security Layer (Deploy second):                             │
│  ┌─────────────────────────────────────────────────────┐    │
│  │  5. Vault (secrets management)                       │    │
│  │  6. External Secrets Operator                        │    │
│  │  7. Kyverno (policy engine)                         │    │
│  └─────────────────────────────────────────────────────┘    │
│                         │                                     │
│  GitOps Layer (Deploy third):                                │
│  ┌─────────────────────────────────────────────────────┐    │
│  │  8. ArgoCD                                           │    │
│  │  9. GitOps repository setup                          │    │
│  └─────────────────────────────────────────────────────┘    │
│                         │                                     │
│  Platform Services (Deploy via ArgoCD):                      │
│  ┌─────────────────────────────────────────────────────┐    │
│  │  10. PostgreSQL (HA) - for Backstage, SonarQube    │    │
│  │  11. MySQL (HA) - for DevLake                       │    │
│  │  12. Harbor (container registry)                    │    │
│  │  13. Jenkins (CI/CD)                                │    │
│  │  14. SonarQube (code quality)                       │    │
│  │  15. Backstage (developer portal)                   │    │
│  └─────────────────────────────────────────────────────┘    │
│                         │                                     │
│  Observability Stack (Deploy in parallel):                   │
│  ┌─────────────────────────────────────────────────────┐    │
│  │  16. Prometheus                                      │    │
│  │  17. Grafana                                         │    │
│  │  18. OpenTelemetry Collector                        │    │
│  │  19. Fluent Bit                                      │    │
│  │  20. OpenSearch (optional)                          │    │
│  └─────────────────────────────────────────────────────┘    │
│                         │                                     │
│  DORA Metrics (Deploy last):                                 │
│  ┌─────────────────────────────────────────────────────┐    │
│  │  21. DevLake                                         │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                               │
└──────────────────────────────────────────────────────────────┘
```

---

## Deployment Timeline

**Epic 1 Deployment Sequence:**

```
Week 1:
├─ Day 1-2: Infrastructure setup (Kubernetes cluster)
├─ Day 3: Ingress, cert-manager
└─ Day 4-5: Vault, External Secrets, Kyverno

Week 2:
├─ Day 1-2: ArgoCD setup and GitOps repository
├─ Day 3: PostgreSQL and MySQL databases
└─ Day 4-5: Harbor registry

Week 3:
├─ Day 1-2: Jenkins CI/CD
├─ Day 3: SonarQube
└─ Day 4-5: Backstage developer portal

Week 4:
├─ Day 1-2: Prometheus and Grafana
├─ Day 3: OpenTelemetry and Fluent Bit
├─ Day 4: DevLake DORA metrics
└─ Day 5: Integration testing and validation
```

---

## Related Documentation

- [Architecture Overview](../architecture.md)
- [Epic 1 Platform Operations Runbook](./epic-1-platform-operations.md)
- [DORA Metrics Implementation Playbook](../playbooks/dora-metrics-implementation.md)
- [AT-E1-001 Validation](./at-e1-001-validation.md)

---

## Diagram Sources

These ASCII diagrams are version-controlled text representations. For
presentation purposes, they can be converted to images using:

- **Mermaid**: For flowcharts and sequence diagrams
- **PlantUML**: For UML and architecture diagrams
- **Graphviz**: For dependency graphs
- **draw.io / Excalidraw**: For manual diagram creation

Example Mermaid conversion available in `/docs/assets/diagrams/`.

---

## Change Log

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2024-12 | 1.0 | Initial Epic 1 architecture diagrams | Platform Team |
