#!/bin/bash
# =============================================================================
# Script: validate-dora-dashboard.sh
# Purpose: Validate DORA metrics dashboard JSON structure and acceptance criteria
# Usage: ./tests/integration/validate-dora-dashboard.sh
# =============================================================================

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

DASHBOARD_FILE="platform/apps/grafana/dashboards/dora-metrics-dashboard.json"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

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

# Test 1: JSON validity
test_json_validity() {
    log_info "Testing JSON validity..."

    # Try jq first (more common in CI), fallback to python3
    if command -v jq &> /dev/null; then
        if jq empty "$REPO_ROOT/$DASHBOARD_FILE" > /dev/null 2>&1; then
            log_success "Dashboard JSON is valid (validated with jq)"
            return 0
        else
            log_error "Dashboard JSON is invalid"
            return 1
        fi
    elif command -v python3 &> /dev/null; then
        if python3 -m json.tool "$REPO_ROOT/$DASHBOARD_FILE" > /dev/null 2>&1; then
            log_success "Dashboard JSON is valid (validated with python3)"
            return 0
        else
            log_error "Dashboard JSON is invalid"
            return 1
        fi
    else
        log_error "Neither jq nor python3 available for JSON validation"
        return 1
    fi
}

# Test 2: All 4 key metrics present
test_four_key_metrics() {
    log_info "Testing presence of 4 key DORA metrics..."

    local metrics_found=0

    if grep -q "Deployment Frequency" "$REPO_ROOT/$DASHBOARD_FILE"; then
        ((metrics_found++))
    fi

    if grep -q "Lead Time for Changes" "$REPO_ROOT/$DASHBOARD_FILE"; then
        ((metrics_found++))
    fi

    if grep -q "Change Failure Rate" "$REPO_ROOT/$DASHBOARD_FILE"; then
        ((metrics_found++))
    fi

    if grep -q "Mean Time to Restore" "$REPO_ROOT/$DASHBOARD_FILE"; then
        ((metrics_found++))
    fi

    if [ "$metrics_found" -eq 4 ]; then
        log_success "All 4 key DORA metrics found"
        return 0
    else
        log_error "Only $metrics_found out of 4 key metrics found"
        return 1
    fi
}

# Test 3: Team-level filtering available
test_team_filtering() {
    log_info "Testing team-level filtering..."

    if grep -q '"name": "team"' "$REPO_ROOT/$DASHBOARD_FILE"; then
        log_success "Team filter template variable found"

        # Check if team filter is used in queries
        if grep -q 'team=~' "$REPO_ROOT/$DASHBOARD_FILE"; then
            log_success "Team filter is used in metric queries"
            return 0
        else
            log_warning "Team filter exists but not used in queries"
            return 1
        fi
    else
        log_error "Team filter template variable not found"
        return 1
    fi
}

# Test 4: 30-day trending visible
test_30day_trending() {
    log_info "Testing 30-day default time range..."

    if grep -q '"from": "now-30d"' "$REPO_ROOT/$DASHBOARD_FILE"; then
        log_success "Default time range set to 30 days"
        return 0
    else
        log_error "Default time range is not 30 days"
        return 1
    fi
}

# Test 5: Benchmark comparison included
test_benchmark_comparison() {
    log_info "Testing benchmark comparison panel..."

    if grep -q "Benchmark" "$REPO_ROOT/$DASHBOARD_FILE"; then
        log_success "Benchmark comparison panel found"

        # Check for performance levels
        if grep -q "Elite" "$REPO_ROOT/$DASHBOARD_FILE" && \
           grep -q "High" "$REPO_ROOT/$DASHBOARD_FILE" && \
           grep -q "Medium" "$REPO_ROOT/$DASHBOARD_FILE" && \
           grep -q "Low" "$REPO_ROOT/$DASHBOARD_FILE"; then
            log_success "All DORA performance levels included"
            return 0
        else
            log_warning "Some DORA performance levels missing"
            return 1
        fi
    else
        log_error "Benchmark comparison panel not found"
        return 1
    fi
}

# Test 6: Environment filtering
test_environment_filtering() {
    log_info "Testing environment filtering..."

    if grep -q '"name": "environment"' "$REPO_ROOT/$DASHBOARD_FILE"; then
        log_success "Environment filter template variable found"
        return 0
    else
        log_warning "Environment filter template variable not found"
        return 1
    fi
}

# Test 7: Service filtering
test_service_filtering() {
    log_info "Testing service filtering..."

    if grep -q '"name": "service"' "$REPO_ROOT/$DASHBOARD_FILE"; then
        log_success "Service filter template variable found"

        # Check if service filter query references team filter (cascading)
        if grep -q 'label_values.*team=~' "$REPO_ROOT/$DASHBOARD_FILE"; then
            log_success "Service filter is cascaded from team filter"
        else
            log_warning "Service filter does not cascade from team filter"
        fi
        return 0
    else
        log_error "Service filter template variable not found"
        return 1
    fi
}

# Test 8: Panel count
test_panel_count() {
    log_info "Testing panel count..."

    # Use jq if available for accurate counting, otherwise use grep
    local panel_count
    if command -v jq &> /dev/null; then
        panel_count=$(jq '[.dashboard.panels // [] | .[] | select(has("id"))] | length' "$REPO_ROOT/$DASHBOARD_FILE" 2>/dev/null || echo "0")
    else
        panel_count=$(grep -c '"id": [0-9]*' "$REPO_ROOT/$DASHBOARD_FILE" || echo "0")
    fi

    if [ "$panel_count" -ge 15 ]; then
        log_success "Dashboard has $panel_count panels (>= 15 expected)"
        return 0
    else
        log_warning "Dashboard has only $panel_count panels (< 15 expected)"
        return 1
    fi
}

# Main execution
main() {
    echo ""
    echo "========================================================================"
    echo "  DORA Metrics Dashboard Validation"
    echo "========================================================================"
    echo ""
    echo "  Dashboard: $DASHBOARD_FILE"
    echo ""

    if [ ! -f "$REPO_ROOT/$DASHBOARD_FILE" ]; then
        log_error "Dashboard file not found: $REPO_ROOT/$DASHBOARD_FILE"
        exit 1
    fi

    local failures=0

    # Run all tests
    test_json_validity || ((failures++))
    test_four_key_metrics || ((failures++))
    test_team_filtering || ((failures++))
    test_30day_trending || ((failures++))
    test_benchmark_comparison || ((failures++))
    test_environment_filtering || ((failures++))
    test_service_filtering || ((failures++))
    test_panel_count || ((failures++))

    echo ""
    echo "========================================================================"
    echo "  Acceptance Criteria Validation"
    echo "========================================================================"
    echo ""

    # Map to acceptance criteria
    log_info "Acceptance Criteria Status:"
    echo ""

    if grep -q "Deployment Frequency" "$REPO_ROOT/$DASHBOARD_FILE" && \
       grep -q "Lead Time for Changes" "$REPO_ROOT/$DASHBOARD_FILE" && \
       grep -q "Change Failure Rate" "$REPO_ROOT/$DASHBOARD_FILE" && \
       grep -q "Mean Time to Restore" "$REPO_ROOT/$DASHBOARD_FILE"; then
        echo -e "  ${GREEN}✓${NC} Dashboard shows all 4 key metrics"
    else
        echo -e "  ${RED}✗${NC} Dashboard shows all 4 key metrics"
    fi

    if grep -q '"name": "team"' "$REPO_ROOT/$DASHBOARD_FILE"; then
        echo -e "  ${GREEN}✓${NC} Team-level filtering available"
    else
        echo -e "  ${RED}✗${NC} Team-level filtering available"
    fi

    if grep -q '"from": "now-30d"' "$REPO_ROOT/$DASHBOARD_FILE"; then
        echo -e "  ${GREEN}✓${NC} 30-day trending visible"
    else
        echo -e "  ${RED}✗${NC} 30-day trending visible"
    fi

    if grep -q "Benchmark" "$REPO_ROOT/$DASHBOARD_FILE"; then
        echo -e "  ${GREEN}✓${NC} Benchmark comparison included"
    else
        echo -e "  ${RED}✗${NC} Benchmark comparison included"
    fi

    echo ""
    echo "========================================================================"

    if [ $failures -eq 0 ]; then
        echo -e "  ${GREEN}✓ All tests passed${NC}"
        echo "========================================================================"
        exit 0
    else
        echo -e "  ${RED}✗ $failures test(s) failed${NC}"
        echo "========================================================================"
        exit 1
    fi
}

main "$@"
