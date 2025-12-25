---
title: How-To Guides
description: Task-oriented guides for accomplishing specific goals with Fawkes
---

# How-To Guides

How-to guides are **task-oriented** and take you through the steps required to solve a specific problem or accomplish a particular goal.

## What You'll Find Here

How-to guides in Fawkes are designed to:

- Provide step-by-step instructions for specific tasks
- Assume you have basic familiarity with the platform
- Focus on practical outcomes
- Address real-world use cases and scenarios

## Platform Operations

The following how-to guides help you accomplish specific tasks with Fawkes.

### Deployment & Delivery

| Guide                                                         | Description                            | Status         |
| ------------------------------------------------------------- | -------------------------------------- | -------------- |
| [Onboard Service to ArgoCD](gitops/onboard-service-argocd.md) | Deploy a new microservice using GitOps | ✅ Available   |
| [Sync ArgoCD Application](gitops/sync-argocd-app.md)          | Manual and automated synchronization   | ✅ Available   |
| Configure Blue-Green Deployments                              | Set up zero-downtime deployments       | 🚧 Coming soon |
| Implement Canary Releases                                     | Gradually roll out changes             | 🚧 Coming soon |
| Rollback a Deployment                                         | Quickly revert problematic releases    | 🚧 Coming soon |

### Infrastructure

| Guide                                                             | Description                                     | Status                                                                      |
| ----------------------------------------------------------------- | ----------------------------------------------- | --------------------------------------------------------------------------- |
| Provision Infrastructure with Terraform                           | Create cloud resources declaratively            | See [Infrastructure as Code Pattern](../patterns/infrastructure-as-code.md) |
| [Configure Ingress with TLS](networking/configure-ingress-tls.md) | Set up HTTPS access with automatic certificates | ✅ Available                                                                |

### Observability

| Guide                                                                      | Description                                        | Status                                                             |
| -------------------------------------------------------------------------- | -------------------------------------------------- | ------------------------------------------------------------------ |
| [Trace Requests with Grafana Tempo](observability/trace-request-tempo.md)  | Debug latency and errors using distributed tracing | ✅ Available                                                       |
| [View DORA Metrics in DevLake](observability/view-dora-metrics-devlake.md) | Access and analyze deployment performance metrics  | ✅ Available                                                       |
| Configure Alerts                                                           | Set up proactive notifications                     | 🚧 Coming soon                                                     |
| Aggregate Logs                                                             | Centralize logging with OpenSearch                 | See [Centralized Logging](../observability/centralized-logging.md) |

### Security & Policy

| Guide                                                                              | Description                                       | Status                         |
| ---------------------------------------------------------------------------------- | ------------------------------------------------- | ------------------------------ |
| [Configure GitHub OAuth for Backstage](security/github-oauth-setup.md)             | Set up GitHub authentication for Backstage portal | ✅ Available                   |
| [GitHub OAuth Quick Start](security/github-oauth-quickstart.md)                    | 5-minute OAuth setup guide                        | ✅ Available                   |
| [Troubleshoot Kyverno Policy Violations](policy/troubleshoot-kyverno-violation.md) | Resolve policy blocks and enforcement issues      | ✅ Available                   |
| [Rotate Vault Secrets](security/rotate-vault-secrets.md)                           | Securely rotate secrets and update applications   | ✅ Available                   |
| Implement Security Scanning                                                        | Add SAST and container scanning                   | See [Security](../security.md) |
| Set Up RBAC                                                                        | Configure role-based access control               | 🚧 Coming soon                 |

### Development

| Guide                                                              | Description                                      | Status         |
| ------------------------------------------------------------------ | ------------------------------------------------ | -------------- |
| [Debug Buildpack Failures](development/debug-buildpack-failure.md) | Troubleshoot Cloud Native Buildpack build errors | ✅ Available   |
| Set Up Local Development                                           | Configure local Fawkes environment               | 🚧 Coming soon |
| Create Custom Pipeline                                             | Build Jenkins pipeline for your project          | 🚧 Coming soon |

## How to Use These Guides

1. **Identify your goal** - What specific task do you need to accomplish?
2. **Check prerequisites** - Each guide lists what you need before starting
3. **Follow the steps** - Work through the guide sequentially
4. **Verify success** - Each guide includes validation steps

## Need More Context?

If you need to understand the concepts behind these guides:

- Visit [Explanation](../explanation/) for conceptual background
- Check [Reference](../reference/) for detailed technical specifications
- Try [Tutorials](../tutorials/) if you're new to a topic

[View Playbooks :material-clipboard-list:](../playbooks/){ .md-button .md-button--primary }
[Explore Reference :material-book:](../reference/){ .md-button }
