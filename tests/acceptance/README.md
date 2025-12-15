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
| AT-E1-007 | Metrics | DORA metrics automated (4 key metrics) | 🚧 Pending |
| AT-E1-008 | Templates | 3 golden paths work end-to-end | 🚧 Pending |
| AT-E1-009 | Registry | Harbor with security scanning | ✅ Implemented |
| AT-E1-010 | Performance | Resource usage <70% on cluster | 🚧 Pending |
| AT-E1-011 | Documentation | Complete docs and runbooks | 🚧 Pending |
| AT-E1-012 | Integration | Full platform workflow validated | 🚧 Pending |

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

## Adding New Acceptance Tests

1. Create validation script in `scripts/validate-at-e1-XXX.sh`
2. Create E2E tests in `tests/e2e/` if needed
3. Create integration tests in `tests/integration/` if needed
4. Add BDD feature file in `tests/bdd/features/` if applicable
5. Update `run-test.sh` to include the new test ID
6. Add Makefile target for convenience
7. Update this README with test details

## Dependencies

- kubectl
- argocd CLI (optional but recommended)
- pytest (for BDD tests)
- jq (for JSON processing)
- Kubernetes cluster access
