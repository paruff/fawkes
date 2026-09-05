#!/bin/bash
# =============================================================================
# Script: validate-golden-path-devex.sh
# Purpose: Validate the DevEx plane of the tracer-bullet golden path
#          (#1751 Phase 3): tracer-bullet is discoverable and usable through
#          the platform's developer-facing surface - a catalog-info.yaml
#          exists, Backstage is deployed, and the component is actually
#          registered in its catalog - not just that Backstage is Running.
# Usage: ./scripts/validate-golden-path-devex.sh [--namespace NS]
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
CATALOG_INFO_PATH="services/${SERVICE_NAME}/catalog-info.yaml"
REPORT_FILE="reports/golden-path-devex-validation-$(date +%Y%m%d-%H%M%S).json"
REPORT_DIR="reports"
PF_PID=""

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

Validate the DevEx plane: tracer-bullet has a catalog-info.yaml, Backstage
is deployed, and the component is actually registered in its catalog.

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

check_catalog_info_exists() {
  log_info "Checking $CATALOG_INFO_PATH exists in git..."
  if [ -f "$CATALOG_INFO_PATH" ]; then
    record_test "catalog-info.yaml Present" "PASS" "$CATALOG_INFO_PATH exists"
  else
    record_test "catalog-info.yaml Present" "FAIL" "$CATALOG_INFO_PATH not found"
  fi
}

check_backstage_deployed() {
  log_info "Checking Backstage is deployed and healthy..."
  if ! kubectl get deployment backstage -n "$NAMESPACE" &> /dev/null; then
    record_test "Backstage Deployed" "FAIL" "Deployment 'backstage' not found in namespace '$NAMESPACE' - DevEx plane not verifiable until deployed"
    return 1
  fi

  local ready
  ready=$(kubectl get deployment backstage -n "$NAMESPACE" -o jsonpath='{.status.readyReplicas}' 2> /dev/null || echo 0)
  if [ "${ready:-0}" -ge 1 ]; then
    record_test "Backstage Deployed" "PASS" "$ready replica(s) Ready"
  else
    record_test "Backstage Deployed" "FAIL" "Backstage Deployment has no Ready replicas"
    return 1
  fi
}

check_component_registered() {
  log_info "Checking tracer-bullet is registered in the Backstage catalog..."
  kubectl port-forward -n "$NAMESPACE" svc/backstage 17007:7007 &> /tmp/backstage-pf.log &
  PF_PID=$!
  sleep 3

  local resp status_code
  status_code=$(curl -s -o /tmp/backstage-catalog-resp.json -w "%{http_code}" --connect-timeout 5 \
    "http://localhost:17007/api/catalog/entities/by-name/component/default/${SERVICE_NAME}" 2> /dev/null || echo "000")
  kill "$PF_PID" &> /dev/null || true
  PF_PID=""

  if [ "$status_code" = "200" ]; then
    record_test "Component Registered" "PASS" "Backstage catalog returned the '$SERVICE_NAME' component"
  elif [ "$status_code" = "404" ]; then
    record_test "Component Registered" "FAIL" "Backstage catalog does not have a '$SERVICE_NAME' component registered (404)"
  else
    record_test "Component Registered" "FAIL" "Could not query Backstage catalog API (HTTP $status_code)"
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
    --arg plane "devex" \
    --arg test_name "Golden Path - DevEx Plane" \
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
  echo "Golden Path - DevEx Plane Summary"
  echo "=========================================="
  echo "Total: $TOTAL_TESTS  Passed: $PASSED_TESTS  Failed: $FAILED_TESTS"
  if [ $FAILED_TESTS -eq 0 ]; then
    log_success "DevEx plane verified ✅"
    return 0
  else
    log_error "DevEx plane has failures ❌"
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

  log_info "Starting golden path devex-plane validation (namespace: $NAMESPACE)..."
  check_catalog_info_exists
  check_backstage_deployed || {
    generate_report
    print_summary
    exit 1
  }
  check_component_registered
  generate_report
  print_summary
}

main "$@"
