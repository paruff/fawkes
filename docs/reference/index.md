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

| Component | Version | Documentation |
|-----------|---------|---------------|
| Kubernetes | 1.28+ | [Kubernetes Reference](kubernetes.md) |
| Terraform | 1.6+ | [Terraform Reference](terraform.md) |
| Crossplane | 1.14+ | [Crossplane Reference](crossplane.md) |

### CI/CD

| Component | Version | Documentation |
|-----------|---------|---------------|
| Jenkins | 2.426+ | [Jenkins Reference](jenkins.md) |
| ArgoCD | 2.9+ | [ArgoCD Reference](argocd.md) |
| GitHub Actions | N/A | [GitHub Actions Reference](github-actions.md) |

### Observability

| Component | Version | Documentation |
|-----------|---------|---------------|
| Prometheus | 2.47+ | [Prometheus Reference](prometheus.md) |
| Grafana | 10.2+ | [Grafana Reference](grafana.md) |
| OpenSearch | 2.11+ | [OpenSearch Reference](opensearch.md) |
| Jaeger | 1.51+ | [Jaeger Reference](jaeger.md) |

### Collaboration

| Component | Version | Documentation |
|-----------|---------|---------------|
| Mattermost | 9.2+ | [Mattermost Reference](mattermost.md) |
| Focalboard | 7.11+ | [Focalboard Reference](focalboard.md) |
| Backstage | 1.21+ | [Backstage Reference](backstage.md) |

### Security

| Component | Version | Documentation |
|-----------|---------|---------------|
| SonarQube | 10.3+ | [SonarQube Reference](sonarqube.md) |
| Trivy | 0.47+ | [Trivy Reference](trivy.md) |
| Kyverno | 1.11+ | [Kyverno Reference](kyverno.md) |
| External Secrets | 0.9+ | [External Secrets Reference](external-secrets.md) |

## Configuration Reference

| Topic | Description |
|-------|-------------|
| [Environment Variables](environment-variables.md) | Platform configuration options |
| [Helm Values](helm-values.md) | Chart configuration reference |
| [Feature Flags](feature-flags.md) | Available feature toggles |

## API Reference

| API | Description |
|-----|-------------|
| [Platform API](api/platform.md) | Core platform endpoints |
| [Metrics API](api/metrics.md) | DORA metrics collection |
| [Webhook API](api/webhooks.md) | Event-driven integrations |

## Command Reference

| CLI | Description |
|-----|-------------|
| [fawkes CLI](cli/fawkes.md) | Platform management commands |
| [ignite.sh](cli/ignite.md) | Bootstrap script reference |

## How Reference Differs from Other Documentation

| Reference | Explanation | How-To |
|-----------|-------------|--------|
| States facts | Discusses ideas | Shows steps |
| Lists options | Provides context | Solves problems |
| Describes APIs | Explains decisions | Gives instructions |
| Technical specs | Background info | Task completion |

[View Tools :material-tools:](../tools/){ .md-button .md-button--primary }
[Configuration Guide :material-cog:](../configuration.md){ .md-button }
