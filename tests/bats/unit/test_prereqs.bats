#!/usr/bin/env bats
# =============================================================================
# BATS tests for scripts/lib/prereqs.sh
# Tests prerequisite checking functions
# =============================================================================

setup() {
  # Load test helpers
  load ../helpers/test_helper
  load ../helpers/mocks
  
  # Setup test environment
  setup_test_env
  
  # Source the common library (required by prereqs.sh)
  source "${LIB_DIR}/common.sh"
  
  # Source the prereqs library
  source "${LIB_DIR}/prereqs.sh"
  
  # Set AUTO_INSTALL to avoid interactive prompts
  export AUTO_INSTALL=0
}

teardown() {
  teardown_test_env
}

# =============================================================================
# Tests for check_prereqs function
# =============================================================================

@test "prereqs: check_prereqs function exists" {
  run type check_prereqs
  assert_success
  assert_output --partial "check_prereqs is a function"
}

@test "prereqs: validates basic tools when tools.sh doesn't exist" {
  # Move tools.sh out of the way temporarily
  if [[ -f "${SCRIPTS_DIR}/tools.sh" ]]; then
    mv "${SCRIPTS_DIR}/tools.sh" "${SCRIPTS_DIR}/tools.sh.bak"
  fi
  
  # Create mocks for required tools
  mkdir -p "${TEST_TEMP_DIR}/bin"
  for tool in kubectl jq base64 terraform; do
    cat > "${TEST_TEMP_DIR}/bin/${tool}" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
    chmod +x "${TEST_TEMP_DIR}/bin/${tool}"
  done
  
  export PATH="${TEST_TEMP_DIR}/bin:${PATH}"
  
  run check_prereqs
  assert_success
  assert_output --partial "All required tools are installed"
  
  # Restore tools.sh if it existed
  if [[ -f "${SCRIPTS_DIR}/tools.sh.bak" ]]; then
    mv "${SCRIPTS_DIR}/tools.sh.bak" "${SCRIPTS_DIR}/tools.sh"
  fi
}

@test "prereqs: module loads without errors" {
  run bash -c "source ${LIB_DIR}/prereqs.sh && echo 'loaded'"
  assert_success
  assert_output --partial "loaded"
}
