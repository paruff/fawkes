#!/bin/bash
# =============================================================================
# Test: test_error_handling.sh
# Purpose: Unit tests for error handling library
# Usage: ./tests/unit/test_error_handling.sh
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Test counters
TESTS_PASSED=0
TESTS_FAILED=0

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo "================================"
echo "Error Handling Library Tests"
echo "================================"
echo ""

# Test 1: Library file exists
echo "Test Group: File Existence"
if [[ -f "${ROOT_DIR}/scripts/lib/error_handling.sh" ]]; then
  echo -e "${GREEN}✓${NC} error_handling.sh exists"
  ((TESTS_PASSED++))
else
  echo -e "${RED}✗${NC} error_handling.sh does not exist"
  ((TESTS_FAILED++))
fi
echo ""

# Test 2: Library can be sourced
echo "Test Group: Library Loading"
export SKIP_TRAP_SETUP=1
if source "${ROOT_DIR}/scripts/lib/error_handling.sh" 2>/dev/null; then
  echo -e "${GREEN}✓${NC} error_handling.sh can be sourced"
  ((TESTS_PASSED++))
else
  echo -e "${RED}✗${NC} error_handling.sh cannot be sourced"
  ((TESTS_FAILED++))
  echo ""
  echo "================================"
  echo "Test Summary"
  echo "================================"
  echo "Tests Passed: ${GREEN}$TESTS_PASSED${NC}"
  echo "Tests Failed: ${RED}$TESTS_FAILED${NC}"
  exit 1
fi
echo ""

# Test 3: Functions are defined
echo "Test Group: Function Definitions"
FUNCTIONS=(
  "log_debug"
  "log_info"
  "log_success"
  "log_warn"
  "log_error"
  "log_fatal"
  "error_exit"
  "require_command"
  "require_var"
  "require_file"
  "require_directory"
  "retry_command"
  "show_progress"
  "show_section"
  "confirm"
)

for func in "${FUNCTIONS[@]}"; do
  if declare -f "$func" &> /dev/null; then
    echo -e "${GREEN}✓${NC} Function '$func' is defined"
    ((TESTS_PASSED++))
  else
    echo -e "${RED}✗${NC} Function '$func' is not defined"
    ((TESTS_FAILED++))
  fi
done
echo ""

# Test 4: Exit codes are defined
echo "Test Group: Exit Code Constants"
EXIT_CODES=(
  "EXIT_SUCCESS"
  "EXIT_GENERAL_ERROR"
  "EXIT_MISSING_PREREQ"
  "EXIT_VALIDATION_FAILED"
  "EXIT_NETWORK_ERROR"
  "EXIT_TIMEOUT"
  "EXIT_USER_CANCELLED"
  "EXIT_CONFIG_ERROR"
  "EXIT_PERMISSION_ERROR"
)

for code in "${EXIT_CODES[@]}"; do
  if [[ -n "${!code:-}" ]]; then
    echo -e "${GREEN}✓${NC} Constant '$code' is defined (value: ${!code})"
    ((TESTS_PASSED++))
  else
    echo -e "${RED}✗${NC} Constant '$code' is not defined"
    ((TESTS_FAILED++))
  fi
done
echo ""

# Test 5: Logging functions work
echo "Test Group: Logging Functions"
TEST_OUTPUT=$(log_info "test message" 2>&1)
if [[ "$TEST_OUTPUT" == *"test message"* ]]; then
  echo -e "${GREEN}✓${NC} log_info outputs correctly"
  ((TESTS_PASSED++))
else
  echo -e "${RED}✗${NC} log_info does not output correctly"
  ((TESTS_FAILED++))
fi

TEST_OUTPUT=$(log_success "test success" 2>&1)
if [[ "$TEST_OUTPUT" == *"test success"* ]]; then
  echo -e "${GREEN}✓${NC} log_success outputs correctly"
  ((TESTS_PASSED++))
else
  echo -e "${RED}✗${NC} log_success does not output correctly"
  ((TESTS_FAILED++))
fi

TEST_OUTPUT=$(log_warn "test warning" 2>&1)
if [[ "$TEST_OUTPUT" == *"test warning"* ]]; then
  echo -e "${GREEN}✓${NC} log_warn outputs correctly"
  ((TESTS_PASSED++))
else
  echo -e "${RED}✗${NC} log_warn does not output correctly"
  ((TESTS_FAILED++))
fi

TEST_OUTPUT=$(log_error "test error" 2>&1)
if [[ "$TEST_OUTPUT" == *"test error"* ]]; then
  echo -e "${GREEN}✓${NC} log_error outputs correctly"
  ((TESTS_PASSED++))
else
  echo -e "${RED}✗${NC} log_error does not output correctly"
  ((TESTS_FAILED++))
fi
echo ""

# Test 6: require_command works correctly
echo "Test Group: Validation Functions"
if require_command "bash" "bash should exist" 2>/dev/null; then
  echo -e "${GREEN}✓${NC} require_command works for existing command"
  ((TESTS_PASSED++))
else
  echo -e "${RED}✗${NC} require_command failed for existing command"
  ((TESTS_FAILED++))
fi

# Run in subshell to prevent exit
if (require_command "nonexistent_command_12345" "should not exist" 2>/dev/null); then
  echo -e "${RED}✗${NC} require_command passed for non-existing command"
  ((TESTS_FAILED++))
else
  echo -e "${GREEN}✓${NC} require_command fails for non-existing command"
  ((TESTS_PASSED++))
fi
echo ""

# Summary
echo "================================"
echo "Test Summary"
echo "================================"
echo "Tests Passed: ${GREEN}$TESTS_PASSED${NC}"
echo "Tests Failed: ${RED}$TESTS_FAILED${NC}"
echo ""

if [[ $TESTS_FAILED -eq 0 ]]; then
  echo -e "${GREEN}✓ All tests passed!${NC}"
  exit 0
else
  echo -e "${RED}✗ Some tests failed.${NC}"
  exit 1
fi
