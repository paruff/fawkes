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
| Jaeger | 1.51+ | See [Distributed Tracing](../observability/distributed-tracing.md) |

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

## Configuration Reference

Configuration documentation is being organized. See the existing [Configuration](../configuration.md) page.

## API Reference

API documentation is under development. The following will be available:

- Platform API - Core platform endpoints
- Metrics API - DORA metrics collection  
- Webhook API - Event-driven integrations

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
