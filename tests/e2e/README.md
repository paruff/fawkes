# End-to-End Integration Tests

This directory contains end-to-end (E2E) integration tests for the Fawkes platform.

## Overview

The E2E tests validate the complete platform workflow from service scaffolding through deployment to metrics collection, ensuring all components integrate seamlessly without manual intervention.

## Test Files

### Core Test Scripts

- **`run-e2e-integration-test.sh`** - Main E2E test orchestration script

  - 12 test phases validating complete platform
  - Automated report generation
  - Multiple execution modes (standard, verbose, dry-run)
  - See `./run-e2e-integration-test.sh --help` for options

- **`argocd-sync-test.sh`** - ArgoCD-specific E2E sync tests

  - Tests GitOps sync workflow
  - Validates application health
  - See `./argocd-sync-test.sh --help` for options

- **`backstage-validation-test.sh`** - Backstage developer portal validation
  - Tests catalog integration
  - Validates template scaffolder
  - See `./backstage-validation-test.sh --help` for options

## Quick Start

### Run Complete E2E Test

```bash
# From repository root
make test-e2e-integration

# Or directly
./tests/e2e/run-e2e-integration-test.sh
```

### Run with Verbose Output

```bash
make test-e2e-integration-verbose

# Or
./tests/e2e/run-e2e-integration-test.sh --verbose
```

### Preview Tests (Dry Run)

```bash
make test-e2e-integration-dry-run

# Or
./tests/e2e/run-e2e-integration-test.sh --dry-run
```

### Run Specific E2E Tests

```bash
# ArgoCD sync tests
make test-e2e-argocd

# All E2E tests
make test-e2e-all
```

## Test Workflow

The complete E2E test validates:

1. **Pre-flight Checks** - Cluster access and tools
2. **Component Health** - All platform components running
3. **Scaffold** - Golden path templates available
4. **Build Pipeline** - Jenkins CI/CD configured
5. **Security Scanning** - All security tools integrated
6. **GitOps Deployment** - ArgoCD sync working
7. **DORA Metrics** - Metrics collection functional
8. **Observability** - Monitoring stack operational
9. **Service Catalog** - Backstage integration working
10. **Integration Points** - All component integrations validated
11. **Performance** - Resource utilization within limits
12. **Automation** - No manual steps required

## Test Reports

Tests automatically generate reports in `test-reports/e2e/`:

```
test-reports/e2e/
└── e2e-test-report-20241215-103000.txt
```

Each report includes:

- Test execution summary
- Component health status
- Integration validation results
- Performance metrics
- Recommendations (if issues found)

## Configuration

### Environment Variables

```bash
# Namespace configuration
export NAMESPACE=fawkes
export ARGOCD_NAMESPACE=fawkes
export MONITORING_NAMESPACE=monitoring
export DEVLAKE_NAMESPACE=fawkes-devlake

# Test configuration
export TEST_SERVICE_NAME=e2e-test-service
export SKIP_CLEANUP=false
export VERBOSE=false
export TIMEOUT=1200
```

### Command-Line Options

```bash
./run-e2e-integration-test.sh [OPTIONS]

Options:
  -n, --namespace         Fawkes namespace (default: fawkes)
  -a, --argocd-ns         ArgoCD namespace (default: fawkes)
  -m, --monitoring-ns     Monitoring namespace (default: monitoring)
  -d, --devlake-ns        DevLake namespace (default: fawkes-devlake)
  -s, --service-name      Test service name
  -t, --timeout           Timeout in seconds (default: 1200)
  -r, --report-dir        Report directory
  --skip-cleanup          Skip cleanup after test
  --dry-run               Show what would be tested
  -v, --verbose           Verbose output
  -h, --help              Show help
```

## Prerequisites

### Required Tools

- `kubectl` - Kubernetes CLI
- `helm` - Kubernetes package manager
- `jq` - JSON processor
- `curl` - HTTP client
- `bc` - Calculator (for resource calculations)

### Platform Requirements

- Kubernetes cluster accessible
- Fawkes platform deployed
- Core namespaces created:
  - `fawkes` - Platform components
  - `monitoring` - Observability stack
  - `fawkes-devlake` - DORA metrics (optional)

### Install Tools

```bash
# macOS
brew install kubectl helm jq curl bc

# Ubuntu/Debian
apt-get install kubectl jq curl bc
```

## Usage Examples

### Basic Execution

```bash
# Standard test run
./run-e2e-integration-test.sh

# With custom namespace
./run-e2e-integration-test.sh --namespace my-fawkes

# Skip cleanup for debugging
./run-e2e-integration-test.sh --skip-cleanup
```

### Advanced Execution

```bash
# Full customization
./run-e2e-integration-test.sh \
  --namespace fawkes \
  --argocd-ns fawkes \
  --monitoring-ns monitoring \
  --devlake-ns fawkes-devlake \
  --service-name my-test \
  --timeout 1800 \
  --verbose

# Custom report directory
./run-e2e-integration-test.sh \
  --report-dir ./my-reports \
  --verbose
```

### CI/CD Integration

#### GitHub Actions

```yaml
- name: Run E2E Tests
  run: ./tests/e2e/run-e2e-integration-test.sh --verbose

- name: Upload Reports
  if: always()
  uses: actions/upload-artifact@v3
  with:
    name: e2e-reports
    path: test-reports/e2e/
```

#### Jenkins Pipeline

```groovy
stage('E2E Tests') {
    steps {
        sh './tests/e2e/run-e2e-integration-test.sh --verbose'
    }
    post {
        always {
            archiveArtifacts 'test-reports/e2e/*.txt'
        }
    }
}
```

## Test Output

### Successful Test Run

```
========================================
Fawkes E2E Integration Test
========================================
[INFO] Testing complete platform workflow: scaffold → deploy → metrics

========================================
Pre-flight Checks
========================================
[✓] Required tools available
[✓] Kubernetes cluster accessible
[✓] All required namespaces exist

========================================
Component Health Checks
========================================
[✓] ArgoCD is healthy (3 pods running)
[✓] Backstage is healthy (2 pods running)
[✓] Jenkins is healthy (1 pods running)
...

============================================
       E2E Integration Test Summary
============================================

Execution Time: 5m 23s
Total Tests:    12
Passed:         12
Failed:         0

[✓] ALL TESTS PASSED ✓

The Fawkes platform end-to-end integration is working correctly!
```

### Failed Test Run

```
========================================
Component Health Checks
========================================
[✓] ArgoCD is healthy (3 pods running)
[✗] Backstage is not healthy

============================================
       E2E Integration Test Summary
============================================

Execution Time: 2m 15s
Total Tests:    12
Passed:         10
Failed:         2

[✗] SOME TESTS FAILED ✗

Please review the failed tests above and check component health.
```

## Troubleshooting

### Tests Fail at Pre-flight

**Issue**: Cannot access Kubernetes cluster

**Solution**:

```bash
# Check cluster access
kubectl cluster-info

# Check kubeconfig
export KUBECONFIG=~/.kube/config
kubectl get nodes
```

### Component Health Checks Fail

**Issue**: Component reported as unhealthy

**Solution**:

```bash
# Check pod status
kubectl get pods -n fawkes

# Check pod logs
kubectl logs -n fawkes deployment/backstage

# Check events
kubectl get events -n fawkes --sort-by='.lastTimestamp'
```

### Tests Timeout

**Issue**: Tests exceed timeout limit

**Solution**:

```bash
# Increase timeout
./run-e2e-integration-test.sh --timeout 1800

# Check cluster performance
kubectl top nodes
kubectl top pods -n fawkes
```

## Related Documentation

- **Main E2E Guide**: `../../docs/testing/e2e-integration-testing.md`
- **BDD Features**: `../bdd/features/e2e-platform-integration.feature`
- **Architecture**: `../../docs/architecture.md`
- **Golden Path**: `../../docs/golden-path-usage.md`

## Contributing

To add new E2E tests:

1. Add test phase to `run-e2e-integration-test.sh`
2. Create BDD scenario in `../bdd/features/e2e-platform-integration.feature`
3. Add step definitions in `../bdd/step_definitions/test_e2e_integration.py`
4. Update documentation
5. Test locally before submitting PR

## Support

### Getting Help

```bash
# Show script help
./run-e2e-integration-test.sh --help

# View detailed documentation
cat ../../docs/testing/e2e-integration-testing.md

# Run in verbose mode
./run-e2e-integration-test.sh --verbose
```

### Common Commands

```bash
# Quick validation
make test-e2e-integration-dry-run

# Full test
make test-e2e-integration

# Debug mode
make test-e2e-integration-verbose

# All E2E tests
make test-e2e-all
```

---

**For complete documentation, see**: `../../docs/testing/e2e-integration-testing.md`

**For implementation details, see**: `../../E2E_TESTING_SUMMARY.md`
