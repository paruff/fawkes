# Terratest Suite for Fawkes Infrastructure

This directory contains automated tests for Terraform modules using [Terratest](https://terratest.gruntwork.io/), a Go library that provides patterns and helper functions for testing infrastructure code.

## Overview

The test suite validates:

1. **Unit Tests**: Individual Terraform modules in isolation
2. **Integration Tests**: Complete infrastructure deployments end-to-end
3. **Cost Estimation Tests**: Infrastructure cost validation and regression testing

## Test Categories

### Unit Tests

Each Terraform module has dedicated unit tests:

- **`azure_resource_group_test.go`**: Tests for Azure Resource Group module
- **`azure_network_test.go`**: Tests for Azure Virtual Network module
- **`azure_aks_cluster_test.go`**: Tests for Azure AKS cluster module
- **`argocd_helm_test.go`**: Tests for ArgoCD Helm deployment module

Unit tests validate:
- Module outputs match expected values
- Input validation works correctly
- Resources are created with proper configuration
- Tags and metadata are applied correctly

### Integration Tests

**`integration_test.go`** contains end-to-end tests that deploy complete infrastructure stacks:

- Full Azure infrastructure (Resource Group → Network → AKS)
- Multi-module dependencies and data flow
- Complete platform deployment scenarios

### Cost Estimation Tests

**`cost_estimation_test.go`** validates infrastructure costs using Infracost:

- Estimates monthly costs for each module
- Validates costs stay within expected ranges
- Prevents cost regressions from configuration changes
- Provides cost transparency before deployment

## Prerequisites

### Required Tools

1. **Go 1.21+**: Install from [golang.org](https://golang.org/dl/)
2. **Terraform 1.6+**: Install from [terraform.io](https://www.terraform.io/downloads)
3. **Azure CLI**: For Azure authentication - [docs](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
4. **Infracost** (optional): For cost estimation tests - [infracost.io](https://www.infracost.io/docs/)

### Azure Authentication

Authenticate with Azure before running integration tests:

```bash
az login
az account set --subscription "your-subscription-id"
```

### Environment Setup

1. **Install Go dependencies**:
   ```bash
   cd tests/terratest
   go mod download
   ```

2. **Set up environment variables**:
   ```bash
   # Required for Azure tests
   export ARM_SUBSCRIPTION_ID="your-subscription-id"
   export ARM_TENANT_ID="your-tenant-id"
   
   # Optional: For cost estimation tests
   export INFRACOST_API_KEY="your-infracost-api-key"
   ```

## Running Tests

### Quick Validation (No Cloud Resources)

Run validation tests that check Terraform syntax without deploying resources:

```bash
cd tests/terratest
go test -v -timeout 30m -run "Validation"
```

### Unit Tests (Deploys Real Resources)

⚠️ **Warning**: These tests create real Azure resources and incur costs.

Run individual module tests:

```bash
# Test a specific module
export RUN_TERRAFORM_INTEGRATION_TESTS=true
go test -v -timeout 30m -run TestAzureResourceGroupModule

# Test all unit tests
export RUN_TERRAFORM_INTEGRATION_TESTS=true
go test -v -timeout 30m -run "Module$"
```

### Integration Tests (Expensive, Time-Consuming)

⚠️ **Warning**: E2E tests can take 20-30 minutes and cost $10-20.

```bash
export RUN_TERRAFORM_E2E_TESTS=true
go test -v -timeout 60m -run TestAzureInfrastructureE2E
```

### Cost Estimation Tests

```bash
export RUN_TERRAFORM_COST_TESTS=true
go test -v -timeout 10m -run "Cost"
```

### Run All Tests

```bash
# Run all tests (requires all environment variables)
export RUN_TERRAFORM_INTEGRATION_TESTS=true
export RUN_TERRAFORM_E2E_TESTS=true
export RUN_TERRAFORM_COST_TESTS=true

go test -v -timeout 60m ./...
```

### Parallel Execution

Terratest tests use `t.Parallel()` for faster execution:

```bash
# Run tests in parallel with 4 concurrent tests
go test -v -timeout 60m -parallel 4 ./...
```

## Test Options

### Environment Variables

| Variable | Purpose | Default |
|----------|---------|---------|
| `RUN_TERRAFORM_INTEGRATION_TESTS` | Enable integration tests that deploy resources | `false` |
| `RUN_TERRAFORM_E2E_TESTS` | Enable expensive end-to-end tests | `false` |
| `RUN_TERRAFORM_COST_TESTS` | Enable cost estimation tests | `false` |
| `ARM_SUBSCRIPTION_ID` | Azure subscription for testing | Required for Azure tests |
| `ARM_TENANT_ID` | Azure tenant ID | Required for Azure tests |
| `INFRACOST_API_KEY` | Infracost API key for cost estimation | Optional |
| `KUBECONFIG` | Path to kubeconfig for Kubernetes tests | `~/.kube/config` |

### Test Filters

Run specific test patterns:

```bash
# Run all validation tests
go test -v -run "Validation"

# Run all Azure tests
go test -v -run "Azure"

# Run all cost tests
go test -v -run "Cost"

# Run specific test
go test -v -run TestAzureResourceGroupModule
```

## CI/CD Integration

### GitHub Actions

Tests are integrated into GitHub Actions workflows:

- **Validation tests** run on every PR (no cost)
- **Integration tests** run on merge to main (controlled)
- **Cost estimation** runs on infrastructure changes

Example workflow configuration:

```yaml
name: Terraform Tests

on: [pull_request]

jobs:
  terraform-validation:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-go@v5
        with:
          go-version: '1.21'
      
      - name: Run validation tests
        run: |
          cd tests/terratest
          go test -v -timeout 30m -run "Validation"
```

See `.github/workflows/terraform-tests.yml` for the complete workflow.

## Best Practices

### 1. Resource Cleanup

All tests use `defer terraform.Destroy()` to ensure resources are cleaned up even if tests fail:

```go
defer terraform.Destroy(t, terraformOptions)
terraform.InitAndApply(t, terraformOptions)
```

### 2. Unique Resource Names

Tests generate unique names to avoid conflicts:

```go
uniqueID := random.UniqueId()
resourceName := fmt.Sprintf("fawkes-test-%s", uniqueID)
```

### 3. Cost Awareness

- Unit tests use minimal resources (single nodes, small VMs)
- Integration tests are gated behind environment variables
- Tag all test resources with `ManagedBy: Terratest`

### 4. Timeouts

Set appropriate timeouts for different test types:

```go
// Unit tests: 30 minutes
go test -timeout 30m

// Integration tests: 60 minutes
go test -timeout 60m
```

### 5. Error Handling

Use `require` for critical assertions, `assert` for non-critical:

```go
require.NoError(t, err, "Terraform init must succeed")
assert.Equal(t, expected, actual, "Output should match")
```

## Troubleshooting

### Tests Hang or Timeout

- Increase timeout: `-timeout 60m`
- Check Azure credentials: `az account show`
- Verify resource quotas in Azure subscription

### Authentication Failures

```bash
# Re-authenticate with Azure
az logout
az login
az account set --subscription "your-subscription-id"

# Verify authentication
az account show
```

### Resource Cleanup Issues

If resources aren't cleaned up:

```bash
# List test resources by tag
az resource list --tag ManagedBy=Terratest

# Clean up manually
az group delete --name fawkes-test-rg-xxxxx --yes --no-wait
```

### Terraform State Lock

If tests fail and leave state locked:

```bash
# This shouldn't happen with local state, but if it does:
cd infra/terraform/modules/azure-aks-cluster
terraform force-unlock <lock-id>
```

## Cost Management

### Expected Costs

| Test Type | Duration | Estimated Cost |
|-----------|----------|----------------|
| Validation | 1-2 min | $0.00 |
| Unit Test (Resource Group) | 1-2 min | $0.00 |
| Unit Test (Network) | 2-3 min | $0.01 |
| Unit Test (AKS) | 10-15 min | $1-2 |
| Integration Test (Full Stack) | 20-30 min | $5-10 |

### Cost Optimization Tips

1. **Use B-series VMs**: `Standard_B2ms` for testing (cheapest option)
2. **Minimal Node Counts**: Use 1 node for unit tests
3. **Quick Cleanup**: Always use `defer terraform.Destroy()`
4. **Skip E2E in Dev**: Only run E2E tests in CI/CD
5. **Use Cost Estimation**: Run cost tests before integration tests

### Monitoring Costs

Set up Azure cost alerts:

```bash
# Create cost alert for test resources
az consumption budget create \
  --budget-name "terratest-budget" \
  --amount 100 \
  --time-grain Monthly \
  --category Cost
```

## Writing New Tests

### Test Template

```go
package test

import (
    "testing"
    "github.com/gruntwork-io/terratest/modules/terraform"
    "github.com/stretchr/testify/assert"
)

func TestMyModule(t *testing.T) {
    t.Parallel()
    
    // Skip if not running integration tests
    if os.Getenv("RUN_TERRAFORM_INTEGRATION_TESTS") != "true" {
        t.Skip("Skipping integration test")
    }
    
    terraformOptions := &terraform.Options{
        TerraformDir: "../../infra/terraform/modules/my-module",
        Vars: map[string]interface{}{
            "name": "test-resource",
        },
        NoColor: true,
    }
    
    defer terraform.Destroy(t, terraformOptions)
    terraform.InitAndApply(t, terraformOptions)
    
    output := terraform.Output(t, terraformOptions, "my_output")
    assert.NotEmpty(t, output)
}
```

### Guidelines

1. **Use descriptive test names**: `TestAzureResourceGroupModule`, not `TestRG`
2. **Add t.Log statements**: Help debug failures
3. **Use unique resource names**: Avoid conflicts with parallel tests
4. **Test both positive and negative cases**: Valid and invalid inputs
5. **Document complex scenarios**: Add comments explaining test logic

## References

- [Terratest Documentation](https://terratest.gruntwork.io/)
- [Terratest Examples](https://github.com/gruntwork-io/terratest/tree/master/examples)
- [Terraform Testing Best Practices](https://www.terraform.io/docs/cloud/guides/recommended-practices/part3.html)
- [Infracost Documentation](https://www.infracost.io/docs/)
- [ADR-005: Terraform Decision](../../docs/adr/ADR-005%20terraform.md)

## Support

For questions or issues:

1. Check the [Troubleshooting](#troubleshooting) section
2. Review test logs for error details
3. Open an issue in the repository
4. Consult Terratest documentation

## License

Copyright (c) 2025 Philip Ruff. Licensed under MIT License.
