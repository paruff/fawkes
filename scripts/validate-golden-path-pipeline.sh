#!/bin/bash
# =============================================================================
# Script: validate-golden-path-pipeline.sh
# Purpose: Validate the Pipeline plane of the tracer-bullet golden path
#          (#1751 Phase 3): the latest CI run for services/tracer-bullet
#          actually built, scanned, SBOM'd, and signed an image - not just
#          that the workflow file exists.
# Usage: ./scripts/validate-golden-path-pipeline.sh [--repo OWNER/REPO]
# Requires: gh CLI (authenticated), cosign (optional, for signature check)
# Exit Codes: 0=success, 1=validation failed
# =============================================================================

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

REPO="${REPO:-paruff/fawkes}"
IMAGE="ghcr.io/paruff/tracer-bullet"
WORKFLOW="tracer-bullet-ci.yml"
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
recent push to main triggered $WORKFLOW, and that run built, scanned,
SBOM'd, and signed a real image in GHCR.

OPTIONS:
    -r, --repo REPO     GitHub repo as owner/name (default: $REPO)
    -h, --help          Show this help message
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
  if ! command -v gh &> /dev/null; then
    record_test "Prerequisites" "FAIL" "gh CLI not found"
    return 1
  fi
  if ! gh auth status &> /dev/null; then
    record_test "Prerequisites" "FAIL" "gh CLI not authenticated"
    return 1
  fi
  record_test "Prerequisites" "PASS" "gh CLI installed and authenticated"
}

check_latest_run() {
  log_info "Checking latest $WORKFLOW run on main..."
  local run_json
  run_json=$(gh run list --repo "$REPO" --workflow "$WORKFLOW" --branch main --limit 1 --json databaseId,status,conclusion,headSha,createdAt 2> /dev/null)

  if [ -z "$run_json" ] || [ "$(echo "$run_json" | jq 'length')" -eq 0 ]; then
    record_test "Latest Run" "FAIL" "No $WORKFLOW runs found on main"
    return 1
  fi

  RUN_ID=$(echo "$run_json" | jq -r '.[0].databaseId')
  RUN_STATUS=$(echo "$run_json" | jq -r '.[0].status')
  RUN_CONCLUSION=$(echo "$run_json" | jq -r '.[0].conclusion')
  RUN_SHA=$(echo "$run_json" | jq -r '.[0].headSha')

  if [ "$RUN_STATUS" != "completed" ]; then
    record_test "Latest Run" "FAIL" "Run $RUN_ID is '$RUN_STATUS', not completed yet"
    return 1
  fi

  if [ "$RUN_CONCLUSION" = "success" ]; then
    record_test "Latest Run" "PASS" "Run $RUN_ID (sha ${RUN_SHA:0:7}) completed successfully"
  else
    record_test "Latest Run" "FAIL" "Run $RUN_ID (sha ${RUN_SHA:0:7}) concluded '$RUN_CONCLUSION'"
    return 1
  fi
}

check_jobs() {
  log_info "Checking individual job outcomes for run $RUN_ID..."
  local jobs_json
  jobs_json=$(gh api "repos/$REPO/actions/runs/$RUN_ID/jobs" 2> /dev/null)

  for job in test build security-scan sbom sign-and-attest update-gitops; do
    local conclusion
    conclusion=$(echo "$jobs_json" | jq -r --arg n "$job" '.jobs[] | select(.name==$n or (.name | startswith($n))) | .conclusion' | head -1)
    if [ "$conclusion" = "success" ]; then
      record_test "Job: $job" "PASS" "Job '$job' succeeded"
    elif [ -z "$conclusion" ]; then
      record_test "Job: $job" "FAIL" "Job '$job' not found in this run"
    else
      record_test "Job: $job" "FAIL" "Job '$job' concluded '$conclusion'"
    fi
  done
}

check_image_pushed() {
  log_info "Checking image was pushed to GHCR..."
  local pkg_json
  pkg_json=$(gh api "/repos/$REPO/packages/container/tracer-bullet/versions" --paginate 2> /dev/null || echo "[]")
  local tag_match
  tag_match=$(echo "$pkg_json" | jq -r --arg sha "${RUN_SHA:0:40}" '[.[] | select(.metadata.container.tags[]? | startswith($sha[0:7]))] | length')

  if [ "${tag_match:-0}" -gt 0 ] 2> /dev/null; then
    record_test "Image Pushed" "PASS" "Found a GHCR image version tagged with sha ${RUN_SHA:0:7}"
  else
    record_test "Image Pushed" "FAIL" "No GHCR image version found tagged with sha ${RUN_SHA:0:7} (check GITHUB_TOKEN package read scope)"
  fi
}

check_signature() {
  log_info "Checking image signature (cosign)..."
  if ! command -v cosign &> /dev/null; then
    record_test "Image Signature" "FAIL" "cosign not installed - cannot verify (install to complete this check)"
    return
  fi
  if cosign verify "${IMAGE}:${RUN_SHA:0:7}" \
    --certificate-identity-regexp "https://github.com/${REPO}/.github/workflows/${WORKFLOW}.*" \
    --certificate-oidc-issuer "https://token.actions.githubusercontent.com" &> /dev/null; then
    record_test "Image Signature" "PASS" "cosign verified a valid keyless signature for ${IMAGE}:${RUN_SHA:0:7}"
  else
    record_test "Image Signature" "FAIL" "cosign could not verify a signature for ${IMAGE}:${RUN_SHA:0:7}"
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
    --arg repo "$REPO" \
    --argjson total "$TOTAL_TESTS" --argjson passed "$PASSED_TESTS" --argjson failed "$FAILED_TESTS" \
    --arg pass_rate "${pass_rate}%" --argjson results "$results_json" \
    '{plane:$plane,test_name:$test_name,timestamp:$timestamp,repo:$repo,summary:{total:$total,passed:$passed,failed:$failed,pass_rate:$pass_rate},results:$results}' \
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
      -r | --repo)
        REPO="$2"
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

  log_info "Starting golden path pipeline-plane validation for $REPO..."
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
  check_jobs
  check_image_pushed
  check_signature
  generate_report
  print_summary
}

main "$@"
