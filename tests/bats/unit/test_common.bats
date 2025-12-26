#!/usr/bin/env bats
# =============================================================================
# BATS tests for scripts/lib/common.sh
# Tests error handling, logging, and state management functions
# =============================================================================

setup() {
  # Load test helpers
  load ../helpers/test_helper
  load ../helpers/mocks
  
  # Setup test environment
  setup_test_env
  
  # Source the common library
  source "${LIB_DIR}/common.sh"
}

teardown() {
  teardown_test_env
}

# =============================================================================
# Tests for error_exit function
# =============================================================================

@test "error_exit: displays error message to stderr" {
  run error_exit "Test error message"
  assert_failure
  assert_output --partial "[ERROR] Test error message"
}

@test "error_exit: uses custom exit code when provided" {
  run bash -c "source ${LIB_DIR}/common.sh; error_exit 'Test error' 42"
  assert_failure 42
}

@test "error_exit: uses exit code 1 by default" {
  run error_exit "Test error"
  assert_failure 1
}

# =============================================================================
# Tests for context_id function
# =============================================================================

@test "context_id: generates context ID from environment variables" {
  export ENV="test"
  export PROVIDER="azure"
  export CLUSTER_NAME="test-cluster"
  export REGION="eastus"
  export LOCATION=""
  
  run context_id
  assert_success
  assert_output "test:azure:test-cluster:eastus:"
}

@test "context_id: uses unknown for missing ENV" {
  unset ENV
  export PROVIDER="local"
  export CLUSTER_NAME="minikube"
  
  run context_id
  assert_success
  assert_output --partial "unknown:local:minikube"
}

@test "context_id: falls back to kubectl context when CLUSTER_NAME not set" {
  unset CLUSTER_NAME
  export ENV="dev"
  export PROVIDER="aws"
  
  setup_kubectl_mock
  
  run context_id
  assert_success
  # Should contain kubectl context or "unknown"
  assert_output --partial "dev:aws:"
}

@test "context_id: replaces spaces with underscores" {
  export ENV="test env"
  export PROVIDER="my provider"
  export CLUSTER_NAME="test cluster"
  
  run context_id
  assert_success
  assert_output "test_env:my_provider:test_cluster::"
}

# =============================================================================
# Tests for state_setup function
# =============================================================================

@test "state_setup: creates state file if it doesn't exist" {
  rm -f "${STATE_FILE}"
  
  run state_setup
  assert_success
  assert_file_exists "${STATE_FILE}"
}

@test "state_setup: initializes runs object in state file" {
  run state_setup
  assert_success
  
  # Verify runs object exists
  run jq -e '.runs' "${STATE_FILE}"
  assert_success
}

@test "state_setup: preserves existing state file content" {
  echo '{"existing":"data"}' > "${STATE_FILE}"
  
  run state_setup
  assert_success
  
  # Verify existing data is preserved
  run jq -e '.existing' "${STATE_FILE}"
  assert_success
  assert_output '"data"'
}

# =============================================================================
# Tests for state_is_done function
# =============================================================================

@test "state_is_done: returns true when step is marked done" {
  cat > "${STATE_FILE}" <<'EOF'
{"runs":{"test-context":{"steps":{"test-step":{"status":"done"}}}}}
EOF
  
  run state_is_done "test-step"
  assert_success
}

@test "state_is_done: returns false when step is not done" {
  cat > "${STATE_FILE}" <<'EOF'
{"runs":{"test-context":{"steps":{"test-step":{"status":"pending"}}}}}
EOF
  
  run state_is_done "test-step"
  assert_failure
}

@test "state_is_done: returns false when step doesn't exist" {
  cat > "${STATE_FILE}" <<'EOF'
{"runs":{"test-context":{"steps":{}}}}
EOF
  
  run state_is_done "nonexistent-step"
  assert_failure
}

@test "state_is_done: returns false when context doesn't exist" {
  cat > "${STATE_FILE}" <<'EOF'
{"runs":{}}
EOF
  
  run state_is_done "test-step"
  assert_failure
}

# =============================================================================
# Tests for state_mark_done function
# =============================================================================

@test "state_mark_done: marks step as done in state file" {
  state_setup
  
  run state_mark_done "test-step"
  assert_success
  
  # Verify step is marked as done
  run jq -e --arg ctx "${CONTEXT_ID}" --arg step "test-step" \
    '.runs[$ctx].steps[$step].status == "done"' "${STATE_FILE}"
  assert_success
}

@test "state_mark_done: adds timestamp to completed step" {
  state_setup
  
  run state_mark_done "test-step"
  assert_success
  
  # Verify timestamp exists
  run jq -e --arg ctx "${CONTEXT_ID}" --arg step "test-step" \
    '.runs[$ctx].steps[$step].ts' "${STATE_FILE}"
  assert_success
}

@test "state_mark_done: creates context if it doesn't exist" {
  cat > "${STATE_FILE}" <<'EOF'
{"runs":{}}
EOF
  
  run state_mark_done "test-step"
  assert_success
  
  # Verify context was created
  run jq -e --arg ctx "${CONTEXT_ID}" '.runs[$ctx]' "${STATE_FILE}"
  assert_success
}

# =============================================================================
# Tests for state_clear_context function
# =============================================================================

@test "state_clear_context: removes context from state file" {
  cat > "${STATE_FILE}" <<'EOF'
{"runs":{"test-context":{"steps":{"step1":{"status":"done"}}}}}
EOF
  
  run state_clear_context "test-context"
  assert_success
  
  # Verify context is removed
  run jq -e '.runs["test-context"]' "${STATE_FILE}"
  assert_failure
}

@test "state_clear_context: preserves other contexts" {
  cat > "${STATE_FILE}" <<'EOF'
{"runs":{"ctx1":{"steps":{}},"ctx2":{"steps":{}}}}
EOF
  
  run state_clear_context "ctx1"
  assert_success
  
  # Verify ctx2 still exists
  run jq -e '.runs["ctx2"]' "${STATE_FILE}"
  assert_success
}

# =============================================================================
# Tests for run_step function
# =============================================================================

@test "run_step: executes function and marks step done" {
  state_setup
  
  # Define test function
  test_func() {
    echo "test executed"
    return 0
  }
  
  run run_step "test-step" test_func
  assert_success
  assert_output --partial "test executed"
  
  # Verify step is marked done
  run state_is_done "test-step"
  assert_success
}

@test "run_step: skips step when RESUME=1 and step is done" {
  state_setup
  state_mark_done "test-step"
  export RESUME=1
  
  # Define test function that should not run
  test_func() {
    echo "should not execute"
    return 0
  }
  
  run run_step "test-step" test_func
  assert_success
  assert_output --partial "Skipping step 'test-step' (resume)"
  refute_output --partial "should not execute"
}

@test "run_step: executes step even if done when RESUME=0" {
  state_setup
  state_mark_done "test-step"
  export RESUME=0
  
  # Define test function
  test_func() {
    echo "executing again"
    return 0
  }
  
  run run_step "test-step" test_func
  assert_success
  assert_output --partial "executing again"
}

@test "run_step: returns failure code when function fails" {
  state_setup
  
  # Define failing function
  test_func() {
    return 42
  }
  
  run run_step "test-step" test_func
  assert_failure 42
}

@test "run_step: does not mark step done when DRY_RUN=1" {
  state_setup
  export DRY_RUN=1
  
  test_func() {
    echo "dry run test"
    return 0
  }
  
  run run_step "test-step" test_func
  assert_success
  assert_output --partial "[DRY-RUN] Not marking step 'test-step' as done"
  
  # Verify step is not marked done
  run state_is_done "test-step"
  assert_failure
}

@test "run_step: passes arguments to function" {
  state_setup
  
  test_func() {
    echo "arg1=$1 arg2=$2"
    return 0
  }
  
  run run_step "test-step" test_func "value1" "value2"
  assert_success
  assert_output --partial "arg1=value1 arg2=value2"
}

# =============================================================================
# Tests for cleanup_resources function
# =============================================================================

@test "cleanup_resources: calls kubectl to delete namespaces" {
  setup_kubectl_mock
  
  run cleanup_resources
  assert_success
  
  # Verify kubectl was called
  assert_file_exists "${TEST_TEMP_DIR}/kubectl.log"
  assert_file_contains "${TEST_TEMP_DIR}/kubectl.log" "delete namespace argocd"
  assert_file_contains "${TEST_TEMP_DIR}/kubectl.log" "delete namespace fawkes"
  assert_file_contains "${TEST_TEMP_DIR}/kubectl.log" "delete namespace jenkins"
}

@test "cleanup_resources: continues on error when deleting namespaces" {
  setup_kubectl_mock
  
  # Should not fail even if kubectl fails
  run cleanup_resources
  assert_success
}

@test "cleanup_resources: attempts to delete ArgoCD CRDs" {
  setup_kubectl_mock
  
  run cleanup_resources
  assert_success
  assert_output --partial "Cleaning up Argo CD cluster-scoped resources"
}
