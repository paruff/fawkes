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
	"time"

	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// TestAzureInfrastructureE2E performs end-to-end testing of the complete Azure infrastructure
func TestAzureInfrastructureE2E(t *testing.T) {
	t.Parallel()

	// Skip if not running E2E tests (these are expensive and time-consuming)
	if os.Getenv("RUN_TERRAFORM_E2E_TESTS") != "true" {
		t.Skip("Skipping E2E test. Set RUN_TERRAFORM_E2E_TESTS=true to run.")
	}

	// Generate unique names
	uniqueID := random.UniqueId()
	resourceGroupName := fmt.Sprintf("fawkes-e2e-rg-%s", uniqueID)
	vnetName := fmt.Sprintf("fawkes-e2e-vnet-%s", uniqueID)
	subnetName := fmt.Sprintf("fawkes-e2e-subnet-%s", uniqueID)
	clusterName := fmt.Sprintf("fawkes-e2e-aks-%s", uniqueID)
	location := "eastus2"

	// Stage 1: Deploy Resource Group
	t.Log("Stage 1: Deploying Resource Group")
	rgOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../infra/terraform/modules/azure-resource-group",
		Vars: map[string]interface{}{
			"name":     resourceGroupName,
			"location": location,
			"tags": map[string]string{
				"Environment": "e2e-test",
				"ManagedBy":   "Terratest",
				"TestID":      uniqueID,
			},
		},
		NoColor: true,
	})

	defer terraform.Destroy(t, rgOptions)
	terraform.InitAndApply(t, rgOptions)

	rgName := terraform.Output(t, rgOptions, "name")
	require.Equal(t, resourceGroupName, rgName, "Resource group should be created")

	// Stage 2: Deploy Network Infrastructure
	t.Log("Stage 2: Deploying Network Infrastructure")
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
				"Environment": "e2e-test",
				"ManagedBy":   "Terratest",
				"TestID":      uniqueID,
			},
		},
		NoColor: true,
	})

	defer terraform.Destroy(t, networkOptions)
	terraform.InitAndApply(t, networkOptions)

	subnetID := terraform.Output(t, networkOptions, "subnet_id")
	require.NotEmpty(t, subnetID, "Subnet should be created")

	// Stage 3: Deploy AKS Cluster
	t.Log("Stage 3: Deploying AKS Cluster (this may take 10-15 minutes)")
	aksOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../infra/terraform/modules/azure-aks-cluster",
		Vars: map[string]interface{}{
			"cluster_name":        clusterName,
			"location":            location,
			"resource_group_name": resourceGroupName,
			"subnet_id":           subnetID,
			"node_vm_size":        "Standard_B2ms",
			"node_count":          1,
			"dns_service_ip":      "10.0.2.10",
			"service_cidr":        "10.0.2.0/24",
			"tags": map[string]string{
				"Environment": "e2e-test",
				"ManagedBy":   "Terratest",
				"TestID":      uniqueID,
			},
		},
		NoColor: true,
		// Increase timeouts for AKS provisioning
		MaxRetries:         3,
		TimeBetweenRetries: 10 * time.Second,
	})

	defer terraform.Destroy(t, aksOptions)
	terraform.InitAndApply(t, aksOptions)

	// Validate AKS cluster outputs
	clusterID := terraform.Output(t, aksOptions, "cluster_id")
	kubeConfig := terraform.Output(t, aksOptions, "kube_config_raw")

	assert.NotEmpty(t, clusterID, "AKS cluster should be created")
	assert.NotEmpty(t, kubeConfig, "Kubeconfig should be available")

	// Stage 4: Verify cluster is accessible
	t.Log("Stage 4: Verifying cluster accessibility")
	// In a real scenario, you would parse the kubeconfig and verify cluster access
	// For now, we just check that the output is not empty
	assert.Contains(t, kubeConfig, "apiVersion", "Kubeconfig should be valid")
	assert.Contains(t, kubeConfig, clusterName, "Kubeconfig should reference cluster name")

	t.Log("E2E test completed successfully!")
}

// TestAzureInfrastructureWithArgoCD tests the complete stack including ArgoCD
func TestAzureInfrastructureWithArgoCD(t *testing.T) {
	t.Parallel()

	// Skip if not running E2E tests
	if os.Getenv("RUN_TERRAFORM_E2E_TESTS") != "true" {
		t.Skip("Skipping E2E test. Set RUN_TERRAFORM_E2E_TESTS=true to run.")
	}

	// This test would follow the same pattern as above but also deploy ArgoCD
	// Skipping actual implementation to keep the test suite focused
	t.Log("This test would deploy complete infrastructure including ArgoCD")
	t.Skip("Extended E2E test - implement when needed for full validation")
}
