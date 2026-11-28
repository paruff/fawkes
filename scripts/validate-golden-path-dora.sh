#!/bin/bash
# =============================================================================
# Script: validate-golden-path-dora.sh
# Purpose: Validate the DORA plane of the python-fawkes-path golden path:
#          Prometheus has a value for the service from Fawkes's own recording
#          rules (ADR-038), not merely that the rules exist.
# Usage: ./scripts/validate-golden-path-dora.sh [--namespace NS] [--service NAME]
# Requires: kubectl (cluster access), jq
# Exit Codes: 0=success, 1=validation failed
# =============================================================================

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

NAMESPACE="${NAMESPACE:-monitoring}"
SERVICE_NAME="${SERVICE_NAME:-python-fawkes-path}"
PROMETHEUS_SERVICE="${PROMETHEUS_SERVICE:-prometheus-prometheus}"
REPORT_FILE="reports/golden-path-dora-validation-$(date +%Y%m%d-%H%M%S).json"
REPORT_DIR="reports"
RULES=(
  dora:deployment_frequency:rate30d_by_app
  dora:change_failure_rate:ratio30d_by_app
)

TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
declare -a TEST_RESULTS=()

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[✓]${NC} $1"; }
log_error() { echo -e "${RED}[✗]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[!]${NC} $1"; }

usage() {
  cat << EOF
Usage: $0 [OPTIONS]

Validate the DORA plane: Prometheus has per-service DORA values for '$SERVICE_NAME'.

OPTIONS:
    -n, --namespace NAMESPACE   Namespace Prometheus runs in (default: $NAMESPACE)
    -s, --service NAME          Argo CD application name (default: $SERVICE_NAME)
    -h, --help                  Show this help message
EOF
}

record_test() {
  local test_name="$1" status="$2" message="$3"
  TOTAL_TESTS=$((TOTAL_TESTS + 1))
  if [ "$status" = "PASS" ]; then
    PASSED_TESTS=$((PASSED_TESTS + 1))
    log_success "$test_name: $message"
  else
    FAILED_TESTS=$((FAILED_TESTS + 1))
    log_error "$test_name: $message"
  fi
  TEST_RESULTS+=("$(jq -n --arg n "$test_name" --arg s "$status" --arg m "$message" '{name:$n,status:$s,message:$m}')")
}

# Query through the API server's service proxy: no port-forward to clean up.
check_rule() {
  local rule="$1" response count query
  query=$(jq -rn --arg q "${rule}{name=\"${SERVICE_NAME}\"}" '$q|@uri')
  if ! response=$(kubectl get --raw "/api/v1/namespaces/${NAMESPACE}/services/${PROMETHEUS_SERVICE}:9090/proxy/api/v1/query?query=${query}" 2>&1); then
    record_test "$rule" "FAIL" "Prometheus query failed: ${response:0:200}"
    return 1
  fi
  count=$(echo "$response" | jq '.data.result | length' 2> /dev/null || true)
  if [ "${count:-0}" -gt 0 ]; then
    record_test "$rule" "PASS" "value for '$SERVICE_NAME': $(echo "$response" | jq -r '.data.result[0].value[1]')"
  else
    record_test "$rule" "FAIL" "no value for '$SERVICE_NAME'"
    return 1
  fi
}

generate_report() {
  log_info "Generating test report..."
  mkdir -p "$REPORT_DIR"
  local timestamp pass_rate results_json
  timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  pass_rate=0
  [ $TOTAL_TESTS -gt 0 ] && pass_rate=$(awk "BEGIN {printf \"%.2f\", ($PASSED_TESTS/$TOTAL_TESTS)*100}")
  results_json="[]"
  [ ${#TEST_RESULTS[@]} -gt 0 ] && results_json=$(printf '%s\n' "${TEST_RESULTS[@]}" | jq -s '.')

  jq -n \
    --arg plane "dora" \
    --arg test_name "Golden Path - DORA Plane" \
    --arg timestamp "$timestamp" \
    --arg project "$SERVICE_NAME" \
    --argjson total "$TOTAL_TESTS" --argjson passed "$PASSED_TESTS" --argjson failed "$FAILED_TESTS" \
    --arg pass_rate "${pass_rate}%" --argjson results "$results_json" \
    '{plane:$plane,test_name:$test_name,timestamp:$timestamp,project:$project,summary:{total:$total,passed:$passed,failed:$failed,pass_rate:$pass_rate},results:$results}' \
    > "$REPORT_FILE"
  log_info "Report saved to: $REPORT_FILE"
}

print_summary() {
  echo ""
  echo "=========================================="
  echo "Golden Path - DORA Plane Summary"
  echo "=========================================="
  echo "Total: $TOTAL_TESTS  Passed: $PASSED_TESTS  Failed: $FAILED_TESTS"
  if [ $FAILED_TESTS -eq 0 ]; then
    log_success "DORA plane verified ✅"
    return 0
  else
    log_error "DORA plane has failures ❌"
    return 1
  fi
}

main() {
  while [[ $# -gt 0 ]]; do
    case $1 in
      -n | --namespace)
        NAMESPACE="$2"
        shift 2
        ;;
      -s | --service)
        SERVICE_NAME="$2"
        shift 2
        ;;
      -h | --help)
        usage
        exit 0
        ;;
      *)
        log_error "Unknown option: $1"
        usage
        exit 1
        ;;
    esac
  done

  log_info "Starting golden path dora-plane validation (service: $SERVICE_NAME)..."
  local rule
  for rule in "${RULES[@]}"; do
    # A failure is recorded and reported; carry on so every rule is shown.
    check_rule "$rule" || true
  done
  generate_report
  print_summary
}

main "$@"
