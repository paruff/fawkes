# Ignite.sh Library Modules

This directory contains the refactored, modular components of the `ignite.sh` bootstrap script.

## Architecture Overview

The `ignite.sh` script has been refactored from a monolithic 1661-line script into a modular architecture with clear separation of concerns. The main script (`scripts/ignite.sh`) is now only 162 lines and orchestrates the various modules.

## Directory Structure

```
scripts/lib/
├── common.sh           # Error handling, logging, state management
├── flags.sh            # Command-line flag parsing
├── prereqs.sh          # Prerequisite checking
├── terraform.sh        # Terraform operations
├── validation.sh       # Cluster and workload validation
├── cluster.sh          # Cluster provisioning orchestration
├── argocd.sh          # ArgoCD deployment and management
├── summary.sh         # Access summary generation
└── providers/
    ├── local.sh       # Local cluster (minikube, docker-desktop)
    ├── aws.sh         # AWS EKS provisioning
    ├── azure.sh       # Azure AKS provisioning (with RBAC & kubelogin)
    └── gcp.sh         # GCP GKE provisioning
```

## Module Descriptions

### common.sh
Core utilities used across all modules:
- `error_exit()` - Error handling with exit
- `context_id()` - Generate unique context identifier
- `state_setup()` - Initialize state tracking file
- `state_is_done()` - Check if step is completed
- `state_mark_done()` - Mark step as completed
- `run_step()` - Execute step with resume support
- `cleanup_resources()` - Clean up ArgoCD and Fawkes resources

### flags.sh
Command-line argument parsing:
- `usage()` - Display help message
- `parse_flags()` - Parse command-line flags and arguments

Supported flags:
- `--provider|-p` - Cloud provider (local|aws|azure|gcp)
- `--cluster-name|-n` - Cluster name
- `--region|-r` - AWS/GCP region
- `--location` - Azure location
- `--only-cluster` - Provision cluster only
- `--only-apps` - Deploy apps only
- `--skip-cluster` - Skip cluster provisioning
- `--dry-run` - Plan mode without execution
- `--resume` - Resume from previous state
- `--verbose|-v` - Enable verbose logging
- `--access` - Show access summary only

### prereqs.sh
Prerequisite validation:
- `check_prereqs()` - Validate required tools (kubectl, jq, terraform, etc.)
- Integrates with `tools.sh` for automated installation
- Supports both macOS (Homebrew) and Linux installation

### terraform.sh
Terraform lifecycle management:
- `tf_apply_dir()` - Apply Terraform in specified directory
- `tf_destroy_dir()` - Destroy Terraform resources
- `try_set_kubeconfig_from_tf_outputs()` - Extract kubeconfig from outputs
- Handles Azure subscription/tenant setup
- Manages AKS node pool imports

### validation.sh
Cluster health validation:
- `validate_cluster()` - Validate Kubernetes API, nodes, storage
- `wait_for_workload()` - Wait for deployment/statefulset readiness
- Provides detailed error messages and troubleshooting tips

### cluster.sh
High-level cluster provisioning orchestration:
- `provision_cluster()` - Route to provider-specific provisioning
- Handles context selection and validation
- Supports interactive mode for existing contexts

### argocd.sh
ArgoCD deployment and configuration:
- `maybe_cleanup_argocd_cluster_resources()` - Clean pre-existing resources
- `deploy_argocd()` - Deploy via Terraform with Helm
- `ensure_argocd_workloads()` - Wait for all ArgoCD components
- `wait_for_argocd_endpoints()` - Ensure service endpoints ready
- `seed_applications()` - Apply bootstrap Applications
- Handles password management for local environments

### summary.sh
Access information display:
- `get_service_password()` - Retrieve service credentials
- `print_access_summary()` - Display comprehensive access guide
- `post_deploy_summary()` - Post-deployment summary
- Shows URLs, credentials, and quick commands for all services

### Provider Modules

#### providers/local.sh
Local Kubernetes cluster provisioning:
- `compute_minikube_resources()` - Calculate memory/CPU based on system
- `compute_minikube_disk_size()` - Determine disk allocation
- `detect_minikube_arch()` - Detect CPU architecture (arm64/amd64)
- `choose_minikube_driver()` - Select best driver (docker, vfkit, qemu)
- `use_first_reachable_local_context()` - Find existing local cluster
- `driver_extra_args()` - Generate driver-specific arguments
- `provision_local_cluster()` - Provision minikube cluster

#### providers/aws.sh
AWS EKS cluster provisioning:
- `provision_aws_cluster()` - Apply Terraform for EKS
- `destroy_aws_cluster()` - Destroy EKS cluster

#### providers/azure.sh
Azure AKS cluster provisioning with RBAC:
- `install_kubelogin()` - Install kubelogin for AKS auth
- `install_kubelogin_binary()` - Direct binary download
- `refresh_aks_credentials()` - Update and validate credentials
- `provision_azure_cluster()` - Apply Terraform for AKS
- `destroy_azure_cluster()` - Destroy AKS cluster
- Handles Azure RBAC role assignment and propagation
- Supports kubelogin authentication with azurecli

#### providers/gcp.sh
GCP GKE cluster provisioning:
- `provision_gcp_cluster()` - Apply Terraform for GKE
- `destroy_gcp_cluster()` - Destroy GKE cluster

## Usage Examples

### Source individual modules
```bash
source scripts/lib/common.sh
source scripts/lib/flags.sh
```

### Run complete bootstrap
```bash
# Local cluster
./scripts/ignite.sh local

# AWS cluster
./scripts/ignite.sh --provider aws --region us-west-2 dev

# Azure cluster with custom name
./scripts/ignite.sh --provider azure --location eastus --cluster-name my-cluster dev

# Dry-run mode
./scripts/ignite.sh --provider azure --dry-run dev

# Resume from failure
./scripts/ignite.sh --resume dev
```

## Testing

Unit tests are located in `tests/unit/test_ignite_modules.sh`:

```bash
# Run all unit tests
./tests/unit/test_ignite_modules.sh
```

Tests verify:
- All functions are properly exported
- Flag parsing works correctly
- Architecture detection functions
- Module loading and sourcing

## Design Principles

1. **Single Responsibility** - Each module has a clear, focused purpose
2. **No Duplication** - Common functionality extracted to shared modules
3. **Independent Testing** - Modules can be tested in isolation
4. **Error Handling** - Consistent error handling via `error_exit()`
5. **Backward Compatibility** - All original flags and behaviors preserved
6. **State Management** - Resume capability via JSON state file
7. **Provider Abstraction** - Clean separation of cloud provider logic

## Benefits

- **Maintainability** - Changes isolated to specific modules
- **Testability** - Each module independently testable
- **Reusability** - Modules can be used by other scripts
- **Readability** - Clear organization and documentation
- **Extensibility** - New providers easily added
- **Debugging** - Easier to trace and fix issues

## Adding a New Provider

To add a new cloud provider (e.g., DigitalOcean):

1. Create `scripts/lib/providers/digitalocean.sh`
2. Implement required functions:
   ```bash
   provision_digitalocean_cluster() { ... }
   destroy_digitalocean_cluster() { ... }
   ```
3. Source in `scripts/ignite.sh`:
   ```bash
   source "${LIB_DIR}/providers/digitalocean.sh"
   ```
4. Add case in `cluster.sh` and destroy logic
5. Update `flags.sh` provider validation
6. Add tests in `tests/unit/test_ignite_modules.sh`

## State Management

The state file (`.ignite-state.json`) tracks completed steps to enable resume:

```json
{
  "runs": {
    "local:local:minikube::": {
      "steps": {
        "check_prereqs": {"status": "done", "ts": "2025-12-26T12:00:00Z"},
        "provision_cluster": {"status": "done", "ts": "2025-12-26T12:05:00Z"}
      }
    }
  }
}
```

## Error Handling

All modules use consistent error handling:
- `error_exit()` for fatal errors
- Descriptive error messages with context
- Cleanup on failure (where applicable)
- Exit codes: 0 = success, 1 = failure

## Logging

Logging conventions:
- 🔎 Validation/checking
- 🔧 Configuration/setup
- 🚀 Execution/deployment
- ✅ Success
- ⚠️  Warning
- ❌ Error
- ⏳ Waiting/in-progress
- 🧹 Cleanup

## Environment Variables

Key environment variables:
- `ARGOCD_NAMESPACE` - ArgoCD namespace (default: fawkes)
- `AUTO_INSTALL` - Auto-install missing tools
- `AUTO_CLEAN_ARGO` - Auto-cleanup existing ArgoCD
- `FAWKES_LOCAL_PASSWORD` - Local ArgoCD password
- `MINIKUBE_MEMORY` - Override minikube memory
- `MINIKUBE_CPUS` - Override minikube CPUs
- `MINIKUBE_DISK_SIZE` - Override minikube disk
- `MINIKUBE_DRIVER` - Force specific driver

## Contributing

When modifying modules:
1. Maintain function signatures for backward compatibility
2. Add tests for new functionality
3. Update this README with changes
4. Follow existing code style and conventions
5. Ensure no code duplication across modules
6. Keep main `ignite.sh` under 200 lines
