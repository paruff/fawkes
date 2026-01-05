# Module Template for New Cloud Providers

This directory contains templates for creating new provider-specific modules.

## Using the Template

When adding support for a new cloud provider (AWS, GCP, Civo, etc.), follow these steps:

### Step 1: Create Provider Directory

```bash
mkdir -p infra/terraform/modules/{provider-name}/kubernetes-cluster
mkdir -p infra/terraform/modules/{provider-name}/network
mkdir -p infra/terraform/modules/{provider-name}/resource-group
```

Replace `{provider-name}` with the actual provider (e.g., `aws`, `gcp`, `civo`).

### Step 2: Copy and Customize Templates

For each module type, create the following files:

#### main.tf

```hcl
# Copyright (c) 2025  Philip Ruff
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
# DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
# OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE
# OR OTHER DEALINGS IN THE SOFTWARE.

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    # Add provider-specific requirements
    provider_name = {
      source  = "hashicorp/{provider-name}"
      version = ">= X.Y.Z"
    }
  }
}

# Add provider-specific resources
resource "provider_resource_type" "main" {
  # Map base module variables to provider-specific resource attributes
  name     = var.cluster_name  # or var.network_name, var.name
  location = var.location
  # ... other provider-specific attributes
}
```

#### variables.tf

```hcl
# Copyright (c) 2025  Philip Ruff
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
# DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
# OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE
# OR OTHER DEALINGS IN THE SOFTWARE.

# Provider-specific variables extending base module

# Include base variables from base/{module-type}/variables.tf
# Add validation rules specific to the provider

# Example for kubernetes-cluster:
variable "cluster_name" {
  description = "Name of the Kubernetes cluster"
  type        = string

  validation {
    condition     = length(var.cluster_name) >= 1 && length(var.cluster_name) <= 63
    error_message = "Cluster name must be between 1 and 63 characters."
  }

  validation {
    condition     = can(regex("^[a-zA-Z0-9][a-zA-Z0-9-]*[a-zA-Z0-9]$", var.cluster_name))
    error_message = "Cluster name must start and end with alphanumeric, and contain only alphanumerics and hyphens."
  }
}

variable "location" {
  description = "Cloud provider region/location for the cluster"
  type        = string

  # Add provider-specific validation if applicable
  validation {
    condition = contains([
      # List valid regions for the provider
      "region-1", "region-2", "region-3"
    ], var.location)
    error_message = "Location must be a valid {provider-name} region."
  }
}

# Add other base variables
variable "resource_group_name" {
  description = "Name of the resource group or organizational unit"
  type        = string
}

variable "node_count" {
  description = "Number of nodes in the default node pool"
  type        = number
  default     = 3

  validation {
    condition     = var.node_count >= 1 && var.node_count <= 1000
    error_message = "Node count must be between 1 and 1000."
  }
}

# Add provider-specific variables
variable "provider_specific_variable" {
  description = "Description of provider-specific variable"
  type        = string
  default     = "default-value"

  validation {
    condition     = # provider-specific validation logic
    error_message = "Error message for validation."
  }
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
```

#### outputs.tf

```hcl
# Copyright (c) 2025  Philip Ruff
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
# DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
# OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE
# OR OTHER DEALINGS IN THE SOFTWARE.

# Provider-specific outputs following base module patterns

# Example for kubernetes-cluster:
output "cluster_id" {
  description = "The ID of the Kubernetes cluster"
  value       = provider_resource_type.main.id
}

output "cluster_name" {
  description = "The name of the Kubernetes cluster"
  value       = provider_resource_type.main.name
}

output "cluster_endpoint" {
  description = "The endpoint/FQDN of the Kubernetes cluster"
  value       = provider_resource_type.main.endpoint
}

output "kube_config" {
  description = "Kubernetes configuration for the cluster"
  value       = provider_resource_type.main.kube_config
  sensitive   = true
}

# Add provider-specific outputs
output "provider_specific_output" {
  description = "Description of provider-specific output"
  value       = provider_resource_type.main.specific_attribute
}
```

#### README.md

```markdown
# {Provider-Name} {Module-Type} Module

Manages a {Provider-Name} {resource-description}, extending the base {module-type} module.

## Usage

\`\`\`hcl
module "{module-name}" {
  source              = "../../modules/{provider-name}/{module-type}"
  cluster_name        = "fawkes-cluster"  # or network_name, name
  location            = "region-1"
  resource_group_name = module.rg.name
  # ... other variables
}
\`\`\`

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.6.0 |
| {provider-name} | >= X.Y.Z |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| cluster_name | Name of the cluster | \`string\` | n/a | yes |
| location | Provider region | \`string\` | n/a | yes |
| ... | ... | ... | ... | ... |

## Outputs

| Name | Description |
|------|-------------|
| cluster_id | The ID of the cluster |
| cluster_name | The name of the cluster |
| ... | ... |

## Validation Rules

- List validation rules specific to this module
- Include any provider-specific constraints

## Examples

Provide usage examples specific to the provider.
```

### Step 3: Test the Module

```bash
cd infra/terraform/modules/{provider-name}/{module-type}
terraform init
terraform validate
terraform fmt -check
```

### Step 4: Add Tests

Create Terratest tests in `tests/terratest/`:

```go
// {provider_name}_{module_type}_test.go
package test

import (
    "testing"
    "github.com/gruntwork-io/terratest/modules/terraform"
    "github.com/stretchr/testify/assert"
)

func Test{ProviderName}{ModuleType}Module(t *testing.T) {
    t.Parallel()
    
    // Test implementation
}
```

### Step 5: Update Documentation

1. Add module to `modules/README.md`
2. Add examples to `examples/{provider-name}-complete/`
3. Update `REFACTORING.md` if needed

## Checklist for New Provider

When adding a new provider module, ensure:

- [ ] Created `{provider-name}/kubernetes-cluster` module
- [ ] Created `{provider-name}/network` module
- [ ] Created `{provider-name}/resource-group` module
- [ ] All variables use snake_case naming
- [ ] All variables have validation rules
- [ ] All variables have descriptions
- [ ] All outputs have descriptions
- [ ] Module has comprehensive README.md
- [ ] Module has terraform.tfvars.example
- [ ] Module passes `terraform validate`
- [ ] Module passes `terraform fmt -check`
- [ ] Added Terratest validation tests
- [ ] Added integration tests (optional)
- [ ] Updated main modules README.md
- [ ] Added usage examples
- [ ] Documented any provider-specific quirks

## Reference Implementations

See existing provider implementations for reference:

- **Azure**: `modules/azure/` - Complete implementation for Azure
- **Base**: `modules/base/` - Common patterns and variables

## Best Practices

1. **Extend, don't duplicate**: Use base module variables where possible
2. **Validate early**: Add validation rules to catch errors early
3. **Document thoroughly**: Include examples and descriptions
4. **Test comprehensively**: Add both validation and integration tests
5. **Follow conventions**: Use snake_case, consistent naming patterns
6. **Version properly**: Specify provider version constraints
7. **Tag consistently**: Support tags/labels for all resources

## Getting Help

For questions about creating new provider modules:
- Review the base module documentation in `modules/base/`
- Check the Azure implementation as a reference
- Consult the Terraform Best Practices guide
- Ask in the team chat or open an issue
