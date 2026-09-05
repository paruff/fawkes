#!/bin/bash
# =============================================================================
# Script: validate-golden-path-dora.sh
# Purpose: Validate the DORA plane of the tracer-bullet golden path
#          (#1751 Phase 3): dora-metrics has actually scraped a real
#          deployment-frequency data point for tracer-bullet - not just
#          that the dora-metrics pod is Running.
# Usage: ./scripts/validate-golden-path-dora.sh [--namespace NAMESPACE]
# Exit Codes: 0=success, 1=validation failed
# =============================================================================

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

NAMESPACE="${NAMESPACE:-fawkes}"
SERVICE_NAME="tracer-bullet"
REPORT_FILE="reports/golden-path-dora-validation-$(date +%Y%m%d-%H%M%S).json"
REPORT_DIR="reports"

TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
declare -a TEST_RESULTS=()
PF_PID=""

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[✓]${NC} $1"; }
log_error() { echo -e "${RED}[✗]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[!]${NC} $1"; }

usage() {
  cat << EOF
Usage: $0 [OPTIONS]

Validate the DORA plane: dora-metrics has scraped a real deployment
data point for tracer-bullet from GitHub Actions.

OPTIONS:
    -n, --namespace NAMESPACE   Workload namespace (default: $NAMESPACE)
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

cleanup() {
  if [ -n "$PF_PID" ]; then
    kill "$PF_PID" &> /dev/null || true
  fi
}
trap cleanup EXIT

check_pod_running() {
  log_info "Checking dora-metrics pod is Running..."
  local pods_json running_count total_count
  pods_json=$(kubectl get pods -n "$NAMESPACE" -l app=dora-metrics -o json 2> /dev/null || echo '{"items":[]}')
  total_count=$(echo "$pods_json" | jq '.items | length')

  if [ "$total_count" -eq 0 ]; then
    record_test "Pod Running" "FAIL" "No dora-metrics pods found in namespace '$NAMESPACE'"
    return 1
  fi

  running_count=$(echo "$pods_json" | jq '[.items[] | select(.status.phase=="Running")] | length')
  if [ "$running_count" -gt 0 ]; then
    record_test "Pod Running" "PASS" "$running_count/$total_count dora-metrics pod(s) Running"
  else
    record_test "Pod Running" "FAIL" "0/$total_count dora-metrics pod(s) Running"
    return 1
  fi
}

trigger_scrape_and_check() {
  log_info "Triggering a fresh scrape and checking for tracer-bullet data..."
  kubectl port-forward -n "$NAMESPACE" svc/dora-metrics 8090:8000 &> /tmp/dora-pf.log &
  PF_PID=$!
  sleep 3

  local scrape_resp
  scrape_resp=$(curl -s --connect-timeout 10 -X GET "http://localhost:8090/api/v1/scrape" 2> /dev/null || echo "")
  if [ -z "$scrape_resp" ]; then
    record_test "Scrape Trigger" "FAIL" "Could not reach dora-metrics /api/v1/scrape via port-forward"
    kill "$PF_PID" &> /dev/null || true
    PF_PID=""
    return 1
  fi
  record_test "Scrape Trigger" "PASS" "Scrape endpoint responded: $(echo "$scrape_resp" | jq -c '.')"

  local metrics_resp
  metrics_resp=$(curl -s --connect-timeout 5 "http://localhost:8090/metrics" 2> /dev/null || echo "")
  kill "$PF_PID" &> /dev/null || true
  PF_PID=""

  if [ -z "$metrics_resp" ]; then
    record_test "Metrics Endpoint" "FAIL" "Could not reach dora-metrics /metrics via port-forward"
    return 1
  fi
  record_test "Metrics Endpoint" "PASS" "/metrics endpoint responded"

  if echo "$metrics_resp" | grep -q "dora_deployments_total"; then
    record_test "DORA Metric Family" "PASS" "dora_deployments_total metric family is present"
  else
    record_test "DORA Metric Family" "FAIL" "dora_deployments_total metric family not found in /metrics output"
    return 1
  fi

  local tb_line
  tb_line=$(echo "$metrics_resp" | grep "dora_deployments_total" | grep -i "$SERVICE_NAME" || true)
  if [ -n "$tb_line" ]; then
    record_test "Tracer-Bullet Data Point" "PASS" "Found deployment data for '$SERVICE_NAME': $tb_line"
  else
    record_test "Tracer-Bullet Data Point" "FAIL" "No dora_deployments_total series labeled service='$SERVICE_NAME' - check GITHUB_TOKEN scope / workflow name matching in dora-metrics config"
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
    --arg service "$SERVICE_NAME" \
    --argjson total "$TOTAL_TESTS" --argjson passed "$PASSED_TESTS" --argjson failed "$FAILED_TESTS" \
    --arg pass_rate "${pass_rate}%" --argjson results "$results_json" \
    '{plane:$plane,test_name:$test_name,timestamp:$timestamp,service:$service,summary:{total:$total,passed:$passed,failed:$failed,pass_rate:$pass_rate},results:$results}' \
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

  log_info "Starting golden path dora-plane validation..."
  check_pod_running || {
    generate_report
    print_summary
    exit 1
  }
  trigger_scrape_and_check
  generate_report
  print_summary
}

main "$@"
