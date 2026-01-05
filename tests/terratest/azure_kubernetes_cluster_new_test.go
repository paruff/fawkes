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

// TestAzureKubernetesClusterModuleValidation validates the new azure/kubernetes-cluster module structure
func TestAzureKubernetesClusterModuleValidation(t *testing.T) {
	t.Parallel()

	// This is a validation test that doesn't deploy resources
	// It only validates the module configuration

	// Construct terraform options without variables for validation
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../infra/terraform/modules/azure/kubernetes-cluster",
		NoColor:      true,
	})

	// Run terraform init and validate
	terraform.Init(t, terraformOptions)
	terraform.Validate(t, terraformOptions)
}

// TestAzureKubernetesClusterModuleIntegration tests the new azure/kubernetes-cluster module with real resources
func TestAzureKubernetesClusterModuleIntegration(t *testing.T) {
	t.Parallel()

	// Skip if not running integration tests
	if os.Getenv("RUN_TERRAFORM_INTEGRATION_TESTS") != "true" {
		t.Skip("Skipping integration test. Set RUN_TERRAFORM_INTEGRATION_TESTS=true to run.")
	}

	// Generate unique names for resources
	uniqueID := random.UniqueId()
	resourceGroupName := fmt.Sprintf("fawkes-test-aks-rg-%s", uniqueID)
	vnetName := fmt.Sprintf("fawkes-test-aks-vnet-%s", uniqueID)
	subnetName := fmt.Sprintf("fawkes-test-aks-subnet-%s", uniqueID)
	clusterName := fmt.Sprintf("fawkes-test-aks-%s", uniqueID)
	location := "eastus2"

	// Create resource group
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

	// Create network
	netTerraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../infra/terraform/modules/azure/network",
		Vars: map[string]interface{}{
			"vnet_name":               vnetName,
			"location":                location,
			"resource_group_name":     resourceGroupName,
			"address_space":           []string{"10.0.0.0/16"},
			"subnet_name":             subnetName,
			"subnet_address_prefixes": []string{"10.0.1.0/24"},
		},
		NoColor: true,
	})

	defer terraform.Destroy(t, netTerraformOptions)
	terraform.InitAndApply(t, netTerraformOptions)

	subnetID := terraform.Output(t, netTerraformOptions, "subnet_id")

	// Create AKS cluster
	aksTerraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../infra/terraform/modules/azure/kubernetes-cluster",
		Vars: map[string]interface{}{
			"cluster_name":        clusterName,
			"location":            location,
			"resource_group_name": resourceGroupName,
			"subnet_id":           subnetID,
			"node_vm_size":        "Standard_B2ms",
			"node_count":          3,
			"tags": map[string]string{
				"Environment": "test",
				"ManagedBy":   "Terratest",
				"Purpose":     "automated-testing",
			},
		},
		NoColor: true,
	})

	defer terraform.Destroy(t, aksTerraformOptions)
	terraform.InitAndApply(t, aksTerraformOptions)

	// Validate outputs
	outputClusterName := terraform.Output(t, aksTerraformOptions, "cluster_name")
	outputClusterID := terraform.Output(t, aksTerraformOptions, "cluster_id")
	outputClusterFQDN := terraform.Output(t, aksTerraformOptions, "cluster_fqdn")

	// Assert that outputs match expected values
	assert.Equal(t, clusterName, outputClusterName, "Cluster name should match input")
	assert.NotEmpty(t, outputClusterID, "Cluster ID should not be empty")
	assert.NotEmpty(t, outputClusterFQDN, "Cluster FQDN should not be empty")
}
