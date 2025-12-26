#!/bin/bash

set -euo pipefail
# Security Quality Gates Validation Script
# Purpose: Validate security quality gates configuration and documentation
# Issue: #22

# Don't exit on first error - we want to collect all results
set +e

echo "=========================================="
echo "Security Quality Gates Validation"
echo "=========================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Track results
PASSED=0
FAILED=0

check_step() {
  if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ $1${NC}"
    ((PASSED++))
  else
    echo -e "${RED}✗ $1${NC}"
    ((FAILED++))
  fi
}

echo ""
echo "1. Checking SonarQube Quality Gate Configuration..."
echo "----------------------------------------"

# Check SonarQube integration in shared library
if [ -f "jenkins-shared-library/vars/securityScan.groovy" ] \
  && grep -q "waitForQualityGate" jenkins-shared-library/vars/securityScan.groovy; then
  check_step "SonarQube quality gate check implemented in securityScan.groovy"
else
  false
  check_step "SonarQube quality gate check implemented in securityScan.groovy"
fi

# Check quality gate enforcement in golden path pipeline
if [ -f "jenkins-shared-library/vars/goldenPathPipeline.groovy" ] \
  && grep -q "Quality Gate" jenkins-shared-library/vars/goldenPathPipeline.groovy \
  && grep -q "waitForQualityGate" jenkins-shared-library/vars/goldenPathPipeline.groovy; then
  check_step "Quality Gate stage exists in Golden Path pipeline"
else
  false
  check_step "Quality Gate stage exists in Golden Path pipeline"
fi

# Check for quality gate always enforced (no disable flag needed - it's always on)
if grep -q "Quality Gate" jenkins-shared-library/vars/goldenPathPipeline.groovy \
  && grep -q "waitForQualityGate" jenkins-shared-library/vars/goldenPathPipeline.groovy; then
  check_step "Quality Gate always enforced in pipeline"
else
  false
  check_step "Quality Gate always enforced in pipeline"
fi

# Check for quality gate timeout configuration
if grep -q "timeout.*MINUTES" jenkins-shared-library/vars/goldenPathPipeline.groovy \
  && grep -q "waitForQualityGate" jenkins-shared-library/vars/goldenPathPipeline.groovy; then
  check_step "Quality Gate timeout configured"
else
  false
  check_step "Quality Gate timeout configured"
fi

# Check for detailed quality gate failure messages
if grep -q "Quality Gate failed" jenkins-shared-library/vars/goldenPathPipeline.groovy \
  || grep -q "Quality Gate failed" jenkins-shared-library/vars/securityScan.groovy; then
  check_step "Detailed quality gate failure messages implemented"
else
  false
  check_step "Detailed quality gate failure messages implemented"
fi

echo ""
echo "2. Checking Trivy Quality Gate Configuration..."
echo "----------------------------------------"

# Check Trivy severity threshold configuration
if [ -f "jenkins-shared-library/vars/goldenPathPipeline.groovy" ] \
  && grep -q "trivySeverity.*HIGH,CRITICAL" jenkins-shared-library/vars/goldenPathPipeline.groovy; then
  check_step "Trivy severity threshold set to HIGH,CRITICAL by default"
else
  false
  check_step "Trivy severity threshold set to HIGH,CRITICAL by default"
fi

# Check Trivy exit code configuration
if grep -q "trivyExitCode" jenkins-shared-library/vars/goldenPathPipeline.groovy \
  || grep -q "exit-code.*1" jenkins-shared-library/vars/securityScan.groovy; then
  check_step "Trivy exit code configuration available"
else
  false
  check_step "Trivy exit code configuration available"
fi

# Check Trivy report archiving
if grep -q "archiveArtifacts.*trivy-report" jenkins-shared-library/vars/securityScan.groovy; then
  check_step "Trivy reports archived as build artifacts"
else
  false
  check_step "Trivy reports archived as build artifacts"
fi

echo ""
echo "3. Checking Secrets Scanning Configuration..."
echo "----------------------------------------"

# Check Gitleaks integration
if [ -f "jenkins-shared-library/vars/securityScan.groovy" ] \
  && grep -q "gitleaks detect" jenkins-shared-library/vars/securityScan.groovy; then
  check_step "Gitleaks secrets scanning integrated"
else
  false
  check_step "Gitleaks secrets scanning integrated"
fi

# Check for Gitleaks container in pod template
if grep -q "name: gitleaks" jenkins-shared-library/vars/goldenPathPipeline.groovy; then
  check_step "Gitleaks container defined in pod template"
else
  false
  check_step "Gitleaks container defined in pod template"
fi

echo ""
echo "4. Checking Quality Gates Documentation..."
echo "----------------------------------------"

# Check main quality gates documentation exists
if [ -f "docs/how-to/security/quality-gates-configuration.md" ]; then
  check_step "Quality gates configuration documentation exists"
else
  false
  check_step "Quality gates configuration documentation exists"
fi

# Check documentation covers SonarQube
if [ -f "docs/how-to/security/quality-gates-configuration.md" ] \
  && grep -q "SonarQube Quality Gates" docs/how-to/security/quality-gates-configuration.md; then
  check_step "Documentation covers SonarQube quality gates"
else
  false
  check_step "Documentation covers SonarQube quality gates"
fi

# Check documentation covers Trivy
if [ -f "docs/how-to/security/quality-gates-configuration.md" ] \
  && grep -q "Trivy Quality Gates" docs/how-to/security/quality-gates-configuration.md; then
  check_step "Documentation covers Trivy quality gates"
else
  false
  check_step "Documentation covers Trivy quality gates"
fi

# Check documentation covers severity thresholds
if [ -f "docs/how-to/security/quality-gates-configuration.md" ] \
  && grep -q -i "severity.*threshold" docs/how-to/security/quality-gates-configuration.md; then
  check_step "Documentation covers severity thresholds"
else
  false
  check_step "Documentation covers severity thresholds"
fi

# Check documentation covers override process
if [ -f "docs/how-to/security/quality-gates-configuration.md" ] \
  && grep -q -i "override.*process" docs/how-to/security/quality-gates-configuration.md; then
  check_step "Documentation covers override process"
else
  false
  check_step "Documentation covers override process"
fi

echo ""
echo "5. Checking Override Process Documentation..."
echo "----------------------------------------"

# Check SonarQube override documentation
if [ -f "docs/how-to/security/quality-gates-configuration.md" ] \
  && grep -q "SuppressWarnings" docs/how-to/security/quality-gates-configuration.md; then
  check_step "SonarQube inline suppression documented"
else
  false
  check_step "SonarQube inline suppression documented"
fi

# Check .trivyignore documentation
if [ -f "docs/how-to/security/quality-gates-configuration.md" ] \
  && grep -q ".trivyignore" docs/how-to/security/quality-gates-configuration.md; then
  check_step "Trivy .trivyignore override process documented"
else
  false
  check_step "Trivy .trivyignore override process documented"
fi

# Check .gitleaks.toml documentation
if [ -f "docs/how-to/security/quality-gates-configuration.md" ] \
  && grep -q ".gitleaks.toml" docs/how-to/security/quality-gates-configuration.md; then
  check_step "Gitleaks .gitleaks.toml override process documented"
else
  false
  check_step "Gitleaks .gitleaks.toml override process documented"
fi

# Check approval process documentation
if [ -f "docs/how-to/security/quality-gates-configuration.md" ] \
  && grep -q -i "approval" docs/how-to/security/quality-gates-configuration.md \
  && grep -q -i "security team" docs/how-to/security/quality-gates-configuration.md; then
  check_step "Override approval process documented"
else
  false
  check_step "Override approval process documented"
fi

echo ""
echo "6. Checking Language-Specific Examples..."
echo "----------------------------------------"

# Check Java example
if [ -f "docs/how-to/security/quality-gates-configuration.md" ] \
  && grep -q "Java Example" docs/how-to/security/quality-gates-configuration.md \
  && grep -q "pom.xml" docs/how-to/security/quality-gates-configuration.md; then
  check_step "Java-specific example documented"
else
  false
  check_step "Java-specific example documented"
fi

# Check Python example
if [ -f "docs/how-to/security/quality-gates-configuration.md" ] \
  && grep -q "Python Example" docs/how-to/security/quality-gates-configuration.md \
  && grep -q "sonar-project.properties" docs/how-to/security/quality-gates-configuration.md; then
  check_step "Python-specific example documented"
else
  false
  check_step "Python-specific example documented"
fi

# Check Node.js example
if [ -f "docs/how-to/security/quality-gates-configuration.md" ] \
  && grep -q "Node.js Example" docs/how-to/security/quality-gates-configuration.md; then
  check_step "Node.js-specific example documented"
else
  false
  check_step "Node.js-specific example documented"
fi

# Check Go example
if [ -f "docs/how-to/security/quality-gates-configuration.md" ] \
  && grep -q "Go Example" docs/how-to/security/quality-gates-configuration.md; then
  check_step "Go-specific example documented"
else
  false
  check_step "Go-specific example documented"
fi

echo ""
echo "7. Checking BDD Acceptance Tests..."
echo "----------------------------------------"

# Check BDD feature file exists
if [ -f "tests/bdd/features/security-quality-gates.feature" ]; then
  check_step "security-quality-gates.feature exists"
else
  false
  check_step "security-quality-gates.feature exists"
fi

# Count BDD scenarios
SCENARIO_COUNT=$(grep -c '^[[:space:]]*Scenario:' tests/bdd/features/security-quality-gates.feature || echo 0)
if [ "$SCENARIO_COUNT" -ge 20 ]; then
  echo -e "${GREEN}✓ BDD feature has $SCENARIO_COUNT scenarios (expected: ≥20)${NC}"
  ((PASSED++))
else
  echo -e "${RED}✗ BDD feature has insufficient scenarios (found: $SCENARIO_COUNT, expected: ≥20)${NC}"
  ((FAILED++))
fi

# Check for SonarQube quality gate tests
if [ -f "tests/bdd/features/security-quality-gates.feature" ] \
  && grep -q "@sonarqube.*@quality-gate" tests/bdd/features/security-quality-gates.feature; then
  check_step "BDD tests include SonarQube quality gate scenarios"
else
  false
  check_step "BDD tests include SonarQube quality gate scenarios"
fi

# Check for Trivy severity threshold tests
if [ -f "tests/bdd/features/security-quality-gates.feature" ] \
  && grep -q "@trivy.*@severity-threshold" tests/bdd/features/security-quality-gates.feature; then
  check_step "BDD tests include Trivy severity threshold scenarios"
else
  false
  check_step "BDD tests include Trivy severity threshold scenarios"
fi

# Check for override process tests
if [ -f "tests/bdd/features/security-quality-gates.feature" ] \
  && grep -q "@override" tests/bdd/features/security-quality-gates.feature; then
  check_step "BDD tests include override process scenarios"
else
  false
  check_step "BDD tests include override process scenarios"
fi

echo ""
echo "8. Checking ADR Documentation..."
echo "----------------------------------------"

# Check ADR-014 exists (SonarQube quality gates)
if [ -f "docs/adr/ADR-014 sonarqube quality gates.md" ]; then
  check_step "ADR-014 SonarQube quality gates exists"
else
  false
  check_step "ADR-014 SonarQube quality gates exists"
fi

# Check ADR mentions quality gate thresholds
if [ -f "docs/adr/ADR-014 sonarqube quality gates.md" ] \
  && grep -q "Quality Gate" "docs/adr/ADR-014 sonarqube quality gates.md"; then
  check_step "ADR-014 documents quality gate strategy"
else
  false
  check_step "ADR-014 documents quality gate strategy"
fi

echo ""
echo "9. Checking Common Failure Scenarios Documentation..."
echo "----------------------------------------"

# Check documentation includes failure scenarios
if [ -f "docs/how-to/security/quality-gates-configuration.md" ] \
  && grep -q "Common Failure Scenarios" docs/how-to/security/quality-gates-configuration.md; then
  check_step "Common failure scenarios documented"
else
  false
  check_step "Common failure scenarios documented"
fi

# Check remediation guidance
if [ -f "docs/how-to/security/quality-gates-configuration.md" ] \
  && grep -q "Remediation" docs/how-to/security/quality-gates-configuration.md; then
  check_step "Remediation guidance provided"
else
  false
  check_step "Remediation guidance provided"
fi

echo ""
echo "10. Checking Best Practices Documentation..."
echo "----------------------------------------"

# Check for DO/DON'T guidance
if [ -f "docs/how-to/security/quality-gates-configuration.md" ] \
  && grep -q "DO ✅" docs/how-to/security/quality-gates-configuration.md \
  && grep -q "DON'T ❌" docs/how-to/security/quality-gates-configuration.md; then
  check_step "Best practices (DO/DON'T) documented"
else
  false
  check_step "Best practices (DO/DON'T) documented"
fi

# Check for support contacts
if [ -f "docs/how-to/security/quality-gates-configuration.md" ] \
  && grep -q "Support" docs/how-to/security/quality-gates-configuration.md; then
  check_step "Support contacts and resources documented"
else
  false
  check_step "Support contacts and resources documented"
fi

echo ""
echo "=========================================="
echo "VALIDATION SUMMARY"
echo "=========================================="
echo -e "${GREEN}Passed: $PASSED${NC}"
echo -e "${RED}Failed: $FAILED${NC}"
echo "Total: $((PASSED + FAILED))"

if [ $FAILED -eq 0 ]; then
  echo ""
  echo -e "${GREEN}✓ All validation checks passed!${NC}"
  echo ""
  echo "Security quality gates are fully configured:"
  echo "  ✓ SonarQube quality gates configured and enforced"
  echo "  ✓ Trivy severity thresholds configured"
  echo "  ✓ Secrets scanning enforced with Gitleaks"
  echo "  ✓ Override processes documented and approved"
  echo "  ✓ Language-specific examples provided"
  echo "  ✓ BDD acceptance tests comprehensive"
  echo "  ✓ Common failures and remediation documented"
  echo ""
  exit 0
else
  echo ""
  echo -e "${RED}✗ Some validation checks failed${NC}"
  echo "Please review the failures above and address them."
  echo ""
  exit 1
fi
