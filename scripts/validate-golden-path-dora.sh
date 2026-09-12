#!/bin/bash
# =============================================================================
# Script: validate-golden-path-dora.sh
# Purpose: Validate the DORA plane of the python-fawkes-path golden path
#          (#1751 Phase 3, updated #1909): DevLake has a configured project
#          for the service and its latest pipeline actually completed - not
#          just that DevLake's pods are Running.
#
#          This script previously checked for a "dora-metrics" pod/service
#          that does not exist in this platform - DORA collection here is
#          done by DevLake (platform/apps/devlake), configured via its own
#          REST API (see docs/KNOWN_LIMITATIONS.md KL-09 for the current
#          known blocker: DevLake's github_graphql collector fails for any
#          repo, tracked in #1855). This script now checks DevLake itself.
# Usage: ./scripts/validate-golden-path-dora.sh [--namespace NAMESPACE] [--project NAME]
# Requires: kubectl (cluster access), curl, jq
# Exit Codes: 0=success, 1=validation failed
# =============================================================================

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

NAMESPACE="${NAMESPACE:-fawkes}"
PROJECT_NAME="${PROJECT_NAME:-python-fawkes-path}"
DEVLAKE_SERVICE="devlake-lake"
DEVLAKE_PORT=8080
LOCAL_PORT=18080
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

Validate the DORA plane: DevLake has a project configured for '$PROJECT_NAME'
and its most recent pipeline run actually completed successfully.

OPTIONS:
    -n, --namespace NAMESPACE   Cluster namespace DevLake runs in (default: $NAMESPACE)
    -p, --project NAME          DevLake project name to check (default: $PROJECT_NAME)
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

check_pods_running() {
  log_info "Checking DevLake pods are Running in namespace '$NAMESPACE'..."
  local pods_json ready_count total_count
  pods_json=$(kubectl get pods -n "$NAMESPACE" -l app.kubernetes.io/name=devlake -o json 2> /dev/null || echo '{"items":[]}')
  total_count=$(echo "$pods_json" | jq '.items | length')

  if [ "$total_count" -eq 0 ]; then
    record_test "DevLake Pods Running" "FAIL" "No DevLake pods found in namespace '$NAMESPACE'"
    return 1
  fi

  ready_count=$(echo "$pods_json" | jq '[.items[] | select(.status.containerStatuses[]?.ready==true)] | length')
  if [ "$ready_count" -eq "$total_count" ]; then
    record_test "DevLake Pods Running" "PASS" "$ready_count/$total_count DevLake pod(s) Ready"
  else
    record_test "DevLake Pods Running" "FAIL" "$ready_count/$total_count DevLake pod(s) Ready"
    return 1
  fi
}

check_project_and_pipeline() {
  log_info "Checking DevLake project '$PROJECT_NAME' and its latest pipeline..."
  kubectl port-forward -n "$NAMESPACE" "svc/$DEVLAKE_SERVICE" "$LOCAL_PORT:$DEVLAKE_PORT" &> /tmp/devlake-dora-pf.log &
  PF_PID=$!
  sleep 3

  local project_json blueprint_id
  project_json=$(curl -s --connect-timeout 10 "http://localhost:$LOCAL_PORT/projects/$PROJECT_NAME" 2> /dev/null || echo "")
  if [ -z "$project_json" ] || [ "$(echo "$project_json" | jq -r '.name // empty')" != "$PROJECT_NAME" ]; then
    record_test "DevLake Project" "FAIL" "No DevLake project named '$PROJECT_NAME' found - run the DevLake connection/project setup first"
    return 1
  fi
  record_test "DevLake Project" "PASS" "DevLake project '$PROJECT_NAME' exists"

  blueprint_id=$(echo "$project_json" | jq -r '.blueprint.id // empty')
  if [ -z "$blueprint_id" ]; then
    record_test "DevLake Blueprint" "FAIL" "Project '$PROJECT_NAME' has no blueprint configured"
    return 1
  fi
  record_test "DevLake Blueprint" "PASS" "Project '$PROJECT_NAME' has blueprint id $blueprint_id"

  local pipelines_json pipeline_status pipeline_message
  pipelines_json=$(curl -s --connect-timeout 10 "http://localhost:$LOCAL_PORT/pipelines?blueprint_id=${blueprint_id}&pageSize=1" 2> /dev/null || echo "")
  if [ -z "$pipelines_json" ] || [ "$(echo "$pipelines_json" | jq '.pipelines | length')" -eq 0 ]; then
    record_test "DevLake Pipeline Run" "FAIL" "No pipeline runs found for blueprint $blueprint_id - trigger one via POST /blueprints/$blueprint_id/trigger"
    return 1
  fi

  pipeline_status=$(echo "$pipelines_json" | jq -r '.pipelines[0].status')
  pipeline_message=$(echo "$pipelines_json" | jq -r '.pipelines[0].message // ""' | head -c 200)

  if [ "$pipeline_status" = "TASK_COMPLETED" ]; then
    record_test "DevLake Pipeline Run" "PASS" "Latest pipeline for '$PROJECT_NAME' completed successfully"
  else
    record_test "DevLake Pipeline Run" "FAIL" "Latest pipeline for '$PROJECT_NAME' is '$pipeline_status': ${pipeline_message}..."
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
    --arg project "$PROJECT_NAME" \
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
    log_error "DORA plane has failures ❌ (see docs/KNOWN_LIMITATIONS.md KL-09 if this is the github_graphql collector failure)"
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
      -p | --project)
        PROJECT_NAME="$2"
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

  log_info "Starting golden path dora-plane validation (project: $PROJECT_NAME)..."
  check_pods_running || {
    generate_report
    print_summary
    exit 1
  }
  check_project_and_pipeline
  generate_report
  print_summary
}

main "$@"
