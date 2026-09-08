#!/bin/bash
# =============================================================================
# Script: validate-golden-path-pipeline.sh
# Purpose: Validate the Pipeline plane of the tracer-bullet golden path
#          (#1751 Phase 3, updated #1909): the latest Tekton `golden-path`
#          PipelineRun for tracer-bullet actually built, scanned, and pushed
#          an image - not just that the Pipeline definition exists.
#
#          tracer-bullet was extracted to its own repo pair in #1813/#1804:
#          app source lives in paruff/tracer-bullet, but CI now runs as an
#          in-cluster Tekton pipeline (platform/apps/tekton/golden-path-pipeline.yaml),
#          not a GitHub Actions workflow. This script was previously written
#          against the deleted tracer-bullet-ci.yml GitHub Actions workflow
#          and always failed for the wrong reason (workflow not found).
# Usage: ./scripts/validate-golden-path-pipeline.sh [--namespace NAMESPACE] [--image-repo OWNER/REPO]
# Requires: kubectl (cluster access), gh CLI (authenticated, for the GHCR check)
# Exit Codes: 0=success, 1=validation failed
# =============================================================================

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

NAMESPACE="${NAMESPACE:-fawkes}"
IMAGE_REPO="${IMAGE_REPO:-paruff/tracer-bullet}"
PIPELINE_NAME="golden-path"
EXPECTED_TASKS=(fetch-source lint-and-test sonar-scan build-and-push scan-image gitops-promote)
REPORT_FILE="reports/golden-path-pipeline-validation-$(date +%Y%m%d-%H%M%S).json"
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

Validate the Pipeline plane of the tracer-bullet golden path: the most
recent Tekton '$PIPELINE_NAME' PipelineRun in namespace '$NAMESPACE'
completed successfully and pushed a real image to GHCR.

OPTIONS:
    -n, --namespace NAMESPACE   Cluster namespace the pipeline runs in (default: $NAMESPACE)
    -i, --image-repo REPO       GHCR image repo as owner/name (default: $IMAGE_REPO)
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

check_prerequisites() {
  log_info "Checking prerequisites..."
  if ! command -v kubectl &> /dev/null; then
    record_test "Prerequisites" "FAIL" "kubectl not found"
    return 1
  fi
  if ! kubectl cluster-info &> /dev/null; then
    record_test "Prerequisites" "FAIL" "Cannot access Kubernetes cluster"
    return 1
  fi
  if ! command -v gh &> /dev/null || ! gh auth status &> /dev/null; then
    record_test "Prerequisites" "FAIL" "gh CLI not found or not authenticated"
    return 1
  fi
  record_test "Prerequisites" "PASS" "kubectl and gh CLI available and authenticated"
}

check_latest_run() {
  log_info "Checking latest '$PIPELINE_NAME' PipelineRun in namespace '$NAMESPACE'..."
  local run_json
  run_json=$(kubectl get pipelinerun -n "$NAMESPACE" \
    -l "tekton.dev/pipeline=$PIPELINE_NAME" \
    --sort-by=.metadata.creationTimestamp \
    -o json 2> /dev/null)

  local run_count
  run_count=$(echo "$run_json" | jq '.items | length')
  if [ "$run_count" -eq 0 ]; then
    record_test "Latest Run" "FAIL" "No '$PIPELINE_NAME' PipelineRuns found in namespace '$NAMESPACE'"
    return 1
  fi

  RUN_NAME=$(echo "$run_json" | jq -r '.items[-1].metadata.name')
  RUN_JSON=$(echo "$run_json" | jq '.items[-1]')
  local succeeded_status succeeded_reason
  succeeded_status=$(echo "$RUN_JSON" | jq -r '.status.conditions[]? | select(.type=="Succeeded") | .status')
  succeeded_reason=$(echo "$RUN_JSON" | jq -r '.status.conditions[]? | select(.type=="Succeeded") | .reason')

  # The pipeline's own top-level result is named "image-tag" (see
  # platform/apps/tekton/golden-path-pipeline.yaml's results: block) - it's
  # the immutable short-SHA the build-and-push task tagged the image with,
  # sourced from $(tasks.fetch-source.results.short-sha).
  RUN_SHA=$(echo "$RUN_JSON" | jq -r '.status.results[]? | select(.name=="image-tag") | .value // empty' | head -1)

  if [ "$succeeded_status" = "True" ]; then
    record_test "Latest Run" "PASS" "PipelineRun '$RUN_NAME' completed successfully (reason: $succeeded_reason)"
  elif [ "$succeeded_status" = "Unknown" ] || [ -z "$succeeded_status" ]; then
    record_test "Latest Run" "FAIL" "PipelineRun '$RUN_NAME' is still running or has no Succeeded condition yet"
    return 1
  else
    record_test "Latest Run" "FAIL" "PipelineRun '$RUN_NAME' concluded '$succeeded_reason'"
    return 1
  fi
}

check_tasks() {
  log_info "Checking individual task outcomes for run '$RUN_NAME'..."
  local taskrun_json
  taskrun_json=$(kubectl get taskrun -n "$NAMESPACE" \
    -l "tekton.dev/pipelineRun=$RUN_NAME" -o json 2> /dev/null)

  for task in "${EXPECTED_TASKS[@]}"; do
    local reason
    reason=$(echo "$taskrun_json" | jq -r --arg t "$task" \
      '.items[] | select(.metadata.labels["tekton.dev/pipelineTask"]==$t) | .status.conditions[]? | select(.type=="Succeeded") | .reason' | head -1)
    if [ "$reason" = "Succeeded" ]; then
      record_test "Task: $task" "PASS" "Task '$task' succeeded"
    elif [ -z "$reason" ]; then
      record_test "Task: $task" "FAIL" "Task '$task' not found in run '$RUN_NAME'"
    else
      record_test "Task: $task" "FAIL" "Task '$task' concluded '$reason'"
    fi
  done
}

check_image_pushed() {
  log_info "Checking image was pushed to GHCR..."
  if [ -z "${RUN_SHA:-}" ]; then
    record_test "Image Pushed" "FAIL" "Could not determine the commit SHA this run built (no short-sha/commit-sha result on the PipelineRun)"
    return
  fi

  # GHCR package versions are queried under /users (or /orgs) per the GitHub
  # Packages API, not /repos - confirmed live against ghcr.io/paruff/tracer-bullet.
  local pkg_json tag_match
  pkg_json=$(gh api "/users/${IMAGE_REPO%/*}/packages/container/${IMAGE_REPO#*/}/versions" --paginate 2> /dev/null || echo "[]")
  if ! echo "$pkg_json" | jq -e 'type=="array"' &> /dev/null; then
    record_test "Image Pushed" "FAIL" "GHCR API did not return a version list for $IMAGE_REPO: $(echo "$pkg_json" | jq -r '.message // "unknown error"')"
    return
  fi
  tag_match=$(echo "$pkg_json" | jq -r --arg sha "${RUN_SHA:0:7}" '[.[] | select(.metadata.container.tags[]? | startswith($sha))] | length')

  if [ "${tag_match:-0}" -gt 0 ] 2> /dev/null; then
    record_test "Image Pushed" "PASS" "Found a GHCR image version for $IMAGE_REPO tagged with sha ${RUN_SHA:0:7}"
  else
    record_test "Image Pushed" "FAIL" "No GHCR image version found for $IMAGE_REPO tagged with sha ${RUN_SHA:0:7}"
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
    --arg plane "pipeline" \
    --arg test_name "Golden Path - Pipeline Plane" \
    --arg timestamp "$timestamp" \
    --arg namespace "$NAMESPACE" \
    --arg image_repo "$IMAGE_REPO" \
    --argjson total "$TOTAL_TESTS" --argjson passed "$PASSED_TESTS" --argjson failed "$FAILED_TESTS" \
    --arg pass_rate "${pass_rate}%" --argjson results "$results_json" \
    '{plane:$plane,test_name:$test_name,timestamp:$timestamp,namespace:$namespace,image_repo:$image_repo,summary:{total:$total,passed:$passed,failed:$failed,pass_rate:$pass_rate},results:$results}' \
    > "$REPORT_FILE"
  log_info "Report saved to: $REPORT_FILE"
}

print_summary() {
  echo ""
  echo "=========================================="
  echo "Golden Path - Pipeline Plane Summary"
  echo "=========================================="
  echo "Total: $TOTAL_TESTS  Passed: $PASSED_TESTS  Failed: $FAILED_TESTS"
  if [ $FAILED_TESTS -eq 0 ]; then
    log_success "Pipeline plane verified ✅"
    return 0
  else
    log_error "Pipeline plane has failures ❌"
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
      -i | --image-repo)
        IMAGE_REPO="$2"
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

  log_info "Starting golden path pipeline-plane validation (namespace: $NAMESPACE, image: $IMAGE_REPO)..."
  check_prerequisites || {
    generate_report
    print_summary
    exit 1
  }
  check_latest_run || {
    generate_report
    print_summary
    exit 1
  }
  check_tasks
  check_image_pushed
  generate_report
  print_summary
}

main "$@"
