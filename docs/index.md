---
title: Home
description: Fawkes Internal Developer Platform - A Comprehensive Approach to Software Delivery
---

# Fawkes Internal Developer Platform

<figure markdown>
  ![Fawkes IDP Overview](assets/images/fawkes-idp.png){ width="400" }
  <figcaption>Fawkes Platform Overview</figcaption>
</figure>

Welcome to the Fawkes project! Fawkes is an open-source platform designed to help teams improve their **software delivery performance** by implementing all **24 DORA capabilities** through integrated tooling and practices.

## 🚀 Key Metrics

| Metric | Description |
|--------|-------------|
| ![](assets/images/icons/deployment-frequency.png){ width="24" } **Deployment Frequency** | How often an organization successfully releases to production |
| ![](assets/images/icons/lead-time.png){ width="24" } **Lead Time** | The time it takes to go from code committed to code successfully running in production |
| ![](assets/images/icons/change-failure.png){ width="24" } **Change Failure Rate** | The percentage of changes that result in a failure in production |
| ![](assets/images/icons/mttr.png){ width="24" } **MTTR** | Mean Time to Restore - The time it takes to recover from a failure in production |

## 🌟 DORA Capabilities

### Fast Flow
| Capability | Purpose | Implementation |
|------------|----------|----------------|
| ![](assets/images/icons/continuous-delivery.png){ width="24" } [Continuous Delivery](patterns/continuous-delivery.md) | Ensuring software is always in a deployable state | [Spinnaker](tools/spinnaker.md), [Flux](tools/flux.md) |
| ![](assets/images/icons/automation.png){ width="24" } [Deployment Automation](patterns/deployment-automation.md) | Automating the deployment process | [Jenkins](tools/jenkins.md) |
| ![](assets/images/icons/continuous-integration.png){ width="24" } Continuous Integration | Frequently merging code changes | GitHub Actions |
| ![](assets/images/icons/database.png){ width="24" } Database Change Management | Managing database changes effectively | Flyway |
| ![](assets/images/icons/infrastructure.png){ width="24" } Flexible Infrastructure | Using cloud and infrastructure-as-code | Terraform |
| ![](assets/images/icons/architecture.png){ width="24" } Loosely Coupled Architecture | Enabling independent team work | Kubernetes |

### Fast Feedback
| Capability | Purpose | Tools |
|------------|----------|-------|
| ![](assets/images/icons/monitoring.png){ width="24" } Monitoring and Observability | Implementing comprehensive monitoring | Prometheus, Grafana |
| ![](assets/images/icons/testing.png){ width="24" } Test Automation | Automated testing at all levels | Selenium, JUnit |
| ![](assets/images/icons/chaos.png){ width="24" } Proactive Failure Management | Testing system resilience | Chaos Mesh |

### Fast Recovery
| Capability | Purpose | Tools |
|------------|----------|-------|
| ![](assets/images/icons/security.png){ width="24" } Shift Left on Security | Early security testing | OWASP ZAP |
| ![](assets/images/icons/quality.png){ width="24" } Change Failure Rate Reduction | Improving code quality | SonarQube |
| ![](assets/images/icons/incident.png){ width="24" } Time to Restore Service | Quick incident resolution | Grafana |

[Explore Capabilities](capabilities.md){ .md-button .md-button--primary }
[View Tools](tools/index.md){ .md-button }
[Implementation Patterns](patterns/index.md){ .md-button }