#!/usr/bin/env bash
# =============================================================================
# File: tests/unit/test_ignite_modules.sh
# Purpose: Unit tests for ignite.sh library modules
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
LIB_DIR="${ROOT_DIR}/scripts/lib"

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test result tracking
test_assert() {
  local description="$1"
  local condition="$2"
  
  TESTS_RUN=$((TESTS_RUN + 1))
  
  if eval "$condition"; then
    echo "✅ PASS: $description"
    TESTS_PASSED=$((TESTS_PASSED + 1))
    return 0
  else
    echo "❌ FAIL: $description"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    return 1
  fi
}

test_function_exists() {
  local function_name="$1"
  local module="$2"
  test_assert "Function $function_name exists in $module" "declare -f $function_name >/dev/null"
}

echo "=========================================="
echo "Testing ignite.sh Library Modules"
echo "=========================================="
echo ""

# Test common.sh
echo "Testing common.sh..."
source "${LIB_DIR}/common.sh"
test_function_exists "error_exit" "common.sh"
test_function_exists "context_id" "common.sh"
test_function_exists "state_setup" "common.sh"
test_function_exists "state_is_done" "common.sh"
test_function_exists "state_mark_done" "common.sh"
test_function_exists "run_step" "common.sh"
test_function_exists "cleanup_resources" "common.sh"
echo ""

# Test flags.sh
echo "Testing flags.sh..."
source "${LIB_DIR}/flags.sh"
test_function_exists "usage" "flags.sh"
test_function_exists "parse_flags" "flags.sh"
echo ""

# Test prereqs.sh
echo "Testing prereqs.sh..."
source "${LIB_DIR}/prereqs.sh"
test_function_exists "check_prereqs" "prereqs.sh"
echo ""

# Test terraform.sh
echo "Testing terraform.sh..."
source "${LIB_DIR}/terraform.sh"
test_function_exists "tf_apply_dir" "terraform.sh"
test_function_exists "tf_destroy_dir" "terraform.sh"
test_function_exists "try_set_kubeconfig_from_tf_outputs" "terraform.sh"
echo ""

# Test validation.sh
echo "Testing validation.sh..."
source "${LIB_DIR}/validation.sh"
test_function_exists "validate_cluster" "validation.sh"
test_function_exists "wait_for_workload" "validation.sh"
echo ""

# Test cluster.sh
echo "Testing cluster.sh..."
source "${LIB_DIR}/cluster.sh"
test_function_exists "provision_cluster" "cluster.sh"
echo ""

# Test argocd.sh
echo "Testing argocd.sh..."
source "${LIB_DIR}/argocd.sh"
test_function_exists "maybe_cleanup_argocd_cluster_resources" "argocd.sh"
test_function_exists "deploy_argocd" "argocd.sh"
test_function_exists "ensure_argocd_workloads" "argocd.sh"
test_function_exists "wait_for_argocd_endpoints" "argocd.sh"
test_function_exists "seed_applications" "argocd.sh"
echo ""

# Test summary.sh
echo "Testing summary.sh..."
source "${LIB_DIR}/summary.sh"
test_function_exists "get_service_password" "summary.sh"
test_function_exists "print_access_summary" "summary.sh"
test_function_exists "post_deploy_summary" "summary.sh"
echo ""

# Test provider modules
echo "Testing providers/local.sh..."
source "${LIB_DIR}/providers/local.sh"
test_function_exists "compute_minikube_resources" "providers/local.sh"
test_function_exists "compute_minikube_disk_size" "providers/local.sh"
test_function_exists "detect_minikube_arch" "providers/local.sh"
test_function_exists "choose_minikube_driver" "providers/local.sh"
test_function_exists "provision_local_cluster" "providers/local.sh"
echo ""

echo "Testing providers/aws.sh..."
source "${LIB_DIR}/providers/aws.sh"
test_function_exists "provision_aws_cluster" "providers/aws.sh"
test_function_exists "destroy_aws_cluster" "providers/aws.sh"
echo ""

echo "Testing providers/azure.sh..."
source "${LIB_DIR}/providers/azure.sh"
test_function_exists "install_kubelogin" "providers/azure.sh"
test_function_exists "provision_azure_cluster" "providers/azure.sh"
test_function_exists "destroy_azure_cluster" "providers/azure.sh"
echo ""

echo "Testing providers/gcp.sh..."
source "${LIB_DIR}/providers/gcp.sh"
test_function_exists "provision_gcp_cluster" "providers/gcp.sh"
test_function_exists "destroy_gcp_cluster" "providers/gcp.sh"
echo ""

# Test flag parsing
echo "Testing flag parsing..."
PROVIDER=""
ENV=""
ONLY_CLUSTER=0
DRY_RUN=0
parse_flags --provider local --dry-run local
test_assert "Provider parsed correctly" '[[ "$PROVIDER" == "local" ]]'
test_assert "Environment parsed correctly" '[[ "$ENV" == "local" ]]'
test_assert "Dry-run flag parsed correctly" '[[ $DRY_RUN -eq 1 ]]'
echo ""

# Test architecture detection
echo "Testing architecture detection..."
ARCH=$(detect_minikube_arch)
test_assert "Architecture detected" '[[ -n "$ARCH" && ("$ARCH" == "arm64" || "$ARCH" == "amd64") ]]'
echo ""

# Summary
echo "=========================================="
echo "Test Summary"
echo "=========================================="
echo "Tests run:    $TESTS_RUN"
echo "Tests passed: $TESTS_PASSED"
echo "Tests failed: $TESTS_FAILED"
echo ""

if [[ $TESTS_FAILED -eq 0 ]]; then
  echo "✅ All tests passed!"
  exit 0
else
  echo "❌ Some tests failed!"
  exit 1
fi
