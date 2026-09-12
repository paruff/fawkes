#!/bin/bash
# =============================================================================
# Script: validate-golden-path-progressive-delivery.sh
# Purpose: Validate the Progressive Delivery plane of the python-fawkes-path golden
#          path (#1751 Phase 3, #1805): Argo Rollouts' Rollout CRD exists with
#          a canary strategy, an AnalysisTemplate is referenced, and (if a
#          rollback event exists in status/history) it completed successfully.
#          Designed to pass on a healthy Rollout even when no mid-rollback is
#          occurring.
# Usage: ./scripts/validate-golden-path-progressive-delivery.sh [--namespace NS]
# Exit Codes: 0=success, 1=validation failed
# =============================================================================

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

NAMESPACE="${NAMESPACE:-fawkes}"
ROLLOUT_NAME="${ROLLOUT_NAME:-python-fawkes-path}"
REPORT_FILE="reports/golden-path-progressive-delivery-validation-$(date +%Y%m%d-%H%M%S).json"
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

Validate the Progressive Delivery plane: Argo Rollouts' Rollout CRD exists
with a canary strategy, an AnalysisTemplate is referenced, and any rollback
event in status/history completed successfully.

OPTIONS:
    -n, --namespace NAMESPACE   Workload namespace (default: $NAMESPACE)
    -r, --rollout NAME          Rollout name (default: $ROLLOUT_NAME)
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

check_rollout_exists() {
  log_info "Checking Rollout '$ROLLOUT_NAME' exists in namespace '$NAMESPACE'..."
  local rollout_json
  if ! rollout_json=$(kubectl get rollout "$ROLLOUT_NAME" -n "$NAMESPACE" -o json 2> /dev/null); then
    record_test "Rollout Exists" "FAIL" "Rollout '$ROLLOUT_NAME' not found in namespace '$NAMESPACE'"
    return 1
  fi
  record_test "Rollout Exists" "PASS" "Rollout '$ROLLOUT_NAME' found"
  echo "$rollout_json"
}

check_canary_strategy() {
  local rollout_json="$1"
  log_info "Checking Rollout has a canary strategy..."
  local strategy_type
  strategy_type=$(echo "$rollout_json" | jq -r '.spec.strategy // {} | keys[0] // "none"')

  if [ "$strategy_type" = "canary" ]; then
    record_test "Canary Strategy" "PASS" "Rollout uses canary strategy"
  else
    record_test "Canary Strategy" "FAIL" "Rollout strategy is '$strategy_type' (expected 'canary')"
    return 1
  fi

  local canary_steps
  canary_steps=$(echo "$rollout_json" | jq '.spec.strategy.canary // {} | steps | length // 0')
  if [ "${canary_steps:-0}" -gt 0 ] 2> /dev/null; then
    record_test "Canary Steps" "PASS" "Canary strategy has $canary_steps step(s)"
  else
    record_test "Canary Steps" "FAIL" "Canary strategy has no steps defined"
  fi
}

check_analysis_template() {
  local rollout_json="$1"
  log_info "Checking AnalysisTemplate is referenced in Rollout..."
  local analysis_ref
  analysis_ref=$(echo "$rollout_json" | jq -r '
    .spec.strategy.canary.analysis // empty |
    (.successfulRunHistoryLimit // empty),
    (.args // [] | map(select(.name == "service-name")) | length)
  ' 2> /dev/null || echo "")

  local has_analysis
  has_analysis=$(echo "$rollout_json" | jq '
    .spec.strategy.canary.analysis != null and
    (.spec.strategy.canary.analysis.templates | length > 0)
  ' 2> /dev/null || echo "false")

  if [ "$has_analysis" = "true" ]; then
    local template_name
    template_name=$(echo "$rollout_json" | jq -r '.spec.strategy.canary.analysis.templates[0].templateName // "unknown"')
    record_test "AnalysisTemplate Referenced" "PASS" "AnalysisTemplate '$template_name' is referenced in canary strategy"
  else
    record_test "AnalysisTemplate Referenced" "FAIL" "No AnalysisTemplate referenced in canary strategy"
    return 1
  fi

  local analysis_in_steps
  analysis_in_steps=$(echo "$rollout_json" | jq '
    (.spec.strategy.canary.steps // []) |
    map(select(.analysis != null)) | length
  ' 2> /dev/null || echo "0")
  if [ "${analysis_in_steps:-0}" -gt 0 ] 2> /dev/null; then
    record_test "Analysis in Canary Steps" "PASS" "Analysis is configured in $analysis_in_steps canary step(s)"
  else
    record_test "Analysis in Canary Steps" "FAIL" "No analysis found in canary steps"
  fi
}

check_rollback_status() {
  local rollout_json="$1"
  log_info "Checking rollback status in Rollout history..."

  local history_length
  history_length=$(echo "$rollout_json" | jq '.status.history | length // 0' 2> /dev/null || echo "0")

  if [ "${history_length:-0}" -eq 0 ] 2> /dev/null; then
    record_test "Rollout History" "PASS" "No rollout history entries (first deployment — no rollback to verify)"
    return 0
  fi

  record_test "Rollout History" "PASS" "Rollout has $history_length history entry/entries"

  local rollback_entries
  rollback_entries=$(echo "$rollout_json" | jq '[.status.history[]? | select(.initiatedBy.automatic == true or .reason == "Rollback")]' 2> /dev/null || echo "[]")
  local rollback_count
  rollback_count=$(echo "$rollback_entries" | jq 'length' 2> /dev/null || echo "0")

  if [ "${rollback_count:-0}" -eq 0 ] 2> /dev/null; then
    record_test "Rollback Events" "PASS" "No automatic rollback events in history (Rollout has not needed to roll back)"
    return 0
  fi

  record_test "Rollback Events" "PASS" "Found $rollback_count automatic rollback event(s) in history"

  local completed_rollbacks
  completed_rollbacks=$(echo "$rollback_entries" | jq '[.[] | select(.completedAt != null and .completedAt != "")] | length' 2> /dev/null || echo "0")
  if [ "${completed_rollbacks:-0}" -gt 0 ] 2> /dev/null; then
    record_test "Rollback Completed" "PASS" "$completed_rollbacks/$rollback_count rollback(s) completed successfully"
  else
    record_test "Rollback Completed" "FAIL" "No rollback events completed (may still be in progress or stuck)"
    return 1
  fi
}

check_rollout_ready() {
  local rollout_json="$1"
  log_info "Checking Rollout Ready status..."

  local ready
  ready=$(echo "$rollout_json" | jq -r '.status.readyReplicas // 0' 2> /dev/null || echo "0")
  local desired
  desired=$(echo "$rollout_json" | jq -r '.spec.replicas // 1' 2> /dev/null || echo "1")
  local phase
  phase=$(echo "$rollout_json" | jq -r '.status.phase // "Unknown"')

  if [ "$phase" = "Healthy" ] || [ "$phase" = "Progressing" ]; then
    record_test "Rollout Phase" "PASS" "Rollout phase is '$phase'"
  else
    record_test "Rollout Phase" "FAIL" "Rollout phase is '$phase' (expected Healthy or Progressing)"
  fi

  if [ "${ready:-0}" -ge "${desired:-1}" ] 2> /dev/null; then
    record_test "Rollout Ready Replicas" "PASS" "$ready/$desired replicas ready"
  else
    record_test "Rollout Ready Replicas" "FAIL" "$ready/$desired replicas ready"
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
    --arg plane "progressive-delivery" \
    --arg test_name "Golden Path - Progressive Delivery Plane" \
    --arg timestamp "$timestamp" \
    --arg namespace "$NAMESPACE" \
    --arg rollout "$ROLLOUT_NAME" \
    --argjson total "$TOTAL_TESTS" --argjson passed "$PASSED_TESTS" --argjson failed "$FAILED_TESTS" \
    --arg pass_rate "${pass_rate}%" --argjson results "$results_json" \
    '{plane:$plane,test_name:$test_name,timestamp:$timestamp,namespace:$namespace,rollout:$rollout,summary:{total:$total,passed:$passed,failed:$failed,pass_rate:$pass_rate},results:$results}' \
    > "$REPORT_FILE"
  log_info "Report saved to: $REPORT_FILE"
}

print_summary() {
  echo ""
  echo "==================================================="
  echo "Golden Path - Progressive Delivery Plane Summary"
  echo "==================================================="
  echo "Total: $TOTAL_TESTS  Passed: $PASSED_TESTS  Failed: $FAILED_TESTS"
  if [ $FAILED_TESTS -eq 0 ]; then
    log_success "Progressive Delivery plane verified ✅"
    return 0
  else
    log_error "Progressive Delivery plane has failures ❌"
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
      -r | --rollout)
        ROLLOUT_NAME="$2"
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

  log_info "Starting golden path progressive-delivery-plane validation..."

  local rollout_json
  rollout_json=$(check_rollout_exists) || {
    generate_report
    print_summary
    exit 1
  }

  check_canary_strategy "$rollout_json"
  check_analysis_template "$rollout_json"
  check_rollback_status "$rollout_json"
  check_rollout_ready "$rollout_json"
  generate_report
  print_summary
}

main "$@"
