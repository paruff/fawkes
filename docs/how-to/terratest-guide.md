# Terratest Configuration and Usage Guide

## Overview

This guide covers the setup, configuration, and usage of the Terratest suite for validating Fawkes infrastructure Terraform modules.

## Table of Contents

1. [Quick Start](#quick-start)
2. [Test Structure](#test-structure)
3. [Running Tests](#running-tests)
4. [CI/CD Integration](#cicd-integration)
5. [Writing Tests](#writing-tests)
6. [Cost Management](#cost-management)
7. [Troubleshooting](#troubleshooting)

## Quick Start

### Prerequisites

Install required tools:

```bash
# Install Go
brew install go  # macOS
# or download from https://golang.org/dl/

# Install Terraform
brew install terraform  # macOS
# or download from https://www.terraform.io/downloads

# Install Azure CLI (for Azure tests)
brew install azure-cli  # macOS
# or follow: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli

# Optional: Install Infracost for cost estimation
brew install infracost  # macOS
# or follow: https://www.infracost.io/docs/
```

### Setup

1. **Authenticate with Azure**:
   ```bash
   az login
   az account set --subscription "your-subscription-id"
   ```

2. **Install Go dependencies**:
   ```bash
   cd tests/terratest
   go mod download
   ```

3. **Run validation tests** (no cost):
   ```bash
   make terraform-test
   ```

## Test Structure

### Directory Layout

```
tests/terratest/
├── README.md                      # Comprehensive documentation
├── go.mod                         # Go module definition
├── go.sum                         # Go dependencies checksum
├── azure_resource_group_test.go   # Resource group module tests
├── azure_network_test.go          # Network module tests
├── azure_aks_cluster_test.go      # AKS cluster module tests
├── argocd_helm_test.go            # ArgoCD Helm module tests
├── integration_test.go            # End-to-end integration tests
└── cost_estimation_test.go        # Cost validation tests
```

### Test Categories

1. **Validation Tests**: Check Terraform syntax without deploying (fast, free)
2. **Unit Tests**: Test individual modules with real deployment (moderate cost)
3. **Integration Tests**: Test complete infrastructure stacks (higher cost)
4. **Cost Estimation Tests**: Validate infrastructure costs using Infracost

## Running Tests

### Using Make Commands

The easiest way to run tests is using the Makefile:

```bash
# Validation only (no deployment, no cost)
make terraform-test

# Integration tests (deploys resources, incurs cost)
make terraform-test-integration

# E2E tests (extensive deployment, 30+ minutes, $10-20 cost)
make terraform-test-e2e

# Cost estimation tests
make terraform-test-cost

# All tests
make terraform-test-all
```

### Using Go Test Directly

For more control, use `go test` directly:

```bash
cd tests/terratest

# Run specific test
go test -v -timeout 30m -run TestAzureResourceGroupModule

# Run all validation tests
go test -v -timeout 30m -run "Validation"

# Run tests matching pattern
go test -v -timeout 30m -run "Azure"

# Run tests in parallel
go test -v -timeout 60m -parallel 4 ./...
```

### Environment Variables

Control test execution with environment variables:

```bash
# Enable integration tests (deploys resources)
export RUN_TERRAFORM_INTEGRATION_TESTS=true

# Enable E2E tests (expensive)
export RUN_TERRAFORM_E2E_TESTS=true

# Enable cost estimation tests
export RUN_TERRAFORM_COST_TESTS=true

# Azure credentials (for integration tests)
export ARM_SUBSCRIPTION_ID="your-subscription-id"
export ARM_TENANT_ID="your-tenant-id"
export ARM_CLIENT_ID="your-client-id"
export ARM_CLIENT_SECRET="your-client-secret"

# Infracost API key (for cost tests)
export INFRACOST_API_KEY="your-api-key"
```

## CI/CD Integration

### GitHub Actions Workflow

Tests are automatically run in CI/CD via `.github/workflows/terraform-tests.yml`:

#### On Pull Request
- **Validation tests**: Always run (syntax check, no deployment)
- **Cost estimation**: Runs if Infracost is configured

#### On Merge to Main
- **Integration tests**: Run automatically to validate modules

#### Manual Trigger
- **E2E tests**: Can be triggered via workflow_dispatch with confirmation

### Setting Up Secrets

Configure these secrets in GitHub repository settings:

```yaml
# Azure credentials (for integration tests)
AZURE_CREDENTIALS: |
  {
    "clientId": "xxx",
    "clientSecret": "xxx",
    "subscriptionId": "xxx",
    "tenantId": "xxx"
  }

ARM_SUBSCRIPTION_ID: "your-subscription-id"
ARM_TENANT_ID: "your-tenant-id"
ARM_CLIENT_ID: "your-client-id"
ARM_CLIENT_SECRET: "your-client-secret"

# Optional: Infracost API key
INFRACOST_API_KEY: "your-infracost-api-key"
```

### Workflow Dispatch

Manually trigger E2E tests:

1. Go to Actions tab in GitHub
2. Select "Terraform Terratest Suite" workflow
3. Click "Run workflow"
4. Check "Run E2E tests" option
5. Confirm and run

## Writing Tests

### Test Template

```go
package test

import (
    "testing"
    "os"
    "github.com/gruntwork-io/terratest/modules/terraform"
    "github.com/stretchr/testify/assert"
)

func TestMyModule(t *testing.T) {
    t.Parallel()
    
    // Gate expensive tests
    if os.Getenv("RUN_TERRAFORM_INTEGRATION_TESTS") != "true" {
        t.Skip("Skipping integration test")
    }
    
    // Configure Terraform
    terraformOptions := &terraform.Options{
        TerraformDir: "../../infra/terraform/modules/my-module",
        Vars: map[string]interface{}{
            "name": "test-resource",
            "location": "eastus2",
        },
        NoColor: true,
    }
    
    // Always cleanup
    defer terraform.Destroy(t, terraformOptions)
    
    // Deploy infrastructure
    terraform.InitAndApply(t, terraformOptions)
    
    // Validate outputs
    output := terraform.Output(t, terraformOptions, "resource_id")
    assert.NotEmpty(t, output, "Resource ID should be set")
}
```

### Best Practices

1. **Use `t.Parallel()`**: Enables parallel test execution
2. **Gate expensive tests**: Use environment variable checks
3. **Always cleanup**: Use `defer terraform.Destroy()`
4. **Generate unique names**: Avoid resource conflicts
5. **Tag test resources**: Add `ManagedBy: Terratest` tag
6. **Set appropriate timeouts**: Allow enough time for deployment
7. **Log progress**: Use `t.Log()` for debugging

### Testing Patterns

#### Testing Module Outputs

```go
outputName := terraform.Output(t, opts, "name")
outputID := terraform.Output(t, opts, "id")
assert.Equal(t, expectedName, outputName)
assert.NotEmpty(t, outputID)
```

#### Testing Validation

```go
_, err := terraform.InitAndValidateE(t, opts)
if expectError {
    require.Error(t, err)
} else {
    require.NoError(t, err)
}
```

#### Testing Dependencies

```go
// Create dependency first
rgOptions := terraform.Options{...}
terraform.InitAndApply(t, rgOptions)
rgName := terraform.Output(t, rgOptions, "name")

// Use output in dependent module
networkOptions := terraform.Options{
    Vars: map[string]interface{}{
        "resource_group_name": rgName,
    },
}
terraform.InitAndApply(t, networkOptions)
```

## Cost Management

### Expected Costs

| Test Type | Duration | Resources | Est. Cost |
|-----------|----------|-----------|-----------|
| Validation | 1-2 min | None | $0.00 |
| Resource Group Unit | 2-3 min | 1 RG | $0.00 |
| Network Unit | 3-5 min | 1 VNet, 1 Subnet | $0.01 |
| AKS Unit | 10-15 min | 1 node cluster | $1-2 |
| Integration E2E | 25-35 min | Full stack | $5-10 |

### Cost Optimization

1. **Use minimal resources**:
   - Single node for AKS tests
   - B-series VMs (cheapest)
   - Minimal address spaces

2. **Quick cleanup**:
   - Always use `defer terraform.Destroy()`
   - Monitor for stuck resources

3. **Test selectively**:
   - Run validation tests frequently (free)
   - Run integration tests on main branch only
   - Run E2E tests manually/scheduled

4. **Monitor spending**:
   ```bash
   # Set up cost alert
   az consumption budget create \
     --budget-name terratest \
     --amount 100 \
     --time-grain Monthly
   ```

### Infracost Integration

Cost estimation with Infracost:

```bash
# Get free API key
infracost auth login

# Set environment variable
export INFRACOST_API_KEY="your-key"

# Run cost tests
make terraform-test-cost
```

## Troubleshooting

### Common Issues

#### Authentication Failures

```bash
# Re-authenticate
az logout
az login
az account show

# Verify subscription
az account list --output table
az account set --subscription "your-subscription-id"
```

#### Test Timeouts

```bash
# Increase timeout
go test -timeout 90m -run TestMyModule

# Check Azure quota
az vm list-usage --location eastus2 --output table
```

#### Resource Not Cleaned Up

```bash
# Find test resources
az resource list --tag ManagedBy=Terratest --output table

# Clean up manually
az group delete --name fawkes-test-rg-xxxxx --yes --no-wait
```

#### State Lock Issues

```bash
# Force unlock (use with caution)
cd infra/terraform/modules/my-module
terraform force-unlock <lock-id>
```

### Debug Mode

Enable verbose logging:

```bash
# Terraform debug logs
export TF_LOG=DEBUG

# Go test verbose output
go test -v -run TestMyModule

# Save output to file
go test -v -run TestMyModule 2>&1 | tee test-output.log
```

### Getting Help

1. Check test logs for specific errors
2. Review [Terratest documentation](https://terratest.gruntwork.io/)
3. Check Azure status: https://status.azure.com/
4. Open issue in repository with test logs

## References

- [Terratest Documentation](https://terratest.gruntwork.io/)
- [Terratest Examples](https://github.com/gruntwork-io/terratest/tree/master/examples)
- [Terraform Testing Guide](https://www.terraform.io/docs/language/modules/testing-experiment.html)
- [Infracost Documentation](https://www.infracost.io/docs/)
- [Azure Terraform Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [ADR-005: Terraform Decision](../../docs/adr/ADR-005%20terraform.md)

## Next Steps

1. **Run validation tests**: `make terraform-test`
2. **Set up Azure credentials**: For integration testing
3. **Configure Infracost**: For cost estimation
4. **Run integration tests**: `make terraform-test-integration`
5. **Add to CI/CD**: Tests run automatically on PRs

For detailed information, see:
- [Terratest README](README.md)
- [Module-specific documentation](../../infra/terraform/modules/)
- [CI/CD workflow](.github/workflows/terraform-tests.yml)
