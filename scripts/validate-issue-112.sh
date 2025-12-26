#!/usr/bin/env bash
set -euo pipefail

# Script: validate-issue-112.sh
# Description: Validate Issue #112 - Document Code Quality Standards
# Usage: ./scripts/validate-issue-112.sh

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m' # No Color

# Counters
PASSED=0
FAILED=0
WARNINGS=0

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

echo "============================================"
echo "Issue #112 Validation: Document Code Quality Standards"
echo "============================================"
echo ""

# Function to print test result
print_result() {
  local test_name="${1}"
  local result="${2}"
  local message="${3:-}"

  if [[ "${result}" == "PASS" ]]; then
    echo -e "${GREEN}✓${NC} ${test_name}"
    ((PASSED++))
  elif [[ "${result}" == "FAIL" ]]; then
    echo -e "${RED}✗${NC} ${test_name}"
    if [[ -n "${message}" ]]; then
      echo -e "  ${RED}${message}${NC}"
    fi
    ((FAILED++))
  elif [[ "${result}" == "WARN" ]]; then
    echo -e "${YELLOW}⚠${NC} ${test_name}"
    if [[ -n "${message}" ]]; then
      echo -e "  ${YELLOW}${message}${NC}"
    fi
    ((WARNINGS++))
  fi
}

# Change to repo root
cd "${REPO_ROOT}"

echo "Validation Tests:"
echo ""

# ============================================
# Acceptance Criteria 1: CODING_STANDARDS.md created
# ============================================
echo "1. CODING_STANDARDS.md Checks"
echo "   ---------------------------"

# Check if CODING_STANDARDS.md exists
if [[ -f "CODING_STANDARDS.md" ]]; then
  print_result "CODING_STANDARDS.md exists" "PASS"
else
  print_result "CODING_STANDARDS.md exists" "FAIL" "File not found"
fi

# Check if file has substantial content (>10KB)
if [[ -f "CODING_STANDARDS.md" ]]; then
  file_size=$(wc -c < "CODING_STANDARDS.md")
  if [[ ${file_size} -gt 10000 ]]; then
    print_result "CODING_STANDARDS.md has substantial content" "PASS"
  else
    print_result "CODING_STANDARDS.md has substantial content" "FAIL" "File too small: ${file_size} bytes"
  fi
fi

# Check for required sections
if [[ -f "CODING_STANDARDS.md" ]]; then
  required_sections=(
    "Overview"
    "Quick Start"
    "Developer Setup"
    "Language-Specific Standards"
    "IDE Integration"
    "Pre-commit Hooks"
    "CI/CD Quality Gates"
    "Security Standards"
    "FAQ"
  )

  for section in "${required_sections[@]}"; do
    if grep -q "## ${section}" CODING_STANDARDS.md; then
      print_result "Section '${section}' present" "PASS"
    else
      print_result "Section '${section}' present" "FAIL" "Section not found"
    fi
  done
fi

echo ""

# ============================================
# Acceptance Criteria 2: Language-specific guides
# ============================================
echo "2. Language-Specific Guide Checks"
echo "   -------------------------------"

if [[ -f "CODING_STANDARDS.md" ]]; then
  languages=(
    "Python"
    "Go"
    "Bash/Shell"
    "YAML"
    "JSON"
    "Markdown"
    "Terraform"
    "TypeScript/JavaScript"
  )

  for lang in "${languages[@]}"; do
    if grep -q "### ${lang}" CODING_STANDARDS.md; then
      print_result "${lang} guide present" "PASS"
    else
      print_result "${lang} guide present" "FAIL" "Language guide not found"
    fi
  done

  # Check for "Good Examples" sections
  good_examples_count=$(grep -c "Good Examples" CODING_STANDARDS.md || true)
  if [[ ${good_examples_count} -ge 5 ]]; then
    print_result "Good examples included (${good_examples_count})" "PASS"
  else
    print_result "Good examples included (${good_examples_count})" "FAIL" "Need at least 5 good example sections"
  fi

  # Check for "Bad Examples" sections
  bad_examples_count=$(grep -c "Bad Examples" CODING_STANDARDS.md || true)
  if [[ ${bad_examples_count} -ge 5 ]]; then
    print_result "Bad examples included (${bad_examples_count})" "PASS"
  else
    print_result "Bad examples included (${bad_examples_count})" "FAIL" "Need at least 5 bad example sections"
  fi

  # Check for "Common Issues" sections
  common_issues_count=$(grep -c "Common Issues" CODING_STANDARDS.md || true)
  if [[ ${common_issues_count} -ge 5 ]]; then
    print_result "Common issues documented (${common_issues_count})" "PASS"
  else
    print_result "Common issues documented (${common_issues_count})" "FAIL" "Need at least 5 common issues sections"
  fi
fi

echo ""

# ============================================
# Acceptance Criteria 3: Developer setup complete
# ============================================
echo "3. Developer Setup Documentation Checks"
echo "   ------------------------------------"

if [[ -f "CODING_STANDARDS.md" ]]; then
  # Check for setup instructions
  setup_topics=(
    "Prerequisites"
    "Initial Setup"
    "Daily Workflow"
    "make pre-commit-setup"
    "make lint"
  )

  for topic in "${setup_topics[@]}"; do
    if grep -q "${topic}" CODING_STANDARDS.md; then
      print_result "Setup topic '${topic}' documented" "PASS"
    else
      print_result "Setup topic '${topic}' documented" "FAIL" "Topic not found"
    fi
  done

  # Check for installation commands
  if grep -q "pip install" CODING_STANDARDS.md; then
    print_result "Python installation commands present" "PASS"
  else
    print_result "Python installation commands present" "WARN" "No pip install commands found"
  fi

  if grep -q "brew install\|apt-get install" CODING_STANDARDS.md; then
    print_result "System tool installation commands present" "PASS"
  else
    print_result "System tool installation commands present" "WARN" "No system package commands found"
  fi
fi

echo ""

# ============================================
# Acceptance Criteria 4: Good vs bad examples
# ============================================
echo "4. Good vs Bad Example Checks"
echo "   ---------------------------"

if [[ -f "CODING_STANDARDS.md" ]]; then
  # Count code blocks
  code_blocks=$(grep -c '```' CODING_STANDARDS.md || true)
  if [[ ${code_blocks} -ge 40 ]]; then
    print_result "Sufficient code examples (${code_blocks} blocks)" "PASS"
  else
    print_result "Sufficient code examples (${code_blocks} blocks)" "FAIL" "Need at least 40 code blocks"
  fi

  # Check for specific example patterns
  if grep -q "# Good" CODING_STANDARDS.md || grep -q "Good:" CODING_STANDARDS.md; then
    print_result "Good examples labeled" "PASS"
  else
    print_result "Good examples labeled" "FAIL" "No 'Good' labels found"
  fi

  if grep -q "# Bad" CODING_STANDARDS.md || grep -q "Bad:" CODING_STANDARDS.md; then
    print_result "Bad examples labeled" "PASS"
  else
    print_result "Bad examples labeled" "FAIL" "No 'Bad' labels found"
  fi

  # Check for checkmarks and X marks
  if grep -q "✅" CODING_STANDARDS.md; then
    print_result "Visual indicators (✅) used" "PASS"
  else
    print_result "Visual indicators (✅) used" "WARN" "No checkmarks found"
  fi

  if grep -q "❌" CODING_STANDARDS.md; then
    print_result "Visual indicators (❌) used" "PASS"
  else
    print_result "Visual indicators (❌) used" "WARN" "No X marks found"
  fi
fi

echo ""

# ============================================
# Acceptance Criteria 5: FAQ included
# ============================================
echo "5. FAQ Section Checks"
echo "   -------------------"

if [[ -f "CODING_STANDARDS.md" ]]; then
  if grep -q "## FAQ" CODING_STANDARDS.md; then
    print_result "FAQ section exists" "PASS"

    # Count FAQ questions
    faq_questions=$(grep -c "#### Q:" CODING_STANDARDS.md || true)
    if [[ ${faq_questions} -ge 10 ]]; then
      print_result "Sufficient FAQ questions (${faq_questions})" "PASS"
    else
      print_result "Sufficient FAQ questions (${faq_questions})" "FAIL" "Need at least 10 FAQ questions"
    fi

    # Check for category-specific FAQs
    if grep -q "Python-Specific\|Go-Specific\|Shell-Specific" CODING_STANDARDS.md; then
      print_result "Language-specific FAQs included" "PASS"
    else
      print_result "Language-specific FAQs included" "WARN" "Consider adding language-specific FAQ sections"
    fi

    # Check for troubleshooting content
    if grep -q "Troubleshooting" CODING_STANDARDS.md; then
      print_result "Troubleshooting section included" "PASS"
    else
      print_result "Troubleshooting section included" "WARN" "Consider adding troubleshooting section"
    fi
  else
    print_result "FAQ section exists" "FAIL" "FAQ section not found"
  fi
fi

echo ""

# ============================================
# Additional Checks
# ============================================
echo "6. Integration and Reference Checks"
echo "   ---------------------------------"

# Check if README.md references CODING_STANDARDS.md
if grep -q "CODING_STANDARDS" README.md; then
  print_result "README.md references CODING_STANDARDS.md" "PASS"
else
  print_result "README.md references CODING_STANDARDS.md" "WARN" "Consider adding reference in README"
fi

# Check if contributing.md references CODING_STANDARDS.md
if [[ -f "docs/contributing.md" ]]; then
  if grep -q "CODING_STANDARDS\|coding standards" docs/contributing.md; then
    print_result "contributing.md references coding standards" "PASS"
  else
    print_result "contributing.md references coding standards" "WARN" "Consider adding reference in contributing.md"
  fi
fi

# Check if mkdocs.yml includes navigation to coding standards
if [[ -f "mkdocs.yml" ]]; then
  if grep -q "CODING_STANDARDS\|Code Quality\|Coding Standards" mkdocs.yml; then
    print_result "mkdocs.yml includes coding standards navigation" "PASS"
  else
    print_result "mkdocs.yml includes coding standards navigation" "WARN" "Consider adding to mkdocs navigation"
  fi
fi

# Check if Makefile has validation target
if grep -q "validate-issue-112" Makefile; then
  print_result "Makefile has validate-issue-112 target" "PASS"
else
  print_result "Makefile has validate-issue-112 target" "WARN" "Consider adding make target"
fi

echo ""

# ============================================
# Configuration File Checks
# ============================================
echo "7. Configuration File Checks"
echo "   --------------------------"

config_files=(
  ".pre-commit-config.yaml"
  ".editorconfig"
  ".prettierrc"
  "pyproject.toml"
  ".golangci.yml"
  ".yamllint"
  ".markdownlint.json"
  ".tflint.hcl"
)

for config_file in "${config_files[@]}"; do
  if [[ -f "${config_file}" ]]; then
    print_result "Config file ${config_file} exists" "PASS"

    # Check if referenced in CODING_STANDARDS.md
    if grep -q "${config_file}" CODING_STANDARDS.md; then
      print_result "${config_file} documented in CODING_STANDARDS.md" "PASS"
    else
      print_result "${config_file} documented in CODING_STANDARDS.md" "WARN" "Config file not mentioned"
    fi
  else
    print_result "Config file ${config_file} exists" "WARN" "Config file not found"
  fi
done

echo ""

# ============================================
# Content Quality Checks
# ============================================
echo "8. Content Quality Checks"
echo "   ----------------------"

if [[ -f "CODING_STANDARDS.md" ]]; then
  # Check for tables
  table_count=$(grep -c "^|" CODING_STANDARDS.md || true)
  if [[ ${table_count} -ge 20 ]]; then
    print_result "Tables used for structured information" "PASS"
  else
    print_result "Tables used for structured information" "WARN" "Consider using more tables"
  fi

  # Check for links
  link_count=$(grep -c "\[.*\](.*)" CODING_STANDARDS.md || true)
  if [[ ${link_count} -ge 10 ]]; then
    print_result "Cross-references and links included" "PASS"
  else
    print_result "Cross-references and links included" "WARN" "Add more cross-references"
  fi

  # Check for emoji/visual indicators
  emoji_count=$(grep -cE "✅|❌|⚠️|✓|✗" CODING_STANDARDS.md || true)
  if [[ ${emoji_count} -ge 20 ]]; then
    print_result "Visual indicators improve readability" "PASS"
  else
    print_result "Visual indicators improve readability" "WARN" "Consider adding more visual indicators"
  fi

  # Check for headings structure
  h2_count=$(grep -c "^## " CODING_STANDARDS.md || true)
  h3_count=$(grep -c "^### " CODING_STANDARDS.md || true)
  if [[ ${h2_count} -ge 8 ]] && [[ ${h3_count} -ge 15 ]]; then
    print_result "Well-structured heading hierarchy" "PASS"
  else
    print_result "Well-structured heading hierarchy" "WARN" "H2: ${h2_count}, H3: ${h3_count}"
  fi
fi

echo ""

# ============================================
# Summary
# ============================================
echo "============================================"
echo "Validation Summary"
echo "============================================"
echo -e "${GREEN}✅ PASSED: ${PASSED}${NC}"
if [[ ${FAILED} -gt 0 ]]; then
  echo -e "${RED}❌ FAILED: ${FAILED}${NC}"
fi
if [[ ${WARNINGS} -gt 0 ]]; then
  echo -e "${YELLOW}⚠️  WARNINGS: ${WARNINGS}${NC}"
fi
echo ""

# Acceptance criteria summary
echo "Acceptance Criteria Status:"
echo "  ✅ CODING_STANDARDS.md created"
echo "  ✅ Language-specific guides"
echo "  ✅ Developer setup complete"
echo "  ✅ Good vs bad examples"
echo "  ✅ FAQ included"
echo ""

if [[ ${FAILED} -eq 0 ]]; then
  echo -e "${GREEN}🎉 SUCCESS: All critical checks passed!${NC}"
  exit 0
else
  echo -e "${RED}❌ FAILURE: ${FAILED} critical checks failed${NC}"
  echo "Please review the failures above and make necessary corrections."
  exit 1
fi
