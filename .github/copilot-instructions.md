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
4. **Open source, self-hosted** - No vendor lock-in
5. **Platform as a product** - Developer experience first

### Architecture Overview
```
┌─────────────────────────────────────────────────────────┐
│                    Fawkes Platform                       │
├─────────────────────────────────────────────────────────┤
│  Developer Portal (Backstage)                            │
│  ├── Service Catalog                                     │
│  ├── Software Templates (Golden Paths)                   │
│  ├── TechDocs (Documentation)                            │
│  └── Dojo Learning Hub (Modules, Labs, Progress)        │
├─────────────────────────────────────────────────────────┤
│  Infrastructure Layer (Kubernetes)                       │
│  ├── Jenkins (CI/CD Pipelines)                          │
│  ├── ArgoCD (GitOps Continuous Delivery)                │
│  ├── Harbor (Container Registry + Scanning)             │
│  ├── Mattermost (Team Collaboration)                    │
│  ├── Focalboard (Project Management)                    │
│  └── Observability (Prometheus, Grafana, OpenSearch)    │
├─────────────────────────────────────────────────────────┤
│  Cloud Infrastructure (Multi-Cloud)                      │
│  ├── Terraform/Crossplane (IaC)                         │
│  ├── Kubernetes Clusters (AWS, Azure, GCP)              │
│  └── Networking, Storage, Security                      │
└─────────────────────────────────────────────────────────┘
```

---

## 📁 Fawkes Repository Structure (Current)

**Use this structure for all file generation:**
```
fawkes/
├── docs/                          # Documentation (existing)
│   ├── dojo/                      # Learning system content
│   ├── adr/                       # Architecture Decision Records
│   └── architecture.md
│
├── infrastructure/                # Infrastructure as Code (existing)
│   ├── terraform/                 # Cloud provider IaC
│   │   ├── aws/
│   │   ├── azure/
│   │   └── gcp/
│   ├── kubernetes/                # K8s manifests
│   │   ├── backstage/
│   │   ├── jenkins/
│   │   ├── argocd/
│   │   └── [other-services]/
│   └── helm/                      # Helm charts (if used)
│
├── templates/                     # Application templates (or create 'apps/')
│   ├── java-spring-boot/
│   ├── python-fastapi/
│   └── nodejs-express/
│
├── tests/                         # Automated tests (create when ready)
│   └── e2e/
│       ├── features/
│       └── step_definitions/
│
├── scripts/                       # Utility scripts (existing)
└── .github/                       # GitHub config (existing)
```

**File Naming Conventions:**
- Kubernetes: `<resource>-<name>.yaml` (e.g., `deployment-backstage.yaml`)
- Terraform: `main.tf`, `variables.tf`, `outputs.tf`
- Keep existing naming if already established
### File Naming Conventions
- **Kubernetes manifests:** `<resource>-<name>.yaml` (e.g., `deployment-backstage.yaml`)
- **Terraform modules:** `main.tf`, `variables.tf`, `outputs.tf`
- **Python tests:** `test_<feature>.py`
- **Feature files:** `<capability>.feature` (lowercase, underscores)
- **Helm charts:** `Chart.yaml`, `values.yaml`, `templates/`


## 🔧 Working with Existing Structure

**IMPORTANT:** Fawkes uses an evolving directory structure. When generating code:

1. **Check existing patterns first** - Look at current file locations before creating new ones
2. **Ask before major moves** - Don't restructure without explicit request
3. **Use relative paths** - Make code work regardless of exact structure
4. **Document location decisions** - Add comments explaining file placement

Example:
```python
# Place this in: infrastructure/kubernetes/monitoring/prometheus-config.yaml
# Rationale: Follows existing infrastructure/kubernetes/<service>/ pattern
```

### Future Structure (Post-MVP)
We plan to evolve toward:
- `/infra` (shorter, more common)
- `/apps` (clearer than templates)
- `/platform` (separate platform services)

But this is NOT a priority for MVP. Focus on functionality, not perfect organization.
---

## 🎓 DORA Capabilities Integration

### The 24 Key Capabilities
Every code change should map to one or more DORA capabilities:

#### Technical Practices
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

#### Process Practices
15. **Streamlined change approval** - Peer review, not CAB
16. **Customer feedback** - Short feedback loops
17. **Team experimentation** - Safe to try new approaches
18. **Work in small batches** - Small, frequent changes
19. **Visibility of work in value stream** - Clear status tracking
20. **Work in process limits** - Focus, avoid multitasking

#### Cultural Practices
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
# Work for weeks...
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
apiVersion: apps/v1
kind: Deployment
metadata:
  name: fawkes-api
  labels:
    app: fawkes-api
    version: v1.2.3
    dora-metric: deployment-frequency
spec:
  replicas: 3
  selector:
    matchLabels:
      app: fawkes-api
  template:
    metadata:
      labels:
        app: fawkes-api
        version: v1.2.3
    spec:
      containers:
      - name: api
        image: harbor.fawkes.local/fawkes/api:v1.2.3
        resources:
          requests:
            memory: "256Mi"
            cpu: "100m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /ready
            port: 8080
          initialDelaySeconds: 5
          periodSeconds: 5
        env:
        - name: ENVIRONMENT
          value: "production"
        - name: LOG_LEVEL
          value: "info"
```

```python
# ❌ Bad: Imperative approach
import subprocess

subprocess.run([
    "kubectl", "create", "deployment", "fawkes-api",
    "--image=fawkes/api:v1.2.3",
    "--replicas=3"
])
subprocess.run([
    "kubectl", "expose", "deployment", "fawkes-api",
    "--port=8080"
])
```

### 3. GitOps Workflow

**All changes through Git:**

```yaml
# ArgoCD Application for automated deployment
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: fawkes-api
  namespace: argocd
  annotations:
    dora-capability: continuous_delivery
spec:
  project: default
  source:
    repoURL: https://github.com/paruff/fawkes.git
    targetRevision: main
    path: infra/platform/k8s/api
  destination:
    server: https://kubernetes.default.svc
    namespace: fawkes-api
  syncPolicy:
    automated:
      prune: true      # Delete resources not in Git
      selfHeal: true   # Revert manual changes
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

---

## 🧪 Testing Strategy

### BDD Test Structure

**Always create Gherkin feature files:**

```gherkin
# tests/e2e/features/continuous_integration.feature

@dora-deployment-frequency @dora-lead-time
Feature: Continuous Integration Pipeline
  As a developer
  I want automated build and test pipelines
  So that I can quickly validate changes
  
  Background:
    Given a Jenkins instance is running
    And the "spring-boot-template" exists
    And GitHub webhooks are configured
  
  @smoke @white-belt
  Scenario: Commit triggers automatic build
    Given I have cloned the "demo-java-app" repository
    When I commit a change to the "main" branch
    Then a Jenkins build starts within 30 seconds
    And the build completes within 5 minutes
    And the build status is reported to GitHub
    And the commit shows a green checkmark
  
  @yellow-belt
  Scenario: Pipeline includes security scanning
    Given a Jenkins pipeline for "demo-python-app"
    When the build stage completes successfully
    Then the security scan stage executes
    And Trivy scans the container image
    And SonarQube analyzes the source code
    And no HIGH or CRITICAL vulnerabilities are found
    And a security report is generated
  
  @green-belt @dora-change-failure-rate
  Scenario: Failed builds notify team immediately
    Given a Jenkins pipeline for "demo-node-app"
    When a build fails due to test failures
    Then a Mattermost notification is sent within 60 seconds
    And the notification includes the failure reason
    And the notification links to the build logs
    And the DORA metrics service records the failure
```

**Step definitions with proper instrumentation:**

```python
# tests/e2e/step_definitions/jenkins_steps.py

from pytest_bdd import given, when, then, parsers
from datetime import datetime, timedelta
import requests
import time

@given(parsers.parse('a Jenkins instance is running'))
def jenkins_running(jenkins_client):
    """
    Verify Jenkins is accessible and healthy.
    
    @dora-capability: continuous_integration
    """
    response = jenkins_client.get('/api/json')
    assert response.status_code == 200, "Jenkins not accessible"
    assert response.json()['mode'] == 'NORMAL', "Jenkins not in normal mode"

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
    
    # Record commit time for DORA metrics
    dora_metrics.record_commit(
        commit_sha=commit.hexsha,
        timestamp=datetime.utcnow(),
        service=git_repo.name
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
                timestamp=builds[0].timestamp,
                service=git_repo.name
            )
            return
        time.sleep(2)
    
    raise AssertionError(
        f"No build started within {seconds}s of commit. "
        f"This impacts deployment frequency SLA."
    )

@then(parsers.parse('the DORA metrics service records the failure'))
def record_failure(dora_metrics, git_repo):
    """
    Record failure for change failure rate calculation.
    
    @dora-metric: change_failure_rate
    """
    dora_metrics.record_failure(
        service=git_repo.name,
        timestamp=datetime.utcnow(),
        failure_type='build_failure'
    )
```

### Test Organization

```python
# tests/e2e/conftest.py

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

### 1. Container Scanning

**Integrate Trivy in all pipelines:**

```groovy
// Jenkinsfile

@Library('fawkes-shared-library') _

pipeline {
  agent {
    kubernetes {
      yaml '''
        apiVersion: v1
        kind: Pod
        spec:
          containers:
          - name: trivy
            image: aquasec/trivy:latest
            command: ['cat']
            tty: true
          - name: docker
            image: docker:24-dind
            securityContext:
              privileged: true
      '''
    }
  }
  
  environment {
    REGISTRY = credentials('harbor-credentials')
    IMAGE_NAME = "harbor.fawkes.local/fawkes/${env.JOB_NAME}"
    IMAGE_TAG = "${env.GIT_COMMIT.take(8)}"
  }
  
  stages {
    stage('Build') {
      steps {
        container('docker') {
          sh '''
            docker build -t ${IMAGE_NAME}:${IMAGE_TAG} .
            docker tag ${IMAGE_NAME}:${IMAGE_TAG} ${IMAGE_NAME}:latest
          '''
        }
      }
    }
    
    stage('Security Scan') {
      steps {
        container('trivy') {
          // Scan for vulnerabilities
          sh '''
            trivy image \
              --severity HIGH,CRITICAL \
              --exit-code 1 \
              --no-progress \
              --format json \
              --output trivy-report.json \
              ${IMAGE_NAME}:${IMAGE_TAG}
          '''
        }
      }
      post {
        always {
          // Archive scan results
          archiveArtifacts artifacts: 'trivy-report.json'
          
          // Send to DORA metrics service
          sh '''
            curl -X POST http://dora-metrics:8080/api/v1/security-scan \
              -H "Content-Type: application/json" \
              -d @trivy-report.json
          '''
        }
        failure {
          mattermostSend(
            color: 'danger',
            message: """
              🚨 Security vulnerabilities found in ${IMAGE_NAME}:${IMAGE_TAG}
              Build: ${env.BUILD_URL}
              Action: Fix vulnerabilities before deployment
            """
          )
        }
      }
    }
    
    stage('Push') {
      when {
        expression { currentBuild.result != 'FAILURE' }
      }
      steps {
        container('docker') {
          sh '''
            echo ${REGISTRY_PSW} | docker login -u ${REGISTRY_USR} --password-stdin harbor.fawkes.local
            docker push ${IMAGE_NAME}:${IMAGE_TAG}
            docker push ${IMAGE_NAME}:latest
          '''
        }
      }
    }
  }
}
```

### 2. Policy Enforcement

**Use Kyverno for policy-as-code:**

```yaml
# infra/platform/k8s/kyverno/require-resource-limits.yaml

apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: require-resource-limits
  annotations:
    policies.kyverno.io/title: Require Resource Limits
    policies.kyverno.io/category: Best Practices
    policies.kyverno.io/severity: medium
    policies.kyverno.io/description: >-
      Containers must have resource limits to prevent resource exhaustion.
      This is a DORA best practice for system reliability.
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
    validate:
      message: >-
        CPU and memory limits are required for all containers.
        This ensures predictable resource usage and prevents noisy neighbor issues.
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

### 3. Secrets Management

**Never hardcode secrets - use External Secrets Operator:**

```yaml
# infra/platform/k8s/external-secrets/database-credentials.yaml

apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: postgres-credentials
  namespace: fawkes-api
  annotations:
    dora-capability: shift_left_on_security
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: vault-backend
    kind: ClusterSecretStore
  target:
    name: postgres-credentials
    creationPolicy: Owner
    template:
      engineVersion: v2
      data:
        # Template for connection string
        DATABASE_URL: "postgresql://{{ .username }}:{{ .password }}@postgres:5432/fawkes"
  data:
  - secretKey: username
    remoteRef:
      key: database/postgres
      property: username
  - secretKey: password
    remoteRef:
      key: database/postgres
      property: password
```

---

## 📊 DORA Metrics Implementation

### Metrics Collection Service

**Create a lightweight service for collecting DORA metrics:**

```python
# dojo-metrics/src/collector.py

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from datetime import datetime
from typing import Literal, Optional
import prometheus_client
from prometheus_client import Counter, Histogram, Gauge

app = FastAPI(title="Fawkes DORA Metrics Collector")

# Prometheus metrics
deployment_counter = Counter(
    'deployments_total',
    'Total number of deployments',
    ['service', 'environment', 'version', 'status']
)

lead_time_histogram = Histogram(
    'lead_time_seconds',
    'Lead time from commit to deployment',
    ['service', 'environment'],
    buckets=[60, 300, 900, 1800, 3600, 7200, 14400, 28800, 86400]  # 1m to 1d
)

failure_counter = Counter(
    'change_failures_total',
    'Total number of failed changes',
    ['service', 'environment', 'failure_type']
)

mttr_histogram = Histogram(
    'mttr_seconds',
    'Mean time to restore service',
    ['service', 'environment', 'incident_type'],
    buckets=[300, 900, 1800, 3600, 7200, 14400, 28800, 86400]  # 5m to 1d
)

class DeploymentEvent(BaseModel):
    service: str
    version: str
    environment: Literal['dev', 'staging', 'production']
    commit_sha: str
    commit_timestamp: datetime
    deployment_timestamp: datetime
    status: Literal['success', 'failure']
    
class IncidentEvent(BaseModel):
    service: str
    environment: Literal['dev', 'staging', 'production']
    incident_type: str
    started_at: datetime
    resolved_at: Optional[datetime] = None
    caused_by_deployment: Optional[str] = None  # Commit SHA

@app.post("/api/v1/deployments")
async def record_deployment(event: DeploymentEvent):
    """
    Record a deployment event for DORA metrics.
    
    Tracks:
    - Deployment frequency (deployments per day)
    - Lead time for changes (commit to deploy time)
    - Change failure rate (if status is failure)
    """
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
    
    return {
        "status": "recorded",
        "metrics": {
            "deployment_frequency": "updated",
            "lead_time_seconds": lead_time,
            "change_failure_rate": "updated" if event.status == 'failure' else "n/a"
        }
    }

@app.post("/api/v1/incidents")
async def record_incident(event: IncidentEvent):
    """
    Record an incident for MTTR calculation.
    
    If caused by deployment, also increments change failure rate.
    """
    if event.resolved_at:
        # Calculate MTTR
        mttr = (event.resolved_at - event.started_at).total_seconds()
        mttr_histogram.labels(
            service=event.service,
            environment=event.environment,
            incident_type=event.incident_type
        ).observe(mttr)
        
        # If caused by deployment, count as change failure
        if event.caused_by_deployment:
            failure_counter.labels(
                service=event.service,
                environment=event.environment,
                failure_type='incident_from_deployment'
            ).inc()
        
        return {
            "status": "recorded",
            "mttr_seconds": mttr
        }
    else:
        return {
            "status": "incident_started",
            "message": "Call again with resolved_at to calculate MTTR"
        }

@app.get("/metrics")
async def metrics():
    """Prometheus metrics endpoint"""
    return prometheus_client.generate_latest()

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8080)
```

### Grafana Dashboard

**Create comprehensive DORA dashboard:**

```json
{
  "dashboard": {
    "title": "Fawkes DORA Metrics",
    "tags": ["dora", "platform-metrics"],
    "timezone": "utc",
    "panels": [
      {
        "title": "Deployment Frequency",
        "type": "graph",
        "datasource": "Prometheus",
        "targets": [
          {
            "expr": "rate(deployments_total{status=\"success\"}[1d])",
            "legendFormat": "{{service}} - {{environment}}"
          }
        ],
        "description": "Deployments per day (rolling average). Elite: >1/day",
        "thresholds": [
          {"value": 1, "color": "green", "fill": false},
          {"value": 0.14, "color": "yellow"},
          {"value": 0.03, "color": "red"}
        ]
      },
      {
        "title": "Lead Time for Changes",
        "type": "graph",
        "datasource": "Prometheus",
        "targets": [
          {
            "expr": "histogram_quantile(0.5, rate(lead_time_seconds_bucket[1h]))",
            "legendFormat": "P50 - {{service}}"
          },
          {
            "expr": "histogram_quantile(0.95, rate(lead_time_seconds_bucket[1h]))",
            "legendFormat": "P95