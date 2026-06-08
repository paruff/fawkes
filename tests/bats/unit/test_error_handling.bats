#!/usr/bin/env bats
# =============================================================================
# BATS tests for scripts/lib/error_handling.sh
# Tests error handling, logging, cleanup, and rollback mechanisms
# =============================================================================

setup() {
  load ../helpers/test_helper
  load ../helpers/mocks

  setup_test_env

  # Source the error handling library
  source "${LIB_DIR}/error_handling.sh"
}

teardown() {
  teardown_test_env
}

# =============================================================================
# Tests for source guard
# =============================================================================

@test "error_handling.sh: fails when executed directly" {
  run bash "${LIB_DIR}/error_handling.sh"
  assert_failure
  assert_output --partial "must be sourced"
}

# =============================================================================
# Tests for exit codes
# =============================================================================

@test "error_handling.sh: defines EXIT_SUCCESS as 0" {
  [ "$EXIT_SUCCESS" -eq 0 ]
}

@test "error_handling.sh: defines EXIT_GENERAL_ERROR as 1" {
  [ "$EXIT_GENERAL_ERROR" -eq 1 ]
}

@test "error_handling.sh: defines EXIT_MISSING_PREREQ as 2" {
  [ "$EXIT_MISSING_PREREQ" -eq 2 ]
}

@test "error_handling.sh: defines EXIT_VALIDATION_FAILED as 3" {
  [ "$EXIT_VALIDATION_FAILED" -eq 3 ]
}

@test "error_handling.sh: defines EXIT_NETWORK_ERROR as 4" {
  [ "$EXIT_NETWORK_ERROR" -eq 4 ]
}

@test "error_handling.sh: defines EXIT_TIMEOUT as 5" {
  [ "$EXIT_TIMEOUT" -eq 5 ]
}

@test "error_handling.sh: defines EXIT_USER_CANCELLED as 6" {
  [ "$EXIT_USER_CANCELLED" -eq 6 ]
}

@test "error_handling.sh: defines EXIT_CONFIG_ERROR as 7" {
  [ "$EXIT_CONFIG_ERROR" -eq 7 ]
}

@test "error_handling.sh: defines EXIT_PERMISSION_ERROR as 8" {
  [ "$EXIT_PERMISSION_ERROR" -eq 8 ]
}

# =============================================================================
# Tests for log_error
# =============================================================================

@test "log_error: outputs to stderr" {
  run log_error "test error message"
  assert_success
  assert_output --partial "test error message"
}

@test "log_error: includes ERROR prefix" {
  run log_error "something broke"
  assert_success
  assert_output --partial "ERROR"
}

@test "log_error: increments ERROR_COUNT" {
  ERROR_COUNT=0
  log_error "count me"
  [ "$ERROR_COUNT" -eq 1 ]
}

# =============================================================================
# Tests for log_info
# =============================================================================

@test "log_info: outputs message" {
  run log_info "info message"
  assert_success
  assert_output --partial "info message"
}

# =============================================================================
# Tests for log_warn
# =============================================================================

@test "log_warn: outputs warning" {
  run log_warn "warning message"
  assert_success
  assert_output --partial "warning message"
}

# =============================================================================
# Tests for register_cleanup_function
# =============================================================================

@test "register_cleanup_function: adds function to CLEANUP_FUNCTIONS" {
  CLEANUP_FUNCTIONS=()
  my_cleanup() { echo "cleaned"; }
  register_cleanup_function my_cleanup
  [ "${#CLEANUP_FUNCTIONS[@]}" -eq 1 ]
}

@test "register_cleanup_function: accumulates multiple cleanup functions" {
  CLEANUP_FUNCTIONS=()
  cleanup1() { true; }
  cleanup2() { true; }
  register_cleanup_function cleanup1
  register_cleanup_function cleanup2
  [ "${#CLEANUP_FUNCTIONS[@]}" -eq 2 ]
}

# =============================================================================
# Tests for register_rollback_function
# =============================================================================

@test "register_rollback_function: adds function to ROLLBACK_FUNCTIONS" {
  ROLLBACK_FUNCTIONS=()
  my_rollback() { echo "rolled back"; }
  register_rollback_function my_rollback
  [ "${#ROLLBACK_FUNCTIONS[@]}" -eq 1 ]
}

# =============================================================================
# Tests for error_exit
# =============================================================================

@test "error_exit: exits with code 1 by default" {
  run bash -c "source ${LIB_DIR}/error_handling.sh; error_exit 'fatal'"
  assert_failure 1
}

@test "error_exit: exits with custom code" {
  run bash -c "source ${LIB_DIR}/error_handling.sh; error_exit 'fatal' 42"
  assert_failure 42
}

@test "error_exit: displays error message" {
  run bash -c "source ${LIB_DIR}/error_handling.sh; error_exit 'something failed'"
  assert_failure
  assert_output --partial "something failed"
}

# =============================================================================
# Tests for log_fatal
# =============================================================================

@test "log_fatal: exits with code 1 by default" {
  run bash -c "source ${LIB_DIR}/error_handling.sh; log_fatal 'fatal error'"
  assert_failure 1
}

@test "log_fatal: exits with custom code" {
  run bash -c "source ${LIB_DIR}/error_handling.sh; log_fatal 'fatal' 99"
  assert_failure 99
}
