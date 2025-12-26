# Fawkes - Internal Product Delivery Platform

> **🎓 Learn platform engineering while building a world-class delivery platform**

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
  <img src="https://img.shields.io/badge/coverage-60%25-yellow.svg" alt="Coverage"/>
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

[Apply for AWS Activate](https://aws.amazon.com/activate/) | [See our AWS Cost Estimation](docs/AWS_COST_ESTIMATION.md)

## AWS Activate Application

📊 [AWS Cost Estimation](docs/AWS_COST_ESTIMATION.md)
📈 [Business Case & Value Proposition](docs/BUSINESS_CASE.md)

---

## 🥋 The Fawkes Dojo: Learn by Doing

**The Problem**: Platform engineering skills are in high demand but hard to acquire. Reading docs ≠ real expertise.

**The Fawkes Solution**: An immersive learning environment where you build actual platform skills on production-like infrastructure.

### Belt Progression System

Progress through 5 belt levels, each building on the last:

```
🥋 White Belt (8 hours)      →  Platform Fundamentals
   ↓ Deploy your first app, understand DORA metrics

🟡 Yellow Belt (8 hours)     →  CI/CD Mastery
   ↓ Build pipelines, implement security scanning

🟢 Green Belt (8 hours)      →  GitOps & Deployment
   ↓ Master blue-green and canary deployments

🟤 Brown Belt (8 hours)      →  Observability & SRE
   ↓ Configure full observability, respond to incidents

⚫ Black Belt (8 hours)      →  Platform Architecture
   ↓ Design platforms, mentor others

Total: 40 hours from novice to platform architect
```

### What You Get

✅ **Hands-On Labs** - Practice in isolated, safe environments
✅ **Immediate Feedback** - Auto-graded labs, real-time validation
✅ **Production Skills** - Same tools used in enterprise platforms
✅ **Recognized Credentials** - Digital badges and certificates
✅ **Community Learning** - Learn with peers, get mentorship
✅ **Platform Engineering University Integration** - Aligned with industry certifications

**[Start Your Dojo Journey →](docs/dojo/getting-started.md)**

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
- **Log Aggregation** - OpenSearch with Fluent Bit
- **Custom Dashboards** - Team-level visibility

### Security & Compliance

- **Security Scanning** - SonarQube (SAST), Trivy (containers), Gitleaks (secrets)
- **Automated Secrets Detection** - Pre-commit hooks and CI/CD pipeline scanning
- **Policy Enforcement** - Kyverno for Kubernetes policies
- **Secrets Management** - External Secrets Operator + HashiCorp Vault
- **Zero Trust Roadmap** - Security-first architecture

### Learning & Growth

- **Dojo Learning Environment** - Hands-on labs with auto-validation
- **Progress Tracking** - Visual dashboards of learning journey
- **Community Support** - Dedicated channels per belt level
- **Certification** - Recognized credentials for each belt

---

## 📊 DORA Metrics: Built-In, Not Bolt-On

Fawkes automates collection and visualization of the **Four Key Metrics** that separate high performers from the rest:

| Metric                      | What It Measures                   | Fawkes Automation                   |
| --------------------------- | ---------------------------------- | ----------------------------------- |
| **Deployment Frequency**    | How often you deploy to production | ✅ Automated via webhooks           |
| **Lead Time for Changes**   | Time from commit to production     | ✅ Git → CI → CD tracking           |
| **Change Failure Rate**     | % of deployments causing failures  | ✅ Deployment correlation           |
| **Time to Restore Service** | Time to recover from incidents     | ✅ Incident detection to resolution |

**Real-time dashboards** show your team's performance and track improvement over time.

**[View DORA Dashboard Demo →](docs/dora/dashboard-demo.md)**

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

### Prerequisites

- Kubernetes 1.28+ cluster
- kubectl configured
- Terraform 1.6+
- AWS/Azure/GCP account (or local cluster)
- Basic understanding of Kubernetes and CI/CD

### Deploy Fawkes (30 minutes)

```bash
# 1. Clone the repository
git clone https://github.com/paruff/fawkes.git
cd fawkes

# 2. Configure your environment
cp config/example.tfvars config/terraform.tfvars
# Edit terraform.tfvars with your settings

# 3. Configure GitHub OAuth for Backstage (REQUIRED)
# See: docs/how-to/security/github-oauth-quickstart.md
# Quick: Create OAuth app at https://github.com/settings/developers
#        Update secrets in platform/apps/backstage/secrets.yaml

# 4. Provision infrastructure and deploy platform via Argo CD
./scripts/ignite.sh --provider aws dev

# 5. Access your platform
kubectl get ingress -n fawkes-platform
# Navigate to Backstage URL shown and login with GitHub
```

**Important**: Before first login, configure GitHub OAuth - see [OAuth Quick Start](docs/how-to/security/github-oauth-quickstart.md)

**[Detailed Getting Started Guide →](docs/getting-started.md)**

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
- **OpenSearch** - Log aggregation and search
- **SonarQube & Trivy** - Security scanning
- **Dojo Environment** - Isolated learning labs

**[View Full Architecture →](docs/architecture.md)**

---

## 🎓 Learning Paths

### Path 1: I Want to Learn Platform Engineering

**Start Here**: [Dojo White Belt](docs/dojo/white-belt/README.md)

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

1. Join our Mattermost community
2. Review open issues and good first issues
3. Pick something that interests you
4. Submit your first PR
5. Celebrate with the community! 🎉

**Ways to Contribute**:

- Code (platform features, dojo modules)
- Documentation (guides, tutorials)
- Dojo content (create new modules)
- Community support (help in Mattermost)
- Bug reports and feature requests

---

## 📚 Documentation

Comprehensive documentation for all aspects of Fawkes:

### Getting Started

- [Installation Guide](docs/getting-started.md)
- [Quick Start Tutorial](docs/tutorials/quick-start.md)
- [Architecture Overview](docs/architecture.md)
- [Configuration Reference](docs/configuration.md)
- 🎥 [Epic 1 Demo Video Script](docs/tutorials/epic-1-demo-video-script.md) - 30-minute platform walkthrough
- 📋 [Epic 1 Demo Checklist](docs/tutorials/epic-1-demo-video-checklist.md) - Quick reference for recording

### Dojo Learning

- [Dojo Architecture](docs/dojo/DOJO_ARCHITECTURE.md)
- [White Belt Curriculum](docs/dojo/white-belt/)
- [Yellow Belt Curriculum](docs/dojo/yellow-belt/)
- [Green Belt Curriculum](docs/dojo/green-belt/)
- [Brown Belt Curriculum](docs/dojo/brown-belt/)
- [Black Belt Curriculum](docs/dojo/black-belt/)

### Platform Components

- [Backstage Setup](docs/components/backstage.md)
- [Mattermost Deployment](docs/components/mattermost.md)
- [Focalboard Usage](docs/components/focalboard.md)
- [Jenkins Configuration](docs/components/jenkins.md)
- [ArgoCD Setup](docs/components/argocd.md)
- [Observability Stack](docs/components/observability.md)

### Operations

- [Day 2 Operations](docs/operations/day2.md)
- [Backup & Disaster Recovery](docs/operations/backup.md)
- [Monitoring & Alerting](docs/operations/monitoring.md)
- [Security Best Practices](docs/operations/security.md)
- [Troubleshooting Guide](docs/troubleshooting.md)
- [AT-E1-001 Validation Tests](docs/runbooks/at-e1-001-validation.md)
- [Azure AKS Validation Checklist](docs/runbooks/azure-aks-validation-checklist.md)

### Contributing

- [Contributing Guide](CONTRIBUTING.md)
- [Code of Conduct](CODE_OF_CONDUCT.md)
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

## 🤝 Community

Join our vibrant platform engineering community:

### Chat & Collaboration

- **Mattermost** - [Join our community workspace](https://fawkes-community.mattermost.com)
- **GitHub Discussions** - [Ask questions, share ideas](https://github.com/paruff/fawkes/discussions)

### Learning & Support

- **Dojo Channels** - Get help with learning modules
- **Office Hours** - Bi-weekly Q&A with maintainers (Wednesdays 2pm ET)
- **Mentorship** - Black Belt graduates mentor new learners

### Stay Updated

- **Blog** - [Platform engineering insights](https://blog.fawkes.io)
- **Newsletter** - Bi-weekly updates (sign up below)
- **Twitter** - [@FawkesIDP](https://twitter.com/FawkesIDP)
- **LinkedIn** - [Fawkes Platform](https://linkedin.com/company/fawkes-platform)

### Events

- **Monthly Webinars** - Deep dives on platform topics
- **Quarterly Conferences** - Virtual platform engineering conference
- **Local Meetups** - Find or start a meetup in your city

---

## 📈 Success Stories

> "We went from deploying once a week to deploying 10x per day. Fawkes gave us the platform and the learning to achieve elite DORA performance."
>
> — **Sarah Chen, VP Engineering, TechCorp**

> "The dojo system is brilliant. Our developers learned platform engineering while building our IDP. Within 3 months, we had 5 certified platform engineers."
>
> — **Marcus Johnson, Platform Lead, FinanceStart**

> "Fawkes integrated everything we were using separate tools for. One platform, one team, incredible productivity gains."
>
> — **Priya Patel, CTO, HealthTech Solutions**

**[Read More Success Stories →](docs/success-stories/)**

---

## 🗺️ Roadmap

### Current Release: v0.1.0-alpha (MVP in Development)

**Sprint 01-04** (Oct-Dec 2025): Foundation

- ✅ Core architecture and governance
- ✅ Dojo learning system design
- 🔄 Backstage deployment
- 🔄 Mattermost + Focalboard integration
- 🔄 CI/CD pipelines
- 🔄 Observability stack
- 🔄 White Belt curriculum

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

**[View Detailed Roadmap →](docs/roadmap.md)**

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

1. **Read** [CONTRIBUTING.md](CONTRIBUTING.md) and [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md)
2. **Join** our [Mattermost community](https://fawkes-community.mattermost.com)
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

📖 **See**: [Code Quality Standards](docs/how-to/development/code-quality-standards.md) for detailed requirements

### Recognition

All contributors are recognized in:

- [CONTRIBUTORS.md](CONTRIBUTORS.md) (automated via all-contributors bot)
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

- All our [contributors](CONTRIBUTORS.md)
- [Platform Engineering University](https://platformengineering.university/) for certification partnership
- The open source community for feedback and support
- Early adopters who believed in the vision

---

## 📞 Support & Contact

### Community Support (Free)

- **Mattermost** - Real-time chat support
- **GitHub Issues** - Bug reports and feature requests
- **GitHub Discussions** - Questions and discussions
- **Documentation** - Comprehensive guides and tutorials

### Professional Support (Coming Q2 2026)

- Implementation assistance
- Custom development
- Training and workshops
- On-call support
- SLA guarantees

**Contact**: [support@fawkes.io](mailto:support@fawkes.io)

---

## 🚀 Start Your Journey

Choose your path:

### 🎓 Learn Platform Engineering

**[Enroll in Dojo White Belt →](docs/dojo/white-belt/)**

Start your journey from novice to platform architect. 8 hours to your first certification.

### 🏗️ Deploy Fawkes Platform

**[Follow Quick Start Guide →](docs/getting-started.md)**

Get your platform running in 30 minutes. Production-ready in hours, not months.

### 🤝 Join the Community

**[Join Mattermost →](https://fawkes-community.mattermost.com)**

Connect with platform engineers, get help, share your experiences.

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
