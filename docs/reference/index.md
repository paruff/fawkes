---
title: Reference
description: Technical reference documentation for Fawkes platform components
---

# Reference

Reference documentation is **information-oriented**. It provides technical descriptions of components, APIs, configurations, and specifications.

## What You'll Find Here

Reference content in Fawkes is designed to:

- Describe the machinery accurately and comprehensively
- Be structured for quick lookup and navigation
- Provide authoritative, correct information
- Serve as the definitive source for technical specifications

## Platform Components

### Infrastructure

| Component | Version | Status |
|-----------|---------|--------|
| Kubernetes | 1.28+ | See [existing tools](../tools/index.md) |
| Terraform | 1.6+ | See [existing tools](../tools/index.md) |
| Crossplane | 1.14+ | 🚧 Reference coming soon |

### CI/CD

| Component | Version | Status |
|-----------|---------|--------|
| Jenkins | 2.426+ | See [Jenkins tool doc](../tools/jenkins.md) |
| ArgoCD | 2.9+ | 🚧 Reference coming soon |
| GitHub Actions | N/A | 🚧 Reference coming soon |

### Observability

| Component | Version | Status |
|-----------|---------|--------|
| Prometheus | 2.47+ | See [Prometheus tool doc](../tools/prometheus.md) |
| Grafana | 10.2+ | 🚧 Reference coming soon |
| OpenSearch | 2.11+ | See [Centralized Logging](../observability/centralized-logging.md) |
| Grafana Tempo | 2.3+ | See [Distributed Tracing](../observability/distributed-tracing.md) |

### Collaboration

| Component | Version | Status |
|-----------|---------|--------|
| Mattermost | 9.2+ | 🚧 Reference coming soon |
| Focalboard | 7.11+ | See [Focalboard tool doc](../tools/focalboard.md) |
| Backstage | 1.21+ | 🚧 Reference coming soon |

### Security

| Component | Version | Status |
|-----------|---------|--------|
| SonarQube | 10.3+ | 🚧 Reference coming soon |
| Trivy | 0.47+ | 🚧 Reference coming soon |
| Kyverno | 1.11+ | 🚧 Reference coming soon |
| External Secrets | 0.9+ | 🚧 Reference coming soon |

## API Reference

REST API specifications for platform services.

| API | Description | Status |
|-----|-------------|--------|
| [Backstage Plugins API](api/backstage-plugins.md) | Internal Backstage plugins (Che Launcher, DevLake Dashboard) | ✅ Available |
| [Jenkins Webhook API](api/jenkins-webhook.md) | Trigger Jenkins pipelines via webhooks | ✅ Available |

## Custom Resource Definitions (CRDs)

Field-level specifications for Kubernetes custom resources and Devfiles.

| CRD | Description | Status |
|-----|-------------|--------|
| [Golden Path Devfile](crds/golden-path-crd.md) | Eclipse Che workspace configuration specification | ✅ Available |

## Configuration Reference

Helm values and configuration tables for platform components.

| Component | Description | Status |
|-----------|-------------|--------|
| [Jenkins Helm Values](config/jenkins-values.md) | Complete Jenkins Helm chart configuration | ✅ Available |
| [Prometheus Helm Values](config/prometheus-values.md) | Complete Prometheus monitoring configuration | ✅ Available |
| See [Configuration Guide](../configuration.md) | General platform configuration | ✅ Available |

## Policy Reference

Complete listings of active policies and their enforcement modes.

| Policy Type | Description | Status |
|-------------|-------------|--------|
| [Kyverno Policy List](policies/kyverno-policy-list.md) | All active Kyverno policies (security, mutation, generation) | ✅ Available |

## Catalog Reference

Service types and capabilities available in the platform.

| Catalog | Description | Status |
|---------|-------------|--------|
| [Service Types](catalogue/service-types.md) | Supported services and deployment patterns | ✅ Available |

## Glossary

| Resource | Description |
|----------|-------------|
| [Glossary](glossary.md) | Fawkes-specific terms, concepts, and acronyms |

## Command Reference

CLI documentation is under development. The following will be available:

- fawkes CLI - Platform management commands
- ignite.sh - Bootstrap script reference

## How Reference Differs from Other Documentation

| Reference | Explanation | How-To |
|-----------|-------------|--------|
| States facts | Discusses ideas | Shows steps |
| Lists options | Provides context | Solves problems |
| Describes APIs | Explains decisions | Gives instructions |
| Technical specs | Background info | Task completion |

[View Tools :material-tools:](../tools/){ .md-button .md-button--primary }
[Configuration Guide :material-cog:](../configuration.md){ .md-button }
