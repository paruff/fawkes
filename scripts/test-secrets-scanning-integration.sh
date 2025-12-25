#!/bin/bash
# Test script to verify secrets scanning integration
# This script validates that the configuration is correct

echo "=========================================="
echo "Fawkes Secrets Scanning Integration Test"
echo "=========================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counter
TESTS_PASSED=0
TESTS_FAILED=0

# Test function
test_check() {
    local test_name=$1
    local test_command=$2

    echo -n "Testing: $test_name ... "

    if eval "$test_command" > /dev/null 2>&1; then
        echo -e "${GREEN}PASS${NC}"
        ((TESTS_PASSED++))
        return 0
    else
        echo -e "${RED}FAIL${NC}"
        ((TESTS_FAILED++))
        return 1
    fi
}

echo "1. Checking Pre-commit Configuration"
echo "-------------------------------------"
test_check "Gitleaks hook exists in .pre-commit-config.yaml" \
    "grep -q 'gitleaks' .pre-commit-config.yaml"

test_check "detect-secrets hook exists" \
    "grep -q 'detect-secrets' .pre-commit-config.yaml"

test_check "Gitleaks configuration file exists" \
    "test -f .gitleaks.toml"

test_check "Secrets baseline file exists" \
    "test -f .secrets.baseline"

echo ""
echo "2. Checking Jenkins Pipeline Integration"
echo "-----------------------------------------"
test_check "Golden Path pipeline has secrets scan stage" \
    "grep -q 'Secrets Scan' jenkins-shared-library/vars/goldenPathPipeline.groovy"

test_check "runSecretsCheck function exists" \
    "grep -q 'runSecretsCheck' jenkins-shared-library/vars/goldenPathPipeline.groovy"

test_check "Gitleaks container in pod template" \
    "grep -q 'gitleaks' jenkins-shared-library/vars/goldenPathPipeline.groovy"

test_check "securityScan library has secrets scan" \
    "grep -q 'secretsScan' jenkins-shared-library/vars/securityScan.groovy"

echo ""
echo "3. Checking Documentation"
echo "-------------------------"
test_check "Secrets management guide exists" \
    "test -f docs/how-to/security/secrets-management.md"

test_check "PRE-COMMIT.md mentions Gitleaks" \
    "grep -q 'Gitleaks' docs/PRE-COMMIT.md"

test_check "security.md references secrets scanning" \
    "grep -q 'Automated Secret Detection' docs/security.md"

test_check "README mentions Gitleaks" \
    "grep -q 'Gitleaks' README.md"

echo ""
echo "4. Checking BDD Tests"
echo "---------------------"
test_check "Secrets scanning feature file exists" \
    "test -f tests/bdd/features/secrets-scanning.feature"

test_check "Feature has pipeline failure scenario" \
    "grep -q 'Pipeline Fails When Secrets Are Detected' tests/bdd/features/secrets-scanning.feature"

test_check "Feature has pre-commit scenario" \
    "grep -q 'Pre-commit Hook Prevents' tests/bdd/features/secrets-scanning.feature"

echo ""
echo "5. Checking Groovy Syntax"
echo "-------------------------"
python3 << 'PYEOF'
import sys

def check_balanced(filepath, char_open, char_close, name):
    with open(filepath, 'r') as f:
        content = f.read()
    open_count = content.count(char_open)
    close_count = content.count(char_close)

    if open_count == close_count:
        print(f"  ✓ {name} balanced in {filepath}")
        return True
    else:
        print(f"  ✗ {name} NOT balanced in {filepath} ({open_count} vs {close_count})")
        return False

files = [
    'jenkins-shared-library/vars/goldenPathPipeline.groovy',
    'jenkins-shared-library/vars/securityScan.groovy'
]

all_valid = True
for filepath in files:
    if not check_balanced(filepath, '{', '}', 'Braces'):
        all_valid = False
    if not check_balanced(filepath, '(', ')', 'Parentheses'):
        all_valid = False

sys.exit(0 if all_valid else 1)
PYEOF

if [ $? -eq 0 ]; then
    echo -e "${GREEN}Groovy syntax validation passed${NC}"
    ((TESTS_PASSED+=2))
else
    echo -e "${RED}Groovy syntax validation failed${NC}"
    ((TESTS_FAILED+=2))
fi

echo ""
echo "=========================================="
echo "Test Results Summary"
echo "=========================================="
echo -e "Tests Passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Tests Failed: ${RED}$TESTS_FAILED${NC}"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ All tests passed! Secrets scanning integration is complete.${NC}"
    echo ""
    echo "Next steps:"
    echo "1. Install pre-commit hooks: make pre-commit-setup"
    echo "2. Test locally: pre-commit run gitleaks --all-files"
    echo "3. Review documentation: docs/how-to/security/secrets-management.md"
    exit 0
else
    echo -e "${RED}✗ Some tests failed. Please review the output above.${NC}"
    exit 1
fi
