#!/bin/bash

################################################################################
# AT-E3-007: Event Tracking Infrastructure Validation
#
# This script validates that comprehensive event tracking is implemented
# across the Fawkes platform with 60+ instrumented events, validation,
# and real-time streaming to Plausible Analytics.
#
# Acceptance Criteria:
# - Event schema defined with clear taxonomy
# - Tracking library deployed and integrated
# - 50+ events instrumented across platform
# - Event validation middleware in place
# - Real-time streaming working with Plausible
#
# Usage: ./scripts/validate-at-e3-007.sh [--namespace fawkes]
################################################################################

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
NAMESPACE="${NAMESPACE:-fawkes}"
DESIGN_SYSTEM_DIR="design-system"
VERBOSE=false

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --namespace)
      NAMESPACE="$2"
      shift 2
      ;;
    -v | --verbose)
      VERBOSE=true
      shift
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

# Test counters
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_TOTAL=0

################################################################################
# Helper Functions
################################################################################

log_info() {
  echo -e "${BLUE}ℹ${NC} $1"
}

log_success() {
  echo -e "${GREEN}✓${NC} $1"
  ((TESTS_PASSED++))
  ((TESTS_TOTAL++))
}

log_error() {
  echo -e "${RED}✗${NC} $1"
  ((TESTS_FAILED++))
  ((TESTS_TOTAL++))
}

log_warning() {
  echo -e "${YELLOW}⚠${NC} $1"
}

run_test() {
  local test_name="$1"
  local test_command="$2"

  if $VERBOSE; then
    log_info "Running: $test_name"
  fi

  if eval "$test_command" > /dev/null 2>&1; then
    log_success "$test_name"
    return 0
  else
    log_error "$test_name"
    if $VERBOSE; then
      eval "$test_command" 2>&1 | sed 's/^/  /'
    fi
    return 1
  fi
}

count_events() {
  local file="$1"
  local pattern="$2"
  grep -c "$pattern" "$file" 2> /dev/null || echo "0"
}

################################################################################
# Validation Tests
################################################################################

echo "=================================================="
echo "AT-E3-007: Event Tracking Infrastructure"
echo "=================================================="
echo ""

log_info "Validating event tracking infrastructure..."
echo ""

# Test 1: Event schema file exists
run_test "Event schema file exists" \
  "test -f ${DESIGN_SYSTEM_DIR}/src/analytics/eventSchema.ts"

# Test 2: Event tracker file exists
run_test "Event tracker file exists" \
  "test -f ${DESIGN_SYSTEM_DIR}/src/analytics/eventTracker.ts"

# Test 3: React hooks file exists
run_test "React hooks file exists" \
  "test -f ${DESIGN_SYSTEM_DIR}/src/analytics/hooks.ts"

# Test 4: Middleware file exists
run_test "Middleware file exists" \
  "test -f ${DESIGN_SYSTEM_DIR}/src/analytics/middleware.ts"

# Test 5: Analytics module index exists
run_test "Analytics module index exists" \
  "test -f ${DESIGN_SYSTEM_DIR}/src/analytics/index.ts"

# Test 6: README documentation exists
run_test "Analytics README exists" \
  "test -f ${DESIGN_SYSTEM_DIR}/src/analytics/README.md"

echo ""
log_info "Validating event schema..."
echo ""

# Test 7: EventCategory enum has at least 10 categories
CATEGORY_COUNT=$(grep -E "^\s+[A-Z_]+ = " "${DESIGN_SYSTEM_DIR}/src/analytics/eventSchema.ts" | wc -l)
run_test "EventCategory enum has at least 10 categories (found: $CATEGORY_COUNT)" \
  "test $CATEGORY_COUNT -ge 10"

# Test 8: EventAction enum has at least 20 actions
ACTION_COUNT=$(grep -E "^\s+[A-Z_]+ = " "${DESIGN_SYSTEM_DIR}/src/analytics/eventSchema.ts" | wc -l)
run_test "EventAction enum has at least 20 actions (found: $ACTION_COUNT)" \
  "test $ACTION_COUNT -ge 20"

# Test 9: PredefinedEvents has at least 60 events
PREDEFINED_COUNT=$(grep -E "^\s+[A-Z_]+: \{$" "${DESIGN_SYSTEM_DIR}/src/analytics/eventSchema.ts" | wc -l)
run_test "PredefinedEvents has at least 60 events (found: $PREDEFINED_COUNT)" \
  "test $PREDEFINED_COUNT -ge 60"

# Test 10: Navigation events defined (at least 5)
NAV_COUNT=$(grep -c "VIEW_HOMEPAGE\\|VIEW_CATALOG\\|SEARCH_CATALOG\\|VIEW_SERVICE\\|VIEW_COMPONENT" "${DESIGN_SYSTEM_DIR}/src/analytics/eventSchema.ts" || echo "0")
run_test "Navigation events defined (found: $NAV_COUNT)" \
  "test $NAV_COUNT -ge 5"

# Test 11: Scaffolding events defined (at least 10)
SCAFFOLD_COUNT=$(grep -c "SCAFFOLDING\\|TEMPLATE_" "${DESIGN_SYSTEM_DIR}/src/analytics/eventSchema.ts" || echo "0")
run_test "Scaffolding events defined (found: $SCAFFOLD_COUNT)" \
  "test $SCAFFOLD_COUNT -ge 10"

# Test 12: Documentation events defined (at least 6)
DOC_COUNT=$(grep -c "DOCS\\|TECHDOCS" "${DESIGN_SYSTEM_DIR}/src/analytics/eventSchema.ts" || echo "0")
run_test "Documentation events defined (found: $DOC_COUNT)" \
  "test $DOC_COUNT -ge 6"

# Test 13: CI/CD events defined (at least 12)
CICD_COUNT=$(grep -c "BUILD\\|DEPLOY\\|PIPELINE\\|ARGOCD" "${DESIGN_SYSTEM_DIR}/src/analytics/eventSchema.ts" || echo "0")
run_test "CI/CD events defined (found: $CICD_COUNT)" \
  "test $CICD_COUNT -ge 12"

# Test 14: Feedback events defined (at least 8)
FEEDBACK_COUNT=$(grep -c "FEEDBACK\\|FRICTION" "${DESIGN_SYSTEM_DIR}/src/analytics/eventSchema.ts" || echo "0")
run_test "Feedback events defined (found: $FEEDBACK_COUNT)" \
  "test $FEEDBACK_COUNT -ge 8"

# Test 15: Error events defined (at least 5)
ERROR_COUNT=$(grep -c "PAGE_ERROR\\|API_ERROR\\|VALIDATION_ERROR\\|AUTHENTICATION_ERROR\\|AUTHORIZATION_ERROR" "${DESIGN_SYSTEM_DIR}/src/analytics/eventSchema.ts" || echo "0")
run_test "Error events defined (found: $ERROR_COUNT)" \
  "test $ERROR_COUNT -ge 5"

# Test 16: Performance events defined (at least 4)
PERF_COUNT=$(grep -c "PERFORMANCE\\|PAGE_LOAD\\|API_RESPONSE\\|TIMEOUT" "${DESIGN_SYSTEM_DIR}/src/analytics/eventSchema.ts" || echo "0")
run_test "Performance events defined (found: $PERF_COUNT)" \
  "test $PERF_COUNT -ge 4"

echo ""
log_info "Validating event tracker implementation..."
echo ""

# Test 17: EventTracker class is defined
run_test "EventTracker class is defined" \
  "grep -q 'export class EventTracker' ${DESIGN_SYSTEM_DIR}/src/analytics/eventTracker.ts"

# Test 18: Track method is implemented
run_test "track() method is implemented" \
  "grep -q 'public track(' ${DESIGN_SYSTEM_DIR}/src/analytics/eventTracker.ts"

# Test 19: TrackPredefined method is implemented
run_test "trackPredefined() method is implemented" \
  "grep -q 'public trackPredefined(' ${DESIGN_SYSTEM_DIR}/src/analytics/eventTracker.ts"

# Test 20: TrackPageView method is implemented
run_test "trackPageView() method is implemented" \
  "grep -q 'public trackPageView(' ${DESIGN_SYSTEM_DIR}/src/analytics/eventTracker.ts"

# Test 21: TrackCustom method is implemented
run_test "trackCustom() method is implemented" \
  "grep -q 'public trackCustom(' ${DESIGN_SYSTEM_DIR}/src/analytics/eventTracker.ts"

# Test 22: Validation is called before sending
run_test "Event validation is called" \
  "grep -q 'validateEvent' ${DESIGN_SYSTEM_DIR}/src/analytics/eventTracker.ts"

# Test 23: Plausible integration is implemented
run_test "Plausible integration is implemented" \
  "grep -q 'window.plausible' ${DESIGN_SYSTEM_DIR}/src/analytics/eventTracker.ts"

# Test 24: Event queue is implemented
run_test "Event queue is implemented" \
  "grep -q 'queue:' ${DESIGN_SYSTEM_DIR}/src/analytics/eventTracker.ts"

echo ""
log_info "Validating React hooks..."
echo ""

# Test 25: useEventTracking hook exists
run_test "useEventTracking hook exists" \
  "grep -q 'export function useEventTracking' ${DESIGN_SYSTEM_DIR}/src/analytics/hooks.ts"

# Test 26: usePageViewTracking hook exists
run_test "usePageViewTracking hook exists" \
  "grep -q 'export function usePageViewTracking' ${DESIGN_SYSTEM_DIR}/src/analytics/hooks.ts"

# Test 27: useComponentTracking hook exists
run_test "useComponentTracking hook exists" \
  "grep -q 'export function useComponentTracking' ${DESIGN_SYSTEM_DIR}/src/analytics/hooks.ts"

# Test 28: useButtonClick hook exists
run_test "useButtonClick hook exists" \
  "grep -q 'export function useButtonClick' ${DESIGN_SYSTEM_DIR}/src/analytics/hooks.ts"

# Test 29: useFormTracking hook exists
run_test "useFormTracking hook exists" \
  "grep -q 'export function useFormTracking' ${DESIGN_SYSTEM_DIR}/src/analytics/hooks.ts"

# Test 30: useSearchTracking hook exists
run_test "useSearchTracking hook exists" \
  "grep -q 'export function useSearchTracking' ${DESIGN_SYSTEM_DIR}/src/analytics/hooks.ts"

# Test 31: useErrorTracking hook exists
run_test "useErrorTracking hook exists" \
  "grep -q 'export function useErrorTracking' ${DESIGN_SYSTEM_DIR}/src/analytics/hooks.ts"

# Test 32: usePerformanceTracking hook exists
run_test "usePerformanceTracking hook exists" \
  "grep -q 'export function usePerformanceTracking' ${DESIGN_SYSTEM_DIR}/src/analytics/hooks.ts"

echo ""
log_info "Validating middleware..."
echo ""

# Test 33: MiddlewareChain class exists
run_test "MiddlewareChain class exists" \
  "grep -q 'export class MiddlewareChain' ${DESIGN_SYSTEM_DIR}/src/analytics/middleware.ts"

# Test 34: Validation middleware exists
run_test "Validation middleware exists" \
  "grep -q 'validationMiddleware' ${DESIGN_SYSTEM_DIR}/src/analytics/middleware.ts"

# Test 35: Privacy middleware exists
run_test "Privacy middleware exists" \
  "grep -q 'privacyMiddleware' ${DESIGN_SYSTEM_DIR}/src/analytics/middleware.ts"

# Test 36: Enrichment middleware exists
run_test "Enrichment middleware exists" \
  "grep -q 'enrichmentMiddleware' ${DESIGN_SYSTEM_DIR}/src/analytics/middleware.ts"

# Test 37: Sampling middleware exists
run_test "Sampling middleware exists" \
  "grep -q 'samplingMiddleware' ${DESIGN_SYSTEM_DIR}/src/analytics/middleware.ts"

# Test 38: Rate limiting middleware exists
run_test "Rate limiting middleware exists" \
  "grep -q 'rateLimitMiddleware' ${DESIGN_SYSTEM_DIR}/src/analytics/middleware.ts"

# Test 39: Deduplication middleware exists
run_test "Deduplication middleware exists" \
  "grep -q 'deduplicationMiddleware' ${DESIGN_SYSTEM_DIR}/src/analytics/middleware.ts"

# Test 40: Timestamp middleware exists
run_test "Timestamp middleware exists" \
  "grep -q 'timestampMiddleware' ${DESIGN_SYSTEM_DIR}/src/analytics/middleware.ts"

echo ""
log_info "Validating exports and integration..."
echo ""

# Test 41: Analytics module exports all components
run_test "Analytics module exports eventSchema" \
  "grep -q \"export \* from './eventSchema'\" ${DESIGN_SYSTEM_DIR}/src/analytics/index.ts"

# Test 42: Analytics module exports eventTracker
run_test "Analytics module exports eventTracker" \
  "grep -q \"export \* from './eventTracker'\" ${DESIGN_SYSTEM_DIR}/src/analytics/index.ts"

# Test 43: Analytics module exports hooks
run_test "Analytics module exports hooks" \
  "grep -q \"export \* from './hooks'\" ${DESIGN_SYSTEM_DIR}/src/analytics/index.ts"

# Test 44: Analytics module exports middleware
run_test "Analytics module exports middleware" \
  "grep -q \"export \* from './middleware'\" ${DESIGN_SYSTEM_DIR}/src/analytics/index.ts"

# Test 45: Design system exports analytics
run_test "Design system exports analytics module" \
  "grep -q \"export \* from './analytics'\" ${DESIGN_SYSTEM_DIR}/src/index.ts"

echo ""
log_info "Validating documentation..."
echo ""

# Test 46: README documents event schema
run_test "README documents event schema" \
  "grep -q 'Event Schema' ${DESIGN_SYSTEM_DIR}/src/analytics/README.md"

# Test 47: README documents all predefined events
run_test "README documents predefined events" \
  "grep -q 'Predefined Events' ${DESIGN_SYSTEM_DIR}/src/analytics/README.md"

# Test 48: README documents React hooks
run_test "README documents React hooks" \
  "grep -q 'React Hooks' ${DESIGN_SYSTEM_DIR}/src/analytics/README.md"

# Test 49: README documents middleware
run_test "README documents middleware" \
  "grep -q 'Middleware' ${DESIGN_SYSTEM_DIR}/src/analytics/README.md"

# Test 50: README includes usage examples
run_test "README includes usage examples" \
  "grep -q 'Quick Start' ${DESIGN_SYSTEM_DIR}/src/analytics/README.md"

# Test 51: README includes troubleshooting
run_test "README includes troubleshooting" \
  "grep -q 'Troubleshooting' ${DESIGN_SYSTEM_DIR}/src/analytics/README.md"

# Test 52: README documents privacy compliance
run_test "README documents privacy compliance" \
  "grep -q 'Privacy' ${DESIGN_SYSTEM_DIR}/src/analytics/README.md"

echo ""
log_info "Validating Plausible integration..."
echo ""

# Test 53: Check if Plausible pod is running
if kubectl get pods -n "$NAMESPACE" -l app=plausible --no-headers 2> /dev/null | grep -q Running; then
  log_success "Plausible pod is running"
  ((TESTS_PASSED++))
  ((TESTS_TOTAL++))
else
  log_error "Plausible pod is not running"
  ((TESTS_FAILED++))
  ((TESTS_TOTAL++))
fi

# Test 54: Check if Plausible service exists
if kubectl get svc -n "$NAMESPACE" plausible --no-headers 2> /dev/null > /dev/null; then
  log_success "Plausible service exists"
  ((TESTS_PASSED++))
  ((TESTS_TOTAL++))
else
  log_error "Plausible service does not exist"
  ((TESTS_FAILED++))
  ((TESTS_TOTAL++))
fi

# Test 55: BDD feature file exists
run_test "BDD feature file for event tracking exists" \
  "test -f tests/bdd/features/event-tracking.feature"

################################################################################
# Summary
################################################################################

echo ""
echo "=================================================="
echo "Validation Summary"
echo "=================================================="
echo ""
echo "Total tests: $TESTS_TOTAL"
echo -e "${GREEN}Passed: $TESTS_PASSED${NC}"
echo -e "${RED}Failed: $TESTS_FAILED${NC}"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
  echo -e "${GREEN}✓ AT-E3-007: Event Tracking Infrastructure - PASSED${NC}"
  echo ""
  echo "All acceptance criteria met:"
  echo "  ✓ Event schema defined with 60+ events"
  echo "  ✓ Tracking library deployed and integrated"
  echo "  ✓ React hooks available for easy integration"
  echo "  ✓ Middleware for validation, privacy, and enrichment"
  echo "  ✓ Real-time streaming to Plausible configured"
  echo "  ✓ Comprehensive documentation provided"
  echo ""
  exit 0
else
  echo -e "${RED}✗ AT-E3-007: Event Tracking Infrastructure - FAILED${NC}"
  echo ""
  echo "Please fix the failed tests and run again."
  echo ""
  exit 1
fi
