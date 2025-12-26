#!/bin/bash
#
# Acceptance Test: AT-E3-004 - Design System Component Library
# Validates that the design system is properly implemented with 30+ components,
# design tokens, documentation, accessibility testing, and ready for npm publishing.
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Test result tracking
declare -a FAILED_TEST_NAMES=()

# Print functions
print_header() {
  echo ""
  echo "=========================================="
  echo "$1"
  echo "=========================================="
  echo ""
}

print_test() {
  echo -n "  Testing: $1 ... "
  TOTAL_TESTS=$((TOTAL_TESTS + 1))
}

print_pass() {
  echo -e "${GREEN}✓ PASS${NC}"
  PASSED_TESTS=$((PASSED_TESTS + 1))
}

print_fail() {
  echo -e "${RED}✗ FAIL${NC}"
  FAILED_TESTS=$((FAILED_TESTS + 1))
  FAILED_TEST_NAMES+=("$1")
}

print_summary() {
  echo ""
  echo "=========================================="
  echo "Test Summary"
  echo "=========================================="
  echo "Total Tests:  $TOTAL_TESTS"
  echo -e "Passed:       ${GREEN}$PASSED_TESTS${NC}"
  echo -e "Failed:       ${RED}$FAILED_TESTS${NC}"

  if [ $FAILED_TESTS -gt 0 ]; then
    echo ""
    echo "Failed Tests:"
    for test_name in "${FAILED_TEST_NAMES[@]}"; do
      echo -e "  ${RED}✗${NC} $test_name"
    done
  fi
  echo "=========================================="
}

# Change to design-system directory
DS_DIR="/home/runner/work/fawkes/fawkes/design-system"
cd "$DS_DIR" || exit 1

print_header "AT-E3-004: Design System Component Library Validation"

# AC1: Component library created
print_header "Acceptance Criteria 1: Component library created"

print_test "Design system directory exists"
if [ -d "$DS_DIR" ]; then
  print_pass
else
  print_fail "Design system directory not found"
fi

print_test "package.json exists with correct metadata"
if [ -f "package.json" ] && grep -q "@fawkes/design-system" package.json; then
  print_pass
else
  print_fail "package.json missing or incorrect"
fi

print_test "TypeScript configuration exists"
if [ -f "tsconfig.json" ]; then
  print_pass
else
  print_fail "tsconfig.json not found"
fi

print_test "Build configuration exists (rollup.config.js)"
if [ -f "rollup.config.js" ]; then
  print_pass
else
  print_fail "rollup.config.js not found"
fi

# AC2: 30+ components documented
print_header "Acceptance Criteria 2: 30+ components documented"

print_test "Components directory exists"
if [ -d "src/components" ]; then
  print_pass
else
  print_fail "Components directory not found"
fi

print_test "At least 30 component directories exist"
COMPONENT_COUNT=$(find src/components -mindepth 1 -maxdepth 1 -type d | wc -l)
if [ "$COMPONENT_COUNT" -ge 30 ]; then
  echo -e "${GREEN}✓ PASS${NC} (Found $COMPONENT_COUNT components)"
  PASSED_TESTS=$((PASSED_TESTS + 1))
else
  echo -e "${RED}✗ FAIL${NC} (Found only $COMPONENT_COUNT components, need 30)"
  FAILED_TESTS=$((FAILED_TESTS + 1))
  FAILED_TEST_NAMES+=("At least 30 component directories")
fi

print_test "Component index exports all components"
if [ -f "src/components/index.ts" ] && [ "$(wc -l < src/components/index.ts)" -ge 40 ]; then
  print_pass
else
  print_fail "Component index missing or incomplete"
fi

print_test "Storybook configuration exists"
if [ -f ".storybook/main.ts" ] && [ -f ".storybook/preview.ts" ]; then
  print_pass
else
  print_fail "Storybook configuration not found"
fi

print_test "At least one component has Storybook stories"
if find src/components -name "*.stories.tsx" | grep -q .; then
  print_pass
else
  print_fail "No Storybook stories found"
fi

# AC3: Design tokens defined
print_header "Acceptance Criteria 3: Design tokens defined"

print_test "Design tokens directory exists"
if [ -d "src/tokens" ]; then
  print_pass
else
  print_fail "Tokens directory not found"
fi

print_test "Color tokens defined"
if [ -f "src/tokens/colors.ts" ]; then
  print_pass
else
  print_fail "Color tokens not found"
fi

print_test "Typography tokens defined"
if [ -f "src/tokens/typography.ts" ]; then
  print_pass
else
  print_fail "Typography tokens not found"
fi

print_test "Spacing tokens defined"
if [ -f "src/tokens/spacing.ts" ]; then
  print_pass
else
  print_fail "Spacing tokens not found"
fi

print_test "Additional tokens defined (shadows, radii, etc.)"
TOKEN_FILES=$(find src/tokens -name "*.ts" -not -name "index.ts" | wc -l)
if [ "$TOKEN_FILES" -ge 5 ]; then
  echo -e "${GREEN}✓ PASS${NC} (Found $TOKEN_FILES token files)"
  PASSED_TESTS=$((PASSED_TESTS + 1))
else
  echo -e "${RED}✗ FAIL${NC} (Found only $TOKEN_FILES token files)"
  FAILED_TESTS=$((FAILED_TESTS + 1))
  FAILED_TEST_NAMES+=("At least 5 token files")
fi

print_test "Global CSS with design tokens"
if [ -f "src/styles/global.css" ]; then
  print_pass
else
  print_fail "Global CSS not found"
fi

# AC4: Accessibility tested
print_header "Acceptance Criteria 4: Accessibility tested"

print_test "jest-axe dependency in package.json"
if grep -q "jest-axe" package.json; then
  print_pass
else
  print_fail "jest-axe not in dependencies"
fi

print_test "Storybook a11y addon configured"
if grep -q "@storybook/addon-a11y" package.json; then
  print_pass
else
  print_fail "Storybook a11y addon not configured"
fi

print_test "Test setup includes accessibility"
if [ -f "src/setupTests.ts" ] && grep -q "jest-axe" src/setupTests.ts; then
  print_pass
else
  print_fail "Test setup doesn't include jest-axe"
fi

print_test "At least one component has accessibility tests"
if find src/components -name "*.test.tsx" -exec grep -l "axe\|toHaveNoViolations" {} \; | grep -q .; then
  print_pass
else
  print_fail "No accessibility tests found"
fi

print_test "ESLint jsx-a11y plugin configured"
if [ -f ".eslintrc.js" ] && grep -q "jsx-a11y" .eslintrc.js; then
  print_pass
else
  print_fail "jsx-a11y plugin not configured"
fi

# AC5: Published to npm (prepared for publishing)
print_header "Acceptance Criteria 5: Ready for npm publishing"

print_test "Package has correct main entry point"
if grep -q '"main":' package.json && grep -q '"module":' package.json; then
  print_pass
else
  print_fail "Package entry points not configured"
fi

print_test "Package has TypeScript types"
if grep -q '"types":' package.json; then
  print_pass
else
  print_fail "TypeScript types not configured"
fi

print_test "Package has build script"
if grep -q '"build":' package.json; then
  print_pass
else
  print_fail "Build script not found"
fi

print_test "Package files specified"
if grep -q '"files":' package.json; then
  print_pass
else
  print_fail "Package files not specified"
fi

print_test "README.md exists with usage instructions"
if [ -f "README.md" ] && grep -q "Installation" README.md && grep -q "Usage" README.md; then
  print_pass
else
  print_fail "README.md missing or incomplete"
fi

print_test "prepublishOnly script exists"
if grep -q '"prepublishOnly":' package.json; then
  print_pass
else
  print_fail "prepublishOnly script not found"
fi

# Additional validation
print_header "Additional Validation"

print_test "Main export index exists"
if [ -f "src/index.ts" ]; then
  print_pass
else
  print_fail "Main index not found"
fi

print_test "Jest configuration exists"
if [ -f "jest.config.js" ]; then
  print_pass
else
  print_fail "Jest configuration not found"
fi

print_test "Prettier configuration exists"
if [ -f ".prettierrc" ]; then
  print_pass
else
  print_fail "Prettier configuration not found"
fi

print_test "Documentation includes introduction"
if [ -f "src/Introduction.mdx" ]; then
  print_pass
else
  print_fail "Introduction documentation not found"
fi

print_test "Dockerfile exists for Storybook deployment"
if [ -f "Dockerfile" ]; then
  print_pass
else
  print_fail "Dockerfile not found"
fi

print_test "Kubernetes deployment manifests exist"
if [ -f "../platform/apps/design-system/deployment.yaml" ]; then
  print_pass
else
  print_fail "Kubernetes deployment not found"
fi

print_test "ArgoCD application manifest exists"
if [ -f "../platform/apps/design-system-application.yaml" ]; then
  print_pass
else
  print_fail "ArgoCD application not found"
fi

# Additional validation for Design Tool Integration (Issue #92)
print_header "Design Tool Integration Validation"

print_test "Penpot deployment manifests exist"
if [ -f "../platform/apps/penpot/deployment.yaml" ]; then
  print_pass
else
  print_fail "Penpot deployment not found"
fi

print_test "Penpot ArgoCD application exists"
if [ -f "../platform/apps/penpot-application.yaml" ]; then
  print_pass
else
  print_fail "Penpot ArgoCD application not found"
fi

print_test "Backstage Penpot plugin configured"
if [ -f "../platform/apps/backstage/plugins/penpot-viewer.yaml" ]; then
  print_pass
else
  print_fail "Backstage Penpot plugin not found"
fi

print_test "Design-to-code workflow documented"
if [ -f "../docs/how-to/design-to-code-workflow.md" ]; then
  print_pass
else
  print_fail "Design-to-code workflow documentation not found"
fi

print_test "Component mapping configuration exists"
if grep -q "penpot-component-mapping" ../platform/apps/backstage/plugins/penpot-viewer.yaml; then
  print_pass
else
  print_fail "Component mapping configuration not found"
fi

print_test "Penpot database configuration exists"
if [ -f "../platform/apps/postgresql/db-penpot-cluster.yaml" ]; then
  print_pass
else
  print_fail "Penpot database configuration not found"
fi

print_test "Penpot database credentials file exists"
if [ -f "../platform/apps/postgresql/db-penpot-credentials.yaml" ]; then
  print_pass
else
  print_fail "Penpot database credentials not found"
fi

print_test "Penpot secrets use placeholder values"
if grep -q "CHANGE_ME_" ../platform/apps/penpot/deployment.yaml \
  && grep -q "CHANGE_ME_" ../platform/apps/postgresql/db-penpot-credentials.yaml; then
  print_pass
else
  print_fail "Penpot secrets should use CHANGE_ME_ placeholders"
fi

print_test "BDD feature file for Penpot integration exists"
if [ -f "../tests/bdd/features/penpot-integration.feature" ]; then
  print_pass
else
  print_fail "Penpot integration BDD tests not found"
fi

# Print summary
print_summary

# Exit with appropriate code
if [ $FAILED_TESTS -eq 0 ]; then
  echo ""
  echo -e "${GREEN}✓ AT-E3-004 PASSED${NC}"
  echo "Design System Component Library is complete and ready!"
  exit 0
else
  echo ""
  echo -e "${RED}✗ AT-E3-004 FAILED${NC}"
  echo "Please fix the failed tests above."
  exit 1
fi
