#!/bin/bash
# =============================================================================
# Script: validate-golden-path-gitops.sh
# Purpose: Validate the GitOps plane of the tracer-bullet golden path
#          (#1751 Phase 3): ArgoCD actually synced the image tag CI committed,
#          and the live Deployment matches what's in git HEAD - not just that
#          the Application object exists.
# Usage: ./scripts/validate-golden-path-gitops.sh [--namespace NAMESPACE]
# Exit Codes: 0=success, 1=validation failed
# =============================================================================

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

NAMESPACE="${NAMESPACE:-fawkes}"
ARGOCD_NAMESPACE="${ARGOCD_NAMESPACE:-argocd}"
MANIFEST_FILE="platform/apps/tracer-bullet/deployment.yaml"
REPORT_FILE="reports/golden-path-gitops-validation-$(date +%Y%m%d-%H%M%S).json"
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

Validate the GitOps plane: ArgoCD's tracer-bullet Application is
Synced/Healthy and the live Deployment's image matches git HEAD.

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

check_application_status() {
  log_info "Checking tracer-bullet Application status..."
  local app_json
  if ! app_json=$(kubectl get application tracer-bullet -n "$NAMESPACE" -o json 2> /dev/null); then
    record_test "Application Exists" "FAIL" "Application 'tracer-bullet' not found in namespace '$NAMESPACE'"
    return 1
  fi
  record_test "Application Exists" "PASS" "Application 'tracer-bullet' found"

  local sync_status health_status
  sync_status=$(echo "$app_json" | jq -r '.status.sync.status // "Unknown"')
  health_status=$(echo "$app_json" | jq -r '.status.health.status // "Unknown"')

  if [ "$sync_status" = "Synced" ]; then
    record_test "Sync Status" "PASS" "tracer-bullet is Synced"
  else
    record_test "Sync Status" "FAIL" "tracer-bullet sync status is '$sync_status'"
  fi

  if [ "$health_status" = "Healthy" ]; then
    record_test "Health Status" "PASS" "tracer-bullet is Healthy"
  else
    record_test "Health Status" "FAIL" "tracer-bullet health status is '$health_status'"
  fi

  local auto_sync self_heal
  auto_sync=$(echo "$app_json" | jq -r '.spec.syncPolicy.automated != null')
  self_heal=$(echo "$app_json" | jq -r '.spec.syncPolicy.automated.selfHeal // false')
  if [ "$auto_sync" = "true" ] && [ "$self_heal" = "true" ]; then
    record_test "Auto-Sync + Self-Heal" "PASS" "automated sync with selfHeal is enabled"
  else
    record_test "Auto-Sync + Self-Heal" "FAIL" "automated sync (automated=$auto_sync, selfHeal=$self_heal) not fully enabled"
  fi
}

check_image_matches_git() {
  log_info "Checking live image tag matches git HEAD's manifest..."

  if [ ! -f "$MANIFEST_FILE" ]; then
    record_test "Manifest Present" "FAIL" "$MANIFEST_FILE not found locally"
    return 1
  fi

  local git_image live_image
  git_image=$(grep -oE 'image: ghcr\.io/paruff/tracer-bullet:[^[:space:]]+' "$MANIFEST_FILE" | head -1 | sed 's/image: //')

  if [ -z "$git_image" ]; then
    record_test "Git Image Tag" "FAIL" "Could not find tracer-bullet image line in $MANIFEST_FILE"
    return 1
  fi
  record_test "Git Image Tag" "PASS" "git HEAD specifies $git_image"

  live_image=$(kubectl get deployment tracer-bullet -n "$NAMESPACE" -o jsonpath='{.spec.template.spec.containers[0].image}' 2> /dev/null || echo "")

  if [ -z "$live_image" ]; then
    record_test "Live Deployment" "FAIL" "Deployment 'tracer-bullet' not found or has no image set"
    return 1
  fi

  if [ "$live_image" = "$git_image" ]; then
    record_test "Image Match" "PASS" "Live Deployment image ($live_image) matches git HEAD"
  else
    record_test "Image Match" "FAIL" "Live Deployment image ($live_image) does NOT match git HEAD ($git_image) - ArgoCD hasn't synced the latest commit yet"
  fi
}

check_pods_ready() {
  log_info "Checking tracer-bullet pods are Ready..."
  local pods_json ready_count total_count
  pods_json=$(kubectl get pods -n "$NAMESPACE" -l app=tracer-bullet -o json 2> /dev/null || echo '{"items":[]}')
  total_count=$(echo "$pods_json" | jq '.items | length')

  if [ "$total_count" -eq 0 ]; then
    record_test "Pods Ready" "FAIL" "No tracer-bullet pods found"
    return 1
  fi

  ready_count=$(echo "$pods_json" | jq '[.items[] | select(.status.conditions[]? | select(.type=="Ready" and .status=="True"))] | length')
  if [ "$ready_count" -eq "$total_count" ]; then
    record_test "Pods Ready" "PASS" "$ready_count/$total_count tracer-bullet pods Ready"
  else
    record_test "Pods Ready" "FAIL" "$ready_count/$total_count tracer-bullet pods Ready"
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
    --arg plane "gitops" \
    --arg test_name "Golden Path - GitOps Plane" \
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
  echo "Golden Path - GitOps Plane Summary"
  echo "=========================================="
  echo "Total: $TOTAL_TESTS  Passed: $PASSED_TESTS  Failed: $FAILED_TESTS"
  if [ $FAILED_TESTS -eq 0 ]; then
    log_success "GitOps plane verified ✅"
    return 0
  else
    log_error "GitOps plane has failures ❌"
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

  log_info "Starting golden path gitops-plane validation (namespace: $NAMESPACE)..."
  check_cluster_access || {
    generate_report
    print_summary
    exit 1
  }
  check_application_status
  check_image_matches_git
  check_pods_ready
  generate_report
  print_summary
}

main "$@"
