#!/bin/bash
# =============================================================================
# Script: validate-golden-path-observability.sh
# Purpose: Validate the Observability plane of the tracer-bullet golden path
#          (#1751 Phase 3): tracer-bullet's OTEL traces actually reach Tempo
#          and its Prometheus metrics actually reach Prometheus - not just
#          that the collector/backend pods are Running.
# Usage: ./scripts/validate-golden-path-observability.sh [--namespace NS]
# Exit Codes: 0=success, 1=validation failed
# =============================================================================

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

NAMESPACE="${NAMESPACE:-fawkes}"
MONITORING_NAMESPACE="${MONITORING_NAMESPACE:-monitoring}"
SERVICE_NAME="tracer-bullet"
REPORT_FILE="reports/golden-path-observability-validation-$(date +%Y%m%d-%H%M%S).json"
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

Validate the Observability plane: real traces for tracer-bullet reach
Tempo and real metrics reach Prometheus.

OPTIONS:
    -n, --namespace NAMESPACE     Workload namespace (default: $NAMESPACE)
    -m, --monitoring-ns NAMESPACE Monitoring namespace (default: $MONITORING_NAMESPACE)
    -h, --help                    Show this help message
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

generate_traffic() {
  log_info "Generating a request to tracer-bullet so it emits a fresh trace..."
  kubectl exec -n "$NAMESPACE" deploy/tracer-bullet -- \
    python3 -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/')" &> /dev/null \
    || log_warning "Could not exec into tracer-bullet to generate traffic (continuing - may already have recent traces)"
  sleep 5
}

check_tempo_traces() {
  log_info "Checking Tempo for recent tracer-bullet traces..."
  kubectl port-forward -n "$MONITORING_NAMESPACE" svc/tempo 3100:3100 &> /tmp/tempo-pf.log &
  PF_PID=$!
  sleep 3

  local resp
  resp=$(curl -s --connect-timeout 5 "http://localhost:3100/api/search?tags=service.name%3D${SERVICE_NAME}&limit=5" 2> /dev/null || echo "")
  kill "$PF_PID" &> /dev/null || true
  PF_PID=""

  if [ -z "$resp" ]; then
    record_test "Tempo Reachable" "FAIL" "Could not reach Tempo query API via port-forward"
    return 1
  fi
  record_test "Tempo Reachable" "PASS" "Tempo query API responded"

  local trace_count
  trace_count=$(echo "$resp" | jq -r '.traces | length' 2> /dev/null || echo 0)
  if [ "${trace_count:-0}" -gt 0 ] 2> /dev/null; then
    record_test "Tempo Traces" "PASS" "Found $trace_count recent trace(s) for service '$SERVICE_NAME'"
  else
    record_test "Tempo Traces" "FAIL" "No recent traces found in Tempo for service '$SERVICE_NAME'"
  fi
}

check_prometheus_metrics() {
  log_info "Checking Prometheus for recent tracer-bullet metrics..."
  kubectl port-forward -n "$MONITORING_NAMESPACE" svc/prometheus-prometheus 9090:9090 &> /tmp/prom-pf.log &
  PF_PID=$!
  sleep 3

  local resp
  resp=$(curl -s --connect-timeout 5 "http://localhost:9090/api/v1/query?query=up%7Bjob%3D~%22.*${SERVICE_NAME}.*%22%7D" 2> /dev/null || echo "")
  kill "$PF_PID" &> /dev/null || true
  PF_PID=""

  if [ -z "$resp" ]; then
    record_test "Prometheus Reachable" "FAIL" "Could not reach Prometheus query API via port-forward"
    return 1
  fi
  record_test "Prometheus Reachable" "PASS" "Prometheus query API responded"

  local result_count
  result_count=$(echo "$resp" | jq -r '.data.result | length' 2> /dev/null || echo 0)
  if [ "${result_count:-0}" -gt 0 ] 2> /dev/null; then
    record_test "Prometheus Metrics" "PASS" "Found $result_count metric series matching '$SERVICE_NAME'"
  else
    record_test "Prometheus Metrics" "FAIL" "No metric series found matching '$SERVICE_NAME' - check ServiceMonitor/scrape config"
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
    --arg plane "observability" \
    --arg test_name "Golden Path - Observability Plane" \
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
  echo "Golden Path - Observability Plane Summary"
  echo "=========================================="
  echo "Total: $TOTAL_TESTS  Passed: $PASSED_TESTS  Failed: $FAILED_TESTS"
  if [ $FAILED_TESTS -eq 0 ]; then
    log_success "Observability plane verified ✅"
    return 0
  else
    log_error "Observability plane has failures ❌"
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
      -m | --monitoring-ns)
        MONITORING_NAMESPACE="$2"
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

  log_info "Starting golden path observability-plane validation..."
  generate_traffic
  check_tempo_traces
  check_prometheus_metrics
  generate_report
  print_summary
}

main "$@"
