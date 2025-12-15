#!/bin/bash
# Trivy Integration Validation Script
# Purpose: Validate Trivy integration with Jenkins and Harbor
# Issue: #20

set -e

echo "=========================================="
echo "Trivy Integration Validation"
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
echo "1. Checking Jenkins shared library files..."
echo "----------------------------------------"

# Check securityScan.groovy exists and contains Trivy
if [ -f "jenkins-shared-library/vars/securityScan.groovy" ] && \
   grep -q "trivy image" jenkins-shared-library/vars/securityScan.groovy; then
    check_step "securityScan.groovy contains Trivy integration"
else
    false
    check_step "securityScan.groovy contains Trivy integration"
fi

# Check goldenPathPipeline.groovy exists and contains Container Security Scan
if [ -f "jenkins-shared-library/vars/goldenPathPipeline.groovy" ] && \
   grep -q "Container Security Scan" jenkins-shared-library/vars/goldenPathPipeline.groovy; then
    check_step "goldenPathPipeline.groovy includes Container Security Scan stage"
else
    false
    check_step "goldenPathPipeline.groovy includes Container Security Scan stage"
fi

# Check for Trivy container in pod template
if grep -q "name: trivy" jenkins-shared-library/vars/goldenPathPipeline.groovy; then
    check_step "Trivy sidecar container defined in pod template"
else
    false
    check_step "Trivy sidecar container defined in pod template"
fi

echo ""
echo "2. Checking Harbor integration..."
echo "----------------------------------------"

# Check Harbor application manifest exists
if [ -f "platform/apps/harbor-application.yaml" ]; then
    check_step "harbor-application.yaml exists"
else
    false
    check_step "harbor-application.yaml exists"
fi

# Check Trivy is enabled in Harbor
if [ -f "platform/apps/harbor-application.yaml" ] && \
   grep -q "trivy:" platform/apps/harbor-application.yaml && \
   grep -q "enabled: true" platform/apps/harbor-application.yaml; then
    check_step "Trivy enabled in Harbor configuration"
else
    false
    check_step "Trivy enabled in Harbor configuration"
fi

# Check Trivy resources are defined
if [ -f "platform/apps/harbor-application.yaml" ] && \
   grep -A 5 "trivy:" platform/apps/harbor-application.yaml | grep -q "resources:"; then
    check_step "Trivy resource limits configured"
else
    false
    check_step "Trivy resource limits configured"
fi

echo ""
echo "3. Checking BDD tests..."
echo "----------------------------------------"

# Check BDD feature file exists
if [ -f "tests/bdd/features/trivy-integration.feature" ]; then
    check_step "trivy-integration.feature exists"
else
    false
    check_step "trivy-integration.feature exists"
fi

# Check step definitions exist
if [ -f "tests/bdd/step_definitions/test_trivy_integration.py" ]; then
    check_step "test_trivy_integration.py exists"
else
    false
    check_step "test_trivy_integration.py exists"
fi

# Count BDD scenarios
SCENARIO_COUNT=$(grep -c '^[[:space:]]*Scenario:' tests/bdd/features/trivy-integration.feature || echo 0)
if [ "$SCENARIO_COUNT" -ge 10 ]; then
    echo -e "${GREEN}✓ BDD feature has $SCENARIO_COUNT scenarios${NC}"
    ((PASSED++))
else
    echo -e "${RED}✗ BDD feature has insufficient scenarios (found: $SCENARIO_COUNT, expected: ≥10)${NC}"
    ((FAILED++))
fi

echo ""
echo "4. Checking Grafana dashboard..."
echo "----------------------------------------"

# Check dashboard file exists
if [ -f "platform/apps/grafana/dashboards/trivy-security-dashboard.json" ]; then
    check_step "Trivy Grafana dashboard exists"
else
    false
    check_step "Trivy Grafana dashboard exists"
fi

# Check dashboard README exists
if [ -f "platform/apps/grafana/dashboards/README.md" ]; then
    check_step "Dashboard README exists"
else
    false
    check_step "Dashboard README exists"
fi

echo ""
echo "5. Checking documentation..."
echo "----------------------------------------"

# Check Trivy README exists
if [ -f "platform/apps/trivy/README.md" ]; then
    check_step "Trivy README exists"
else
    false
    check_step "Trivy README exists"
fi

# Check README has integration sections
if [ -f "platform/apps/trivy/README.md" ] && \
   grep -q "Integration with Jenkins" platform/apps/trivy/README.md && \
   grep -q "Integration with Harbor" platform/apps/trivy/README.md; then
    check_step "README documents Jenkins and Harbor integration"
else
    false
    check_step "README documents Jenkins and Harbor integration"
fi

# Check architecture doc mentions Trivy
if [ -f "docs/architecture.md" ] && grep -q -i "trivy" docs/architecture.md; then
    check_step "Architecture document mentions Trivy"
else
    false
    check_step "Architecture document mentions Trivy"
fi

echo ""
echo "6. Checking template Jenkinsfiles..."
echo "----------------------------------------"

# Check Python template
if [ -f "templates/python-service/skeleton/Jenkinsfile" ] && \
   grep -q "goldenPathPipeline" templates/python-service/skeleton/Jenkinsfile; then
    check_step "Python template uses Golden Path pipeline"
else
    false
    check_step "Python template uses Golden Path pipeline"
fi

# Check Java template
if [ -f "templates/java-service/skeleton/Jenkinsfile" ] && \
   grep -q "goldenPathPipeline" templates/java-service/skeleton/Jenkinsfile; then
    check_step "Java template uses Golden Path pipeline"
else
    false
    check_step "Java template uses Golden Path pipeline"
fi

# Check Node.js template
if [ -f "templates/nodejs-service/skeleton/Jenkinsfile" ] && \
   grep -q "goldenPathPipeline" templates/nodejs-service/skeleton/Jenkinsfile; then
    check_step "Node.js template uses Golden Path pipeline"
else
    false
    check_step "Node.js template uses Golden Path pipeline"
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
    echo "Trivy integration is complete and validated:"
    echo "  ✓ Jenkins pipelines include Trivy scanning"
    echo "  ✓ Harbor has Trivy scanner configured"
    echo "  ✓ BDD tests cover integration scenarios"
    echo "  ✓ Grafana dashboard available for visibility"
    echo "  ✓ Comprehensive documentation provided"
    echo ""
    exit 0
else
    echo ""
    echo -e "${RED}✗ Some validation checks failed${NC}"
    echo "Please review the failures above and address them."
    echo ""
    exit 1
fi
