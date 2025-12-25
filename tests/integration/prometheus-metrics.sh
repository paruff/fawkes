#!/bin/bash
# =============================================================================
# Script: prometheus-metrics.sh
# Purpose: Query Prometheus metrics to validate observability stack
# Usage: ./tests/integration/prometheus-metrics.sh [PROMETHEUS_URL]
# =============================================================================

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default Prometheus URL
PROMETHEUS_URL="${1:-http://prometheus.127.0.0.1.nip.io}"

log_info() {
  echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
  echo -e "${GREEN}[✓]${NC} $1"
}

log_error() {
  echo -e "${RED}[✗]${NC} $1"
}

# Test Prometheus is reachable
test_prometheus_health() {
  log_info "Testing Prometheus health endpoint..."

  if curl -sf "${PROMETHEUS_URL}/-/healthy" > /dev/null 2>&1; then
    log_success "Prometheus is healthy"
    return 0
  else
    log_error "Prometheus health check failed"
    return 1
  fi
}

# Test Prometheus has targets
test_prometheus_targets() {
  log_info "Testing Prometheus scrape targets..."

  local response=$(curl -sf "${PROMETHEUS_URL}/api/v1/targets" 2> /dev/null || echo '{}')
  # Note: Using grep for simplicity. For production, consider using jq:
  # local active_targets=$(echo "$response" | jq '.data.activeTargets | map(select(.health == "up")) | length')
  local active_targets=$(echo "$response" | grep -o '"health":"up"' | wc -l)

  if [ "$active_targets" -gt 0 ]; then
    log_success "Prometheus has $active_targets active targets"
    return 0
  else
    log_error "No active Prometheus targets found"
    return 1
  fi
}

# Test that 'up' metric is available
test_up_metric() {
  log_info "Testing 'up' metric availability..."

  local response=$(curl -sf "${PROMETHEUS_URL}/api/v1/query?query=up" 2> /dev/null || echo '{}')
  local result_count=$(echo "$response" | grep -o '"result":\[' | wc -l)

  if [ "$result_count" -gt 0 ]; then
    log_success "'up' metric is available"
    return 0
  else
    log_error "'up' metric not found"
    return 1
  fi
}

# Test DORA metrics are being collected
test_dora_metrics() {
  log_info "Testing DORA metrics availability..."

  # Check for deployment frequency metric
  local response=$(curl -sf "${PROMETHEUS_URL}/api/v1/query?query=dora_deployment_frequency" 2> /dev/null || echo '{}')

  if echo "$response" | grep -q '"status":"success"'; then
    log_success "DORA metrics are being collected"
    return 0
  else
    log_info "DORA metrics not yet available (this is optional)"
    return 0 # Don't fail if DORA metrics aren't set up yet
  fi
}

# Main execution
main() {
  echo ""
  echo "========================================================================"
  echo "  Prometheus Metrics Validation"
  echo "========================================================================"
  echo ""
  echo "  Prometheus URL: $PROMETHEUS_URL"
  echo ""

  local failures=0

  test_prometheus_health || ((failures++))
  test_prometheus_targets || ((failures++))
  test_up_metric || ((failures++))
  test_dora_metrics || ((failures++))

  echo ""
  echo "========================================================================"

  if [ $failures -eq 0 ]; then
    echo -e "  ${GREEN}✓ All Prometheus metric tests passed${NC}"
    echo "========================================================================"
    exit 0
  else
    echo -e "  ${RED}✗ $failures test(s) failed${NC}"
    echo "========================================================================"
    exit 1
  fi
}

main "$@"
