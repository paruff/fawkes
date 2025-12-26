#!/bin/bash

# validate-at-e3-010.sh
# Validation script for AT-E3-010: Usability Testing Infrastructure
#
# This script validates that usability testing infrastructure is properly
# set up including documentation, templates, recording tools, and processes.
#
# Note: Uses set -uo pipefail only (without -e) to collect all validation results
set -uo pipefail

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
      echo "Validates AT-E3-010: Usability Testing Infrastructure"
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

print_header "AT-E3-010: Usability Testing Infrastructure Validation"
echo "Namespace: $NAMESPACE"
echo "Date: $(date)"
echo ""

# ============================================================================
# Documentation Structure
# ============================================================================
print_header "1. Documentation Structure"

print_check "Usability testing guide exists"
if [ -f "docs/how-to/usability-testing-guide.md" ]; then
  print_pass "Usability testing guide found"
else
  print_fail "Usability testing guide not found"
fi

print_check "Session recording setup guide exists"
if [ -f "docs/how-to/session-recording-setup.md" ]; then
  print_pass "Session recording setup guide found"
else
  print_fail "Session recording setup guide not found"
fi

print_check "Usability testing guide content is comprehensive"
if [ -f "docs/how-to/usability-testing-guide.md" ]; then
  content_checks=0
  if grep -q "Planning Usability Tests" "docs/how-to/usability-testing-guide.md"; then
    ((content_checks++))
  fi
  if grep -q "Conducting Tests" "docs/how-to/usability-testing-guide.md"; then
    ((content_checks++))
  fi
  if grep -q "Recording and Analysis" "docs/how-to/usability-testing-guide.md"; then
    ((content_checks++))
  fi
  if grep -q "Best Practices" "docs/how-to/usability-testing-guide.md"; then
    ((content_checks++))
  fi

  if [ $content_checks -eq 4 ]; then
    print_pass "Guide covers all key sections"
  else
    print_fail "Guide is missing key sections ($content_checks/4 found)"
  fi
else
  print_fail "Cannot check guide content - file not found"
fi

# ============================================================================
# Templates
# ============================================================================
print_header "2. Test Script and Templates"

print_check "Usability test script template exists"
if [ -f "docs/research/templates/usability-test-script.md" ]; then
  print_pass "Test script template found"
else
  print_fail "Test script template not found"
fi

print_check "Observation checklist template exists"
if [ -f "docs/research/templates/usability-observation-checklist.md" ]; then
  print_pass "Observation checklist found"
else
  print_fail "Observation checklist not found"
fi

print_check "Analysis template exists"
if [ -f "docs/research/templates/usability-analysis-template.md" ]; then
  print_pass "Analysis template found"
else
  print_fail "Analysis template not found"
fi

print_check "Participant screener template exists"
if [ -f "docs/research/templates/participant-screener.md" ]; then
  print_pass "Participant screener found"
else
  print_fail "Participant screener not found"
fi

print_check "Test script template includes required sections"
if [ -f "docs/research/templates/usability-test-script.md" ]; then
  sections=0
  if grep -q "Opening" "docs/research/templates/usability-test-script.md"; then
    ((sections++))
  fi
  if grep -q "Task" "docs/research/templates/usability-test-script.md"; then
    ((sections++))
  fi
  if grep -q "Post-Task Questions" "docs/research/templates/usability-test-script.md"; then
    ((sections++))
  fi
  if grep -q "Closing" "docs/research/templates/usability-test-script.md"; then
    ((sections++))
  fi

  if [ $sections -eq 4 ]; then
    print_pass "Test script includes all required sections"
  else
    print_fail "Test script missing sections ($sections/4 found)"
  fi
else
  print_fail "Cannot check template sections - file not found"
fi

# ============================================================================
# Recording Tools
# ============================================================================
print_header "3. Session Recording Infrastructure"

print_check "OpenReplay deployment configuration exists"
if [ -f "platform/apps/openreplay/openreplay-application.yaml" ]; then
  print_pass "OpenReplay ArgoCD application found"
else
  print_fail "OpenReplay ArgoCD application not found"
fi

print_check "OpenReplay documentation exists"
if [ -f "platform/apps/openreplay/README.md" ]; then
  print_pass "OpenReplay README found"
else
  print_fail "OpenReplay README not found"
fi

print_check "OpenReplay namespace exists (optional)"
if timeout 5 kubectl get namespace openreplay &> /dev/null 2>&1; then
  print_pass "OpenReplay namespace exists"

  print_check "OpenReplay pods are running"
  if timeout 5 kubectl get pods -n openreplay --field-selector=status.phase=Running 2> /dev/null | grep -q "openreplay"; then
    print_pass "OpenReplay pods are running"
  else
    print_warning "OpenReplay pods not running (deployment optional for validation)"
  fi
else
  print_warning "OpenReplay namespace not found (deployment optional)"
fi

# ============================================================================
# Analysis Framework
# ============================================================================
print_header "4. Analysis Framework"

print_check "Analysis template has metrics tracking"
if [ -f "docs/research/templates/usability-analysis-template.md" ]; then
  metrics=0
  if grep -q "Task Success Rate" "docs/research/templates/usability-analysis-template.md" \
    || grep -q "task completion" "docs/research/templates/usability-analysis-template.md"; then
    ((metrics++))
  fi
  if grep -q "Time to Complete" "docs/research/templates/usability-analysis-template.md" \
    || grep -q "duration" "docs/research/templates/usability-analysis-template.md"; then
    ((metrics++))
  fi
  if grep -q "Confidence" "docs/research/templates/usability-analysis-template.md"; then
    ((metrics++))
  fi

  if [ $metrics -eq 3 ]; then
    print_pass "Analysis template includes success metrics"
  else
    print_fail "Analysis template missing metrics ($metrics/3 found)"
  fi
else
  print_fail "Cannot check metrics - analysis template not found"
fi

print_check "Analysis template has issue categorization"
if [ -f "docs/research/templates/usability-analysis-template.md" ]; then
  if grep -q "Critical\|P0" "docs/research/templates/usability-analysis-template.md" \
    && grep -q "Major\|P1" "docs/research/templates/usability-analysis-template.md" \
    && grep -q "Minor\|P2" "docs/research/templates/usability-analysis-template.md"; then
    print_pass "Issue severity categorization present"
  else
    print_fail "Issue severity categorization missing"
  fi
else
  print_fail "Cannot check categorization - analysis template not found"
fi

print_check "Synthesis process is documented"
if grep -q "Cross-Session Synthesis" "docs/research/templates/usability-analysis-template.md" \
  || grep -q "synthesis" "docs/how-to/usability-testing-guide.md"; then
  print_pass "Synthesis process documented"
else
  print_fail "Synthesis process not documented"
fi

# ============================================================================
# Participant Recruitment Process
# ============================================================================
print_header "5. Participant Recruitment Process"

print_check "Participant screener has selection criteria"
if [ -f "docs/research/templates/participant-screener.md" ]; then
  criteria=0
  if grep -q "role\|Role" "docs/research/templates/participant-screener.md"; then
    ((criteria++))
  fi
  if grep -q "experience\|Experience" "docs/research/templates/participant-screener.md"; then
    ((criteria++))
  fi
  if grep -q "availability\|Availability" "docs/research/templates/participant-screener.md"; then
    ((criteria++))
  fi

  if [ $criteria -eq 3 ]; then
    print_pass "Screener includes selection criteria"
  else
    print_fail "Screener missing criteria ($criteria/3 found)"
  fi
else
  print_fail "Cannot check criteria - screener not found"
fi

print_check "Recruitment email templates are provided"
if [ -f "docs/research/templates/participant-screener.md" ]; then
  if grep -q "Recruitment Email" "docs/research/templates/participant-screener.md" \
    || grep -q "email template" "docs/research/templates/participant-screener.md"; then
    print_pass "Email templates provided"
  else
    print_fail "Email templates not found"
  fi
else
  print_fail "Cannot check email templates - screener not found"
fi

print_check "Scheduling workflow is documented"
if grep -q "schedule\|Schedule" "docs/how-to/usability-testing-guide.md" \
  || grep -q "calendar" "docs/research/templates/participant-screener.md"; then
  print_pass "Scheduling workflow documented"
else
  print_fail "Scheduling workflow not documented"
fi

# ============================================================================
# Privacy and Consent
# ============================================================================
print_header "6. Privacy and Consent"

print_check "Consent process is documented"
if grep -q "consent\|Consent" "docs/how-to/usability-testing-guide.md" \
  || grep -q "consent\|Consent" "docs/research/templates/usability-test-script.md"; then
  print_pass "Consent process documented"
else
  print_fail "Consent process not documented"
fi

print_check "Data privacy guidelines exist"
if grep -q "privacy\|Privacy\|anonymize\|Anonymize" "docs/how-to/usability-testing-guide.md"; then
  print_pass "Privacy guidelines documented"
else
  print_fail "Privacy guidelines not documented"
fi

print_check "Data sanitization is documented"
if grep -q "sanitize\|Sanitize" "docs/how-to/session-recording-setup.md" 2> /dev/null; then
  print_pass "Data sanitization documented"
else
  print_warning "Data sanitization documentation should be enhanced"
fi

# ============================================================================
# BDD Feature Tests
# ============================================================================
print_header "7. Acceptance Tests"

print_check "BDD feature file exists"
if [ -f "tests/bdd/features/usability-testing.feature" ]; then
  print_pass "Usability testing BDD feature found"
else
  print_fail "Usability testing BDD feature not found"
fi

print_check "Feature file has comprehensive scenarios"
if [ -f "tests/bdd/features/usability-testing.feature" ]; then
  scenarios=$(grep -c "Scenario:" "tests/bdd/features/usability-testing.feature" || echo 0)
  if [ "$scenarios" -ge 10 ]; then
    print_pass "Feature file has $scenarios test scenarios"
  else
    print_warning "Feature file has only $scenarios scenarios (expected 10+)"
  fi
else
  print_fail "Cannot check scenarios - feature file not found"
fi

# ============================================================================
# Integration with Research Repository
# ============================================================================
print_header "8. Integration with Research Repository"

print_check "Research data structure exists"
if [ -d "docs/research/data" ]; then
  print_pass "Research data directory exists"
else
  print_warning "Research data directory should be created"
fi

print_check "Insights directory exists"
if [ -d "docs/research/insights" ]; then
  print_pass "Research insights directory exists"
else
  print_warning "Research insights directory should be created"
fi

print_check "Templates directory exists"
if [ -d "docs/research/templates" ]; then
  print_pass "Research templates directory exists"
else
  print_fail "Research templates directory not found"
fi

# ============================================================================
# Best Practices Documentation
# ============================================================================
print_header "9. Best Practices and Guidance"

print_check "Best practices section exists in guide"
if grep -q "Best Practices" "docs/how-to/usability-testing-guide.md"; then
  print_pass "Best practices documented"
else
  print_fail "Best practices section not found"
fi

print_check "Troubleshooting guidance exists"
if grep -q "Troubleshooting\|troubleshooting" "docs/how-to/session-recording-setup.md" 2> /dev/null; then
  print_pass "Troubleshooting guidance provided"
else
  print_warning "Troubleshooting guidance should be added"
fi

print_check "External resources are referenced"
if grep -q "Nielsen Norman\|Steve Krug\|nngroup" "docs/how-to/usability-testing-guide.md"; then
  print_pass "External best practice resources referenced"
else
  print_warning "Consider adding references to usability testing experts"
fi

# ============================================================================
# Summary
# ============================================================================
print_header "Validation Summary"

TOTAL_CHECKS=$((CHECKS_PASSED + CHECKS_FAILED + CHECKS_WARNING))
PASS_RATE=$((CHECKS_PASSED * 100 / TOTAL_CHECKS))

echo "Total Checks: $TOTAL_CHECKS"
echo -e "${GREEN}Passed: $CHECKS_PASSED${NC}"
echo -e "${RED}Failed: $CHECKS_FAILED${NC}"
echo -e "${YELLOW}Warnings: $CHECKS_WARNING${NC}"
echo "Pass Rate: $PASS_RATE%"

echo ""

if [ $CHECKS_FAILED -eq 0 ]; then
  echo -e "${GREEN}✅ AT-E3-010 VALIDATION PASSED${NC}"
  echo "Usability testing infrastructure is properly configured."
  exit 0
elif [ $CHECKS_FAILED -le 3 ]; then
  echo -e "${YELLOW}⚠️  AT-E3-010 VALIDATION PASSED WITH WARNINGS${NC}"
  echo "Minor issues found but core infrastructure is in place."
  exit 0
else
  echo -e "${RED}❌ AT-E3-010 VALIDATION FAILED${NC}"
  echo "Critical components missing or misconfigured."
  exit 1
fi
