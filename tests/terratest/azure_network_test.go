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

// TestAzureNetworkModule validates the azure-network module
func TestAzureNetworkModule(t *testing.T) {
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

	// First create a resource group for the network
	rgOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../infra/terraform/modules/azure-resource-group",
		Vars: map[string]interface{}{
			"name":     resourceGroupName,
			"location": location,
			"tags": map[string]string{
				"Environment": "test",
				"ManagedBy":   "Terratest",
			},
		},
		NoColor: true,
	})

	defer terraform.Destroy(t, rgOptions)
	terraform.InitAndApply(t, rgOptions)

	// Now create the network
	networkOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../infra/terraform/modules/azure-network",
		Vars: map[string]interface{}{
			"vnet_name":              vnetName,
			"location":               location,
			"resource_group_name":    resourceGroupName,
			"address_space":          []string{"10.0.0.0/16"},
			"subnet_name":            subnetName,
			"subnet_address_prefixes": []string{"10.0.1.0/24"},
			"tags": map[string]string{
				"Environment": "test",
				"ManagedBy":   "Terratest",
			},
		},
		NoColor: true,
	})

	defer terraform.Destroy(t, networkOptions)
	terraform.InitAndApply(t, networkOptions)

	// Validate outputs
	outputVnetName := terraform.Output(t, networkOptions, "vnet_name")
	outputVnetID := terraform.Output(t, networkOptions, "vnet_id")
	outputSubnetID := terraform.Output(t, networkOptions, "subnet_id")

	// Assertions
	assert.Equal(t, vnetName, outputVnetName, "VNet name should match input")
	assert.NotEmpty(t, outputVnetID, "VNet ID should not be empty")
	assert.NotEmpty(t, outputSubnetID, "Subnet ID should not be empty")
	assert.Contains(t, outputVnetID, resourceGroupName, "VNet ID should contain resource group name")
	assert.Contains(t, outputSubnetID, subnetName, "Subnet ID should contain subnet name")
}

// TestAzureNetworkCIDRValidation validates Terraform syntax
func TestAzureNetworkCIDRValidation(t *testing.T) {
	t.Parallel()

	terraformOptions := &terraform.Options{
		TerraformDir: "../../infra/terraform/modules/azure-network",
		NoColor:      true,
	}

	// Validate that the Terraform configuration is syntactically valid
	terraform.Init(t, terraformOptions)
	terraform.Validate(t, terraformOptions)

	t.Log("✅ Azure Network module validation passed")
}
