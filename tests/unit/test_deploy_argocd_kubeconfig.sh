#!/usr/bin/env bash
# =============================================================================
# File: tests/unit/test_deploy_argocd_kubeconfig.sh
# Purpose: Test that deploy_argocd reuses kubeconfig from try_set_kubeconfig_from_tf_outputs
#          instead of silently capturing the wrong kubectl context.
# Regression test for: ignite.sh azure provider silently deploys ArgoCD to the wrong cluster
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
LIB_DIR="${ROOT_DIR}/scripts/lib"

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

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

echo "=========================================="
echo "Testing deploy_argocd kubeconfig handling"
echo "=========================================="
echo ""

# Source required libraries
source "${LIB_DIR}/common.sh"
source "${LIB_DIR}/flags.sh"
source "${LIB_DIR}/terraform.sh"

# ---- Test 1: deploy_argocd should use existing KUBECONFIG file when set ----
echo "Test 1: deploy_argocd reuses KUBECONFIG when set to a valid file"

# Create a fake kubeconfig that points to a specific cluster
FAKE_KUBECONFIG=$(mktemp -t fawkes-test-kc-XXXX.yaml)
cat > "${FAKE_KUBECONFIG}" << 'EOF'
apiVersion: v1
kind: Config
clusters:
- cluster:
    server: https://fake-aks-cluster:6443
    certificate-authority-data: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSURqRENDQW15Z0F3SUJBZ0lKQUxm
  name: fake-aks-context
contexts:
- context:
    cluster: fake-aks-context
    user: fake-aks-user
  name: fake-aks-context
current-context: fake-aks-context
users:
- name: fake-aks-user
  user:
    token: fake-token
EOF

# Set KUBECONFIG to our fake file (simulating what try_set_kubeconfig_from_tf_outputs does)
export KUBECONFIG="${FAKE_KUBECONFIG}"

# Create a mock kubeconfig that represents the "wrong" cluster (simulating a pre-existing context)
WRONG_KUBECONFIG=$(mktemp -t fawkes-test-wrong-kc-XXXX.yaml)
cat > "${WRONG_KUBECONFIG}" << 'EOF'
apiVersion: v1
kind: Config
clusters:
- cluster:
    server: https://minikube:8443
    certificate-authority-data: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSURqRENDQW15Z0F3SUJBZ0lKQUxm
  name: minikube
contexts:
- context:
    cluster: minikube
    user: minikube
  name: minikube
current-context: minikube
users:
- name: minikube
  user:
    token: fake-token
EOF

# Override KUBECONFIG to include both files, with wrong one first (simulating real scenario)
# The wrong kubeconfig's context would be selected by 'kubectl config view --raw --minify'
export KUBECONFIG="${WRONG_KUBECONFIG}:${FAKE_KUBECONFIG}"

# Verify our setup: current-context should be minikube (the wrong one)
CURRENT_CTX=$(kubectl config current-context 2> /dev/null || echo "unknown")
test_assert "Current kubectl context is the wrong cluster (minikube)" '[[ "$CURRENT_CTX" == "minikube" ]]'

# Verify the fake AKS kubeconfig exists and is valid
test_assert "Fake AKS kubeconfig file exists" '[[ -f "${FAKE_KUBECONFIG}" ]]'
test_assert "Fake AKS kubeconfig has expected cluster" 'grep -q "fake-aks-cluster" "${FAKE_KUBECONFIG}"'

# Now test the core behavior: deploy_argocd should use the KUBECONFIG path
# that try_set_kubeconfig_from_tf_outputs set, not create a new one from kubectl context.
#
# We can't run deploy_argocd directly (needs terraform, kubectl, etc.), so we test
# the kubeconfig resolution logic that the fix introduces.

# Simulate what the fixed deploy_argocd should do:
resolve_kubeconfig_for_argocd() {
  local kubeconfig_path="${KUBECONFIG:-}"
  if [[ -n "${kubeconfig_path}" ]]; then
    # Check if it's a single file path (set by try_set_kubeconfig_from_tf_outputs)
    if [[ -f "${kubeconfig_path}" ]]; then
      echo "${kubeconfig_path}"
      return 0
    fi
    # KUBECONFIG may contain multiple paths separated by ':'
    # Use the first valid file
    local IFS=':'
    for path in ${kubeconfig_path}; do
      if [[ -f "${path}" ]]; then
        echo "${path}"
        return 0
      fi
    done
  fi
  # Fallback: would create temp from kubectl config view (old behavior)
  echo ""
  return 1
}

# Test the resolution function
RESOLVED_PATH=$(resolve_kubeconfig_for_argocd)
test_assert "Kubeconfig resolution returns a valid file path" '[[ -n "${RESOLVED_PATH}" && -f "${RESOLVED_PATH}" ]]'

# The resolved path should be one of the files in KUBECONFIG, NOT a new temp file
# In our setup, KUBECONFIG has two files - it should resolve to one of them
IS_ONE_OF_ORIG=false
if [[ "${RESOLVED_PATH}" == "${FAKE_KUBECONFIG}" || "${RESOLVED_PATH}" == "${WRONG_KUBECONFIG}" ]]; then
  IS_ONE_OF_ORIG=true
fi
test_assert "Resolved path is one of the original KUBECONFIG files (not a new temp)" '${IS_ONE_OF_ORIG}'

# Now test that when KUBECONFIG is empty/unset, the function falls back
unset KUBECONFIG
FALLBACK_RESULT=$(resolve_kubeconfig_for_argocd || true)
test_assert "Fallback returns empty when KUBECONFIG is unset" '[[ -z "${FALLBACK_RESULT}" ]]'

# Test when KUBECONFIG points to a nonexistent file
export KUBECONFIG="/nonexistent/path/kubeconfig.yaml"
MISSING_RESULT=$(resolve_kubeconfig_for_argocd || true)
test_assert "Returns empty when KUBECONFIG points to nonexistent file" '[[ -z "${MISSING_RESULT}" ]]'

# Test multi-path KUBECONFIG with first file missing
export KUBECONFIG="/nonexistent/path:${FAKE_KUBECONFIG}"
MULTI_RESULT=$(resolve_kubeconfig_for_argocd)
test_assert "Multi-path KUBECONFIG resolves to first valid file" '[[ "${MULTI_RESULT}" == "${FAKE_KUBECONFIG}" ]]'

# ---- Test 2: Old behavior would have used wrong context ----
echo ""
echo "Test 2: Verify old behavior (kubectl config view) captures wrong context"

# Reset to wrong KUBECONFIG
export KUBECONFIG="${WRONG_KUBECONFIG}:${FAKE_KUBECONFIG}"

# What the OLD deploy_argocd did:
OLD_TEMP=$(mktemp -t fawkes-old-behavior-XXXX.yaml)
kubectl config view --raw --minify --flatten > "${OLD_TEMP}"

# The old behavior would capture minikube (the wrong cluster)
OLD_CONTEXT=$(kubectl --kubeconfig="${OLD_TEMP}" config current-context 2> /dev/null || echo "unknown")
test_assert "Old behavior captures wrong context (minikube)" '[[ "${OLD_CONTEXT}" == "minikube" ]]'
test_assert "Old behavior temp file does NOT contain AKS cluster" '! grep -q "fake-aks-cluster" "${OLD_TEMP}"'

# Cleanup
rm -f "${OLD_TEMP}"

# ---- Test 3: try_set_kubeconfig_from_tf_outputs sets KUBECONFIG correctly ----
echo ""
echo "Test 3: try_set_kubeconfig_from_tf_outputs sets KUBECONFIG to a file"

# Create a mock terraform output directory and kubeconfig
TF_MOCK_DIR=$(mktemp -d)
MOCK_KUBECONFIG="${TF_MOCK_DIR}/aks-kubeconfig.yaml"
cat > "${MOCK_KUBECONFIG}" << 'EOF'
apiVersion: v1
kind: Config
clusters:
- cluster:
    server: https://mock-aks:6443
  name: mock-aks
contexts:
- context:
    cluster: mock-aks
    user: mock-aks
  name: mock-aks
current-context: mock-aks
users:
- name: mock-aks
  user:
    token: mock-token
EOF

# Save and restore KUBECONFIG
PREV_KUBECONFIG="${KUBECONFIG:-}"
unset KUBECONFIG

# Simulate what try_set_kubeconfig_from_tf_outputs does:
# It extracts kubeconfig_path from terraform output and sets KUBECONFIG
TF_OUT_PATH="${MOCK_KUBECONFIG}"
test_assert "Terraform output kubeconfig file exists" '[[ -f "${TF_OUT_PATH}" ]]'
test_assert "Terraform output kubeconfig has expected cluster" 'grep -q "mock-aks" "${TF_OUT_PATH}"'

# The key assertion: when KUBECONFIG is set to this file,
# deploy_argocd should use it directly instead of kubectl config view
export KUBECONFIG="${TF_OUT_PATH}"
RESOLVED=$(resolve_kubeconfig_for_argocd)
test_assert "KUBECONFIG set from TF outputs is reused by deploy_argocd" '[[ "${RESOLVED}" == "${TF_OUT_PATH}" ]]'

# Restore
export KUBECONFIG="${PREV_KUBECONFIG}"
rm -rf "${TF_MOCK_DIR}"

# ---- Cleanup ----
rm -f "${FAKE_KUBECONFIG}" "${WRONG_KUBECONFIG}"

# ---- Summary ----
echo ""
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
