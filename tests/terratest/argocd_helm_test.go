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
	"os"
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

// TestArgoCDHelmModule validates the argocd-helm module
func TestArgoCDHelmModule(t *testing.T) {
	t.Parallel()

	// Skip if not running integration tests or if no kubeconfig is available
	if os.Getenv("RUN_TERRAFORM_INTEGRATION_TESTS") != "true" {
		t.Skip("Skipping integration test. Set RUN_TERRAFORM_INTEGRATION_TESTS=true to run.")
	}

	kubeconfigPath := os.Getenv("KUBECONFIG")
	if kubeconfigPath == "" {
		kubeconfigPath = os.Getenv("HOME") + "/.kube/config"
	}

	// Check if kubeconfig exists
	if _, err := os.Stat(kubeconfigPath); os.IsNotExist(err) {
		t.Skip("Skipping test: no kubeconfig found")
	}

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../infra/terraform/modules/argocd-helm",
		Vars: map[string]interface{}{
			"release_name":      "argocd-test",
			"namespace":         "argocd-test",
			"create_namespace":  true,
			"kubeconfig_path":   kubeconfigPath,
			"chart_version":     "5.51.6",
			"server_replicas":   1,
			"repo_server_replicas": 1,
			"controller_replicas":  1,
		},
		NoColor: true,
	})

	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)

	// Validate outputs
	outputReleaseName := terraform.Output(t, terraformOptions, "release_name")
	outputNamespace := terraform.Output(t, terraformOptions, "namespace")

	// Assertions
	assert.Equal(t, "argocd-test", outputReleaseName, "Release name should match input")
	assert.Equal(t, "argocd-test", outputNamespace, "Namespace should match input")
}

// TestArgoCDHelmValidation validates Terraform syntax
func TestArgoCDHelmValidation(t *testing.T) {
	t.Parallel()

	terraformOptions := &terraform.Options{
		TerraformDir: "../../infra/terraform/modules/argocd-helm",
		NoColor:      true,
	}

	// Validate that the Terraform configuration is syntactically valid
	terraform.Init(t, terraformOptions)
	terraform.Validate(t, terraformOptions)

	t.Log("✅ ArgoCD Helm module validation passed")
}
