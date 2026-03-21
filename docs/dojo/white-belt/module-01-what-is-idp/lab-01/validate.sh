#!/bin/bash
# =============================================================================
# Script: validate.sh
# Purpose: Validate White Belt Module 01 Lab 01 completion criteria
# Usage:   ./docs/dojo/white-belt/module-01-what-is-idp/lab-01/validate.sh
#          make dojo-validate BELT=white MODULE=01 LAB=01
# Exit Codes: 0=all checks passed, 1=one or more checks failed
# =============================================================================

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Lab configuration
LAB_NAMESPACE="dojo-lab-01"
DEPLOYMENT_NAME="hello-fawkes"
SERVICE_NAME="hello-fawkes"
ARGOCD_NAMESPACE="${ARGOCD_NAMESPACE:-argocd}"
BACKSTAGE_URL="${BACKSTAGE_URL:-http://localhost:7007}"
GRAFANA_URL="${GRAFANA_URL:-http://localhost:3000}"
CHECK_HTTP_PORT="${CHECK_HTTP_PORT:-18888}"

# Dojo progress configuration
DOJO_BELT="white"
DOJO_LAB_ID="lab-01"
DOJO_PROGRESS_CONFIGMAP="fawkes-dojo-progress"
DOJO_PROGRESS_NAMESPACE="fawkes"
DOJO_GITHUB_USERNAME="${GITHUB_USER:-$(git config user.name 2> /dev/null | tr ' ' '-' | tr '[:upper:]' '[:lower:]' || echo "")}"

# Test results
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
PF_PID=""

# =============================================================================
# Helper Functions
# =============================================================================

log_info() {
  echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
  echo -e "${GREEN}[✓]${NC} $1"
}

log_error() {
  echo -e "${RED}[✗]${NC} $1"
}

log_warning() {
  echo -e "${YELLOW}[!]${NC} $1"
}

usage() {
  cat << EOF
Usage: $0 [OPTIONS]

Validate White Belt Module 01 Lab 01 completion criteria.

OPTIONS:
    -n, --namespace     Lab namespace (default: $LAB_NAMESPACE)
    -a, --argocd-ns     ArgoCD namespace (default: $ARGOCD_NAMESPACE)
    -b, --backstage     Backstage URL (default: $BACKSTAGE_URL)
    -g, --grafana       Grafana URL (default: $GRAFANA_URL)
    -p, --http-port     Local port for HTTP check (default: $CHECK_HTTP_PORT)
    -h, --help          Show this help message

ENVIRONMENT VARIABLES:
    ARGOCD_NAMESPACE    Override default ArgoCD namespace
    BACKSTAGE_URL       Override default Backstage URL
    GRAFANA_URL         Override default Grafana URL
    CHECK_HTTP_PORT     Override local port used for port-forward HTTP check

CHECKS PERFORMED:
    1. kubectl is installed
    2. Kubernetes cluster is accessible
    3. Namespace '$LAB_NAMESPACE' exists and is Active
    4. Deployment '$DEPLOYMENT_NAME' has at least 1 ready replica
    5. Service '$SERVICE_NAME' exists
    6. HTTP GET to service returns 200
    7. ArgoCD Application '$DEPLOYMENT_NAME' is Synced (skipped if ArgoCD absent)
    8. Backstage API is reachable
    9. Grafana API is reachable

EXAMPLES:
    $0
    $0 --namespace dojo-lab-01
    $0 --backstage http://localhost:7007 --grafana http://localhost:3000

EOF
}

record_test() {
  local test_name="$1"
  local status="$2"
  local message="$3"

  TOTAL_TESTS=$((TOTAL_TESTS + 1))

  if [ "$status" = "PASS" ]; then
    PASSED_TESTS=$((PASSED_TESTS + 1))
    log_success "$test_name: $message"
  else
    FAILED_TESTS=$((FAILED_TESTS + 1))
    log_error "$test_name: $message"
  fi
}

cleanup() {
  if [ -n "$PF_PID" ]; then
    kill "$PF_PID" 2> /dev/null || true
    PF_PID=""
  fi
}

# =============================================================================
# Dojo Progress Functions
# =============================================================================

# write_dojo_progress — patches the fawkes-dojo-progress ConfigMap to record
# that DOJO_GITHUB_USERNAME has completed DOJO_LAB_ID in DOJO_BELT.
#
# This function is called automatically after all tests pass.
# It is a best-effort update: failures emit a warning but do not fail the
# overall validation run (exit code is still 0 on test success).
#
# Requires:
#   - kubectl with access to the fawkes namespace
#   - RBAC: Role dojo-progress-writer bound to the running ServiceAccount
#     (see platform/backstage/plugins/dojo-progress/rbac.yaml)
write_dojo_progress() {
  local username="$1"
  local belt="$2"
  local lab_id="$3"
  local status="${4:-PASS}"

  if [ -z "$username" ]; then
    log_warning "DOJO_GITHUB_USERNAME not set — skipping progress update."
    log_warning "Set GITHUB_USER env var or configure git user.name to enable tracking."
    return 0
  fi

  if ! kubectl get namespace "$DOJO_PROGRESS_NAMESPACE" > /dev/null 2>&1; then
    log_warning "Namespace '$DOJO_PROGRESS_NAMESPACE' not found — skipping progress update."
    return 0
  fi

  log_info "Recording dojo progress: @${username} ${belt}/${lab_id} = ${status}"

  # Ensure the ConfigMap exists (create it if it doesn't).
  if ! kubectl get configmap "$DOJO_PROGRESS_CONFIGMAP" \
    -n "$DOJO_PROGRESS_NAMESPACE" > /dev/null 2>&1; then
    log_info "Creating ConfigMap '$DOJO_PROGRESS_CONFIGMAP'..."
    kubectl create configmap "$DOJO_PROGRESS_CONFIGMAP" \
      -n "$DOJO_PROGRESS_NAMESPACE" \
      --from-literal="$username={}" 2> /dev/null || true
  fi

  # Read existing user progress (may be empty or absent).
  local existing
  existing=$(kubectl get configmap "$DOJO_PROGRESS_CONFIGMAP" \
    -n "$DOJO_PROGRESS_NAMESPACE" \
    -o jsonpath="{.data.${username}}" 2> /dev/null || echo "")

  # Build the updated JSON blob using Python.
  # Pass shell variables through environment variables to avoid injection.
  local updated_json
  updated_json=$(DOJO_EXISTING="$existing" \
    DOJO_BELT="$belt" \
    DOJO_LAB_ID="$lab_id" \
    DOJO_STATUS="$status" \
    python3 - << 'PYEOF'
import json
import os

raw = os.environ.get("DOJO_EXISTING", "")
belt = os.environ["DOJO_BELT"]
lab_id = os.environ["DOJO_LAB_ID"]
status = os.environ["DOJO_STATUS"]

try:
    progress = json.loads(raw) if raw.strip() else {}
except Exception:
    progress = {}

belts = ["white", "yellow", "green", "brown", "black"]
for b in belts:
    if b not in progress:
        progress[b] = {"labs": {}}

progress[belt]["labs"][lab_id] = status
print(json.dumps(progress))
PYEOF
  )

  if [ -z "$updated_json" ]; then
    log_warning "Failed to compute updated progress JSON — skipping ConfigMap patch."
    return 0
  fi

  # Write the patch payload to a temp file to avoid quoting/escaping issues
  # with special characters in the JSON value.
  local patch_file
  patch_file=$(mktemp /tmp/dojo-progress-patch.XXXXXX.json)
  python3 -c "
import json, sys
payload = {'data': {'$username': sys.stdin.read()}}
print(json.dumps(payload))
" <<< "$updated_json" > "$patch_file"

  if kubectl patch configmap "$DOJO_PROGRESS_CONFIGMAP" \
    -n "$DOJO_PROGRESS_NAMESPACE" \
    --type merge \
    --patch-file "$patch_file" > /dev/null 2>&1; then
    log_success "Progress recorded: @${username} ${belt}/${lab_id} = ${status}"
  else
    log_warning "Could not patch ConfigMap '$DOJO_PROGRESS_CONFIGMAP'."
    log_warning "Ensure RBAC is applied: kubectl apply -f platform/backstage/plugins/dojo-progress/rbac.yaml"
  fi

  rm -f "$patch_file"
}

# =============================================================================
# Check Functions
# =============================================================================

check_prerequisites() {
  log_info "Checking prerequisites..."

  if command -v kubectl > /dev/null 2>&1; then
    record_test "Prerequisites" "PASS" "kubectl is installed"
  else
    record_test "Prerequisites" "FAIL" \
      "kubectl not found — install from https://kubernetes.io/docs/tasks/tools/"
  fi
}

check_cluster_access() {
  log_info "Checking cluster access..."

  if kubectl cluster-info > /dev/null 2>&1; then
    record_test "Cluster Access" "PASS" "Kubernetes cluster is accessible"
    return 0
  else
    record_test "Cluster Access" "FAIL" \
      "Cannot access Kubernetes cluster — run 'make dev-up' first"
    return 1
  fi
}

check_namespace() {
  log_info "Checking namespace '$LAB_NAMESPACE'..."

  if kubectl get namespace "$LAB_NAMESPACE" > /dev/null 2>&1; then
    local phase
    phase=$(kubectl get namespace "$LAB_NAMESPACE" -o jsonpath='{.status.phase}')
    if [ "$phase" = "Active" ]; then
      record_test "Namespace" "PASS" "'$LAB_NAMESPACE' exists and is Active"
    else
      record_test "Namespace" "FAIL" \
        "'$LAB_NAMESPACE' exists but phase is '$phase' (expected Active)"
    fi
  else
    record_test "Namespace" "FAIL" \
      "Namespace '$LAB_NAMESPACE' not found — run: kubectl apply -f solution/namespace.yaml"
  fi
}

check_deployment() {
  log_info "Checking deployment '$DEPLOYMENT_NAME'..."

  if ! kubectl get deployment "$DEPLOYMENT_NAME" -n "$LAB_NAMESPACE" > /dev/null 2>&1; then
    record_test "Deployment" "FAIL" \
      "Deployment '$DEPLOYMENT_NAME' not found in '$LAB_NAMESPACE' — run: kubectl apply -f solution/deployment.yaml"
    return
  fi

  local ready
  ready=$(kubectl get deployment "$DEPLOYMENT_NAME" -n "$LAB_NAMESPACE" \
    -o jsonpath='{.status.readyReplicas}' 2> /dev/null || echo "0")

  if [ "${ready:-0}" -ge 1 ]; then
    local desired
    desired=$(kubectl get deployment "$DEPLOYMENT_NAME" -n "$LAB_NAMESPACE" \
      -o jsonpath='{.spec.replicas}' 2> /dev/null || echo "?")
    record_test "Deployment" "PASS" \
      "'$DEPLOYMENT_NAME' has $ready/$desired ready replicas"
  else
    record_test "Deployment" "FAIL" \
      "'$DEPLOYMENT_NAME' has 0 ready replicas — check: kubectl get pods -n $LAB_NAMESPACE"
  fi
}

check_service() {
  log_info "Checking service '$SERVICE_NAME'..."

  if kubectl get service "$SERVICE_NAME" -n "$LAB_NAMESPACE" > /dev/null 2>&1; then
    record_test "Service" "PASS" \
      "Service '$SERVICE_NAME' exists in '$LAB_NAMESPACE'"
  else
    record_test "Service" "FAIL" \
      "Service '$SERVICE_NAME' not found — run: kubectl apply -f solution/service.yaml"
  fi
}

check_http() {
  log_info "Checking HTTP response from service..."

  local port="$CHECK_HTTP_PORT"
  local http_code=""
  local retries=0
  local max_retries=10

  # Start port-forward in background
  kubectl port-forward "svc/$SERVICE_NAME" "${port}:80" \
    -n "$LAB_NAMESPACE" > /dev/null 2>&1 &
  PF_PID=$!

  # Wait for port-forward to establish by polling the port
  while [ "$retries" -lt "$max_retries" ]; do
    if kill -0 "$PF_PID" 2> /dev/null \
      && curl -s -o /dev/null --max-time 1 "http://localhost:${port}/" 2> /dev/null; then
      break
    fi
    sleep 1
    retries=$((retries + 1))
  done

  if kill -0 "$PF_PID" 2> /dev/null; then
    http_code=$(curl -s -o /dev/null -w "%{http_code}" \
      --max-time 5 "http://localhost:${port}/" 2> /dev/null || echo "000")

    kill "$PF_PID" 2> /dev/null || true
    PF_PID=""

    if [ "$http_code" = "200" ]; then
      record_test "HTTP Check" "PASS" \
        "'$SERVICE_NAME' returned HTTP $http_code"
    else
      record_test "HTTP Check" "FAIL" \
        "'$SERVICE_NAME' returned HTTP $http_code (expected 200)"
    fi
  else
    PF_PID=""
    record_test "HTTP Check" "FAIL" \
      "Port-forward to '$SERVICE_NAME' failed — check deployment is ready"
  fi
}

check_argocd() {
  log_info "Checking ArgoCD application..."

  if ! kubectl get namespace "$ARGOCD_NAMESPACE" > /dev/null 2>&1; then
    log_warning "ArgoCD namespace '$ARGOCD_NAMESPACE' not found — skipping ArgoCD check"
    return
  fi

  if ! kubectl get application "$DEPLOYMENT_NAME" -n "$ARGOCD_NAMESPACE" > /dev/null 2>&1; then
    record_test "ArgoCD Application" "FAIL" \
      "Application '$DEPLOYMENT_NAME' not found in '$ARGOCD_NAMESPACE' — run: kubectl apply -f solution/argocd-application.yaml"
    return
  fi

  local sync_status
  sync_status=$(kubectl get application "$DEPLOYMENT_NAME" -n "$ARGOCD_NAMESPACE" \
    -o jsonpath='{.status.sync.status}' 2> /dev/null || echo "Unknown")

  if [ "$sync_status" = "Synced" ]; then
    record_test "ArgoCD Application" "PASS" \
      "'$DEPLOYMENT_NAME' sync status is $sync_status"
  else
    record_test "ArgoCD Application" "FAIL" \
      "'$DEPLOYMENT_NAME' sync status is '$sync_status' (expected Synced)"
  fi
}

check_backstage() {
  log_info "Checking Backstage catalog..."

  local http_code
  http_code=$(curl -s -o /dev/null -w "%{http_code}" \
    --max-time 5 "${BACKSTAGE_URL}/api/catalog/entities" 2> /dev/null || echo "000")

  if [ "$http_code" = "200" ]; then
    record_test "Backstage Catalog" "PASS" \
      "Backstage API is reachable at ${BACKSTAGE_URL}"
  else
    record_test "Backstage Catalog" "FAIL" \
      "Backstage API returned HTTP $http_code at ${BACKSTAGE_URL} — ensure Backstage is running"
  fi
}

check_grafana() {
  log_info "Checking Grafana observability..."

  local http_code
  http_code=$(curl -s -o /dev/null -w "%{http_code}" \
    --max-time 5 "${GRAFANA_URL}/api/health" 2> /dev/null || echo "000")

  if [ "$http_code" = "200" ]; then
    record_test "Grafana Observability" "PASS" \
      "Grafana API is reachable at ${GRAFANA_URL}"
  else
    record_test "Grafana Observability" "FAIL" \
      "Grafana API returned HTTP $http_code at ${GRAFANA_URL} — ensure Grafana is running"
  fi
}

print_summary() {
  echo ""
  echo "=========================================="
  echo "White Belt Module 01 Lab 01 — Results"
  echo "=========================================="
  echo "Total Tests : $TOTAL_TESTS"
  echo "Passed      : $PASSED_TESTS"
  echo "Failed      : $FAILED_TESTS"
  echo ""

  if [ "$FAILED_TESTS" -eq 0 ]; then
    log_success "All tests passed! ✅"
    echo ""
    echo "🎉 Congratulations! You have completed White Belt Module 1 Lab 01."
    echo "   Your service is deployed, synced via GitOps, and observable."
    echo "   Move on to Module 02: DORA Metrics."
    write_dojo_progress \
      "$DOJO_GITHUB_USERNAME" \
      "$DOJO_BELT" \
      "$DOJO_LAB_ID" \
      "PASS"
    return 0
  else
    log_error "Some tests failed! ❌"
    echo ""
    echo "Please review the failures above. Common fixes:"
    echo "  - Run 'make dev-up' if the cluster is not running"
    echo "  - Apply solution manifests: kubectl apply -f solution/"
    echo "  - Wait for pods to be ready: kubectl get pods -n $LAB_NAMESPACE"
    echo "  - See lab-01/instructions.md for step-by-step guidance"
    return 1
  fi
}

# =============================================================================
# Main Execution
# =============================================================================

main() {
  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case $1 in
      -n | --namespace)
        LAB_NAMESPACE="$2"
        shift 2
        ;;
      -a | --argocd-ns)
        ARGOCD_NAMESPACE="$2"
        shift 2
        ;;
      -b | --backstage)
        BACKSTAGE_URL="$2"
        shift 2
        ;;
      -g | --grafana)
        GRAFANA_URL="$2"
        shift 2
        ;;
      -p | --http-port)
        CHECK_HTTP_PORT="$2"
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

  trap cleanup EXIT

  log_info "Starting White Belt Module 01 Lab 01 validation..."
  log_info "Lab namespace     : $LAB_NAMESPACE"
  log_info "ArgoCD namespace  : $ARGOCD_NAMESPACE"
  log_info "Backstage URL     : $BACKSTAGE_URL"
  log_info "Grafana URL       : $GRAFANA_URL"
  echo ""

  check_prerequisites
  check_cluster_access || {
    echo ""
    echo "Cannot continue without cluster access. Run 'make dev-up'."
    exit 1
  }
  check_namespace
  check_deployment
  check_service
  check_http
  check_argocd
  check_backstage
  check_grafana

  print_summary
}

main "$@"
