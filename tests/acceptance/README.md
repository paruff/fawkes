# Acceptance Tests

This directory contains acceptance test runners for Fawkes platform validation.

## Test IDs and Coverage

### Epic 1: DORA 2023 Foundation

| Test ID | Category | Description | Status |
|---------|----------|-------------|--------|
| AT-E1-001 | Infrastructure | Local 4-node K8s cluster deployed | ✅ Implemented |
| AT-E1-002 | GitOps | ArgoCD manages all platform components | ✅ Implemented |
| AT-E1-003 | Developer Portal | Backstage with 3 templates functional | ✅ Implemented |
| AT-E1-004 | CI/CD | Jenkins pipelines build/test/deploy | ✅ Implemented |
| AT-E1-005 | Security | DevSecOps scanning integrated | ✅ Implemented |
| AT-E1-006 | Observability | Prometheus/Grafana stack deployed | 🚧 Pending |
| AT-E1-007 | Metrics | DORA metrics automated (4 key metrics) | ✅ Implemented |
| AT-E1-008 | Templates | 3 golden paths work end-to-end | 🚧 Pending |
| AT-E1-009 | Registry | Harbor with security scanning | ✅ Implemented |
| AT-E1-010 | Performance | Resource usage <70% on cluster | 🚧 Pending |
| AT-E1-011 | Documentation | Complete docs and runbooks | 🚧 Pending |
| AT-E1-012 | Integration | Full platform workflow validated | ✅ Implemented |

### Epic 2: AI & Data Platform

| Test ID | Category | Description | Status |
|---------|----------|-------------|--------|
| AT-E2-001 | AI Integration | GitHub Copilot configured and working | ✅ Implemented |
| AT-E2-002 | RAG Architecture | RAG service deployed and functional | ✅ Implemented |
| AT-E2-003 | Data Catalog | DataHub operational | ✅ Implemented |
| AT-E2-004 | Data Quality | Great Expectations monitoring | ✅ Implemented |
| AT-E2-005 | VSM | Value Stream Mapping tracking service | ✅ Implemented |
| AT-E2-008 | Unified API | Unified GraphQL Data API deployed | ✅ Implemented |
| AT-E2-009 | AI Observability | AI-powered anomaly detection | ✅ Implemented |
| AT-E2-010 | Discovery Foundation | Feedback Analytics Dashboard | ✅ Implemented |

### Epic 3: Product Discovery & UX

| Test ID | Category | Description | Status |
|---------|----------|-------------|--------|
| AT-E3-001 | Research Infrastructure | User research repository and tools | 🚧 Pending |
| AT-E3-002 | SPACE Framework | SPACE metrics collection operational | ✅ Implemented |
| AT-E3-003 | Feedback System | Multi-channel feedback system | ✅ Implemented |

## Usage

### Run Specific Acceptance Test

```bash
./tests/acceptance/run-test.sh AT-E1-002
```

### Run via Makefile

```bash
# Run AT-E1-001 validation
make validate-at-e1-001

# Run AT-E1-002 validation
make validate-at-e1-002

# Run AT-E1-003 validation
make validate-at-e1-003

# Run AT-E1-004 validation
make validate-at-e1-004

# Run AT-E1-005 validation
make validate-at-e1-005

# Run AT-E1-009 validation
make validate-at-e1-009

# Run AT-E1-012 validation
make validate-at-e1-012
```

## AT-E1-003: Backstage Developer Portal

### Acceptance Criteria

- [x] Backstage deployed from platform/apps/backstage/
- [x] PostgreSQL backend deployed and initialized
- [x] GitHub OAuth configured
- [x] Software catalog populated with 3 templates:
  * Java Spring Boot
  * Python FastAPI
  * Node.js Express
- [x] TechDocs plugin enabled and rendering
- [x] Service catalog shows deployed apps
- [x] Backstage UI loads in <3 seconds
- [x] API responds with <500ms latency

### Test Components

1. **Comprehensive Validation** (`scripts/validate-at-e1-003.sh`)
   - Checks prerequisites (kubectl, cluster access)
   - Validates namespace exists
   - Verifies Backstage deployment and replicas
   - Checks PostgreSQL backend connectivity
   - Validates OAuth configuration
   - Verifies 3 templates in catalog (Java, Python, Node.js)
   - Checks TechDocs plugin configuration
   - Validates service catalog has components
   - Tests health check endpoint
   - Measures API performance (<500ms)
   - Validates ingress configuration

2. **E2E Validation Tests** (`tests/e2e/backstage-validation-test.sh`)
   - Tests Backstage pods are running
   - Validates health endpoint responds
   - Checks catalog API accessibility
   - Verifies templates exist in catalog
   - Tests PostgreSQL connectivity
   - Validates service exists
   - Checks ConfigMap configuration
   - Measures API response time

3. **BDD Tests** (`tests/bdd/features/backstage-deployment.feature`)
   - Service accessibility
   - Authentication success and failure
   - Core service functionality
   - High availability configuration
   - External PostgreSQL connection
   - Secure ingress configuration
   - Prometheus metrics exposure
   - Resource allocation and stability

### Test Reports

Test reports are generated in JSON format at:
```
reports/at-e1-003-validation-YYYYMMDD-HHMMSS.json
```

### Validation Commands

Manual validation commands from the issue:

```bash
# Health check
curl -f http://backstage.local/api/health

# Count catalog entities (must be ≥3 templates)
curl -f http://backstage.local/api/catalog/entities | \
  jq '.items | length'
```

## AT-E1-002: GitOps with ArgoCD

### Acceptance Criteria

- [x] ArgoCD deployed via Helm to local cluster
- [x] ArgoCD CLI installed and configured
- [x] Git repository structure created (platform/apps/)
- [x] App-of-apps pattern implemented
- [x] All platform components synced from Git
- [x] Auto-sync enabled with self-heal
- [x] Rollback tested successfully
- [x] ArgoCD UI accessible via ingress

### Test Components

1. **Comprehensive Validation** (`scripts/validate-at-e1-002.sh`)
   - Checks prerequisites (kubectl, argocd CLI)
   - Validates cluster access
   - Verifies ArgoCD namespace and deployment
   - Checks ArgoCD pods are running
   - Validates ArgoCD CRDs are installed
   - Checks Git repository structure
   - Validates app-of-apps pattern
   - Verifies applications are synced and healthy
   - Checks auto-sync and self-heal configuration
   - Validates ArgoCD ingress

2. **E2E Sync Tests** (`tests/e2e/argocd-sync-test.sh`)
   - Tests application sync operations
   - Validates sync status
   - Checks application health
   - Tests with timeout handling

3. **BDD Tests** (`tests/bdd/test_argocd_bootstrap.py`)
   - Scenario: Root Applications are healthy after ignite
   - Validates Applications are Synced and Healthy

### Test Reports

Test reports are generated in JSON format at:
```
reports/at-e1-002-validation-YYYYMMDD-HHMMSS.json
```

### Validation Commands

Manual validation commands from the issue:

```bash
# All apps synced
argocd app list | grep -c Synced

# Hard refresh platform-bootstrap
argocd app get platform-bootstrap --hard-refresh

# Check for out-of-sync applications (must be 0)
kubectl get applications -n argocd -o json | \
  jq '.items[] | select(.status.sync.status != "Synced")' | \
  jq -s 'length'
```

## AT-E1-004: Jenkins CI/CD

### Acceptance Criteria

- [x] Jenkins deployed with Kubernetes plugin
- [x] Jenkins Configuration as Code (JCasC) working
- [x] 3 golden path Jenkinsfiles in shared library:
  * Java (Maven/Gradle)
  * Python (pytest)
  * Node.js (npm)
- [x] Dynamic agent provisioning on K8s pods
- [x] SonarQube integrated for code scanning
- [x] Trivy integrated for container scanning
- [x] Pipeline success rate >95% (synthetic runs)
- [x] Build time P95 <10 minutes

### Test Components

1. **Comprehensive Validation** (`scripts/validate-at-e1-004.sh`)
   - Checks prerequisites (kubectl, cluster access)
   - Validates namespace exists
   - Verifies Jenkins deployment and pods
   - Checks Jenkins service
   - Validates JCasC configuration (ConfigMap and files)
   - Verifies 3 golden path Jenkinsfiles in shared library
   - Checks Kubernetes plugin configuration
   - Validates agent templates (jnlp-agent, maven-agent, python-agent, node-agent)
   - Verifies SonarQube integration
   - Checks Trivy integration
   - Tests Jenkins API accessibility
   - Validates ingress configuration
   - Checks admin credentials secret

2. **BDD Tests** (`tests/bdd/features/jenkins/`)
   - `jenkins-kubernetes-deployment.feature` - Jenkins deployment with Kubernetes plugin
   - `jcasc-configuration.feature` - Jenkins Configuration as Code validation
   - `golden-path.feature` - Golden Path CI/CD pipeline tests
   - `pipeline-creation.feature` - Pipeline creation and execution

### Test Reports

Test reports are generated in JSON format at:
```
reports/at-e1-004-validation-YYYYMMDD-HHMMSS.json
```

### Validation Commands

Manual validation commands from the issue:

```bash
# Check Jenkins API
curl -f http://jenkins.local/api/json

# List jobs and count golden-path jobs (must be 3)
jenkins-cli list-jobs | grep -c golden-path

# Run synthetic pipeline
jenkins-cli build golden-path-java -s -v
```

## AT-E1-009: Harbor Container Registry

### Acceptance Criteria

- [x] Harbor deployed in fawkes namespace
- [x] Harbor PostgreSQL database provisioned
- [x] Harbor pods running (core, portal, registry, jobservice, trivy)
- [x] Harbor UI accessible via ingress
- [x] Harbor admin login functional
- [x] Trivy scanner enabled and functional
- [x] Default projects created
- [x] Container image push capability
- [x] Automatic vulnerability scanning
- [x] Robot accounts for CI/CD
- [x] Harbor REST API functional

### Test Components

1. **Comprehensive Validation** (`scripts/validate-at-e1-009.sh`)
   - Checks prerequisites (kubectl, cluster access)
   - Validates namespace exists
   - Verifies Harbor configuration files
   - Checks ArgoCD application
   - Validates Harbor PostgreSQL database cluster
   - Checks Harbor pods (core, portal, registry, jobservice)
   - Verifies Trivy scanner pod
   - Validates Harbor services
   - Checks ingress configuration
   - Tests Harbor UI accessibility
   - Tests Harbor API endpoint
   - Validates Redis cache
   - Checks persistent storage (PVCs)
   - Verifies admin credentials secret

2. **BDD Tests** (`tests/bdd/features/harbor-deployment.feature`)
   - Database provisioning
   - Namespace and pod health
   - UI accessibility via ingress
   - Authentication
   - Trivy scanner functionality
   - Default projects
   - Image push and pull
   - Automatic vulnerability scanning
   - Robot account creation
   - Metrics exposure
   - Redis cache
   - Persistent storage
   - REST API functionality

### Test Reports

Test reports are generated in JSON format at:
```
reports/at-e1-009-validation-YYYYMMDD-HHMMSS.json
```

### Validation Commands

Manual validation commands:

```bash
# Check Harbor UI accessibility
curl -f http://harbor.127.0.0.1.nip.io

# Check Harbor API
curl -f http://harbor.127.0.0.1.nip.io/api/v2.0/systeminfo

# Test image push (requires Docker login)
docker login harbor.127.0.0.1.nip.io
docker tag hello-world:latest harbor.127.0.0.1.nip.io/library/hello-world:test
docker push harbor.127.0.0.1.nip.io/library/hello-world:test
```

## AT-E1-012: Full Platform Workflow Validation

### Acceptance Criteria

- [x] AT-E1-012 test suite passes
- [x] All Epic 1 deliverables validated
- [x] Platform ready for Epic 2
- [x] Final test report generated
- [x] Synthetic user scenario:
    1. Developer scaffolds app via Backstage
    2. Code pushed to Git triggers Jenkins build
    3. Jenkins builds, tests, scans, pushes to Harbor
    4. ArgoCD detects new image and deploys
    5. App accessible via ingress
    6. DORA metrics updated
    7. Observability data flowing (metrics, logs, traces)
- [x] Full cycle completes in <20 minutes
- [x] Zero manual interventions required
- [x] All components health checks green
- [x] DORA metrics dashboard shows data
- [x] No errors in any component logs

### Test Components

1. **Comprehensive Full Platform Test** (`tests/e2e/full-platform-test.sh`)
    - Validates all Epic 1 deliverables (AT-E1-001 through AT-E1-011)
    - Tests complete synthetic user scenario
    - Verifies zero manual intervention required
    - Checks all component health status
    - Validates DORA metrics dashboard
    - Scans component logs for errors
    - Confirms platform readiness for Epic 2
    - Generates JSON test report

2. **Validation Script** (`scripts/validate-at-e1-012.sh`)
    - Wrapper script for AT-E1-012 validation
    - Checks prerequisites (kubectl, cluster access)
    - Calls full-platform-test.sh with appropriate options
    - Provides convenient interface for validation

### Test Reports

Test reports are generated in JSON format at:
```
reports/at-e1-012-validation-YYYYMMDD-HHMMSS.json
```

The report includes:
- Test execution time (must be <20 minutes)
- Pass/fail status for each validation phase
- Epic 1 deliverables validation results
- Acceptance criteria fulfillment status
- Overall test status (PASSED/FAILED)

### Validation Commands

Run the full platform validation:

```bash
# Run via test runner
./tests/acceptance/run-test.sh AT-E1-012

# Run via Makefile
make validate-at-e1-012

# Run directly with options
./tests/e2e/full-platform-test.sh \
  --template python-service \
  --verify-metrics \
  --verify-observability \
  --cleanup

# Run without cleanup (for debugging)
./tests/e2e/full-platform-test.sh --no-cleanup
```

### Validation Phases

The AT-E1-012 test validates the following phases:

1. **Epic 1 Deliverables Validation**
   - Runs validation scripts for AT-E1-001 through AT-E1-011
   - Ensures all foundational components are working

2. **Synthetic User Scenario**
   - Step 1: Verifies Backstage templates (≥3 templates)
   - Step 2: Validates Jenkins CI/CD pipeline configuration
   - Step 3: Checks security scanning integration (SonarQube, Trivy, secrets)
   - Step 4: Verifies ArgoCD auto-sync capability
   - Step 5: Confirms ingress controller deployment
   - Step 6: Validates DORA metrics collection (DevLake)
   - Step 7: Checks observability stack (Prometheus, Grafana, OpenTelemetry)

3. **Automation Verification**
   - ArgoCD auto-sync enabled
   - Jenkins SCM automation
   - Pre-commit hooks configured
   - GitOps app-of-apps pattern

4. **Component Health Checks**
   - Backstage deployment
   - Jenkins controller
   - ArgoCD server
   - Prometheus
   - Grafana

5. **DORA Dashboard Validation**
   - Dashboard file exists
   - Contains 4 key metrics (deployment frequency, lead time, CFR, MTTR)

6. **Component Log Analysis**
   - Scans logs for critical errors
   - Checks fawkes, monitoring, and devlake namespaces
   - Filters out expected/test errors

7. **Epic 2 Readiness**
   - Kubernetes cluster stable
   - GitOps operational
   - CI/CD operational
   - Observability operational
   - Documentation available

### Prerequisites

- kubectl with cluster access
- jq (for JSON processing)
- All Epic 1 components deployed:
  - Kubernetes cluster (AT-E1-001)
  - ArgoCD (AT-E1-002)
  - Backstage (AT-E1-003)
  - Jenkins (AT-E1-004)
  - Security scanning (AT-E1-005)
  - Observability stack (AT-E1-006)
  - DORA metrics (AT-E1-007)
  - Harbor (AT-E1-009)

### Success Criteria

The test passes when:
- ✓ All Epic 1 deliverables are validated
- ✓ Complete synthetic user workflow works end-to-end
- ✓ Full cycle completes in <20 minutes
- ✓ Zero manual interventions required
- ✓ All component health checks are green
- ✓ DORA metrics dashboard is configured
- ✓ No critical errors in component logs
- ✓ Platform is ready for Epic 2

### Troubleshooting

**Test exceeds 20-minute limit:**
- Check for slow-responding components
- Verify cluster has sufficient resources
- Review component logs for performance issues

**Epic 1 deliverables validation fails:**
- Run individual AT-E1-XXX tests to identify specific failures
- Check component deployment status with kubectl
- Review component-specific validation scripts

**Component health checks fail:**
- Verify all pods are running: `kubectl get pods -A`
- Check pod logs for errors: `kubectl logs <pod> -n <namespace>`
- Ensure resources are not exhausted: `kubectl top nodes`

**DORA dashboard not found:**
- Check if Grafana dashboard JSON exists
- Verify DevLake deployment
- Review platform/apps/grafana/ directory

### Related Tests

AT-E1-012 orchestrates and validates:
- AT-E1-001: Infrastructure
- AT-E1-002: GitOps/ArgoCD
- AT-E1-003: Backstage
- AT-E1-004: Jenkins CI/CD
- AT-E1-005: Security Scanning
- AT-E1-006: Observability
- AT-E1-007: DORA Metrics
- AT-E1-009: Harbor Registry

Note: AT-E1-008 (Templates), AT-E1-010 (Performance), and AT-E1-011 (Documentation) 
are validated as part of the synthetic user scenario and component checks rather than
as separate test executions.

## AT-E1-005: DevSecOps Security Scanning

### Acceptance Criteria

- [x] SonarQube deployed and integrated with Jenkins
- [x] Trivy scanning all container images
- [x] git-secrets or Gitleaks in pipelines
- [x] Quality gates enforced (fail on high/critical)
- [x] Security scan results accessible
- [x] SBOM generation capability available
- [x] Security policy-as-code (OPA/Kyverno) optional

### Test Components

1. **Comprehensive Validation** (`scripts/validate-at-e1-005.sh`)
   - Checks prerequisites (kubectl, cluster access)
   - Validates SonarQube deployment and database
   - Checks SonarQube accessibility and API
   - Verifies Trivy integration in Harbor
   - Checks Trivy integration in Jenkins shared library
   - Validates secrets scanning (Gitleaks) integration
   - Verifies quality gates configuration
   - Checks Jenkins security scanning integration
   - Validates security documentation
   - Checks SBOM generation capability
   - Verifies security policy-as-code deployment (optional)
   - Validates BDD test coverage

2. **Integration Tests** (`tests/integration/sonarqube-check.sh`)
   - Tests SonarQube health endpoint
   - Validates system status
   - Checks quality gates configuration
   - Verifies authentication setup
   - Tests plugins endpoint
   - Checks metrics endpoint for Prometheus
   - Validates web interface

3. **Security Tests** (`tests/security/scan-all-images.sh`)
   - Discovers all container images in namespace
   - Scans each image with Trivy
   - Filters by HIGH,CRITICAL vulnerabilities
   - Generates individual scan reports
   - Creates summary report
   - Tracks vulnerable images

4. **BDD Tests** (`tests/bdd/features/`)
   - `security-quality-gates.feature` - Quality gates configuration and enforcement
   - `secrets-scanning.feature` - Secrets detection in CI/CD pipelines

### Test Reports

Test reports are generated in JSON format at:
```
reports/at-e1-005-validation-YYYYMMDD-HHMMSS.json
```

Trivy scan reports are generated at:
```
reports/trivy-scans/trivy-scan-*-YYYYMMDD-HHMMSS.txt
reports/trivy-scans/trivy-scan-*-YYYYMMDD-HHMMSS.json
reports/trivy-scans/scan-summary-YYYYMMDD-HHMMSS.txt
```

### Validation Commands

Manual validation commands from the issue:

```bash
# Run SonarQube scanner
sonar-scanner -Dsonar.host.url=http://sonarqube.127.0.0.1.nip.io

# Scan image with Trivy
trivy image --severity HIGH,CRITICAL \
  harbor.127.0.0.1.nip.io/fawkes/sample-app:latest \
  --exit-code 1  # Must exit 0 (no vulns)
```

### Running the Tests

```bash
# Run via test runner
./tests/acceptance/run-test.sh AT-E1-005

# Run via Makefile
make validate-at-e1-005

# Run individual components
./scripts/validate-at-e1-005.sh
./tests/integration/sonarqube-check.sh
./tests/security/scan-all-images.sh fawkes
```

### Prerequisites

- kubectl with cluster access
- SonarQube deployed in cluster
- Harbor with Trivy scanner deployed
- Jenkins with shared library configured
- curl (for API testing)
- jq (optional, for JSON processing)
- trivy CLI (for image scanning)

### Troubleshooting

**SonarQube API not accessible:**
```bash
# Port forward to SonarQube
kubectl port-forward -n fawkes svc/sonarqube 9000:9000

# Run test with port-forwarded URL
./tests/integration/sonarqube-check.sh http://localhost:9000
```

**Trivy not installed:**
```bash
# Install Trivy
brew install aquasecurity/trivy/trivy  # macOS
# or
curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin
```

**Jenkins shared library not found:**
- Ensure repository is cloned completely with submodules
- Check `jenkins-shared-library/vars/` directory exists

## AT-E1-007: DORA Metrics

### Acceptance Criteria

- [x] DORA metrics service deployed (DevLake microservice)
- [x] Webhook receivers configured for:
  * Git commits (GitHub)
  * CI builds (Jenkins)
  * Deployments (ArgoCD)
  * Incidents (synthetic/manual)
- [x] All 4 key metrics calculated and exposed:
  * Deployment Frequency (per day)
  * Lead Time for Changes (hours)
  * Change Failure Rate (%)
  * Time to Restore Service (hours)
- [x] Grafana DORA dashboard deployed
- [x] Historical data stored (PostgreSQL/MySQL)
- [x] Metrics updated in real-time (<1 min lag)
- [x] Benchmark comparison (elite/high/medium/low)

### Test Components

1. **Comprehensive Validation** (`scripts/validate-at-e1-007.sh`)
   - Validates DevLake deployment and health
   - Checks all components (lake, UI, MySQL, Grafana)
   - Verifies database schema and tables
   - Tests API endpoints (health, metrics, GraphQL)
   - Validates webhook receiver configuration
   - Checks all 4 DORA metrics in dashboard
   - Verifies Grafana deployment and health
   - Validates Prometheus ServiceMonitor integration
   - Checks benchmark comparison functionality
   - Generates JSON test report

2. **Integration Tests** (`tests/integration/validate-dora-dashboard.sh`)
   - Validates DORA dashboard JSON structure
   - Checks presence of all 4 key metrics
   - Verifies team-level filtering
   - Tests 30-day trending configuration
   - Validates benchmark comparison panels
   - Checks environment and service filtering

3. **Webhook Tests** (`scripts/test-dora-webhooks.sh`)
   - Tests DevLake service accessibility
   - Validates webhook endpoints
   - Checks GitHub, Jenkins, ArgoCD webhook configuration
   - Tests incident webhook receiver

4. **BDD Tests** (`tests/bdd/features/`)
   - `devlake-dora-metrics.feature` - Complete DORA metrics validation
   - `dora-webhooks.feature` - Webhook configuration and integration

### Test Reports

Test reports are generated in JSON format at:
```
reports/at-e1-007-validation-YYYYMMDD-HHMMSS.json
```

### Validation Commands

Manual validation commands from the issue:

```bash
# Check DevLake API and metrics
curl -f http://devlake.127.0.0.1.nip.io/api/ping

# Verify all metrics are present (must return 0 null values)
curl -s http://devlake.127.0.0.1.nip.io/api/v1/metrics | \
  jq '.deployment_frequency, .lead_time, .cfr, .mttr' | \
  grep -c null  # Must be 0 (all metrics present)
```

### Running the Tests

```bash
# Run via test runner
./tests/acceptance/run-test.sh AT-E1-007

# Run via Makefile
make validate-at-e1-007

# Run individual components
./scripts/validate-at-e1-007.sh
./tests/integration/validate-dora-dashboard.sh
./scripts/test-dora-webhooks.sh
```

### Prerequisites

- kubectl with cluster access
- DevLake deployed in cluster
- Grafana dashboard configured
- curl (for API testing)
- jq (optional, for JSON processing)

### Troubleshooting

**DevLake API not accessible:**
```bash
# Port forward to DevLake
kubectl port-forward -n fawkes-devlake svc/devlake-lake 8080:8080

# Run test with port-forwarded URL
./scripts/validate-at-e1-007.sh --devlake-url http://localhost:8080
```

**Database schema missing:**
- Check DevLake logs for migration errors
- Verify MySQL pod is running and accessible
- Check database initialization jobs

**Grafana dashboard not found:**
- Verify Grafana pod is running
- Check ConfigMap for dashboard definitions
- Ensure dashboard JSON is valid

## Adding New Acceptance Tests

1. Create validation script in `scripts/validate-at-e1-XXX.sh` or `scripts/validate-at-e2-XXX.sh`
2. Create E2E tests in `tests/e2e/` if needed
3. Create integration tests in `tests/integration/` if needed
4. Add BDD feature file in `tests/bdd/features/` if applicable
5. Update `run-test.sh` to include the new test ID
6. Add Makefile target for convenience
7. Update this README with test details

## AT-E2-001: AI Coding Assistant (GitHub Copilot)

### Acceptance Criteria

- [x] GitHub Copilot configured for organization
- [x] IDE extensions documented (VSCode, IntelliJ, Vim)
- [x] Integration with RAG system documented
- [x] Test code generation working
- [x] Usage telemetry configured (opt-in)
- [x] Documentation complete and accessible

### Test Components

1. **Comprehensive Validation** (`scripts/validate-at-e2-001.sh`)
   - Validates Copilot documentation exists and is comprehensive
   - Checks IDE extension documentation (VSCode, IntelliJ, Vim)
   - Verifies RAG integration documentation
   - Validates code generation test script exists and works
   - Checks telemetry configuration and opt-in mechanism
   - Verifies privacy considerations documented
   - Validates Grafana dashboard exists and is valid JSON
   - Checks metrics documentation
   - Verifies all documentation is accessible
   - Generates JSON test report

2. **Code Generation Tests** (`tests/ai/code-generation-test.sh`)
   - Tests REST API generation
   - Tests Terraform code generation
   - Tests test case generation
   - Validates generated code quality

### Test Reports

Test reports are generated in JSON format at:
```
reports/at-e2-001-validation-YYYYMMDD-HHMMSS.json
```

### Validation Commands

Run the test:

```bash
# Run via test runner
./tests/acceptance/run-test.sh AT-E2-001

# Run via Makefile
make validate-at-e2-001

# Run directly
./scripts/validate-at-e2-001.sh --namespace fawkes
```

### Prerequisites

- Documentation files must exist:
  - `docs/ai/copilot-setup.md`
  - `platform/apps/ai-telemetry/README.md`
  - `platform/apps/ai-telemetry/dashboards/ai-telemetry-dashboard.json`
  - `tests/ai/code-generation-test.sh`
- Python 3 for JSON validation
- bash for running tests

### Troubleshooting

**Documentation not found:**
- Verify all required documentation files exist
- Check file paths match expected locations
- Ensure files are committed to repository

**Code generation tests fail:**
- Review test script logs
- Check if required tools are installed
- Verify test script has execute permissions

## AT-E2-002: RAG Architecture

### Acceptance Criteria

- [x] Weaviate vector database deployed
- [x] RAG service deployed with 2 replicas
- [x] RAG service accessible via ingress
- [x] Health endpoint working
- [x] Context retrieval working (<500ms)
- [x] Relevance scoring >0.7
- [x] Resource limits configured properly
- [x] Integration with Weaviate validated
- [x] API documented (OpenAPI)
- [x] Prometheus metrics exposed

### Test Components

1. **Comprehensive Validation** (`scripts/validate-at-e2-002.sh`)
   - Phase 1: Prerequisites (kubectl, cluster access, namespace)
   - Phase 2: Weaviate Integration (deployment, pods ready)
   - Phase 3: RAG Service Deployment (deployment, replicas, service, ingress, ConfigMap)
   - Phase 4: Resource Limits (CPU/memory requests and limits)
   - Phase 5: API Endpoints (health, OpenAPI docs, metrics)
   - Phase 6: Context Retrieval (query endpoint, performance, relevance)
   - Generates test summary with pass/fail counts

2. **BDD Tests** (`tests/bdd/features/rag-service.feature`)
   - RAG service deployment and running
   - Service accessibility via ClusterIP
   - Ingress configuration
   - Health check working
   - Context retrieval performance (<500ms)
   - Relevance scoring (>0.7)
   - Weaviate integration
   - Resource limits
   - Security context
   - OpenAPI documentation
   - Prometheus metrics

### Test Reports

Test output is shown in terminal with pass/fail status for each phase.

### Validation Commands

Run the test:

```bash
# Run via test runner
./tests/acceptance/run-test.sh AT-E2-002

# Run via Makefile
make validate-at-e2-002

# Run directly
./scripts/validate-at-e2-002.sh

# Run BDD tests
pytest tests/bdd -k "rag" -v --tb=short
```

### Prerequisites

- kubectl with cluster access
- Weaviate deployed in namespace `fawkes`
- RAG service deployed in namespace `fawkes`
- curl (for API testing)
- jq (for JSON processing)
- bc (for calculations)
- pytest (for BDD tests)

### Troubleshooting

**RAG service not accessible:**
```bash
# Check pod status
kubectl get pods -n fawkes -l app=rag-service

# Check service
kubectl get svc rag-service -n fawkes

# Check ingress
kubectl get ingress rag-service -n fawkes

# Port forward for testing
kubectl port-forward -n fawkes svc/rag-service 8080:80
```

**Weaviate connection failed:**
```bash
# Check Weaviate status
kubectl get pods -n fawkes -l app=weaviate

# Check Weaviate service
kubectl get svc weaviate -n fawkes

# Verify ConfigMap has correct Weaviate URL
kubectl get configmap rag-service-config -n fawkes -o yaml
```

**Performance issues (>500ms):**
- Check Weaviate resource usage
- Verify network latency
- Review indexed document size
- Check query parameters (top_k, threshold)

## AT-E2-003: DataHub Data Catalog

### Acceptance Criteria

- [x] DataHub deployed with GMS and Frontend
- [x] PostgreSQL backend operational
- [x] OpenSearch for search indexing
- [x] DataHub UI accessible via ingress
- [x] GraphQL API functional
- [x] Metadata ingestion working
- [x] Automated ingestion CronJobs:
  * PostgreSQL ingestion (daily)
  * Kubernetes ingestion (hourly)
  * Git/CI ingestion (6-hour)
- [x] Data lineage visualization
- [x] Resource limits configured
- [x] Prometheus metrics exposed

### Test Components

1. **Comprehensive Validation** (`scripts/validate-at-e2-003.sh`)
    - Phase 1: Prerequisites (kubectl, cluster access, namespace)
    - Phase 2: PostgreSQL Database (cluster health, pods, service)
    - Phase 3: OpenSearch (pods, service)
    - Phase 4: DataHub Deployment (GMS, Frontend replicas)
    - Phase 5: Services (GMS service, Frontend service)
    - Phase 6: Ingress Configuration (ingress exists, hosts configured)
    - Phase 7: API Health (GMS health, Frontend health)
    - Phase 8: Ingestion Automation (CronJobs for PostgreSQL, K8s, Git/CI)
    - Phase 9: Resource Limits (CPU/memory requests and limits)
    - Phase 10: ArgoCD Application (sync status, health status)
    - Generates test summary with pass/fail counts and JSON report

2. **BDD Tests** (`tests/bdd/features/datahub-deployment.feature`)
    - Service deployment and accessibility
    - GraphQL API health
    - Metadata storage with PostgreSQL
    - Search indexing with OpenSearch
    - PostgreSQL metadata ingestion
    - Basic authentication
    - Data lineage visualization
    - Resource allocation and stability
    - Prometheus metrics exposure
    - PostgreSQL high availability
    - Data governance with tags
    - REST API integration
    - UI search and discovery
    - Automated metadata ingestion (CronJobs)
    - End-to-end metadata lineage

### Test Reports

Test reports are generated in JSON format at:
```
reports/at-e2-003-validation-YYYYMMDD-HHMMSS.json
```

### Validation Commands

Run the test:

```bash
# Run via test runner
./tests/acceptance/run-test.sh AT-E2-003

# Run via Makefile
make validate-at-e2-003

# Run directly
./scripts/validate-at-e2-003.sh --namespace fawkes

# Run BDD tests
pytest tests/bdd -k "datahub" -v --tb=short
```

### Prerequisites

- kubectl with cluster access
- PostgreSQL cluster deployed (db-datahub-dev)
- OpenSearch deployed in logging namespace
- DataHub deployed in namespace `fawkes`
- curl (for API testing)
- jq (optional, for JSON processing)
- pytest (for BDD tests)

### Troubleshooting

**DataHub pods not starting:**
```bash
# Check pod status
kubectl get pods -n fawkes -l "app.kubernetes.io/instance=datahub"

# Check GMS logs
kubectl logs -n fawkes deployment/datahub-datahub-gms

# Check Frontend logs
kubectl logs -n fawkes deployment/datahub-datahub-frontend
```

**PostgreSQL connection issues:**
```bash
# Check PostgreSQL cluster
kubectl get cluster db-datahub-dev -n fawkes

# Check PostgreSQL pods
kubectl get pods -n fawkes -l "cnpg.io/cluster=db-datahub-dev"

# Test connection from GMS pod
kubectl exec -n fawkes deployment/datahub-datahub-gms -- \
  curl -f http://db-datahub-dev-rw:5432
```

**OpenSearch not accessible:**
```bash
# Check OpenSearch pods
kubectl get pods -n logging -l "app=opensearch"

# Port-forward for testing
kubectl port-forward -n logging svc/opensearch 9200:9200
```

**Ingestion jobs not running:**
```bash
# Check CronJobs
kubectl get cronjobs -n fawkes | grep datahub

# Manually trigger a job
kubectl create job --from=cronjob/datahub-postgres-ingestion manual-run -n fawkes

# Check job logs
kubectl logs -n fawkes job/manual-run
```

## AT-E2-004: Great Expectations Data Quality

### Acceptance Criteria

- [x] Great Expectations configuration deployed
- [x] Data source connections configured:
  * Backstage database
  * Harbor database
  * DataHub database
  * SonarQube database
  * DORA metrics database
- [x] Expectation suites created for all databases
- [x] Validation running automatically (CronJob)
- [x] Checkpoints configured
- [x] Prometheus exporter for metrics
- [x] Grafana dashboard for visualization
- [x] ArgoCD application deployed

### Test Components

1. **Comprehensive Validation** (`scripts/validate-at-e2-004.sh`)
    - Phase 1: Prerequisites (kubectl, cluster access, namespace)
    - Phase 2: Great Expectations Configuration (ConfigMaps, Secrets)
    - Phase 3: Data Sources Connected (all database clusters)
    - Phase 4: Expectation Suites Created (5 suites for different databases)
    - Phase 5: Validation Running Automatically (CronJob schedule)
    - Phase 6: Checkpoints Configuration (checkpoint YAML files)
    - Phase 7: Prometheus Exporter (deployment, service, ServiceMonitor)
    - Phase 8: Grafana Dashboard (JSON file validation, panel count)
    - Phase 9: ArgoCD Application (sync and health status)
    - Generates test summary with pass/fail counts

2. **BDD Tests** (to be created in `tests/bdd/features/`)
    - Data quality configuration
    - Database connections
    - Expectation suite validation
    - Automated validation runs
    - Prometheus metrics exposure
    - Grafana dashboard visualization

### Test Reports

Test reports are shown in terminal output. Future enhancement will generate JSON reports at:
```
reports/at-e2-004-validation-YYYYMMDD-HHMMSS.json
```

### Validation Commands

Run the test:

```bash
# Run via test runner
./tests/acceptance/run-test.sh AT-E2-004

# Run via Makefile
make validate-at-e2-004

# Run directly
./scripts/validate-at-e2-004.sh --namespace fawkes

# Run BDD tests (when available)
pytest tests/bdd -k "data_quality or great_expectations" -v --tb=short
```

### Prerequisites

- kubectl with cluster access
- All database clusters deployed:
  - db-backstage
  - db-harbor
  - db-datahub
  - db-sonarqube-dev
- Data quality ConfigMaps and Secrets
- Great Expectations configuration
- Python 3 (for JSON validation)
- pytest (for BDD tests)

### Troubleshooting

**ConfigMaps not found:**
```bash
# Check ConfigMaps
kubectl get configmap -n fawkes | grep -E "data-quality|gx-"

# View ConfigMap contents
kubectl get configmap gx-full-config -n fawkes -o yaml
```

**Database connections failing:**
```bash
# Check database cluster status
kubectl get clusters -n fawkes

# Test connection to a database
kubectl exec -n fawkes deployment/data-quality-exporter -- \
  psql -h db-backstage-rw -U postgres -d backstage -c "SELECT 1"
```

**CronJob not running:**
```bash
# Check CronJob
kubectl get cronjob data-quality-validation -n fawkes

# Check job history
kubectl get jobs -n fawkes -l app=data-quality

# Manually trigger validation
kubectl create job --from=cronjob/data-quality-validation manual-validation -n fawkes

# Check job logs
kubectl logs -n fawkes job/manual-validation
```

**Prometheus metrics not available:**
```bash
# Check exporter deployment
kubectl get deployment data-quality-exporter -n fawkes

# Check exporter logs
kubectl logs -n fawkes deployment/data-quality-exporter

# Port-forward and test metrics endpoint
kubectl port-forward -n fawkes svc/data-quality-exporter 9110:9110
curl http://localhost:9110/metrics
```

## AT-E2-005: VSM (Value Stream Mapping)

### Acceptance Criteria

- [x] VSM service API deployed
- [x] Work item tracking across stages
- [x] Cycle time calculation per stage
- [x] Flow metrics collection (throughput, WIP, cycle time)
- [x] 8-stage value stream configured
- [x] PostgreSQL database for persistence
- [x] API documented (OpenAPI/Swagger)
- [x] Prometheus metrics exposed
- [x] 2+ replicas for high availability
- [x] Resource limits configured

### Value Stream Stages

The VSM service uses an 8-stage value stream:

1. **Backlog** (wait) - Work items waiting to be analyzed
2. **Design** (active, WIP: 5) - Active design and analysis phase
3. **Development** (active, WIP: 10) - Active implementation phase
4. **Code Review** (wait, WIP: 8) - Waiting for peer review
5. **Testing** (active, WIP: 8) - Active testing and QA phase
6. **Deployment Approval** (wait, WIP: 5) - Waiting for deployment approval
7. **Deploy** (active, WIP: 3) - Active deployment to production
8. **Production** (done) - Successfully deployed and running

### Test Components

1. **Comprehensive Validation** (`scripts/validate-at-e2-005.sh`)
    - Phase 1: Prerequisites (kubectl, cluster access, namespace)
    - Phase 2: PostgreSQL Database (cluster health, pods, service)
    - Phase 3: VSM Service Deployment (deployment, replicas, service, ingress, ConfigMap)
    - Phase 4: API Health Check (health endpoint, readiness endpoint)
    - Phase 5: API Endpoints (stages, metrics, OpenAPI docs)
    - Phase 6: Flow Metrics (throughput, WIP, cycle time calculation)
    - Phase 7: Prometheus Metrics (metrics exposure, ServiceMonitor)
    - Phase 8: Resource Configuration (CPU/memory requests and limits)
    - Phase 9: ArgoCD Application (sync and health status)
    - Generates JSON test report

2. **BDD Tests** (`tests/bdd/features/`)
    - VSM service deployment and accessibility
    - Work item creation and tracking
    - Stage transitions with validation
    - Flow metrics calculation
    - Prometheus metrics exposure
    - Resource allocation and stability

### Test Reports

Test reports are generated in JSON format at:
```
reports/at-e2-005-validation-YYYYMMDD-HHMMSS.json
```

### Validation Commands

Run the test:

```bash
# Run via test runner
./tests/acceptance/run-test.sh AT-E2-005

# Run via Makefile
make validate-at-e2-005

# Run directly
./scripts/validate-at-e2-005.sh --namespace fawkes

# Run BDD tests (when available)
pytest tests/bdd -k "vsm or value_stream" -v --tb=short
```

### API Endpoints

The VSM service provides the following endpoints:

- `POST /api/v1/work-items` - Create new work item
- `PUT /api/v1/work-items/{id}/transition` - Move work item between stages
- `GET /api/v1/work-items/{id}/history` - Get stage history for work item
- `GET /api/v1/metrics` - Get flow metrics (throughput, WIP, cycle time)
- `GET /api/v1/stages` - List all available stages
- `GET /api/v1/health` - Health check
- `GET /ready` - Readiness check
- `GET /metrics` - Prometheus metrics
- `GET /docs` - OpenAPI/Swagger documentation

### Prerequisites

- kubectl with cluster access
- PostgreSQL cluster deployed (db-vsm-dev)
- VSM service deployed in namespace `fawkes`
- curl (for API testing)
- jq (optional, for JSON processing)
- pytest (for BDD tests)

### Troubleshooting

**VSM service not accessible:**
```bash
# Check pod status
kubectl get pods -n fawkes -l app=vsm-service

# Check service
kubectl get svc vsm-service -n fawkes

# Check ingress
kubectl get ingress vsm-service -n fawkes

# Port forward for testing
kubectl port-forward -n fawkes svc/vsm-service 8080:80
```

**PostgreSQL connection failed:**
```bash
# Check PostgreSQL cluster
kubectl get cluster db-vsm-dev -n fawkes

# Check PostgreSQL pods
kubectl get pods -n fawkes -l "cnpg.io/cluster=db-vsm-dev"

# Verify ConfigMap has correct database URL
kubectl get configmap vsm-service-config -n fawkes -o yaml
```

**Flow metrics not calculating:**
- Ensure work items have been created and transitioned
- Check database has stage transitions recorded
- Verify metrics calculation is not failing in logs
- Check that stages are properly configured

## AT-E2-008: Unified GraphQL Data API

### Acceptance Criteria

- [x] Hasura GraphQL Engine deployed
- [x] GraphQL API endpoint accessible
- [x] Schema introspection working
- [x] Query performance <1s (P95)
- [x] GraphQL Playground accessible
- [x] Redis cache for performance (optional)
- [x] RBAC configuration
- [x] Prometheus metrics exposed
- [x] ServiceMonitor configured
- [x] Resource limits configured

### Test Components

1. **Comprehensive Validation** (`scripts/validate-at-e2-008.sh`)
    - Test 1: Hasura Deployment (deployment exists, replicas ready)
    - Test 2: Hasura Service (service exists, port configured)
    - Test 3: Hasura Ingress (ingress configured)
    - Test 4: Redis Cache (cache deployment, if configured)
    - Test 5: GraphQL Endpoint Health (health check)
    - Test 6: GraphQL Schema Introspection (type count)
    - Test 7: Query Performance Test (P95 < 1s, 20 iterations)
    - Test 8: GraphQL Console Access (playground/console)
    - Test 9: RBAC Configuration (permission files, anonymous role)
    - Test 10: Monitoring Integration (ServiceMonitor, metrics endpoint)

2. **Performance Tests** (`tests/performance/graphql-load-test.js`)
    - k6 load testing for GraphQL queries
    - Performance benchmarking
    - Stress testing

### Test Reports

Test execution logs show pass/fail status for each test phase.

### Validation Commands

Run the test:

```bash
# Run via test runner
./tests/acceptance/run-test.sh AT-E2-008

# Run via Makefile
make validate-at-e2-008

# Run directly
./scripts/validate-at-e2-008.sh --namespace fawkes

# Run performance tests (requires k6)
k6 run tests/performance/graphql-load-test.js
```

### API Endpoints

The Hasura GraphQL API provides:

- `POST /v1/graphql` - GraphQL query endpoint
- `GET /healthz` - Health check endpoint
- `GET /v1/metrics` - Prometheus metrics
- `GET /console` - GraphQL Playground/Console
- GraphQL introspection queries for schema exploration

### Prerequisites

- kubectl with cluster access
- Hasura deployed in namespace `fawkes`
- curl (for API testing)
- jq (for JSON processing)
- k6 (for performance tests, optional)

### Troubleshooting

**Hasura not accessible:**
```bash
# Check pod status
kubectl get pods -n fawkes -l app=hasura

# Check service
kubectl get svc hasura -n fawkes

# Check ingress
kubectl get ingress hasura -n fawkes

# Port forward for testing
kubectl port-forward -n fawkes svc/hasura 8080:8080
```

**GraphQL schema empty:**
- Ensure database tables are tracked in Hasura
- Access console at http://localhost:8080/console
- Go to Data tab and track tables
- Verify database connections are configured

**Performance issues:**
- Check Redis cache deployment and configuration
- Verify database connection pooling settings
- Review query complexity and optimize if needed
- Check resource limits on Hasura pods

**RBAC not working:**
- Verify permissions.yaml file exists
- Apply metadata: `hasura metadata apply`
- Check role configuration in Hasura console
- Test with different x-hasura-role headers

## AT-E2-010: Feedback Analytics Dashboard

### Acceptance Criteria

- [x] Feedback analytics dashboard created
- [x] NPS trends visible
- [x] Feedback categorization shown
- [x] Sentiment analysis working
- [x] Top issues highlighted
- [x] Metrics exported to Prometheus

### Test Components

1. **Comprehensive Validation** (`scripts/validate-at-e2-010.sh`)
    - AC1: Feedback analytics dashboard created
      - Dashboard file exists at `platform/apps/grafana/dashboards/feedback-analytics.json`
      - Dashboard JSON is valid
      - Dashboard has correct title "Feedback Analytics"
      - Dashboard has sufficient panels (>10)
    - AC2: NPS trends visible
      - NPS score panel exists
      - NPS trend panel exists
      - NPS components panel exists (promoters/passives/detractors)
    - AC3: Feedback categorization shown
      - Category panel exists
      - Rating distribution panel exists
    - AC4: Sentiment analysis working
      - Sentiment module exists (`services/feedback/app/sentiment.py`)
      - VADER dependency specified in requirements.txt
      - Sentiment fields in database schema
      - Sentiment panels in dashboard
    - AC5: Top issues highlighted
      - Top issues panel exists
      - Low-rated feedback panel exists
    - AC6: Metrics exported to Prometheus
      - Metrics module exists (`services/feedback/app/metrics.py`)
      - All required metrics defined (nps_score, nps_promoters_percentage, nps_detractors_percentage, feedback_response_rate, feedback_submissions_total, feedback_sentiment_score)
      - Metrics integrated in main application
    - Generates JSON test report

2. **BDD Tests** (`tests/bdd/features/feedback-widget.feature`)
    - Feedback service deployment and health
    - Database cluster operational
    - Feedback submission with validation
    - Authorization and admin endpoints
    - Feedback status management
    - Statistics endpoint
    - Ingress configuration
    - Backstage proxy configuration
    - Prometheus metrics exposure
    - Resource limits and security

### Feedback Analytics Features

The feedback analytics system includes:

#### NPS Metrics
- **NPS Score**: -100 to +100 scale, calculated from 1-5 star ratings
  - Promoters: 5 stars (would recommend)
  - Passives: 4 stars (satisfied but not enthusiastic)
  - Detractors: 1-3 stars (unhappy customers)
- **Formula**: NPS = (% Promoters - % Detractors) × 100
- **Tracking periods**: overall, last_30d, last_90d

#### Sentiment Analysis
- **AI-powered analysis** using VADER (Valence Aware Dictionary and sEntiment Reasoner)
- **Automatic classification**: positive (≥0.05), neutral (-0.05 to 0.05), negative (≤-0.05)
- **Compound score**: -1.0 (most negative) to +1.0 (most positive)
- Stored with each feedback submission

#### Dashboard Panels (25 total)
1. **Key Metrics Overview**: NPS Score, Total Feedback, Response Rate, Average Rating
2. **NPS Breakdown**: NPS Trend (90-day), NPS Components Distribution
3. **Feedback Volume & Categories**: Volume Over Time, Feedback by Category
4. **Rating Distribution**: 1-5 star distribution, Rating Trend
5. **Sentiment Analysis**: Sentiment Distribution, Sentiment by Category
6. **Response Tracking**: Status Distribution, Response Rate Trend
7. **Top Issues & Insights**: Top Categories, Low-Rated Feedback

### Test Reports

Test reports are generated in JSON format at:
```
reports/at-e2-010-validation-YYYYMMDD-HHMMSS.json
```

### Validation Commands

Run the test:

```bash
# Run via test runner
./tests/acceptance/run-test.sh AT-E2-010

# Run via Makefile
make validate-at-e2-010

# Run directly
./scripts/validate-at-e2-010.sh --namespace fawkes

# Run with verbose output
./scripts/validate-at-e2-010.sh --namespace fawkes --verbose

# Run BDD tests
pytest tests/bdd -k "feedback" -v --tb=short
```

### Feedback Service API Endpoints

The feedback service provides:

#### Public Endpoints
- `POST /api/v1/feedback` - Submit feedback (automatically analyzes sentiment)
- `GET /health` - Health check

#### Admin Endpoints (require Bearer token)
- `GET /api/v1/feedback` - List all feedback (paginated, includes sentiment)
- `PUT /api/v1/feedback/{id}/status` - Update feedback status
- `GET /api/v1/feedback/stats` - Get aggregated statistics
- `POST /api/v1/metrics/refresh` - Manually refresh Prometheus metrics

#### Metrics
- `GET /metrics` - Prometheus metrics endpoint

### Prerequisites

- kubectl with cluster access
- Feedback service deployed in namespace `fawkes`
- PostgreSQL database cluster (db-feedback-dev)
- Grafana dashboard configured
- Python 3 (for JSON validation)
- pytest (for BDD tests)

### Troubleshooting

**Feedback service not accessible:**
```bash
# Check pod status
kubectl get pods -n fawkes -l app=feedback-service

# Check service
kubectl get svc feedback-service -n fawkes

# Check ingress
kubectl get ingress feedback-service -n fawkes

# Port forward for testing
kubectl port-forward -n fawkes svc/feedback-service 8080:8000
```

**PostgreSQL connection failed:**
```bash
# Check PostgreSQL cluster
kubectl get cluster db-feedback-dev -n fawkes

# Check PostgreSQL pods
kubectl get pods -n fawkes -l "cnpg.io/cluster=db-feedback-dev"

# Test connection
kubectl exec -n fawkes deployment/feedback-service -- \
  curl -f http://db-feedback-dev-rw:5432
```

**Dashboard not found in Grafana:**
- Verify dashboard JSON file exists: `platform/apps/grafana/dashboards/feedback-analytics.json`
- Check if dashboard is loaded in Grafana ConfigMap
- Access Grafana UI and manually import the dashboard
- Check Grafana logs for import errors

**Sentiment analysis not working:**
- Verify VADER dependency installed: `grep vaderSentiment services/feedback/requirements.txt`
- Check sentiment module exists: `services/feedback/app/sentiment.py`
- Review feedback service logs for sentiment analysis errors
- Test sentiment API by submitting feedback with comments

**Metrics not appearing in Prometheus:**
- Check metrics endpoint: `curl http://feedback-service:8000/metrics`
- Verify ServiceMonitor exists for feedback service
- Check Prometheus targets configuration
- Manually refresh metrics: `curl -X POST http://feedback-service:8000/api/v1/metrics/refresh`

### Example Usage

Submit feedback with sentiment analysis:
```bash
curl -X POST http://feedback-service.fawkes.svc:8000/api/v1/feedback \
  -H "Content-Type: application/json" \
  -d '{
    "rating": 5,
    "category": "UI",
    "comment": "Great user interface! Love the new design.",
    "email": "user@example.com",
    "page_url": "https://backstage.example.com/catalog"
  }'
```

Response includes sentiment:
```json
{
  "id": 1,
  "rating": 5,
  "category": "UI",
  "comment": "Great user interface! Love the new design.",
  "sentiment": "positive",
  "sentiment_compound": 0.836,
  "status": "open",
  "created_at": "2025-12-23T12:00:00Z"
}
```

View metrics:
```bash
curl http://feedback-service:8000/metrics | grep -E "nps_|feedback_|sentiment"
```

## Generating Reports

Use the `generate-report.sh` script to create consolidated reports:

```bash
# Generate HTML report for Epic 2, Week 1
./tests/acceptance/generate-report.sh --epic 2 --week 1

# Generate JSON report for Epic 1
./tests/acceptance/generate-report.sh --epic 1 --format json

# Generate markdown report with custom output
./tests/acceptance/generate-report.sh --epic 2 --week 1 --format markdown --output my-report.md

# Generate report for all tests
./tests/acceptance/generate-report.sh --format html
```

Report formats:
- **HTML**: Interactive report with summary cards and tables
- **JSON**: Machine-readable format for CI/CD integration
- **Markdown**: Documentation-friendly format

Reports are saved in the `reports/` directory by default.

## Dependencies

- kubectl
- argocd CLI (optional but recommended)
- pytest (for BDD tests)
- jq (for JSON processing)
- bc (for calculations)
- curl (for API testing)
- python3 (for JSON validation)
- Kubernetes cluster access

## AT-E3-003: Multi-Channel Feedback System

### Acceptance Criteria

- [x] Backstage widget functional (feedback-service)
- [x] CLI tool working (feedback-cli)
- [x] Mattermost bot responsive (feedback-bot)
- [x] Automation creating issues (cronjob)
- [x] Analytics dashboard showing data (Grafana)
- [x] All channels integrated

### Feedback Channels

1. **Backstage Widget** (`services/feedback/`)
   - REST API for feedback submission
   - PostgreSQL database storage
   - Admin endpoints
   - Sentiment analysis
   - GitHub issue creation

2. **CLI Tool** (`services/feedback-cli/`)
   - Terminal-based feedback submission
   - Interactive mode
   - Offline queue capability
   - Configuration management

3. **Mattermost Bot** (`services/feedback-bot/`)
   - Natural language interface
   - `/feedback` slash command
   - Auto-categorization
   - Sentiment analysis (VADER)
   - Smart rating extraction

4. **Automation Pipeline** (`platform/apps/feedback-service/cronjob-automation.yaml`)
   - Runs every 15 minutes
   - AI-powered triage
   - Priority calculation
   - Duplicate detection
   - GitHub issue creation

5. **Analytics Dashboard** (`platform/apps/grafana/dashboards/feedback-analytics.json`)
   - NPS Score tracking
   - Sentiment visualization
   - Feedback volume metrics
   - Rating distribution
   - Historical trends

### Test Components

1. **Comprehensive Validation** (`scripts/validate-at-e3-003.sh`)
    - AC1: Backstage Widget Functional
      - Feedback service deployment exists
      - Database cluster operational
      - API accessible and healthy
      - Backstage proxy configured
    - AC2: CLI Tool Working
      - Code exists in repository
      - Submit and list commands present
      - Configuration management implemented
    - AC3: Mattermost Bot Responsive
      - Bot deployment exists and running
      - Service accessible
      - NLP and sentiment analysis capabilities
    - AC4: Automation Creating Issues
      - CronJob scheduled (every 15 minutes)
      - Automation endpoint available
      - GitHub integration configured
    - AC5: Analytics Dashboard Showing Data
      - Dashboard file exists and valid JSON
      - Key metrics present (NPS, sentiment, volume, ratings)
      - Grafana operational
    - AC6: All Channels Integrated
      - ServiceMonitors configured
      - Metrics exposed
      - Components can communicate
      - BDD test coverage

2. **BDD Tests** (`tests/bdd/features/multi-channel-feedback.feature`)
    - Backstage widget functional
    - CLI tool working
    - Mattermost bot responsive
    - Automation creating issues
    - Analytics dashboard operational
    - System integration verified
    - Observability configured
    - Security and resources validated
    - Data flow end-to-end
    - All channels completeness

3. **Individual Channel BDD Tests**
    - `feedback-widget.feature` - Backstage widget scenarios
    - `feedback-bot.feature` - Mattermost bot scenarios
    - `feedback-automation.feature` - Automation pipeline scenarios

### Test Reports

Test reports are generated in JSON format at:
```
reports/at-e3-003-validation-YYYYMMDD-HHMMSS.json
```

### Validation Commands

Run the test:

```bash
# Run via test runner
./tests/acceptance/run-test.sh AT-E3-003

# Run via Makefile
make validate-at-e3-003

# Run directly
./scripts/validate-at-e3-003.sh --namespace fawkes --monitoring-ns monitoring

# Run with verbose output
./scripts/validate-at-e3-003.sh --namespace fawkes --monitoring-ns monitoring --verbose

# Run BDD tests
pytest tests/bdd -k "at-e3-003 or multi-channel" -v
behave tests/bdd/features --tags=@at-e3-003
behave tests/bdd/features --tags=@multi-channel
```

### Manual Validation

**Submit feedback via different channels:**

```bash
# 1. Via API (Backstage widget)
kubectl port-forward -n fawkes svc/feedback-service 8000:8000
curl -X POST http://localhost:8000/api/v1/feedback \
  -H "Content-Type: application/json" \
  -d '{"rating": 5, "category": "UI", "comment": "Great platform!"}'

# 2. Via CLI tool
cd services/feedback-cli
pip install -e .
fawkes-feedback submit -i

# 3. Via Mattermost
# In Mattermost: /feedback This is amazing!

# 4. Check automation
kubectl get cronjob feedback-automation -n fawkes
kubectl get jobs -n fawkes -l app=feedback-automation

# 5. View analytics
kubectl port-forward -n monitoring svc/grafana 3000:3000
# Open http://localhost:3000 and find "Feedback Analytics" dashboard
```

### Prerequisites

- kubectl with cluster access
- Feedback service deployed in `fawkes` namespace
- Grafana deployed in `monitoring` namespace
- Mattermost instance (for bot testing)
- Python 3 (for CLI tool)
- curl (for API testing)
- jq (optional, for JSON processing)

### Troubleshooting

**Feedback service not accessible:**
```bash
# Check deployment and logs
kubectl get deployment feedback-service -n fawkes
kubectl logs -n fawkes -l app=feedback-service --tail=50

# Port-forward for testing
kubectl port-forward -n fawkes svc/feedback-service 8000:8000
curl http://localhost:8000/health
```

**Bot not responding:**
```bash
# Check bot deployment
kubectl get deployment feedback-bot -n fawkes
kubectl logs -n fawkes -l app=feedback-bot --tail=50

# Verify Mattermost integration
kubectl get secret feedback-bot-secret -n fawkes
```

**Automation not running:**
```bash
# Check CronJob
kubectl get cronjob feedback-automation -n fawkes
kubectl describe cronjob feedback-automation -n fawkes

# Manually trigger
kubectl create job --from=cronjob/feedback-automation manual-test -n fawkes
kubectl logs -n fawkes job/manual-test
```

**Dashboard not showing data:**
```bash
# Check Grafana
kubectl get pods -n monitoring -l app.kubernetes.io/name=grafana

# Verify dashboard exists
ls -la platform/apps/grafana/dashboards/feedback-analytics.json

# Check metrics
kubectl port-forward -n fawkes svc/feedback-service 8000:8000
curl http://localhost:8000/metrics | grep feedback_
```

### Success Criteria

The test passes when:
- ✓ All 5 feedback channels are implemented
- ✓ Code exists for all components
- ✓ Deployments are configured correctly
- ✓ Analytics dashboard has all required metrics
- ✓ BDD tests exist and pass
- ✓ Integration between components is verified

### Related Tests

- AT-E3-001: Research Infrastructure validation
- AT-E3-002: SPACE Framework Implementation validation
- AT-E2-010: Feedback Analytics Dashboard validation

### Documentation References

- [AT-E3-003 Implementation Guide](../../docs/validation/AT-E3-003-IMPLEMENTATION.md)
- [Feedback Service README](../../services/feedback/README.md)
- [CLI Tool README](../../services/feedback-cli/README.md)
- [Bot README](../../services/feedback-bot/README.md)
- [Multi-Channel Feedback BDD Tests](../bdd/features/multi-channel-feedback.feature)

