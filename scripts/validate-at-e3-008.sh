#!/bin/bash

set -euo pipefail
# Don't use set -e to prevent early exit on failures
# We want to collect all validation results

# validate-at-e3-008.sh
# Validation script for AT-E3-008: Continuous Discovery Process
#
# This script validates that continuous discovery workflow is properly
# established including documentation, processes, metrics, and advisory board.

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters
CHECKS_PASSED=0
CHECKS_FAILED=0
CHECKS_WARNING=0

# Helper functions
print_header() {
  echo -e "\n${BLUE}===================================================${NC}"
  echo -e "${BLUE}$1${NC}"
  echo -e "${BLUE}===================================================${NC}\n"
}

print_check() {
  echo -e "${YELLOW}⏳ Checking: $1${NC}"
}

print_pass() {
  echo -e "${GREEN}✅ PASS: $1${NC}"
  ((CHECKS_PASSED++))
}

print_fail() {
  echo -e "${RED}❌ FAIL: $1${NC}"
  ((CHECKS_FAILED++))
}

print_warning() {
  echo -e "${YELLOW}⚠️  WARNING: $1${NC}"
  ((CHECKS_WARNING++))
}

# Parse command line arguments
NAMESPACE="${NAMESPACE:-fawkes}"

while [[ $# -gt 0 ]]; do
  case $1 in
    --namespace)
      NAMESPACE="$2"
      shift 2
      ;;
    --help)
      echo "Usage: $0 [OPTIONS]"
      echo ""
      echo "Validates AT-E3-008: Continuous Discovery Process"
      echo ""
      echo "Options:"
      echo "  --namespace NAMESPACE    Kubernetes namespace (default: fawkes)"
      echo "  --help                   Show this help message"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

print_header "AT-E3-008: Continuous Discovery Process Validation"
echo "Namespace: $NAMESPACE"
echo "Date: $(date)"
echo ""

# ============================================================================
# AC1: Discovery Workflow Operational
# ============================================================================
print_header "1. Discovery Workflow Documentation"

print_check "Continuous discovery workflow playbook exists"
if [ -f "docs/playbooks/continuous-discovery-workflow.md" ]; then
  print_pass "Continuous discovery workflow playbook found"
else
  print_fail "Continuous discovery workflow playbook not found"
fi

print_check "Discovery workflow playbook is comprehensive"
if [ -f "docs/playbooks/continuous-discovery-workflow.md" ]; then
  word_count=$(wc -w < "docs/playbooks/continuous-discovery-workflow.md")
  if [ "$word_count" -gt 2000 ]; then
    print_pass "Playbook is comprehensive (${word_count} words)"
  else
    print_fail "Playbook is too brief (${word_count} words, expected >2000)"
  fi
else
  print_fail "Cannot check playbook comprehensiveness - file not found"
fi

print_check "Discovery workflow includes key sections"
if [ -f "docs/playbooks/continuous-discovery-workflow.md" ]; then
  required_sections=(
    "Business Objective"
    "Technical Prerequisites"
    "Discovery Cadence"
    "User Interviews"
    "Feedback Collection"
    "Advisory Board"
    "Metrics"
  )

  missing_sections=()
  for section in "${required_sections[@]}"; do
    if ! grep -qi "$section" "docs/playbooks/continuous-discovery-workflow.md"; then
      missing_sections+=("$section")
    fi
  done

  if [ ${#missing_sections[@]} -eq 0 ]; then
    print_pass "All required sections present in playbook"
  else
    print_fail "Missing sections in playbook: ${missing_sections[*]}"
  fi
else
  print_fail "Cannot check sections - file not found"
fi

print_check "Discovery metrics dashboard documentation exists"
if [ -f "docs/how-to/epic-3-user-guide.md" ] && grep -q "discovery metrics\|SPACE metrics" "docs/how-to/epic-3-user-guide.md"; then
  print_pass "Discovery metrics documentation found"
else
  print_fail "Discovery metrics documentation not found"
fi

# ============================================================================
# AC2: Usability Testing Functional
# ============================================================================
print_header "2. Usability Testing Integration"

print_check "Usability testing guide exists"
if [ -f "docs/how-to/usability-testing-guide.md" ]; then
  print_pass "Usability testing guide found"
else
  print_fail "Usability testing guide not found"
fi

print_check "Usability testing templates exist"
if [ -d "docs/research/templates" ]; then
  template_count=$(find docs/research/templates -name "*.md" -type f 2> /dev/null | wc -l)
  if [ "$template_count" -gt 0 ]; then
    print_pass "Usability testing templates found (${template_count} templates)"
  else
    print_fail "No usability testing templates found"
  fi
else
  print_fail "Usability testing templates directory not found"
fi

# ============================================================================
# AC3: Advisory Board Active
# ============================================================================
print_header "3. Advisory Board Setup"

print_check "Advisory board documentation exists"
if [ -f "docs/how-to/run-advisory-board-meetings.md" ]; then
  print_pass "Advisory board meeting guide found"
else
  print_fail "Advisory board meeting guide not found"
fi

print_check "Advisory board guide is comprehensive"
if [ -f "docs/how-to/run-advisory-board-meetings.md" ]; then
  word_count=$(wc -w < "docs/how-to/run-advisory-board-meetings.md")
  if [ "$word_count" -gt 1000 ]; then
    print_pass "Advisory board guide is comprehensive (${word_count} words)"
  else
    print_warning "Advisory board guide is brief (${word_count} words)"
  fi
else
  print_fail "Cannot check advisory board guide - file not found"
fi

print_check "Advisory board includes meeting structure"
if [ -f "docs/how-to/run-advisory-board-meetings.md" ]; then
  required_topics=(
    "Meeting"
    "Agenda"
    "Participants"
    "Frequency"
  )

  missing_topics=()
  for topic in "${required_topics[@]}"; do
    if ! grep -qi "$topic" "docs/how-to/run-advisory-board-meetings.md"; then
      missing_topics+=("$topic")
    fi
  done

  if [ ${#missing_topics[@]} -eq 0 ]; then
    print_pass "Advisory board guide has proper structure"
  else
    print_warning "Advisory board guide missing topics: ${missing_topics[*]}"
  fi
else
  print_fail "Cannot check advisory board structure - file not found"
fi

# ============================================================================
# AC4: All Documentation Complete
# ============================================================================
print_header "4. Epic 3 Documentation Completeness"

print_check "Epic 3 documentation index exists"
if [ -f "docs/EPIC-3-DOCUMENTATION-INDEX.md" ]; then
  print_pass "Epic 3 documentation index found"
else
  print_fail "Epic 3 documentation index not found"
fi

print_check "Epic 3 user guide exists"
if [ -f "docs/how-to/epic-3-user-guide.md" ]; then
  print_pass "Epic 3 user guide found"
else
  print_fail "Epic 3 user guide not found"
fi

print_check "Epic 3 operations runbook exists"
if [ -f "docs/runbooks/epic-3-product-discovery-operations.md" ]; then
  print_pass "Epic 3 operations runbook found"
else
  print_fail "Epic 3 operations runbook not found"
fi

print_check "Epic 3 API reference exists"
if [ -f "docs/reference/api/epic-3-product-discovery-apis.md" ]; then
  print_pass "Epic 3 API reference found"
else
  print_fail "Epic 3 API reference not found"
fi

print_check "Epic 3 architecture diagrams exist"
if [ -f "docs/runbooks/epic-3-architecture-diagrams.md" ]; then
  print_pass "Epic 3 architecture diagrams found"
else
  print_fail "Epic 3 architecture diagrams not found"
fi

print_check "Epic 3 demo video resources exist"
if [ -f "docs/tutorials/epic-3-demo-video-script.md" ]; then
  print_pass "Epic 3 demo video resources found"
else
  print_fail "Epic 3 demo video resources not found"
fi

# ============================================================================
# AC5: Platform Ready for Users
# ============================================================================
print_header "5. Platform User Readiness"

print_check "Feedback service is deployed"
if kubectl get deployment feedback-service -n "$NAMESPACE" > /dev/null 2>&1; then
  replicas_ready=$(kubectl get deployment feedback-service -n "$NAMESPACE" -o jsonpath='{.status.readyReplicas}')
  replicas_desired=$(kubectl get deployment feedback-service -n "$NAMESPACE" -o jsonpath='{.spec.replicas}')
  if [ "$replicas_ready" -eq "$replicas_desired" ]; then
    print_pass "Feedback service is deployed and ready ($replicas_ready/$replicas_desired replicas)"
  else
    print_fail "Feedback service replicas not ready ($replicas_ready/$replicas_desired)"
  fi
else
  print_fail "Feedback service deployment not found"
fi

print_check "SPACE metrics service is deployed"
if kubectl get deployment space-metrics -n "$NAMESPACE" > /dev/null 2>&1; then
  replicas_ready=$(kubectl get deployment space-metrics -n "$NAMESPACE" -o jsonpath='{.status.readyReplicas}')
  replicas_desired=$(kubectl get deployment space-metrics -n "$NAMESPACE" -o jsonpath='{.spec.replicas}')
  if [ "$replicas_ready" -eq "$replicas_desired" ]; then
    print_pass "SPACE metrics service is deployed and ready ($replicas_ready/$replicas_desired replicas)"
  else
    print_fail "SPACE metrics service replicas not ready ($replicas_ready/$replicas_desired)"
  fi
else
  print_fail "SPACE metrics service deployment not found"
fi

print_check "Analytics platform is accessible"
if kubectl get deployment -n "$NAMESPACE" -l app.kubernetes.io/name=plausible > /dev/null 2>&1 \
  || kubectl get deployment -n "$NAMESPACE" -l app=posthog > /dev/null 2>&1 \
  || kubectl get deployment -n "$NAMESPACE" -l app=analytics-dashboard > /dev/null 2>&1; then
  print_pass "Analytics platform is deployed"
else
  print_warning "Analytics platform deployment not found (may be external)"
fi

print_check "Feature flags platform is deployed"
if kubectl get deployment unleash -n "$NAMESPACE" > /dev/null 2>&1; then
  replicas_ready=$(kubectl get deployment unleash -n "$NAMESPACE" -o jsonpath='{.status.readyReplicas}')
  replicas_desired=$(kubectl get deployment unleash -n "$NAMESPACE" -o jsonpath='{.spec.replicas}')
  if [ "$replicas_ready" -eq "$replicas_desired" ]; then
    print_pass "Feature flags platform (Unleash) is deployed and ready ($replicas_ready/$replicas_desired replicas)"
  else
    print_fail "Feature flags platform replicas not ready ($replicas_ready/$replicas_desired)"
  fi
else
  print_fail "Feature flags platform (Unleash) deployment not found"
fi

# ============================================================================
# AC6: All Epic Acceptance Tests Passing
# ============================================================================
print_header "6. Epic 3 Acceptance Tests Status"

print_check "AT-E3-001 validation script exists"
if [ -f "scripts/validate-at-e3-001.sh" ]; then
  print_pass "AT-E3-001 validation script found"
else
  print_warning "AT-E3-001 validation script not found"
fi

print_check "AT-E3-002 validation script exists"
if [ -f "scripts/validate-at-e3-002.sh" ]; then
  print_pass "AT-E3-002 validation script found"
else
  print_warning "AT-E3-002 validation script not found"
fi

print_check "AT-E3-003 validation script exists"
if [ -f "scripts/validate-at-e3-003.sh" ]; then
  print_pass "AT-E3-003 validation script found"
else
  print_warning "AT-E3-003 validation script not found"
fi

print_check "AT-E3-006 validation script exists"
if [ -f "scripts/validate-at-e3-006.sh" ]; then
  print_pass "AT-E3-006 validation script found"
else
  print_warning "AT-E3-006 validation script not found"
fi

print_check "AT-E3-007 validation script exists"
if [ -f "scripts/validate-at-e3-007.sh" ]; then
  print_pass "AT-E3-007 validation script found"
else
  print_warning "AT-E3-007 validation script not found"
fi

print_check "AT-E3-010 validation script exists"
if [ -f "scripts/validate-at-e3-010.sh" ]; then
  print_pass "AT-E3-010 validation script found"
else
  print_warning "AT-E3-010 validation script not found"
fi

# ============================================================================
# Summary
# ============================================================================
print_header "Validation Summary"

echo "Total Checks: $((CHECKS_PASSED + CHECKS_FAILED + CHECKS_WARNING))"
echo -e "✅ Passed:   ${GREEN}$CHECKS_PASSED${NC}"
echo -e "❌ Failed:   ${RED}$CHECKS_FAILED${NC}"
echo -e "⚠️  Warnings: ${YELLOW}$CHECKS_WARNING${NC}"
echo ""

if [ $CHECKS_FAILED -eq 0 ]; then
  echo -e "${GREEN}🎉 AT-E3-008 validation passed!${NC}"
  echo ""
  echo "Continuous Discovery Process is operational:"
  echo "  ✓ Discovery workflow documented and comprehensive"
  echo "  ✓ Usability testing infrastructure ready"
  echo "  ✓ Advisory board setup documented"
  echo "  ✓ All Epic 3 documentation complete"
  echo "  ✓ Platform components deployed and ready"
  echo "  ✓ Acceptance tests framework established"
  exit 0
else
  echo -e "${RED}❌ AT-E3-008 validation failed${NC}"
  echo ""
  echo "Please address the failed checks above."
  exit 1
fi
