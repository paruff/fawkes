#!/bin/bash
# =============================================================================
# Script: grafana-dashboards.sh
# Purpose: Validate Grafana dashboards via API
# Usage: ./tests/integration/grafana-dashboards.sh [GRAFANA_URL]
# =============================================================================

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default Grafana URL and credentials
GRAFANA_URL="${1:-http://grafana.127.0.0.1.nip.io}"
GRAFANA_USER="${GRAFANA_USER:-admin}"
GRAFANA_PASSWORD="${GRAFANA_PASSWORD:-prom-operator}"

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

# Test Grafana health
test_grafana_health() {
    log_info "Testing Grafana health endpoint..."
    
    local response=$(curl -sf "${GRAFANA_URL}/api/health" 2>/dev/null || echo '{}')
    
    if echo "$response" | grep -q '"database":"ok"'; then
        log_success "Grafana is healthy"
        return 0
    else
        log_error "Grafana health check failed"
        return 1
    fi
}

# Test Grafana datasources
test_grafana_datasources() {
    log_info "Testing Grafana datasources..."
    
    local response=$(curl -sf -u "${GRAFANA_USER}:${GRAFANA_PASSWORD}" \
        "${GRAFANA_URL}/api/datasources" 2>/dev/null || echo '[]')
    
    local datasource_count=$(echo "$response" | grep -o '"name":' | wc -l)
    
    if [ "$datasource_count" -gt 0 ]; then
        log_success "Found $datasource_count datasource(s)"
        
        # Check if Prometheus datasource exists
        if echo "$response" | grep -q '"type":"prometheus"'; then
            log_success "Prometheus datasource is configured"
        else
            log_warning "Prometheus datasource not found"
        fi
        return 0
    else
        log_error "No datasources configured"
        return 1
    fi
}

# Test Grafana dashboards
test_grafana_dashboards() {
    log_info "Testing Grafana dashboards..."
    
    local response=$(curl -sf -u "${GRAFANA_USER}:${GRAFANA_PASSWORD}" \
        "${GRAFANA_URL}/api/search?type=dash-db" 2>/dev/null || echo '[]')
    
    local dashboard_count=$(echo "$response" | grep -o '"title":' | wc -l)
    
    if [ "$dashboard_count" -gt 0 ]; then
        log_success "Found $dashboard_count dashboard(s)"
        
        # Check for specific dashboards
        if echo "$response" | grep -qi "kubernetes"; then
            log_success "Kubernetes dashboards found"
        fi
        
        if echo "$response" | grep -qi "dora"; then
            log_success "DORA metrics dashboard found"
        else
            log_info "DORA metrics dashboard not yet configured (optional)"
        fi
        
        return 0
    else
        log_warning "No dashboards found (may be imported later)"
        return 0  # Don't fail if dashboards aren't imported yet
    fi
}

# Test dashboard load time
test_dashboard_load_time() {
    log_info "Testing dashboard load performance..."
    
    # Get first dashboard UID
    local dashboards=$(curl -sf -u "${GRAFANA_USER}:${GRAFANA_PASSWORD}" \
        "${GRAFANA_URL}/api/search?type=dash-db&limit=1" 2>/dev/null || echo '[]')
    
    local uid=$(echo "$dashboards" | grep -o '"uid":"[^"]*"' | head -1 | cut -d'"' -f4)
    
    if [ -n "$uid" ]; then
        local start_time=$(date +%s%N)
        curl -sf -u "${GRAFANA_USER}:${GRAFANA_PASSWORD}" \
            "${GRAFANA_URL}/api/dashboards/uid/${uid}" >/dev/null 2>&1
        local end_time=$(date +%s%N)
        
        local load_time=$(( (end_time - start_time) / 1000000 ))  # Convert to milliseconds
        
        if [ "$load_time" -lt 2000 ]; then
            log_success "Dashboard load time: ${load_time}ms (< 2 seconds)"
            return 0
        else
            log_warning "Dashboard load time: ${load_time}ms (>= 2 seconds)"
            return 1
        fi
    else
        log_info "No dashboards available to test load time"
        return 0
    fi
}

# Test Grafana organization
test_grafana_org() {
    log_info "Testing Grafana organization..."
    
    local response=$(curl -sf -u "${GRAFANA_USER}:${GRAFANA_PASSWORD}" \
        "${GRAFANA_URL}/api/org" 2>/dev/null || echo '{}')
    
    if echo "$response" | grep -q '"name"'; then
        local org_name=$(echo "$response" | grep -o '"name":"[^"]*"' | cut -d'"' -f4)
        log_success "Grafana organization: $org_name"
        return 0
    else
        log_error "Failed to get Grafana organization"
        return 1
    fi
}

# Main execution
main() {
    echo ""
    echo "========================================================================"
    echo "  Grafana Dashboards Validation"
    echo "========================================================================"
    echo ""
    echo "  Grafana URL: $GRAFANA_URL"
    echo "  User: $GRAFANA_USER"
    echo ""
    
    local failures=0
    
    test_grafana_health || ((failures++))
    test_grafana_org || ((failures++))
    test_grafana_datasources || ((failures++))
    test_grafana_dashboards || ((failures++))
    test_dashboard_load_time || ((failures++))
    
    echo ""
    echo "========================================================================"
    
    if [ $failures -eq 0 ]; then
        echo -e "  ${GREEN}✓ All Grafana dashboard tests passed${NC}"
        echo "========================================================================"
        exit 0
    else
        echo -e "  ${RED}✗ $failures test(s) failed${NC}"
        echo "========================================================================"
        exit 1
    fi
}

main "$@"
