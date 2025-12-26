#!/usr/bin/env bash
# =============================================================================
# File: tests/bats/run-tests.sh
# Purpose: Run BATS tests with coverage reporting
# Usage: ./tests/bats/run-tests.sh [--coverage] [--filter PATTERN]
# =============================================================================

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
BATS_TESTS_DIR="${SCRIPT_DIR}/unit"
COVERAGE_DIR="${PROJECT_ROOT}/reports/bats-coverage"
RESULTS_DIR="${PROJECT_ROOT}/reports/bats-results"

# Options
COVERAGE=0
FILTER=""
VERBOSE=0
JUNIT=0

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --coverage)
      COVERAGE=1
      shift
      ;;
    --filter)
      FILTER="$2"
      shift 2
      ;;
    --verbose)
      VERBOSE=1
      shift
      ;;
    --junit)
      JUNIT=1
      shift
      ;;
    --help)
      cat <<EOF
Usage: $0 [OPTIONS]

Run BATS tests for Bash scripts

OPTIONS:
    --coverage     Generate code coverage report using kcov
    --filter STR   Only run tests matching STR pattern
    --verbose      Show verbose test output
    --junit        Generate JUnit XML report
    --help         Show this help message

EXAMPLES:
    # Run all tests
    $0

    # Run tests with coverage
    $0 --coverage

    # Run only common.sh tests
    $0 --filter test_common

    # Run with verbose output and JUnit report
    $0 --verbose --junit
EOF
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

# Ensure BATS is in PATH
if ! command -v bats >/dev/null 2>&1; then
  echo -e "${YELLOW}⚠️  BATS not found in PATH${NC}"
  echo -e "${BLUE}ℹ️  Installing BATS...${NC}"
  "${SCRIPT_DIR}/install-bats.sh" --prefix "${HOME}/.local"
  export PATH="${HOME}/.local/bin:${PATH}"
  
  if ! command -v bats >/dev/null 2>&1; then
    echo -e "${RED}❌ Failed to install BATS${NC}"
    exit 1
  fi
fi

echo -e "${BLUE}🧪 Running BATS tests...${NC}"
echo ""

# Create reports directory
mkdir -p "${RESULTS_DIR}" "${COVERAGE_DIR}"

# Find test files
TEST_FILES=()
if [[ -n "${FILTER}" ]]; then
  mapfile -t TEST_FILES < <(find "${BATS_TESTS_DIR}" -name "*${FILTER}*.bats")
  if [[ ${#TEST_FILES[@]} -eq 0 ]]; then
    echo -e "${RED}❌ No tests found matching filter: ${FILTER}${NC}"
    exit 1
  fi
  echo -e "${BLUE}ℹ️  Running ${#TEST_FILES[@]} test file(s) matching '${FILTER}'${NC}"
else
  mapfile -t TEST_FILES < <(find "${BATS_TESTS_DIR}" -name "*.bats")
  echo -e "${BLUE}ℹ️  Running ${#TEST_FILES[@]} test file(s)${NC}"
fi

# BATS options
BATS_OPTS=()
if [[ ${VERBOSE} -eq 1 ]]; then
  BATS_OPTS+=("--verbose-run")
fi

if [[ ${JUNIT} -eq 1 ]]; then
  BATS_OPTS+=("--formatter" "junit" "--output" "${RESULTS_DIR}")
fi

# Run tests
FAILED=0
if [[ ${COVERAGE} -eq 1 ]]; then
  # Check if kcov is available
  if ! command -v kcov >/dev/null 2>&1; then
    echo -e "${YELLOW}⚠️  kcov not found, coverage reporting disabled${NC}"
    echo -e "${BLUE}ℹ️  Install kcov: sudo apt-get install kcov (Ubuntu) or brew install kcov (macOS)${NC}"
    COVERAGE=0
  fi
fi

if [[ ${COVERAGE} -eq 1 ]]; then
  echo -e "${BLUE}📊 Running tests with coverage...${NC}"
  
  # Run with kcov
  for test_file in "${TEST_FILES[@]}"; do
    test_name=$(basename "${test_file}" .bats)
    kcov --exclude-pattern=/usr,/tmp "${COVERAGE_DIR}/${test_name}" \
      bats "${BATS_OPTS[@]}" "${test_file}" || FAILED=1
  done
  
  echo ""
  echo -e "${GREEN}📊 Coverage report generated at: ${COVERAGE_DIR}/index.html${NC}"
else
  # Run without coverage
  if bats "${BATS_OPTS[@]}" "${TEST_FILES[@]}"; then
    echo ""
    echo -e "${GREEN}✅ All tests passed!${NC}"
  else
    FAILED=1
    echo ""
    echo -e "${RED}❌ Some tests failed${NC}"
  fi
fi

# Summary
echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}                     Test Summary                              ${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "Test files:        ${#TEST_FILES[@]}"
if [[ ${JUNIT} -eq 1 ]]; then
  echo -e "JUnit report:      ${RESULTS_DIR}/"
fi
if [[ ${COVERAGE} -eq 1 ]]; then
  echo -e "Coverage report:   ${COVERAGE_DIR}/index.html"
fi

if [[ ${FAILED} -eq 1 ]]; then
  echo ""
  echo -e "${RED}❌ Tests failed${NC}"
  exit 1
else
  echo ""
  echo -e "${GREEN}✅ All tests passed!${NC}"
  exit 0
fi
