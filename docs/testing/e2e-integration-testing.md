# End-to-End Integration Testing

This document describes the comprehensive end-to-end (E2E) integration testing framework for the Fawkes platform. The E2E tests validate the complete workflow from service scaffolding through deployment to metrics collection.

## Overview

The E2E integration test suite validates that all platform components work together seamlessly without manual intervention. It tests the complete golden path workflow:

```
Scaffold → Build → Security Scan → Deploy → Metrics → Observability
```

## Test Architecture

### Test Layers

```
┌─────────────────────────────────────────────────────────────────┐
│                    E2E Test Orchestration                        │
│              (run-e2e-integration-test.sh)                       │
└───────────────────────┬─────────────────────────────────────────┘
                        │
        ┌───────────────┼───────────────┐
        │               │               │
        ▼               ▼               ▼
┌──────────────┐ ┌──────────────┐ ┌──────────────┐
│ BDD Features │ │ Shell Tests  │ │ Validation   │
│  (Behave)    │ │   Scripts    │ │   Scripts    │
└──────────────┘ └──────────────┘ └──────────────┘
        │               │               │
        └───────────────┼───────────────┘
                        │
        ┌───────────────┼───────────────┐
        │               │               │
        ▼               ▼               ▼
┌──────────────┐ ┌──────────────┐ ┌──────────────┐
│  Platform    │ │   GitOps     │ │  Observability│
│ Components   │ │   Layer      │ │     Stack    │
└──────────────┘ └──────────────┘ └──────────────┘
```

### Test Phases

The E2E test executes the following phases in order:

1. **Pre-flight Checks** - Verify cluster access and required tools
2. **Component Health** - Validate all platform components are running
3. **Scaffold Validation** - Verify golden path templates are available
4. **Build Pipeline** - Validate Jenkins CI/CD configuration
5. **Security Scanning** - Verify security tools integration
6. **GitOps Deployment** - Validate ArgoCD deployment workflow
7. **DORA Metrics** - Verify metrics collection from all sources
8. **Observability** - Validate monitoring and logging stack
9. **Service Catalog** - Verify Backstage integration
10. **Integration Points** - Validate all component integrations
11. **Performance** - Validate resource utilization
12. **Automation** - Verify no manual steps required

## Quick Start

### Prerequisites

- Kubernetes cluster with Fawkes platform deployed
- `kubectl` configured with cluster access
- Required tools: `kubectl`, `helm`, `jq`, `curl`
- Python 3.8+ with `behave` and `kubernetes` packages (for BDD tests)

### Running E2E Tests

#### Full Integration Test

Run the complete E2E integration test:

```bash
make test-e2e-integration
```

Or directly:

```bash
./tests/e2e/run-e2e-integration-test.sh
```

#### Verbose Mode

Run with detailed output:

```bash
make test-e2e-integration-verbose
```

Or:

```bash
./tests/e2e/run-e2e-integration-test.sh --verbose
```

#### Dry Run

See what would be tested without executing:

```bash
make test-e2e-integration-dry-run
```

#### Custom Configuration

Run with custom namespaces:

```bash
./tests/e2e/run-e2e-integration-test.sh \
  --namespace fawkes \
  --argocd-ns fawkes \
  --monitoring-ns monitoring \
  --devlake-ns fawkes-devlake
```

#### Skip Cleanup

Preserve test resources for debugging:

```bash
./tests/e2e/run-e2e-integration-test.sh --skip-cleanup
```

### Running BDD Feature Tests

Run the complete BDD test suite:

```bash
behave tests/bdd/features/e2e-platform-integration.feature
```

Run specific scenarios:

```bash
behave tests/bdd/features/e2e-platform-integration.feature \
  --name "Complete workflow - Scaffold new Python service"
```

Run with tags:

```bash
# Run all E2E tests
behave tests/bdd/features --tags=@e2e

# Run only scaffold tests
behave tests/bdd/features --tags=@scaffold

# Run security tests
behave tests/bdd/features --tags=@security
```

## Test Scenarios

### Complete Workflow Tests

#### Scaffold to Deploy

Tests the complete workflow from scaffolding a new service to successful deployment:

- ✅ Golden path template usage
- ✅ Repository creation with proper structure
- ✅ CI/CD pipeline configuration
- ✅ Automated build and test
- ✅ Security scanning (secrets, SAST, container scan)
- ✅ GitOps deployment via ArgoCD
- ✅ Service becomes healthy
- ✅ Metrics collection
- ✅ Backstage catalog registration

#### Component Integration

Tests that all platform components integrate correctly:

- ✅ GitHub → Jenkins (webhook trigger)
- ✅ Jenkins → DevLake (build metrics)
- ✅ Jenkins → Harbor (image push)
- ✅ Jenkins → SonarQube (quality analysis)
- ✅ ArgoCD → DevLake (deployment events)
- ✅ ArgoCD → Kubernetes (app sync)
- ✅ Backstage → GitHub (repo discovery)
- ✅ Backstage → ArgoCD (status visibility)
- ✅ Prometheus → Apps (metrics scraping)
- ✅ Grafana → Prometheus (visualization)

### Security Testing

#### Security Scanning Pipeline

Tests all security scanning stages:

- ✅ Gitleaks secrets detection
- ✅ SonarQube SAST analysis
- ✅ SonarQube quality gate enforcement
- ✅ Trivy container vulnerability scanning
- ✅ Security report archiving
- ✅ Build failure on HIGH/CRITICAL findings

### Metrics Collection

#### DORA Metrics

Tests automated DORA metrics collection:

- ✅ Deployment Frequency (from ArgoCD)
- ✅ Lead Time for Changes (commit → deployment)
- ✅ Change Failure Rate (failed syncs / total)
- ✅ Mean Time to Restore (incident → recovery)
- ✅ Metrics visible in Grafana dashboards

### Performance Testing

#### Resource Utilization

Validates platform performance:

- ✅ Cluster CPU usage < 70%
- ✅ Cluster memory usage < 70%
- ✅ Pod health > 90%
- ✅ Build time < 5 minutes (Python small)
- ✅ Deployment time < 2 minutes
- ✅ ArgoCD sync < 30 seconds

### Automation Validation

#### No Manual Intervention

Validates full automation:

- ✅ ArgoCD auto-sync enabled
- ✅ Webhook automation configured
- ✅ CI/CD fully automated
- ✅ Metrics collection automatic
- ✅ No human approval required

## Test Reports

### Report Generation

E2E tests automatically generate reports:

```bash
./tests/e2e/run-e2e-integration-test.sh --report-dir ./test-reports/e2e
```

Report location: `./test-reports/e2e/e2e-test-report-YYYYMMDD-HHMMSS.txt`

### Report Contents

Each report includes:

- **Execution metadata** (timestamp, configuration)
- **Test results** (total, passed, failed)
- **Component health status**
- **Integration validation results**
- **Performance metrics**
- **Recommendations** (if issues found)

### Example Report

```
Fawkes E2E Integration Test Report
Generated: 2024-12-15 10:30:00

Configuration:
  Namespace: fawkes
  ArgoCD Namespace: fawkes
  Monitoring Namespace: monitoring
  DevLake Namespace: fawkes-devlake

Results:
  Total Tests: 12
  Passed: 12
  Failed: 0

✓ ALL TESTS PASSED

The Fawkes platform end-to-end integration is working correctly!
All components are properly integrated from scaffold to deploy to metrics.
```

## Continuous Integration

### CI/CD Pipeline Integration

Add E2E tests to your CI/CD pipeline:

#### GitHub Actions

```yaml
name: E2E Tests

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  e2e-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Setup kubeconfig
        run: |
          mkdir -p ~/.kube
          echo "${{ secrets.KUBECONFIG }}" > ~/.kube/config

      - name: Run E2E Integration Tests
        run: |
          make test-e2e-integration

      - name: Upload Test Reports
        if: always()
        uses: actions/upload-artifact@v3
        with:
          name: e2e-test-reports
          path: test-reports/e2e/
```

#### Jenkins Pipeline

```groovy
stage('E2E Integration Test') {
    steps {
        sh 'make test-e2e-integration'
    }
    post {
        always {
            archiveArtifacts artifacts: 'test-reports/e2e/*.txt', allowEmptyArchive: true
        }
    }
}
```

### Scheduled Testing

Run E2E tests on a schedule:

```bash
# Cron job to run daily at 2 AM
0 2 * * * cd /path/to/fawkes && make test-e2e-integration >> /var/log/fawkes-e2e.log 2>&1
```

## Troubleshooting

### Common Issues

#### Tests Fail at Pre-flight Checks

**Symptom**: Tests fail before reaching component health checks

**Causes**:

- Cluster not accessible
- Required tools not installed
- Incorrect namespace configuration

**Solutions**:

```bash
# Verify cluster access
kubectl cluster-info

# Check namespaces
kubectl get namespaces | grep -E "fawkes|argocd|monitoring"

# Install required tools
brew install kubectl helm jq  # macOS
apt-get install kubectl jq    # Ubuntu/Debian
```

#### Component Health Checks Fail

**Symptom**: One or more components reported as unhealthy

**Causes**:

- Component not deployed
- Component pods not running
- Resource constraints

**Solutions**:

```bash
# Check component status
kubectl get pods -n fawkes
kubectl get pods -n monitoring

# Check pod logs
kubectl logs -n fawkes deployment/backstage

# Check resource usage
kubectl top nodes
kubectl top pods -n fawkes
```

#### ArgoCD Sync Tests Fail

**Symptom**: ArgoCD sync validation fails

**Causes**:

- ArgoCD not deployed
- No applications configured
- Auto-sync not enabled

**Solutions**:

```bash
# Check ArgoCD
kubectl get deployment argocd-server -n fawkes

# List applications
kubectl get applications -n fawkes

# Check app status
argocd app list
argocd app get <app-name>
```

#### Metrics Collection Tests Fail

**Symptom**: DORA metrics validation fails

**Causes**:

- DevLake not deployed
- Webhook configuration missing
- Network policies blocking traffic

**Solutions**:

```bash
# Check DevLake
kubectl get pods -n fawkes-devlake

# Check webhook configuration
kubectl get cm -n fawkes-devlake

# Test connectivity
kubectl exec -n fawkes <jenkins-pod> -- curl http://devlake.fawkes-devlake.svc:8080/health
```

### Debug Mode

Run tests with maximum verbosity:

```bash
./tests/e2e/run-e2e-integration-test.sh --verbose --skip-cleanup
```

This will:

- Show detailed progress for each test
- Preserve test resources for inspection
- Display all kubectl/API calls

### Manual Validation

Manually verify components:

```bash
# Component health
make validate-at-e1-002  # ArgoCD
make validate-at-e1-003  # Backstage
make validate-at-e1-004  # Jenkins
make validate-at-e1-006  # Observability
make validate-at-e1-007  # DORA Metrics

# Integration points
kubectl get applications -n fawkes
kubectl get pods -A
kubectl top nodes
```

## Best Practices

### Test Execution

1. **Run E2E tests regularly** - At least daily in development, on every release
2. **Use dry-run first** - Understand what will be tested before executing
3. **Check pre-requisites** - Ensure cluster is healthy before testing
4. **Review reports** - Always check test reports for warnings
5. **Monitor resources** - Ensure cluster has sufficient resources

### Test Development

1. **Keep tests independent** - Each test should be self-contained
2. **Use descriptive names** - Test names should clearly describe what's being tested
3. **Add cleanup** - Always clean up test resources
4. **Handle failures gracefully** - Tests should fail fast with clear messages
5. **Document assumptions** - Clearly document what's required for tests to pass

### Integration with Development Workflow

1. **Run before merge** - Execute E2E tests before merging PRs
2. **Block on failure** - Don't deploy if E2E tests fail
3. **Track trends** - Monitor test execution time and failure rates
4. **Automate remediation** - Auto-create issues for E2E test failures

## Test Coverage

The E2E test suite covers:

### Platform Components (100%)

- ✅ ArgoCD (GitOps)
- ✅ Backstage (Developer Portal)
- ✅ Jenkins (CI/CD)
- ✅ Prometheus (Metrics)
- ✅ Grafana (Visualization)
- ✅ DevLake (DORA Metrics)
- ✅ Harbor (Container Registry)
- ✅ SonarQube (SAST)
- ✅ Trivy (Container Scanning)
- ✅ Gitleaks (Secrets Detection)

### Integration Points (100%)

- ✅ GitHub → Jenkins webhooks
- ✅ Jenkins → DevLake metrics
- ✅ Jenkins → Harbor images
- ✅ Jenkins → SonarQube analysis
- ✅ ArgoCD → Kubernetes sync
- ✅ ArgoCD → DevLake deployments
- ✅ Backstage → GitHub discovery
- ✅ Backstage → ArgoCD status
- ✅ Prometheus → Apps scraping
- ✅ Grafana → Prometheus queries

### Workflows (100%)

- ✅ Service scaffolding
- ✅ Code build and test
- ✅ Security scanning
- ✅ Container build and push
- ✅ GitOps deployment
- ✅ Health monitoring
- ✅ Metrics collection
- ✅ Catalog registration

## Maintenance

### Updating Tests

When adding new platform components:

1. Add health check to `check_component_health()`
2. Add integration validation to `test_integration_points()`
3. Add BDD scenarios to `e2e-platform-integration.feature`
4. Add step definitions to `test_e2e_integration.py`
5. Update documentation

### Test Data Management

E2E tests use:

- **No persistent test data** - Tests are self-contained
- **Cleanup after execution** - Resources cleaned up automatically
- **No external dependencies** - Tests use only platform components

### Version Compatibility

E2E tests are compatible with:

- **Kubernetes**: 1.25+
- **ArgoCD**: 2.9+
- **Jenkins**: 2.4+
- **Prometheus**: 2.40+
- **Grafana**: 9.0+

## Performance Benchmarks

### Expected Test Duration

| Test Phase            | Duration       | Notes                         |
| --------------------- | -------------- | ----------------------------- |
| Pre-flight checks     | 10s            | Tool and cluster verification |
| Component health      | 20s            | Pod status checks             |
| Scaffold validation   | 15s            | Template structure checks     |
| Build pipeline        | 30s            | Pipeline configuration check  |
| Security scanning     | 30s            | Tool integration verification |
| GitOps deployment     | 45s            | ArgoCD sync validation        |
| DORA metrics          | 20s            | DevLake connectivity check    |
| Observability         | 30s            | Monitoring stack validation   |
| Integration points    | 40s            | All integrations verified     |
| Performance checks    | 20s            | Resource utilization          |
| Automation validation | 15s            | Auto-sync verification        |
| **Total**             | **~5 minutes** | Complete test suite           |

### Resource Requirements

- **CPU**: Minimal (< 0.1 core)
- **Memory**: Minimal (< 100Mi)
- **Network**: Minimal (mostly API calls)
- **Storage**: < 10Mi (for reports)

## References

### Related Documentation

- [Architecture Overview](../architecture.md)
- [Golden Path Templates](../golden-path-usage.md)
- [DORA Metrics](../../platform/apps/devlake/README.md)
- [Security Scanning](../how-to/security/quality-gates-configuration.md)
- [GitOps Guide](../how-to/gitops-deployment.md)

### External Resources

- [BDD with Behave](https://behave.readthedocs.io/)
- [Kubernetes Testing](https://kubernetes.io/docs/tasks/debug/)
- [DORA Metrics](https://dora.dev/)
- [GitOps Principles](https://opengitops.dev/)

## Contributing

To contribute E2E tests:

1. **Create feature file** in `tests/bdd/features/`
2. **Implement step definitions** in `tests/bdd/step_definitions/`
3. **Update orchestration script** if adding new phases
4. **Document the test** in this guide
5. **Submit PR** with test examples

### Test Template

```gherkin
@e2e @my-feature
Feature: My New Platform Feature
  As a platform user
  I want to use my new feature
  So that I can achieve my goal

  Scenario: Feature works end-to-end
    Given the platform is deployed
    When I use the new feature
    Then it should work correctly
    And metrics should be collected
```

---

**Last Updated**: December 15, 2024
**Version**: 1.0
**Maintainer**: Fawkes Platform Team
