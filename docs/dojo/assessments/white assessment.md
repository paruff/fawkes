# White Belt Assessment: Fawkes Platform Operator

**Certification**: Fawkes Platform Operator
**Duration**: 2 hours
**Passing Score**: 80% (24/30 questions)
**Format**: 30 multiple choice questions + 3 hands-on labs

---

## 📋 Assessment Overview

This assessment validates your understanding of:

- Internal developer platform fundamentals
- DORA metrics and their significance
- GitOps principles and workflows
- Basic deployment operations

**Requirements**:

- Completed Modules 1-4
- Access to Fawkes lab environment
- Basic command line proficiency

---

## Part 1: Written Exam (30 Questions)

### Section A: Platform Fundamentals (10 questions)

**Question 1**: What is the primary purpose of an Internal Developer Platform (IDP)?

A) Replace developers with automation
B) Reduce cognitive load and provide self-service capabilities
C) Control what developers can deploy
D) Monitor production systems

<details>
<summary>Answer</summary>
**B** - IDPs reduce cognitive load by abstracting infrastructure complexity and enabling developer self-service.
</details>

---

**Question 2**: Which of the following is NOT a benefit of platform engineering?

A) Faster deployment frequency
B) Reduced mean time to recovery (MTTR)
C) Elimination of all incidents
D) Improved developer productivity

<details>
<summary>Answer</summary>
**C** - Platforms reduce incidents but cannot eliminate them entirely. The goal is faster detection and recovery.
</details>

---

**Question 3**: What is "cognitive load" in the context of platform engineering?

A) The amount of RAM required by applications
B) The mental effort required to understand and use systems
C) The number of microservices in production
D) The complexity of infrastructure code

<details>
<summary>Answer</summary>
**B** - Cognitive load is the mental effort developers must expend to work with infrastructure and tools.
</details>

---

**Question 4**: Which principle describes treating infrastructure configuration as code in version control?

A) DevOps
B) GitOps
C) Infrastructure as a Service (IaaS)
D) Continuous Integration

<details>
<summary>Answer</summary>
**B** - GitOps uses Git as the single source of truth for declarative infrastructure and applications.
</details>

---

**Question 5**: What is a "golden path" in platform engineering?

A) The fastest deployment route
B) The opinionated, easiest way to accomplish common tasks
C) The path taken by production traffic
D) The career progression for platform engineers

<details>
<summary>Answer</summary>
**B** - Golden paths are well-supported, opinionated workflows that make the "right way" the "easy way."
</details>

---

**Question 6**: What does "platform as a product" mean?

A) Selling the platform to external customers
B) Treating internal developers as customers with user research and satisfaction metrics
C) Building platforms with product management tools
D) Creating commercial software products

<details>
<summary>Answer</summary>
**B** - Platform teams should treat internal developers as customers, gathering feedback and measuring satisfaction.
</details>

---

**Question 7**: Which layer of the platform engineering stack includes Kubernetes?

A) Developer experience layer
B) Infrastructure layer
C) Application layer
D) Observability layer

<details>
<summary>Answer</summary>
**B** - Kubernetes is part of the infrastructure/orchestration layer that platforms abstract for developers.
</details>

---

**Question 8**: What is "self-service" in the context of IDPs?

A) Developers fix their own production incidents
B) Developers can provision resources without tickets or manual intervention
C) Automated deployment without human approval
D) Documentation that developers read themselves

<details>
<summary>Answer</summary>
**B** - Self-service enables developers to provision infrastructure, deploy applications, and access resources independently.
</details>

---

**Question 9**: Which team topology is most common for platform teams?

A) Stream-aligned team
B) Complicated subsystem team
C) Platform team
D) Enabling team

<details>
<summary>Answer</summary>
**C** - Platform teams provide internal services (the platform) that reduce cognitive load for stream-aligned teams.
</details>

---

**Question 10**: What is the relationship between platform engineering and DevOps?

A) They are competing approaches
B) Platform engineering replaces DevOps
C) Platform engineering is an evolution/implementation of DevOps principles
D) They are unrelated concepts

<details>
<summary>Answer</summary>
**C** - Platform engineering implements DevOps principles by providing self-service tools and automation.
</details>

---

### Section B: DORA Metrics (10 questions)

**Question 11**: What are the four key DORA metrics?

A) Uptime, latency, cost, scalability
B) Deployment frequency, lead time, MTTR, change failure rate
C) Code coverage, bug count, technical debt, velocity
D) Commits, pull requests, releases, rollbacks

<details>
<summary>Answer</summary>
**B** - The four DORA metrics are: deployment frequency, lead time for changes, time to restore service (MTTR), and change failure rate.
</details>

---

**Question 12**: What is considered "elite" performance for deployment frequency?

A) Once per week
B) Once per day
C) Multiple times per day (on-demand)
D) Once per month

<details>
<summary>Answer</summary>
**C** - Elite performers deploy multiple times per day, enabling fast feedback and reduced risk per deployment.
</details>

---

**Question 13**: What does "lead time for changes" measure?

A) How long a feature takes to develop
B) Time from commit to successfully running in production
C) Time to review pull requests
D) How long builds take in CI

<details>
<summary>Answer</summary>
**B** - Lead time measures the time from code commit to running successfully in production.
</details>

---

**Question 14**: What is MTTR in the context of DORA metrics?

A) Mean Time To Release
B) Maximum Time To Respond
C) Mean Time To Restore/Recover
D) Minimum Test Requirements

<details>
<summary>Answer</summary>
**C** - MTTR is Mean Time To Restore service when an incident occurs.
</details>

---

**Question 15**: What is considered "elite" performance for change failure rate?

A) 0% (no failures)
B) 0-15%
C) 15-30%
D) 30-45%

<details>
<summary>Answer</summary>
**B** - Elite performers have a change failure rate of 0-15%.
</details>

---

**Question 16**: Which DORA metric measures the percentage of deployments causing production issues?

A) Deployment frequency
B) Lead time
C) MTTR
D) Change failure rate

<details>
<summary>Answer</summary>
**D** - Change failure rate measures the percentage of changes that result in degraded service or require remediation.
</details>

---

**Question 17**: How do DORA metrics relate to business outcomes?

A) They don't - they're just technical metrics
B) High performers ship features faster and more reliably, improving competitiveness
C) Only deployment frequency matters for business
D) They only matter for engineering teams

<details>
<summary>Answer</summary>
**B** - Research shows high DORA performers are 2x more likely to meet/exceed business goals.
</details>

---

**Question 18**: What is the relationship between deployment frequency and stability?

A) More frequent deployments reduce stability
B) They are unrelated
C) High performers achieve both high frequency AND high stability
D) You must choose between frequency or stability

<details>
<summary>Answer</summary>
**C** - Elite performers deploy more frequently AND have lower change failure rates - you don't trade one for the other.
</details>

---

**Question 19**: Which DORA capability focuses on automated testing?

A) Version control
B) Test automation
C) Deployment automation
D) Trunk-based development

<details>
<summary>Answer</summary>
**B** - Test automation is a key technical capability enabling fast, reliable deployments.
</details>

---

**Question 20**: Why is "small batch size" important for DORA metrics?

A) Smaller changes are easier to review, deploy, and rollback
B) It reduces storage costs
C) Developers prefer small tasks
D) It simplifies project management

<details>
<summary>Answer</summary>
**A** - Small batches reduce risk, enable faster feedback, and make failures easier to diagnose and fix.
</details>

---

### Section C: GitOps & Deployment (10 questions)

**Question 21**: What is the core principle of GitOps?

A) All developers must use Git
B) Git is the single source of truth for declarative infrastructure and applications
C) Operations team manages Git repositories
D) Deployments only happen via Git hooks

<details>
<summary>Answer</summary>
**B** - GitOps uses Git as the single source of truth, with automated processes ensuring the cluster matches Git state.
</details>

---

**Question 22**: Which tool is most commonly used for GitOps in Kubernetes?

A) Jenkins
B) GitLab CI
C) ArgoCD or Flux
D) GitHub Actions

<details>
<summary>Answer</summary>
**C** - ArgoCD and Flux are purpose-built GitOps operators for Kubernetes.
</details>

---

**Question 23**: What is "declarative configuration"?

A) Declaring what you want, not how to achieve it
B) Writing detailed step-by-step scripts
C) Using command-line tools instead of GUIs
D) Documenting infrastructure changes

<details>
<summary>Answer</summary>
**A** - Declarative configuration describes the desired end state, letting the system figure out how to achieve it.
</details>

---

**Question 24**: In GitOps, when should you make changes to production?

A) By SSH-ing into servers
B) Through the Kubernetes dashboard
C) By committing to Git and letting automation apply changes
D) Via kubectl apply commands

<details>
<summary>Answer</summary>
**C** - GitOps changes are made via Git commits, then automatically applied to clusters.
</details>

---

**Question 25**: What is "drift detection" in GitOps?

A) Monitoring server clock skew
B) Detecting when cluster state differs from Git
C) Tracking developer productivity changes
D) Measuring network latency

<details>
<summary>Answer</summary>
**B** - Drift detection identifies when the actual cluster state differs from the desired state in Git.
</details>

---

**Question 26**: What is a "manifest" in Kubernetes?

A) A shipping document
B) A YAML/JSON file describing desired resources
C) A deployment log
D) A configuration backup

<details>
<summary>Answer</summary>
**B** - Manifests are declarative YAML or JSON files describing Kubernetes resources.
</details>

---

**Question 27**: What happens when you push a commit to the GitOps repository?

A) Developers are notified
B) GitOps operator detects change and applies it to cluster
C) Manual approval is required
D) Nothing until you run a command

<details>
<summary>Answer</summary>
**B** - GitOps operators continuously monitor Git and automatically sync changes to clusters.
</details>

---

**Question 28**: What is "reconciliation" in GitOps?

A) Merging Git branches
B) The process of making cluster state match Git state
C) Resolving deployment conflicts
D) Approving pull requests

<details>
<summary>Answer</summary>
**B** - Reconciliation is the automated process of ensuring cluster state matches the desired state in Git.
</details>

---

**Question 29**: Which is a benefit of GitOps?

A) Faster SSH access
B) Audit trail via Git history
C) Reduced need for version control
D) Elimination of all manual processes

<details>
<summary>Answer</summary>
**B** - Every change is recorded in Git, providing a complete audit trail and easy rollback.
</details>

---

**Question 30**: What is the difference between push-based and pull-based deployment?

A) Push sends notifications, pull requests data
B) Push: CI pushes to cluster. Pull: Operator pulls from Git
C) They are the same thing
D) Push is for production, pull is for staging

<details>
<summary>Answer</summary>
**B** - Push-based: CI system pushes changes to cluster. Pull-based (GitOps): Operator running in cluster pulls from Git.
</details>

---

## Part 2: Hands-On Labs (70 minutes)

### Lab 1: Deploy Your First Application (20 minutes)

**Objective**: Deploy a web application to Kubernetes using GitOps workflow.

**Tasks**:

1. Fork the sample application repository
2. Modify the deployment manifest (change replica count to 3)
3. Commit and push changes to Git
4. Verify ArgoCD detects and applies changes
5. Access the application via its service URL

**Acceptance Criteria**:

- ✅ Application running with 3 replicas
- ✅ All pods in "Running" state
- ✅ Application accessible via browser
- ✅ ArgoCD shows "Synced" and "Healthy" status

**Validation Command**:

```bash
fawkes assessment validate --lab white-belt-lab1
```

---

### Lab 2: Deploy to Multiple Environments (25 minutes)

**Objective**: Use Kustomize overlays to deploy the same app to dev and prod environments.

**Tasks**:

1. Create base configuration (common to all environments)
2. Create dev overlay (1 replica, dev config)
3. Create prod overlay (3 replicas, prod config, resource limits)
4. Deploy both environments via ArgoCD
5. Verify different configurations in each environment

**Acceptance Criteria**:

- ✅ Dev environment: 1 replica, no resource limits
- ✅ Prod environment: 3 replicas, resource limits configured
- ✅ Both environments use same base image
- ✅ ArgoCD managing both environments

**Validation Command**:

```bash
fawkes assessment validate --lab white-belt-lab2
```

---

### Lab 3: Monitor DORA Metrics (25 minutes)

**Objective**: Set up DORA metrics collection and dashboard for your application.

**Tasks**:

1. Configure deployment tracking (Prometheus annotations)
2. Deploy the DORA metrics exporter
3. Create Grafana dashboard showing:
   - Deployment frequency (last 7 days)
   - Average lead time
   - Recent deployments timeline
4. Perform 3 test deployments and observe metrics

**Acceptance Criteria**:

- ✅ Deployment frequency metric showing 3+ deployments
- ✅ Lead time calculated for each deployment
- ✅ Dashboard displays real-time metrics
- ✅ Deployment success/failure status tracked

**Validation Command**:

```bash
fawkes assessment validate --lab white-belt-lab3
```

---

## Submission & Grading

### Automated Grading

The Fawkes assessment system automatically grades:

- **Written exam**: Instant results upon submission
- **Labs**: Validation scripts check cluster state

### Manual Review

Platform engineers will review:

- Code quality in Git commits
- Documentation in pull requests
- Dashboard configuration

### Scoring

```
Written Exam:  30 questions × 2 points = 60 points
Lab 1:         10 points
Lab 2:         15 points
Lab 3:         15 points
─────────────────────────────────────────────────
Total:         100 points

Passing Score: 80 points
```

---

## Results & Certification

### Passing (≥80 points)

You will receive:

- ✅ **Fawkes Platform Operator** digital certificate
- 🎖️ Digital badge (add to LinkedIn/resume)
- 📧 Certificate email with verification link
- 🚀 Access to Yellow Belt curriculum

### Not Passing (<80 points)

- 📊 Detailed score report showing weak areas
- 📚 Recommended modules to review
- 🔄 Can retake after 7 days
- 💬 Schedule office hours with instructors

---

## Study Resources

### Review Materials

- Module 1: Internal Delivery Platforms
- Module 2: DORA Metrics
- Module 3: GitOps Principles
- Module 4: Your First Deployment

### Practice Labs

```bash
# Launch practice environment
fawkes lab start --module 1
fawkes lab start --module 2
fawkes lab start --module 3
fawkes lab start --module 4
```

### Additional Resources

- [DORA Research Papers](https://dora.dev)
- [GitOps Principles](https://opengitops.dev)
- [Kubernetes Basics](https://kubernetes.io/docs/tutorials/)
- [ArgoCD Documentation](https://argo-cd.readthedocs.io)

---

## Taking the Assessment

### Schedule Your Assessment

```bash
# Check eligibility
fawkes assessment check-eligibility --belt white

# Schedule assessment session
fawkes assessment schedule --belt white --date "2025-10-20" --time "14:00"

# You'll receive confirmation email with:
# - Assessment link
# - Duration (2 hours)
# - Requirements checklist
```

### During the Assessment

1. **Written Exam** (60 minutes)

   - 30 questions, multiple choice
   - Can review and change answers
   - Submit when complete

2. **Hands-On Labs** (70 minutes)

   - Access lab environment via browser
   - Complete all 3 labs
   - Run validation commands
   - Submit lab results

3. **Review** (if time permits)
   - Double-check written answers
   - Verify all lab tasks complete
   - Submit final assessment

---

## Good Luck! 🍀

Remember:

- ✅ Read questions carefully
- ✅ Use the lab environment to test your understanding
- ✅ Don't rush - you have 2 hours
- ✅ If stuck, move on and come back later
- ✅ Validate labs before submitting

**Questions?** Contact #dojo-support on Mattermost

---

**White Belt Assessment** | Fawkes Dojo | Version 1.0
_Earn your Fawkes Platform Operator certification_ 🥋
