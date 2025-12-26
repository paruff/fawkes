#!/bin/bash
# =============================================================================
# Script: test-validation-scripts.sh
# Purpose: Test AT-E1-004 and AT-E1-009 validation scripts
# Usage: ./tests/integration/test-validation-scripts.sh
# =============================================================================

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get the root directory
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

log_info() {
  echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
  echo -e "${GREEN}[✓]${NC} $1"
}

log_error() {
  echo -e "${RED}[✗]${NC} $1"
}

log_warning() {
  echo -e "${YELLOW}[!]${NC} $1"
}

test_script_exists() {
  local script_path="$1"
  local script_name="$2"

  if [ -f "$script_path" ]; then
    log_success "$script_name exists"
    return 0
  else
    log_error "$script_name not found at $script_path"
    return 1
  fi
}

test_script_executable() {
  local script_path="$1"
  local script_name="$2"

  if [ -x "$script_path" ]; then
    log_success "$script_name is executable"
    return 0
  else
    log_error "$script_name is not executable"
    return 1
  fi
}

test_script_help() {
  local script_path="$1"
  local script_name="$2"

  if "$script_path" --help > /dev/null 2>&1; then
    log_success "$script_name help works"
    return 0
  else
    log_error "$script_name help failed"
    return 1
  fi
}

test_script_syntax() {
  local script_path="$1"
  local script_name="$2"

  if bash -n "$script_path" 2>&1; then
    log_success "$script_name has valid syntax"
    return 0
  else
    log_error "$script_name has syntax errors"
    return 1
  fi
}

main() {
  echo ""
  log_info "=============================================="
  log_info "Testing Validation Scripts"
  log_info "=============================================="
  echo ""

  local failed=0

  # Test AT-E1-004 script
  log_info "Testing AT-E1-004 validation script..."
  test_script_exists "$ROOT_DIR/scripts/validate-at-e1-004.sh" "AT-E1-004 script" || failed=$((failed + 1))
  test_script_executable "$ROOT_DIR/scripts/validate-at-e1-004.sh" "AT-E1-004 script" || failed=$((failed + 1))
  test_script_syntax "$ROOT_DIR/scripts/validate-at-e1-004.sh" "AT-E1-004 script" || failed=$((failed + 1))
  test_script_help "$ROOT_DIR/scripts/validate-at-e1-004.sh" "AT-E1-004 script" || failed=$((failed + 1))
  echo ""

  # Test AT-E1-009 script
  log_info "Testing AT-E1-009 validation script..."
  test_script_exists "$ROOT_DIR/scripts/validate-at-e1-009.sh" "AT-E1-009 script" || failed=$((failed + 1))
  test_script_executable "$ROOT_DIR/scripts/validate-at-e1-009.sh" "AT-E1-009 script" || failed=$((failed + 1))
  test_script_syntax "$ROOT_DIR/scripts/validate-at-e1-009.sh" "AT-E1-009 script" || failed=$((failed + 1))
  test_script_help "$ROOT_DIR/scripts/validate-at-e1-009.sh" "AT-E1-009 script" || failed=$((failed + 1))
  echo ""

  # Test run-test.sh script
  log_info "Testing run-test.sh runner..."
  test_script_exists "$ROOT_DIR/tests/acceptance/run-test.sh" "run-test.sh" || failed=$((failed + 1))
  test_script_executable "$ROOT_DIR/tests/acceptance/run-test.sh" "run-test.sh" || failed=$((failed + 1))
  test_script_syntax "$ROOT_DIR/tests/acceptance/run-test.sh" "run-test.sh" || failed=$((failed + 1))
  test_script_help "$ROOT_DIR/tests/acceptance/run-test.sh" "run-test.sh" || failed=$((failed + 1))
  echo ""

  # Test Makefile targets
  log_info "Testing Makefile targets..."
  if grep -q "validate-at-e1-004:" "$ROOT_DIR/Makefile"; then
    log_success "Makefile has validate-at-e1-004 target"
  else
    log_error "Makefile missing validate-at-e1-004 target"
    failed=$((failed + 1))
  fi

  if grep -q "validate-at-e1-009:" "$ROOT_DIR/Makefile"; then
    log_success "Makefile has validate-at-e1-009 target"
  else
    log_error "Makefile missing validate-at-e1-009 target"
    failed=$((failed + 1))
  fi
  echo ""

  # Test README documentation
  log_info "Testing README documentation..."
  if grep -q "AT-E1-004" "$ROOT_DIR/tests/acceptance/README.md"; then
    log_success "README documents AT-E1-004"
  else
    log_error "README missing AT-E1-004 documentation"
    failed=$((failed + 1))
  fi

  if grep -q "AT-E1-009" "$ROOT_DIR/tests/acceptance/README.md"; then
    log_success "README documents AT-E1-009"
  else
    log_error "README missing AT-E1-009 documentation"
    failed=$((failed + 1))
  fi
  echo ""

  # Summary
  log_info "=============================================="
  log_info "Test Summary"
  log_info "=============================================="
  if [ "$failed" -eq 0 ]; then
    log_success "All tests passed!"
    return 0
  else
    log_error "$failed test(s) failed"
    return 1
  fi
}

main "$@"
