# Fawkes Architecture Overview

## Document Information

**Version**: 1.0
**Last Updated**: October 4, 2025
**Status**: Living Document
**Audience**: Contributors, Adopters, Platform Engineers

---

## Table of Contents

1. [Introduction](#introduction)
2. [Architectural Principles](#architectural-principles)
3. [High-Level Architecture](#high-level-architecture)
4. [Component Overview](#component-overview)
5. [Data Flow](#data-flow)
6. [Integration Patterns](#integration-patterns)
7. [Security Architecture](#security-architecture)
8. [Multi-Cloud Strategy](#multi-cloud-strategy)
9. [Scalability & Performance](#scalability--performance)
10. [Technology Stack](#technology-stack)
11. [Future Architecture](#future-architecture)

---

## Introduction

Fawkes is an opinionated Internal Delivery Platform (IDP) designed to accelerate software delivery through automation, observability, and continuous learning. This document describes the architectural design, component interactions, and key technical decisions.

### Architectural Context

Fawkes sits at the intersection of:
- **Platform Engineering**: Providing self-service infrastructure and tooling
- **DevSecOps**: Integrating security throughout the delivery pipeline
- **DORA Research**: Optimizing for the four key metrics
- **GitOps**: Declarative, version-controlled infrastructure and applications

---

## Architectural Principles

### 1. Developer Experience First
- Self-service capabilities over ticket-driven workflows
- Golden paths for common scenarios
- Single pane of glass (Backstage) for discovery and management
- Fast feedback loops (build, test, deploy in minutes, not hours)

### 2. Observable by Default
- Every component exposes metrics, logs, and traces
- DORA metrics collected automatically
- Distributed tracing for end-to-end visibility
- Real-time dashboards for platform health

### 3. Secure by Design
- Security scanning at every stage (code, dependencies, containers, runtime)
- Policy-as-code for compliance automation
- Least privilege access controls
- Secrets management with rotation
- Zero-trust networking (roadmap)

### 4. Declarative & GitOps-Driven
- All configuration stored in Git
- Automated reconciliation of desired state
- Audit trail through Git history
- Easy rollback capabilities

### 5. Cloud-Agnostic with Pragmatic Defaults
- Multi-cloud support through abstraction layers
- Provider-specific optimizations where needed
- Start with AWS, expand to Azure/GCP
- On-premises capable (though cloud-first)

### 6. Extensible & Pluggable
- Plugin architecture for custom extensions
- Well-defined APIs for integration
- Modular components that can be adopted incrementally
- Community contributions encouraged

### 7. Metrics-Driven Improvement
- Measure everything
- DORA metrics as first-class citizens
- A/B testing for platform changes
- Continuous optimization based on data

---

## High-Level Architecture

### C4 Model - Context Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                        External Systems                          │
│                                                                   │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐        │
│  │  GitHub  │  │  Cloud   │  │Container │  │  Secrets │        │
│  │  (SCM)   │  │ Provider │  │ Registry │  │  Manager │        │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘        │
└─────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────┐
│                        Fawkes Platform                            │
│                                                                   │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │              Developer Portal (Backstage)                  │  │
│  │         Self-Service | Catalog | Templates | Docs         │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                    │                              │
│  ┌─────────────┬─────────────┬─────────────┬─────────────┐     │
│  │   CI/CD     │   GitOps    │Observability│  Security   │     │
│  │  (Jenkins)  │  (ArgoCD)   │(Prom/Graf)  │(SonarQube)  │     │
│  └─────────────┴─────────────┴─────────────┴─────────────┘     │
│                                    │                              │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │      Infrastructure Layer (Kubernetes + IaC)              │  │
│  │            Terraform | Crossplane | Helm                  │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────┐
│                      Application Teams                            │
│                                                                   │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐        │
│  │  Team A  │  │  Team B  │  │  Team C  │  │  Team D  │        │
│  │  Apps    │  │  Apps    │  │  Apps    │  │  Apps    │        │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘        │
└─────────────────────────────────────────────────────────────────┘
```

### Key Boundaries

**North**: Developer interaction through Backstage portal and Git
**South**: Kubernetes clusters and cloud infrastructure
**East/West**: External systems and services
**Core**: Platform services providing CI/CD, GitOps, observability, security

---

## Developer Experience Layer

The Developer Experience (DX) Layer is the primary interface between developers and the Fawkes platform. It provides a unified, authenticated interface for self-service capabilities, monitoring, and service discovery.

### Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         Developer Experience Layer                           │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌────────────────────────────────────────────────────────────────────────┐ │
│  │                        Backstage Developer Portal                       │ │
│  │                                                                          │ │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌────────────┐ │ │
│  │  │   Service    │  │   Software   │  │   TechDocs   │  │   Search   │ │ │
│  │  │   Catalog    │  │  Templates   │  │              │  │            │ │ │
│  │  └──────────────┘  └──────────────┘  └──────────────┘  └────────────┘ │ │
│  │                                                                          │ │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌────────────┐ │ │
│  │  │   Plugins    │  │     Auth     │  │  Kubernetes  │  │   Dojo     │ │ │
│  │  │   (CI/CD)    │  │   (OAuth)    │  │   Status     │  │  Learning  │ │ │
│  │  └──────────────┘  └──────────────┘  └──────────────┘  └────────────┘ │ │
│  └────────────────────────────────────────────────────────────────────────┘ │
│                                      │                                       │
│                                      ▼                                       │
│  ┌────────────────────────────────────────────────────────────────────────┐ │
│  │                           PostgreSQL (HA)                               │ │
│  │                    CloudNativePG: db-backstage-dev                      │ │
│  └────────────────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────────┘
                                       │
                 ┌─────────────────────┼─────────────────────┐
                 │                     │                     │
                 ▼                     ▼                     ▼
         ┌─────────────┐       ┌─────────────┐       ┌─────────────┐
         │   Jenkins   │       │   ArgoCD    │       │   GitHub    │
         │   (CI/CD)   │       │   (GitOps)  │       │   (OAuth)   │
         └─────────────┘       └─────────────┘       └─────────────┘
```

### Key Components

| Component | Purpose | Technology |
|-----------|---------|------------|
| **Backstage Portal** | Single pane of glass for developers | TypeScript/React |
| **Service Catalog** | Inventory of services, APIs, resources | Backstage Core |
| **Software Templates** | Golden paths for new services | Backstage Scaffolder |
| **TechDocs** | Documentation as code | MkDocs + Backstage |
| **Authentication** | SSO via OAuth 2.0/OIDC | GitHub OAuth |
| **PostgreSQL** | Catalog and session storage | CloudNativePG (HA) |

### Authentication Flow

```
Developer Access Request
         │
         ▼
┌─────────────────────────────────────────────────────────────┐
│                      Ingress Controller                      │
│                   (HTTPS: backstage.fawkes.idp)              │
└─────────────────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────────────┐
│                    Backstage Frontend                        │
│                                                              │
│  ┌──────────────────┐                                       │
│  │ Unauthenticated? │──Yes──┐                               │
│  └──────────────────┘       │                               │
│           │                 │                               │
│          No                 ▼                               │
│           │       ┌──────────────────┐                      │
│           │       │ Redirect to SSO  │                      │
│           │       │  (GitHub OAuth)  │                      │
│           │       └──────────────────┘                      │
│           │                 │                               │
│           │                 ▼                               │
│           │       ┌──────────────────┐                      │
│           │       │ OAuth Callback   │                      │
│           │       │ Validate Token   │                      │
│           │       └──────────────────┘                      │
│           │                 │                               │
│           ▼                 ▼                               │
│       ┌──────────────────────────────────────────────────┐ │
│       │                 Authenticated                     │ │
│       │          Access to Catalog, Templates, Docs       │ │
│       └──────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

### Deployment Configuration

**High Availability**:
- 2 replicas with pod anti-affinity
- Pod disruption budget (minAvailable: 1)
- PostgreSQL HA cluster (3 instances)

**Resource Allocation**:
- Backstage: 500m-2 CPU, 512Mi-2Gi memory
- PostgreSQL: 500m-2 CPU, 512Mi-2Gi memory

**Security**:
- TLS termination at ingress (cert-manager)
- Non-root container execution
- Read-only filesystem where possible
- Security context with dropped capabilities

### Integration Points

| Integration | Purpose | Configuration |
|-------------|---------|---------------|
| **GitHub OAuth** | User authentication | `auth.providers.github` |
| **GitHub API** | Repository discovery | `integrations.github` |
| **Jenkins** | CI/CD pipeline status | `proxy.endpoints./jenkins` |
| **ArgoCD** | Deployment status | `proxy.endpoints./argocd` |
| **Kubernetes** | Resource status | `kubernetes.clusterLocatorMethods` |
| **Prometheus** | Metrics exposure | ServiceMonitor |

---

## Component Overview

### 1. Developer Portal (Backstage)

**Purpose**: Single pane of glass for developer self-service

**Key Features**:
- Software catalog (services, APIs, resources)
- Software templates (golden paths)
- TechDocs (documentation as code)
- Plugin ecosystem (CI/CD status, metrics, alerts)

**Technology**: Backstage (TypeScript/React), PostgreSQL

**Integrations**:
- GitHub (repository discovery, authentication)
- Jenkins (pipeline status)
- ArgoCD (deployment status)
- Grafana (metrics dashboards)

### 2. CI/CD Layer (Jenkins)

**Purpose**: Continuous integration and build automation

**Key Features**:
- Pipeline as code (Jenkinsfile)
- Dynamic Kubernetes agents
- Shared pipeline libraries
- Multi-stage builds (build, test, scan, package)

**Technology**: Jenkins, Kubernetes plugin, Docker

**Pipelines**:
- Build pipeline (compile, unit test)
- Security scan pipeline (SAST, dependency check, container scan)
- Integration test pipeline
- Deployment pipeline (publish artifacts, trigger CD)

### 3. GitOps Layer (ArgoCD)

**Purpose**: Declarative continuous delivery

**Key Features**:
- Git as source of truth
- Automated sync and reconciliation
- Progressive delivery (blue-green, canary)
- Multi-cluster management
- Rollback capabilities

**Technology**: ArgoCD, Kustomize/Helm

**Repository Structure**:
```
gitops-repo/
├── apps/
│   ├── team-a/
│   ├── team-b/
├── platform/
│   ├── backstage/
│   ├── jenkins/
│   ├── prometheus/
└── infrastructure/
    ├── clusters/
    ├── namespaces/
```

### 4. Observability Stack

**Purpose**: Comprehensive monitoring, logging, and tracing

**Components**:

**Metrics** (Prometheus + Grafana):
- Platform metrics (Jenkins, ArgoCD, Backstage)
- Application metrics (custom + OpenTelemetry)
- DORA metrics (automated collection)
- Infrastructure metrics (Kubernetes, nodes)

**Logging** (OpenSearch + Fluent Bit):
- Centralized log aggregation
- Structured logging
- Log correlation with traces
- Retention policies

**Tracing** (Jaeger + OpenTelemetry):
- Distributed tracing
- Service dependency mapping
- Performance analysis
- Request flow visualization

**Alerting** (Grafana Alerting):
- Threshold-based alerts
- Anomaly detection
- Multi-channel notifications (Slack, PagerDuty, email)

### 5. Security Layer

**Purpose**: Shift-left security and compliance automation

**Components**:

**Code Security** (SonarQube):
- Static analysis (SAST)
- Code quality gates
- Technical debt tracking
- Security hotspots

**Container Security** (Trivy):
- Image vulnerability scanning
- SBOM generation
- Policy enforcement
- Registry integration

**Secrets Management** (HashiCorp Vault + External Secrets Operator):
- HashiCorp Vault for centralized secrets management (HA deployment)
- Vault Agent Sidecar for automatic secret injection into pods
- CSI Secret Store Driver for volume-based secret mounting
- External Secrets Operator for cloud provider integration
- Kubernetes Auth Method for service account authentication
- Dynamic secret generation and automatic rotation
- Comprehensive audit logging for compliance

**Policy Enforcement** (Kyverno):
- Admission control
- Resource validation
- Mutation policies
- Reporting and compliance

### 6. DORA Metrics Service

**Purpose**: Automated collection and visualization of DORA metrics

**Implementation**: Apache DevLake provides unified DORA metrics collection,
calculation, and visualization. In the Fawkes GitOps architecture:

- **ArgoCD** is the primary source for deployment metrics (syncs = deployments)
- **Jenkins** provides CI quality metrics (builds, tests, rework)
- **GitHub** provides commit and PR data
- **Observability** provides incident data for CFR/MTTR

**Architecture**:
```
┌─────────────────────────────────────────────────────────────────┐
│                        Data Sources                              │
│                                                                   │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │   GitHub     │  │   ArgoCD     │  │   Jenkins    │          │
│  │              │  │  (PRIMARY)   │  │   (CI/QA)    │          │
│  │ • Commits    │  │ • Syncs      │  │ • Builds     │          │
│  │ • PRs        │  │ • Deploys    │  │ • Tests      │          │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘          │
│         │                 │                  │                   │
│  ┌──────────────┐        │                  │                   │
│  │ Observability│        │                  │                   │
│  │ • Incidents  │        │                  │                   │
│  └──────┬───────┘        │                  │                   │
└─────────┼────────────────┼──────────────────┼───────────────────┘
          │                │                  │
          ▼                ▼                  ▼
┌─────────────────────────────────────────────────────────────────┐
│                      DevLake Platform                            │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │   GitHub   │   ArgoCD    │   Jenkins   │   Webhook         │ │
│  │   Plugin   │   Plugin    │   Plugin    │   Plugin          │ │
│  └─────────────────────────┬──────────────────────────────────┘ │
│                            │                                     │
│                            ▼                                     │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │                   DORA Calculations                         │ │
│  │  • Deployment Frequency (ArgoCD syncs)                     │ │
│  │  • Lead Time (Commit → ArgoCD sync)                        │ │
│  │  • CFR (Failed syncs + Incidents)                          │ │
│  │  • MTTR (Incident → Restore sync)                          │ │
│  │  • Operational Performance (SLO adherence)                 │ │
│  └────────────────────────────────────────────────────────────┘ │
│                            │                                     │
│                            ▼                                     │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │                   MySQL Database                            │ │
│  └────────────────────────────────────────────────────────────┘ │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                      Visualization                               │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │   Grafana    │  │  Backstage   │  │  DevLake UI  │          │
│  │  Dashboards  │  │   Plugin     │  │              │          │
│  └──────────────┘  └──────────────┘  └──────────────┘          │
└─────────────────────────────────────────────────────────────────┘
```

**DORA Metrics Calculated**:
1. **Deployment Frequency**: ArgoCD syncs per day/week (production apps)
2. **Lead Time for Changes**: Commit timestamp to ArgoCD sync completion
3. **Change Failure Rate**: (Failed syncs + Incidents) / Total syncs
4. **Mean Time to Restore**: Incident creation to restore sync
5. **Operational Performance**: SLO/SLI adherence from Prometheus

**CI/Rework Metrics** (from Jenkins):
- Build Success Rate
- Quality Gate Pass Rate
- Test Flakiness
- Rework Rate (retry builds)

See [ADR-016: DevLake DORA Strategy](adr/ADR-016%20devlake-dora-strategy.md) for details.

### 7. Infrastructure Layer

**Purpose**: Cloud infrastructure provisioning and management

**Components**:

**Terraform**:
- Kubernetes cluster provisioning
- VPC, networking, security groups
- IAM roles and policies
- Cloud resources (databases, caches, queues)

**Crossplane** (Roadmap):
- Kubernetes-native infrastructure management
- Cloud-agnostic abstractions
- GitOps-driven infrastructure
- Self-service resource provisioning

**Helm**:
- Package management for Kubernetes
- Platform component deployment
- Application chart templating

---

## Data Flow

### 1. Application Deployment Flow

```
Developer commits code
        │
        ▼
GitHub webhook triggers Jenkins
        │
        ▼
Jenkins Pipeline:
├── Checkout code
├── Build & unit test
├── Security scanning (SonarQube, Trivy)
├── Build container image
├── Push to registry
└── Update GitOps repository
        │
        ▼
ArgoCD detects change
        │
        ▼
ArgoCD syncs application to Kubernetes
        │
        ▼
Deployment triggers DORA metrics webhook
        │
        ▼
DORA service updates metrics
        │
        ▼
Grafana displays updated dashboards
```

### 2. Platform Component Update Flow

```
Platform team updates component config
        │
        ▼
Commit to GitOps repository
        │
        ▼
ArgoCD detects drift
        │
        ▼
ArgoCD applies changes to cluster
        │
        ▼
Prometheus scrapes new metrics
        │
        ▼
Grafana reflects changes
```

### 3. Developer Self-Service Flow

```
Developer accesses Backstage
        │
        ▼
Selects template (e.g., "Python Microservice")
        │
        ▼
Fills template parameters
        │
        ▼
Backstage Scaffolder:
├── Creates GitHub repository
├── Populates with template code
├── Configures CI/CD pipeline
├── Creates ArgoCD application
└── Registers in service catalog
        │
        ▼
Developer commits changes
        │
        ▼
Automated CI/CD pipeline executes
        │
        ▼
Application deployed to cluster
```

### 4. Observability Data Flow

```
Applications emit telemetry
        │
        ├──> Metrics → OpenTelemetry Collector → Prometheus
        │
        ├──> Logs → Fluent Bit → OpenSearch
        │
        └──> Traces → OpenTelemetry Collector → Jaeger
                                │
                                ▼
                All data queryable via Grafana
```

---

## Integration Patterns

### 1. Webhook-Based Integration

Used for real-time event notification between components.

**Example**: Jenkins → DORA Metrics Service
```
Jenkins Pipeline Completes
    │
    ▼
Webhook POST to /webhook/build
    │
    ├─ Headers: X-Jenkins-Event, X-Build-Number
    ├─ Body: Build metadata (status, duration, commit SHA)
    │
    ▼
DORA Service processes event
    │
    ├─ Calculate lead time (commit → build completion)
    ├─ Update deployment frequency
    └─ Store in PostgreSQL and expose to Prometheus
```

### 2. Pull-Based Discovery

Used for service catalog and status updates.

**Example**: Backstage → Kubernetes
```
Backstage Kubernetes Plugin
    │
    ▼
Queries Kubernetes API (every 30s)
    │
    ├─ List pods by label selector
    ├─ Get deployment status
    └─ Fetch resource metrics
    │
    ▼
Display in Backstage UI (real-time status)
```

### 3. GitOps Reconciliation

Used for declarative state management.

**Example**: ArgoCD → Kubernetes
```
ArgoCD watches Git repository
    │
    ▼
Detects drift (desired state ≠ actual state)
    │
    ▼
Reconciliation loop:
    ├─ Fetch manifests from Git
    ├─ Compare with cluster state
    ├─ Apply differences (kubectl apply)
    └─ Update sync status
    │
    ▼
Cluster converges to desired state
```

### 4. API-Based Integration

Used for programmatic interactions.

**Example**: Backstage Templates → GitHub API
```
User triggers template scaffolding
    │
    ▼
Backstage calls GitHub API:
    ├─ POST /orgs/{org}/repos (create repository)
    ├─ PUT /repos/{repo}/contents/* (add files)
    ├─ POST /repos/{repo}/hooks (add webhooks)
    └─ PUT /repos/{repo}/collaborators (set permissions)
    │
    ▼
Repository ready for development
```

---

## Security Architecture

### Defense in Depth

```
┌────────────────────────────────────────────────────────────┐
│ Layer 7: Developer Education & Awareness                   │
│ - Security training, dojo modules                          │
└────────────────────────────────────────────────────────────┘
┌────────────────────────────────────────────────────────────┐
│ Layer 6: Application Security                              │
│ - SAST (SonarQube), dependency scanning, secret detection │
└────────────────────────────────────────────────────────────┘
┌────────────────────────────────────────────────────────────┐
│ Layer 5: Container Security                                │
│ - Image scanning (Trivy), SBOM, signed images             │
└────────────────────────────────────────────────────────────┘
┌────────────────────────────────────────────────────────────┐
│ Layer 4: Runtime Security                                  │
│ - Policy enforcement (Kyverno), admission control          │
└────────────────────────────────────────────────────────────┘
┌────────────────────────────────────────────────────────────┐
│ Layer 3: Network Security                                  │
│ - Network policies, service mesh, ingress controls        │
└────────────────────────────────────────────────────────────┘
┌────────────────────────────────────────────────────────────┐
│ Layer 2: Identity & Access Management                      │
│ - RBAC, service accounts, secrets management              │
└────────────────────────────────────────────────────────────┘
┌────────────────────────────────────────────────────────────┐
│ Layer 1: Infrastructure Security                           │
│ - Encrypted storage, secure boot, hardened OS             │
└────────────────────────────────────────────────────────────┘
```

### Security Scanning Pipeline

```
Code Commit
    │
    ▼
┌─────────────────────────────────────────┐
│ Stage 1: Source Code Analysis          │
│ - SonarQube (SAST)                      │
│   * Security vulnerability detection    │
│   * Code quality metrics                │
│   * Technical debt tracking             │
│ - git-secrets (credential scanning)    │
│ - License compliance check              │
│ Quality Gate: Block if critical issues │
│                                         │
│ ⚡ Main Branch: MUST pass to proceed    │
│ 📊 Dashboard: sonarqube.fawkes.local    │
└─────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────┐
│ Stage 2: Dependency Analysis            │
│ - OWASP Dependency Check                │
│ - npm audit / pip audit                 │
│ Quality Gate: Block if high CVEs       │
└─────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────┐
│ Stage 3: Container Image Scan           │
│ - Trivy vulnerability scan              │
│ - SBOM generation                       │
│ Quality Gate: Block if critical vulns  │
└─────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────┐
│ Stage 4: Policy Validation              │
│ - Kyverno policy check                  │
│ - Resource limits validation            │
│ Quality Gate: Enforce policies         │
└─────────────────────────────────────────┘
    │
    ▼
Deploy to Kubernetes
```

### SonarQube Quality Gate Integration

The SonarQube Quality Gate is a mandatory stage in the Golden Path CI/CD pipeline:

```
┌─────────────────────────────────────────────────────────────────┐
│                  SonarQube Quality Gate Flow                     │
│                                                                   │
│  ┌──────────┐     ┌──────────────┐     ┌──────────────────┐    │
│  │  Build   │ ──► │   Analyze    │ ──► │  Quality Gate    │    │
│  │  Code    │     │  with Sonar  │     │  Evaluation      │    │
│  └──────────┘     └──────────────┘     └──────────────────┘    │
│                                                │                  │
│                    ┌───────────────────────────┴────────┐        │
│                    ▼                                    ▼        │
│           ┌──────────────┐                    ┌──────────────┐  │
│           │     PASS     │                    │     FAIL     │  │
│           │   ✅ Green   │                    │   ❌ Red     │  │
│           └──────────────┘                    └──────────────┘  │
│                    │                                    │        │
│                    ▼                                    ▼        │
│           ┌──────────────┐                    ┌──────────────┐  │
│           │ Build Image  │                    │ Stop Pipeline│  │
│           │ Push Registry│                    │ Log Failure  │  │
│           └──────────────┘                    │ Link to Report│  │
│                                               └──────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

**Quality Gate Conditions**:
- 0 new bugs
- 0 new vulnerabilities
- 100% security hotspots reviewed
- ≥80% new code coverage
- ≤3% duplicated lines
- Maintainability rating A

### Secrets Management

**Architecture**:

The Fawkes platform implements a hybrid secrets management approach using
HashiCorp Vault as the primary secrets store with External Secrets Operator
for cloud provider integration.

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          Secrets Management Layer                            │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌────────────────────────────┐    ┌────────────────────────────────────┐  │
│  │    HashiCorp Vault (HA)    │    │   External Secrets Operator        │  │
│  │                            │    │                                    │  │
│  │  ┌──────────────────────┐  │    │  • AWS Secrets Manager sync       │  │
│  │  │ vault-0 (Primary)    │  │    │  • Azure Key Vault sync           │  │
│  │  │ vault-1 (Standby)    │  │    │  • GCP Secret Manager sync        │  │
│  │  │ vault-2 (Standby)    │  │    │                                    │  │
│  │  └──────────────────────┘  │    └────────────────────────────────────┘  │
│  │                            │                     │                       │
│  │  • Kubernetes Auth         │                     │                       │
│  │  • Dynamic Secrets         │                     │                       │
│  │  • Audit Logging           │                     │                       │
│  └────────────────────────────┘                     │                       │
│              │                                       │                       │
│              │ Vault Agent Sidecar                  │ ExternalSecret        │
│              │ or CSI Driver                        │                       │
│              ▼                                       ▼                       │
│  ┌─────────────────────────────────────────────────────────────────────────┐│
│  │                        Kubernetes Secrets                                ││
│  │  (Mounted as volumes or environment variables in application pods)      ││
│  └─────────────────────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────────────────────┘
```

**Secret Injection Methods**:

| Method | Description | Use Case |
|--------|-------------|----------|
| Vault Agent Sidecar | Automatic injection via mutating webhook | Most applications, auto-rotation |
| CSI Secret Store | Mount secrets as volumes | Legacy apps, file-based config |
| External Secrets | Sync from cloud providers | Cloud-native deployments |

**Secret Rotation Flow**:
```
Secret Updated in Vault
     │
     ▼
Vault Agent Detects Change (polling interval)
     │
     ▼
Agent Updates /vault/secrets/* Files
     │
     ▼
Application Reads New Secret (no pod restart)
```

**Best Practices**:
- No secrets in Git repositories
- Secrets encrypted at rest and in transit
- Automatic rotation via Vault Agent
- Audit logging for all secret access
- Least privilege access via Vault policies
- Service account authentication (no static tokens)

---

## Multi-Cloud Strategy

### Current State (MVP): AWS Focus

**Rationale**:
- Fastest time to MVP
- Most mature Terraform provider
- Largest market share
- Extensive documentation and community

**AWS Components**:
- EKS (Kubernetes)
- VPC, subnets, security groups
- IAM roles and policies
- ECR (container registry)
- RDS (databases)
- ElastiCache (caching)
- S3 (storage)
- Route 53 (DNS)

### Target State: Multi-Cloud Abstraction

**Approach**: Crossplane for cloud-agnostic infrastructure

```
Developer requests database
    │
    ▼
Creates Kubernetes Custom Resource:
kind: Database
spec:
  engine: postgresql
  size: small
    │
    ▼
Crossplane Composition:
    │
    ├─ AWS → Creates RDS instance
    ├─ Azure → Creates Azure Database for PostgreSQL
    └─ GCP → Creates Cloud SQL instance
    │
    ▼
Connection details stored in Kubernetes Secret
    │
    ▼
Application consumes database
```

**Benefits**:
- Consistent API across clouds
- GitOps-driven infrastructure
- Self-service for developers
- Reduced cloud vendor lock-in

### Multi-Cloud Architecture

```
                    Fawkes Control Plane
                            │
        ┌───────────────────┼───────────────────┐
        │                   │                   │
        ▼                   ▼                   ▼
    AWS Region          Azure Region        GCP Region
        │                   │                   │
    ┌───────┐           ┌───────┐           ┌───────┐
    │  EKS  │           │  AKS  │           │  GKE  │
    └───────┘           └───────┘           └───────┘
        │                   │                   │
    App Workloads       App Workloads       App Workloads
```

**Cluster Federation**:
- ArgoCD manages multiple clusters
- Centralized observability (Prometheus, Grafana)
- Unified developer portal (Backstage)
- Cross-cluster service discovery

---

## Scalability & Performance

### Horizontal Scaling

**Kubernetes Cluster**:
- Node autoscaling (3-100 nodes)
- Pod autoscaling (HPA based on CPU/memory/custom metrics)
- Cluster API for cluster lifecycle management

**Platform Components**:
- Jenkins: Dynamic agents (spin up/down as needed)
- Prometheus: Sharding and federation for large environments
- Grafana: Read replicas for dashboard queries

### Performance Targets

| Metric | Target | Measurement |
|--------|--------|-------------|
| CI Build Time (small) | < 5 minutes | P95 |
| CI Build Time (large) | < 15 minutes | P95 |
| Deployment Time | < 2 minutes | P95 |
| Backstage Page Load | < 2 seconds | P95 |
| Grafana Dashboard Load | < 3 seconds | P95 |
| ArgoCD Sync Time | < 30 seconds | P95 |
| GitOps Drift Detection | < 3 minutes | Maximum |

### Resource Allocation (per cluster)

**MVP Scale** (5 teams, 25 services):
- Kubernetes nodes: 5-10 (16GB RAM, 4 vCPU each)
- Total cluster capacity: ~80GB RAM, 40 vCPU
- Platform overhead: ~30GB RAM, 15 vCPU
- Application capacity: ~50GB RAM, 25 vCPU

**Production Scale** (20 teams, 200 services):
- Kubernetes nodes: 20-50 (32GB RAM, 8 vCPU each)
- Total cluster capacity: ~640GB RAM, 400 vCPU
- Platform overhead: ~100GB RAM, 50 vCPU
- Application capacity: ~540GB RAM, 350 vCPU

### Caching Strategy

- **Backstage**: Redis for session and catalog caching
- **Jenkins**: Shared workspace volumes, Docker layer caching
- **ArgoCD**: Repository caching, manifest caching
- **Grafana**: Query result caching (5-minute TTL)

---

## Technology Stack

### Core Platform

| Component | Technology | Version | Rationale |
|-----------|-----------|---------|-----------|
| Container Orchestration | Kubernetes | 1.28+ | Industry standard, CNCF graduated |
| Infrastructure as Code | Terraform | 1.6+ | Mature, multi-cloud, large community |
| Developer Portal | Backstage | Latest | CNCF incubating, Spotify-proven |
| CI/CD | Jenkins | 2.4+ | Enterprise adoption, extensive plugins |
| GitOps | ArgoCD | 2.9+ | Kubernetes-native, progressive delivery |
| Container Registry | Harbor | 2.9+ | Security scanning, RBAC, replication |

### Observability

| Component | Technology | Version | Rationale |
|-----------|-----------|---------|-----------|
| Metrics | Prometheus | 2.48+ | CNCF graduated, Kubernetes-native |
| Visualization | Grafana | 10+ | Rich dashboards, multi-source support |
| Logging | OpenSearch | 2.11+ | Open source, Elasticsearch-compatible |
| Log Collection | Fluent Bit | 2.2+ | Lightweight, high-performance |
| Tracing | Jaeger | 1.52+ | CNCF graduated, OpenTelemetry support |
| Instrumentation | OpenTelemetry | 1.21+ | CNCF project, vendor-neutral |

### Security

| Component | Technology | Version | Rationale |
|-----------|-----------|---------|-----------|
| SAST | SonarQube | 10+ | Code quality and security analysis |
| Container Scanning | Trivy | 0.48+ | Comprehensive vulnerability detection |
| Policy Engine | Kyverno | 1.11+ | Kubernetes-native, easier than OPA |
| Secrets (Primary) | HashiCorp Vault | 1.17+ | Centralized secrets, dynamic credentials, HA |
| Secrets (Cloud Sync) | External Secrets Operator | 0.9+ | Multi-provider cloud secrets sync |
| Secrets (CSI) | Secrets Store CSI Driver | 1.4+ | Volume-based secret mounting |

### Data Stores

| Component | Technology | Version | Purpose |
|-----------|-----------|---------|---------|
| Backstage Backend | PostgreSQL | 15+ | Service catalog, user data |
| DORA Metrics | PostgreSQL | 15+ | Historical metrics storage |
| SonarQube | PostgreSQL | 15+ | Code analysis data |
| Jenkins | File system + PostgreSQL | - | Build data, job configs |

### Programming Languages

| Purpose | Language | Rationale |
|---------|----------|-----------|
| Platform Services | Go | Performance, Kubernetes ecosystem |
| DORA Metrics Service | Go or Python | Developer preference, quick development |
| Backstage Plugins | TypeScript | Backstage requirement |
| Scripts/Automation | Bash, Python | Platform automation, tooling |
| IaC Modules | HCL (Terraform) | Infrastructure provisioning |

---

## Future Architecture

### 6-Month Roadmap

**Multi-Cloud Expansion**:
- Azure support via Terraform
- GCP support via Terraform
- Crossplane implementation for cloud abstraction

**Advanced Security**:
- Service mesh (Linkerd) for mTLS
- Runtime security (Falco)
- Policy-as-code enforcement (expanded Kyverno policies)
- SLSA compliance

**Enhanced Observability**:
- Distributed tracing adoption (100% of services)
- Cost visibility (OpenCost integration)
- SLO tracking and error budgets

**Dojo Expansion**:
- 10+ learning modules
- Hands-on labs with live platform
- Certification integration complete

### 12-Month Vision

**Platform Maturity**:
- CNCF Sandbox/Incubating project
- 50+ production deployments
- Enterprise-grade stability (99.9% uptime)

**Advanced Features**:
- Multi-region deployments
- Disaster recovery automation
- Blue-green cluster upgrades
- Chaos engineering integration

**Ecosystem**:
- 20+ community plugins
- Commercial support partnerships
- Training and certification program

**Research & Development**:
- AI-powered platform insights
- Predictive failure detection
- Automated performance optimization

---

## Architectural Decision Records (ADRs)

Major architectural decisions are documented in ADRs stored in `/docs/adr/`:

- [ADR-001: Kubernetes as Container Orchestration Platform](../adr/001-kubernetes.md)
- [ADR-002: Backstage for Developer Portal](../adr/002-backstage.md)
- [ADR-003: ArgoCD for GitOps](../adr/003-argocd.md)
- [ADR-004: Jenkins for CI/CD](../adr/004-jenkins.md)
- [ADR-005: Terraform over Pulumi for IaC](../adr/005-terraform.md)
- [ADR-006: PostgreSQL for Data Persistence](../adr/006-postgresql.md)
- [ADR-009: Secrets Management](../adr/ADR-009%20secrets%20managment.md)
- [ADR-015: HashiCorp Vault Deployment](../adr/ADR-015%20vault%20deployment.md)
- [ADR-016: DevLake for DORA Metrics](../adr/ADR-016%20devlake-dora-strategy.md)

---

## Diagrams

### Component Interaction Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                         Backstage                               │
│  ┌────────┐  ┌────────┐  ┌────────┐  ┌────────┐  ┌────────┐  │
│  │Catalog │  │Templates│ │TechDocs│  │ Plugins│  │  Auth  │  │
│  └───┬────┘  └───┬────┘  └───┬────┘  └───┬────┘  └───┬────┘  │
└──────┼───────────┼───────────┼───────────┼───────────┼────────┘
       │           │           │           │           │
       │           │           │           │           │
┌──────▼───────────▼───────────▼───────────▼───────────▼────────┐
│                      Kubernetes API                             │
└──────┬───────────┬───────────┬───────────┬───────────┬────────┘
       │           │           │           │           │
   ┌───▼───┐   ┌──▼───┐   ┌──▼───┐   ┌──▼───┐   ┌──▼───┐
   │Jenkins│   │ArgoCD│   │Prom  │   │Kyverno│  │Apps │
   └───┬───┘   └──┬───┘   └──┬───┘   └──┬───┘   └──┬───┘
       │          │          │          │          │
   ┌───▼──────────▼──────────▼──────────▼──────────▼────────┐
   │              Kubernetes Workloads                       │
   │  ┌────────┐  ┌────────┐  ┌────────┐  ┌────────┐       │
   │  │  Pods  │  │Services│  │Ingress │  │ Volumes│       │
   │  └────────┘  └────────┘  └────────┘  └────────┘       │
   └──────────────────────────────────────────────────────────┘
```

### Deployment Pipeline Detail

```
┌──────────────────────────────────────────────────────────┐
│                    Git Commit                            │
└────────────────────────┬─────────────────────────────────┘
                         │
                         ▼
┌──────────────────────────────────────────────────────────┐
│            Jenkins Pipeline Triggered                    │
│                                                          │
│  Stage 1: Build          [3 min]                        │
│  ├─ Checkout code                                       │
│  ├─ Dependency resolution                               │
│  ├─ Compile                                             │
│  └─ Unit tests                                          │
│                                                          │
│  Stage 2: Security Scan  [2 min]                        │
│  ├─ SonarQube SAST                                      │
│  ├─ Dependency check                                    │
│  └─ Secret scanning                                     │
│                                                          │
│  Stage 3: Package        [1 min]                        │
│  ├─ Build Docker image                                  │
│  ├─ Trivy scan                                          │
│  └─ Push to Harbor                                      │
│                                                          │
│  Stage 4: Deploy         [30 sec]                       │
│  ├─ Update GitOps repo                                  │
│  └─ Trigger DORA webhook                                │
└────────────────────────┬─────────────────────────────────┘
                         │
                         ▼
┌──────────────────────────────────────────────────────────┐
│              ArgoCD Detects Change                       │
│                                                          │
│  ├─ Fetch manifests from Git                            │
│  ├─ Validate with Kyverno policies                      │
│  ├─ Apply to Kubernetes                                 │
│  └─ Monitor rollout status                              │
└────────────────────────┬─────────────────────────────────┘
                         │
                         ▼
┌──────────────────────────────────────────────────────────┐
│               Application Running                        │
│                                                          │
│  ├─ Prometheus scrapes metrics                          │
│  ├─ Fluent Bit collects logs                            │
│  ├─ OpenTelemetry traces requests                       │
│  └─ Grafana visualizes data                             │
└──────────────────────────────────────────────────────────┘
```

---

## Conclusion

This architecture provides a solid foundation for a production-ready Internal Delivery Platform that:

✅ Prioritizes developer experience through self-service and automation
✅ Integrates security throughout the delivery pipeline
✅ Provides comprehensive observability and DORA metrics
✅ Follows GitOps principles for declarative management
✅ Scales from small teams to enterprise deployments
✅ Remains extensible and customizable

The architecture will evolve based on community feedback, adoption patterns, and emerging best practices in platform engineering.

---

**Next Steps**:
1. Review and approve this architecture
2. Create detailed ADRs for key decisions
3. Begin MVP implementation following this blueprint
4. Iterate based on early adopter feedback

**Questions or Feedback**: Open a GitHub Discussion or contact the architecture team

---

**Document Maintainers**: Platform Architecture Team
**Review Cadence**: Quarterly or when major changes proposed
**Last Architectural Review**: October 4, 2025