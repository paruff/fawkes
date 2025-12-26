# BATS Test Helper Functions
# =============================================================================
# Common setup and helper functions for BATS tests
# =============================================================================

# Detect BATS helper library location
if [[ -d "${HOME}/.local/lib" ]]; then
  BATS_LIB_PATH="${HOME}/.local/lib"
elif [[ -d "/usr/local/lib" ]]; then
  BATS_LIB_PATH="/usr/local/lib"
elif [[ -d "/usr/lib" ]]; then
  BATS_LIB_PATH="/usr/lib"
else
  echo "ERROR: Cannot find BATS helper libraries" >&2
  exit 1
fi

# Load BATS helper libraries
load "${BATS_LIB_PATH}/bats-support/load.bash"
load "${BATS_LIB_PATH}/bats-assert/load.bash"
load "${BATS_LIB_PATH}/bats-file/load.bash"

# Project root directory (adjust for different test depths)
if [[ "${BATS_TEST_DIRNAME}" == *"/unit/providers"* ]]; then
  export PROJECT_ROOT="${BATS_TEST_DIRNAME}/../../../.."
elif [[ "${BATS_TEST_DIRNAME}" == *"/unit"* ]]; then
  export PROJECT_ROOT="${BATS_TEST_DIRNAME}/../../.."
else
  export PROJECT_ROOT="${BATS_TEST_DIRNAME}/../.."
fi

# Source directory for scripts
export SCRIPTS_DIR="${PROJECT_ROOT}/scripts"
export LIB_DIR="${SCRIPTS_DIR}/lib"

# Test fixtures directory
export FIXTURES_DIR="${BATS_TEST_DIRNAME}/fixtures"

# Setup function to create test environment
setup_test_env() {
  # Create temporary directory for test
  export TEST_TEMP_DIR="$(mktemp -d)"
  
  # Create temporary state file
  export STATE_FILE="${TEST_TEMP_DIR}/test-state.json"
  echo '{}' > "${STATE_FILE}"
  
  # Set test context
  export CONTEXT_ID="test-context"
  export DRY_RUN=0
  export RESUME=0
}

# Teardown function to clean up test environment
teardown_test_env() {
  if [[ -n "${TEST_TEMP_DIR:-}" && -d "${TEST_TEMP_DIR}" ]]; then
    rm -rf "${TEST_TEMP_DIR}"
  fi
}

# Mock kubectl command
mock_kubectl() {
  export -f kubectl
  kubectl() {
    echo "kubectl $*" >> "${TEST_TEMP_DIR}/kubectl.log"
    
    # Handle common kubectl commands for testing
    case "$1" in
      "cluster-info")
        return 0
        ;;
      "get")
        case "$2" in
          "nodes")
            echo '{"items":[{"status":{"conditions":[{"type":"Ready","status":"True"}]}}]}'
            ;;
          "storageclass")
            echo '{"items":[{"metadata":{"name":"default","annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}]}'
            ;;
          *)
            echo '{"items":[]}'
            ;;
        esac
        ;;
      *)
        return 0
        ;;
    esac
  }
}

# Mock jq command
mock_jq() {
  export -f jq
  jq() {
    # Simple mock that returns empty array for most queries
    echo "[]"
  }
}

# Helper to check if function exists
function_exists() {
  declare -f "$1" > /dev/null
  return $?
}

# Helper to create mock state file
create_mock_state() {
  local state_content="${1:-{}}"
  echo "${state_content}" > "${STATE_FILE}"
}

# Helper to assert file contains text
assert_file_contains() {
  local file="$1"
  local text="$2"
  run grep -F "${text}" "${file}"
  assert_success
}

# Helper to assert file does not contain text
assert_file_not_contains() {
  local file="$1"
  local text="$2"
  run grep -F "${text}" "${file}"
  assert_failure
}

# Helper to run script with timeout
run_with_timeout() {
  local timeout="$1"
  shift
  timeout "${timeout}" "$@"
}
