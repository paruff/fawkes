# AT-E1-002 Validation Test Guide

## Overview

This guide explains how to run and validate AT-E1-002 acceptance tests for GitOps with ArgoCD.

**Test ID**: AT-E1-002
**Category**: GitOps
**Description**: ArgoCD manages all platform components
**Priority**: P0 - Critical

## Prerequisites

Before running AT-E1-002 tests, ensure you have:

1. **Kubernetes cluster** - Local (kind, minikube, Docker Desktop) or cloud (AKS, EKS, GKE)
2. **kubectl** - Configured and connected to your cluster
3. **ArgoCD deployed** - Via Helm or manifest
4. **ArgoCD CLI** - Optional but recommended for enhanced validation
5. **jq** - For JSON processing in validation scripts
6. **pytest** - For running BDD tests (optional)

## Quick Start

### 1. Run Complete AT-E1-002 Validation

```bash
# Using the unified test runner
./tests/acceptance/run-test.sh AT-E1-002

# Or using Makefile
make validate-at-e1-002
```

This will run:
1. Comprehensive validation checks
2. E2E sync tests
3. BDD tests (if pytest available)

### 2. Run Individual Test Components

#### Comprehensive Validation Only

```bash
./scripts/validate-at-e1-002.sh
```

Options:
```bash
# Custom namespace
./scripts/validate-at-e1-002.sh --namespace argocd

# Verbose output
./scripts/validate-at-e1-002.sh --verbose

# Custom report location
./scripts/validate-at-e1-002.sh --report /path/to/report.json
```

#### E2E Sync Tests Only

```bash
./tests/e2e/argocd-sync-test.sh
```

Options:
```bash
# Test specific application
./tests/e2e/argocd-sync-test.sh --app platform-bootstrap

# Custom timeout
./tests/e2e/argocd-sync-test.sh --timeout 600

# Verbose output
./tests/e2e/argocd-sync-test.sh --verbose
```

#### BDD Tests Only

```bash
# All ArgoCD bootstrap tests
pytest tests/bdd/test_argocd_bootstrap.py -v

# All ArgoCD deployment tests
pytest tests/bdd/step_definitions/test_argocd_deployment.py -v

# Tests tagged with @gitops
pytest tests/bdd -v -m gitops

# Tests tagged with @local
pytest tests/bdd -v -m local
```

## Validation Checks

The AT-E1-002 validation performs the following checks:

### 1. Prerequisites
- ✅ kubectl is installed and accessible
- ✅ argocd CLI is installed (optional)

### 2. Cluster Access
- ✅ Kubernetes cluster is accessible via kubectl
- ✅ Cluster info can be retrieved

### 3. ArgoCD Namespace
- ✅ ArgoCD namespace exists (default: `fawkes`)
- ✅ Namespace is in Active phase

### 4. ArgoCD Deployment
- ✅ argocd-server is deployed
- ✅ argocd-application-controller is deployed
- ✅ argocd-repo-server is deployed
- ✅ argocd-redis is deployed

### 5. ArgoCD Pods
- ✅ All ArgoCD pods are Running
- ✅ All ArgoCD pods are Ready
- ✅ No pods in Failed or Pending state

### 6. ArgoCD CRDs
- ✅ applications.argoproj.io CRD exists
- ✅ applicationsets.argoproj.io CRD exists
- ✅ appprojects.argoproj.io CRD exists

### 7. Git Repository Structure
- ✅ platform/apps/ directory exists
- ✅ platform/bootstrap/ directory exists

### 8. App-of-Apps Pattern
- ✅ Root Application(s) exist
  - platform-bootstrap
  - fawkes-app
  - fawkes-infra
- ✅ At least one Application exists

### 9. Application Sync Status
- ✅ All applications are Synced
- ✅ All applications are Healthy
- ✅ No out-of-sync applications

### 10. Auto-Sync Configuration
- ✅ Auto-sync is enabled on applications
- ✅ Self-heal is enabled on applications

### 11. ArgoCD Ingress
- ✅ Ingress resource exists for ArgoCD
- ✅ Ingress has valid host configuration

## Test Reports

### JSON Report Format

Test reports are generated in JSON format at:
```
reports/at-e1-002-validation-YYYYMMDD-HHMMSS.json
```

Example report structure:
```json
{
  "test_id": "AT-E1-002",
  "test_name": "GitOps with ArgoCD",
  "timestamp": "2025-01-15T10:30:00Z",
  "namespace": "fawkes",
  "summary": {
    "total": 25,
    "passed": 25,
    "failed": 0,
    "pass_rate": "100.00%"
  },
  "results": [
    {
      "name": "Prerequisites",
      "status": "PASS",
      "message": "kubectl is installed"
    }
  ]
}
```

### Viewing Reports

```bash
# View latest report
cat reports/at-e1-002-validation-*.json | jq .

# Check summary only
cat reports/at-e1-002-validation-*.json | jq '.summary'

# Check failed tests only
cat reports/at-e1-002-validation-*.json | jq '.results[] | select(.status=="FAIL")'
```

## Manual Validation Commands

From the issue requirements, you can also run these manual validation commands:

### Check All Apps Are Synced

```bash
argocd app list | grep -c Synced
```

Expected: Count matches total number of applications

### Hard Refresh Platform Bootstrap

```bash
argocd app get platform-bootstrap --hard-refresh
```

Expected: Application syncs successfully

### Check for Out-of-Sync Applications

```bash
kubectl get applications -n fawkes -o json | \
  jq '.items[] | select(.status.sync.status != "Synced")' | \
  jq -s 'length'
```

Expected: `0` (no out-of-sync applications)

## Acceptance Criteria Checklist

Based on issue #8, the following acceptance criteria must be met:

- [ ] **AT-E1-002 test suite passes** - All validation scripts pass
- [ ] **ArgoCD managing components** - Applications are synced and healthy
- [ ] **Test report generated** - JSON report exists in reports/ directory
- [ ] **ArgoCD deployed via Helm** - ArgoCD components are running
- [ ] **ArgoCD CLI installed and configured** - CLI can interact with server
- [ ] **Git repository structure created** - platform/apps/ and platform/bootstrap/ exist
- [ ] **App-of-apps pattern implemented** - Root applications manage child applications
- [ ] **All platform components synced from Git** - No manual kubectl apply needed
- [ ] **Auto-sync enabled with self-heal** - Drift is automatically corrected
- [ ] **Rollback tested successfully** - Can revert to previous versions
- [ ] **ArgoCD UI accessible via ingress** - UI is available at configured host

## Troubleshooting

### No Cluster Access

```
Error: Cannot access Kubernetes cluster
```

**Solution**: Ensure kubectl is configured and pointing to the correct cluster:
```bash
kubectl cluster-info
kubectl config current-context
```

### ArgoCD Namespace Not Found

```
Error: Namespace 'fawkes' does not exist
```

**Solution**: Either:
1. Deploy ArgoCD to the fawkes namespace
2. Use `--namespace argocd` if ArgoCD is in a different namespace

### No Applications Found

```
Error: No applications found
```

**Solution**: Deploy the app-of-apps pattern:
```bash
kubectl apply -f platform/bootstrap/app-of-apps.yaml
```

### Applications Not Synced

```
Error: X/Y applications are Synced
```

**Solution**: Check application status and sync:
```bash
argocd app list
argocd app sync <app-name>
argocd app get <app-name>
```

### ArgoCD CLI Not Found

```
Warning: argocd CLI not found
```

**Note**: This is optional. Install from:
https://argo-cd.readthedocs.io/en/stable/cli_installation/

## CI/CD Integration

### GitHub Actions Example

```yaml
- name: Run AT-E1-002 Validation
  run: |
    ./tests/acceptance/run-test.sh AT-E1-002

- name: Upload Test Report
  uses: actions/upload-artifact@v3
  if: always()
  with:
    name: at-e1-002-report
    path: reports/at-e1-002-validation-*.json
```

### Jenkins Pipeline Example

```groovy
stage('AT-E1-002 Validation') {
    steps {
        sh './tests/acceptance/run-test.sh AT-E1-002'
    }
    post {
        always {
            archiveArtifacts artifacts: 'reports/at-e1-002-validation-*.json'
        }
    }
}
```

## Dependencies

The issue specifies the following dependencies:

- **Issue #5**: Deploy ArgoCD
- **Issue #6**: Git repo structure
- **Issue #7**: App-of-apps pattern

Ensure these are completed before running AT-E1-002 tests.

## Additional Resources

- [Architecture Documentation](../architecture.md)
- [Implementation Plan](../implementation-plan/IMPLEMENTATION_HANDOFF.md)
- [ArgoCD Bootstrap Feature](../../tests/bdd/features/argocd_bootstrap.feature)
- [ArgoCD Deployment Feature](../../tests/bdd/features/argocd-deployment.feature)
- [Week 1 Detailed Tasks](../implementation-plan/week1-detailed-tasks.md)
