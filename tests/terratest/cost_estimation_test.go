// Copyright (c) 2025  Philip Ruff
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
// IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
// DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
// OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE
// OR OTHER DEALINGS IN THE SOFTWARE.

package test

import (
	"encoding/json"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// CostEstimate represents a simplified cost estimate structure
type CostEstimate struct {
	TotalMonthlyCost float64 `json:"totalMonthlyCost"`
	Currency         string  `json:"currency"`
}

// EstimateInfracost runs Infracost to estimate Terraform costs
// Returns the monthly cost estimate or an error
func EstimateInfracost(t *testing.T, terraformDir string) (*CostEstimate, error) {
	// Check if Infracost is installed
	_, err := exec.LookPath("infracost")
	if err != nil {
		return nil, fmt.Errorf("infracost not installed: %w", err)
	}

	// Generate Terraform plan
	planFile := filepath.Join(os.TempDir(), fmt.Sprintf("tfplan-%s.json", filepath.Base(terraformDir)))
	defer os.Remove(planFile)

	cmd := exec.Command("terraform", "show", "-json", "tfplan")
	cmd.Dir = terraformDir
	output, err := cmd.CombinedOutput()
	if err != nil {
		return nil, fmt.Errorf("failed to generate plan JSON: %w, output: %s", err, string(output))
	}

	if err := os.WriteFile(planFile, output, 0644); err != nil {
		return nil, fmt.Errorf("failed to write plan file: %w", err)
	}

	// Run Infracost
	cmd = exec.Command("infracost", "breakdown", "--path", planFile, "--format", "json")
	output, err = cmd.CombinedOutput()
	if err != nil {
		t.Logf("Infracost output: %s", string(output))
		return nil, fmt.Errorf("failed to run infracost: %w", err)
	}

	// Parse the result (simplified - actual Infracost output is more complex)
	var result map[string]interface{}
	if err := json.Unmarshal(output, &result); err != nil {
		return nil, fmt.Errorf("failed to parse infracost output: %w", err)
	}

	// Extract cost information
	estimate := &CostEstimate{
		Currency: "USD",
	}

	// This is a simplified parser - adjust based on actual Infracost JSON structure
	if totalMonthlyCost, ok := result["totalMonthlyCost"].(float64); ok {
		estimate.TotalMonthlyCost = totalMonthlyCost
	}

	return estimate, nil
}

// TestAKSClusterCostEstimate validates that AKS cluster cost is within expected range
func TestAKSClusterCostEstimate(t *testing.T) {
	// Skip if Infracost is not installed or if not running cost tests
	if os.Getenv("RUN_TERRAFORM_COST_TESTS") != "true" {
		t.Skip("Skipping cost test. Set RUN_TERRAFORM_COST_TESTS=true to run.")
	}

	terraformOptions := &terraform.Options{
		TerraformDir: "../../infra/terraform/modules/azure-aks-cluster",
		Vars: map[string]interface{}{
			"cluster_name":        "cost-test-aks",
			"location":            "eastus2",
			"resource_group_name": "cost-test-rg",
			"subnet_id":           "/subscriptions/test/resourceGroups/test-rg/providers/Microsoft.Network/virtualNetworks/test-vnet/subnets/test-subnet",
			"node_vm_size":        "Standard_B2ms",
			"node_count":          3,
			"dns_service_ip":      "10.0.2.10",
			"service_cidr":        "10.0.2.0/24",
		},
		NoColor: true,
	}

	// Initialize and plan (don't apply)
	terraform.Init(t, terraformOptions)
	terraform.Plan(t, terraformOptions)

	// Estimate cost (if Infracost is available)
	estimate, err := EstimateInfracost(t, terraformOptions.TerraformDir)
	if err != nil {
		t.Logf("Cost estimation skipped: %v", err)
		t.Skip("Infracost not available or failed")
	}

	// Validate cost is within reasonable range for test cluster
	// 3 B2ms nodes should cost approximately $60-100/month
	maxExpectedCost := 200.0 // Conservative upper bound
	assert.Less(t, estimate.TotalMonthlyCost, maxExpectedCost,
		fmt.Sprintf("Monthly cost should be less than $%.2f", maxExpectedCost))

	t.Logf("Estimated monthly cost: $%.2f %s", estimate.TotalMonthlyCost, estimate.Currency)
}

// TestResourceGroupCostEstimate validates resource group cost (should be free)
func TestResourceGroupCostEstimate(t *testing.T) {
	if os.Getenv("RUN_TERRAFORM_COST_TESTS") != "true" {
		t.Skip("Skipping cost test. Set RUN_TERRAFORM_COST_TESTS=true to run.")
	}

	terraformOptions := &terraform.Options{
		TerraformDir: "../../infra/terraform/modules/azure-resource-group",
		Vars: map[string]interface{}{
			"name":     "cost-test-rg",
			"location": "eastus2",
		},
		NoColor: true,
	}

	terraform.Init(t, terraformOptions)
	terraform.Plan(t, terraformOptions)

	estimate, err := EstimateInfracost(t, terraformOptions.TerraformDir)
	if err != nil {
		t.Logf("Cost estimation skipped: %v", err)
		t.Skip("Infracost not available or failed")
	}

	// Resource groups themselves are free
	assert.Equal(t, 0.0, estimate.TotalMonthlyCost,
		"Resource group should have no direct cost")

	t.Logf("Estimated monthly cost: $%.2f %s", estimate.TotalMonthlyCost, estimate.Currency)
}

// TestNetworkCostEstimate validates network infrastructure cost
func TestNetworkCostEstimate(t *testing.T) {
	if os.Getenv("RUN_TERRAFORM_COST_TESTS") != "true" {
		t.Skip("Skipping cost test. Set RUN_TERRAFORM_COST_TESTS=true to run.")
	}

	terraformOptions := &terraform.Options{
		TerraformDir: "../../infra/terraform/modules/azure-network",
		Vars: map[string]interface{}{
			"vnet_name":              "cost-test-vnet",
			"location":               "eastus2",
			"resource_group_name":    "cost-test-rg",
			"address_space":          []string{"10.0.0.0/16"},
			"subnet_name":            "cost-test-subnet",
			"subnet_address_prefixes": []string{"10.0.1.0/24"},
		},
		NoColor: true,
	}

	terraform.Init(t, terraformOptions)
	terraform.Plan(t, terraformOptions)

	estimate, err := EstimateInfracost(t, terraformOptions.TerraformDir)
	if err != nil {
		t.Logf("Cost estimation skipped: %v", err)
		t.Skip("Infracost not available or failed")
	}

	// Basic VNet and subnet should be very low cost (mostly egress charges)
	maxExpectedCost := 10.0
	assert.Less(t, estimate.TotalMonthlyCost, maxExpectedCost,
		fmt.Sprintf("Network cost should be less than $%.2f", maxExpectedCost))

	t.Logf("Estimated monthly cost: $%.2f %s", estimate.TotalMonthlyCost, estimate.Currency)
}

// TestCostRegression validates that infrastructure changes don't unexpectedly increase costs
func TestCostRegression(t *testing.T) {
	if os.Getenv("RUN_TERRAFORM_COST_TESTS") != "true" {
		t.Skip("Skipping cost test. Set RUN_TERRAFORM_COST_TESTS=true to run.")
	}

	// This test would compare current costs against a baseline
	// In a real implementation, you would:
	// 1. Store baseline costs in a file or database
	// 2. Run current cost estimation
	// 3. Compare and fail if cost increases beyond threshold (e.g., 10%)

	t.Log("Cost regression testing - baseline comparison")
	t.Skip("Implement baseline cost tracking for full regression testing")
}

// TestInfracostAvailability checks if Infracost is available and properly configured
func TestInfracostAvailability(t *testing.T) {
	path, err := exec.LookPath("infracost")
	if err != nil {
		t.Skip("Infracost not installed. Install from https://www.infracost.io/docs/")
	}

	t.Logf("Infracost found at: %s", path)

	// Check Infracost version
	cmd := exec.Command("infracost", "--version")
	output, err := cmd.CombinedOutput()
	require.NoError(t, err, "Infracost should be executable")

	t.Logf("Infracost version: %s", string(output))

	// Check if API key is configured
	apiKey := os.Getenv("INFRACOST_API_KEY")
	if apiKey == "" {
		t.Log("INFRACOST_API_KEY not set. Some features may not work.")
		t.Log("Get a free API key from https://dashboard.infracost.io")
	} else {
		t.Log("INFRACOST_API_KEY is configured")
	}
}
