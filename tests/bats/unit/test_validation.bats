#!/usr/bin/env bats
# =============================================================================
# BATS tests for scripts/lib/validation.sh
# Tests cluster and workload validation functions
# =============================================================================

setup() {
  # Load test helpers
  load ../helpers/test_helper
  load ../helpers/mocks
  
  # Setup test environment
  setup_test_env
  
  # Source the common library first (required by validation.sh)
  source "${LIB_DIR}/common.sh"
  
  # Source the validation library
  source "${LIB_DIR}/validation.sh"
  
  # Setup kubectl mock
  setup_kubectl_mock
}

teardown() {
  teardown_test_env
}

# =============================================================================
# Tests for validate_cluster function
# =============================================================================

@test "validate_cluster: succeeds when cluster is healthy" {
  run validate_cluster
  assert_success
  assert_output --partial "Validating Kubernetes cluster health"
  assert_output --partial "Nodes Ready"
}

@test "validate_cluster: detects API unreachability" {
  # Create a mock kubectl that simulates unreachable API
  cat > "${TEST_TEMP_DIR}/bin/kubectl" <<'EOF'
#!/usr/bin/env bash
case "$1" in
  "cluster-info")
    exit 1
    ;;
esac
EOF
  chmod +x "${TEST_TEMP_DIR}/bin/kubectl"
  export PATH="${TEST_TEMP_DIR}/bin:${PATH}"
  
  run validate_cluster
  assert_failure
  assert_output --partial "Kubernetes API is not reachable"
}

@test "validate_cluster: checks node readiness" {
  run validate_cluster
  assert_success
  assert_output --partial "Nodes Ready"
}

@test "validate_cluster: fails when no ready nodes" {
  # Create a mock kubectl that returns no ready nodes
  cat > "${TEST_TEMP_DIR}/bin/kubectl" <<'EOF'
#!/usr/bin/env bash
case "$1" in
  "cluster-info")
    exit 0
    ;;
  "get")
    if [[ "$2" == "nodes" && "$*" == *"-o json"* ]]; then
      echo '{"items":[{"status":{"conditions":[{"type":"Ready","status":"False"}]}}]}'
    elif [[ "$2" == "storageclass" ]]; then
      echo '{"items":[]}'
    fi
    ;;
esac
EOF
  chmod +x "${TEST_TEMP_DIR}/bin/kubectl"
  
  run timeout 5 validate_cluster
  # Should fail or timeout waiting for ready nodes
  assert_failure
}

@test "validate_cluster: checks for StorageClass existence" {
  run validate_cluster
  assert_success
  assert_output --partial "Default StorageClass"
}

@test "validate_cluster: warns when no default StorageClass" {
  # Create mock kubectl with no default StorageClass
  cat > "${TEST_TEMP_DIR}/bin/kubectl" <<'EOF'
#!/usr/bin/env bash
case "$1" in
  "cluster-info")
    exit 0
    ;;
  "get")
    if [[ "$2" == "nodes" && "$*" == *"-o json"* ]]; then
      echo '{"items":[{"status":{"conditions":[{"type":"Ready","status":"True"}]}}]}'
    elif [[ "$2" == "storageclass" && "$*" == *"-o json"* ]]; then
      echo '{"items":[{"metadata":{"name":"local","annotations":{}}}]}'
    elif [[ "$2" == "storageclass" ]]; then
      echo "local"
    fi
    ;;
esac
EOF
  chmod +x "${TEST_TEMP_DIR}/bin/kubectl"
  
  run validate_cluster
  assert_success
  assert_output --partial "[WARN] No default StorageClass detected"
}

@test "validate_cluster: fails when no StorageClass found" {
  # Create mock kubectl with no StorageClass
  cat > "${TEST_TEMP_DIR}/bin/kubectl" <<'EOF'
#!/usr/bin/env bash
case "$1" in
  "cluster-info")
    exit 0
    ;;
  "get")
    if [[ "$2" == "nodes" && "$*" == *"-o json"* ]]; then
      echo '{"items":[{"status":{"conditions":[{"type":"Ready","status":"True"}]}}]}'
    elif [[ "$2" == "storageclass" ]]; then
      exit 1
    fi
    ;;
esac
EOF
  chmod +x "${TEST_TEMP_DIR}/bin/kubectl"
  
  run validate_cluster
  assert_failure
  assert_output --partial "No StorageClass resources found"
}

# =============================================================================
# Tests for wait_for_workload function
# =============================================================================

@test "wait_for_workload: waits for deployment to be available" {
  # Create mock kubectl that simulates successful deployment
  cat > "${TEST_TEMP_DIR}/bin/kubectl" <<'EOF'
#!/usr/bin/env bash
case "$1" in
  "get")
    if [[ "$2" == "deployment" ]]; then
      exit 0
    fi
    ;;
  "wait")
    echo "deployment.apps/test-app condition met"
    exit 0
    ;;
esac
EOF
  chmod +x "${TEST_TEMP_DIR}/bin/kubectl"
  
  run wait_for_workload "test-app" "default" "60"
  assert_success
  assert_output --partial "Waiting for workload test-app in namespace default"
}

@test "wait_for_workload: waits for statefulset when deployment not found" {
  # Create mock kubectl that finds statefulset
  cat > "${TEST_TEMP_DIR}/bin/kubectl" <<'EOF'
#!/usr/bin/env bash
case "$1" in
  "get")
    if [[ "$2" == "deployment" ]]; then
      exit 1
    elif [[ "$2" == "statefulset" ]]; then
      exit 0
    fi
    ;;
  "rollout")
    echo "statefulset rolling update complete"
    exit 0
    ;;
esac
EOF
  chmod +x "${TEST_TEMP_DIR}/bin/kubectl"
  
  run wait_for_workload "test-app" "default" "60"
  assert_success
}

@test "wait_for_workload: uses default namespace when not specified" {
  # Create mock kubectl
  cat > "${TEST_TEMP_DIR}/bin/kubectl" <<'EOF'
#!/usr/bin/env bash
echo "kubectl $@" >> "${TEST_TEMP_DIR}/kubectl.log"
case "$1" in
  "get")
    if [[ "$2" == "deployment" ]]; then
      exit 0
    fi
    ;;
  "wait")
    exit 0
    ;;
esac
EOF
  chmod +x "${TEST_TEMP_DIR}/bin/kubectl"
  export PATH="${TEST_TEMP_DIR}/bin:${PATH}"
  
  run wait_for_workload "test-app"
  assert_success
  
  # Verify default namespace was used
  run grep -- "default" "${TEST_TEMP_DIR}/kubectl.log"
  assert_success
}

@test "wait_for_workload: uses default timeout of 300s when not specified" {
  cat > "${TEST_TEMP_DIR}/bin/kubectl" <<'EOF'
#!/usr/bin/env bash
echo "kubectl $@" >> "${TEST_TEMP_DIR}/kubectl.log"
case "$1" in
  "get")
    if [[ "$2" == "deployment" ]]; then
      exit 0
    fi
    ;;
  "wait")
    exit 0
    ;;
esac
EOF
  chmod +x "${TEST_TEMP_DIR}/bin/kubectl"
  export PATH="${TEST_TEMP_DIR}/bin:${PATH}"
  
  run wait_for_workload "test-app" "default"
  assert_success
  
  # Verify default timeout was used
  run grep -- "300s" "${TEST_TEMP_DIR}/kubectl.log"
  assert_success
}

@test "wait_for_workload: fails when deployment wait times out" {
  # Create mock kubectl that simulates timeout
  cat > "${TEST_TEMP_DIR}/bin/kubectl" <<'EOF'
#!/usr/bin/env bash
case "$1" in
  "get")
    if [[ "$2" == "deployment" ]]; then
      exit 0
    fi
    ;;
  "wait")
    echo "error: timed out waiting for the condition"
    exit 1
    ;;
  "-n")
    # Handle namespace flag for describe/get commands
    exit 0
    ;;
esac
EOF
  chmod +x "${TEST_TEMP_DIR}/bin/kubectl"
  
  run wait_for_workload "test-app" "default" "5"
  assert_failure
}

@test "wait_for_workload: falls back to pod check when deployment and statefulset not found" {
  skip "Timeout behavior difficult to test reliably - covered by integration tests"
  
  # This test verifies the function prints the fallback message
  cat > "${TEST_TEMP_DIR}/bin/kubectl" <<'EOF'
#!/usr/bin/env bash
# Return failure for deployment and statefulset checks
if [[ "$1" == "get" && ("$2" == "deployment" || "$2" == "statefulset") ]]; then
  exit 1
fi
# Return empty pods list to trigger timeout
if [[ "$1" == "-n" || "$1" == "get" ]]; then
  exit 0
fi
exit 0
EOF
  chmod +x "${TEST_TEMP_DIR}/bin/kubectl"
  export PATH="${TEST_TEMP_DIR}/bin:${PATH}"
  
  # Run with short timeout and capture output
  run bash -c "wait_for_workload test-app default 2" || true
  
  # Verify fallback message is shown
  assert_output --partial "falling back to pods with prefix"
}

@test "wait_for_workload: returns failure when pod is not ready" {
  # Create mock kubectl where pod never becomes ready
  cat > "${TEST_TEMP_DIR}/bin/kubectl" <<'EOF'
#!/usr/bin/env bash
case "$1" in
  "get")
    if [[ "$2" == "deployment" || "$2" == "statefulset" ]]; then
      exit 1
    elif [[ "$2" == "pods" && "$*" == *"--no-headers"* ]]; then
      echo "test-app-12345"
    elif [[ "$2" == "pod" && "$*" == *"-o jsonpath"* ]]; then
      echo "false"
    fi
    ;;
  "-n")
    exit 0
    ;;
esac
EOF
  chmod +x "${TEST_TEMP_DIR}/bin/kubectl"
  
  run timeout 5 wait_for_workload "test-app" "default" "2"
  assert_failure
}

@test "wait_for_workload: handles custom namespace correctly" {
  cat > "${TEST_TEMP_DIR}/bin/kubectl" <<'EOF'
#!/usr/bin/env bash
echo "kubectl $@" >> "${TEST_TEMP_DIR}/kubectl.log"
case "$1" in
  "get")
    if [[ "$2" == "deployment" ]]; then
      exit 0
    fi
    ;;
  "wait")
    exit 0
    ;;
esac
EOF
  chmod +x "${TEST_TEMP_DIR}/bin/kubectl"
  export PATH="${TEST_TEMP_DIR}/bin:${PATH}"
  
  run wait_for_workload "test-app" "custom-namespace" "60"
  assert_success
  
  # Verify custom namespace was used
  run grep -- "custom-namespace" "${TEST_TEMP_DIR}/kubectl.log"
  assert_success
}

@test "wait_for_workload: handles custom timeout correctly" {
  cat > "${TEST_TEMP_DIR}/bin/kubectl" <<'EOF'
#!/usr/bin/env bash
echo "kubectl $@" >> "${TEST_TEMP_DIR}/kubectl.log"
case "$1" in
  "get")
    if [[ "$2" == "deployment" ]]; then
      exit 0
    fi
    ;;
  "wait")
    exit 0
    ;;
esac
EOF
  chmod +x "${TEST_TEMP_DIR}/bin/kubectl"
  export PATH="${TEST_TEMP_DIR}/bin:${PATH}"
  
  run wait_for_workload "test-app" "default" "120"
  assert_success
  
  # Verify custom timeout was used
  run grep -- "120s" "${TEST_TEMP_DIR}/kubectl.log"
  assert_success
}
