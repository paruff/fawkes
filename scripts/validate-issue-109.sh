#!/usr/bin/env bash

set -euo pipefail
# Validation script for Issue #109 - Code Quality Standards and Linting
set -uo pipefail # Removed -e to allow script to continue on errors

echo "=========================================="
echo "Validating Code Quality Standards (Issue #109)"
echo "=========================================="
echo ""

# Track validation results
PASSED=0
FAILED=0

validate_file() {
  local file=$1
  local description=$2

  if [ -f "$file" ]; then
    echo "✅ PASS: $description"
    ((PASSED++))
  else
    echo "❌ FAIL: $description - File not found: $file"
    ((FAILED++))
  fi
}

validate_command() {
  local cmd=$1
  local description=$2

  if command -v "$cmd" &> /dev/null || which "$cmd" &> /dev/null; then
    echo "✅ PASS: $description"
    ((PASSED++))
  else
    echo "⚠️  SKIP: $description - Command not available (optional for contributors)"
    # Don't count as failure - not all developers need all tools installed
  fi
}

validate_config() {
  local config=$1
  local pattern=$2
  local description=$3

  if grep -q "$pattern" "$config"; then
    echo "✅ PASS: $description"
    ((PASSED++))
  else
    echo "❌ FAIL: $description"
    ((FAILED++))
  fi
}

echo "## 1. Linting Rules Defined for All Languages"
echo "----------------------------------------------"
validate_config ".pre-commit-config.yaml" "shellcheck" "Bash linting configured (ShellCheck)"
validate_config ".pre-commit-config.yaml" "black" "Python formatting configured (Black)"
validate_config ".pre-commit-config.yaml" "flake8" "Python linting configured (Flake8)"
validate_config ".pre-commit-config.yaml" "golangci-lint" "Go linting configured (golangci-lint)"
validate_config ".pre-commit-config.yaml" "yamllint" "YAML linting configured (yamllint)"
validate_config ".pre-commit-config.yaml" "check-json" "JSON linting configured (check-json)"
validate_config ".pre-commit-config.yaml" "markdownlint" "Markdown linting configured (markdownlint)"
validate_config ".pre-commit-config.yaml" "terraform_fmt" "Terraform formatting configured"
validate_config ".pre-commit-config.yaml" "terraform_tflint" "Terraform linting configured (TFLint)"
validate_file ".golangci.yml" "Go linting configuration file exists"
validate_file ".yamllint" "YAML linting configuration file exists"
validate_file ".markdownlint.json" "Markdown linting configuration file exists"
validate_file ".tflint.hcl" "Terraform linting configuration file exists"
echo ""

echo "## 2. Pre-commit Hooks Configured"
echo "----------------------------------------------"
validate_file ".pre-commit-config.yaml" "Pre-commit configuration exists"
validate_file ".git/hooks/pre-commit" "Pre-commit hooks installed"
echo ""

echo "## 3. CI/CD Quality Gates"
echo "----------------------------------------------"
validate_file ".github/workflows/pre-commit.yml" "CI/CD pre-commit workflow exists"
validate_config ".github/workflows/pre-commit.yml" "pre-commit run" "CI/CD runs pre-commit checks"
validate_config ".github/workflows/pre-commit.yml" "Setup Terraform" "CI/CD has Terraform setup"
validate_config ".github/workflows/pre-commit.yml" "Setup kubectl" "CI/CD has Kubernetes tools setup"
echo ""

echo "## 4. Security Scanning"
echo "----------------------------------------------"
validate_config ".pre-commit-config.yaml" "gitleaks" "Secrets scanning configured (Gitleaks)"
validate_config ".pre-commit-config.yaml" "detect-secrets" "Secrets scanning configured (detect-secrets)"
validate_config ".pre-commit-config.yaml" "terraform_tfsec" "Terraform security scanning configured (tfsec)"
validate_file ".gitleaks.toml" "Gitleaks configuration exists"
validate_file ".secrets.baseline" "detect-secrets baseline exists"
echo ""

echo "## 5. Developer Setup Guide"
echo "----------------------------------------------"
validate_file "docs/how-to/development/code-quality-standards.md" "Comprehensive code quality standards guide"
validate_file "docs/PRE-COMMIT.md" "Pre-commit setup guide"
validate_file "docs/how-to/security/quality-gates-configuration.md" "Quality gates configuration guide"
validate_config "Makefile" "pre-commit-setup" "Makefile has pre-commit-setup target"
validate_config "Makefile" "lint" "Makefile has lint target"
validate_config "README.md" "make pre-commit-setup" "README mentions pre-commit setup"
validate_config "docs/contributing.md" "Code Quality" "Contributing guide mentions code quality"
validate_config "docs/development.md" "make lint" "Development guide mentions linting"
echo ""

echo "## 6. Documentation Coverage"
echo "----------------------------------------------"
echo "Checking code quality standards documentation completeness..."
DOC="docs/how-to/development/code-quality-standards.md"
if [ -f "$DOC" ]; then
  validate_config "$DOC" "Bash" "Bash standards documented"
  validate_config "$DOC" "Python" "Python standards documented"
  validate_config "$DOC" "Go" "Go standards documented"
  validate_config "$DOC" "YAML" "YAML standards documented"
  validate_config "$DOC" "JSON" "JSON standards documented"
  validate_config "$DOC" "Markdown" "Markdown standards documented"
  validate_config "$DOC" "Terraform" "Terraform standards documented"
  validate_config "$DOC" "IDE Integration" "IDE integration documented"
  validate_config "$DOC" "VS Code" "VS Code integration documented"
  validate_config "$DOC" "Common Issues\|Troubleshooting" "Troubleshooting section included"
  validate_config "$DOC" "Common Issues" "Common issues documented"
fi
echo ""

echo "## 7. Makefile Targets"
echo "----------------------------------------------"
validate_config "Makefile" "^lint:" "lint target defined"
validate_config "Makefile" "^pre-commit-setup:" "pre-commit-setup target defined"
validate_config "Makefile" "^terraform-validate:" "terraform-validate target defined"
validate_config "Makefile" "^validate:" "validate target defined"
echo ""

echo "## 8. Optional Tools Check (for developers)"
echo "----------------------------------------------"
echo "Note: These are optional - developers can contribute without all tools installed"
validate_command "pre-commit" "pre-commit installed"
validate_command "black" "Black formatter available"
validate_command "flake8" "Flake8 linter available"
validate_command "shellcheck" "ShellCheck available"
validate_command "yamllint" "yamllint available"
validate_command "terraform" "Terraform available"
validate_command "tflint" "TFLint available"
echo ""

echo "=========================================="
echo "Validation Summary"
echo "=========================================="
echo "✅ PASSED: $PASSED"
echo "❌ FAILED: $FAILED"
echo ""

if [ $FAILED -eq 0 ]; then
  echo "🎉 SUCCESS: All code quality standards validations passed!"
  echo ""
  echo "Acceptance Criteria Status:"
  echo "  ✅ Linting rules defined for all languages"
  echo "  ✅ Pre-commit hooks configured"
  echo "  ✅ CI/CD quality gates"
  echo "  ✅ Developer setup guide complete"
  echo "  ⏳ All code passes linting (run 'make lint' to check)"
  echo ""
  echo "To complete setup:"
  echo "  1. Run: make pre-commit-setup"
  echo "  2. Run: make lint"
  echo "  3. Install optional tools as needed (see docs)"
  exit 0
else
  echo "❌ FAILURE: $FAILED validation(s) failed"
  exit 1
fi
