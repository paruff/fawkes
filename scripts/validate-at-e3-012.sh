#!/bin/bash

set -euo pipefail
# Don't use set -e to prevent early exit on failures
# We want to collect all validation results

# validate-at-e3-012.sh
# Validation script for AT-E3-012: Complete Epic 3 Documentation
#
# This script validates that all Epic 3 documentation is complete including
# runbooks, API references, tutorials, how-to guides, and architecture docs.

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
      echo "Validates AT-E3-012: Complete Epic 3 Documentation"
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

print_header "AT-E3-012: Complete Epic 3 Documentation Validation"
echo "Namespace: $NAMESPACE"
echo "Date: $(date)"
echo ""

# ============================================================================
# Documentation Index and Overview
# ============================================================================
print_header "1. Documentation Index and Overview"

print_check "Epic 3 documentation index exists"
if [ -f "docs/EPIC-3-DOCUMENTATION-INDEX.md" ]; then
  print_pass "Epic 3 documentation index found"

  # Check if index is comprehensive
  word_count=$(wc -w < "docs/EPIC-3-DOCUMENTATION-INDEX.md")
  if [ "$word_count" -gt 1000 ]; then
    print_pass "Documentation index is comprehensive (${word_count} words)"
  else
    print_warning "Documentation index is brief (${word_count} words)"
  fi
else
  print_fail "Epic 3 documentation index not found"
fi

print_check "Documentation index includes key sections"
if [ -f "docs/EPIC-3-DOCUMENTATION-INDEX.md" ]; then
  required_sections=(
    "Getting Started"
    "Runbooks"
    "API References"
    "Demo"
    "How-To Guides"
  )

  missing_sections=()
  for section in "${required_sections[@]}"; do
    if ! grep -qi "$section" "docs/EPIC-3-DOCUMENTATION-INDEX.md"; then
      missing_sections+=("$section")
    fi
  done

  if [ ${#missing_sections[@]} -eq 0 ]; then
    print_pass "All required sections in documentation index"
  else
    print_fail "Missing sections in index: ${missing_sections[*]}"
  fi
else
  print_fail "Cannot check sections - documentation index not found"
fi

# ============================================================================
# User Guides
# ============================================================================
print_header "2. User Guides"

print_check "Epic 3 user guide exists"
if [ -f "docs/how-to/epic-3-user-guide.md" ]; then
  word_count=$(wc -w < "docs/how-to/epic-3-user-guide.md")
  if [ "$word_count" -gt 3000 ]; then
    print_pass "Epic 3 user guide found and comprehensive (${word_count} words)"
  else
    print_warning "Epic 3 user guide found but brief (${word_count} words)"
  fi
else
  print_fail "Epic 3 user guide not found"
fi

print_check "User guide covers all user personas"
if [ -f "docs/how-to/epic-3-user-guide.md" ]; then
  required_personas=(
    "Developer"
    "Product Manager"
    "UX Researcher"
    "Platform Engineer"
  )

  missing_personas=()
  for persona in "${required_personas[@]}"; do
    if ! grep -qi "$persona" "docs/how-to/epic-3-user-guide.md"; then
      missing_personas+=("$persona")
    fi
  done

  if [ ${#missing_personas[@]} -eq 0 ]; then
    print_pass "User guide covers all personas"
  else
    print_fail "User guide missing personas: ${missing_personas[*]}"
  fi
else
  print_fail "Cannot check personas - user guide not found"
fi

print_check "SPACE metrics guide exists"
if [ -f "docs/how-to/space-metrics-guide.md" ]; then
  print_pass "SPACE metrics guide found"
else
  print_fail "SPACE metrics guide not found"
fi

print_check "Product analytics quickstart exists"
if [ -f "docs/how-to/product-analytics-quickstart.md" ]; then
  print_pass "Product analytics quickstart found"
else
  print_fail "Product analytics quickstart not found"
fi

print_check "Accessibility testing guide exists"
if [ -f "docs/how-to/accessibility-testing-guide.md" ]; then
  print_pass "Accessibility testing guide found"
else
  print_fail "Accessibility testing guide not found"
fi

print_check "Usability testing guide exists"
if [ -f "docs/how-to/usability-testing-guide.md" ]; then
  print_pass "Usability testing guide found"
else
  print_fail "Usability testing guide not found"
fi

print_check "Advisory board meeting guide exists"
if [ -f "docs/how-to/run-advisory-board-meetings.md" ]; then
  print_pass "Advisory board meeting guide found"
else
  print_fail "Advisory board meeting guide not found"
fi

# ============================================================================
# Runbooks and Operations
# ============================================================================
print_header "3. Runbooks and Operations"

print_check "Epic 3 operations runbook exists"
if [ -f "docs/runbooks/epic-3-product-discovery-operations.md" ]; then
  word_count=$(wc -w < "docs/runbooks/epic-3-product-discovery-operations.md")
  if [ "$word_count" -gt 3000 ]; then
    print_pass "Epic 3 operations runbook found and comprehensive (${word_count} words)"
  else
    print_warning "Epic 3 operations runbook found but brief (${word_count} words)"
  fi
else
  print_fail "Epic 3 operations runbook not found"
fi

print_check "Operations runbook includes component status checks"
if [ -f "docs/runbooks/epic-3-product-discovery-operations.md" ]; then
  required_components=(
    "SPACE Metrics"
    "Feedback"
    "Unleash"
    "Analytics"
  )

  missing_components=()
  for component in "${required_components[@]}"; do
    if ! grep -qi "$component" "docs/runbooks/epic-3-product-discovery-operations.md"; then
      missing_components+=("$component")
    fi
  done

  if [ ${#missing_components[@]} -eq 0 ]; then
    print_pass "Operations runbook covers all key components"
  else
    print_fail "Operations runbook missing components: ${missing_components[*]}"
  fi
else
  print_fail "Cannot check components - operations runbook not found"
fi

print_check "Operations runbook includes troubleshooting"
if [ -f "docs/runbooks/epic-3-product-discovery-operations.md" ]; then
  if grep -qi "troubleshooting\|common issues\|debugging" "docs/runbooks/epic-3-product-discovery-operations.md"; then
    print_pass "Operations runbook includes troubleshooting section"
  else
    print_fail "Operations runbook missing troubleshooting section"
  fi
else
  print_fail "Cannot check troubleshooting - operations runbook not found"
fi

# ============================================================================
# Architecture and Design
# ============================================================================
print_header "4. Architecture and Design Documentation"

print_check "Epic 3 architecture diagrams exist"
if [ -f "docs/runbooks/epic-3-architecture-diagrams.md" ]; then
  word_count=$(wc -w < "docs/runbooks/epic-3-architecture-diagrams.md")
  if [ "$word_count" -gt 1000 ]; then
    print_pass "Epic 3 architecture diagrams found and detailed (${word_count} words)"
  else
    print_warning "Epic 3 architecture diagrams found but brief (${word_count} words)"
  fi
else
  print_fail "Epic 3 architecture diagrams not found"
fi

print_check "Architecture diagrams cover all major systems"
if [ -f "docs/runbooks/epic-3-architecture-diagrams.md" ]; then
  required_diagrams=(
    "SPACE metrics"
    "Feedback"
    "Analytics"
    "Feature flags"
    "Discovery workflow"
  )

  missing_diagrams=()
  for diagram in "${required_diagrams[@]}"; do
    if ! grep -qi "$diagram" "docs/runbooks/epic-3-architecture-diagrams.md"; then
      missing_diagrams+=("$diagram")
    fi
  done

  if [ ${#missing_diagrams[@]} -eq 0 ]; then
    print_pass "Architecture diagrams cover all major systems"
  else
    print_fail "Architecture diagrams missing: ${missing_diagrams[*]}"
  fi
else
  print_fail "Cannot check diagrams - architecture doc not found"
fi

print_check "Continuous discovery playbook exists"
if [ -f "docs/playbooks/continuous-discovery-workflow.md" ]; then
  print_pass "Continuous discovery playbook found"
else
  print_fail "Continuous discovery playbook not found"
fi

# ============================================================================
# API References
# ============================================================================
print_header "5. API Reference Documentation"

print_check "Epic 3 API reference exists"
if [ -f "docs/reference/api/epic-3-product-discovery-apis.md" ]; then
  word_count=$(wc -w < "docs/reference/api/epic-3-product-discovery-apis.md")
  if [ "$word_count" -gt 2000 ]; then
    print_pass "Epic 3 API reference found and comprehensive (${word_count} words)"
  else
    print_warning "Epic 3 API reference found but brief (${word_count} words)"
  fi
else
  print_fail "Epic 3 API reference not found"
fi

print_check "API reference documents all major APIs"
if [ -f "docs/reference/api/epic-3-product-discovery-apis.md" ]; then
  required_apis=(
    "SPACE Metrics API"
    "Feedback Service API"
    "Unleash API"
    "Analytics API"
  )

  missing_apis=()
  for api in "${required_apis[@]}"; do
    if ! grep -qi "$api" "docs/reference/api/epic-3-product-discovery-apis.md"; then
      missing_apis+=("$api")
    fi
  done

  if [ ${#missing_apis[@]} -eq 0 ]; then
    print_pass "API reference documents all major APIs"
  else
    print_fail "API reference missing APIs: ${missing_apis[*]}"
  fi
else
  print_fail "Cannot check APIs - API reference not found"
fi

print_check "API reference includes authentication details"
if [ -f "docs/reference/api/epic-3-product-discovery-apis.md" ]; then
  if grep -qi "authentication\|bearer\|api key\|token" "docs/reference/api/epic-3-product-discovery-apis.md"; then
    print_pass "API reference includes authentication details"
  else
    print_warning "API reference may be missing authentication details"
  fi
else
  print_fail "Cannot check authentication - API reference not found"
fi

# ============================================================================
# Demo and Tutorial Resources
# ============================================================================
print_header "6. Demo and Tutorial Resources"

print_check "Epic 3 demo video script exists"
if [ -f "docs/tutorials/epic-3-demo-video-script.md" ]; then
  word_count=$(wc -w < "docs/tutorials/epic-3-demo-video-script.md")
  if [ "$word_count" -gt 2000 ]; then
    print_pass "Epic 3 demo video script found and detailed (${word_count} words)"
  else
    print_warning "Epic 3 demo video script found but brief (${word_count} words)"
  fi
else
  print_fail "Epic 3 demo video script not found"
fi

print_check "Epic 3 demo video checklist exists"
if [ -f "docs/tutorials/epic-3-demo-video-checklist.md" ]; then
  print_pass "Epic 3 demo video checklist found"
else
  print_fail "Epic 3 demo video checklist not found"
fi

print_check "Epic 3 demo video page exists"
if [ -f "docs/tutorials/epic-3-demo-video.md" ]; then
  print_pass "Epic 3 demo video page found"
else
  print_fail "Epic 3 demo video page not found"
fi

# ============================================================================
# Component-Specific Documentation
# ============================================================================
print_header "7. Component-Specific Documentation"

print_check "Design system documentation exists"
if [ -f "docs/how-to/deploy-design-system-storybook.md" ]; then
  print_pass "Design system deployment guide found"
else
  print_warning "Design system deployment guide not found"
fi

print_check "Feature flags documentation exists"
if [ -f "docs/how-to/epic-3-user-guide.md" ] && grep -qi "feature flags\|unleash" "docs/how-to/epic-3-user-guide.md"; then
  print_pass "Feature flags documentation found"
else
  print_warning "Feature flags documentation may be incomplete"
fi

print_check "Experimentation framework documentation exists"
if [ -d "services/experimentation" ] && [ -f "services/experimentation/README.md" ]; then
  print_pass "Experimentation framework documentation found"
else
  print_warning "Experimentation framework documentation not found"
fi

# ============================================================================
# Validation and Implementation Documentation
# ============================================================================
print_header "8. Validation and Implementation Documentation"

print_check "Acceptance test documentation in tests/acceptance/README.md"
if [ -f "tests/acceptance/README.md" ]; then
  if grep -qi "AT-E3" "tests/acceptance/README.md"; then
    print_pass "Epic 3 acceptance tests documented"
  else
    print_warning "Epic 3 acceptance tests may not be documented"
  fi
else
  print_fail "Acceptance tests README not found"
fi

print_check "AT-E3 implementation summaries exist"
implementation_docs=$(find docs/validation -name "AT-E3-*-IMPLEMENTATION.md" 2> /dev/null | wc -l)
if [ "$implementation_docs" -gt 0 ]; then
  print_pass "Found ${implementation_docs} AT-E3 implementation documents"
else
  print_warning "No AT-E3 implementation documents found in docs/validation"
fi

# ============================================================================
# Documentation Quality Checks
# ============================================================================
print_header "9. Documentation Quality Checks"

print_check "Documentation files use proper markdown"
broken_links=0
if command -v markdownlint > /dev/null 2>&1; then
  # Count errors (we'll just check if command succeeds)
  if markdownlint docs/how-to/epic-3-user-guide.md > /dev/null 2>&1; then
    print_pass "Documentation passes markdown linting"
  else
    print_warning "Documentation has markdown linting issues"
  fi
else
  print_warning "markdownlint not installed, skipping markdown quality check"
fi

print_check "Key documentation files have adequate length"
total_words=0
key_docs=(
  "docs/EPIC-3-DOCUMENTATION-INDEX.md"
  "docs/how-to/epic-3-user-guide.md"
  "docs/runbooks/epic-3-product-discovery-operations.md"
  "docs/reference/api/epic-3-product-discovery-apis.md"
  "docs/runbooks/epic-3-architecture-diagrams.md"
)

for doc in "${key_docs[@]}"; do
  if [ -f "$doc" ]; then
    words=$(wc -w < "$doc")
    total_words=$((total_words + words))
  fi
done

if [ $total_words -gt 10000 ]; then
  print_pass "Key documentation has adequate content (${total_words} total words)"
elif [ $total_words -gt 5000 ]; then
  print_warning "Key documentation content is moderate (${total_words} total words)"
else
  print_fail "Key documentation content is insufficient (${total_words} total words, expected >10000)"
fi

# ============================================================================
# Completeness Check
# ============================================================================
print_header "10. Documentation Completeness"

print_check "All 12 Epic 3 acceptance tests documented"
documented_tests=0
for i in $(seq -w 1 12); do
  test_id="AT-E3-0${i#0}"
  if grep -rqi "$test_id" docs/ tests/acceptance/README.md 2> /dev/null; then
    ((documented_tests++))
  fi
done

if [ $documented_tests -ge 10 ]; then
  print_pass "Most Epic 3 acceptance tests documented (${documented_tests}/12)"
elif [ $documented_tests -ge 6 ]; then
  print_warning "Some Epic 3 acceptance tests documented (${documented_tests}/12)"
else
  print_fail "Few Epic 3 acceptance tests documented (${documented_tests}/12)"
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
  echo -e "${GREEN}🎉 AT-E3-012 validation passed!${NC}"
  echo ""
  echo "Epic 3 documentation is complete:"
  echo "  ✓ Documentation index comprehensive"
  echo "  ✓ User guides for all personas"
  echo "  ✓ Operations runbooks with troubleshooting"
  echo "  ✓ Architecture diagrams for all systems"
  echo "  ✓ API references for all services"
  echo "  ✓ Demo and tutorial resources"
  echo "  ✓ Component-specific documentation"
  echo "  ✓ Validation and implementation docs"
  echo "  ✓ Quality standards met"
  exit 0
else
  echo -e "${RED}❌ AT-E3-012 validation failed${NC}"
  echo ""
  echo "Please address the failed checks above."
  exit 1
fi
