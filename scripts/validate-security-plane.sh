#!/usr/bin/env bash
# Security Plane Validation Script
# Validates that the security plane is properly configured

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Counters
PASSED=0
FAILED=0
WARNINGS=0

echo "🔒 Fawkes Security Plane Validation"
echo "=================================="
echo ""

# Function to print status
print_status() {
    local status=$1
    local message=$2
    
    case $status in
        "PASS")
            echo -e "${GREEN}✅ PASS${NC}: $message"
            ((PASSED++))
            ;;
        "FAIL")
            echo -e "${RED}❌ FAIL${NC}: $message"
            ((FAILED++))
            ;;
        "WARN")
            echo -e "${YELLOW}⚠️  WARN${NC}: $message"
            ((WARNINGS++))
            ;;
        "INFO")
            echo -e "ℹ️  INFO: $message"
            ;;
    esac
}

# Check 1: Security plane directory structure
echo "📂 Checking directory structure..."
if [ -d "$REPO_ROOT/.security-plane" ]; then
    print_status "PASS" "Security plane directory exists"
else
    print_status "FAIL" "Security plane directory not found"
fi

if [ -d "$REPO_ROOT/.security-plane/policies" ]; then
    print_status "PASS" "Policies directory exists"
else
    print_status "FAIL" "Policies directory not found"
fi

if [ -d "$REPO_ROOT/.security-plane/templates" ]; then
    print_status "PASS" "Templates directory exists"
else
    print_status "FAIL" "Templates directory not found"
fi

echo ""

# Check 2: Required policy files
echo "📜 Checking policy files..."
POLICY_FILES=(
    "kubernetes-security.rego"
    "dockerfile-security.rego"
    "supply-chain-security.rego"
)

for policy in "${POLICY_FILES[@]}"; do
    if [ -f "$REPO_ROOT/.security-plane/policies/$policy" ]; then
        print_status "PASS" "Policy file found: $policy"
    else
        print_status "FAIL" "Policy file missing: $policy"
    fi
done

echo ""

# Check 3: GitHub workflows
echo "⚙️  Checking GitHub workflows..."
WORKFLOW_FILES=(
    "reusable-security-scanning.yml"
    "reusable-policy-enforcement.yml"
    "reusable-sbom-generation.yml"
    "reusable-image-signing.yml"
    "security-plane-adoption.yml"
)

for workflow in "${WORKFLOW_FILES[@]}"; do
    if [ -f "$REPO_ROOT/.github/workflows/$workflow" ]; then
        print_status "PASS" "Workflow found: $workflow"
    else
        print_status "FAIL" "Workflow missing: $workflow"
    fi
done

echo ""

# Check 4: Template files
echo "📋 Checking template files..."
if [ -f "$REPO_ROOT/.security-plane/templates/secure-deployment.yaml" ]; then
    print_status "PASS" "Secure deployment template found"
else
    print_status "FAIL" "Secure deployment template missing"
fi

if [ -f "$REPO_ROOT/.security-plane/templates/Dockerfile.secure" ]; then
    print_status "PASS" "Secure Dockerfile template found"
else
    print_status "FAIL" "Secure Dockerfile template missing"
fi

echo ""

# Check 5: Documentation
echo "📖 Checking documentation..."
DOC_FILES=(
    ".security-plane/README.md"
    ".security-plane/onboarding/ONBOARDING.md"
    "docs/security-plane/reference-architecture.md"
)

for doc in "${DOC_FILES[@]}"; do
    if [ -f "$REPO_ROOT/$doc" ]; then
        print_status "PASS" "Documentation found: $doc"
    else
        print_status "WARN" "Documentation missing: $doc"
    fi
done

echo ""

# Check 6: Issue templates
echo "🎫 Checking issue templates..."
if [ -f "$REPO_ROOT/.github/ISSUE_TEMPLATE/security-vulnerability.md" ]; then
    print_status "PASS" "Security vulnerability template found"
else
    print_status "WARN" "Security vulnerability template missing"
fi

if [ -f "$REPO_ROOT/.github/ISSUE_TEMPLATE/policy-violation.md" ]; then
    print_status "PASS" "Policy violation template found"
else
    print_status "WARN" "Policy violation template missing"
fi

echo ""

# Check 7: Service template integration
echo "🔧 Checking service template integration..."
TEMPLATES=("python-service" "nodejs-service" "java-service")

for template in "${TEMPLATES[@]}"; do
    if [ -f "$REPO_ROOT/templates/$template/skeleton/.github/workflows/security.yml" ]; then
        print_status "PASS" "Security workflow in $template template"
    else
        print_status "WARN" "Security workflow missing in $template template"
    fi
done

echo ""

# Check 8: Validate policy syntax (if conftest is available)
echo "✅ Validating policy syntax..."
if command -v conftest &> /dev/null; then
    for policy in "$REPO_ROOT/.security-plane/policies/"*.rego; do
        if [ -f "$policy" ]; then
            if conftest verify "$policy" &> /dev/null; then
                print_status "PASS" "Policy syntax valid: $(basename $policy)"
            else
                print_status "FAIL" "Policy syntax invalid: $(basename $policy)"
            fi
        fi
    done
else
    print_status "INFO" "Conftest not installed - skipping policy syntax validation"
fi

echo ""

# Check 9: Validate workflow syntax
echo "🔍 Validating workflow syntax..."
if command -v yamllint &> /dev/null; then
    for workflow in "$REPO_ROOT/.github/workflows/"*.yml; do
        if [ -f "$workflow" ]; then
            if yamllint "$workflow" &> /dev/null; then
                print_status "PASS" "Workflow syntax valid: $(basename $workflow)"
            else
                print_status "WARN" "Workflow has YAML linting issues: $(basename $workflow)"
            fi
        fi
    done
else
    print_status "INFO" "yamllint not installed - skipping workflow syntax validation"
fi

echo ""

# Summary
echo "=================================="
echo "📊 Validation Summary"
echo "=================================="
echo -e "${GREEN}Passed: $PASSED${NC}"
echo -e "${RED}Failed: $FAILED${NC}"
echo -e "${YELLOW}Warnings: $WARNINGS${NC}"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}✅ Security Plane validation successful!${NC}"
    exit 0
else
    echo -e "${RED}❌ Security Plane validation failed with $FAILED error(s)${NC}"
    exit 1
fi
