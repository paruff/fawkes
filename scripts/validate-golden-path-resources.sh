#!/bin/bash
# =============================================================================
# Script: validate-golden-path-resources.sh
# Purpose: Validate the Resources plane of the tracer-bullet golden path
#          (#1751 Phase 3): every golden-path container declares CPU/memory
#          requests and limits, actual usage is known, PVCs are Bound, and
#          the PostgreSQL (CloudNativePG) backing cluster is healthy - not
#          just that pods are Running.
# Usage: ./scripts/validate-golden-path-resources.sh [--namespace NS]
# Exit Codes: 0=success, 1=validation failed
# =============================================================================

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

NAMESPACE="${NAMESPACE:-fawkes}"
GOLDEN_PATH_DEPLOYMENTS=("tracer-bullet" "dora-metrics" "smart-alerting")
REPORT_FILE="reports/golden-path-resources-validation-$(date +%Y%m%d-%H%M%S).json"
REPORT_DIR="reports"

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

Validate the Resources plane: every golden-path container has resource
requests/limits, PVCs are Bound, and the PostgreSQL backing cluster is
healthy.

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

check_cluster_access() {
  log_info "Checking cluster access..."
  if kubectl cluster-info &> /dev/null; then
    record_test "Cluster Access" "PASS" "Kubernetes cluster is accessible"
  else
    record_test "Cluster Access" "FAIL" "Cannot access Kubernetes cluster"
    return 1
  fi
}

check_resource_requests_limits() {
  local deployment="$1"
  log_info "Checking CPU/memory requests and limits for '$deployment'..."
  local dep_json
  if ! dep_json=$(kubectl get deployment "$deployment" -n "$NAMESPACE" -o json 2> /dev/null); then
    record_test "Resource Limits: $deployment" "FAIL" "Deployment '$deployment' not found in namespace '$NAMESPACE'"
    return
  fi

  local missing
  missing=$(echo "$dep_json" | jq -r '
    [.spec.template.spec.containers[]
     | select((.resources.requests.cpu // "") == "" or (.resources.requests.memory // "") == ""
              or (.resources.limits.cpu // "") == "" or (.resources.limits.memory // "") == "")
     | .name] | join(",")')

  if [ -z "$missing" ]; then
    record_test "Resource Limits: $deployment" "PASS" "All containers declare CPU/memory requests and limits"
  else
    record_test "Resource Limits: $deployment" "FAIL" "Container(s) missing requests/limits: $missing"
  fi
}

check_actual_usage() {
  log_info "Checking actual pod resource usage (kubectl top)..."
  local top_output
  if ! top_output=$(kubectl top pods -n "$NAMESPACE" --no-headers 2> /dev/null); then
    record_test "Actual Pod Usage" "FAIL" "metrics-server unavailable - cannot report actual CPU/memory usage (informational only, not a hard gate)"
    return
  fi

  if [ -z "$top_output" ]; then
    record_test "Actual Pod Usage" "FAIL" "kubectl top returned no data for namespace '$NAMESPACE'"
    return
  fi

  record_test "Actual Pod Usage" "PASS" "metrics-server reachable; sample: $(echo "$top_output" | head -1)"
}

check_pvcs_bound() {
  log_info "Checking PersistentVolumeClaims are Bound..."
  local pvc_json total_count bound_count
  pvc_json=$(kubectl get pvc -A -o json 2> /dev/null || echo '{"items":[]}')
  total_count=$(echo "$pvc_json" | jq '.items | length')

  if [ "$total_count" -eq 0 ]; then
    record_test "PVCs Bound" "FAIL" "No PersistentVolumeClaims found in the cluster - expected at least Prometheus/Alertmanager/PostgreSQL storage"
    return
  fi

  bound_count=$(echo "$pvc_json" | jq '[.items[] | select(.status.phase=="Bound")] | length')
  if [ "$bound_count" -eq "$total_count" ]; then
    record_test "PVCs Bound" "PASS" "$bound_count/$total_count PVC(s) Bound"
  else
    local pending
    pending=$(echo "$pvc_json" | jq -r '[.items[] | select(.status.phase!="Bound") | "\(.metadata.namespace)/\(.metadata.name)=\(.status.phase)"] | join(", ")')
    record_test "PVCs Bound" "FAIL" "$bound_count/$total_count PVC(s) Bound - not Bound: $pending"
  fi
}

check_postgresql_cluster() {
  log_info "Checking CloudNativePG cluster health..."
  local cluster_json cluster_count
  cluster_json=$(kubectl get clusters.postgresql.cnpg.io -A -o json 2> /dev/null || echo '{"items":[]}')
  cluster_count=$(echo "$cluster_json" | jq '.items | length')

  if [ "$cluster_count" -eq 0 ]; then
    record_test "PostgreSQL Cluster" "FAIL" "No CloudNativePG Cluster resources found - is the postgresql Application deployed?"
    return
  fi

  local unhealthy
  unhealthy=$(echo "$cluster_json" | jq -r '[.items[] | select(.status.phase != "Cluster in healthy state") | "\(.metadata.namespace)/\(.metadata.name)=\(.status.phase // "Unknown")"] | join(", ")')

  if [ -z "$unhealthy" ]; then
    record_test "PostgreSQL Cluster" "PASS" "$cluster_count CloudNativePG cluster(s) healthy"
  else
    record_test "PostgreSQL Cluster" "FAIL" "Unhealthy cluster(s): $unhealthy"
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
    --arg plane "resources" \
    --arg test_name "Golden Path - Resources Plane" \
    --arg timestamp "$timestamp" \
    --arg namespace "$NAMESPACE" \
    --argjson total "$TOTAL_TESTS" --argjson passed "$PASSED_TESTS" --argjson failed "$FAILED_TESTS" \
    --arg pass_rate "${pass_rate}%" --argjson results "$results_json" \
    '{plane:$plane,test_name:$test_name,timestamp:$timestamp,namespace:$namespace,summary:{total:$total,passed:$passed,failed:$failed,pass_rate:$pass_rate},results:$results}' \
    > "$REPORT_FILE"
  log_info "Report saved to: $REPORT_FILE"
}

print_summary() {
  echo ""
  echo "=========================================="
  echo "Golden Path - Resources Plane Summary"
  echo "=========================================="
  echo "Total: $TOTAL_TESTS  Passed: $PASSED_TESTS  Failed: $FAILED_TESTS"
  if [ $FAILED_TESTS -eq 0 ]; then
    log_success "Resources plane verified ✅"
    return 0
  else
    log_error "Resources plane has failures ❌"
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

  log_info "Starting golden path resources-plane validation (namespace: $NAMESPACE)..."
  check_cluster_access || {
    generate_report
    print_summary
    exit 1
  }
  for dep in "${GOLDEN_PATH_DEPLOYMENTS[@]}"; do
    check_resource_requests_limits "$dep"
  done
  check_actual_usage
  check_pvcs_bound
  check_postgresql_cluster
  generate_report
  print_summary
}

main "$@"
