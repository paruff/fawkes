#!/bin/bash
# =============================================================================
# Script: sonarqube-check.sh
# Purpose: Integration test for SonarQube API and functionality
# Usage: ./tests/integration/sonarqube-check.sh [SONARQUBE_URL]
# =============================================================================

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SONARQUBE_URL="${1:-http://sonarqube.127.0.0.1.nip.io}"
TIMEOUT=10

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

# Track test results
PASSED=0
FAILED=0

check_test() {
    if [ $? -eq 0 ]; then
        log_success "$1"
        ((PASSED++))
    else
        log_error "$1"
        ((FAILED++))
    fi
}

echo ""
log_info "=============================================="
log_info "SonarQube Integration Test"
log_info "=============================================="
log_info "SonarQube URL: $SONARQUBE_URL"
echo ""

# Test 1: Check if SonarQube is accessible
log_info "Test 1: Checking SonarQube accessibility..."
if curl -f -s --connect-timeout $TIMEOUT "$SONARQUBE_URL/api/system/health" &> /dev/null; then
    check_test "SonarQube health endpoint accessible"
else
    log_warning "SonarQube health endpoint not accessible (may require port-forward)"
    log_info "Try: kubectl port-forward -n fawkes svc/sonarqube 9000:9000"
    false
    check_test "SonarQube health endpoint accessible"
fi

# Test 2: Check system status
log_info "Test 2: Checking SonarQube system status..."
if command -v jq &> /dev/null; then
    HEALTH_STATUS=$(curl -f -s --connect-timeout $TIMEOUT "$SONARQUBE_URL/api/system/health" 2>/dev/null | jq -r '.health' || echo "UNKNOWN")
    if [ "$HEALTH_STATUS" = "GREEN" ] || [ "$HEALTH_STATUS" = "YELLOW" ]; then
        check_test "SonarQube health status: $HEALTH_STATUS"
    else
        false
        check_test "SonarQube health status: $HEALTH_STATUS (expected GREEN or YELLOW)"
    fi
else
    log_warning "jq not installed, skipping health status check"
fi

# Test 3: Check system info
log_info "Test 3: Checking SonarQube system info..."
if curl -f -s --connect-timeout $TIMEOUT "$SONARQUBE_URL/api/system/info" &> /dev/null; then
    check_test "SonarQube system info endpoint accessible"
else
    false
    check_test "SonarQube system info endpoint accessible"
fi

# Test 4: Check if quality gates exist
log_info "Test 4: Checking quality gates configuration..."
if curl -f -s --connect-timeout $TIMEOUT "$SONARQUBE_URL/api/qualitygates/list" &> /dev/null; then
    check_test "SonarQube quality gates endpoint accessible"
    
    if command -v jq &> /dev/null; then
        QG_COUNT=$(curl -f -s --connect-timeout $TIMEOUT "$SONARQUBE_URL/api/qualitygates/list" 2>/dev/null | jq '.qualitygates | length' || echo "0")
        if [ "$QG_COUNT" -gt 0 ]; then
            log_success "Found $QG_COUNT quality gate(s)"
        else
            log_warning "No quality gates found (may need authentication)"
        fi
    fi
else
    false
    check_test "SonarQube quality gates endpoint accessible"
fi

# Test 5: Check authentication requirement
log_info "Test 5: Checking authentication configuration..."
RESPONSE=$(curl -s --connect-timeout $TIMEOUT "$SONARQUBE_URL/api/authentication/validate" || echo "{}")
if echo "$RESPONSE" | grep -q "valid"; then
    log_success "Authentication endpoint responding"
else
    log_warning "Authentication endpoint may require credentials"
fi

# Test 6: Check if SonarQube plugins are loaded
log_info "Test 6: Checking SonarQube plugins..."
if curl -f -s --connect-timeout $TIMEOUT "$SONARQUBE_URL/api/plugins/installed" &> /dev/null; then
    check_test "SonarQube plugins endpoint accessible"
    
    if command -v jq &> /dev/null; then
        PLUGIN_COUNT=$(curl -f -s --connect-timeout $TIMEOUT "$SONARQUBE_URL/api/plugins/installed" 2>/dev/null | jq '.plugins | length' || echo "0")
        if [ "$PLUGIN_COUNT" -gt 0 ]; then
            log_success "Found $PLUGIN_COUNT installed plugin(s)"
        fi
    fi
else
    false
    check_test "SonarQube plugins endpoint accessible"
fi

# Test 7: Check metrics endpoint (for Prometheus integration)
log_info "Test 7: Checking metrics endpoint..."
if curl -f -s --connect-timeout $TIMEOUT "$SONARQUBE_URL/api/monitoring/metrics" &> /dev/null; then
    check_test "SonarQube metrics endpoint accessible"
else
    log_warning "Metrics endpoint not accessible (may require authentication or plugin)"
fi

# Test 8: Verify web interface loads
log_info "Test 8: Checking web interface..."
if curl -f -s --connect-timeout $TIMEOUT "$SONARQUBE_URL/" | grep -q "SonarQube"; then
    check_test "SonarQube web interface loads"
else
    false
    check_test "SonarQube web interface loads"
fi

# Summary
echo ""
log_info "=============================================="
log_info "Test Summary"
log_info "=============================================="
log_info "Total Tests: $((PASSED + FAILED))"
log_success "Passed: $PASSED"
log_error "Failed: $FAILED"
echo ""

if [ $FAILED -eq 0 ]; then
    log_success "All SonarQube integration tests passed!"
    exit 0
else
    log_error "Some SonarQube integration tests failed"
    exit 1
fi
