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

// TestAzureResourceGroupModuleValidation validates the new azure/resource-group module structure
func TestAzureResourceGroupModuleValidation(t *testing.T) {
	t.Parallel()

	// This is a validation test that doesn't deploy resources
	// It only validates the module configuration

	// Construct terraform options without variables for validation
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../infra/terraform/modules/azure/resource-group",
		NoColor:      true,
	})

	// Run terraform init and validate
	terraform.Init(t, terraformOptions)
	terraform.Validate(t, terraformOptions)
}

// TestAzureResourceGroupModuleIntegration tests the new azure/resource-group module with real resources
func TestAzureResourceGroupModuleIntegration(t *testing.T) {
	t.Parallel()

	// Skip if not running integration tests
	if os.Getenv("RUN_TERRAFORM_INTEGRATION_TESTS") != "true" {
		t.Skip("Skipping integration test. Set RUN_TERRAFORM_INTEGRATION_TESTS=true to run.")
	}

	// Generate unique names for resources
	uniqueID := random.UniqueId()
	resourceGroupName := fmt.Sprintf("fawkes-test-rg-%s", uniqueID)
	location := "eastus2"

	// Construct terraform options
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../infra/terraform/modules/azure/resource-group",
		Vars: map[string]interface{}{
			"name":     resourceGroupName,
			"location": location,
			"tags": map[string]string{
				"Environment": "test",
				"ManagedBy":   "Terratest",
				"Purpose":     "automated-testing",
			},
		},
		NoColor: true,
	})

	// Clean up resources at the end of the test
	defer terraform.Destroy(t, terraformOptions)

	// Run terraform init and apply
	terraform.InitAndApply(t, terraformOptions)

	// Validate outputs
	outputName := terraform.Output(t, terraformOptions, "name")
	outputLocation := terraform.Output(t, terraformOptions, "location")
	outputID := terraform.Output(t, terraformOptions, "id")

	// Assert that outputs match expected values
	assert.Equal(t, resourceGroupName, outputName, "Resource group name should match input")
	assert.Equal(t, location, outputLocation, "Resource group location should match input")
	assert.NotEmpty(t, outputID, "Resource group ID should not be empty")

	// Verify the resource group ID format
	expectedIDPrefix := fmt.Sprintf("/subscriptions/")
	assert.Contains(t, outputID, expectedIDPrefix, "Resource group ID should contain subscription ID")
}
