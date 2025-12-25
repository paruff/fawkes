---
title: Explanation
description: Conceptual guides that explain the "why" behind Fawkes
---

# Explanation

Explanation documentation is **understanding-oriented**. It clarifies concepts, provides background, and helps you understand why things work the way they do.

## What You'll Find Here

Explanation content in Fawkes is designed to:

- Provide context and background knowledge
- Explain concepts, architecture decisions, and design choices
- Help you understand the "why" behind features
- Connect different parts of the platform together

## Core Concepts

The following explanatory content provides deep-dive understanding of Fawkes architectural decisions and design philosophy.

### Architecture & GitOps

| Topic                                              | Description                                                                                                                                   |
| -------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------- |
| [GitOps Strategy](architecture/gitops-strategy.md) | Why ArgoCD, the App-of-Apps pattern, and the shift from push to pull deployment                                                               |
| GitOps Principles                                  | Declarative, version-controlled infrastructure - See [Module 3: GitOps Principles](../dojo/modules/white-belt/module-03-gitops-principles.md) |
| Loosely Coupled Architecture                       | Why independence matters - See [Architecture](../architecture.md)                                                                             |

### Containers & Build Strategy

| Topic                                                        | Description                                                                            |
| ------------------------------------------------------------ | -------------------------------------------------------------------------------------- |
| [Buildpacks Philosophy](containers/buildpacks-philosophy.md) | The trade-offs of Cloud Native Buildpacks vs. Dockerfiles for security and maintenance |

### Security & Compliance

| Topic                                                      | Description                                                                                                                        |
| ---------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------- |
| [Zero Trust Model](security/zero-trust-model.md)           | How Vault, Kyverno, and Istio/Ingress work together for defense in depth                                                           |
| [Policy as Code Tiers](governance/policy-as-code-tiers.md) | Understanding the Audit vs. Enforce governance model                                                                               |
| Shift Left Security                                        | Why early security testing matters - See [Module 7: Security Scanning](../dojo/modules/yellow-belt/module-07-security-scanning.md) |
| Zero Trust Architecture                                    | Modern security principles - See [Module 19: Security Zero Trust](../dojo/modules/black-belt/module-19-security-zerotrust.md)      |

### Observability

| Topic                                                   | Description                                                          |
| ------------------------------------------------------- | -------------------------------------------------------------------- |
| [Unified Telemetry](observability/unified-telemetry.md) | The role of OpenTelemetry as the standard vs. vendor-specific agents |

### Platform Engineering

| Topic                                                                               | Description                                                                                                                |
| ----------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------- |
| [Product Discovery & Delivery Flow (IP3dP)](idp/product-discovery-delivery-flow.md) | How to treat your platform as a product with continuous discovery and measurement                                          |
| What is an Internal Developer Platform?                                             | Understanding IDPs and their value - See [Module 1: What is IDP](../dojo/modules/white-belt/module-01-what-is-idp.md)      |
| Platform as a Product                                                               | Operating your platform with product thinking - See [ADR-020](../adr/ADR-020%20Platform-as-Product%20Operating%20Model.md) |
| Golden Paths                                                                        | Paved roads for developer productivity - See [Golden Path Usage](../golden-path-usage.md)                                  |

### DORA & Performance

| Topic                      | Description                                                                                                                   |
| -------------------------- | ----------------------------------------------------------------------------------------------------------------------------- |
| Understanding DORA Metrics | The four key metrics and why they matter - See [Module 2: DORA Metrics](../dojo/modules/white-belt/module-02-dora-metrics.md) |
| Elite Performance          | What it means to be an elite performer - See [Home page](../index.md)                                                         |

## Business Value

| Topic                       | Description                              | Status                                                                                                       |
| --------------------------- | ---------------------------------------- | ------------------------------------------------------------------------------------------------------------ |
| ROI of Platform Engineering | Quantifying platform value               | See [Business Case](../business_case.md)                                                                     |
| Developer Experience        | Why DX matters for business outcomes     | See [DX Metrics ADR](../adr/ADR-025%20Developer%20Experience%20Metrics%20Collection%20%26%20Dashboarding.md) |
| Risk Mitigation             | How platforms reduce organizational risk | 🚧 Coming soon                                                                                               |

## How This Differs from Other Documentation

| Explanation         | How-To Guides      | Reference            |
| ------------------- | ------------------ | -------------------- |
| Discusses concepts  | Shows steps        | Lists specifications |
| Provides background | Solves problems    | Provides data        |
| Explains decisions  | Gives instructions | Documents APIs       |
| Connects ideas      | Focuses on tasks   | Describes options    |

## Architectural Decision Records

For detailed rationale behind specific decisions, see our [ADR collection](../adr/).

[View ADRs :material-file-document:](../adr/){ .md-button .md-button--primary }
[Explore Patterns :material-puzzle:](../patterns/){ .md-button }
