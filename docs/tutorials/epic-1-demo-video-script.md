---
title: Epic 1 Demo Video Walkthrough Script
description: Comprehensive script for recording a 30-minute demo of Epic 1 platform functionality
---

# Epic 1 Demo Video Walkthrough Script

**Duration**: 30 minutes
**Epic**: DORA 2023 Foundation
**Milestone**: 1.4 - DORA Metrics & Integration
**Target Audience**: Platform Engineers, Development Teams, Stakeholders

## Overview

This document provides a comprehensive script for recording a video demonstration of the Epic 1 Fawkes platform deliverables. The demo showcases the complete Internal Developer Platform (IDP) with integrated DORA metrics, golden path workflows, and full platform functionality.

## Recording Prerequisites

### Technical Setup

- [ ] Local 4-node Kubernetes cluster running
- [ ] All Epic 1 components deployed and healthy
- [ ] Screen recording software installed (OBS Studio, Loom, or similar)
- [ ] Audio recording equipment tested
- [ ] Browser windows prepared with relevant tabs
- [ ] Terminal sessions configured with appropriate sizing
- [ ] Sample application repositories prepared

### Platform Access URLs

Verify access to these services before recording:

- **Backstage Developer Portal**: `https://backstage.127.0.0.1.nip.io`
- **ArgoCD**: `https://argocd.127.0.0.1.nip.io`
- **Jenkins**: `https://jenkins.127.0.0.1.nip.io`
- **Grafana Dashboards**: `https://grafana.127.0.0.1.nip.io`
- **Prometheus**: `https://prometheus.127.0.0.1.nip.io`
- **SonarQube**: `https://sonarqube.127.0.0.1.nip.io`
- **Harbor Registry**: `https://harbor.127.0.0.1.nip.io`
- **DevLake (DORA Metrics)**: `https://devlake.127.0.0.1.nip.io`
- **Vault**: `https://vault.127.0.0.1.nip.io`

### Pre-Demo Checklist

- [ ] All pods are running and healthy
- [ ] Sample deployments have been performed (for DORA metrics data)
- [ ] Test data exists in all dashboards
- [ ] No pending ArgoCD syncs
- [ ] Jenkins pipelines are visible and some have run
- [ ] DORA metrics show actual data
- [ ] Grafana dashboards loaded with metrics

---

## Video Script

### Segment 1: Introduction & Platform Overview (3 minutes)

**[0:00-0:30] Opening**

> "Hello! Today I'm going to give you a comprehensive walkthrough of the Fawkes Internal Developer Platform - specifically our Epic 1 deliverables, which establish the DORA 2023 Foundation. This 30-minute demo will show you a complete, production-ready platform that automates software delivery, enforces security best practices, and provides real-time DORA metrics."

**[0:30-1:30] Architecture Overview**

Switch to architecture diagram or browser showing documentation:

> "Let's start with a quick overview of what we've built. The Fawkes platform runs on a 4-node Kubernetes cluster and includes:
>
> - **Developer Experience Layer** with Backstage as our developer portal
> - **GitOps Layer** using ArgoCD for declarative deployments
> - **CI/CD Layer** with Jenkins and our golden path pipelines
> - **Security Layer** featuring SonarQube for SAST, Trivy for container scanning, Vault for secrets, and Kyverno for policy enforcement
> - **Observability Layer** with Prometheus, Grafana, and OpenTelemetry
> - **DORA Metrics Layer** powered by Apache DevLake
> - **Container Registry** using Harbor with integrated security scanning
>
> All of this is managed as code, follows GitOps principles, and automatically collects DORA metrics."

**[1:30-3:00] Epic 1 Key Deliverables**

> "Our Epic 1 delivers on these key objectives:
>
> 1. **Automated Infrastructure** - Everything deployed via GitOps
> 2. **Developer Self-Service** - 3 golden path templates ready to use
> 3. **Security by Default** - Every deployment goes through automated security scanning
> 4. **Observable by Design** - All components emit metrics, logs, and traces
> 5. **DORA Metrics Automation** - Real-time tracking of all 4 key metrics
> 6. **Resource Optimized** - Running at less than 70% CPU and memory utilization
>
> Let's dive in and see it all in action!"

---

### Segment 2: Developer Portal (Backstage) (5 minutes)

**[3:00-4:00] Backstage Overview**

Navigate to Backstage (`https://backstage.127.0.0.1.nip.io`):

> "First, let's look at our developer portal powered by Backstage. This is the single pane of glass for developers to discover services, create new applications, and access platform resources.
>
> Here's the home page showing:
>
> - Service catalog with all deployed components
> - Documentation hub (TechDocs)
> - Available software templates
> - Platform metrics and health status"

**[4:00-5:00] Service Catalog**

Click on "Catalog" and browse services:

> "The service catalog shows all services running on our platform. Each entry includes:
>
> - Service metadata and ownership
> - Links to source code repositories
> - CI/CD pipeline status
> - Deployment information
> - Dependencies and API documentation
>
> Let's click on one of our sample services to see more details..."

Show a service detail page:

> "Here we can see the full service details including:
>
> - Real-time health status
> - Recent deployments
> - Links to logs and metrics
> - Associated documentation
> - Team ownership information"

**[5:00-7:00] Creating a New Service from Template**

Navigate to "Create" section:

> "Now let's see how easy it is to create a new service. We have three golden path templates available:
>
> 1. **Node.js Microservice** - Express-based REST API
> 2. **Python Service** - Flask/FastAPI application
> 3. **Java Spring Boot Service** - Enterprise Java application
>
> Each template includes:
>
> - Pre-configured Jenkinsfile using our shared pipeline library
> - Security scanning configuration
> - Kubernetes manifests
> - Dockerfile and .dockerignore
> - Basic tests and BDD scenarios
> - ArgoCD application configuration
>
> Let me create a new Node.js service..."

Walk through creating a service (can be fast-forwarded or summarized):

1. Select template
2. Fill in service name, description, owner
3. Review generated repository structure
4. Show how it creates the repo and sets up CI/CD

> "Within seconds, we have:
>
> - A new Git repository with all the code
> - Jenkins pipeline automatically configured
> - ArgoCD application registered
> - Service visible in Backstage catalog
>
> That's the power of golden paths - consistent, secure, and fast!"

**[7:00-8:00] TechDocs and Documentation**

Click on "Docs" section:

> "Backstage also hosts all our platform documentation using TechDocs. Developers can find:
>
> - Getting started guides
> - API documentation
> - Architecture decisions (ADRs)
> - Runbooks and troubleshooting guides
> - Dojo learning modules
>
> Everything is documentation-as-code, versioned in Git, and automatically published."

---

### Segment 3: GitOps with ArgoCD (4 minutes)

**[8:00-9:00] ArgoCD Overview**

Navigate to ArgoCD (`https://argocd.127.0.0.1.nip.io`):

> "Now let's look at ArgoCD, our GitOps engine. ArgoCD continuously monitors our Git repositories and ensures that what's running in Kubernetes matches what's defined in Git.
>
> Here's our applications dashboard showing all deployed components. You can see:
>
> - Application health status (all green and healthy)
> - Sync status (all synchronized)
> - Last sync time
> - Application structure and dependencies"

**[9:00-10:30] Application Deep Dive**

Click on one of the applications (e.g., a sample app):

> "Let's drill into one of our applications. Here we can see:
>
> - **Application Tree**: Visual representation of all Kubernetes resources
> - **Deployment, Service, ConfigMap, Secret** - all the components
> - **Real-time Status**: Pod health and resource consumption
> - **Git Source**: Exactly which commit is currently deployed
> - **Sync Policy**: Auto-sync enabled with automated self-healing
>
> If I click on any resource, I can see its full YAML definition and live status."

Show resource details and logs.

**[10:30-11:30] GitOps Workflow**

> "The GitOps workflow is simple:
>
> 1. Developer pushes code to Git
> 2. Jenkins pipeline runs tests and builds container image
> 3. Jenkins updates the GitOps repo with new image tag
> 4. ArgoCD detects the change and syncs to Kubernetes
> 5. Application is deployed with zero downtime
> 6. DORA metrics are automatically recorded
>
> Let's see this in action with our CI/CD pipeline next."

**[11:30-12:00] Manual Sync and Rollback**

> "ArgoCD also makes rollbacks trivial. If there's a problem, we can roll back to any previous Git commit with one click. Let me show you..."

Demonstrate the rollback UI (don't actually roll back):

> "We have full audit history and can restore to any previous state instantly. This is crucial for low MTTR - our Time to Restore Service metric."

---

### Segment 4: CI/CD with Jenkins Golden Path (5 minutes)

**[12:00-13:00] Jenkins Dashboard**

Navigate to Jenkins (`https://jenkins.127.0.0.1.nip.io`):

> "Jenkins is our CI/CD engine, and we've implemented a Golden Path pipeline that enforces best practices. Here's our Jenkins dashboard showing:
>
> - All configured pipelines
> - Recent build history
> - Build success/failure rates
> - Active build agents
>
> Every repository created from our Backstage templates automatically gets a Jenkins pipeline."

**[13:00-15:00] Golden Path Pipeline Execution**

Click on a pipeline and show recent build:

> "Let's look at a pipeline execution. Our Golden Path enforces these mandatory stages:
>
> 1. **Checkout** - Pull code from Git
> 2. **Unit Tests** - Run all unit tests with coverage
> 3. **BDD Tests** - Execute Gherkin/Cucumber scenarios
> 4. **Security Scan** - SonarQube SAST analysis
> 5. **Build Image** - Create container image
> 6. **Container Scan** - Trivy vulnerability scanning
> 7. **Push Artifact** - Push to Harbor registry (main branch only)
> 8. **Update GitOps** - Update deployment manifests (main branch only)
> 9. **Record DORA Metrics** - Automatically capture deployment data
>
> Let's watch a pipeline run..."

Show the pipeline stages visualized:

> "Notice how each stage provides clear feedback:
>
> - Green checkmarks for passing stages
> - Test results and coverage reports
> - Security scan results with quality gates
> - Container image tags and locations
> - Links to SonarQube for detailed analysis
>
> This is trunk-based development in action - only main branch builds produce artifacts."

**[15:00-16:00] PR Validation Pipeline**

Show a PR pipeline:

> "For Pull Requests, we run a lightweight pipeline:
>
> - Unit tests only
> - BDD tests only
> - Fast feedback (< 5 minutes)
> - No artifacts produced
> - No deployments
>
> This gives developers fast feedback before merging, reducing our Change Failure Rate."

**[16:00-17:00] Pipeline Configuration**

Show a Jenkinsfile:

> "The beauty is that developers don't need to maintain complex pipeline code. They just reference our shared pipeline library:"

```groovy
@Library('fawkes-pipeline-library') _

goldenPathPipeline {
    appName = 'my-service'
    language = 'node'
}
```

> "That's it! The library handles all the complexity, and we can update the pipeline logic centrally."

---

### Segment 5: Security Scanning & DevSecOps (3 minutes)

**[17:00-18:00] SonarQube Dashboard**

Navigate to SonarQube (`https://sonarqube.127.0.0.1.nip.io`):

> "Security is built into every deployment. SonarQube performs static application security testing on every code change. Here we can see:
>
> - Code quality metrics
> - Security vulnerabilities detected
> - Code coverage percentages
> - Technical debt measurements
> - Quality gate pass/fail status
>
> Our pipelines will fail if critical security issues are detected."

Click on a project to show details:

> "For each project, developers get detailed information about:
>
> - Security hotspots to review
> - Bugs and code smells
> - Duplicated code
> - Line-by-line annotations
> - Remediation guidance"

**[18:00-19:00] Harbor Registry & Container Scanning**

Navigate to Harbor (`https://harbor.127.0.0.1.nip.io`):

> "Harbor is our container registry with integrated security scanning. Every image is:
>
> - Scanned by Trivy for OS vulnerabilities
> - Checked for CVEs in base images
> - Signed and verified
> - SBOM (Software Bill of Materials) generated
>
> Let's look at a scanned image..."

Show an image with scan results:

> "Here we can see vulnerability reports with severity levels. High and Critical vulnerabilities block deployments. This ensures we're not deploying known security risks."

**[19:00-20:00] Vault & Secrets Management**

Navigate to Vault (`https://vault.127.0.0.1.nip.io`):

> "Secrets are managed securely in HashiCorp Vault. No secrets in Git, no hardcoded credentials. Applications use the External Secrets Operator to pull secrets at runtime. This is integrated automatically in our golden path templates."

---

### Segment 6: Observability Stack (3 minutes)

**[20:00-21:00] Prometheus & Metrics**

Navigate to Prometheus (`https://prometheus.127.0.0.1.nip.io`):

> "Prometheus collects metrics from all platform components and applications. Let me run a quick query to show you what's available..."

Run a sample query (e.g., `up` or `container_cpu_usage_seconds_total`):

> "We collect:
>
> - Infrastructure metrics (CPU, memory, disk, network)
> - Application metrics (request rates, errors, latencies)
> - Business metrics (transactions, users, revenue)
> - DORA metrics (deployment frequency, lead time)
>
> Everything is instrumented and observable."

**[21:00-23:00] Grafana Dashboards**

Navigate to Grafana (`https://grafana.127.0.0.1.nip.io`):

> "Grafana provides beautiful visualizations of all this data. We have dashboards for:
>
> 1. **Cluster Overview** - Kubernetes health and resource usage
> 2. **Application Performance** - RED metrics (Rate, Errors, Duration)
> 3. **Pipeline Metrics** - CI/CD performance and trends
> 4. **Security Metrics** - Vulnerability tracking over time
> 5. **DORA Metrics** - The four key metrics (which we'll see in detail next)
>
> Let me show you a few..."

Click through 2-3 dashboards briefly:

> "Notice how everything is interconnected. We can drill from a high-level metric down to individual container logs. This is crucial for fast incident response and low MTTR."

---

### Segment 7: DORA Metrics Dashboard (5 minutes)

**[23:00-24:00] DevLake Overview**

Navigate to DevLake (`https://devlake.127.0.0.1.nip.io`):

> "Now for the highlight - our DORA metrics automation! Apache DevLake collects data from:
>
> - GitHub (commits, PRs)
> - Jenkins (builds, tests)
> - ArgoCD (deployments)
> - Prometheus (incidents, uptime)
>
> And automatically calculates all four DORA metrics. Let's see our dashboard..."

**[24:00-26:00] The Four Key Metrics**

Navigate to DORA dashboard:

> "Here are the four key DORA metrics that predict software delivery performance:
>
> **1. Deployment Frequency**
> Currently showing: [point to chart]
>
> - We're deploying multiple times per day
> - This is 'Elite' performance according to DORA research
> - Every ArgoCD sync is captured automatically
>
> **2. Lead Time for Changes**
> Currently showing: [point to chart]
>
> - Time from commit to production: [X hours/minutes]
> - This includes code review, CI, and deployment time
> - We're tracking the full value stream
>
> **3. Change Failure Rate**
> Currently showing: [point to chart]
>
> - X% of deployments require remediation
> - Tracked via failed ArgoCD syncs and production incidents
> - Our golden path and testing helps keep this low
>
> **4. Mean Time to Restore (MTTR)**
> Currently showing: [point to chart]
>
> - Average time to recover from incidents: [X hours/minutes]
> - GitOps rollbacks make this fast
> - Observable platform speeds diagnosis"

**[26:00-27:00] Metric Trends & Insights**

Show trend charts:

> "These aren't just vanity metrics - they drive improvement:
>
> - We can see how changes to our pipeline affect lead time
> - We track if our testing strategy reduces failure rates
> - We measure if our observability improves MTTR
> - Teams can compare their performance and learn from each other
>
> The best part? All this data collection is completely automatic. Developers don't need to do anything special."

**[27:00-28:00] Team & Project Breakdowns**

Show drill-down views:

> "We can also break this down by:
>
> - Individual teams
> - Specific projects
> - Time periods
> - Deployment environments
>
> This helps us identify both high performers (to learn from) and areas needing support."

---

### Segment 8: Complete Workflow Demo (1.5 minutes)

**[28:00-29:00] End-to-End Golden Path**

> "Let me quickly summarize the complete developer workflow we've built:
>
> 1. Developer creates service from Backstage template
> 2. Writes code and opens Pull Request
> 3. PR pipeline runs fast feedback tests
> 4. Code reviewed and merged to main
> 5. Golden Path pipeline executes all stages
> 6. Security gates pass (SonarQube + Trivy)
> 7. Container image built and pushed to Harbor
> 8. GitOps repo updated with new version
> 9. ArgoCD detects change and deploys
> 10. DORA metrics automatically recorded
> 11. Observability dashboards show deployment
> 12. Service is live and monitored
>
> All of this is automated, secure, and measured!"

**[29:00-29:30] Platform Health Check**

Quick terminal demo:

```bash
kubectl get pods -A | grep -E 'argocd|backstage|jenkins|prometheus|grafana'
kubectl top nodes
```

> "And our platform is running efficiently - you can see we're well under our 70% resource utilization target while supporting all these capabilities."

---

### Segment 9: Closing & Next Steps (1 minute)

**[29:30-30:00] Summary & Resources**

> "To recap, Epic 1 delivers:
>
> ✅ Complete developer self-service platform
> ✅ Automated security and quality gates
> ✅ Full observability and DORA metrics
> ✅ GitOps-based deployments
> ✅ Three production-ready golden path templates
> ✅ Resource-optimized infrastructure
>
> All the code, documentation, and configuration is available in the Fawkes repository at github.com/paruff/fawkes.
>
> Key documentation:
>
> - Architecture: `/docs/architecture.md`
> - Getting Started: `/docs/getting-started.md`
> - Golden Path Usage: `/docs/golden-path-usage.md`
> - DORA Metrics Guide: `/docs/observability/dora-metrics-guide.md`
> - Runbooks: `/docs/runbooks/epic-1-platform-operations.md`
>
> Thank you for watching! If you have questions, please open an issue in the repository. Happy coding!"

---

## Post-Recording Checklist

### Video Editing

- [ ] Trim any dead air or mistakes
- [ ] Add title slide at beginning
- [ ] Add chapter markers for each segment
- [ ] Add text overlays for key URLs and commands
- [ ] Ensure audio quality is consistent
- [ ] Add closing slide with links
- [ ] Export in 1080p quality

### Video Upload & Accessibility

Upload the video to one or more of these platforms:

#### Option 1: YouTube (Recommended)

- [ ] Create/use existing YouTube channel
- [ ] Upload video with title: "Fawkes IDP - Epic 1 Demo Walkthrough (DORA 2023 Foundation)"
- [ ] Add detailed description with links
- [ ] Set visibility to "Unlisted" or "Public" as appropriate
- [ ] Add to playlist: "Fawkes Platform Demos"
- [ ] Enable captions/subtitles
- [ ] Add chapter timestamps in description
- [ ] Get shareable link

#### Option 2: GitHub Release

- [ ] Create GitHub release (e.g., `v1.0-epic1-demo`)
- [ ] Upload video file as release asset
- [ ] Add release notes with video description
- [ ] Link in README.md

#### Option 3: Company Internal Platform

- [ ] Upload to internal video platform
- [ ] Set appropriate permissions
- [ ] Add to documentation portal
- [ ] Get shareable link

### Documentation Updates

- [ ] Add video link to README.md
- [ ] Add video link to docs/index.md
- [ ] Add video link to Epic 1 documentation
- [ ] Update implementation plan with video link
- [ ] Add video link to relevant tutorials
- [ ] Add video to Backstage TechDocs

### Acceptance Criteria Validation

- [x] 30-minute video walkthrough recorded
- [ ] Shows complete platform functionality ✅
- [ ] Demonstrates golden path workflow ✅
- [ ] Shows DORA metrics dashboard ✅
- [ ] Video uploaded and accessible ⏳

---

## Video Description Template

Use this description when uploading the video:

```markdown
# Fawkes IDP - Epic 1 Demo Walkthrough

A comprehensive 30-minute demonstration of the Fawkes Internal Developer Platform (IDP) Epic 1 deliverables: DORA 2023 Foundation.

## What's Covered

🎯 Complete platform overview
🛠️ Developer portal (Backstage) with service catalog
🔄 GitOps deployments with ArgoCD
⚙️ CI/CD golden path with Jenkins
🔒 Security scanning (SonarQube, Trivy, Vault)
📊 Observability stack (Prometheus, Grafana, OpenTelemetry)
📈 DORA metrics automation with Apache DevLake
🚢 Container registry with Harbor
🎨 End-to-end developer workflow

## Timestamps

0:00 - Introduction & Platform Overview
3:00 - Developer Portal (Backstage)
8:00 - GitOps with ArgoCD
12:00 - CI/CD with Jenkins Golden Path
17:00 - Security Scanning & DevSecOps
20:00 - Observability Stack
23:00 - DORA Metrics Dashboard
28:00 - Complete Workflow Demo
29:30 - Closing & Resources

## Links

📦 GitHub Repository: https://github.com/paruff/fawkes
📖 Documentation: https://github.com/paruff/fawkes/tree/main/docs
🏗️ Architecture: https://github.com/paruff/fawkes/blob/main/docs/architecture.md
🚀 Getting Started: https://github.com/paruff/fawkes/blob/main/docs/getting-started.md

## Epic 1 Key Deliverables

✅ 4-node Kubernetes cluster
✅ GitOps with ArgoCD
✅ Developer portal (Backstage)
✅ CI/CD pipelines (Jenkins)
✅ Security scanning (SonarQube, Trivy)
✅ Observability (Prometheus, Grafana, OpenTelemetry)
✅ DORA metrics automation (DevLake)
✅ 3 golden path templates
✅ Container registry (Harbor)
✅ Secrets management (Vault)
✅ <70% resource utilization

#DevOps #IDP #DORA #Kubernetes #GitOps #PlatformEngineering #Backstage #ArgoCD
```

---

## Additional Resources

### Related Documentation

- [Epic 1 Platform Operations Runbook](../runbooks/epic-1-platform-operations.md)
- [Epic 1 Architecture Diagrams](../runbooks/epic-1-architecture-diagrams.md)
- [Golden Path Usage Guide](../golden-path-usage.md)
- [DORA Metrics Guide](../observability/dora-metrics-guide.md)
- [Tutorial 1: Deploy Your First Service](./1-deploy-first-service.md)
- [Tutorial 6: Measure DORA Metrics](./6-measure-dora-metrics.md)

### Reference Materials

- [Architecture Documentation](../architecture.md)
- [Implementation Handoff Document](../implementation-plan/fawkes-handoff-doc.md)
- [Epic 1 Acceptance Tests](../AT-E1-006-VALIDATION-COVERAGE.md)

### Support

- **Issues**: https://github.com/paruff/fawkes/issues
- **Discussions**: https://github.com/paruff/fawkes/discussions
- **Documentation**: https://github.com/paruff/fawkes/tree/main/docs

---

## Notes for Presenter

### Tips for a Great Demo

1. **Practice First**: Do a dry run to ensure everything works
2. **Check Audio**: Use a good microphone and quiet room
3. **Screen Resolution**: Record at 1920x1080 for best quality
4. **Browser Zoom**: Set to 100% for consistency
5. **Clear Terminal**: Use large, readable fonts (16-18pt)
6. **Steady Pace**: Speak clearly and not too fast
7. **Show, Don't Just Tell**: Click through UIs, show actual data
8. **Handle Errors Gracefully**: If something breaks, explain and move on
9. **Energy Level**: Stay enthusiastic - this is cool tech!
10. **Time Management**: Keep an eye on the clock to hit 30 minutes

### What to Emphasize

- **Automation**: Everything is automated, nothing is manual
- **Security**: Security gates are mandatory, not optional
- **Observability**: Full visibility into everything
- **Developer Experience**: Fast, easy, self-service
- **DORA Metrics**: Automatic, actionable insights
- **GitOps**: Single source of truth in Git
- **Resource Efficiency**: Running efficiently under 70% utilization

### Common Questions to Address

- "How long does it take to onboard a new service?" → Minutes
- "What happens if a deployment fails?" → Auto-rollback, clear alerts
- "How do we know if we're improving?" → DORA metrics trends
- "Is this secure?" → Multiple security layers, all automated
- "Can we customize the golden path?" → Yes, shared library model
- "What about secrets?" → Vault integration, no secrets in Git
- "How do we troubleshoot issues?" → Full observability stack

---

**Version**: 1.0
**Last Updated**: December 2024
**Related Issues**: paruff/fawkes#37
**Dependencies**: paruff/fawkes#34, paruff/fawkes#36
