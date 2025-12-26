#!/bin/bash
# Don't use set -e to prevent early exit on failures
# We want to collect all validation results

# validate-epic-3-final.sh
# Comprehensive validation script for Final Epic 3 Validation (Issue #108)
#
# This script runs all four final Epic 3 acceptance tests:
# - AT-E3-008: Continuous Discovery Process
# - AT-E3-010: Usability Testing Infrastructure
# - AT-E3-011: Product Analytics Platform
# - AT-E3-012: Complete Epic 3 Documentation

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Counters
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_WARNING=0

# Test results
declare -A TEST_RESULTS

# Helper functions
print_banner() {
  echo -e "${MAGENTA}"
  echo "╔═══════════════════════════════════════════════════════════════════╗"
  echo "║                                                                   ║"
  echo "║        Epic 3 Final Validation - Issue #108                      ║"
  echo "║                                                                   ║"
  echo "║   AT-E3-008: Continuous Discovery Process                        ║"
  echo "║   AT-E3-010: Usability Testing Infrastructure                    ║"
  echo "║   AT-E3-011: Product Analytics Platform                          ║"
  echo "║   AT-E3-012: Complete Epic 3 Documentation                       ║"
  echo "║                                                                   ║"
  echo "╚═══════════════════════════════════════════════════════════════════╝"
  echo -e "${NC}"
}

print_header() {
  echo -e "\n${BLUE}═══════════════════════════════════════════════════════════════════${NC}"
  echo -e "${BLUE}$1${NC}"
  echo -e "${BLUE}═══════════════════════════════════════════════════════════════════${NC}\n"
}

print_test_header() {
  echo -e "\n${CYAN}╔═══════════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${CYAN}║ $1${NC}"
  echo -e "${CYAN}╚═══════════════════════════════════════════════════════════════════╝${NC}\n"
}

print_pass() {
  echo -e "${GREEN}✅ PASS: $1${NC}"
  ((TESTS_PASSED++))
}

print_fail() {
  echo -e "${RED}❌ FAIL: $1${NC}"
  ((TESTS_FAILED++))
}

print_warning() {
  echo -e "${YELLOW}⚠️  WARNING: $1${NC}"
  ((TESTS_WARNING++))
}

# Parse command line arguments
NAMESPACE="${NAMESPACE:-fawkes}"
VERBOSE="${VERBOSE:-false}"
GENERATE_REPORT="${GENERATE_REPORT:-true}"
REPORT_DIR="reports"

while [[ $# -gt 0 ]]; do
  case $1 in
    --namespace)
      NAMESPACE="$2"
      shift 2
      ;;
    --verbose)
      VERBOSE="true"
      shift
      ;;
    --no-report)
      GENERATE_REPORT="false"
      shift
      ;;
    --report-dir)
      REPORT_DIR="$2"
      shift 2
      ;;
    --help)
      echo "Usage: $0 [OPTIONS]"
      echo ""
      echo "Validates all Final Epic 3 Acceptance Tests (Issue #108)"
      echo ""
      echo "Options:"
      echo "  --namespace NAMESPACE    Kubernetes namespace (default: fawkes)"
      echo "  --verbose                Show detailed output from validation scripts"
      echo "  --no-report              Skip generating JSON report"
      echo "  --report-dir DIR         Report directory (default: reports)"
      echo "  --help                   Show this help message"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

# Create report directory if needed
mkdir -p "$REPORT_DIR"

START_TIME=$(date +%s)
TIMESTAMP=$(date +"%Y%m%d-%H%M%S")

print_banner
echo "Namespace: $NAMESPACE"
echo "Verbose: $VERBOSE"
echo "Generate Report: $GENERATE_REPORT"
echo "Report Directory: $REPORT_DIR"
echo "Date: $(date)"
echo ""

# ============================================================================
# Run AT-E3-008: Continuous Discovery Process
# ============================================================================
print_test_header "AT-E3-008: Continuous Discovery Process"

if [ -f "scripts/validate-at-e3-008.sh" ]; then
  if [ "$VERBOSE" = "true" ]; then
    ./scripts/validate-at-e3-008.sh --namespace "$NAMESPACE"
    AT_E3_008_EXIT=$?
  else
    OUTPUT=$(./scripts/validate-at-e3-008.sh --namespace "$NAMESPACE" 2>&1)
    AT_E3_008_EXIT=$?
    echo "$OUTPUT" | tail -20
  fi

  if [ $AT_E3_008_EXIT -eq 0 ]; then
    TEST_RESULTS["AT-E3-008"]="PASSED"
    print_pass "AT-E3-008 validation passed"
  else
    TEST_RESULTS["AT-E3-008"]="FAILED"
    print_fail "AT-E3-008 validation failed"
  fi
else
  TEST_RESULTS["AT-E3-008"]="MISSING"
  print_fail "AT-E3-008 validation script not found"
fi

# ============================================================================
# Run AT-E3-010: Usability Testing Infrastructure
# ============================================================================
print_test_header "AT-E3-010: Usability Testing Infrastructure"

if [ -f "scripts/validate-at-e3-010.sh" ]; then
  if [ "$VERBOSE" = "true" ]; then
    ./scripts/validate-at-e3-010.sh --namespace "$NAMESPACE"
    AT_E3_010_EXIT=$?
  else
    OUTPUT=$(./scripts/validate-at-e3-010.sh --namespace "$NAMESPACE" 2>&1)
    AT_E3_010_EXIT=$?
    echo "$OUTPUT" | tail -20
  fi

  if [ $AT_E3_010_EXIT -eq 0 ]; then
    TEST_RESULTS["AT-E3-010"]="PASSED"
    print_pass "AT-E3-010 validation passed"
  else
    TEST_RESULTS["AT-E3-010"]="FAILED"
    print_fail "AT-E3-010 validation failed"
  fi
else
  TEST_RESULTS["AT-E3-010"]="MISSING"
  print_fail "AT-E3-010 validation script not found"
fi

# ============================================================================
# Run AT-E3-011: Product Analytics Platform
# ============================================================================
print_test_header "AT-E3-011: Product Analytics Platform"

if [ -f "scripts/validate-product-analytics.sh" ]; then
  if [ "$VERBOSE" = "true" ]; then
    ./scripts/validate-product-analytics.sh --namespace "$NAMESPACE"
    AT_E3_011_EXIT=$?
  else
    OUTPUT=$(./scripts/validate-product-analytics.sh --namespace "$NAMESPACE" 2>&1)
    AT_E3_011_EXIT=$?
    echo "$OUTPUT" | tail -20
  fi

  if [ $AT_E3_011_EXIT -eq 0 ]; then
    TEST_RESULTS["AT-E3-011"]="PASSED"
    print_pass "AT-E3-011 validation passed"
  else
    TEST_RESULTS["AT-E3-011"]="FAILED"
    print_fail "AT-E3-011 validation failed"
  fi
else
  TEST_RESULTS["AT-E3-011"]="MISSING"
  print_fail "AT-E3-011 validation script not found"
fi

# ============================================================================
# Run AT-E3-012: Complete Epic 3 Documentation
# ============================================================================
print_test_header "AT-E3-012: Complete Epic 3 Documentation"

if [ -f "scripts/validate-at-e3-012.sh" ]; then
  if [ "$VERBOSE" = "true" ]; then
    ./scripts/validate-at-e3-012.sh --namespace "$NAMESPACE"
    AT_E3_012_EXIT=$?
  else
    OUTPUT=$(./scripts/validate-at-e3-012.sh --namespace "$NAMESPACE" 2>&1)
    AT_E3_012_EXIT=$?
    echo "$OUTPUT" | tail -20
  fi

  if [ $AT_E3_012_EXIT -eq 0 ]; then
    TEST_RESULTS["AT-E3-012"]="PASSED"
    print_pass "AT-E3-012 validation passed"
  else
    TEST_RESULTS["AT-E3-012"]="FAILED"
    print_fail "AT-E3-012 validation failed"
  fi
else
  TEST_RESULTS["AT-E3-012"]="MISSING"
  print_fail "AT-E3-012 validation script not found"
fi

# ============================================================================
# Summary and Report Generation
# ============================================================================
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

print_header "Final Validation Summary"

echo "Test Results:"
echo "-------------"
for test in AT-E3-008 AT-E3-010 AT-E3-011 AT-E3-012; do
  result="${TEST_RESULTS[$test]}"
  case $result in
    PASSED)
      echo -e "  ${GREEN}✅ $test: $result${NC}"
      ;;
    FAILED)
      echo -e "  ${RED}❌ $test: $result${NC}"
      ;;
    MISSING)
      echo -e "  ${YELLOW}⚠️  $test: $result${NC}"
      ;;
  esac
done

echo ""
echo "Execution Time: ${DURATION}s"
echo ""

# Count results
PASSED_COUNT=0
FAILED_COUNT=0
MISSING_COUNT=0

for result in "${TEST_RESULTS[@]}"; do
  case $result in
    PASSED) ((PASSED_COUNT++)) ;;
    FAILED) ((FAILED_COUNT++)) ;;
    MISSING) ((MISSING_COUNT++)) ;;
  esac
done

echo "Summary:"
echo -e "  ${GREEN}Passed:  $PASSED_COUNT/4${NC}"
echo -e "  ${RED}Failed:  $FAILED_COUNT/4${NC}"
echo -e "  ${YELLOW}Missing: $MISSING_COUNT/4${NC}"
echo ""

# Generate JSON report
if [ "$GENERATE_REPORT" = "true" ]; then
  REPORT_FILE="$REPORT_DIR/epic-3-final-validation-$TIMESTAMP.json"

  cat > "$REPORT_FILE" << EOF
{
  "test_suite": "Epic 3 Final Validation",
  "issue": "#108",
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "duration_seconds": $DURATION,
  "namespace": "$NAMESPACE",
  "results": {
    "AT-E3-008": {
      "name": "Continuous Discovery Process",
      "status": "${TEST_RESULTS["AT-E3-008"]}",
      "script": "scripts/validate-at-e3-008.sh"
    },
    "AT-E3-010": {
      "name": "Usability Testing Infrastructure",
      "status": "${TEST_RESULTS["AT-E3-010"]}",
      "script": "scripts/validate-at-e3-010.sh"
    },
    "AT-E3-011": {
      "name": "Product Analytics Platform",
      "status": "${TEST_RESULTS["AT-E3-011"]}",
      "script": "scripts/validate-product-analytics.sh"
    },
    "AT-E3-012": {
      "name": "Complete Epic 3 Documentation",
      "status": "${TEST_RESULTS["AT-E3-012"]}",
      "script": "scripts/validate-at-e3-012.sh"
    }
  },
  "summary": {
    "total": 4,
    "passed": $PASSED_COUNT,
    "failed": $FAILED_COUNT,
    "missing": $MISSING_COUNT,
    "pass_rate_percent": $((PASSED_COUNT * 100 / 4))
  }
}
EOF

  print_pass "Report generated: $REPORT_FILE"
fi

# Final status
echo ""
if [ $FAILED_COUNT -eq 0 ] && [ $MISSING_COUNT -eq 0 ]; then
  echo -e "${GREEN}╔═══════════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${GREEN}║                                                                   ║${NC}"
  echo -e "${GREEN}║  🎉 All Epic 3 Final Validations PASSED!                        ║${NC}"
  echo -e "${GREEN}║                                                                   ║${NC}"
  echo -e "${GREEN}║  ✓ Discovery workflow operational                                ║${NC}"
  echo -e "${GREEN}║  ✓ Usability testing functional                                  ║${NC}"
  echo -e "${GREEN}║  ✓ Product analytics deployed                                    ║${NC}"
  echo -e "${GREEN}║  ✓ All documentation complete                                    ║${NC}"
  echo -e "${GREEN}║  ✓ Platform ready for users                                      ║${NC}"
  echo -e "${GREEN}║                                                                   ║${NC}"
  echo -e "${GREEN}╚═══════════════════════════════════════════════════════════════════╝${NC}"
  echo ""
  exit 0
elif [ $PASSED_COUNT -ge 3 ]; then
  echo -e "${YELLOW}╔═══════════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${YELLOW}║                                                                   ║${NC}"
  echo -e "${YELLOW}║  ⚠️  Most Epic 3 Validations PASSED ($PASSED_COUNT/4)                         ║${NC}"
  echo -e "${YELLOW}║                                                                   ║${NC}"
  echo -e "${YELLOW}║  Please address the failed validation(s) above.                  ║${NC}"
  echo -e "${YELLOW}║                                                                   ║${NC}"
  echo -e "${YELLOW}╚═══════════════════════════════════════════════════════════════════╝${NC}"
  echo ""
  exit 1
else
  echo -e "${RED}╔═══════════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${RED}║                                                                   ║${NC}"
  echo -e "${RED}║  ❌ Epic 3 Final Validation FAILED                               ║${NC}"
  echo -e "${RED}║                                                                   ║${NC}"
  echo -e "${RED}║  Please address the failed validations above.                    ║${NC}"
  echo -e "${RED}║                                                                   ║${NC}"
  echo -e "${RED}╚═══════════════════════════════════════════════════════════════════╝${NC}"
  echo ""
  exit 1
fi
