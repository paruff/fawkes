# Copilot Instructions for Fawkes Platform

## 🎯 Agent Model Capabilities

When using Copilot in agent mode, you will get:

### Planning Phase

- **Architecture analysis** - Review existing code and suggest optimal implementation patterns
- **Dependency mapping** - Identify required components and integration points
- **Task breakdown** - Decompose complex features into implementable steps
- **Risk assessment** - Flag potential issues before implementation
- **Alternative evaluation** - Compare multiple approaches with trade-offs

### Implementation Phase

- **Multi-file generation** - Create complete feature implementations across files
- **Test generation** - Automatic unit, integration, and E2E test creation
- **Documentation updates** - Keep docs in sync with code changes
- **Configuration management** - Generate all required configs (K8s, Terraform, etc.)
- **Refactoring suggestions** - Improve existing code continuously

---

## 🏗️ Fawkes Platform Context

### What is Fawkes?

Fawkes is an **open-source Internal Product Delivery Platform** that combines:

- **Infrastructure automation** (Kubernetes, Terraform/Crossplane)
- **Developer portal** (Backstage with software templates)
- **CI/CD pipelines** (Jenkins, ArgoCD for GitOps)
- **Team collaboration** (Mattermost, Focalboard)
- **Immersive learning** (Dojo system with 5-belt progression)

### Key Differentiators

1. **DORA metrics automated** - All 4 key metrics tracked from day one
2. **Integrated learning curriculum** - Learn while building
3. **Complete product delivery stack** - Not just infrastructure
4. **Open source, self-hosted** - No vendor lock-in, MIT licensed
5. **Platform as a product** - Developer experience first

### Current MVP Scope

**IN SCOPE:**

- Kubernetes orchestration (AWS EKS primary, multi-cloud planned)
- Backstage developer portal + Dojo learning hub
- Jenkins CI/CD with golden path templates
- ArgoCD for GitOps continuous delivery
- Mattermost for team collaboration
- Focalboard for project management (bundled with Mattermost)
- Prometheus + Grafana for observability
- OpenSearch + Fluent Bit for logging
- SonarQube + Trivy for security scanning
- Harbor for container registry
- DORA metrics automation

**OUT OF SCOPE (Post-MVP):**

- Spinnaker (dropped from MVP - using ArgoCD + Argo Rollouts instead)
- Eclipse Che (using local workspace automation for MVP)
- Multi-cloud abstractions with Crossplane (AWS first, then expand)
- Advanced service mesh features

### Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    Fawkes Platform                           │
├─────────────────────────────────────────────────────────────┤
│  Developer Portal (Backstage)                                │
│  ├── Service Catalog                                         │
│  ├── Software Templates (Golden Paths)                       │
│  ├── TechDocs (Documentation)                                │
│  └── Dojo Learning Hub (Modules, Labs, Progress)            │
├─────────────────────────────────────────────────────────────┤
│  Infrastructure Layer (Kubernetes)                           │
│  ├── Jenkins (CI/CD Pipelines)                              │
│  ├── ArgoCD (GitOps Continuous Delivery)                    │
│  ├── Harbor (Container Registry + Scanning)                 │
│  ├── Mattermost (Team Collaboration)                        │
│  ├── Focalboard (Project Management - in Mattermost)        │
│  └── Observability (Prometheus, Grafana, OpenSearch)        │
├─────────────────────────────────────────────────────────────┤
│  Cloud Infrastructure (AWS First, Multi-Cloud Later)        │
│  ├── Terraform (IaC for AWS)                                │
│  ├── Amazon EKS (Kubernetes)                                │
│  └── AWS Services (RDS, S3, ALB, CloudWatch, etc.)          │
└─────────────────────────────────────────────────────────────┘
```

---

## 📁 Fawkes Repository Structure (CURRENT)

**CRITICAL: Use this EXACT structure for all file generation**

Based on the actual repository at https://github.com/paruff/fawkes:

```
fawkes/
├── docs/                           # Documentation
│   ├── dojo/                       # Dojo learning system
│   │   ├── DOJO_ARCHITECTURE.md   # Complete learning system design
│   │   ├── white-belt/            # White belt curriculum
│   │   ├── yellow-belt/           # Yellow belt curriculum
│   │   ├── green-belt/            # Green belt curriculum
│   │   ├── brown-belt/            # Brown belt curriculum
│   │   └── black-belt/            # Black belt curriculum
│   ├── adr/                        # Architecture Decision Records
│   │   ├── ADR-001-kubernetes.md
│   │   ├── ADR-002-backstage.md
│   │   ├── ADR-003-argocd.md
│   │   ├── ADR-004-jenkins.md
│   │   ├── ADR-005-terraform.md
│   │   ├── ADR-006-postgresql.md
│   │   ├── ADR-007-mattermost.md
│   │   └── ADR-008-focalboard.md
│   ├── components/                 # Component-specific docs
│   ├── operations/                 # Operational guides
│   ├── sprints/                    # Sprint planning docs
│   ├── architecture.md             # System architecture
│   ├── getting-started.md          # Getting started guide
│   ├── troubleshooting.md          # Troubleshooting
│   ├── AWS_COST_ESTIMATION.md      # AWS cost analysis
│   └── BUSINESS_CASE.md            # Business value prop
│
├── infra/                          # Infrastructure as Code
│   ├── scripts/ignite.sh           # Unified cluster + Argo CD bootstrap
│   ├── scripts/ignite.sh           # Unified cluster + Argo CD bootstrap
│   ├── terraform/                  # Terraform modules (AWS primary)
│   │   └── aws/                    # AWS-specific IaC
│   ├── kubernetes/                 # Kubernetes manifests
│   │   ├── backstage/              # Developer portal
│   │   ├── jenkins/                # CI/CD
│   │   ├── argocd/                 # GitOps
│   │   ├── harbor/                 # Container registry
│   │   ├── mattermost/             # Collaboration
│   │   ├── prometheus/             # Metrics
│   │   ├── grafana/                # Dashboards
│   │   └── opensearch/             # Logging
│   ├── helm/                       # Helm charts
│   └── workspace/                  # Developer workspace automation
│       ├── setup-OS-space.sh       # Local workspace setup
│       └── [platform-specific]/    # macOS/Windows configs
│
├── modules/                        # Terraform/reusable modules
│   └── [cloud-provider-modules]/
│
├── templates/                      # Application templates (golden paths)
│   ├── java-spring-boot/          # Java template (existing)
│   ├── python-fastapi/             # Python template (planned)
│   └── nodejs-express/             # Node.js template (planned)
│
├── tests/                          # Automated tests
│   ├── e2e/                        # End-to-end BDD tests (create when ready)
│   │   ├── features/               # Gherkin scenarios
│   │   └── step_definitions/       # Test implementations
│   ├── integration/                # Integration tests
│   └── unit/                       # Unit tests
│
├── scripts/                        # Utility scripts
│   ├── setup/                      # Setup automation
│   ├── validation/                 # Config validation
│   └── run-tests.sh                # Test runner
│
├── .github/                        # GitHub configuration
│   ├── workflows/                  # CI/CD pipelines
│   ├── ISSUE_TEMPLATE/             # Issue templates
│   │   ├── bug_report.yml
│   │   ├── feature_request.yml
│   │   ├── dojo_module.yml
│   │   └── security_vulnerability.yml
│   ├── PULL_REQUEST_TEMPLATE.md
│   └── labels.yml                  # GitHub labels config
│
├── config/                         # Configuration files
│   └── example.tfvars              # Example Terraform variables
│
├── GOVERNANCE.md                   # Project governance
├── CODE_OF_CONDUCT.md              # Community standards
├── PROJECT_CHARTER.md              # Vision and mission
├── CONTRIBUTING.md                 # Contribution guidelines
├── CONTRIBUTORS.md                 # Contributor recognition
├── LICENSE                         # MIT License
└── README.md                       # Main project README
```

### File Naming Conventions

- **Kubernetes manifests:** `<resource>-<name>.yaml` (e.g., `deployment-backstage.yaml`)
- **Terraform modules:** `main.tf`, `variables.tf`, `outputs.tf`
- **Python tests:** `test_<feature>.py`
- **Feature files:** `<capability>.feature` (lowercase, underscores)
- **Helm charts:** `Chart.yaml`, `values.yaml`, `templates/`
- **Scripts:** Place in `scripts/` (e.g., `ignite.sh`, `setup-OS-space.sh`)

### Key Paths Reference

| Component              | Path                                   |
| ---------------------- | -------------------------------------- |
| Infrastructure scripts | `/scripts/ignite.sh`                   |
| Terraform (AWS)        | `/infra/terraform/aws/` or `/modules/` |
| Kubernetes manifests   | `/infra/kubernetes/<service>/`         |
| Dojo curriculum        | `/docs/dojo/<belt-level>/`             |
| ADRs                   | `/docs/adr/ADR-###-<topic>.md`         |
| Application templates  | `/templates/<language>-<framework>/`   |
| Tests                  | `/tests/<type>/`                       |
| Scripts                | `/scripts/` or `/infra/`               |

---

## 🔧 Working with Existing Structure

**IMPORTANT:** Fawkes uses an established directory structure. When generating code:

1. **Check existing patterns first** - Look at current file locations before creating new ones
2. **Ask before major moves** - Don't restructure without explicit request
3. **Use relative paths** - Make code work regardless of exact structure
4. **Document location decisions** - Add comments explaining file placement
5. **Respect established conventions** - Follow existing naming and organization

### Example Placement Decision

```python
# File: infra/kubernetes/prometheus/servicemonitor-jenkins.yaml
# Rationale: Follows existing infra/kubernetes/<service>/ pattern
# Related: infra/kubernetes/jenkins/deployment-jenkins.yaml
```

### When in Doubt

- **For infrastructure:** Check `/infra/` first
- **For docs:** Check `/docs/` structure
- **For templates:** Use `/templates/`
- **For tests:** Create in `/tests/e2e/` or `/tests/integration/`
- **Ask the user:** "Should this go in X or Y?"

---

## 🎓 DORA Capabilities Integration

### The 24 Key Capabilities

Every code change should map to one or more DORA capabilities:

#### Technical Practices (14 capabilities)

1. **Version control** - All code in Git, trunk-based development
2. **Continuous integration** - Automated build/test on every commit
3. **Deployment automation** - Push-button or automated deployment
4. **Trunk-based development** - Short-lived branches (<1 day)
5. **Test automation** - Comprehensive automated test suite
6. **Test data management** - Realistic test data provisioning
7. **Shift left on security** - Security scanning in CI pipeline
8. **Continuous delivery** - Code always in deployable state
9. **Loosely coupled architecture** - Services independently deployable
10. **Empowered teams** - Teams choose tools, make decisions
11. **Monitoring & observability** - Proactive system health tracking
12. **Proactive failure notification** - Alerts before user impact
13. **Database change management** - Automated schema migrations
14. **Code maintainability** - Clean, documented, testable code

#### Process Practices (6 capabilities)

15. **Streamlined change approval** - Peer review, not CAB
16. **Customer feedback** - Short feedback loops
17. **Team experimentation** - Safe to try new approaches
18. **Work in small batches** - Small, frequent changes
19. **Visibility of work in value stream** - Clear status tracking
20. **Work in process limits** - Focus, avoid multitasking

#### Cultural Practices (4 capabilities)

21. **Generative organizational culture** - Westrum model
22. **Learning culture** - Blameless postmortems, knowledge sharing
23. **Job satisfaction** - Autonomy, mastery, purpose
24. **Transformational leadership** - Servant leadership

### Tagging System

Use these tags in code comments and tests:

```python
# @dora-capability: continuous_integration
# @dora-metric: deployment_frequency, lead_time
# @belt-level: white-belt
def automated_build_pipeline():
    """
    Implements automated CI pipeline that triggers on every commit.

    DORA Impact:
    - Increases deployment frequency through automation
    - Reduces lead time by catching issues early

    Learning Objective: Students learn to create Jenkins pipelines
    that integrate with GitHub webhooks.
    """
    pass
```

---

## 🚀 Development Patterns

### 1. Trunk-Based Development

**ALWAYS follow these practices:**

```bash
# ✅ Good: Short-lived feature branch
git checkout -b feature/add-metrics
# Work for max 1 day
git commit -am "Add DORA metrics collection"
git push origin feature/add-metrics
# Create PR, get review, merge same day

# ❌ Bad: Long-lived branch
git checkout -b feature/refactor-entire-system
# Work for weeks... NO!
```

**Branch Rules:**

- Maximum **3 active branches** in repository
- Merge within **1 day** of creation
- Use **feature flags** for incomplete features
- No code freeze periods

### 2. Declarative Infrastructure

**Always use declarative formats:**

```yaml
# ✅ Good: Declarative Kubernetes manifest
# File: infra/kubernetes/backstage/deployment-backstage.yaml

apiVersion: apps/v1
kind: Deployment
metadata:
  name: backstage
  namespace: fawkes-platform
  labels:
    app: backstage
    component: developer-portal
    dora-capability: self-service
spec:
  replicas: 2
  selector:
    matchLabels:
      app: backstage
  template:
    metadata:
      labels:
        app: backstage
        version: v1.20.0
    spec:
      containers:
        - name: backstage
          image: backstage/backstage:v1.20.0
          ports:
            - containerPort: 7007
              name: http
          resources:
            requests:
              memory: "512Mi"
              cpu: "250m"
            limits:
              memory: "1Gi"
              cpu: "500m"
          env:
            - name: POSTGRES_HOST
              valueFrom:
                secretKeyRef:
                  name: backstage-postgres
                  key: host
          livenessProbe:
            httpGet:
              path: /healthcheck
              port: 7007
            initialDelaySeconds: 60
            periodSeconds: 10
          readinessProbe:
            httpGet:
              path: /healthcheck
              port: 7007
            initialDelaySeconds: 30
            periodSeconds: 5
```

```python
# ❌ Bad: Imperative approach (avoid this)
import subprocess

subprocess.run([
    "kubectl", "create", "deployment", "backstage",
    "--image=backstage/backstage:v1.20.0",
    "--replicas=2"
])
```

### 3. GitOps Workflow with ArgoCD

**All infrastructure changes through Git:**

```yaml
# File: infra/kubernetes/argocd/application-backstage.yaml
# ArgoCD Application for automated deployment

apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: backstage
  namespace: argocd
  annotations:
    dora-capability: continuous_delivery
    notifications.argoproj.io/subscribe.on-deployed.mattermost: fawkes-deployments
spec:
  project: default
  source:
    repoURL: https://github.com/paruff/fawkes.git
    targetRevision: main
    path: infra/kubernetes/backstage
  destination:
    server: https://kubernetes.default.svc
    namespace: fawkes-platform
  syncPolicy:
    automated:
      prune: true # Delete resources not in Git
      selfHeal: true # Revert manual changes
      allowEmpty: false
    syncOptions:
      - CreateNamespace=true
    retry:
      limit: 5
      backoff:
        duration: 5s
        factor: 2
        maxDuration: 3m
```

### 4. Progressive Delivery with Argo Rollouts

**Use Argo Rollouts for canary and blue-green deployments (replaces Spinnaker):**

```yaml
# File: infra/kubernetes/backstage/rollout-backstage.yaml
# Progressive deployment strategy

apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: backstage
  namespace: fawkes-platform
  annotations:
    dora-capability: deployment_automation
spec:
  replicas: 3
  strategy:
    canary:
      steps:
        - setWeight: 20
        - pause: { duration: 5m }
        - setWeight: 40
        - pause: { duration: 5m }
        - setWeight: 60
        - pause: { duration: 5m }
        - setWeight: 80
        - pause: { duration: 5m }
      analysis:
        templates:
          - templateName: backstage-success-rate
        startingStep: 2
        args:
          - name: service-name
            value: backstage
  selector:
    matchLabels:
      app: backstage
  template:
    metadata:
      labels:
        app: backstage
    spec:
      containers:
        - name: backstage
          image: backstage/backstage:v1.21.0 # New version
          # ... rest of container spec
```

---

## 🧪 Testing Strategy

### BDD Test Structure

**Create Gherkin feature files for all capabilities:**

```gherkin
# File: tests/e2e/features/continuous_integration.feature
# @dora-capability: continuous_integration

@dora-deployment-frequency @dora-lead-time
Feature: Continuous Integration Pipeline
  As a developer
  I want automated build and test pipelines
  So that I can quickly validate changes

  Background:
    Given a Jenkins instance is running at "http://jenkins.fawkes-platform.svc"
    And the "spring-boot-template" exists in "/templates/java-spring-boot"
    And GitHub webhooks are configured

  @smoke @white-belt
  Scenario: Commit triggers automatic build
    Given I have cloned the "demo-java-app" repository
    When I commit a change to the "main" branch
    Then a Jenkins build starts within 30 seconds
    And the build completes within 5 minutes
    And the build status is reported to GitHub
    And the commit shows a green checkmark
    And DORA metrics record the deployment

  @yellow-belt
  Scenario: Pipeline includes security scanning
    Given a Jenkins pipeline for "demo-python-app"
    When the build stage completes successfully
    Then the security scan stage executes
    And Trivy scans the container image for vulnerabilities
    And SonarQube analyzes the source code
    And no HIGH or CRITICAL vulnerabilities are found
    And a security report is archived

  @green-belt @dora-change-failure-rate
  Scenario: Failed builds notify team via Mattermost
    Given a Jenkins pipeline for "demo-node-app"
    When a build fails due to test failures
    Then a Mattermost notification is sent within 60 seconds
    And the notification includes the failure reason
    And the notification links to the build logs
    And the DORA metrics service records the failure
```

**Step definitions with proper instrumentation:**

```python
# File: tests/e2e/step_definitions/jenkins_steps.py

from pytest_bdd import given, when, then, parsers
from datetime import datetime, timedelta
import requests
import time

@given(parsers.parse('a Jenkins instance is running at "{url}"'))
def jenkins_running(jenkins_client, url):
    """
    Verify Jenkins is accessible and healthy.

    @dora-capability: continuous_integration
    """
    response = jenkins_client.get(f'{url}/api/json')
    assert response.status_code == 200, f"Jenkins not accessible at {url}"
    data = response.json()
    assert data.get('mode') == 'NORMAL', "Jenkins not in normal mode"
    assert data.get('numExecutors', 0) > 0, "No Jenkins executors available"

@when(parsers.parse('I commit a change to the "{branch}" branch'))
def commit_change(git_repo, branch, dora_metrics):
    """
    Commit test change and record timestamp for lead time calculation.

    @dora-metric: lead_time
    """
    git_repo.checkout(branch)

    # Make traceable change
    commit_id = f"test-{datetime.utcnow().isoformat()}"
    with open('README.md', 'a') as f:
        f.write(f'\n<!-- Test commit {commit_id} -->')

    git_repo.index.add(['README.md'])
    commit = git_repo.index.commit(f'Test commit {commit_id}')
    git_repo.remote('origin').push(branch)

    # Record commit time for DORA lead time metric
    dora_metrics.record_commit(
        commit_sha=commit.hexsha,
        timestamp=datetime.utcnow(),
        service=git_repo.name,
        branch=branch
    )

@then(parsers.parse('a Jenkins build starts within {seconds:d} seconds'))
def build_starts(jenkins_client, git_repo, seconds, dora_metrics):
    """
    Verify build triggered within SLA and update deployment frequency metric.

    @dora-metric: deployment_frequency
    """
    start_time = datetime.utcnow()
    deadline = start_time + timedelta(seconds=seconds)

    while datetime.utcnow() < deadline:
        builds = jenkins_client.get_builds(git_repo.name)
        if builds and builds[0].timestamp > dora_metrics.get_commit_time(git_repo.name):
            # Build started - record for metrics
            dora_metrics.record_build_start(
                build_id=builds[0].id,
                build_number=builds[0].number,
                timestamp=builds[0].timestamp,
                service=git_repo.name
            )
            return
        time.sleep(2)

    raise AssertionError(
        f"No build started within {seconds}s of commit to {git_repo.name}. "
        f"This impacts deployment frequency SLA."
    )

@then('DORA metrics record the deployment')
def verify_dora_metrics(dora_metrics, git_repo):
    """
    Verify DORA metrics service recorded all events.

    @dora-capability: monitoring_and_observability
    """
    # Verify metrics were recorded
    metrics = dora_metrics.get_metrics(service=git_repo.name)

    assert metrics.get('deployment_frequency') is not None, \
        "Deployment frequency not recorded"
    assert metrics.get('lead_time') is not None, \
        "Lead time not recorded"

    # Verify Prometheus metrics are accessible
    prom_response = requests.get('http://prometheus.fawkes-platform.svc:9090/api/v1/query',
                                 params={'query': f'deployments_total{{service="{git_repo.name}"}}'})
    assert prom_response.status_code == 200, "Cannot query Prometheus metrics"
```

### Test Organization

```python
# File: tests/e2e/conftest.py

import pytest
from typing import Dict, List

def pytest_collection_modifyitems(config, items):
    """
    Add belt level and DORA capability markers for tracking.

    @dora-capability: learning_culture
    """
    belt_order = ['white-belt', 'yellow-belt', 'green-belt',
                  'brown-belt', 'black-belt']

    for item in items:
        # Extract belt level
        belt_markers = [m.name for m in item.iter_markers()
                       if m.name in belt_order]
        if belt_markers:
            item.add_marker(pytest.mark.belt_level(belt_markers[0]))

        # Extract DORA metrics
        dora_markers = [m.name for m in item.iter_markers()
                       if m.name.startswith('dora-')]
        for marker in dora_markers:
            metric = marker.replace('dora-', '')
            item.add_marker(pytest.mark.dora_metric(metric))

def pytest_terminal_summary(terminalreporter, exitstatus, config):
    """
    Report results by belt level for dojo progression tracking.
    """
    belt_results: Dict[str, List[str]] = {}

    for report in terminalreporter.stats.get('passed', []):
        belt_marker = report.keywords.get('belt_level')
        if belt_marker:
            belt = belt_marker[0].args[0]
            belt_results.setdefault(belt, []).append(report.nodeid)

    terminalreporter.write_sep('=', 'Dojo Progression Summary')
    for belt in ['white-belt', 'yellow-belt', 'green-belt',
                 'brown-belt', 'black-belt']:
        scenarios = belt_results.get(belt, [])
        status = '✅' if scenarios else '⏸️'
        terminalreporter.write_line(
            f'  {status} {belt.upper()}: {len(scenarios)} scenarios passed'
        )

    # DORA metrics summary
    dora_results: Dict[str, int] = {}
    for report in terminalreporter.stats.get('passed', []):
        dora_marker = report.keywords.get('dora_metric')
        if dora_marker:
            for metric in dora_marker:
                metric_name = metric.args[0]
                dora_results[metric_name] = dora_results.get(metric_name, 0) + 1

    if dora_results:
        terminalreporter.write_sep('=', 'DORA Metrics Coverage')
        for metric, count in sorted(dora_results.items()):
            terminalreporter.write_line(f'  📊 {metric}: {count} tests')
```

---

## 🔒 Security Patterns

### 1. Container Scanning with Trivy

**Integrate Trivy in all Jenkins pipelines:**

```groovy
// File: templates/java-spring-boot/Jenkinsfile

@Library('fawkes-shared-library') _

pipeline {
  agent {
    kubernetes {
      yaml '''
        apiVersion: v1
        kind: Pod
        metadata:
          labels:
            jenkins: agent
        spec:
          serviceAccountName: jenkins
          containers:
          - name: maven
            image: maven:3.9-eclipse-temurin-17
            command: ['cat']
            tty: true
          - name: trivy
            image: aquasec/trivy:latest
            command: ['cat']
            tty: true
          - name: kaniko
            image: gcr.io/kaniko-project/executor:latest
            command: ['cat']
            tty: true
      '''
    }
  }

  environment {
    HARBOR_REGISTRY = 'harbor.fawkes-platform.svc'
    HARBOR_PROJECT = 'fawkes'
    IMAGE_NAME = "${HARBOR_REGISTRY}/${HARBOR_PROJECT}/${env.JOB_NAME}"
    IMAGE_TAG = "${env.GIT_COMMIT.take(8)}"
    HARBOR_CREDS = credentials('harbor-robot-account')
  }

  stages {
    stage('Build') {
      steps {
        container('maven') {
          sh '''
            mvn clean package -DskipTests=false
            mvn test
          '''
        }
      }
    }

    stage('Code Quality') {
      steps {
        container('maven') {
          withSonarQubeEnv('SonarQube') {
            sh 'mvn sonar:sonar'
          }
        }
      }
    }

    stage('Build Container') {
      steps {
        container('kaniko') {
          sh '''
            /kaniko/executor \
              --dockerfile=Dockerfile \
              --context=dir://$(pwd) \
              --destination=${IMAGE_NAME}:${IMAGE_TAG} \
              --destination=${IMAGE_NAME}:latest \
              --skip-tls-verify
          '''
        }
      }
    }

    stage('Security Scan') {
      steps {
        container('trivy') {
          sh '''
            trivy image \
              --severity HIGH,CRITICAL \
              --exit-code 1 \
              --no-progress \
              --format json \
              --output trivy-report.json \
              --insecure \
              ${IMAGE_NAME}:${IMAGE_TAG}
          '''
        }
      }
      post {
        always {
          archiveArtifacts artifacts: 'trivy-report.json', allowEmptyArchive: true

          // Send scan results to DORA metrics service
          sh '''
            curl -X POST http://dora-metrics.fawkes-platform.svc:8080/api/v1/security-scan \
              -H "Content-Type: application/json" \
              -d @trivy-report.json || true
          '''
        }
        failure {
          mattermostSend(
            endpoint: 'http://mattermost.fawkes-platform.svc:8065/hooks/...',
            color: 'danger',
            message: """
              🚨 **Security Vulnerabilities Found**

              **Service:** ${IMAGE_NAME}:${IMAGE_TAG}
              **Build:** ${env.BUILD_URL}
              **Action Required:** Fix HIGH/CRITICAL vulnerabilities before deployment

              See attached trivy-report.json for details.
            """
          )
        }
      }
    }

    stage('Deploy to Dev') {
      when {
        branch 'main'
        expression { currentBuild.result != 'FAILURE' }
      }
      steps {
        script {
          // Update ArgoCD application manifest
          sh '''
            git clone https://github.com/paruff/fawkes.git fawkes-gitops
            cd fawkes-gitops/infra/kubernetes/${JOB_NAME}

            # Update image tag in deployment
            sed -i "s|image:.*|image: ${IMAGE_NAME}:${IMAGE_TAG}|g" deployment.yaml

            git config user.email "jenkins@fawkes-platform"
            git config user.name "Fawkes Jenkins"
            git add deployment.yaml
            git commit -m "Update ${JOB_NAME} to ${IMAGE_TAG}"
            git push origin main
          '''

          // Record deployment for DORA metrics
          sh '''
            curl -X POST http://dora-metrics.fawkes-platform.svc:8080/api/v1/deployments \
              -H "Content-Type: application/json" \
              -d '{
                "service": "'${JOB_NAME}'",
                "version": "'${IMAGE_TAG}'",
                "environment": "dev",
                "commit_sha": "'${GIT_COMMIT}'",
                "commit_timestamp": "'$(git show -s --format=%cI ${GIT_COMMIT})'",
                "deployment_timestamp": "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'",
                "status": "success"
              }'
          '''
        }
      }
      post {
        success {
          mattermostSend(
            color: 'good',
            message: """
              ✅ **Deployment Successful**

              **Service:** ${JOB_NAME}
              **Version:** ${IMAGE_TAG}
              **Environment:** dev
              **Build:** ${env.BUILD_URL}
            """
          )
        }
      }
    }
  }

  post {
    always {
      // Cleanup workspace
      cleanWs()
    }
  }
}
```

### 2. Policy Enforcement with Kyverno

**Use Kyverno for policy-as-code (simpler than OPA for MVP):**

```yaml
# File: infra/kubernetes/kyverno/require-resource-limits.yaml

apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: require-resource-limits
  annotations:
    policies.kyverno.io/title: Require Resource Limits
    policies.kyverno.io/category: Best Practices
    policies.kyverno.io/severity: medium
    policies.kyverno.io/description: >-
      All containers must have CPU and memory limits to prevent resource exhaustion.
      This is a DORA best practice for system reliability and security.
    dora-capability: monitoring_and_observability
spec:
  validationFailureAction: enforce
  background: true
  rules:
    - name: validate-resources
      match:
        any:
          - resources:
              kinds:
                - Deployment
                - StatefulSet
                - DaemonSet
              namespaces:
                - fawkes-*
      validate:
        message: >-
          All containers must have CPU and memory limits defined.
          This ensures predictable resource usage and prevents noisy neighbor issues.

          Example:
            resources:
              limits:
                memory: "512Mi"
                cpu: "500m"
              requests:
                memory: "256Mi"
                cpu: "100m"
        pattern:
          spec:
            template:
              spec:
                containers:
                  - resources:
                      limits:
                        memory: "?*"
                        cpu: "?*"
                      requests:
                        memory: "?*"
                        cpu: "?*"
```

```yaml
# File: infra/kubernetes/kyverno/disallow-latest-tag.yaml

apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: disallow-latest-tag
  annotations:
    policies.kyverno.io/title: Disallow Latest Tag
    policies.kyverno.io/category: Best Practices
    policies.kyverno.io/severity: high
    policies.kyverno.io/description: >-
      Container images must use specific version tags, not 'latest'.
      Using 'latest' tag makes deployments non-deterministic and harder to rollback.
    dora-capability: continuous_delivery
spec:
  validationFailureAction: enforce
  background: true
  rules:
    - name: require-image-tag
      match:
        any:
          - resources:
              kinds:
                - Deployment
                - StatefulSet
                - DaemonSet
      validate:
        message: >-
          Container images must not use 'latest' tag.
          Use a specific version tag like 'v1.2.3' or git commit SHA.
        pattern:
          spec:
            template:
              spec:
                containers:
                  - image: "!*:latest"
```

### 3. Secrets Management with External Secrets Operator

**Never hardcode secrets - use External Secrets Operator with AWS Secrets Manager:**

```yaml
# File: infra/kubernetes/external-secrets/clustersecretstore-aws.yaml

apiVersion: external-secrets.io/v1beta1
kind: ClusterSecretStore
metadata:
  name: aws-secretsmanager
  annotations:
    dora-capability: shift_left_on_security
spec:
  provider:
    aws:
      service: SecretsManager
      region: us-east-1
      auth:
        jwt:
          serviceAccountRef:
            name: external-secrets-sa
            namespace: external-secrets-system
```

```yaml
# File: infra/kubernetes/backstage/externalsecret-postgres.yaml

apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: backstage-postgres-credentials
  namespace: fawkes-platform
  annotations:
    dora-capability: shift_left_on_security
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: aws-secretsmanager
    kind: ClusterSecretStore
  target:
    name: backstage-postgres
    creationPolicy: Owner
    template:
      engineVersion: v2
      data:
        # Template for connection string
        DATABASE_URL: "postgresql://{{ .username }}:{{ .password }}@{{ .host }}:5432/backstage"
        POSTGRES_USER: "{{ .username }}"
        POSTGRES_PASSWORD: "{{ .password }}"
        POSTGRES_HOST: "{{ .host }}"
  data:
    - secretKey: username
      remoteRef:
        key: fawkes/backstage/postgres
        property: username
    - secretKey: password
      remoteRef:
        key: fawkes/backstage/postgres
        property: password
    - secretKey: host
      remoteRef:
        key: fawkes/backstage/postgres
        property: host
```

---

## 📊 DORA Metrics Implementation

### Metrics Collection Service

**Create a lightweight FastAPI service for collecting DORA metrics:**

```python
# File: scripts/dora-metrics/main.py
# Note: This may eventually move to a dedicated service directory

from fastapi import FastAPI, HTTPException, BackgroundTasks
from pydantic import BaseModel, Field
from datetime import datetime
from typing import Literal, Optional
import prometheus_client
from prometheus_client import Counter, Histogram, Gauge, generate_latest
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(
    title="Fawkes DORA Metrics Collector",
    description="Automated collection of the Four Key DORA metrics",
    version="1.0.0"
)

# Prometheus metrics
deployment_counter = Counter(
    'fawkes_deployments_total',
    'Total number of deployments',
    ['service', 'environment', 'version', 'status']
)

lead_time_histogram = Histogram(
    'fawkes_lead_time_seconds',
    'Lead time from commit to deployment (seconds)',
    ['service', 'environment'],
    buckets=[60, 300, 900, 1800, 3600, 7200, 14400, 28800, 86400]  # 1m to 1d
)

failure_counter = Counter(
    'fawkes_change_failures_total',
    'Total number of failed changes',
    ['service', 'environment', 'failure_type']
)

mttr_histogram = Histogram(
    'fawkes_mttr_seconds',
    'Mean time to restore service (seconds)',
    ['service', 'environment', 'incident_type'],
    buckets=[300, 900, 1800, 3600, 7200, 14400, 28800, 86400]  # 5m to 1d
)

active_incidents = Gauge(
    'fawkes_active_incidents',
    'Number of currently active incidents',
    ['service', 'environment']
)

# Pydantic models
class DeploymentEvent(BaseModel):
    service: str = Field(..., description="Service name")
    version: str = Field(..., description="Version or git commit SHA")
    environment: Literal['dev', 'staging', 'production'] = Field(..., description="Target environment")
    commit_sha: str = Field(..., description="Git commit SHA")
    commit_timestamp: datetime = Field(..., description="When the commit was created")
    deployment_timestamp: datetime = Field(default_factory=datetime.utcnow, description="When deployment occurred")
    status: Literal['success', 'failure'] = Field(..., description="Deployment outcome")

    class Config:
        json_schema_extra = {
            "example": {
                "service": "demo-java-app",
                "version": "v1.2.3",
                "environment": "production",
                "commit_sha": "abc123def456",
                "commit_timestamp": "2025-10-25T10:00:00Z",
                "deployment_timestamp": "2025-10-25T10:15:00Z",
                "status": "success"
            }
        }

class IncidentEvent(BaseModel):
    service: str = Field(..., description="Affected service name")
    environment: Literal['dev', 'staging', 'production'] = Field(..., description="Affected environment")
    incident_type: str = Field(..., description="Type of incident (e.g., 'outage', 'degradation')")
    severity: Literal['low', 'medium', 'high', 'critical'] = Field(..., description="Incident severity")
    started_at: datetime = Field(..., description="When incident started")
    resolved_at: Optional[datetime] = Field(None, description="When incident was resolved")
    caused_by_deployment: Optional[str] = Field(None, description="Git commit SHA if caused by deployment")

    class Config:
        json_schema_extra = {
            "example": {
                "service": "demo-java-app",
                "environment": "production",
                "incident_type": "outage",
                "severity": "high",
                "started_at": "2025-10-25T11:00:00Z",
                "resolved_at": "2025-10-25T11:30:00Z",
                "caused_by_deployment": "abc123def456"
            }
        }

class SecurityScanResult(BaseModel):
    service: str
    version: str
    scanner: Literal['trivy', 'sonarqube', 'snyk']
    high_vulnerabilities: int
    critical_vulnerabilities: int
    timestamp: datetime = Field(default_factory=datetime.utcnow)

# API Endpoints

@app.get("/")
async def root():
    """Health check endpoint"""
    return {
        "service": "Fawkes DORA Metrics Collector",
        "status": "healthy",
        "version": "1.0.0"
    }

@app.post("/api/v1/deployments", status_code=201)
async def record_deployment(event: DeploymentEvent):
    """
    Record a deployment event for DORA metrics calculation.

    Tracks:
    - Deployment frequency (deployments per day)
    - Lead time for changes (commit to deploy time)
    - Change failure rate (if status is failure)
    """
    try:
        # Increment deployment counter
        deployment_counter.labels(
            service=event.service,
            environment=event.environment,
            version=event.version,
            status=event.status
        ).inc()

        # Calculate and record lead time
        lead_time = (event.deployment_timestamp - event.commit_timestamp).total_seconds()
        lead_time_histogram.labels(
            service=event.service,
            environment=event.environment
        ).observe(lead_time)

        # Record failure if applicable
        if event.status == 'failure':
            failure_counter.labels(
                service=event.service,
                environment=event.environment,
                failure_type='deployment_failure'
            ).inc()

            logger.warning(
                f"Deployment failure recorded: {event.service} v{event.version} to {event.environment}"
            )
        else:
            logger.info(
                f"Deployment success recorded: {event.service} v{event.version} to {event.environment}"
            )

        return {
            "status": "recorded",
            "service": event.service,
            "metrics": {
                "deployment_frequency": "updated",
                "lead_time_seconds": round(lead_time, 2),
                "change_failure_rate": "updated" if event.status == 'failure' else "n/a"
            }
        }
    except Exception as e:
        logger.error(f"Error recording deployment: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/v1/incidents", status_code=201)
async def record_incident(event: IncidentEvent):
    """
    Record an incident for MTTR calculation.

    If caused by deployment, also increments change failure rate.
    If incident is ongoing (no resolved_at), updates active incidents gauge.
    """
    try:
        if event.resolved_at:
            # Calculate MTTR
            mttr = (event.resolved_at - event.started_at).total_seconds()
            mttr_histogram.labels(
                service=event.service,
                environment=event.environment,
                incident_type=event.incident_type
            ).observe(mttr)

            # Decrement active incidents
            active_incidents.labels(
                service=event.service,
                environment=event.environment
            ).dec()

            # If caused by deployment, count as change failure
            if event.caused_by_deployment:
                failure_counter.labels(
                    service=event.service,
                    environment=event.environment,
                    failure_type='incident_from_deployment'
                ).inc()

            logger.info(
                f"Incident resolved: {event.service} in {event.environment} "
                f"after {round(mttr/60, 2)} minutes"
            )

            return {
                "status": "resolved",
                "service": event.service,
                "mttr_seconds": round(mttr, 2),
                "mttr_minutes": round(mttr / 60, 2)
            }
        else:
            # Incident started but not resolved
            active_incidents.labels(
                service=event.service,
                environment=event.environment
            ).inc()

            logger.warning(
                f"Incident started: {event.service} in {event.environment} "
                f"(severity: {event.severity})"
            )

            return {
                "status": "incident_started",
                "service": event.service,
                "message": "Call again with resolved_at to calculate MTTR"
            }
    except Exception as e:
        logger.error(f"Error recording incident: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/v1/security-scan", status_code=201)
async def record_security_scan(scan: SecurityScanResult):
    """
    Record security scan results for tracking vulnerability trends.
    """
    logger.info(
        f"Security scan recorded: {scan.service} v{scan.version} - "
        f"Critical: {scan.critical_vulnerabilities}, High: {scan.high_vulnerabilities}"
    )

    return {
        "status": "recorded",
        "service": scan.service,
        "version": scan.version
    }

@app.get("/metrics")
async def metrics():
    """Prometheus metrics endpoint for scraping"""
    return Response(
        content=generate_latest(),
        media_type="text/plain"
    )

@app.get("/health")
async def health():
    """Health check for Kubernetes probes"""
    return {"status": "healthy"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        app,
        host="0.0.0.0",
        port=8080,
        log_level="info"
    )
```

### Deployment for DORA Metrics Service

```yaml
# File: infra/kubernetes/dora-metrics/deployment-dora-metrics.yaml

apiVersion: apps/v1
kind: Deployment
metadata:
  name: dora-metrics
  namespace: fawkes-platform
  labels:
    app: dora-metrics
    component: observability
spec:
  replicas: 2
  selector:
    matchLabels:
      app: dora-metrics
  template:
    metadata:
      labels:
        app: dora-metrics
    spec:
      containers:
        - name: dora-metrics
          image: python:3.11-slim
          workingDir: /app
          command:
            - python
            - main.py
          ports:
            - containerPort: 8080
              name: http
          resources:
            requests:
              memory: "128Mi"
              cpu: "100m"
            limits:
              memory: "256Mi"
              cpu: "200m"
          livenessProbe:
            httpGet:
              path: /health
              port: 8080
            initialDelaySeconds: 30
            periodSeconds: 10
          readinessProbe:
            httpGet:
              path: /health
              port: 8080
            initialDelaySeconds: 5
            periodSeconds: 5
          volumeMounts:
            - name: app-code
              mountPath: /app
      volumes:
        - name: app-code
          configMap:
            name: dora-metrics-code
---
apiVersion: v1
kind: Service
metadata:
  name: dora-metrics
  namespace: fawkes-platform
  labels:
    app: dora-metrics
spec:
  selector:
    app: dora-metrics
  ports:
    - name: http
      port: 8080
      targetPort: 8080
---
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: dora-metrics
  namespace: fawkes-platform
  labels:
    app: dora-metrics
spec:
  selector:
    matchLabels:
      app: dora-metrics
  endpoints:
    - port: http
      path: /metrics
      interval: 30s
```

### Grafana Dashboard for DORA Metrics

```json
{
  "dashboard": {
    "title": "Fawkes DORA Metrics",
    "tags": ["dora", "platform-metrics", "fawkes"],
    "timezone": "utc",
    "panels": [
      {
        "id": 1,
        "title": "Deployment Frequency",
        "type": "graph",
        "gridPos": { "x": 0, "y": 0, "w": 12, "h": 8 },
        "datasource": "Prometheus",
        "targets": [
          {
            "expr": "sum(rate(fawkes_deployments_total{status=\"success\"}[1d])) by (service)",
            "legendFormat": "{{service}}",
            "refId": "A"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "unit": "deployments/day"
          }
        },
        "thresholds": [
          { "value": 1, "color": "green" },
          { "value": 0.14, "color": "yellow" },
          { "value": 0.03, "color": "red" }
        ],
        "description": "Deployments per day. Elite: >1/day, High: weekly, Medium: monthly, Low: <monthly"
      },
      {
        "id": 2,
        "title": "Lead Time for Changes",
        "type": "graph",
        "gridPos": { "x": 12, "y": 0, "w": 12, "h": 8 },
        "datasource": "Prometheus",
        "targets": [
          {
            "expr": "histogram_quantile(0.5, rate(fawkes_lead_time_seconds_bucket[1h]))",
            "legendFormat": "P50 - {{service}}",
            "refId": "A"
          },
          {
            "expr": "histogram_quantile(0.95, rate(fawkes_lead_time_seconds_bucket[1h]))",
            "legendFormat": "P95 - {{service}}",
            "refId": "B"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "unit": "hours"
          }
        },
        "thresholds": [
          { "value": 3600, "color": "green" },
          { "value": 86400, "color": "yellow" },
          { "value": 604800, "color": "red" }
        ],
        "description": "Time from commit to production. Elite: <1 hour, High: <1 day, Medium: <1 week, Low: >1 month"
      },
      {
        "id": 3,
        "title": "Change Failure Rate",
        "type": "gauge",
        "gridPos": { "x": 0, "y": 8, "w": 12, "h": 8 },
        "datasource": "Prometheus",
        "targets": [
          {
            "expr": "sum(rate(fawkes_change_failures_total[7d])) / sum(rate(fawkes_deployments_total[7d])) * 100",
            "refId": "A"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "unit": "percent",
            "min": 0,
            "max": 100,
            "thresholds": {
              "mode": "absolute",
              "steps": [
                { "value": 0, "color": "green" },
                { "value": 15, "color": "yellow" },
                { "value": 30, "color": "red" }
              ]
            }
          }
        },
        "description": "% of deployments causing failures. Elite: <15%, High: <30%, Medium: <45%, Low: >45%"
      },
      {
        "id": 4,
        "title": "Mean Time to Restore (MTTR)",
        "type": "graph",
        "gridPos": { "x": 12, "y": 8, "w": 12, "h": 8 },
        "datasource": "Prometheus",
        "targets": [
          {
            "expr": "histogram_quantile(0.5, rate(fawkes_mttr_seconds_bucket[7d]))",
            "legendFormat": "P50 MTTR",
            "refId": "A"
          },
          {
            "expr": "histogram_quantile(0.95, rate(fawkes_mttr_seconds_bucket[7d]))",
            "legendFormat": "P95 MTTR",
            "refId": "B"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "unit": "hours"
          }
        },
        "thresholds": [
          { "value": 3600, "color": "green" },
          { "value": 86400, "color": "yellow" },
          { "value": 604800, "color": "red" }
        ],
        "description": "Time to restore service after incident. Elite: <1 hour, High: <1 day, Medium: <1 week, Low: >1 week"
      },
      {
        "id": 5,
        "title": "Active Incidents",
        "type": "stat",
        "gridPos": { "x": 0, "y": 16, "w": 6, "h": 4 },
        "datasource": "Prometheus",
        "targets": [
          {
            "expr": "sum(fawkes_active_incidents)",
            "refId": "A"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "unit": "incidents",
            "thresholds": {
              "mode": "absolute",
              "steps": [
                { "value": 0, "color": "green" },
                { "value": 1, "color": "yellow" },
                { "value": 3, "color": "red" }
              ]
            }
          }
        }
      },
      {
        "id": 6,
        "title": "Deployments Today",
        "type": "stat",
        "gridPos": { "x": 6, "y": 16, "w": 6, "h": 4 },
        "datasource": "Prometheus",
        "targets": [
          {
            "expr": "sum(increase(fawkes_deployments_total{status=\"success\"}[24h]))",
            "refId": "A"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "unit": "deployments"
          }
        }
      }
    ]
  }
}
```

---

## 🎓 Dojo Learning Integration

### Creating Dojo Module Content

When generating dojo learning modules, follow this structure:

```markdown
# File: docs/dojo/white-belt/module-01-what-is-idp.md

# Module 1: Internal Delivery Platforms - What and Why

**Belt Level**: 🥋 White Belt
**Duration**: 60 minutes
**Prerequisites**: Basic understanding of software development, Git, command line
**Learning Path**: Module 1 of 20 (White Belt: Modules 1-4)

---

## 📋 Module Overview

Welcome to the Fawkes Dojo! This is your first step toward becoming a platform engineer.

### Learning Objectives

By completing this module, you will be able to:

1. **Define** what an Internal Delivery Platform (IDP) is
2. **Explain** the difference between traditional infrastructure and platform engineering
3. **Identify** key components of Fawkes platform
4. **Describe** the business value and ROI of platform engineering
5. **Deploy** your first application using Fawkes (hands-on lab)

### Why This Matters

Platform engineering is one of the fastest-growing disciplines in technology.
Organizations with mature platforms:

- Deploy **10x more frequently**
- Have **50% lower change failure rates**
- Recover from incidents **2x faster**
- Save **30-40% in infrastructure costs**

### DORA Capabilities Covered

This module teaches:

- ✅ **Version control** - Understanding Git-based workflows
- ✅ **Deployment automation** - Self-service deployment
- ✅ **Loosely coupled architecture** - Microservices patterns

---

## 📚 Section 1: What is an Internal Delivery Platform?

### The Problem: Developer Cognitive Load

Imagine a developer starting a new microservice. Without a platform, they must:

1. Provision infrastructure (AWS console, navigation hell)
2. Set up CI/CD (write Jenkinsfile from scratch)
3. Configure observability (Prometheus, Grafana, dashboards)
4. Implement security (scanning tools, secrets management)
5. Set up deployment (Kubernetes manifests, Helm charts)
6. Configure networking (ingress, service mesh, DNS)
7. Manage databases (provision, backup, migrations)
8. Document everything (runbooks, architecture diagrams)

**Result**: 2-4 weeks before writing application code. High error rate. Inconsistent implementations.

### The Solution: Platform Engineering

**Platform Engineering** treats infrastructure and tooling as a product for internal customers (developers).

**Fawkes Platform** provides:

- **Self-service capabilities** - Deploy via Backstage portal
- **Golden paths** - Pre-configured, opinionated workflows
- **Automation** - CI/CD, deployment, monitoring automated
- **Standards** - Consistent security, observability, best practices
- **Developer experience** - Simple, fast, delightful interface

**Result**: Deploy new service in <1 hour. Consistent quality. Developers focus on business logic.

---

## 🛠️ Hands-On Lab: Deploy Your First Application

### Lab Objectives

- Use Backstage to create a new service from a template
- Trigger an automated build in Jenkins
- Deploy to development environment via ArgoCD
- View DORA metrics for your deployment

### Prerequisites

- Access to Fawkes platform (provided by instructor)
- GitHub account
- Basic familiarity with command line

### Step 1: Access Backstage

1. Navigate to `https://backstage.fawkes-platform.local`
2. Log in with your GitHub account
3. You should see the Fawkes developer portal home page

### Step 2: Create Service from Template

1. Click "Create" in the left sidebar
2. Select "Java Spring Boot Microservice" template
3. Fill in the form:
   - **Service Name**: `my-first-service`
   - **Description**: "Learning platform engineering with Fawkes"
   - **Owner**: (your name/team)
4. Click "Create"
5. Backstage will:
   - Create GitHub repository
   - Scaffold application code
   - Configure Jenkins pipeline
   - Set up ArgoCD application

### Step 3: Observe the Build

1. Click on "View in Jenkins" link
2. Watch the pipeline execute:
   - ✅ Checkout code
   - ✅ Build with Maven
   - ✅ Run tests
   - ✅ Security scan (SonarQube, Trivy)
   - ✅ Build container image
   - ✅ Push to Harbor registry

### Step 4: Monitor Deployment

1. Click on "View in ArgoCD" link
2. Watch ArgoCD sync your application:
   - ✅ Detects new image in registry
   - ✅ Updates Kubernetes manifests
   - ✅ Deploys to `dev` namespace
   - ✅ Runs health checks

### Step 5: View DORA Metrics

1. Navigate to Grafana dashboard: `https://grafana.fawkes-platform.local`
2. Open "DORA Metrics" dashboard
3. Find your service in the metrics:
   - **Deployment Frequency**: 1 deployment recorded
   - **Lead Time**: Time from template creation to deployment
   - **Change Failure Rate**: 0% (successful deployment)

### Step 6: Access Your Application

1. Get the application URL from ArgoCD
2. Visit `https://my-first-service.dev.fawkes-platform.local`
3. You should see the Spring Boot welcome page!

### Lab Complete! 🎉

Congratulations! You've:

- ✅ Created a service using a golden path template
- ✅ Triggered an automated CI/CD pipeline
- ✅ Deployed to Kubernetes via GitOps
- ✅ Generated DORA metrics automatically

**Time to deployment:** ~10 minutes (vs. 2-4 weeks manually)

---

## 📊 Assessment

Test your knowledge:

1. What is an Internal Delivery Platform?
2. Name three components of the Fawkes platform
3. What are the Four Key DORA metrics?
4. How does a platform reduce cognitive load for developers?

[Take the Module 1 Quiz →](/docs/dojo/white-belt/quiz-01.md)

---

## 🎯 Next Steps

**Continue Learning:**

- [Module 2: CI/CD Fundamentals](/docs/dojo/white-belt/module-02-cicd-fundamentals.md)
- [Module 3: GitOps with ArgoCD](/docs/dojo/white-belt/module-03-gitops.md)

**Practice More:**

- Create a Python service using the FastAPI template
- Explore the Backstage service catalog
- Review the generated Jenkins pipeline code

**Get Help:**

- Join `#dojo-white-belt` channel in Mattermost
- Ask questions in office hours (Wednesdays 2pm ET)
- Review the troubleshooting guide

---

## 📚 Additional Resources

- [Team Topologies Book](https://teamtopologies.com/) - Platform team patterns
- [Backstage Documentation](https://backstage.io/docs) - Developer portal
- [DORA Research](https://dora.dev/) - Four Key Metrics research
- [Fawkes Architecture](/docs/architecture.md) - Platform design
```

---

## 🔍 Code Review Guidelines

When reviewing generated code or suggesting improvements, check for:

### Platform Engineering Principles

- [ ] **Self-service enabled** - Can developers use without platform team help?
- [ ] **Opinionated defaults** - Does it follow the golden path?
- [ ] **Fail-fast validation** - Are errors caught early with clear messages?
- [ ] **Observable by default** - Are metrics, logs, traces included?
- [ ] **Secure by default** - Are security best practices enforced?

### DORA Capabilities Checklist

- [ ] **Continuous Integration** - Automated build/test on every commit?
- [ ] **Deployment Automation** - One-click or automated deployment?
- [ ] **Trunk-Based Development** - Short-lived branches (<1 day)?
- [ ] **Shift Left Security** - Scanning in CI pipeline?
- [ ] **Monitoring & Observability** - Metrics/logs/traces exported?

### Code Quality Standards

- [ ] **DRY (Don't Repeat Yourself)** - Use templates/modules
- [ ] **SOLID Principles** - Single responsibility, open/closed, etc.
- [ ] **12-Factor App** - Configuration via environment, stateless, etc.
- [ ] **Error Handling** - Graceful degradation, clear error messages
- [ ] **Documentation** - Inline comments for complex logic, README updates

### Fawkes-Specific Checks

- [ ] **Correct file location** - Follows repository structure?
- [ ] **Naming conventions** - Matches existing patterns?
- [ ] **No Spinnaker references** - Uses ArgoCD/Argo Rollouts instead
- [ ] **No fawkes.io domain** - Project is open source, not commercial
- [ ] **AWS first** - Multi-cloud is future, AWS is MVP focus
- [ ] **Mattermost integration** - Notifications go to Mattermost, not Slack

---

## 🚫 Things to AVOID

### Removed from MVP (Do NOT Generate)

- ❌ **Spinnaker** - Use ArgoCD + Argo Rollouts for progressive delivery
- ❌ **Eclipse Che** - Use local workspace automation (infra/workspace/)
- ❌ **fawkes.io domain** - No commercial domain, use fawkes-platform.local
- ❌ **Crossplane** (yet) - Use Terraform for AWS, Crossplane post-MVP
- ❌ **Service Mesh** (yet) - Basic Kubernetes networking for MVP
- ❌ **Multi-cloud** (yet) - AWS first, Azure/GCP later

### Anti-Patterns to Avoid

- ❌ Hardcoded secrets in manifests
- ❌ Using `:latest` image tags
- ❌ No resource limits on containers
- ❌ Imperative infrastructure commands
- ❌ Long-lived feature branches
- ❌ Manual deployment steps
- ❌ No observability instrumentation
- ❌ Copying code instead of using shared libraries

---

## 💡 Pro Tips for Using Copilot

### When Planning

1. **Start with the why** - "I need X because of DORA capability Y"
2. **Reference ADRs** - "As decided in ADR-003, we use ArgoCD"
3. **Check existing code** - "Look at templates/java-spring-boot for patterns"
4. **Ask for alternatives** - "What are 3 ways to implement this?"

### When Implementing

1. **Be specific about location** - "Create in infra/kubernetes/jenkins/"
2. **Request complete solutions** - "Include manifest, service, and ingress"
3. **Ask for tests** - "Also create BDD test in tests/e2e/features/"
4. **Think about docs** - "Update docs/components/jenkins.md too"

### When Debugging

1. **Provide context** - "Jenkins build fails at security scan stage"
2. **Share error messages** - Paste the actual error
3. **Describe expected vs actual** - "Should create Harbor repository but gets 404"
4. **Ask about DORA impact** - "How does this affect lead time metric?"

### Example Prompts

**Good Prompt:**

```
Create a Kubernetes Deployment for the Jenkins service in infra/kubernetes/jenkins/.
Requirements:
- Use jenkins/jenkins:lts-jdk17 image
- 2 replicas with PersistentVolumeClaim for /var/jenkins_home
- Resource limits: 2Gi memory, 1 CPU
- Liveness/readiness probes on port 8080
- ServiceAccount with RBAC for Kubernetes plugin
- Follow existing patterns from infra/kubernetes/backstage/

Also create:
- Service (NodePort on 8080, 50000)
- Ingress (jenkins.fawkes-platform.local)
- PersistentVolumeClaim (10Gi, ReadWriteOnce)

Include all in separate YAML files following naming convention.
```

**Bad Prompt:**

```
make jenkins work in kubernetes
```

---

## 📖 Reference: Key Technologies

### Technology Stack Summary

| Component                   | Technology       | Version | Purpose                         |
| --------------------------- | ---------------- | ------- | ------------------------------- |
| **Container Orchestration** | Kubernetes       | 1.28+   | Run all platform services       |
| **Developer Portal**        | Backstage        | 1.20+   | Self-service + dojo hub         |
| **CI/CD**                   | Jenkins          | LTS     | Build and test automation       |
| **GitOps**                  | ArgoCD           | 2.9+    | Continuous delivery             |
| **Progressive Delivery**    | Argo Rollouts    | 1.6+    | Canary/blue-green deployments   |
| **Container Registry**      | Harbor           | 2.10+   | Image storage + scanning        |
| **Collaboration**           | Mattermost       | 9.0+    | Team chat + ChatOps             |
| **Project Management**      | Focalboard       | 7.0+    | Sprint planning (in Mattermost) |
| **Metrics**                 | Prometheus       | 2.48+   | Time-series metrics             |
| **Dashboards**              | Grafana          | 10.0+   | Visualization                   |
| **Logging**                 | OpenSearch       | 2.11+   | Log aggregation                 |
| **Log Collection**          | Fluent Bit       | 2.2+    | Log forwarding                  |
| **Code Quality**            | SonarQube        | 10.0+   | SAST scanning                   |
| **Container Scanning**      | Trivy            | 0.48+   | Vulnerability scanning          |
| **Policy Enforcement**      | Kyverno          | 1.11+   | Kubernetes policies             |
| **Secrets**                 | External Secrets | 0.9+    | AWS Secrets Manager integration |
| **Infrastructure**          | Terraform        | 1.6+    | AWS provisioning                |
| **Database**                | PostgreSQL       | 15+     | Platform data persistence       |

### Important Endpoints

| Service    | URL                                        | Purpose            |
| ---------- | ------------------------------------------ | ------------------ |
| Backstage  | `https://backstage.fawkes-platform.local`  | Developer portal   |
| Jenkins    | `https://jenkins.fawkes-platform.local`    | CI/CD pipelines    |
| ArgoCD     | `https://argocd.fawkes-platform.local`     | GitOps deployments |
| Harbor     | `https://harbor.fawkes-platform.local`     | Container registry |
| Grafana    | `https://grafana.fawkes-platform.local`    | Dashboards         |
| Prometheus | `https://prometheus.fawkes-platform.local` | Metrics            |
| Mattermost | `https://mattermost.fawkes-platform.local` | Team collaboration |
| SonarQube  | `https://sonarqube.fawkes-platform.local`  | Code quality       |

### Default Namespaces

| Namespace                 | Purpose                   |
| ------------------------- | ------------------------- |
| `fawkes-platform`         | Core platform services    |
| `fawkes-dojo`             | Dojo learning labs        |
| `argocd`                  | ArgoCD controller         |
| `monitoring`              | Prometheus, Grafana       |
| `logging`                 | OpenSearch, Fluent Bit    |
| `external-secrets-system` | External Secrets Operator |
| `kyverno`                 | Policy enforcement        |

---

## 🎯 Quick Start Commands

### Common Development Tasks

```bash
# Provision AWS infrastructure
cd infra
../scripts/ignite.sh --provider aws dev

# Deploy platform components on current cluster
../scripts/ignite.sh --only-apps local

# Run tests
cd tests/e2e
pytest -v --tb=short

# Access Backstage locally (port-forward)
kubectl port-forward -n fawkes-platform svc/backstage 7007:7007

# View logs for a service
kubectl logs -n fawkes-platform -l app=jenkins -f

# Restart a deployment
kubectl rollout restart deployment/backstage -n fawkes-platform

# Sync ArgoCD application
argocd app sync backstage

# Get DORA metrics
curl http://dora-metrics.fawkes-platform.svc:8080/api/v1/metrics

# Access Grafana DORA dashboard
kubectl port-forward -n monitoring svc/grafana 3000:3000
# Open http://localhost:3000/d/dora-metrics
```

### Useful Kubectl Commands

```bash
# Get all platform services
kubectl get all -n fawkes-platform

# Check pod status
kubectl get pods -n fawkes-platform -o wide

# Describe a failing pod
kubectl describe pod <pod-name> -n fawkes-platform

# Check resource usage
kubectl top nodes
kubectl top pods -n fawkes-platform

# View events
kubectl get events -n fawkes-platform --sort-by='.lastTimestamp'

# Execute command in pod
kubectl exec -it <pod-name> -n fawkes-platform -- /bin/bash

# View logs with context
kubectl logs -n fawkes-platform <pod-name> --previous
kubectl logs -n fawkes-platform <pod-name> --tail=100 -f
```

---

## 🆘 Troubleshooting Guide

### Common Issues and Solutions

#### Issue: Jenkins build fails at security scan stage

```bash
# Check Trivy is installed in agent
kubectl exec -it <jenkins-agent-pod> -n fawkes-platform -- trivy --version

# Verify Harbor registry is accessible
kubectl exec -it <jenkins-agent-pod> -n fawkes-platform -- \
  curl -k https://harbor.fawkes-platform.svc

# Check if image was pushed successfully
curl -u robot-account:password \
  https://harbor.fawkes-platform.local/api/v2.0/projects/fawkes/repositories
```

#### Issue: ArgoCD not syncing application

```bash
# Check ArgoCD application status
kubectl get application -n argocd backstage -o yaml

# View sync operation logs
argocd app logs backstage

# Force sync
argocd app sync backstage --force

# Check if repository is accessible
argocd repo list
```

#### Issue: DORA metrics not appearing in Grafana

```bash
# Verify metrics service is running
kubectl get pods -n fawkes-platform -l app=dora-metrics

# Check if Prometheus is scraping metrics
kubectl port-forward -n monitoring svc/prometheus 9090:9090
# Visit http://localhost:9090/targets

# Test metrics endpoint directly
kubectl exec -it <prometheus-pod> -n monitoring -- \
  curl http://dora-metrics.fawkes-platform.svc:8080/metrics

# Check Grafana datasource configuration
kubectl get configmap -n monitoring grafana-datasources -o yaml
```

#### Issue: Cannot access Backstage portal

```bash
# Check ingress configuration
kubectl get ingress -n fawkes-platform

# Verify DNS resolution
nslookup backstage.fawkes-platform.local

# Check certificate (if using TLS)
kubectl get certificate -n fawkes-platform

# View Backstage logs
kubectl logs -n fawkes-platform -l app=backstage --tail=50
```

---

## 📝 Documentation Standards

When creating or updating documentation:

### Structure

```markdown
# Title (H1 - One per document)

**Metadata**: Version, Last Updated, Status, Audience

## Overview (H2)

- Brief description
- Purpose and scope
- Prerequisites

## Table of Contents (if >3 sections)

## Main Content (H2 sections)

- Clear headings
- Code examples with language tags
- Screenshots where helpful
- Links to related docs

## Troubleshooting (H2)

- Common issues
- Error messages and solutions

## Additional Resources (H2)

- External links
- Related documentation
- Contact information
```

### Code Examples

- Always include file path: `# File: path/to/file.yaml`
- Use proper syntax highlighting: `yaml,`bash, ```python
- Add comments explaining non-obvious parts
- Include DORA capability annotations
- Show complete, runnable examples

### Linking

- Use relative links for internal docs: `[Architecture](../architecture.md)`
- Use absolute URLs for external resources
- Check links don't break when docs move

---

## 🎓 Belt-Specific Guidelines

### White Belt (Beginner)

- Focus on concepts, not complexity
- Provide step-by-step instructions
- Include lots of screenshots
- Explain every command
- Use simple, working examples

### Yellow Belt (Intermediate)

- Introduce complexity gradually
- Explain trade-offs and alternatives
- Encourage exploration
- Provide troubleshooting guidance
- Include performance considerations

### Green Belt (Advanced)

- Assume foundational knowledge
- Focus on advanced patterns
- Discuss architectural decisions
- Include optimization techniques
- Reference ADRs and best practices

### Brown Belt (Expert)

- Multi-component integration
- Production considerations
- Disaster recovery scenarios
- Performance tuning
- Custom implementations

### Black Belt (Master)

- Platform architecture design
- Multi-tenancy patterns
- Cost optimization strategies
- Mentoring and teaching
- Contributing to Fawkes core

---

## 🔄 Continuous Improvement

### Contributing to Copilot Instructions

Found a pattern that works well? Submit a PR to improve these instructions!

```bash
# Fork the repository
git clone https://github.com/paruff/fawkes.git
cd fawkes

# Create a branch
git checkout -b improve-copilot-instructions

# Edit the file
# (This file should be at .github/copilot-instructions.md or similar)

# Commit with clear message
git commit -am "Add pattern for X to Copilot instructions"

# Push and create PR
git push origin improve-copilot-instructions
```

### Feedback Loop

After using these instructions:

1. **What worked well?** - Share successful patterns
2. **What was confusing?** - Help clarify ambiguous sections
3. **What's missing?** - Suggest new sections or examples
4. **What's outdated?** - Update deprecated practices

Post feedback in:

- GitHub Discussion: https://github.com/paruff/fawkes/discussions
- Mattermost: `#platform-engineering` channel
- Weekly office hours: Wednesdays 2pm ET

---

## 📊 Success Metrics

Track how well Copilot is helping:

- **Time to first PR** - How quickly can new contributors submit code?
- **Code review cycles** - Fewer cycles = better adherence to patterns
- **Test coverage** - Are tests being generated automatically?
- **Documentation freshness** - Are docs updated with code changes?
- **DORA metrics** - Is generated code improving platform performance?

---

## 🏁 Summary

**Key Takeaways:**

1. ✅ Fawkes uses an established structure - respect it
2. ✅ AWS first, multi-cloud later - don't over-abstract
3. ✅ ArgoCD replaces Spinnaker - use Argo Rollouts for progressive delivery
4. ✅ Mattermost, not Slack - all notifications go to Mattermost
5. ✅ DORA metrics are first-class - instrument everything
6. ✅ Security from the start - scanning, policies, secrets management
7. ✅ Dojo learning is core - create educational content
8. ✅ GitOps workflow - all changes through Git

**Remember:**

- Check existing patterns before creating new ones
- Follow the repository structure exactly
- Tag code with DORA capabilities and belt levels
- Include tests with all new features
- Update documentation when code changes
- Ask when uncertain about placement or approach

**Your Goal:**
Help build Fawkes into the world's best open-source Internal Product Delivery Platform,
where developers learn platform engineering while deploying production-grade infrastructure.

---

**Version:** 1.0.0
**Last Updated:** October 26, 2025
**Maintained By:** Fawkes Platform Team
**Questions?** Open a [GitHub Discussion](https://github.com/paruff/fawkes/discussions)
