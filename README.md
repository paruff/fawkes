# Fawkes - Internal Product Delivery Platform

> **🎓 Learn platform engineering while building a world-class delivery platform**

> **Status**: Pre-alpha (`v0.3.95`, September 2026) — local k3d evaluation works; cloud production is not yet ready. See [Known Limitations](docs/KNOWN_LIMITATIONS.md).

> **Scope**: Fawkes is the core IDP (platform orchestration). It is **not** the Dojo curriculum (now at [uFawkesDojo](https://github.com/paruff/uFawkesDojo)) and **not** a CI SaaS — composable stacks ([uFawkesObs / Pipe / DevX](#ufawkes-stack-ecosystem)) cover observability, delivery, and developer experience.

<p align="center">
  <img src="docs/images/fawkes-logo.png" alt="Fawkes Logo" width="200"/>
</p>

<p align="center">
  <a href="#-the-fawkes-dojo"><strong>Start Learning →</strong></a> ·
  <a href="#-quick-start"><strong>Deploy Platform →</strong></a> ·
  <a href="#-documentation"><strong>Read Docs →</strong></a> ·
  <a href="#-community"><strong>Join Community →</strong></a>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="License"/>
  <img src="https://img.shields.io/badge/kubernetes-1.28%2B-326CE5.svg" alt="Kubernetes"/>
  <img src="https://img.shields.io/badge/contributions-welcome-brightgreen.svg" alt="Contributions"/>
  <img src="https://img.shields.io/github/stars/paruff/fawkes?style=social" alt="Stars"/>
</p>

<p align="center">
  <a href="https://github.com/paruff/fawkes/actions/workflows/code-quality.yml">
    <img src="https://github.com/paruff/fawkes/actions/workflows/code-quality.yml/badge.svg" alt="Code Quality"/>
  </a>
  <a href="https://github.com/paruff/fawkes/actions/workflows/pre-commit.yml">
    <img src="https://github.com/paruff/fawkes/actions/workflows/pre-commit.yml/badge.svg" alt="Pre-commit"/>
  </a>
  <a href="https://github.com/paruff/fawkes/actions/workflows/security-and-terraform.yml">
    <img src="https://github.com/paruff/fawkes/actions/workflows/security-and-terraform.yml/badge.svg" alt="Security"/>
  </a>
  <a href="https://github.com/paruff/fawkes/actions/workflows/code-quality.yml">
    <img src="https://img.shields.io/badge/coverage-CI--enforced-informational.svg" alt="Coverage threshold enforced in CI — see code-quality workflow"/>
  </a>
</p>

---

## What Makes Fawkes Different?

Fawkes isn't just another Internal Developer Platform—it's a **complete Internal Product Delivery Platform** that uniquely combines:

### 🎓 Immersive Dojo Learning

Learn platform engineering by doing, not just reading. Progress through belt levels while building real skills on production-grade infrastructure.

### 🚀 Complete Product Delivery

Everything teams need: infrastructure, CI/CD, collaboration, project management, observability, and security—all integrated, all open source.

### 📊 DORA-Driven by Design

Four key metrics automated from day one. Measure what matters, improve continuously, achieve elite performance.

### 🤝 Unified Experience

One platform, one login, one interface. No more context switching between a dozen tools.

---

## 🚀 AWS Activate Project

Fawkes is applying for the AWS Activate program to accelerate development and provide free learning resources to the platform engineering community. We're building an AWS-native Internal Delivery Platform that helps organizations achieve Elite DORA performance.

**Why AWS?**

- Native integration with EKS, RDS, S3, and CloudWatch
- Scalable, secure infrastructure for enterprise workloads
- Cost-effective for startups and growing companies
- Best-in-class Kubernetes support with Amazon EKS

**AWS Services Used**: EKS, RDS, S3, ALB, CloudWatch, X-Ray, Secrets Manager, IAM, VPC, Certificate Manager

[Apply for AWS Activate](https://aws.amazon.com/activate/) | [AWS Deployment Guide](docs/archive/AWS_deployment_guide.md)

## AWS Activate Application

📊 Cost estimation and business case docs are not yet published — see the [archive deployment guide](docs/archive/AWS_deployment_guide.md) for current AWS notes.

---

## 🥋 The Fawkes Dojo: Learn by Doing

Platform engineering skills are hard to acquire by reading docs. The Dojo curriculum — 5 belt levels, 40 hours from novice to platform architect, hands-on labs with auto-graded validation — now lives in its own repo so it can be shared across the whole stack family:

**[Start Your Dojo Journey →](https://github.com/paruff/uFawkesDojo)**

Fastest way to learn by doing: run one composable Docker stack locally (`uFawkesObs` for observability, `uFawkesPipe` for delivery, `uFawkesDevX` for developer experience — see [Quick Start](#-quick-start)), then work the matching Dojo belt against it.

---

## 🚀 A Complete Product Delivery Platform

Unlike infrastructure-only solutions, Fawkes provides everything product teams need:

### Infrastructure & Delivery

- **Kubernetes Orchestration** - Multi-cloud ready (AWS, Azure, GCP)
- **Infrastructure as Code** - Terraform and Crossplane
- **CI/CD Pipelines** - Jenkins with golden path templates
- **GitOps Workflows** - ArgoCD for declarative deployments
- **Progressive Delivery** - Blue-green, canary, automated rollback

### Collaboration & Planning

- **Team Chat** - Mattermost for real-time collaboration
- **Project Management** - Focalboard (Notion-like) for sprints and roadmaps
- **ChatOps** - Deploy and manage from chat
- **Platform Notifications** - CI/CD, deployments, alerts in chat

### Observability & Insights

- **DORA Metrics** - Automated collection of all 4 key metrics
- **Metrics & Dashboards** - Prometheus and Grafana
- **Distributed Tracing** - Jaeger with OpenTelemetry
- **Log Aggregation** - Loki with OpenTelemetry Collector
- **Custom Dashboards** - Team-level visibility

### Security & Compliance

- **🔒 Security Plane** - Comprehensive security framework with SBOM, signing, and policy enforcement
- **Security Scanning** - SonarQube (SAST), Trivy (containers), Gitleaks (secrets)
- **Automated Secrets Detection** - Pre-commit hooks and CI/CD pipeline scanning
- **Policy Enforcement** - Kyverno for Kubernetes policies + OPA/Rego for CI/CD
- **SBOM Generation** - Syft-based Software Bill of Materials
- **Image Signing** - Cosign for cryptographic signatures
- **Secrets Management** - External Secrets Operator + HashiCorp Vault
- **Zero Trust Architecture** - Security-first architecture

**[Learn more about the Security Plane →](.security-plane/README.md)**

### Learning & Growth

- **Dojo Learning Environment** - Hands-on labs with auto-validation
- **Progress Tracking** - Visual dashboards of learning journey
- **Community Support** - Dedicated channels per belt level
- **Certification** - Recognized credentials for each belt

---

## 📊 DORA Metrics: Built-In, Not Bolt-On

Fawkes collects and visualizes the **Four Key Metrics** that separate high performers from the rest. Collection is **partial in pre-alpha** — pipelines emit deployment events, but DevLake DORA dashboards are not yet populated (see [KL-12](docs/KNOWN_LIMITATIONS.md)):

| Metric                      | What It Measures                   | Fawkes Status                                  |
| --------------------------- | ---------------------------------- | ---------------------------------------------- |
| **Deployment Frequency**    | How often you deploy to production | 🚧 Partial — events emitted, dashboards pending |
| **Lead Time for Changes**   | Time from commit to production     | 🚧 Partial — Git → CI → CD tracking, no baseline yet |
| **Change Failure Rate**     | % of deployments causing failures  | 🚧 Partial — rework-rate proxy in [METRICS](docs/METRICS.md) |
| **Time to Restore Service** | Time to recover from incidents     | 🚧 Planned — incident detection not yet wired  |

**DORA capability**: Fawkes provides the quality-internal-platform, version-control, and small-batch foundations; per-stack capability mapping lives in [ROADMAP](ROADMAP.md).

**[DORA Metrics Guide →](docs/observability/dora-metrics-guide.md)**

---

## 🎯 Who Is Fawkes For?

### Platform Engineering Teams

Build and operate internal platforms with best practices baked in. Spend less time on toil, more on innovation.

### DevOps Teams Evolving to Platform Engineering

Make the transition with a comprehensive platform that embodies modern practices.

### Engineering Leaders

Improve delivery performance with data-driven insights. Achieve elite DORA metrics.

### Platform Engineering Students

Learn by doing with hands-on labs on production-grade infrastructure. Earn recognized certifications.

### Organizations Building IDPs

Don't start from scratch. Deploy a production-ready platform and customize to your needs.

---

## ⚡ Quick Start

Not sure where to begin? Choose the path that fits your goal:

| Path                                                                                    | Goal                                                         | Time      |
| --------------------------------------------------------------------------------------- | ------------------------------------------------------------ | --------- |
| **[0 — Learn via Docker Stacks](docs/getting-started.md#path-0--learn-via-docker-stacks)** | Learn by doing: one composable stack + Dojo belt, no cluster | ~10 min   |
| **[A — Evaluate Locally](docs/getting-started.md#path-a--evaluate-locally)**             | Try Fawkes on your laptop with k3d — no cloud account needed | ~20 min   |
| **[B — Deploy to Cloud](docs/getting-started.md#path-b--deploy-to-cloud-aws-eks)**       | Production-capable deployment on AWS EKS                     | 2–4 hours |
| **[C — Enterprise Multi-Cloud](docs/getting-started.md#path-c--enterprise-multi-cloud)** | Multi-cloud, SSO, RBAC, compliance                           | 1–2 days  |

**Fastest start (Path A):**

```bash
git clone https://github.com/paruff/fawkes.git
cd fawkes
make dev-up      # creates k3d cluster + deploys 5 core components
make dev-status  # prints service URLs and credentials
```

**[Full Getting Started Guide →](docs/getting-started.md)**

---

## 🏗️ Architecture

Fawkes is built on a modern, cloud-native architecture:

```
┌─────────────────────────────────────────────────────────────┐
│              Fawkes Product Delivery Platform                │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌────────────────────────────────────────────────────┐    │
│  │       Backstage Developer Portal + Dojo Hub        │    │
│  └────────────────────────────────────────────────────┘    │
│           │                                                  │
│  ┌────────┴─────────┬──────────────┬─────────────┐        │
│  │  Collaboration   │   Project    │    Dojo     │        │
│  │  (Mattermost)    │ (Focalboard) │  Learning   │        │
│  └──────────────────┴──────────────┴─────────────┘        │
│           │                                                  │
│  ┌────────┴──────────────────────────────────────┐        │
│  │   CI/CD • GitOps • Observability • Security   │        │
│  └───────────────────────────────────────────────┘        │
│           │                                                  │
│  ┌────────┴──────────────────────────────────────┐        │
│  │  Kubernetes + Multi-Cloud Infrastructure      │        │
│  └───────────────────────────────────────────────┘        │
└─────────────────────────────────────────────────────────────┘
```

**Key Components**:

- **Backstage** - Developer portal and dojo learning hub
- **Mattermost** - Team collaboration and ChatOps
- **Focalboard** - Project management (bundled with Mattermost)
- **Jenkins** - CI/CD pipelines with golden paths
- **ArgoCD** - GitOps-driven continuous delivery
- **Prometheus & Grafana** - Metrics and dashboards
- **Loki** - Log aggregation and search
- **SonarQube & Trivy** - Security scanning
- **Dojo Environment** - Isolated learning labs

**[View Full Architecture →](docs/architecture.md)**

---

## 🎓 Learning Paths

### Path 1: I Want to Learn Platform Engineering

**Start Here**: [Dojo White Belt](https://github.com/paruff/uFawkesDojo/tree/main/white-belt)

1. Enroll in White Belt (8 hours)
2. Complete 4 modules with hands-on labs
3. Pass assessment and earn certification
4. Progress through Yellow, Green, Brown, Black belts
5. Total time: 40 hours to platform architect

**Skills You'll Gain**:

- Deploy applications with CI/CD
- Implement GitOps workflows
- Configure observability stacks
- Respond to incidents effectively
- Design platform architectures

### Path 2: I Want to Deploy Fawkes

**Start Here**: [Deployment Guide](docs/getting-started.md)

1. Review prerequisites and architecture
2. Provision cloud infrastructure (30 min)
3. Deploy platform components (30 min)
4. Configure integrations (30 min)
5. Onboard first team (1 hour)

**What You'll Have**:

- Production-ready IDP
- Automated DORA metrics
- Golden path templates
- Team collaboration platform
- Learning environment for your teams

### Path 3: I Want to Contribute

**Start Here**: [Contributing Guide](CONTRIBUTING.md)

1. Join the conversation in [GitHub Discussions](https://github.com/paruff/fawkes/discussions)
2. Review open issues and good first issues
3. Pick something that interests you
4. Submit your first PR
5. Celebrate with the community! 🎉

**Ways to Contribute**:

- Code (platform features, dojo modules)
- Documentation (guides, tutorials)
- Dojo content (create new modules)
- Community support (help others in Discussions)
- Bug reports and feature requests

---

## 📚 Documentation

Comprehensive documentation for all aspects of Fawkes:

### Getting Started

- [Installation Guide](docs/getting-started.md)
- [Deploy Your First Service](docs/tutorials/1-deploy-first-service.md) - 30-minute quick start
- [Architecture Overview](docs/ARCHITECTURE.md)
- [Configuration Reference](docs/configuration.md)
- 🎥 [Epic 1 Demo Video Script](docs/tutorials/epic-1-demo-video-script.md) - 30-minute platform walkthrough
- 📋 [Epic 1 Demo Checklist](docs/tutorials/epic-1-demo-video-checklist.md) - Quick reference for recording

### Dojo Learning

- [Dojo Architecture](https://github.com/paruff/uFawkesDojo/blob/main/Fawkes%20Dojo%3A%20Immersive%20Learning%20Architecture.md)
- [White Belt Curriculum](https://github.com/paruff/uFawkesDojo/tree/main/white-belt)
- [Yellow Belt Curriculum](https://github.com/paruff/uFawkesDojo/tree/main/modules/yellow-belt)
- [Green Belt Curriculum](https://github.com/paruff/uFawkesDojo/tree/main/modules/green-belt)
- [Brown Belt Curriculum](https://github.com/paruff/uFawkesDojo/tree/main/modules/brown-belt)
- [Black Belt Curriculum](https://github.com/paruff/uFawkesDojo/tree/main/modules/black-belt)

### Platform Components

- [Backstage](platform/apps/backstage/README.md) - Developer portal and service catalog
- [Mattermost](platform/apps/mattermost/README.md) - Team collaboration and ChatOps
- [CI Direction: Tekton + uFawkesPipe](docs/DEPLOYMENT_STRATEGY.md) - Golden-path pipeline (Jenkins retained only for legacy; see [Jenkins CaSC notes](docs/how-to/jenkins-casc-configuration.md))
- [ArgoCD / GitOps](docs/DEPLOYMENT_STRATEGY.md) - Declarative delivery and rollback protocol
- [Observability Stack](docs/observability/index.md) - Prometheus, Grafana, OTEL, Loki

### Operations

- [Runbooks](docs/runbooks/index.md) - Platform operations procedures
- [Security](docs/security.md) - Best practices and security plane
- [Troubleshooting Guide](docs/troubleshooting.md)
- [AT-E1-001 Validation Tests](docs/runbooks/at-e1-001-validation.md)
- [Azure AKS Validation Checklist](docs/runbooks/azure-aks-validation-checklist.md)

### Contributing

- [Contributing Guide](docs/contributing.md)
- [Code of Conduct](docs/CODE_OF_CONDUCT.md)
- [Development Setup](docs/development.md)
- [Pre-commit Hooks Setup](docs/PRE-COMMIT.md)
- [Architectural Decision Records](docs/adr/)

---

## 🌟 Key Features

### For Platform Teams

✅ **Production-Ready** - Battle-tested components, enterprise-grade reliability
✅ **Open Source** - No vendor lock-in, full control, MIT licensed
✅ **Multi-Cloud** - AWS, Azure, GCP with consistent APIs
✅ **GitOps Native** - Declarative configuration, automated reconciliation
✅ **Extensible** - Plugin architecture, REST APIs, customizable
✅ **Well Documented** - Comprehensive guides, tutorials, runbooks

### For Development Teams

✅ **Self-Service** - Deploy without tickets, provision infrastructure instantly
✅ **Golden Paths** - Pre-configured templates for common scenarios
✅ **Fast Feedback** - Build, test, deploy in minutes
✅ **Visibility** - Real-time status, metrics, logs, traces in one place
✅ **ChatOps** - Manage deployments from team chat
✅ **Safety** - Automated testing, security scanning, easy rollback

### For Engineering Leaders

✅ **DORA Metrics** - Measure and improve delivery performance
✅ **Cost Visibility** - Track infrastructure and operational costs
✅ **Compliance** - Automated policy enforcement, audit trails
✅ **Team Health** - Developer satisfaction tracking (NPS)
✅ **Skill Development** - Integrated learning with certification
✅ **ROI Tracking** - Quantify platform value and improvements

---

## 🔌 Extensions

Advanced capabilities available as opt-in add-ons. Extensions are **not** deployed
by default — they add operational complexity and resource requirements beyond the
core platform.

| Extension                                               | Components                                            | When to Add                                        |
| ------------------------------------------------------- | ----------------------------------------------------- | -------------------------------------------------- |
| **[AI](extensions/ai/README.md)**                       | Weaviate (vector DB), RAG service for semantic search | LLM tooling, semantic doc search                   |
| **[Data Platform](extensions/data-platform/README.md)** | DataHub (data catalog), Great Expectations (quality)  | Data catalog, lineage tracking, quality validation |

[View all extensions →](extensions/README.md)

---

## 🤝 Community

Community is forming. Join the conversation in [GitHub Discussions](https://github.com/paruff/fawkes/discussions). Office hours and chat channels will be announced once the platform reaches beta.

### Get Involved

- **GitHub Discussions** - [Ask questions, share ideas](https://github.com/paruff/fawkes/discussions)
- **GitHub Issues** - [Report bugs and request features](https://github.com/paruff/fawkes/issues)

---

## 🗺️ Roadmap

### Current Release: [v0.3.95](https://github.com/paruff/fawkes/releases/tag/v0.3.95) (September 2026, pre-alpha)

- ✅ Core architecture and governance
- ✅ Dojo curriculum spun out to [uFawkesDojo](https://github.com/paruff/uFawkesDojo)
- ✅ User research infrastructure — personas, interview guides, insights database
- ✅ Product discovery and adoption support
- ✅ Security plane — SBOM, image signing, policy enforcement
- 🚧 DORA metrics collection partial — dashboards pending ([KL-12](docs/KNOWN_LIMITATIONS.md))
- 🚧 Multi-cloud support (AWS, Azure, GCP) — evaluation only, no remote state ([KL-01](docs/KNOWN_LIMITATIONS.md))
- ✅ GitOps workflows with ArgoCD
- ✅ Observability stack (Prometheus, Grafana, OpenTelemetry)
- ✅ Tekton golden-path pipeline + CI direction set ([uFawkesPipe](https://github.com/paruff/ufawkespipe))
- ✅ Backstage developer portal
- ✅ Mattermost collaboration platform
- ✅ Extensions — AI (Weaviate, RAG service) and Data Platform (DataHub) available as opt-in add-ons

### Q1 2026: Platform Expansion

- Multi-cloud support (Azure, GCP)
- Complete belt curricula (all 5 belts)
- Advanced security features
- Enterprise features (SSO, RBAC)
- 50+ production deployments target

### Q2 2026: Ecosystem & Scale

- Backstage plugin marketplace
- Community-contributed dojo modules
- Advanced DORA analytics
- Cost optimization features
- 100+ certified platform engineers

### Q3 2026: Enterprise & Certification

- CNCF Sandbox application
- Platform Engineering University partnership launch
- Enterprise support offerings
- Multi-region deployments
- Chaos engineering integration

### Q4 2026: Innovation

- AI-powered platform insights
- Predictive failure detection
- Automated performance optimization
- FinOps integration
- 1,000+ community members

**[View Detailed Roadmap →](ROADMAP.md)**

---

## 🤝 Contributing

Fawkes is open source and community-driven. We welcome contributions of all kinds:

### Ways to Contribute

**🐛 Report Bugs** - [Open an issue](https://github.com/paruff/fawkes/issues/new?template=bug_report.yml)

**✨ Request Features** - [Share your ideas](https://github.com/paruff/fawkes/issues/new?template=feature_request.yml)

**📝 Improve Documentation** - Help others learn and succeed

**💻 Submit Code** - Fix bugs, add features, optimize performance

**🎓 Create Dojo Content** - Develop new learning modules

**🎨 Design & UX** - Improve interfaces and user experience

**💬 Support Community** - Answer questions, help others

**🌍 Translate** - Help make Fawkes accessible globally

### Getting Started with Contributing

1. **Read** [Contributing Guide](docs/contributing.md) and [Code of Conduct](docs/CODE_OF_CONDUCT.md)
2. **Join** the [GitHub Discussions](https://github.com/paruff/fawkes/discussions)
3. **Browse** [good first issues](https://github.com/paruff/fawkes/labels/good%20first%20issue)
4. **Fork** the repository and create a branch
5. **Set up code quality tools** - Essential for all contributors:

   ```bash
   # Install pre-commit hooks (one-time setup)
   make pre-commit-setup

   # Run linters before committing
   make lint
   ```

6. **Make** your changes with tests and documentation
7. **Submit** a pull request
8. **Celebrate** your contribution! 🎉

### Code Quality Standards

All contributions must pass:

- ✅ **Automated linting** - Bash, Python, Go, YAML, JSON, Markdown, Terraform
- ✅ **Security scanning** - Secrets detection, SAST, container scanning
- ✅ **Pre-commit hooks** - Run automatically on `git commit`
- ✅ **CI/CD checks** - GitHub Actions validate on every PR

📖 **See**: [CODING_STANDARDS.md](CODING_STANDARDS.md) - Comprehensive coding standards guide with examples and FAQs

**Tests**: `make test-all` runs unit + BATS + BDD + integration suites (`tests/`, see [test strategy](docs/test-strategy.md)). Integration tests need a live cluster; unit tests run anywhere.

### Recognition

All contributors are recognized in:

- [Contributors graph](https://github.com/paruff/fawkes/graphs/contributors) (all-contributors automation planned)
- Monthly "Contributor of the Month" spotlight
- Annual "Top Contributors" feature
- Speaking opportunities at community events

---

## 📜 License

Fawkes is open source software licensed under the [MIT License](LICENSE).

This means you can:

- ✅ Use commercially
- ✅ Modify
- ✅ Distribute
- ✅ Sublicense
- ✅ Use privately

With the requirements to:

- Include the license and copyright notice
- State changes made to the code

**No Warranty** - Software is provided "as is" without warranty.

---

## 🙏 Acknowledgments

Fawkes is built on the shoulders of giants and inspired by:

- **[Accelerate](https://itrevolution.com/product/accelerate/)** by Nicole Forsgren, Jez Humble, Gene Kim - DORA research foundation
- **[Team Topologies](https://teamtopologies.com/)** by Matthew Skelton, Manuel Pais - Platform team patterns
- **[Backstage](https://backstage.io/)** by Spotify - Developer portal inspiration
- **[Platform Engineering](https://platformengineering.org/)** community - Best practices and patterns
- **CNCF Projects** - Kubernetes, Prometheus, ArgoCD, and hundreds of other tools

### Special Thanks

- All our [contributors](https://github.com/paruff/fawkes/graphs/contributors)
- [Platform Engineering University](https://platformengineering.university/) for certification partnership
- The open source community for feedback and support
- Early adopters who believed in the vision

---

## 📞 Support & Contact

### Community Support (Free)

- **GitHub Discussions** - Questions and discussions
- **GitHub Issues** - Bug reports and feature requests
- **Documentation** - Comprehensive guides and tutorials

### Professional Support

> **Roadmap item — not yet available.** Professional support (implementation assistance, training, SLA) is planned as a future offering. Follow [GitHub Discussions](https://github.com/paruff/fawkes/discussions) for announcements.

---

## 🚀 Start Your Journey

Choose your path:

### 🎓 Learn Platform Engineering

**[Enroll in Dojo White Belt →](https://github.com/paruff/uFawkesDojo)**

Start your journey from novice to platform architect. 8 hours to your first certification.

### 🏗️ Deploy Fawkes Platform

**[Follow Quick Start Guide →](docs/getting-started.md)**

Get your platform running in 30 minutes. Production-ready in hours, not months.

### 🤝 Join the Community

**[Join GitHub Discussions →](https://github.com/paruff/fawkes/discussions)**

Connect with platform engineers, ask questions, and share your experiences.

### 💻 Contribute to Fawkes

**[View Good First Issues →](https://github.com/paruff/fawkes/labels/good%20first%20issue)**

Make your first contribution and become part of the community.

---

<p align="center">
  <strong>Built with ❤️ by platform engineers, for platform engineers</strong>
</p>

<p align="center">
  <a href="#-the-fawkes-dojo">Dojo</a> •
  <a href="#-quick-start">Quick Start</a> •
  <a href="#-documentation">Docs</a> •
  <a href="#-community">Community</a> •
  <a href="#-contributing">Contributing</a> •
  <a href="https://github.com/paruff/fawkes/blob/main/LICENSE">License</a>
</p>

<p align="center">
  <sub>Fawkes: Named after Dumbledore's phoenix, symbolizing resilience and renewal</sub>
</p>

## 🛡 License

This project is licensed under the [MIT License](LICENSE).

## uFawkes Stack Ecosystem

Fawkes is the core platform. The uFawkes stacks are composable components that extend the platform:

| Stack           | Description                                          | Link                                            |
| --------------- | ---------------------------------------------------- | ----------------------------------------------- |
| **uFawkesObs**  | Observability — Prometheus, Grafana, AI dashboards   | [GitHub](https://github.com/paruff/ufawkesobs)  |
| **uFawkesPipe** | CI/CD — Tekton golden path, Woodpecker, DevSecOps    | [GitHub](https://github.com/paruff/ufawkespipe) |
| **uFawkesDORA** | DORA metrics — dashboards, VSM, delivery performance | [GitHub](https://github.com/paruff/ufawkesdora) |
| **uFawkesSec**  | Security — policy-as-code, supply chain, guardrails  | [GitHub](https://github.com/paruff/ufawkessec)  |
| **uFawkesDevX** | Developer experience — golden paths, IDP templates   | [GitHub](https://github.com/paruff/ufawkesdevx) |
| **uFawkesAI**   | AI agent templates — golden path scaffolding         | [GitHub](https://github.com/paruff/ufawkesai)   |

**Marketing Site**: [ufawkes.dev](https://ufawkes.dev)
**Product Suite Roadmap**: [ROADMAP.md](ROADMAP.md)
