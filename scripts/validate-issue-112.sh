#!/usr/bin/env bash

set -euo pipefail

cd "$(dirname "$0")/.."

echo "============================================"
echo "Issue #112 Validation"
echo "============================================"
echo ""

PASSED=0
FAILED=0

check() {
  local desc="$1"
  local cmd="$2"
  if eval "$cmd" > /dev/null 2>&1; then
    echo "✓ $desc"
    PASSED=$((PASSED + 1))
    return 0
  else
    echo "✗ $desc"
    FAILED=$((FAILED + 1))
    return 0 # Don't exit on failure
  fi
}

# Test 1: File exists
check "CODING_STANDARDS.md exists" "[[ -f CODING_STANDARDS.md ]]" || true

# Test 2: File size
SIZE=$(wc -c < CODING_STANDARDS.md 2> /dev/null || echo 0)
if [[ $SIZE -gt 10000 ]]; then
  echo "✓ File size adequate ($SIZE bytes)"
  PASSED=$((PASSED + 1))
else
  echo "✗ File too small ($SIZE bytes)"
  FAILED=$((FAILED + 1))
fi

# Test 3: Required sections
echo ""
echo "Checking required sections..."
for SEC in "Overview" "Quick Start" "Developer Setup" "Language-Specific Standards" "FAQ"; do
  check "Section '$SEC'" "grep -q '^## $SEC' CODING_STANDARDS.md" || true
done

# Test 4: Languages
echo ""
echo "Checking language guides..."
for LANG in "Python" "Go" "Bash/Shell" "YAML" "JSON" "Markdown" "Terraform" "TypeScript/JavaScript"; do
  check "Language '$LANG'" "grep -q '^### $LANG' CODING_STANDARDS.md" || true
done

# Test 5: Examples
echo ""
GOOD=$(grep -c "Good Examples" CODING_STANDARDS.md 2> /dev/null || echo 0)
BAD=$(grep -c "Bad Examples" CODING_STANDARDS.md 2> /dev/null || echo 0)
if [[ $GOOD -ge 5 ]] && [[ $BAD -ge 5 ]]; then
  echo "✓ Examples: $GOOD good, $BAD bad"
  PASSED=$((PASSED + 1))
else
  echo "✗ Insufficient examples: $GOOD good, $BAD bad"
  FAILED=$((FAILED + 1))
fi

# Test 6: FAQ
FAQ=$(grep -c "#### Q:" CODING_STANDARDS.md 2> /dev/null || echo 0)
if [[ $FAQ -ge 10 ]]; then
  echo "✓ FAQ has $FAQ questions"
  PASSED=$((PASSED + 1))
else
  echo "✗ FAQ needs more questions (has $FAQ)"
  FAILED=$((FAILED + 1))
fi

# Test 7: Integration
echo ""
echo "Checking integrations..."
check "README references CODING_STANDARDS" "grep -q CODING_STANDARDS README.md" || true
check "contributing.md updated" "grep -q CODING_STANDARDS docs/contributing.md" || true
check "mkdocs.yml updated" "grep -q CODING_STANDARDS mkdocs.yml" || true
check "Makefile has target" "grep -q validate-issue-112 Makefile" || true

echo ""
echo "============================================"
echo "Results: $PASSED passed, $FAILED failed"
echo "============================================"
echo ""

if [[ $FAILED -eq 0 ]]; then
  echo "🎉 All checks passed!"
  echo ""
  echo "Acceptance Criteria Status:"
  echo "  ✅ CODING_STANDARDS.md created"
  echo "  ✅ Language-specific guides"
  echo "  ✅ Developer setup complete"
  echo "  ✅ Good vs bad examples"
  echo "  ✅ FAQ included"
  exit 0
else
  echo "❌ $FAILED checks failed"
  echo "Please review the output above"
  exit 1
fi
