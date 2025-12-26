#!/usr/bin/env bash

set -euo pipefail
# Validation script for Issue #111: Code Quality CI/CD Pipeline
# This script validates that the code quality pipeline is properly implemented

set -eo pipefail  # Exit on error, pipe failures (but allow unset variables for flexibility)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Counters
PASSED=0
FAILED=0
WARNINGS=0

# Helper functions
pass() {
    echo -e "${GREEN}✅ PASS${NC}: $1"
    PASSED=$((PASSED + 1))
}

fail() {
    echo -e "${RED}❌ FAIL${NC}: $1"
    FAILED=$((FAILED + 1))
}

warn() {
    echo -e "${YELLOW}⚠️  WARN${NC}: $1"
    WARNINGS=$((WARNINGS + 1))
}

section() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  $1"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# Validate workflow file exists and is valid YAML
validate_workflow() {
    section "1. Validating Code Quality Workflow"
    
    if [ -f ".github/workflows/code-quality.yml" ]; then
        pass "Code quality workflow file exists"
    else
        fail "Code quality workflow file not found"
        return 0  # Continue validation
    fi
    
    # Validate YAML syntax (simple check - just try to parse with Python if available)
    if command -v python &> /dev/null; then
        if python -c "import yaml; yaml.safe_load(open('.github/workflows/code-quality.yml'))" &> /dev/null; then
            pass "Workflow YAML syntax is valid"
        else
            warn "Could not validate YAML syntax with Python"
        fi
    else
        warn "Python not available, skipping YAML validation"
    fi
    
    # Check workflow name
    if grep -q "name: Code Quality" .github/workflows/code-quality.yml; then
        pass "Workflow has correct name"
    else
        fail "Workflow name is incorrect"
    fi
    
    return 0
}

# Validate all required jobs are present
validate_jobs() {
    section "2. Validating Workflow Jobs"
    
    required_jobs=(
        "python-quality"
        "python-coverage"
        "typescript-quality"
        "go-quality"
        "shell-quality"
        "security-integration"
        "quality-summary"
    )
    
    for job in "${required_jobs[@]}"; do
        if grep -q "^  ${job}:" .github/workflows/code-quality.yml; then
            pass "Job '$job' exists in workflow"
        else
            fail "Job '$job' missing from workflow"
        fi
    done
}

# Validate linters are configured
validate_linters() {
    section "3. Validating Linter Configuration"
    
    # Python linters
    linters=(
        "black"
        "flake8"
        "mypy"
        "pylint"
    )
    
    for linter in "${linters[@]}"; do
        if grep -q "$linter" .github/workflows/code-quality.yml; then
            pass "Python linter '$linter' configured in workflow"
        else
            warn "Python linter '$linter' not found in workflow"
        fi
    done
    
    # Other language linters
    if grep -q "golangci-lint" .github/workflows/code-quality.yml; then
        pass "Go linter (golangci-lint) configured"
    else
        warn "Go linter not found in workflow"
    fi
    
    if grep -q "ShellCheck" .github/workflows/code-quality.yml || grep -q "shellcheck" .github/workflows/code-quality.yml; then
        pass "Shell linter (ShellCheck) configured"
    else
        warn "Shell linter not found in workflow"
    fi
    
    if grep -q "ESLint" .github/workflows/code-quality.yml || grep -q "eslint" .github/workflows/code-quality.yml; then
        pass "TypeScript/JavaScript linter (ESLint) configured"
    else
        warn "TypeScript/JavaScript linter not found in workflow"
    fi
}

# Validate coverage configuration
validate_coverage() {
    section "4. Validating Test Coverage Configuration"
    
    # Check .coveragerc
    if [ -f ".coveragerc" ]; then
        pass ".coveragerc configuration file exists"
        
        if grep -q "branch = True" .coveragerc; then
            pass "Branch coverage enabled"
        else
            warn "Branch coverage not explicitly enabled"
        fi
        
        if grep -q "\[report\]" .coveragerc; then
            pass "Report configuration section exists"
        else
            warn "Report configuration section missing"
        fi
    else
        fail ".coveragerc configuration file not found"
    fi
    
    # Check pytest.ini coverage settings
    if [ -f "tests/pytest.ini" ]; then
        pass "pytest.ini configuration exists"
        
        if grep -q "cov" tests/pytest.ini; then
            pass "Coverage configuration in pytest.ini"
        else
            warn "Coverage not configured in pytest.ini"
        fi
    else
        warn "pytest.ini not found in tests directory"
    fi
    
    # Check workflow has coverage reporting
    if grep -q "pytest-cov\|--cov" .github/workflows/code-quality.yml; then
        pass "Coverage reporting configured in workflow"
    else
        fail "Coverage reporting not found in workflow"
    fi
    
    # Check coverage threshold
    if grep -q "cov-fail-under" .github/workflows/code-quality.yml; then
        threshold=$(grep -o "cov-fail-under=[0-9]*" .github/workflows/code-quality.yml | head -1 | cut -d= -f2)
        if [ -n "$threshold" ] && [ "$threshold" -ge 60 ]; then
            pass "Coverage threshold set to ${threshold}%"
        else
            warn "Coverage threshold should be at least 60%"
        fi
    else
        warn "Coverage threshold not explicitly set"
    fi
}

# Validate security scanning integration
validate_security() {
    section "5. Validating Security Scanning Integration"
    
    # Check security workflow exists
    if [ -f ".github/workflows/security-and-terraform.yml" ]; then
        pass "Security workflow exists"
    else
        fail "Security workflow not found"
    fi
    
    # Check Gitleaks configuration
    if [ -f ".gitleaks.toml" ]; then
        pass "Gitleaks configuration exists"
    else
        warn "Gitleaks configuration not found"
    fi
    
    # Check pre-commit security hooks
    if [ -f ".pre-commit-config.yaml" ]; then
        pass "Pre-commit configuration exists"
        
        if grep -q "gitleaks" .pre-commit-config.yaml; then
            pass "Gitleaks hook configured in pre-commit"
        else
            warn "Gitleaks not configured in pre-commit"
        fi
        
        if grep -q "detect-secrets" .pre-commit-config.yaml; then
            pass "detect-secrets hook configured in pre-commit"
        else
            warn "detect-secrets not configured in pre-commit"
        fi
    else
        fail "Pre-commit configuration not found"
    fi
    
    # Check security integration job in quality workflow
    if grep -q "security-integration" .github/workflows/code-quality.yml; then
        pass "Security integration check in quality workflow"
    else
        warn "Security integration check not found in workflow"
    fi
}

# Validate quality badges in README
validate_badges() {
    section "6. Validating Quality Badges in README"
    
    if [ ! -f "README.md" ]; then
        fail "README.md not found"
        return 1
    fi
    
    # Check for workflow badges
    badges=(
        "code-quality.yml"
        "pre-commit.yml"
        "security-and-terraform.yml"
    )
    
    for badge in "${badges[@]}"; do
        if grep -q "$badge" README.md; then
            pass "Badge for '$badge' present in README"
        else
            warn "Badge for '$badge' not found in README"
        fi
    done
    
    # Check for coverage badge
    if grep -q "coverage" README.md; then
        pass "Coverage badge present in README"
    else
        warn "Coverage badge not found in README"
    fi
}

# Validate documentation
validate_documentation() {
    section "7. Validating Documentation"
    
    # Check GitHub Actions workflows documentation
    if [ -f "docs/how-to/development/github-actions-workflows.md" ]; then
        pass "GitHub Actions workflows documentation exists"
    else
        fail "GitHub Actions workflows documentation not found"
    fi
    
    # Check code quality standards documentation
    if [ -f "docs/how-to/development/code-quality-standards.md" ]; then
        pass "Code quality standards documentation exists"
    else
        warn "Code quality standards documentation not found"
    fi
    
    # Check mkdocs navigation includes new documentation
    if [ -f "mkdocs.yml" ]; then
        if grep -q "github-actions-workflows.md" mkdocs.yml; then
            pass "New documentation added to mkdocs navigation"
        else
            warn "New documentation not added to mkdocs navigation"
        fi
    else
        warn "mkdocs.yml not found"
    fi
}

# Validate Makefile targets
validate_makefile() {
    section "8. Validating Makefile Targets"
    
    if [ ! -f "Makefile" ]; then
        fail "Makefile not found"
        return 1
    fi
    
    # Check for lint target
    if grep -q "^lint:" Makefile; then
        pass "Makefile has 'lint' target"
    else
        warn "Makefile missing 'lint' target"
    fi
    
    # Check for pre-commit-setup target
    if grep -q "^pre-commit-setup:" Makefile; then
        pass "Makefile has 'pre-commit-setup' target"
    else
        warn "Makefile missing 'pre-commit-setup' target"
    fi
}

# Validate workflow triggers
validate_triggers() {
    section "9. Validating Workflow Triggers"
    
    # Check pull_request trigger
    if grep -q "pull_request:" .github/workflows/code-quality.yml; then
        pass "Workflow triggers on pull_request"
    else
        fail "Workflow does not trigger on pull_request"
    fi
    
    # Check push trigger
    if grep -q "push:" .github/workflows/code-quality.yml; then
        pass "Workflow triggers on push"
    else
        warn "Workflow does not trigger on push"
    fi
    
    # Check workflow_dispatch
    if grep -q "workflow_dispatch:" .github/workflows/code-quality.yml; then
        pass "Workflow can be manually triggered"
    else
        warn "Workflow cannot be manually triggered"
    fi
}

# Validate permissions
validate_permissions() {
    section "10. Validating Workflow Permissions"
    
    if grep -q "permissions:" .github/workflows/code-quality.yml; then
        pass "Workflow permissions defined"
        
        # Check for security-events write permission
        if grep -A 5 "permissions:" .github/workflows/code-quality.yml | grep -q "security-events: write"; then
            pass "Security events write permission set"
        else
            warn "Security events write permission not set"
        fi
        
        # Check for pull-requests write permission
        if grep -A 5 "permissions:" .github/workflows/code-quality.yml | grep -q "pull-requests: write"; then
            pass "Pull requests write permission set"
        else
            warn "Pull requests write permission not set"
        fi
    else
        warn "Workflow permissions not defined"
    fi
}

# Main execution
main() {
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║  Issue #111: Code Quality CI/CD Pipeline - Validation         ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""
    
    validate_workflow
    validate_jobs
    validate_linters
    validate_coverage
    validate_security
    validate_badges
    validate_documentation
    validate_makefile
    validate_triggers
    validate_permissions
    
    # Summary
    section "Validation Summary"
    echo ""
    echo "Results:"
    echo -e "  ${GREEN}Passed:${NC}   $PASSED"
    echo -e "  ${RED}Failed:${NC}   $FAILED"
    echo -e "  ${YELLOW}Warnings:${NC} $WARNINGS"
    echo ""
    
    if [ $FAILED -eq 0 ]; then
        echo -e "${GREEN}✅ All critical checks passed!${NC}"
        echo ""
        echo "Next steps:"
        echo "  1. Create a PR to test the workflow"
        echo "  2. Verify workflow runs successfully"
        echo "  3. Check that badges appear correctly"
        echo "  4. Review coverage reports"
        echo ""
        exit 0
    else
        echo -e "${RED}❌ Some critical checks failed. Please review and fix.${NC}"
        echo ""
        exit 1
    fi
}

# Run main
main
