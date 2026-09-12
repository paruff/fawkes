#!/bin/bash
# =============================================================================
# Script: validate-golden-path-gitops.sh
# Purpose: Validate the GitOps plane of the python-fawkes-path golden path
#          (#1751 Phase 3, updated #1909): ArgoCD actually synced the image
#          tag CI committed, and the live Deployment matches what's in the
#          python-fawkes-path-gitops repo's HEAD - not just that the Application
#          object exists.
# Usage: ./scripts/validate-golden-path-gitops.sh [--namespace NAMESPACE]
# Requires: kubectl (cluster access), gh CLI (authenticated, to read the
#           gitops repo's manifest)
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
# python-fawkes-path's desired-state manifests were extracted to their own repo in
# #1813/#1804 (paruff/python-fawkes-path-gitops) - there is no local file to read
# git HEAD from any more. Fetched live via `gh api` instead.
GITOPS_REPO="${GITOPS_REPO:-paruff/python-fawkes-path-gitops}"
GITOPS_MANIFEST_PATH="deployment.yaml"
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

Validate the GitOps plane: ArgoCD's python-fawkes-path Application is
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
  if ! kubectl cluster-info &> /dev/null; then
    record_test "Cluster Access" "FAIL" "Cannot access Kubernetes cluster"
    return 1
  fi
  if ! command -v gh &> /dev/null || ! gh auth status &> /dev/null; then
    record_test "Cluster Access" "FAIL" "gh CLI not found or not authenticated (needed to read $GITOPS_REPO)"
    return 1
  fi
  record_test "Cluster Access" "PASS" "Kubernetes cluster is accessible and gh CLI is authenticated"
}

check_application_status() {
  log_info "Checking python-fawkes-path Application status..."
  local app_json
  # ArgoCD Application CRs always live in the ArgoCD namespace, not the
  # workload's own namespace - $NAMESPACE (fawkes/fawkes-alpha/etc.) is where
  # the Deployment/pods live, which is a different thing (see check_pods_ready).
  if ! app_json=$(kubectl get application python-fawkes-path -n "$ARGOCD_NAMESPACE" -o json 2> /dev/null); then
    record_test "Application Exists" "FAIL" "Application 'python-fawkes-path' not found in namespace '$ARGOCD_NAMESPACE'"
    return 1
  fi
  record_test "Application Exists" "PASS" "Application 'python-fawkes-path' found"

  local sync_status health_status
  sync_status=$(echo "$app_json" | jq -r '.status.sync.status // "Unknown"')
  health_status=$(echo "$app_json" | jq -r '.status.health.status // "Unknown"')

  if [ "$sync_status" = "Synced" ]; then
    record_test "Sync Status" "PASS" "python-fawkes-path is Synced"
  else
    record_test "Sync Status" "FAIL" "python-fawkes-path sync status is '$sync_status'"
  fi

  if [ "$health_status" = "Healthy" ]; then
    record_test "Health Status" "PASS" "python-fawkes-path is Healthy"
  else
    record_test "Health Status" "FAIL" "python-fawkes-path health status is '$health_status'"
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
  log_info "Checking live image tag matches $GITOPS_REPO HEAD's manifest..."

  local manifest_content
  manifest_content=$(gh api "repos/$GITOPS_REPO/contents/$GITOPS_MANIFEST_PATH" --jq '.content' 2> /dev/null | base64 -d 2> /dev/null || echo "")

  if [ -z "$manifest_content" ]; then
    record_test "Manifest Present" "FAIL" "Could not fetch $GITOPS_MANIFEST_PATH from $GITOPS_REPO (check gh auth / repo access)"
    return 1
  fi

  local git_image live_image
  git_image=$(echo "$manifest_content" | grep -oE 'image: ghcr\.io/paruff/python-fawkes-path:[^[:space:]]+' | head -1 | sed 's/image: //')

  if [ -z "$git_image" ]; then
    record_test "Git Image Tag" "FAIL" "Could not find python-fawkes-path image line in $GITOPS_REPO's $GITOPS_MANIFEST_PATH"
    return 1
  fi
  record_test "Git Image Tag" "PASS" "$GITOPS_REPO HEAD specifies $git_image"

  live_image=$(kubectl get deployment python-fawkes-path -n "$NAMESPACE" -o jsonpath='{.spec.template.spec.containers[0].image}' 2> /dev/null || echo "")

  if [ -z "$live_image" ]; then
    record_test "Live Deployment" "FAIL" "Deployment 'python-fawkes-path' not found or has no image set"
    return 1
  fi

  if [ "$live_image" = "$git_image" ]; then
    record_test "Image Match" "PASS" "Live Deployment image ($live_image) matches $GITOPS_REPO HEAD"
  else
    record_test "Image Match" "FAIL" "Live Deployment image ($live_image) does NOT match $GITOPS_REPO HEAD ($git_image) - ArgoCD hasn't synced the latest commit yet"
  fi
}

check_pods_ready() {
  log_info "Checking python-fawkes-path pods are Ready..."
  local pods_json ready_count total_count
  pods_json=$(kubectl get pods -n "$NAMESPACE" -l app=python-fawkes-path -o json 2> /dev/null || echo '{"items":[]}')
  total_count=$(echo "$pods_json" | jq '.items | length')

  if [ "$total_count" -eq 0 ]; then
    record_test "Pods Ready" "FAIL" "No python-fawkes-path pods found"
    return 1
  fi

  ready_count=$(echo "$pods_json" | jq '[.items[] | select(.status.conditions[]? | select(.type=="Ready" and .status=="True"))] | length')
  if [ "$ready_count" -eq "$total_count" ]; then
    record_test "Pods Ready" "PASS" "$ready_count/$total_count python-fawkes-path pods Ready"
  else
    record_test "Pods Ready" "FAIL" "$ready_count/$total_count python-fawkes-path pods Ready"
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
