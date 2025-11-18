Every directory should have a README.md explaining its purpose:

infra/kubernetes/jenkins/README.md:
````markdown
# Jenkins CI/CD Service

## Purpose
Jenkins provides automated build, test, and deployment pipelines for all Fawkes applications.

## Files
- `deployment-jenkins.yaml` - Main Jenkins controller
- `service-jenkins.yaml` - Service exposing ports 8080 (web) and 50000 (agents)
- `configmap-casc.yaml` - Jenkins Configuration as Code
- `persistentvolume-jenkins.yaml` - Storage for job history

## Configuration
- Kubernetes plugin for dynamic agents
- GitHub integration for webhooks
- Harbor integration for image storage
- Mattermost plugin for notifications

## Dependencies
- PostgreSQL (job history)
- Harbor (artifact storage)
- GitHub (source code)

## DORA Capabilities
- Continuous Integration
- Deployment Automation
- Test Automation
````

**AI Benefit**: Copilot reads READMEs for context when generating code in that directory.

---

## 🧪 Testing: The AI Confidence Engine

### 1. Behavior-Driven Development (BDD) with Gherkin

**Why BDD for AI?** Gherkin is:
- Human-readable (you can review easily)
- Machine-parseable (AI can generate/validate)
- Spec-first (define behavior before implementation)
- Living documentation (tests = docs)
````gherkin
# File: tests/e2e/features/deployment_pipeline.feature

@dora-deployment-frequency @dora-lead-time
Feature: Automated Deployment Pipeline
  As a developer
  I want my code changes to deploy automatically
  So that I can deliver value to users quickly

  Background:
    Given a Jenkins instance is running
    And an ArgoCD instance is configured
    And the "demo-app" repository exists
    And GitHub webhooks are configured

  @smoke @critical-path
  Scenario: Code commit triggers full deployment
    Given I have checked out the "demo-app" repository
    When I commit a change to the "main" branch
    Then a Jenkins build starts within 30 seconds
    And the build runs unit tests
    And the build runs integration tests
    And the build scans for security vulnerabilities
    And the build creates a container image
    And the image is pushed to Harbor registry
    And ArgoCD detects the new image
    And ArgoCD deploys to the "dev" environment
    And the deployment completes within 10 minutes
    And health checks pass
    And DORA metrics are recorded

  @security @compliance
  Scenario: Deployment fails when security scan finds critical vulnerabilities
    Given I have a service with critical CVEs in dependencies
    When I commit the code
    Then the Jenkins build starts
    And the security scan stage executes
    And Trivy finds critical vulnerabilities
    And the pipeline fails with clear error message
    And a Mattermost notification is sent
    And the DORA failure metric is incremented
    And the deployment does NOT proceed

  @rollback @resilience
  Scenario: Failed deployment automatically rolls back
    Given a successful deployment of "v1.0.0" in production
    When I deploy "v1.1.0" with a failing health check
    Then ArgoCD detects the health check failure
    And ArgoCD automatically rolls back to "v1.0.0"
    And a Mattermost alert is sent
    And MTTR timer starts
    When the rollback completes
    Then MTTR timer stops
    And MTTR metric is recorded
````

**AI Benefit**:
- Copilot can generate step definitions from scenarios
- Copilot can generate scenarios from user stories
- You get executable specs that AI validates

### 2. Test Pyramid with AI Generation
````python
# File: tests/conftest.py
# Pytest configuration that AI understands

import pytest
from typing import Generator

# ====================================
# FIXTURES: AI can reference these
# ====================================

@pytest.fixture(scope="session")
def kubernetes_cluster():
    """Provides access to test Kubernetes cluster"""
    from kubernetes import client, config
    config.load_kube_config()
    return client.CoreV1Api()

@pytest.fixture(scope="session")
def jenkins_client():
    """Provides authenticated Jenkins API client"""
    from jenkinsapi.jenkins import Jenkins
    return Jenkins(
        'http://jenkins.fawkes-platform.svc:8080',
        username='robot-account',
        password=os.getenv('JENKINS_TOKEN')
    )

@pytest.fixture(scope="function")
def clean_namespace(kubernetes_cluster) -> Generator[str, None, None]:
    """Creates and cleans up a test namespace"""
    namespace = f"test-{uuid.uuid4().hex[:8]}"

    # Create namespace
    kubernetes_cluster.create_namespace(
        body=client.V1Namespace(metadata=client.V1ObjectMeta(name=namespace))
    )

    yield namespace

    # Cleanup
    kubernetes_cluster.delete_namespace(namespace)

# ====================================
# MARKERS: AI uses these for categorization
# ====================================

def pytest_configure(config):
    """Register custom markers for AI to use"""
    config.addinivalue_line("markers", "unit: Unit tests (fast, no external deps)")
    config.addinivalue_line("markers", "integration: Integration tests (medium, external deps)")
    config.addinivalue_line("markers", "e2e: End-to-end tests (slow, full system)")
    config.addinivalue_line("markers", "smoke: Smoke tests (critical path only)")
    config.addinivalue_line("markers", "security: Security-focused tests")
    config.addinivalue_line("markers", "performance: Performance/load tests")

    # DORA capability markers
    config.addinivalue_line("markers", "dora-deployment-frequency: Tests deployment frequency")
    config.addinivalue_line("markers", "dora-lead-time: Tests lead time for changes")
    config.addinivalue_line("markers", "dora-change-failure-rate: Tests change failure detection")
    config.addinivalue_line("markers", "dora-mttr: Tests mean time to restore")

    # Belt level markers for dojo
    config.addinivalue_line("markers", "white-belt: White belt curriculum tests")
    config.addinivalue_line("markers", "yellow-belt: Yellow belt curriculum tests")
    config.addinivalue_line("markers", "green-belt: Green belt curriculum tests")
    config.addinivalue_line("markers", "brown-belt: Brown belt curriculum tests")
    config.addinivalue_line("markers", "black-belt: Black belt curriculum tests")

# ====================================
# HOOKS: AI understands test lifecycle
# ====================================

def pytest_collection_modifyitems(config, items):
    """
    Auto-tag tests based on path and enhance with metadata.
    AI can rely on this for automatic categorization.
    """
    for item in items:
        # Auto-tag based on directory
        if "tests/unit" in str(item.fspath):
            item.add_marker(pytest.mark.unit)
        elif "tests/integration" in str(item.fspath):
            item.add_marker(pytest.mark.integration)
        elif "tests/e2e" in str(item.fspath):
            item.add_marker(pytest.mark.e2e)

        # Add DORA context based on test name
        test_name = item.name.lower()
        if "deploy" in test_name:
            item.add_marker(pytest.mark.dora_deployment_frequency)
        if "commit" in test_name or "lead_time" in test_name:
            item.add_marker(pytest.mark.dora_lead_time)
        if "fail" in test_name or "rollback" in test_name:
            item.add_marker(pytest.mark.dora_change_failure_rate)
        if "incident" in test_name or "restore" in test_name or "mttr" in test_name:
            item.add_marker(pytest.mark.dora_mttr)
````

**AI Benefit**: Copilot generates tests that automatically get proper markers and fixtures.

### 3. Property-Based Testing for Infrastructure
````python
# File: tests/integration/test_kubernetes_manifests.py
# AI can generate property tests

from hypothesis import given, strategies as st
import yaml

@given(
    replicas=st.integers(min_value=1, max_value=10),
    memory_request=st.integers(min_value=128, max_value=2048),
    cpu_request=st.integers(min_value=100, max_value=2000)
)
def test_deployment_manifest_is_valid(replicas, memory_request, cpu_request):
    """
    Property test: Any valid combination of replicas and resources
    should produce a valid Kubernetes manifest.

    AI Benefit: Tests edge cases you might not think of.
    """
    manifest = generate_deployment_manifest(
        replicas=replicas,
        memory_request_mi=memory_request,
        cpu_request_millicores=cpu_request
    )

    # Parse as YAML
    parsed = yaml.safe_load(manifest)

    # Validate structure
    assert parsed['kind'] == 'Deployment'
    assert parsed['spec']['replicas'] == replicas

    # Validate resource limits are higher than requests
    container = parsed['spec']['template']['spec']['containers'][0]
    assert int(container['resources']['limits']['memory'].rstrip('Mi')) >= memory_request
    assert int(container['resources']['limits']['cpu'].rstrip('m')) >= cpu_request
````

---

## 📋 User Stories: Executable Specifications

### 1. Story Template That AI Understands
````markdown
# File: docs/stories/STORY-001-developer-onboarding.md

## Story ID: STORY-001
**Title**: Developer Self-Service Onboarding
**Epic**: Developer Experience
**Priority**: P0 (Critical)
**Sprint**: Sprint 01
**Status**: In Progress

## User Story
**As a** new developer joining the team
**I want** to provision my own development environment with one click
**So that** I can start contributing code on my first day without waiting for ops tickets

## Acceptance Criteria (Testable)

### AC1: Environment Provisioning
**Given** I have access to Backstage portal
**When** I click "Create New Environment"
**Then** a Kubernetes namespace is created within 60 seconds
**And** I receive the connection details via email
**And** the environment includes:
  - PostgreSQL database (dev size)
  - Redis cache
  - S3 bucket (or equivalent)
  - Pre-configured secrets

### AC2: Service Templates Available
**Given** my environment is provisioned
**When** I navigate to the "Create Service" page
**Then** I see templates for:
  - Java Spring Boot
  - Python FastAPI
  - Node.js Express
  - Go Gin
**And** each template has a preview and description

### AC3: Automated CI/CD Setup
**Given** I select a service template
**When** I fill in the service details and click "Create"
**Then** within 5 minutes:
  - GitHub repository is created
  - Jenkins pipeline is configured
  - ArgoCD application is set up
  - First deployment completes successfully
  - I receive a Mattermost notification with links

## DORA Impact
- **Deployment Frequency**: ↑ Removes manual setup time
- **Lead Time**: ↓ Developers productive day 1
- **Change Failure Rate**: ↓ Standardized, tested templates
- **MTTR**: ↓ Consistent environments easier to debug

## Technical Notes
- Use Backstage software templates
- Leverage ArgoCD ApplicationSets
- Terraform for AWS resources
- External Secrets for credentials

## Definition of Done
- [ ] All acceptance criteria pass automated tests
- [ ] BDD scenarios written and passing
- [ ] Documentation updated (getting started guide)
- [ ] Demo video recorded
- [ ] Reviewed by 2 team members
- [ ] Deployed to staging and validated
- [ ] Metrics dashboard shows successful onboarding

## Related
- **Blocks**: STORY-002 (needs this environment to test)
- **Depends On**: ADR-002 (Backstage), ADR-003 (ArgoCD)
- **Dojo Module**: White Belt Module 1

## Test Scenarios (Gherkin)
See: `tests/e2e/features/developer_onboarding.feature`
````

**AI Benefit**:
- Copilot can generate the feature file from the story
- Copilot can generate step definitions from acceptance criteria
- Copilot can create test data based on "Given" clauses

### 2. Story-to-Code Workflow
````bash
# Step 1: Create story (human writes)
docs/stories/STORY-001-developer-onboarding.md

# Step 2: AI generates feature file
# Prompt: "Create BDD feature file from STORY-001"
tests/e2e/features/developer_onboarding.feature

# Step 3: AI generates step definitions
# Prompt: "Generate pytest-bdd steps for developer_onboarding.feature"
tests/e2e/step_definitions/onboarding_steps.py

# Step 4: Run tests (they fail - no implementation)
pytest tests/e2e/features/developer_onboarding.feature
# Result: Red tests

# Step 5: AI generates implementation
# Prompt: "Implement Backstage template to make onboarding tests pass"
templates/environment-template/template.yaml
infra/kubernetes/backstage/templates/

# Step 6: Run tests (they pass)
pytest tests/e2e/features/developer_onboarding.feature
# Result: Green tests

# Step 7: AI updates docs
# Prompt: "Update getting-started.md with new onboarding flow"
docs/getting-started.md
````

---

## 🔄 CI/CD: Rapid Feedback Loops

### 1. Fast Feedback Pipeline
````yaml
# File: .github/workflows/pr-validation.yml
# AI-friendly CI pipeline with clear stages

name: Pull Request Validation

on:
  pull_request:
    branches: [main]

jobs:
  # ============================================
  # STAGE 1: Fast Checks (< 2 minutes)
  # ============================================
  fast-checks:
    name: Fast Checks
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      # Copilot understands these checks
      - name: Lint YAML files
        run: |
          pip install yamllint
          yamllint -c .yamllint infra/ tests/

      - name: Validate Kubernetes manifests
        run: |
          kubectl-validate infra/kubernetes/**/*.yaml

      - name: Check Terraform formatting
        run: |
          cd infra/terraform
          terraform fmt -check -recursive

      - name: Markdown lint
        run: |
          npm install -g markdownlint-cli
          markdownlint docs/**/*.md

      - name: Check for secrets
        run: |
          pip install detect-secrets
          detect-secrets scan --all-files

      # AI knows these should pass quickly
      - name: Fast unit tests
        run: |
          pytest tests/unit -m "not slow" --maxfail=5

  # ============================================
  # STAGE 2: Build & Security (5-7 minutes)
  # ============================================
  build-and-scan:
    name: Build and Security Scan
    runs-on: ubuntu-latest
    needs: fast-checks
    steps:
      - uses: actions/checkout@v4

      - name: Build container images
        run: |
          docker build -t fawkes/test:${{ github.sha }} .

      - name: Trivy vulnerability scan
        uses: aquasecurity/trivy-action@master
        with:
          image-ref: fawkes/test:${{ github.sha }}
          severity: HIGH,CRITICAL
          exit-code: 1

      - name: SonarQube static analysis
        env:
          SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
        run: |
          sonar-scanner \
            -Dsonar.projectKey=fawkes \
            -Dsonar.sources=. \
            -Dsonar.host.url=${{ secrets.SONAR_URL }}

  # ============================================
  # STAGE 3: Integration Tests (10-15 minutes)
  # ============================================
  integration-tests:
    name: Integration Tests
    runs-on: ubuntu-latest
    needs: build-and-scan
    services:
      postgres:
        image: postgres:15
        env:
          POSTGRES_PASSWORD: test
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
      redis:
        image: redis:7
        options: >-
          --health-cmd "redis-cli ping"
          --health-interval 10s
    steps:
      - uses: actions/checkout@v4

      - name: Run integration tests
        env:
          POSTGRES_HOST: postgres
          REDIS_HOST: redis
        run: |
          pytest tests/integration \
            --junitxml=integration-results.xml \
            --cov=. \
            --cov-report=xml

  # ============================================
  # STAGE 4: E2E Tests (20-30 minutes)
  # ============================================
  e2e-tests:
    name: End-to-End Tests
    runs-on: ubuntu-latest
    needs: integration-tests
    steps:
      - uses: actions/checkout@v4

      - name: Create kind cluster
        uses: helm/kind-action@v1

      - name: Deploy platform components
        run: |
          ./infra/buildplatform.sh --test-mode

      - name: Run BDD tests
        run: |
          pytest tests/e2e \
            --gherkin-terminal-reporter \
            --junitxml=e2e-results.xml \
            --html=e2e-report.html

      - name: Upload test report
        if: always()
        uses: actions/upload-artifact@v3
        with:
          name: e2e-test-report
          path: e2e-report.html

  # ============================================
  # STAGE 5: DORA Metrics Collection
  # ============================================
  collect-metrics:
    name: Collect DORA Metrics
    runs-on: ubuntu-latest
    needs: [fast-checks, build-and-scan, integration-tests, e2e-tests]
    if: always()
    steps:
      - name: Calculate lead time
        run: |
          # Time from first commit to PR ready
          COMMIT_TIME=$(git log --format=%ct -1 ${{ github.event.pull_request.base.sha }})
          NOW=$(date +%s)
          LEAD_TIME=$((NOW - COMMIT_TIME))
          echo "Lead time: $LEAD_TIME seconds"

      - name: Record test results
        run: |
          # Send to DORA metrics service
          curl -X POST https://dora-metrics.fawkes.local/api/v1/pr-metrics \
            -H "Content-Type: application/json" \
            -d '{
              "pr_number": "${{ github.event.pull_request.number }}",
              "lead_time_seconds": "'$LEAD_TIME'",
              "tests_passed": "${{ job.status == 'success' }}",
              "commit_sha": "${{ github.sha }}"
            }'
````

**AI Benefit**:
- Copilot knows the pipeline structure
- Can suggest fixes for failing stages
- Understands where tests belong
- Can add new checks in the right stage

### 2. Pre-commit Hooks for Instant Feedback
````yaml
# File: .pre-commit-config.yaml
# Catches issues before commit

repos:
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.5.0
    hooks:
      - id: trailing-whitespace
      - id: end-of-file-fixer
      - id: check-yaml
        args: ['--allow-multiple-documents']
      - id: check-added-large-files
        args: ['--maxkb=500']
      - id: check-json
      - id: detect-private-key
      - id: mixed-line-ending

  - repo: https://github.com/adrienverge/yamllint
    rev: v1.33.0
    hooks:
      - id: yamllint
        args: ['-c', '.yamllint']

  - repo: https://github.com/antonbabenko/pre-commit-terraform
    rev: v1.86.0
    hooks:
      - id: terraform_fmt
      - id: terraform_validate
      - id: terraform_docs

  - repo: https://github.com/psf/black
    rev: 23.12.1
    hooks:
      - id: black
        language_version: python3.11

  - repo: https://github.com/PyCQA/flake8
    rev: 7.0.0
    hooks:
      - id: flake8
        args: ['--max-line-length=100']

  - repo: local
    hooks:
      - id: pytest-quick
        name: Run quick unit tests
        entry: pytest tests/unit -m "not slow" --maxfail=1
        language: system
        pass_filenames: false
        always_run: true
````

**Install with**:
````bash
pip install pre-commit
pre-commit install
````

**AI Benefit**: Copilot-generated code is validated before commit, creating a tight feedback loop.

---

## 📖 Documentation: AI-Readable Context

### 1. Architecture Decision Records (ADRs)
````markdown
# File: docs/adr/ADR-009-testing-strategy.md

# ADR-009: Testing Strategy for Fawkes Platform

## Status
Accepted

## Context
We need a comprehensive testing strategy that:
- Catches bugs early in development
- Supports AI-assisted development (Copilot needs clear test patterns)
- Provides fast feedback (<5 minutes for most tests)
- Validates DORA capabilities
- Supports dojo learning (tests as examples)

## Decision
We will implement a **5-layer test pyramid**:

### Layer 1: Unit Tests (Fast - seconds)
- **What**: Individual functions/classes in isolation
- **Tools**: pytest with mocks
- **Coverage**: >80% of business logic
- **Run**: On every save (IDE), pre-commit hook, CI
- **AI Role**: Generate tests from docstrings

### Layer 2: Integration Tests (Medium - minutes)
- **What**: Multiple components together with real dependencies
- **Tools**: pytest with testcontainers
- **Coverage**: All external integrations (DB, APIs, services)
- **Run**: Pre-push, CI pull requests
- **AI Role**: Generate tests from API contracts

### Layer 3: Contract Tests (Medium - minutes)
- **What**: API contracts between services
- **Tools**: Pact, Schemathesis
- **Coverage**: All service-to-service communication
- **Run**: CI pull requests
- **AI Role**: Generate contracts from OpenAPI specs

### Layer 4: E2E Tests (Slow - tens of minutes)
- **What**: Full user workflows across system
- **Tools**: pytest-bdd with Gherkin
- **Coverage**: Critical paths, DORA capabilities
- **Run**: CI pull requests, nightly
- **AI Role**: Generate scenarios from user stories

### Layer 5: Chaos/Load Tests (Slowest - hours)
- **What**: System behavior under stress/failure
- **Tools**: k6, Chaos Mesh
- **Coverage**: Resilience patterns
- **Run**: Nightly, pre-release
- **AI Role**: Generate load scenarios from SLOs

## Test Organization
````
tests/
├── unit/                      # Layer 1
│   ├── test_jenkins_api.py
│   └── test_dora_metrics.py
├── integration/               # Layer 2
│   ├── test_backstage_templates.py
│   └── test_argocd_sync.py
├── contract/                  # Layer 3
│   ├── pacts/
│   └── test_api_contracts.py
├── e2e/                       # Layer 4
│   ├── features/
│   └── step_definitions/
└── chaos/                     # Layer 5
    ├── scenarios/
    └── test_resilience.py