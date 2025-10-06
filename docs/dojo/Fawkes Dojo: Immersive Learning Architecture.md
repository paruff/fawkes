# Fawkes Dojo: Immersive Learning Architecture

## Document Information

**Version**: 1.0  
**Last Updated**: October 7, 2025  
**Status**: Living Document  
**Audience**: Learning Architects, Contributors, Platform Engineers

---

## Table of Contents

1. [Vision & Philosophy](#vision--philosophy)
2. [Learning System Overview](#learning-system-overview)
3. [Belt Progression System](#belt-progression-system)
4. [Curriculum Architecture](#curriculum-architecture)
5. [Hands-On Lab Environment](#hands-on-lab-environment)
6. [Assessment & Certification](#assessment--certification)
7. [DORA Capabilities Mapping](#dora-capabilities-mapping)
8. [Platform Engineering University Integration](#platform-engineering-university-integration)
9. [Technology Stack](#technology-stack)
10. [Implementation Roadmap](#implementation-roadmap)

---

## Vision & Philosophy

### The Problem

Platform engineering skills are in high demand but difficult to acquire:
- **Theory vs. Practice Gap**: Reading about platform engineering ≠ doing platform engineering
- **No Safe Practice Environment**: Production is too risky, toy examples aren't realistic
- **Fragmented Learning**: Scattered blog posts, docs, and courses don't provide cohesive journey
- **No Feedback Loops**: Hard to know if you're improving or building bad habits
- **Lack of Recognition**: No clear progression system or credentials

### The Fawkes Dojo Solution

> **"Learn platform engineering by building and operating a real platform"**

The Fawkes Dojo is not a traditional course or documentation site. It's an **immersive learning environment** where:

1. ✅ **Learn by Doing**: Every concept practiced immediately in production-like environment
2. ✅ **Safe to Fail**: Isolated environments where mistakes are learning opportunities
3. ✅ **Immediate Feedback**: Automated validation, metrics, and mentor review
4. ✅ **Progressive Mastery**: Clear belt system showing skill progression
5. ✅ **Real Tools, Real Skills**: Same tools used in production environments
6. ✅ **Community Learning**: Learn with peers, share achievements, get help
7. ✅ **Recognized Credentials**: Earn badges/certificates valued by employers

### Learning Philosophy

#### 1. **Production-First Learning**
- Labs use the actual Fawkes platform, not simplified versions
- Same tools, same workflows, same challenges as production
- Mistakes have consequences (within safe boundaries)
- Build muscle memory for real-world scenarios

#### 2. **Immediate Application**
- Maximum 5 minutes of theory before hands-on practice
- Every concept demonstrated, then practiced
- Build, break, fix—the fastest path to mastery

#### 3. **Spaced Repetition & Reinforcement**
- Concepts introduced multiple times in increasing complexity
- Earlier skills reinforced in advanced modules
- Regular reviews and retrospectives

#### 4. **Deliberate Practice**
- Focused on specific skills with clear goals
- Challenging but achievable (flow state)
- Immediate feedback on performance
- Reflection on what worked and what didn't

#### 5. **Social Learning**
- Learn with cohorts (optional but encouraged)
- Share solutions and approaches
- Peer code review and feedback
- Celebrate achievements publicly

---

## Learning System Overview

### High-Level Architecture

```
┌────────────────────────────────────────────────────────────────┐
│                    Fawkes Dojo Learning System                  │
├────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐ │
│  │           Backstage Dojo Portal (Learning Hub)            │ │
│  │  • Curriculum Browser  • Progress Tracking  • Leaderboard│ │
│  │  • Lab Launcher  • Achievement Badges  • Community       │ │
│  └───────────┬──────────────────────────────────┬───────────┘ │
│              │                                   │             │
│  ┌───────────▼─────────────┐      ┌────────────▼──────────┐  │
│  │  Learning Content (TechDocs) │  │   Hands-On Labs        │  │
│  │  • Modules (video + text)    │  │   (Live Environment)   │  │
│  │  • Exercises                 │  │   • Personal namespace │  │
│  │  • Quizzes                   │  │   • Sample apps        │  │
│  │  • References                │  │   • CI/CD pipelines    │  │
│  └──────────────────────────────┘  │   • Monitoring         │  │
│                                     │   • Auto-validation    │  │
│                                     └────────────────────────┘  │
│              │                                   │             │
│  ┌───────────▼───────────────────────────────────▼──────────┐ │
│  │         Assessment & Certification Engine                │ │
│  │  • Automated Grading  • Manual Review  • Certificates   │ │
│  └─────────────────────────────────────────────────────────┘ │
│              │                                                 │
│  ┌───────────▼──────────────────────────────────────────────┐ │
│  │            Progress & Analytics (Focalboard)             │ │
│  │  • Individual progress  • Cohort analytics              │ │
│  │  • Skill gaps  • Time tracking  • Completion rates      │ │
│  └──────────────────────────────────────────────────────────┘ │
│              │                                                 │
│  ┌───────────▼──────────────────────────────────────────────┐ │
│  │           Community & Support (Mattermost)               │ │
│  │  • #dojo channels  • Peer help  • Mentor office hours   │ │
│  │  • Achievement announcements  • Study groups            │ │
│  └──────────────────────────────────────────────────────────┘ │
└────────────────────────────────────────────────────────────────┘
```

### Component Responsibilities

| Component | Purpose | Technology |
|-----------|---------|------------|
| **Dojo Portal** | Single entry point for all learning | Backstage plugin |
| **Content System** | Modules, videos, documentation | TechDocs (Markdown + MkDocs) |
| **Lab Environment** | Hands-on practice in isolated namespaces | Kubernetes namespaces + RBAC |
| **Validation System** | Auto-grade labs, provide feedback | Custom Go/Python service |
| **Progress Tracking** | Track learner progress, visualize journey | Focalboard + PostgreSQL |
| **Achievement System** | Badges, certificates, leaderboards | Backstage plugin + database |
| **Community Platform** | Discussion, support, collaboration | Mattermost |
| **Analytics Engine** | Learning effectiveness, content gaps | Grafana + custom metrics |

---

## Belt Progression System

### Belt Philosophy

Inspired by martial arts dojo systems, the belt progression provides:
- **Clear Milestones**: Tangible goals to work toward
- **Skill Validation**: Each belt certifies specific competencies
- **Public Recognition**: Displayable badges and credentials
- **Motivation**: Gamification without sacrificing rigor

### Belt Levels

#### 🥋 White Belt: Platform Fundamentals (8 hours)
**Target Audience**: New to platform engineering or Fawkes  
**Prerequisites**: Basic command line, Git, and Docker knowledge  
**Certification**: "Fawkes Platform Operator"

**Core Competencies**:
- Understand what an Internal Delivery Platform is and why it matters
- Explain DORA metrics and their business impact
- Navigate Backstage portal and service catalog
- Deploy an application using a golden path template
- View and interpret basic DORA metrics
- Use Mattermost for team collaboration
- Track work in Focalboard

**DORA Capabilities Covered**: 4 of 24
- Continuous Integration
- Continuous Delivery
- Monitoring and Observability
- Deployment Automation

**Assessment**: 
- Deploy 2 sample applications successfully
- Demonstrate understanding of DORA metrics (quiz)
- Complete 3 hands-on labs
- Pass 80% on written assessment

---

#### 🟡 Yellow Belt: CI/CD Mastery (8 hours)
**Target Audience**: Developers ready to own their CI/CD  
**Prerequisites**: White Belt certification  
**Certification**: "Fawkes CI/CD Specialist"

**Core Competencies**:
- Build custom Jenkins pipelines from scratch
- Implement security scanning (SAST, dependency check, container scanning)
- Configure quality gates and automated testing
- Optimize build times and resource usage
- Troubleshoot failed pipelines effectively
- Understand artifact management and versioning
- Implement pipeline-as-code best practices

**DORA Capabilities Covered**: 6 of 24 (additional)
- Test Automation
- Test Data Management
- Shift Left on Security
- Trunk-Based Development
- Version Control
- Code Review

**Assessment**:
- Build 3 production-ready pipelines (Java, Python, Node.js)
- Achieve <5 min build time for sample app
- Implement security scanning with zero critical vulnerabilities
- Score 85%+ on advanced CI/CD quiz

---

#### 🟢 Green Belt: GitOps & Deployment (8 hours)
**Target Audience**: Engineers managing deployments  
**Prerequisites**: Yellow Belt certification  
**Certification**: "Fawkes Deployment Engineer"

**Core Competencies**:
- Implement GitOps workflows with ArgoCD
- Configure blue-green and canary deployments
- Implement progressive delivery with automated rollback
- Manage multi-environment deployments (dev, staging, prod)
- Troubleshoot deployment failures and rollback safely
- Understand Kubernetes deployment strategies
- Implement deployment best practices

**DORA Capabilities Covered**: 7 of 24 (additional)
- Deployment Automation (advanced)
- Infrastructure as Code
- Empowering Teams
- Visual Management
- Work in Small Batches
- Team Experimentation
- Change Approval Process

**Assessment**:
- Implement GitOps for 3 environments
- Execute successful canary deployment with rollback
- Recover from simulated deployment failure <5 min
- Design deployment strategy for complex application
- Score 85%+ on GitOps assessment

---

#### 🟤 Brown Belt: Observability & SRE (8 hours)
**Target Audience**: Engineers responsible for reliability  
**Prerequisites**: Green Belt certification  
**Certification**: "Fawkes SRE Practitioner"

**Core Competencies**:
- Configure comprehensive observability (metrics, logs, traces)
- Design and implement custom DORA metrics dashboards
- Define and track SLIs, SLOs, and error budgets
- Implement distributed tracing for microservices
- Conduct effective incident response and postmortems
- Practice chaos engineering fundamentals
- Optimize platform and application performance

**DORA Capabilities Covered**: 5 of 24 (additional)
- Monitoring and Observability (advanced)
- Proactive Failure Notification
- Database Change Management
- WIP Limits
- Visualizing Work

**Assessment**:
- Configure full observability stack for application
- Create custom DORA metrics dashboard
- Define SLOs and implement alerts
- Respond to simulated incident (pass if MTTR <30 min)
- Conduct postmortem analysis
- Score 90%+ on SRE assessment

---

#### ⚫ Black Belt: Platform Architecture (8 hours)
**Target Audience**: Platform architects and tech leads  
**Prerequisites**: Brown Belt certification  
**Certification**: "Fawkes Platform Architect"

**Core Competencies**:
- Design platform architecture for new teams
- Implement multi-tenancy and resource governance
- Design security architecture (zero trust principles)
- Plan multi-cloud deployment strategies
- Evaluate and integrate new platform tools
- Mentor others in platform engineering
- Contribute to platform codebase

**DORA Capabilities Covered**: 2 of 24 (final)
- Loosely Coupled Architecture
- Generative Organizational Culture

**Assessment**:
- Design complete platform for fictional company
- Present architecture to panel (peer + mentor review)
- Implement multi-tenant namespace design
- Contribute meaningful code or documentation to Fawkes
- Mentor 2 learners through White Belt
- Score 90%+ on architecture assessment

---

### Belt Progression Visualization

```
White Belt (8h)          Platform Fundamentals
    ↓                   ✓ Deploy apps
    ↓                   ✓ Basic DORA metrics
    ↓
Yellow Belt (8h)         CI/CD Mastery  
    ↓                   ✓ Custom pipelines
    ↓                   ✓ Security scanning
    ↓
Green Belt (8h)          GitOps & Deployment
    ↓                   ✓ Blue-green/canary
    ↓                   ✓ Multi-environment
    ↓
Brown Belt (8h)          Observability & SRE
    ↓                   ✓ Full observability
    ↓                   ✓ Incident response
    ↓
Black Belt (8h)          Platform Architecture
                        ✓ Design platforms
                        ✓ Mentor others

Total Time: 40 hours (1 week full-time or 5 weeks part-time)
```

---

## Curriculum Architecture

### Module Structure

Each module follows consistent structure for predictability:

```
Module N: [Title]
├── 1. Learning Objectives (3 min)
│   ├── What you'll learn
│   ├── Why it matters
│   └── Success criteria
├── 2. Theory & Concepts (10-15 min)
│   ├── Video explanation (5-7 min)
│   ├── Written content with diagrams
│   ├── Real-world examples
│   └── Common pitfalls
├── 3. Demonstration (10 min)
│   ├── Instructor walkthrough video
│   ├── Step-by-step with narration
│   └── Explaining "why" at each step
├── 4. Hands-On Lab (15-20 min)
│   ├── Lab environment auto-provisioned
│   ├── Clear instructions
│   ├── Checkpoints with validation
│   ├── Troubleshooting hints
│   └── Auto-graded submission
├── 5. Knowledge Check (5 min)
│   ├── 5-10 quiz questions
│   ├── Immediate feedback
│   └── Links to relevant content for wrong answers
├── 6. Reflection & Next Steps (5 min)
│   ├── What you learned
│   ├── How it connects to real work
│   ├── Additional resources
│   └── Preview of next module

Total Time per Module: 45-60 minutes
```

### Complete Curriculum Map

#### White Belt (8 hours total)

**Module 1: Internal Delivery Platforms - What and Why** (60 min)
- What is an IDP and why organizations need them
- Platform as a Product mindset
- Team Topologies: enabling teams
- Fawkes platform tour
- **Lab**: Explore Backstage catalog, navigate documentation

**Module 2: DORA Metrics - The North Star** (60 min)
- Four Key Metrics explained in depth
- High performers vs. low performers data
- How DORA metrics drive business outcomes
- Fawkes DORA metrics automation
- **Lab**: View live DORA dashboard, understand metric calculations

**Module 3: GitOps Principles** (60 min)
- Declarative infrastructure and applications
- Git as source of truth
- Automated reconciliation
- Benefits and challenges
- **Lab**: Make a GitOps change, watch ArgoCD sync

**Module 4: Your First Deployment** (60 min)
- Golden path templates
- Step-by-step deployment process
- Monitoring deployment progress
- Viewing DORA metrics in real-time
- **Lab**: Deploy your first application end-to-end

**White Belt Assessment** (2 hours)
- Deploy 2 additional applications (different languages)
- Written exam (30 questions)
- Practical troubleshooting scenario

---

#### Yellow Belt (8 hours total)

**Module 5: Continuous Integration Fundamentals** (60 min)
- CI principles and benefits
- Jenkins architecture
- Pipeline-as-code (Jenkinsfile)
- Build stages and best practices
- **Lab**: Create basic Jenkinsfile, run first build

**Module 6: Building Golden Path Pipelines** (60 min)
- Shared libraries and reusable components
- Multi-stage pipelines (build, test, package)
- Caching and optimization
- Parallel execution
- **Lab**: Build optimized pipeline with <5 min runtime

**Module 7: Security Scanning & Quality Gates** (60 min)
- Static analysis (SonarQube)
- Dependency scanning
- Container image scanning (Trivy)
- Quality gates and policy enforcement
- **Lab**: Add comprehensive security scanning to pipeline

**Module 8: Artifact Management** (60 min)
- Container registry (Harbor)
- Versioning strategies (semantic versioning)
- Artifact promotion across environments
- Retention policies
- **Lab**: Implement artifact management workflow

**Yellow Belt Assessment** (2 hours)
- Build 3 production-ready pipelines
- Optimize build performance
- Implement security scanning with zero critical CVEs
- Written exam (40 questions)

---

#### Green Belt (8 hours total)

**Module 9: GitOps with ArgoCD** (60 min)
- ArgoCD architecture and concepts
- Application definitions
- Sync policies and health assessment
- Automated vs. manual sync
- **Lab**: Configure ArgoCD application, implement sync

**Module 10: Deployment Strategies** (60 min)
- Blue-green deployments
- Canary deployments
- Rolling updates
- Feature flags
- **Lab**: Implement blue-green deployment

**Module 11: Progressive Delivery** (60 min)
- Traffic splitting and analysis
- Automated rollback triggers
- Metrics-driven deployments
- A/B testing integration
- **Lab**: Configure canary deployment with automated rollback

**Module 12: Rollback & Incident Response** (60 min)
- When and how to rollback
- Incident detection and alerting
- Emergency procedures
- Postmortem process
- **Lab**: Simulate production incident, execute rollback

**Green Belt Assessment** (2 hours)
- Implement GitOps for 3 environments
- Execute canary deployment
- Respond to simulated incident
- Design deployment strategy document
- Written exam (40 questions)

---

#### Brown Belt (8 hours total)

**Module 13: Metrics, Logs, and Traces** (60 min)
- Three pillars of observability
- Prometheus metrics collection
- OpenSearch log aggregation
- Jaeger distributed tracing
- **Lab**: Configure full observability stack

**Module 14: DORA Metrics Deep Dive** (60 min)
- Advanced DORA metrics calculation
- Custom dashboard creation
- Team-level vs. organization-level metrics
- Using metrics for continuous improvement
- **Lab**: Build custom DORA dashboard for your team

**Module 15: SLIs, SLOs, and Error Budgets** (60 min)
- Defining Service Level Indicators
- Setting appropriate Service Level Objectives
- Calculating and tracking error budgets
- Using error budgets for decision-making
- **Lab**: Define SLOs and implement monitoring

**Module 16: Incident Management & Postmortems** (60 min)
- Incident severity levels
- On-call best practices
- Effective incident response
- Blameless postmortems
- **Lab**: Participate in simulated incident response

**Brown Belt Assessment** (2 hours)
- Configure comprehensive observability
- Create custom dashboards
- Define SLOs and alerts
- Respond to simulated incidents (MTTR measured)
- Written exam (45 questions)

---

#### Black Belt (8 hours total)

**Module 17: Platform as a Product** (60 min)
- Treating platform as product
- Understanding customer (developer) needs
- Platform roadmapping
- Measuring platform success
- **Lab**: Conduct developer interviews, create roadmap

**Module 18: Multi-Tenancy & Resource Management** (60 min)
- Namespace-based isolation
- Resource quotas and limits
- Network policies
- RBAC strategies
- **Lab**: Design and implement multi-tenant environment

**Module 19: Security & Zero Trust** (60 min)
- Zero trust principles
- Policy as code (Kyverno/OPA)
- Secrets management (External Secrets)
- Compliance automation
- **Lab**: Implement zero trust policies

**Module 20: Multi-Cloud Strategies** (60 min)
- Multi-cloud architecture patterns
- Crossplane for cloud abstraction
- Disaster recovery across clouds
- Cost optimization
- **Lab**: Design multi-cloud deployment strategy

**Black Belt Assessment** (4 hours)
- Design complete platform architecture
- Present to peer review panel
- Implement multi-tenant design
- Contribute to Fawkes codebase
- Mentor 2 White Belt learners
- Written exam (50 questions)

---

## Hands-On Lab Environment

### Lab Architecture

```
┌────────────────────────────────────────────────────────────┐
│              Fawkes Dojo Kubernetes Cluster                │
├────────────────────────────────────────────────────────────┤
│                                                            │
│  Dojo System Namespace (dojo-system)                      │
│  ├── dojo-portal (Backstage with dojo plugin)            │
│  ├── dojo-provisioner (creates learner namespaces)       │
│  ├── dojo-validator (auto-grades labs)                   │
│  └── dojo-dashboard (progress tracking)                  │
│                                                            │
│  ─────────────────────────────────────────────────────────│
│                                                            │
│  Learner Namespace (dojo-learner-{username})             │
│  ├── Resources:                                           │
│  │   ├── CPU: 2 cores                                    │
│  │   ├── Memory: 4Gi                                     │
│  │   ├── Storage: 10Gi                                   │
│  │   └── LoadBalancers: 2                                │
│  ├── Pre-deployed:                                        │
│  │   ├── sample-app (demo application)                  │
│  │   ├── jenkins-agent (personal CI agent)              │
│  │   └── lab-validator (checks lab completion)          │
│  ├── RBAC:                                                │
│  │   ├── Full control within namespace                   │
│  │   ├── Read-only to shared resources                   │
│  │   └── No cluster-wide permissions                     │
│  └── Network Policies:                                    │
│      ├── Can access dojo services                        │
│      ├── Can access internet                             │
│      └── Isolated from other learners                    │
│                                                            │
│  [Repeat for each learner...]                            │
│                                                            │
│  Shared Services Namespace (dojo-shared)                  │
│  ├── container-registry (Harbor)                          │
│  ├── git-server (Gitea for labs)                         │
│  ├── prometheus (metrics collection)                     │
│  └── grafana (dashboards)                                │
└────────────────────────────────────────────────────────────┘
```

### Lab Provisioning Process

1. **Learner Enrolls in Module**:
   ```
   User clicks "Start Lab" in Backstage
       ↓
   Dojo Provisioner API called
       ↓
   Creates namespace: dojo-learner-{username}
       ↓
   Applies resource quotas and RBAC
       ↓
   Deploys lab-specific resources
       ↓
   Returns access credentials and instructions
       ↓
   Lab environment ready in <2 minutes
   ```

2. **Lab Execution**:
   ```
   Learner follows lab instructions
       ↓
   Makes changes in their namespace
       ↓
   Lab Validator monitors progress
       ↓
   Checkpoints automatically verified
       ↓
   Feedback provided in real-time
       ↓
   Final submission auto-graded
   ```

3. **Lab Cleanup**:
   ```
   Lab completed or 24-hour timeout
       ↓
   Namespace marked for deletion
       ↓
   Grace period: 1 hour (allow review)
       ↓
   Namespace and resources deleted
       ↓
   Results stored in database
   ```

### Lab Validation System

**Automated Validation Types**:
- **Resource Existence**: Deployment, Service, Ingress created
- **Configuration Correctness**: Labels, annotations, replicas match spec
- **Health Status**: Pods running, services responding
- **Security Compliance**: No privileged containers, security contexts set
- **Performance**: Response time, resource usage within limits
- **DORA Metrics**: Deployment recorded, metrics updated

**Example Validation (Lab: Deploy First App)**:
```yaml
validations:
  - name: "Deployment exists"
    type: "resource-exists"
    resource: "deployment/sample-app"
    points: 10
    
  - name: "Service responds"
    type: "http-check"
    url: "http://sample-app.{namespace}.svc.cluster.local"
    expected_status: 200
    points: 15
    
  - name: "DORA metric recorded"
    type: "metric-check"
    metric: "deployments_total{app='sample-app'}"
    expected: "> 0"
    points: 10
    
  - name: "Deployment successful"
    type: "status-check"
    resource: "deployment/sample-app"
    condition: "Available"
    points: 15
    
total_points: 50
passing_score: 40
```

---

## Assessment & Certification

### Assessment Types

**1. Continuous Assessment** (throughout module)
- Knowledge check quizzes (5-10 questions per module)
- Hands-on lab auto-grading
- Code quality checks
- Performance benchmarks

**2. Belt Certification Assessment**
- Practical exam (hands-on challenges)
- Written exam (comprehensive knowledge check)
- Project work (Black Belt only)
- Peer/mentor review (Black Belt only)

### Certification Requirements

| Belt Level | Practical Exam | Written Exam | Additional Requirements |
|-----------|----------------|--------------|-------------------------|
| White | 2 deployments | 30 questions, 80% pass | Complete 3 labs |
| Yellow | 3 pipelines | 40 questions, 85% pass | Build time <5 min |
| Green | GitOps + canary | 40 questions, 85% pass | MTTR <5 min on simulation |
| Brown | Full observability | 45 questions, 85% pass | MTTR <30 min on incident |
| Black | Platform design | 50 questions, 90% pass | Code contribution + mentoring |

### Digital Badges & Credentials

**Earned Upon Certification**:
- Digital badge (PNG with verification link)
- Verifiable certificate (PDF with unique ID)
- LinkedIn/Credly integration
- Listed on Fawkes contributor page
- Special role in Mattermost

**Badge Design**:
```
┌─────────────────────┐
│   🥋 White Belt    │
│  Fawkes Platform    │
│      Operator       │
│                     │
│   [Your Name]       │
│   Oct 2025          │
│                     │
│  Verify: fawks.io/  │
│  cert/ABC123        │
└─────────────────────┘
```

---

## DORA Capabilities Mapping

All 24 DORA capabilities covered across belt progression:

### Continuous Delivery Capabilities (8)
1. ✅ **Version Control** - Yellow Belt, Module 6
2. ✅ **Deployment Automation** - White Belt (basic), Green Belt (advanced)
3. ✅ **Continuous Integration** - Yellow Belt, Module 5-6
4. ✅ **Trunk-Based Development** - Yellow Belt, Module 6
5. ✅ **Test Automation** - Yellow Belt, Module 6-7
6. ✅ **Test Data Management** - Yellow Belt, Module 7
7. ✅ **Shift Left on Security** - Yellow Belt, Module 7
8. ✅ **Continuous Delivery** - Green Belt, Module 9-11

### Architecture Capabilities (3)
9. ✅ **Loosely Coupled Architecture** - Black Belt, Module 17-20
10. ✅ **Empowering Teams** - Green Belt, Module 9
11. ✅ **Database Change Management** - Brown Belt, Module 14

### Product & Process Capabilities (6)
12. ✅ **Team Experimentation** - Green Belt, Module 11
13. ✅ **Work in Small Batches** - Green Belt, Module 10
14. ✅ **Visual Management** - Green Belt, Module 9
15. ✅ **WIP Limits** - Brown Belt, Module 15
16. ✅ **Visualizing Work** - Brown Belt (Focalboard usage)
17. ✅ **Change Approval Process** - Green Belt, Module 12

### Lean Management & Monitoring (4)
18. ✅ **Monitoring and Observability** - White Belt (basic), Brown Belt (advanced)
19. ✅ **Proactive Failure Notification** - Brown Belt, Module 16
20. ✅ **Lightweight Change Approval** - Green Belt, Module 12
21. ✅ **Code Review** - Yellow Belt, Module 6

### Cultural Capabilities (3)
22. ✅ **Generative Organizational Culture** - Black Belt, Module 17
23. ✅ **Learning Culture** - Entire Dojo system embodies this
24. ✅ **Job Satisfaction** - Measured via NPS in dojo feedback

---

## Platform Engineering University Integration

### Certification Alignment

**Observability in Platform Engineering** → Brown Belt
- Dojo modules 13-16 directly align with course content
- Hands-on labs use same tools taught in course
- Certificate holders get credit toward Brown Belt (skip modules 13-14)

**Cloud Development Environments in Platform Engineering** → Yellow Belt
- Modules 5-8 cover CDE concepts
- Eclipse Che integration (roadmap) provides CDE experience
- Certificate holders get credit toward Yellow Belt (skip module 5)

### Co-Branded Learning Paths

1. **"PEU Observability → Fawkes Brown Belt" Path**:
   - Complete PEU Observability course
   - Get 50% credit toward Fawkes Brown Belt
   - Complete modules 15-16 only
   - Take Brown Belt assessment

2. **"Fawkes Dojo → PEU Certification" Path**:
   - Complete Fawkes White + Yellow Belts
   - Get prep materials for PEU courses
   - 20% discount on PEU courses (partnership benefit)

### Joint Content Development

- Fawkes provides real platform for PEU hands-on labs
- PEU contributes curriculum review and expertise
- Co-create advanced modules (Black Belt)
- Joint webinars and workshops

---

## Technology Stack

### Learning Management
- **Backstage Plugin**: `@fawkes/plugin-dojo` (custom)
- **Content Storage**: GitHub repository (`fawkes-dojo-content`)
- **Content Rendering**: TechDocs (MkDocs Material theme)
- **Video Hosting**: YouTube (public) + self-hosted (optional)

### Lab Environment
- **Orchestration**: Kubernetes 1.28+
- **Provisioning**: Custom Go service (`dojo-provisioner`)
- **Validation**: Custom Python service (`dojo-validator`)
- **Isolation**: Kubernetes namespaces + Network Policies

### Progress Tracking
- **Dashboard**: Focalboard boards
- **Database**: PostgreSQL (learner progress, scores)
- **Analytics**: Grafana dashboards
- **Metrics**: Prometheus (completion rates, time spent)

### Communication
- **Community**: Mattermost `#dojo-*` channels
- **Notifications**: Mattermost webhooks
- **Support**: Office hours (video + Mattermost)

### Assessment
- **Quizzes**: Custom React components in Backstage
- **Auto-Grading**: `dojo-validator` service
- **Manual Review**: Maintainer dashboard (Black Belt)
- **Certificates**: PDF generation service (PDFKit)

---

## Implementation Roadmap

### Phase 1: MVP (Weeks 1-4)
- ✅ Dojo architecture documented
- [ ] Backstage dojo plugin (basic)
- [ ] White Belt curriculum (4 modules)
- [ ] Lab environment provisioning
- [ ] Basic auto-validation
- [ ] Progress tracking (simple)

**Deliverable**: White Belt available for early adopters

### Phase 2: Expansion (Weeks 5-8)
- [ ] Yellow Belt curriculum (4 modules)
- [ ] Green Belt curriculum (4 modules)
- [ ] Enhanced lab validation
- [ ] Focalboard integration
- [ ] Achievement badges
- [ ] Community features (leaderboards)

**Deliverable**: White + Yellow + Green Belts complete

### Phase 3: Advanced (Weeks 9-12)
- [ ] Brown Belt curriculum (4 modules)
- [ ] Black Belt curriculum (4 modules)
- [ ] Certification system
- [ ] Mentor matching
- [ ] Analytics dashboard
- [ ] PEU integration

**Deliverable**: Complete belt system operational

### Phase 4: Scale (Months 4-6)
- [ ] Cohort-based learning
- [ ] Live workshops and events
- [ ] Additional language support
- [ ] Advanced assessment features
- [ ] Learning path recommendations
- [ ] Alumni network

**Deliverable**: Scalable learning platform for 100+ concurrent learners

---

## Success Metrics

### Learning Effectiveness
- **Completion Rate**: % of learners who finish started belt (Target: >70%)
- **Time to Belt**: Average time to complete each belt (Track against estimates)
- **Assessment Pass Rate**: First-attempt pass rate (Target: 60-70%)
- **Knowledge Retention**: Re-test after 30/90 days (Target: >80% retention)

### Platform Adoption
- **Active Learners**: Monthly active users in dojo (Target: 100 by month 6)
- **Belt Certifications**: Total certifications issued (Target: 50 White, 20 Yellow, 10 Green, 5 Brown, 2 Black by month 6)
- **Learner NPS**: Net Promoter Score (Target: >50)
- **Completion Time**: 95% of learners complete labs within estimated time

### Business Impact
- **Skill Development**: Demonstrated DORA metric improvement for learners' teams (Target: 25% improvement)
- **Platform Adoption**: % of dojo graduates who deploy Fawkes (Target: 60%)
- **Community Growth**: Dojo-driven contributor pipeline (Target: 30% of contributors start as learners)
- **Employer Recognition**: Companies recognizing Fawkes certification (Target: 20+ by end of year 1)

---

## Conclusion

The Fawkes Dojo is not just a training program—it's a **learning platform** that transforms how platform engineering skills are acquired and recognized. By combining:

✅ **Immersive hands-on learning** in production-like environments  
✅ **Clear progression system** with recognized credentials  
✅ **DORA-driven curriculum** aligned with industry best practices  
✅ **Community learning** with peers and mentors  
✅ **Integration with work** using the same platform for learning and production  

We create a unique differentiator that positions Fawkes not just as infrastructure, but as a **complete platform engineering education ecosystem**.

**Next Steps**: Begin Module 1 content creation and lab environment setup.

---

**Document Maintainers**: Learning Architecture Team  
**Review Cadence**: Monthly or when curriculum updates needed  
**Last Review**: October 7, 2025