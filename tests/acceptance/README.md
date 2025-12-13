# Acceptance Tests

This directory contains acceptance test runners for Fawkes platform validation.

## Test IDs and Coverage

### Epic 1: DORA 2023 Foundation

| Test ID | Category | Description | Status |
|---------|----------|-------------|--------|
| AT-E1-001 | Infrastructure | Local 4-node K8s cluster deployed | ✅ Implemented |
| AT-E1-002 | GitOps | ArgoCD manages all platform components | ✅ Implemented |
| AT-E1-003 | Developer Portal | Backstage with 3 templates functional | 🚧 Pending |
| AT-E1-004 | CI/CD | Jenkins pipelines build/test/deploy | 🚧 Pending |
| AT-E1-005 | Security | DevSecOps scanning integrated | 🚧 Pending |
| AT-E1-006 | Observability | Prometheus/Grafana stack deployed | 🚧 Pending |
| AT-E1-007 | Metrics | DORA metrics automated (4 key metrics) | 🚧 Pending |
| AT-E1-008 | Templates | 3 golden paths work end-to-end | 🚧 Pending |
| AT-E1-009 | Registry | Harbor with security scanning | 🚧 Pending |
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
