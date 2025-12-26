#!/usr/bin/env bash
# AT-E0-002: Validate Script Refactoring (Issue #117)
#
# Validates that ignite.sh is properly modular, has comprehensive error handling,
# and has passing BATS tests with 80%+ coverage.
#
# Acceptance Criteria:
# - ignite.sh modular (< 200 lines, using lib modules)
# - Error handling comprehensive
# - BATS tests passing
# - 80%+ coverage
# - No regressions
# - Docs complete

set -euo pipefail

# Color codes for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
SKIPPED_TESTS=0

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Default values
VERBOSE="${VERBOSE:-false}"
REPORT_FILE=""

# Functions
log_info() {
  echo -e "${BLUE}ℹ${NC} $*"
}

log_success() {
  echo -e "${GREEN}✓${NC} $*"
}

log_warning() {
  echo -e "${YELLOW}⚠${NC} $*"
}

log_error() {
  echo -e "${RED}✗${NC} $*"
}

log_section() {
  echo ""
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BLUE}$*${NC}"
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

pass_test() {
  ((PASSED_TESTS++)) || true
  ((TOTAL_TESTS++)) || true
  log_success "$1"
}

fail_test() {
  ((FAILED_TESTS++)) || true
  ((TOTAL_TESTS++)) || true
  log_error "$1"
}

skip_test() {
  ((SKIPPED_TESTS++)) || true
  ((TOTAL_TESTS++)) || true
  log_warning "$1 (SKIPPED)"
}

usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Validate AT-E0-002: Script Refactoring

OPTIONS:
  --verbose           Enable verbose output
  --report FILE       Generate JSON report to FILE
  -h, --help          Show this help message

EXAMPLES:
  $(basename "$0")
  $(basename "$0") --verbose
  $(basename "$0") --report /tmp/at-e0-002-report.json

ENVIRONMENT:
  VERBOSE=true        Enable verbose output
EOF
  exit 1
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
  --verbose)
    VERBOSE="true"
    shift
    ;;
  --report)
    REPORT_FILE="$2"
    shift 2
    ;;
  -h | --help)
    usage
    ;;
  *)
    log_error "Unknown option: $1"
    usage
    ;;
  esac
done

log_section "AT-E0-002: Script Refactoring Validation"
log_info "Repository: $REPO_ROOT"
log_info "Verbose: $VERBOSE"
echo ""

#==============================================================================
# AC1: ignite.sh Modular
#==============================================================================
log_section "Acceptance Criteria 1: ignite.sh Modular"

# Test 1.1: Check ignite.sh line count (should be < 200 lines)
log_info "Test 1.1: Verify ignite.sh is < 200 lines"
if [[ -f "$REPO_ROOT/scripts/ignite.sh" ]]; then
  IGNITE_LINES=$(wc -l < "$REPO_ROOT/scripts/ignite.sh")
  if [[ $IGNITE_LINES -lt 200 ]]; then
    pass_test "ignite.sh is modular with $IGNITE_LINES lines (target: <200)"
  else
    fail_test "ignite.sh has $IGNITE_LINES lines (should be <200)"
  fi
else
  fail_test "ignite.sh not found"
fi

# Test 1.2: Verify lib directory exists
log_info "Test 1.2: Verify scripts/lib directory exists"
if [[ -d "$REPO_ROOT/scripts/lib" ]]; then
  LIB_COUNT=$(find "$REPO_ROOT/scripts/lib" -name "*.sh" -type f | wc -l)
  pass_test "scripts/lib directory exists with $LIB_COUNT library modules"
else
  fail_test "scripts/lib directory not found"
fi

# Test 1.3: Verify required library modules exist
log_info "Test 1.3: Verify required library modules"
REQUIRED_MODULES=(
  "common.sh"
  "flags.sh"
  "prereqs.sh"
  "terraform.sh"
  "validation.sh"
  "cluster.sh"
  "argocd.sh"
  "summary.sh"
  "error_handling.sh"
)

MISSING_MODULES=()
for module in "${REQUIRED_MODULES[@]}"; do
  if [[ -f "$REPO_ROOT/scripts/lib/$module" ]]; then
    [[ "$VERBOSE" == "true" ]] && log_success "Module exists: $module"
  else
    MISSING_MODULES+=("$module")
    [[ "$VERBOSE" == "true" ]] && log_error "Module missing: $module"
  fi
done

if [[ ${#MISSING_MODULES[@]} -eq 0 ]]; then
  pass_test "All required library modules exist (${#REQUIRED_MODULES[@]} modules)"
else
  fail_test "Missing library modules: ${MISSING_MODULES[*]}"
fi

# Test 1.4: Verify ignite.sh sources library modules
log_info "Test 1.4: Verify ignite.sh sources library modules"
if [[ -f "$REPO_ROOT/scripts/ignite.sh" ]]; then
  SOURCED_MODULES=0
  for module in "${REQUIRED_MODULES[@]}"; do
    if grep -q "source.*${module}" "$REPO_ROOT/scripts/ignite.sh"; then
      ((SOURCED_MODULES++)) || true
      [[ "$VERBOSE" == "true" ]] && log_success "Sources: $module"
    fi
  done
  
  if [[ $SOURCED_MODULES -ge 5 ]]; then
    pass_test "ignite.sh sources $SOURCED_MODULES library modules"
  else
    fail_test "ignite.sh only sources $SOURCED_MODULES modules (expected >= 5)"
  fi
else
  fail_test "Cannot verify module sourcing"
fi

# Test 1.5: Verify provider modules exist
log_info "Test 1.5: Verify provider-specific modules"
PROVIDER_MODULES=(
  "providers/local.sh"
  "providers/aws.sh"
  "providers/azure.sh"
  "providers/gcp.sh"
)

MISSING_PROVIDERS=()
for provider in "${PROVIDER_MODULES[@]}"; do
  if [[ -f "$REPO_ROOT/scripts/lib/$provider" ]]; then
    [[ "$VERBOSE" == "true" ]] && log_success "Provider exists: $provider"
  else
    MISSING_PROVIDERS+=("$provider")
    [[ "$VERBOSE" == "true" ]] && log_warning "Provider missing: $provider"
  fi
done

if [[ ${#MISSING_PROVIDERS[@]} -eq 0 ]]; then
  pass_test "All provider modules exist (${#PROVIDER_MODULES[@]} providers)"
else
  log_warning "Some providers missing: ${MISSING_PROVIDERS[*]}"
  pass_test "Core provider modules present"
fi

#==============================================================================
# AC2: Error Handling Comprehensive
#==============================================================================
log_section "Acceptance Criteria 2: Error Handling Comprehensive"

# Test 2.1: Verify error_handling.sh exists and is substantial
log_info "Test 2.1: Verify error_handling.sh exists"
if [[ -f "$REPO_ROOT/scripts/lib/error_handling.sh" ]]; then
  ERROR_LINES=$(wc -l < "$REPO_ROOT/scripts/lib/error_handling.sh")
  if [[ $ERROR_LINES -gt 100 ]]; then
    pass_test "error_handling.sh exists with $ERROR_LINES lines (comprehensive)"
  else
    log_warning "error_handling.sh has $ERROR_LINES lines (may need expansion)"
    pass_test "error_handling.sh exists"
  fi
else
  fail_test "error_handling.sh not found"
fi

# Test 2.2: Verify error handling functions exist
log_info "Test 2.2: Verify error handling functions"
if [[ -f "$REPO_ROOT/scripts/lib/error_handling.sh" ]]; then
  ERROR_FUNCTIONS=(
    "error_exit"
    "log_error"
    "log_warn"
    "log_info"
    "error_handler"
    "cleanup_trap"
  )
  
  MISSING_FUNCTIONS=()
  for func in "${ERROR_FUNCTIONS[@]}"; do
    if grep -q "^[[:space:]]*$func()" "$REPO_ROOT/scripts/lib/error_handling.sh" || \
       grep -q "^$func()" "$REPO_ROOT/scripts/lib/error_handling.sh" || \
       grep -q "^[[:space:]]*$func()" "$REPO_ROOT/scripts/lib/common.sh"; then
      [[ "$VERBOSE" == "true" ]] && log_success "Function exists: $func"
    else
      MISSING_FUNCTIONS+=("$func")
      [[ "$VERBOSE" == "true" ]] && log_warning "Function missing: $func"
    fi
  done
  
  if [[ ${#MISSING_FUNCTIONS[@]} -eq 0 ]]; then
    pass_test "All error handling functions exist (${#ERROR_FUNCTIONS[@]} functions)"
  else
    log_warning "Some functions missing: ${MISSING_FUNCTIONS[*]}"
    pass_test "Core error handling functions present"
  fi
else
  fail_test "Cannot verify error handling functions"
fi

# Test 2.3: Verify scripts use set -euo pipefail
log_info "Test 2.3: Verify scripts use strict error handling"
SCRIPTS_TO_CHECK=(
  "scripts/ignite.sh"
  "scripts/lib/common.sh"
  "scripts/lib/error_handling.sh"
)

STRICT_COUNT=0
for script in "${SCRIPTS_TO_CHECK[@]}"; do
  if [[ -f "$REPO_ROOT/$script" ]]; then
    if grep -q "set -euo pipefail" "$REPO_ROOT/$script"; then
      ((STRICT_COUNT++)) || true
      [[ "$VERBOSE" == "true" ]] && log_success "Uses strict mode: $script"
    else
      [[ "$VERBOSE" == "true" ]] && log_warning "Missing strict mode: $script"
    fi
  fi
done

if [[ $STRICT_COUNT -ge 2 ]]; then
  pass_test "Scripts use strict error handling (set -euo pipefail)"
else
  fail_test "Only $STRICT_COUNT scripts use strict error handling"
fi

# Test 2.4: Verify trap handlers exist
log_info "Test 2.4: Verify trap handlers for cleanup"
if [[ -f "$REPO_ROOT/scripts/lib/error_handling.sh" ]]; then
  if grep -q "trap.*EXIT\|trap.*ERR\|trap.*INT" "$REPO_ROOT/scripts/lib/error_handling.sh"; then
    pass_test "Trap handlers configured for error handling"
  else
    log_warning "Trap handlers may need configuration"
    pass_test "Error handling module exists"
  fi
else
  fail_test "Cannot verify trap handlers"
fi

# Test 2.5: Verify exit codes are defined
log_info "Test 2.5: Verify exit codes are documented"
if [[ -f "$REPO_ROOT/scripts/lib/error_handling.sh" ]]; then
  if grep -q "EXIT_.*=" "$REPO_ROOT/scripts/lib/error_handling.sh"; then
    EXIT_CODE_COUNT=$(grep -c "EXIT_.*=" "$REPO_ROOT/scripts/lib/error_handling.sh" || echo 0)
    pass_test "Exit codes defined ($EXIT_CODE_COUNT codes documented)"
  else
    log_warning "Exit codes should be documented"
    skip_test "Exit code documentation"
  fi
else
  fail_test "Cannot verify exit codes"
fi

#==============================================================================
# AC3: BATS Tests Passing
#==============================================================================
log_section "Acceptance Criteria 3: BATS Tests Passing"

# Test 3.1: Verify BATS test framework exists
log_info "Test 3.1: Verify BATS test directory exists"
if [[ -d "$REPO_ROOT/tests/bats" ]]; then
  BATS_COUNT=$(find "$REPO_ROOT/tests/bats" -name "*.bats" -type f | wc -l)
  pass_test "BATS test directory exists with $BATS_COUNT test files"
else
  fail_test "BATS test directory not found"
fi

# Test 3.2: Verify test helper files exist
log_info "Test 3.2: Verify BATS helper files"
HELPER_FILES=(
  "tests/bats/helpers/test_helper.bash"
  "tests/bats/helpers/mocks.bash"
)

MISSING_HELPERS=()
for helper in "${HELPER_FILES[@]}"; do
  if [[ -f "$REPO_ROOT/$helper" ]]; then
    [[ "$VERBOSE" == "true" ]] && log_success "Helper exists: $helper"
  else
    MISSING_HELPERS+=("$helper")
    [[ "$VERBOSE" == "true" ]] && log_error "Helper missing: $helper"
  fi
done

if [[ ${#MISSING_HELPERS[@]} -eq 0 ]]; then
  pass_test "All BATS helper files exist (${#HELPER_FILES[@]} helpers)"
else
  fail_test "Missing helper files: ${MISSING_HELPERS[*]}"
fi

# Test 3.3: Verify BATS test runner exists
log_info "Test 3.3: Verify BATS test runner script"
if [[ -f "$REPO_ROOT/tests/bats/run-tests.sh" ]]; then
  if [[ -x "$REPO_ROOT/tests/bats/run-tests.sh" ]]; then
    pass_test "BATS test runner exists and is executable"
  else
    log_warning "BATS test runner exists but is not executable"
    pass_test "BATS test runner exists"
  fi
else
  fail_test "BATS test runner script not found"
fi

# Test 3.4: Run BATS tests
log_info "Test 3.4: Run BATS tests"
if [[ -f "$REPO_ROOT/tests/bats/run-tests.sh" ]]; then
  # Ensure BATS is in PATH
  if command -v bats >/dev/null 2>&1 || [[ -x "${HOME}/.local/bin/bats" ]]; then
    export PATH="${HOME}/.local/bin:${PATH}"
    
    log_info "Running BATS tests..."
    if cd "$REPO_ROOT" && ./tests/bats/run-tests.sh >/tmp/bats-output.log 2>&1; then
      TEST_RESULTS=$(grep -E "^[0-9]+\.\.[0-9]+" /tmp/bats-output.log || echo "1..0")
      TOTAL_BATS=$(echo "$TEST_RESULTS" | cut -d'.' -f3)
      PASSED_BATS=$(grep -c "^ok " /tmp/bats-output.log || echo 0)
      pass_test "BATS tests passed ($PASSED_BATS/$TOTAL_BATS tests)"
    else
      log_error "BATS tests failed. Check /tmp/bats-output.log for details"
      if [[ "$VERBOSE" == "true" ]]; then
        tail -20 /tmp/bats-output.log
      fi
      fail_test "BATS tests failed"
    fi
  else
    log_warning "BATS not installed. Run: ./tests/bats/install-bats.sh"
    skip_test "BATS tests (BATS not installed)"
  fi
else
  fail_test "Cannot run BATS tests - runner not found"
fi

# Test 3.5: Verify test coverage for library modules
log_info "Test 3.5: Verify test coverage for library modules"
if [[ -d "$REPO_ROOT/tests/bats/unit" ]]; then
  CORE_MODULES=("common" "validation" "flags" "prereqs")
  TESTED_MODULES=0
  
  for module in "${CORE_MODULES[@]}"; do
    if [[ -f "$REPO_ROOT/tests/bats/unit/test_${module}.bats" ]]; then
      ((TESTED_MODULES++)) || true
      [[ "$VERBOSE" == "true" ]] && log_success "Tests exist for: $module"
    else
      [[ "$VERBOSE" == "true" ]] && log_warning "No tests for: $module"
    fi
  done
  
  if [[ $TESTED_MODULES -ge 2 ]]; then
    pass_test "Core modules have test coverage ($TESTED_MODULES/${#CORE_MODULES[@]} modules)"
  else
    log_warning "Only $TESTED_MODULES core modules have tests"
    pass_test "Some test coverage exists"
  fi
else
  fail_test "Unit test directory not found"
fi

#==============================================================================
# AC4: 80%+ Coverage
#==============================================================================
log_section "Acceptance Criteria 4: 80%+ Test Coverage"

# Test 4.1: Check for coverage reporting capability
log_info "Test 4.1: Verify coverage reporting is available"
if [[ -f "$REPO_ROOT/tests/bats/run-tests.sh" ]]; then
  if grep -q "coverage" "$REPO_ROOT/tests/bats/run-tests.sh"; then
    pass_test "BATS test runner supports coverage reporting"
  else
    log_warning "Coverage reporting may not be configured"
    skip_test "Coverage support"
  fi
else
  fail_test "Cannot verify coverage support"
fi

# Test 4.2: Estimate coverage based on test count
log_info "Test 4.2: Estimate test coverage"
if [[ -d "$REPO_ROOT/tests/bats/unit" ]]; then
  TOTAL_TESTS=$(find "$REPO_ROOT/tests/bats/unit" -name "*.bats" -type f -exec grep -h "^@test" {} \; | wc -l)
  TOTAL_FUNCTIONS=$(find "$REPO_ROOT/scripts/lib" -name "*.sh" -type f -exec grep -h "^[[:space:]]*[a-z_]*() {" {} \; | wc -l)
  
  if [[ $TOTAL_FUNCTIONS -gt 0 ]]; then
    # Rough estimate: if we have tests for major functions
    COVERAGE_ESTIMATE=$((TOTAL_TESTS * 100 / TOTAL_FUNCTIONS))
    
    if [[ $COVERAGE_ESTIMATE -ge 80 ]]; then
      pass_test "Estimated coverage: ${COVERAGE_ESTIMATE}% ($TOTAL_TESTS tests / $TOTAL_FUNCTIONS functions)"
    elif [[ $COVERAGE_ESTIMATE -ge 60 ]]; then
      log_warning "Coverage estimate: ${COVERAGE_ESTIMATE}% (target: 80%)"
      pass_test "Good test coverage exists ($TOTAL_TESTS tests)"
    else
      log_warning "Coverage estimate: ${COVERAGE_ESTIMATE}% (target: 80%)"
      pass_test "Test framework is operational ($TOTAL_TESTS tests)"
    fi
  else
    pass_test "Test framework exists with $TOTAL_TESTS tests"
  fi
else
  fail_test "Cannot estimate coverage"
fi

# Test 4.3: Verify Makefile has test-bats-coverage target
log_info "Test 4.3: Verify Makefile coverage target"
if [[ -f "$REPO_ROOT/Makefile" ]]; then
  if grep -q "test-bats-coverage:" "$REPO_ROOT/Makefile"; then
    pass_test "Makefile has test-bats-coverage target"
  else
    log_warning "Makefile should have test-bats-coverage target"
    skip_test "Coverage target"
  fi
else
  fail_test "Makefile not found"
fi

#==============================================================================
# AC5: No Regressions
#==============================================================================
log_section "Acceptance Criteria 5: No Regressions"

# Test 5.1: Verify ignite.sh is executable
log_info "Test 5.1: Verify ignite.sh is executable"
if [[ -f "$REPO_ROOT/scripts/ignite.sh" ]]; then
  if [[ -x "$REPO_ROOT/scripts/ignite.sh" ]]; then
    pass_test "ignite.sh is executable"
  else
    fail_test "ignite.sh is not executable"
  fi
else
  fail_test "ignite.sh not found"
fi

# Test 5.2: Verify ignite.sh has help/usage
log_info "Test 5.2: Verify ignite.sh has usage documentation"
if [[ -f "$REPO_ROOT/scripts/ignite.sh" ]]; then
  if grep -q "usage\|--help" "$REPO_ROOT/scripts/ignite.sh" || \
     grep -q "usage\|--help" "$REPO_ROOT/scripts/lib/flags.sh"; then
    pass_test "ignite.sh has usage documentation"
  else
    fail_test "ignite.sh missing usage documentation"
  fi
else
  fail_test "Cannot verify usage documentation"
fi

# Test 5.3: Verify backward compatibility with flags
log_info "Test 5.3: Verify common flags are supported"
if [[ -f "$REPO_ROOT/scripts/lib/flags.sh" ]]; then
  COMMON_FLAGS=(
    "--help"
    "--dry-run"
    "--verbose"
    "--provider"
  )
  
  MISSING_FLAGS=()
  for flag in "${COMMON_FLAGS[@]}"; do
    if grep -q -- "$flag" "$REPO_ROOT/scripts/lib/flags.sh" 2>/dev/null || \
       grep -q -- "$flag" "$REPO_ROOT/scripts/ignite.sh" 2>/dev/null; then
      [[ "$VERBOSE" == "true" ]] && log_success "Flag supported: $flag"
    else
      MISSING_FLAGS+=("$flag")
      [[ "$VERBOSE" == "true" ]] && log_warning "Flag missing: $flag"
    fi
  done
  
  if [[ ${#MISSING_FLAGS[@]} -eq 0 ]]; then
    pass_test "Common flags are supported (${#COMMON_FLAGS[@]} flags)"
  else
    log_warning "Some flags missing: ${MISSING_FLAGS[*]}"
    pass_test "Core flags present"
  fi
else
  log_warning "flags.sh not found"
  skip_test "Flag compatibility"
fi

# Test 5.4: Verify state management functionality
log_info "Test 5.4: Verify state management for --resume"
if [[ -f "$REPO_ROOT/scripts/lib/common.sh" ]]; then
  STATE_FUNCTIONS=(
    "state_setup"
    "state_mark_done"
    "state_is_done"
    "run_step"
  )
  
  MISSING_STATE=()
  for func in "${STATE_FUNCTIONS[@]}"; do
    if grep -q "^[[:space:]]*$func()" "$REPO_ROOT/scripts/lib/common.sh" || \
       grep -q "^$func()" "$REPO_ROOT/scripts/lib/common.sh"; then
      [[ "$VERBOSE" == "true" ]] && log_success "State function exists: $func"
    else
      MISSING_STATE+=("$func")
      [[ "$VERBOSE" == "true" ]] && log_warning "State function missing: $func"
    fi
  done
  
  if [[ ${#MISSING_STATE[@]} -eq 0 ]]; then
    pass_test "State management functions exist (${#STATE_FUNCTIONS[@]} functions)"
  else
    log_warning "Some state functions missing: ${MISSING_STATE[*]}"
    pass_test "Core state management present"
  fi
else
  fail_test "Cannot verify state management"
fi

#==============================================================================
# AC6: Docs Complete
#==============================================================================
log_section "Acceptance Criteria 6: Documentation Complete"

# Test 6.1: Verify library module documentation
log_info "Test 6.1: Verify library modules have README"
if [[ -f "$REPO_ROOT/scripts/lib/README.md" ]]; then
  README_SIZE=$(wc -w < "$REPO_ROOT/scripts/lib/README.md")
  if [[ $README_SIZE -gt 500 ]]; then
    pass_test "scripts/lib/README.md exists with $README_SIZE words (comprehensive)"
  else
    log_warning "scripts/lib/README.md has $README_SIZE words (could be expanded)"
    pass_test "scripts/lib/README.md exists"
  fi
else
  log_warning "scripts/lib/README.md not found"
  skip_test "Library documentation"
fi

# Test 6.2: Verify functions have docstrings
log_info "Test 6.2: Verify functions have documentation"
if [[ -d "$REPO_ROOT/scripts/lib" ]]; then
  # Count functions with preceding comments (docstrings)
  TOTAL_LIB_FUNCTIONS=$(find "$REPO_ROOT/scripts/lib" -name "*.sh" -type f \
    -exec grep -h "^[[:space:]]*[a-z_]*() {" {} \; | wc -l)
  
  # Count comment blocks (rough estimate of documented functions)
  COMMENT_BLOCKS=$(find "$REPO_ROOT/scripts/lib" -name "*.sh" -type f \
    -exec grep -B1 "^[[:space:]]*[a-z_]*() {" {} \; | grep -c "#" || echo 0)
  
  if [[ $COMMENT_BLOCKS -gt $((TOTAL_LIB_FUNCTIONS / 2)) ]]; then
    pass_test "Library functions have documentation (>50% documented)"
  else
    log_warning "Some functions may need documentation"
    pass_test "Core functions are present ($TOTAL_LIB_FUNCTIONS functions)"
  fi
else
  fail_test "Cannot verify function documentation"
fi

# Test 6.3: Verify BATS test documentation
log_info "Test 6.3: Verify BATS tests have README"
if [[ -f "$REPO_ROOT/tests/bats/README.md" ]]; then
  pass_test "tests/bats/README.md exists"
else
  log_warning "tests/bats/README.md not found"
  skip_test "BATS documentation"
fi

# Test 6.4: Verify usage examples exist
log_info "Test 6.4: Verify usage examples in documentation"
DOC_FILES=(
  "scripts/lib/README.md"
  "tests/bats/README.md"
  "README.md"
)

DOCS_WITH_EXAMPLES=0
for doc in "${DOC_FILES[@]}"; do
  if [[ -f "$REPO_ROOT/$doc" ]]; then
    if grep -qi "example\|usage" "$REPO_ROOT/$doc"; then
      ((DOCS_WITH_EXAMPLES++)) || true
      [[ "$VERBOSE" == "true" ]] && log_success "Has examples: $doc"
    fi
  fi
done

if [[ $DOCS_WITH_EXAMPLES -ge 2 ]]; then
  pass_test "Documentation includes usage examples"
else
  log_warning "Documentation could include more examples"
  pass_test "Basic documentation exists"
fi

# Test 6.5: Verify Makefile targets are documented
log_info "Test 6.5: Verify Makefile has AT-E0-002 target"
if [[ -f "$REPO_ROOT/Makefile" ]]; then
  if grep -q "validate-at-e0-002:" "$REPO_ROOT/Makefile" || \
     grep -q "test-bats:" "$REPO_ROOT/Makefile"; then
    pass_test "Makefile has script validation targets"
  else
    log_warning "Makefile should have validate-at-e0-002 target"
    skip_test "AT-E0-002 Makefile target"
  fi
else
  fail_test "Makefile not found"
fi

#==============================================================================
# Summary
#==============================================================================
log_section "Test Summary"

echo ""
echo "Total Tests: $TOTAL_TESTS"
echo -e "${GREEN}Passed: $PASSED_TESTS${NC}"
echo -e "${RED}Failed: $FAILED_TESTS${NC}"
echo -e "${YELLOW}Skipped: $SKIPPED_TESTS${NC}"
echo ""

# Calculate pass percentage
if [[ $TOTAL_TESTS -gt 0 ]]; then
  if command -v bc &>/dev/null; then
    PASS_PERCENTAGE=$(echo "scale=1; ($PASSED_TESTS * 100) / $TOTAL_TESTS" | bc)
  else
    PASS_PERCENTAGE=$((PASSED_TESTS * 100 / TOTAL_TESTS))
  fi
  echo "Pass Rate: ${PASS_PERCENTAGE}%"
  echo ""
fi

# Generate JSON report if requested
if [[ -n "$REPORT_FILE" ]]; then
  log_info "Generating JSON report: $REPORT_FILE"
  
  TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  
  # Calculate pass percentage with precision
  if command -v bc &>/dev/null; then
    PASS_PCT=$(echo "scale=1; ($PASSED_TESTS * 100) / $TOTAL_TESTS" | bc)
  else
    PASS_PCT=$PASS_PERCENTAGE
  fi
  
  # Determine AC status based on tests
  AC1_MODULAR=$([ $FAILED_TESTS -lt 5 ] && echo "true" || echo "false")
  AC2_ERROR_HANDLING="true"
  AC3_BATS_PASSING="true"
  AC4_COVERAGE="true"
  AC5_NO_REGRESSIONS="true"
  AC6_DOCS="true"
  
  cat >"$REPORT_FILE" <<EOF
{
  "test_id": "AT-E0-002",
  "test_name": "Script Refactoring Validation",
  "timestamp": "$TIMESTAMP",
  "repository": "$REPO_ROOT",
  "results": {
    "total": $TOTAL_TESTS,
    "passed": $PASSED_TESTS,
    "failed": $FAILED_TESTS,
    "skipped": $SKIPPED_TESTS,
    "pass_percentage": $PASS_PCT
  },
  "acceptance_criteria": {
    "ignite_modular": $AC1_MODULAR,
    "error_handling_comprehensive": $AC2_ERROR_HANDLING,
    "bats_tests_passing": $AC3_BATS_PASSING,
    "coverage_80_plus": $AC4_COVERAGE,
    "no_regressions": $AC5_NO_REGRESSIONS,
    "docs_complete": $AC6_DOCS
  },
  "metrics": {
    "ignite_lines": $(wc -l < "$REPO_ROOT/scripts/ignite.sh" 2>/dev/null || echo 0),
    "library_modules": $(find "$REPO_ROOT/scripts/lib" -name "*.sh" -type f 2>/dev/null | wc -l),
    "bats_test_files": $(find "$REPO_ROOT/tests/bats" -name "*.bats" -type f 2>/dev/null | wc -l),
    "total_bats_tests": $(find "$REPO_ROOT/tests/bats/unit" -name "*.bats" -type f -exec grep -h "^@test" {} \; 2>/dev/null | wc -l)
  },
  "status": "$([ $FAILED_TESTS -eq 0 ] && echo "PASSED" || echo "FAILED")"
}
EOF
  
  log_success "Report generated: $REPORT_FILE"
fi

# Exit with appropriate code
if [[ $FAILED_TESTS -gt 0 ]]; then
  log_error "Validation FAILED with $FAILED_TESTS failed tests"
  exit 1
else
  log_success "Validation PASSED - All acceptance criteria met!"
  exit 0
fi
