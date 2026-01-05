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
	"fmt"
	"os"
	"testing"

	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

// TestAzureNetworkModuleValidation validates the new azure/network module structure
func TestAzureNetworkModuleValidation(t *testing.T) {
	t.Parallel()

	// This is a validation test that doesn't deploy resources
	// It only validates the module configuration

	// Construct terraform options without variables for validation
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../infra/terraform/modules/azure/network",
		NoColor:      true,
	})

	// Run terraform init and validate
	terraform.Init(t, terraformOptions)
	terraform.Validate(t, terraformOptions)
}

// TestAzureNetworkModuleIntegration tests the new azure/network module with real resources
func TestAzureNetworkModuleIntegration(t *testing.T) {
	t.Parallel()

	// Skip if not running integration tests
	if os.Getenv("RUN_TERRAFORM_INTEGRATION_TESTS") != "true" {
		t.Skip("Skipping integration test. Set RUN_TERRAFORM_INTEGRATION_TESTS=true to run.")
	}

	// Generate unique names for resources
	uniqueID := random.UniqueId()
	resourceGroupName := fmt.Sprintf("fawkes-test-net-rg-%s", uniqueID)
	vnetName := fmt.Sprintf("fawkes-test-vnet-%s", uniqueID)
	subnetName := fmt.Sprintf("fawkes-test-subnet-%s", uniqueID)
	location := "eastus2"

	// First create resource group
	rgTerraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../infra/terraform/modules/azure/resource-group",
		Vars: map[string]interface{}{
			"name":     resourceGroupName,
			"location": location,
		},
		NoColor: true,
	})

	defer terraform.Destroy(t, rgTerraformOptions)
	terraform.InitAndApply(t, rgTerraformOptions)

	// Then create network
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../infra/terraform/modules/azure/network",
		Vars: map[string]interface{}{
			"vnet_name":               vnetName,
			"location":                location,
			"resource_group_name":     resourceGroupName,
			"address_space":           []string{"10.0.0.0/16"},
			"subnet_name":             subnetName,
			"subnet_address_prefixes": []string{"10.0.1.0/24"},
			"tags": map[string]string{
				"Environment": "test",
				"ManagedBy":   "Terratest",
			},
		},
		NoColor: true,
	})

	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)

	// Validate outputs
	outputVnetName := terraform.Output(t, terraformOptions, "vnet_name")
	outputSubnetName := terraform.Output(t, terraformOptions, "subnet_name")
	outputVnetID := terraform.Output(t, terraformOptions, "vnet_id")
	outputSubnetID := terraform.Output(t, terraformOptions, "subnet_id")

	// Assert that outputs match expected values
	assert.Equal(t, vnetName, outputVnetName, "VNet name should match input")
	assert.Equal(t, subnetName, outputSubnetName, "Subnet name should match input")
	assert.NotEmpty(t, outputVnetID, "VNet ID should not be empty")
	assert.NotEmpty(t, outputSubnetID, "Subnet ID should not be empty")
}
