---
title: Home
description: Fawkes Internal Developer Platform - Data-Driven Approach to Software Delivery Excellence
---

# Fawkes Internal Developer Platform

<figure markdown>
  ![Fawkes IDP Overview](assets/images/fawkes-idp.png){ width="400" }
  <figcaption>Fawkes Platform Overview</figcaption>
</figure>

Welcome to the Fawkes project! Fawkes is an open-source platform designed to help teams achieve **elite performance** in software delivery by implementing all **24 DORA capabilities** through integrated tooling and practices. Based on research from "Accelerate" and the DORA State of DevOps reports, organizations that excel in these capabilities are **twice as likely to exceed their organizational performance goals**.

## 🎯 Elite Performance Targets

| Metric | Elite Performance | Industry Average |
|--------|------------------|------------------|
| ![](assets/images/icons/deployment-frequency.png){ width="24" } **Deployment Frequency** | Multiple deploys per day | Between once per week and once per month |
| ![](assets/images/icons/lead-time.png){ width="24" } **Lead Time** | Less than one hour | Between one week and one month |
| ![](assets/images/icons/change-failure.png){ width="24" } **Change Failure Rate** | 0-15% | 31-45% |
| ![](assets/images/icons/mttr.png){ width="24" } **MTTR** | Less than one hour | Less than one day |

## 🌟 DORA Capabilities

### Fast Flow
| Capability | Purpose | Implementation | Performance Impact |
|------------|----------|----------------|-------------------|
| ![](assets/images/icons/continuous-delivery.png){ width="24" } [Continuous Delivery](patterns/continuous-delivery.md) | Ensuring software is always in a deployable state | [Spinnaker](tools/spinnaker.md), [Flux](tools/flux.md) | 2.5x more likely to exceed goals |
| ![](assets/images/icons/automation.png){ width="24" } [Deployment Automation](patterns/deployment-automation.md) | Automating the deployment process | [Jenkins](tools/jenkins.md) | 3x more likely to meet reliability targets |
| ![](assets/images/icons/continuous-integration.png){ width="24" } [Continuous Integration](patterns/continuous-integration.md) | Frequently merging code changes | GitHub Actions | 2x faster recovery from incidents |
| ![](assets/images/icons/database.png){ width="24" } [Database Change Management](patterns/database-changes.md) | Managing database changes effectively | Flyway | 1.5x more likely to exceed productivity goals |
| ![](assets/images/icons/infrastructure.png){ width="24" } [Flexible Infrastructure](patterns/infrastructure-as-code.md) | Using cloud and infrastructure-as-code | Terraform | 2x more likely to meet cost targets |
| ![](assets/images/icons/architecture.png){ width="24" } [Loosely Coupled Architecture](patterns/architecture.md) | Enabling independent team work | Kubernetes | 1.7x higher employee satisfaction |

### Fast Feedback
| Capability | Purpose | Tools | Performance Impact |
|------------|----------|-------|-------------------|
| ![](assets/images/icons/monitoring.png){ width="24" } [Monitoring](patterns/monitoring.md) | Implementing comprehensive monitoring | Prometheus, Grafana | 2x more likely to detect issues before failure |
| ![](assets/images/icons/testing.png){ width="24" } [Test Automation](patterns/test-automation.md) | Automated testing at all levels | Selenium, JUnit | 3x lower change failure rate |
| ![](assets/images/icons/chaos.png){ width="24" } [Proactive Failure](patterns/chaos-engineering.md) | Testing system resilience | Chaos Mesh | 1.5x faster incident resolution |

### Fast Recovery
| Capability | Purpose | Tools | Performance Impact |
|------------|----------|-------|-------------------|
| ![](assets/images/icons/security.png){ width="24" } [Shift Left Security](patterns/security.md) | Early security testing | OWASP ZAP | 2x fewer security incidents |
| ![](assets/images/icons/quality.png){ width="24" } [Quality Gates](patterns/quality.md) | Improving code quality | SonarQube | 1.8x fewer production defects |
| ![](assets/images/icons/incident.png){ width="24" } [Incident Response](patterns/incident-response.md) | Quick incident resolution | Grafana | 73% faster MTTR |

## 📈 Getting Started

1. [Assess your current capabilities](getting-started/assessment.md)
2. [Choose your implementation path](getting-started/implementation-paths.md)
3. [Set up your first capability](getting-started/quick-wins.md)

[Start Your Journey :rocket:](getting-started.md){ .md-button .md-button--primary }
[Explore Capabilities](capabilities.md){ .md-button }
[View Implementation Guide](implementation-guide.md){ .md-button }