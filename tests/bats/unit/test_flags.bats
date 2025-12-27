#!/usr/bin/env bats
# =============================================================================
# BATS tests for scripts/lib/flags.sh
# Tests flag parsing and validation
# =============================================================================

setup() {
  # Load test helpers
  load ../helpers/test_helper
  load ../helpers/mocks
  
  # Setup test environment
  setup_test_env
  
  # Initialize required variables
  export PROVIDER=""
  export CLUSTER_NAME=""
  export REGION=""
  export LOCATION=""
  export ONLY_CLUSTER=0
  export ONLY_APPS=0
  export SKIP_CLUSTER=0
  export DRY_RUN=0
  export RESUME=0
  export VERBOSE=0
  export SHOW_ACCESS_ONLY=0
  export ENV=""
  export PREFER_MINIKUBE=0
  export PREFER_DOCKER=0
  
  # Source the flags library (and dependencies)
  source "${LIB_DIR}/common.sh"
  source "${LIB_DIR}/flags.sh"
}

teardown() {
  teardown_test_env
}

# =============================================================================
# Tests for parse_flags function
# =============================================================================

@test "parse_flags: handles --help flag" {
  run parse_flags --help
  # Should exit with error (usage) since --help exits
  assert_failure
  assert_output --partial "Usage:"
}

@test "parse_flags: handles --verbose flag" {
  parse_flags --verbose
  assert_equal "$VERBOSE" "1"
}

@test "parse_flags: handles --dry-run flag" {
  parse_flags --dry-run
  assert_equal "$DRY_RUN" "1"
}

@test "parse_flags: handles --provider flag" {
  parse_flags --provider aws local
  assert_equal "$PROVIDER" "aws"
}

@test "parse_flags: handles --cluster-name flag" {
  parse_flags --cluster-name test-cluster local
  assert_equal "$CLUSTER_NAME" "test-cluster"
}

@test "parse_flags: handles --region flag" {
  parse_flags --region us-west-2 local
  assert_equal "$REGION" "us-west-2"
}

@test "parse_flags: handles --only-cluster flag" {
  parse_flags --only-cluster local
  assert_equal "$ONLY_CLUSTER" "1"
}

@test "parse_flags: handles --only-apps flag" {
  parse_flags --only-apps local
  assert_equal "$ONLY_APPS" "1"
}

@test "parse_flags: handles --skip-cluster flag" {
  parse_flags --skip-cluster local
  assert_equal "$SKIP_CLUSTER" "1"
}

@test "parse_flags: handles --resume flag" {
  parse_flags --resume local
  assert_equal "$RESUME" "1"
}

@test "parse_flags: parses environment from positional arg" {
  parse_flags local
  assert_equal "$ENV" "local"
}

@test "parse_flags: handles multiple flags together" {
  parse_flags --verbose --dry-run --provider azure dev
  assert_equal "$VERBOSE" "1"
  assert_equal "$DRY_RUN" "1"
  assert_equal "$PROVIDER" "azure"
  assert_equal "$ENV" "dev"
}
