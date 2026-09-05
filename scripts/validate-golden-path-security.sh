#!/bin/bash
# =============================================================================
# Script: validate-golden-path-security.sh
# Purpose: Validate the Security plane of the tracer-bullet golden path
#          (#1751 Phase 3): the live deployed image is signed, workload pods
#          run with a hardened securityContext, and smart-alerting's alert
#          endpoints actually reject unauthenticated requests (AUD-2) - not
#          just that these things are declared in git.
# Usage: ./scripts/validate-golden-path-security.sh [--namespace NS]
# Requires: cosign (optional, for signature check)
# Exit Codes: 0=success, 1=validation failed
# =============================================================================

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

NAMESPACE="${NAMESPACE:-fawkes}"
REPO="${REPO:-paruff/fawkes}"
TRACER_BULLET_IMAGE="ghcr.io/paruff/tracer-bullet"
WORKFLOW="tracer-bullet-ci.yml"
REPORT_FILE="reports/golden-path-security-validation-$(date +%Y%m%d-%H%M%S).json"
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

Validate the Security plane: the live tracer-bullet image is signed,
workload pods run hardened, and smart-alerting rejects unauthenticated
alert-ingestion requests.

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

check_live_image_signature() {
  log_info "Checking the live tracer-bullet image is signed..."
  if ! command -v cosign &> /dev/null; then
    record_test "Live Image Signature" "FAIL" "cosign not installed - cannot verify (install to complete this check)"
    return
  fi

  local live_image
  live_image=$(kubectl get deployment tracer-bullet -n "$NAMESPACE" -o jsonpath='{.spec.template.spec.containers[0].image}' 2> /dev/null || echo "")
  if [ -z "$live_image" ]; then
    record_test "Live Image Signature" "FAIL" "Could not read the live tracer-bullet Deployment image"
    return
  fi

  if cosign verify "$live_image" \
    --certificate-identity-regexp "https://github.com/${REPO}/.github/workflows/${WORKFLOW}.*" \
    --certificate-oidc-issuer "https://token.actions.githubusercontent.com" &> /dev/null; then
    record_test "Live Image Signature" "PASS" "cosign verified a valid keyless signature for the live image ($live_image)"
  else
    record_test "Live Image Signature" "FAIL" "cosign could not verify a signature for the live image ($live_image)"
  fi
}

check_pod_security_context() {
  local deployment="$1"
  log_info "Checking pod securityContext for '$deployment'..."
  local dep_json
  if ! dep_json=$(kubectl get deployment "$deployment" -n "$NAMESPACE" -o json 2> /dev/null); then
    record_test "SecurityContext: $deployment" "FAIL" "Deployment '$deployment' not found in namespace '$NAMESPACE'"
    return
  fi

  local run_as_non_root priv_esc
  run_as_non_root=$(echo "$dep_json" | jq -r '.spec.template.spec.securityContext.runAsNonRoot // .spec.template.spec.containers[0].securityContext.runAsNonRoot // false')
  priv_esc=$(echo "$dep_json" | jq -r '.spec.template.spec.containers[0].securityContext.allowPrivilegeEscalation // true')

  if [ "$run_as_non_root" = "true" ]; then
    record_test "SecurityContext runAsNonRoot: $deployment" "PASS" "runAsNonRoot is true"
  else
    record_test "SecurityContext runAsNonRoot: $deployment" "FAIL" "runAsNonRoot is not set to true"
  fi

  if [ "$priv_esc" = "false" ]; then
    record_test "SecurityContext allowPrivilegeEscalation: $deployment" "PASS" "allowPrivilegeEscalation is false"
  else
    record_test "SecurityContext allowPrivilegeEscalation: $deployment" "FAIL" "allowPrivilegeEscalation is not set to false"
  fi
}

check_smart_alerting_auth() {
  log_info "Checking smart-alerting rejects unauthenticated alert-ingestion requests (AUD-2)..."
  if ! kubectl get deployment smart-alerting -n "$NAMESPACE" &> /dev/null; then
    record_test "smart-alerting Auth Check" "FAIL" "Deployment 'smart-alerting' not found in namespace '$NAMESPACE' - skipping"
    return
  fi

  kubectl port-forward -n "$NAMESPACE" deploy/smart-alerting 18080:8000 &> /tmp/smart-alerting-pf.log &
  local pf_pid=$!
  sleep 3

  local status_code
  status_code=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 -X POST \
    "http://localhost:18080/api/v1/alerts/webhook" -H "Content-Type: application/json" -d '{}' 2> /dev/null || true)
  status_code="${status_code:-000}"
  kill "$pf_pid" &> /dev/null || true

  if [ "$status_code" = "401" ] || [ "$status_code" = "403" ]; then
    record_test "smart-alerting Auth Check" "PASS" "Unauthenticated request correctly rejected (HTTP $status_code)"
  elif [ "$status_code" = "000" ]; then
    record_test "smart-alerting Auth Check" "FAIL" "Could not reach smart-alerting via port-forward"
  else
    record_test "smart-alerting Auth Check" "FAIL" "Unauthenticated request returned HTTP $status_code (expected 401/403)"
  fi
}

check_no_placeholder_credentials() {
  log_info "Checking for CHANGE_ME_* placeholder credentials in platform/apps/..."
  local hits
  hits=$(grep -rl "CHANGE_ME_" platform/apps/ 2> /dev/null | wc -l | tr -d ' ')
  if [ "$hits" -eq 0 ]; then
    record_test "No Placeholder Credentials" "PASS" "No CHANGE_ME_* placeholders found in platform/apps/"
  else
    record_test "No Placeholder Credentials" "FAIL" "$hits file(s) under platform/apps/ still contain CHANGE_ME_* placeholders"
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
    --arg plane "security" \
    --arg test_name "Golden Path - Security Plane" \
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
  echo "Golden Path - Security Plane Summary"
  echo "=========================================="
  echo "Total: $TOTAL_TESTS  Passed: $PASSED_TESTS  Failed: $FAILED_TESTS"
  if [ $FAILED_TESTS -eq 0 ]; then
    log_success "Security plane verified ✅"
    return 0
  else
    log_error "Security plane has failures ❌"
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

  log_info "Starting golden path security-plane validation (namespace: $NAMESPACE)..."
  check_cluster_access || {
    generate_report
    print_summary
    exit 1
  }
  check_live_image_signature
  check_pod_security_context "tracer-bullet"
  check_pod_security_context "smart-alerting"
  check_smart_alerting_auth
  check_no_placeholder_credentials
  generate_report
  print_summary
}

main "$@"
