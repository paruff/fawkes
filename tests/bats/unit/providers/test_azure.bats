#!/usr/bin/env bats
# =============================================================================
# BATS tests for scripts/lib/providers/azure.sh
# Tests Azure AKS cluster provisioning functions
# =============================================================================

setup() {
  # Load test helpers
  load ../../helpers/test_helper
  load ../../helpers/mocks
  
  # Setup test environment
  setup_test_env
  
  # Source required libraries
  source "${LIB_DIR}/common.sh"
  source "${LIB_DIR}/providers/azure.sh"
  
  # Setup mocks
  setup_az_mock
  setup_kubectl_mock
}

teardown() {
  teardown_test_env
}

# =============================================================================
# Tests for install_kubelogin function
# =============================================================================

@test "install_kubelogin: skips installation when kubelogin already exists" {
  # Create fake kubelogin in PATH
  cat > "${TEST_TEMP_DIR}/bin/kubelogin" <<'EOF'
#!/usr/bin/env bash
echo "kubelogin version 0.1.4"
EOF
  chmod +x "${TEST_TEMP_DIR}/bin/kubelogin"
  
  run install_kubelogin
  assert_success
  assert_output --partial "kubelogin already installed"
}

@test "install_kubelogin: attempts to install when kubelogin not found" {
  # Remove kubelogin from PATH
  export PATH="${TEST_TEMP_DIR}/empty:${PATH}"
  mkdir -p "${TEST_TEMP_DIR}/empty"
  
  # Mock curl and brew
  cat > "${TEST_TEMP_DIR}/bin/curl" <<'EOF'
#!/usr/bin/env bash
exit 1
EOF
  chmod +x "${TEST_TEMP_DIR}/bin/curl"
  
  run install_kubelogin
  # Should attempt installation (may fail in test environment)
  assert_output --partial "Installing kubelogin"
}

# =============================================================================
# Tests for refresh_aks_credentials function
# =============================================================================

@test "refresh_aks_credentials: checks cluster status before refreshing" {
  # Mock az to return successful cluster state
  cat > "${TEST_TEMP_DIR}/bin/az" <<'EOF'
#!/usr/bin/env bash
echo "az $*" >> "${TEST_TEMP_DIR}/az.log"
case "$2" in
  "show")
    echo '{"state":"Succeeded","azureRbac":false}'
    exit 0
    ;;
  "get-credentials")
    echo "Merged \"test-cluster\" as current context"
    exit 0
    ;;
esac
EOF
  chmod +x "${TEST_TEMP_DIR}/bin/az"
  
  # Mock kubelogin
  cat > "${TEST_TEMP_DIR}/bin/kubelogin" <<'EOF'
#!/usr/bin/env bash
echo "kubelogin version 0.1.4"
EOF
  chmod +x "${TEST_TEMP_DIR}/bin/kubelogin"
  
  run refresh_aks_credentials "test-rg" "test-cluster"
  assert_success
  assert_output --partial "Refreshing AKS credentials"
}

@test "refresh_aks_credentials: fails when cluster is not in Succeeded state" {
  # Mock az to return non-succeeded state
  cat > "${TEST_TEMP_DIR}/bin/az" <<'EOF'
#!/usr/bin/env bash
case "$2" in
  "show")
    echo '{"state":"Updating","azureRbac":false}'
    exit 0
    ;;
esac
EOF
  chmod +x "${TEST_TEMP_DIR}/bin/az"
  
  run refresh_aks_credentials "test-rg" "test-cluster"
  assert_failure
  assert_output --partial "not in 'Succeeded' state"
}

@test "refresh_aks_credentials: calls az aks get-credentials" {
  # Mock az to log calls
  cat > "${TEST_TEMP_DIR}/bin/az" <<'EOF'
#!/usr/bin/env bash
echo "az $*" >> "${TEST_TEMP_DIR}/az.log"
case "$2" in
  "show")
    echo '{"state":"Succeeded","azureRbac":false}'
    exit 0
    ;;
  "get-credentials")
    echo "Merged \"test-cluster\" as current context"
    exit 0
    ;;
esac
EOF
  chmod +x "${TEST_TEMP_DIR}/bin/az"
  
  # Mock kubelogin
  cat > "${TEST_TEMP_DIR}/bin/kubelogin" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
  chmod +x "${TEST_TEMP_DIR}/bin/kubelogin"
  
  run refresh_aks_credentials "test-rg" "test-cluster"
  assert_success
  
  # Verify az get-credentials was called
  assert_file_contains "${TEST_TEMP_DIR}/az.log" "get-credentials"
}

@test "refresh_aks_credentials: uses correct resource group and cluster name" {
  cat > "${TEST_TEMP_DIR}/bin/az" <<'EOF'
#!/usr/bin/env bash
echo "az $*" >> "${TEST_TEMP_DIR}/az.log"
case "$2" in
  "show")
    echo '{"state":"Succeeded","azureRbac":false}'
    exit 0
    ;;
  "get-credentials")
    exit 0
    ;;
esac
EOF
  chmod +x "${TEST_TEMP_DIR}/bin/az"
  
  # Mock kubelogin
  cat > "${TEST_TEMP_DIR}/bin/kubelogin" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
  chmod +x "${TEST_TEMP_DIR}/bin/kubelogin"
  
  run refresh_aks_credentials "my-resource-group" "my-cluster"
  assert_success
  
  # Verify correct parameters were passed
  assert_file_contains "${TEST_TEMP_DIR}/az.log" "my-resource-group"
  assert_file_contains "${TEST_TEMP_DIR}/az.log" "my-cluster"
}
