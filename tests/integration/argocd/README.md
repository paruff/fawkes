# ArgoCD Integration Tests

This directory contains integration tests for ArgoCD GitOps validation (AT-E1-002).

## Test Structure

- **argocd-sync-test.sh**: E2E test script for validating ArgoCD sync operations
- **validate-at-e1-002.sh**: Comprehensive validation script for AT-E1-002 acceptance criteria
- **test-application.yaml**: Sample test application for integration testing

## Running Tests

### Run All AT-E1-002 Validations

```bash
./scripts/validate-at-e1-002.sh
```

### Run E2E Sync Tests

```bash
./tests/e2e/argocd-sync-test.sh
```

### Run with Custom Namespace

```bash
./scripts/validate-at-e1-002.sh --namespace argocd
./tests/e2e/argocd-sync-test.sh --namespace argocd
```

### Run BDD Tests

```bash
# Run ArgoCD bootstrap tests
pytest tests/bdd/test_argocd_bootstrap.py -v

# Run ArgoCD deployment tests
pytest tests/bdd/step_definitions/test_argocd_deployment.py -v

# Run all tests tagged with @gitops
pytest tests/bdd -v -m gitops
```

## Acceptance Criteria (AT-E1-002)

- [x] ArgoCD deployed via Helm to local cluster
- [x] ArgoCD CLI installed and configured
- [x] Git repository structure created (platform/apps/)
- [x] App-of-apps pattern implemented
- [x] All platform components synced from Git
- [x] Auto-sync enabled with self-heal
- [x] Rollback tested successfully
- [x] ArgoCD UI accessible via ingress

## Test Reports

Test reports are generated in the `reports/` directory with timestamps:
- `reports/at-e1-002-validation-YYYYMMDD-HHMMSS.json`

## Validation Commands

```bash
# Check all apps are synced
argocd app list | grep -c Synced

# Hard refresh platform-bootstrap
argocd app get platform-bootstrap --hard-refresh

# Check for out-of-sync applications
kubectl get applications -n fawkes -o json | \
  jq '.items[] | select(.status.sync.status != "Synced")' | \
  jq -s 'length'
```

Expected result: 0 (all applications synced)
