#!/bin/bash
# =============================================================================
# Script: validate-at-e1-009.sh
# Purpose: Validate AT-E1-009 acceptance criteria for Harbor Container Registry
# Usage: ./scripts/validate-at-e1-009.sh [--namespace NAMESPACE]
# Exit Codes: 0=success, 1=validation failed
# =============================================================================

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
NAMESPACE="${NAMESPACE:-fawkes}"
VERBOSE=false
REPORT_FILE="reports/at-e1-009-validation-$(date +%Y%m%d-%H%M%S).json"
REPORT_DIR="reports"
HARBOR_URL="http://harbor.127.0.0.1.nip.io"

# Test results
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
declare -a TEST_RESULTS=()

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

Validate AT-E1-009 acceptance criteria for Harbor Container Registry.

OPTIONS:
    -n, --namespace         Namespace (default: $NAMESPACE)
    -v, --verbose           Verbose output
    -r, --report            Report file path (default: $REPORT_FILE)
    -u, --url               Harbor URL (default: $HARBOR_URL)
    -h, --help              Show this help message

ENVIRONMENT VARIABLES:
    NAMESPACE               Override default namespace
    HARBOR_URL              Override Harbor URL

ACCEPTANCE CRITERIA:
    - Harbor deployed in fawkes namespace
    - Harbor PostgreSQL database provisioned
    - Harbor pods running (core, portal, registry, jobservice, trivy)
    - Harbor UI accessible via ingress
    - Harbor admin login functional
    - Trivy scanner enabled and functional
    - Default projects created
    - Container image push capability
    - Automatic vulnerability scanning
    - Robot accounts for CI/CD
    - Harbor REST API functional

EXAMPLES:
    $0
    $0 --namespace fawkes
    $0 --verbose
    $0 --report custom-report.json
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

  # Escape JSON special characters
  local escaped_name=$(echo "$test_name" | sed 's/\\/\\\\/g; s/"/\\"/g')
  local escaped_message=$(echo "$message" | sed 's/\\/\\\\/g; s/"/\\"/g')

  TEST_RESULTS+=("{\"name\":\"$escaped_name\",\"status\":\"$status\",\"message\":\"$escaped_message\"}")
}

generate_report() {
  mkdir -p "$REPORT_DIR"

  local status="FAILED"
  if [ "$FAILED_TESTS" -eq 0 ]; then
    status="PASSED"
  fi

  # Build tests JSON array
  local tests_json=""
  if [ ${#TEST_RESULTS[@]} -gt 0 ]; then
    tests_json=$(printf '%s\n' "${TEST_RESULTS[@]}" | paste -sd ',' -)
  fi

  cat > "$REPORT_FILE" << EOF
{
  "test_id": "AT-E1-009",
  "test_name": "Harbor Container Registry Validation",
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "status": "$status",
  "summary": {
    "total": $TOTAL_TESTS,
    "passed": $PASSED_TESTS,
    "failed": $FAILED_TESTS
  },
  "tests": [
    $tests_json
  ]
}
EOF

  log_info "Report generated: $REPORT_FILE"
}

# =============================================================================
# Validation Functions
# =============================================================================

validate_prerequisites() {
  log_info "Validating prerequisites..."

  # Check kubectl
  if ! command -v kubectl &> /dev/null; then
    record_test "Prerequisites" "FAIL" "kubectl not found"
    return 1
  fi

  # Check jq
  if ! command -v jq &> /dev/null; then
    record_test "Prerequisites" "FAIL" "jq not found (required for JSON processing)"
    return 1
  fi

  record_test "Prerequisites" "PASS" "kubectl and jq available"

  # Check cluster access
  if ! kubectl cluster-info &> /dev/null; then
    record_test "Cluster Access" "FAIL" "Cannot access Kubernetes cluster"
    return 1
  fi
  record_test "Cluster Access" "PASS" "Cluster accessible"
}

validate_namespace() {
  log_info "Checking namespace '$NAMESPACE'..."

  if kubectl get namespace "$NAMESPACE" &> /dev/null; then
    local status=$(kubectl get namespace "$NAMESPACE" -o jsonpath='{.status.phase}')
    if [ "$status" = "Active" ]; then
      record_test "Namespace" "PASS" "Namespace $NAMESPACE is Active"
    else
      record_test "Namespace" "FAIL" "Namespace $NAMESPACE status: $status"
      return 1
    fi
  else
    record_test "Namespace" "FAIL" "Namespace $NAMESPACE does not exist"
    return 1
  fi
}

validate_harbor_database() {
  log_info "Checking Harbor PostgreSQL database..."

  # Check for CloudNativePG cluster
  if kubectl get cluster db-harbor-dev -n "$NAMESPACE" &> /dev/null 2>&1; then
    local instances=$(kubectl get cluster db-harbor-dev -n "$NAMESPACE" -o jsonpath='{.spec.instances}' 2> /dev/null || echo "0")
    record_test "Harbor Database Cluster" "PASS" "Harbor PostgreSQL cluster exists with $instances instances"
  elif kubectl get statefulset -n "$NAMESPACE" -l app=postgresql,component=harbor &> /dev/null; then
    record_test "Harbor Database" "PASS" "Harbor database StatefulSet found"
  else
    record_test "Harbor Database" "WARN" "Harbor database configuration not found (may use external DB)"
  fi

  # Check for database credentials secret
  if kubectl get secret db-harbor-credentials -n "$NAMESPACE" &> /dev/null 2>&1 \
    || kubectl get secret harbor-database -n "$NAMESPACE" &> /dev/null 2>&1; then
    record_test "Database Credentials" "PASS" "Harbor database credentials secret exists"
  else
    record_test "Database Credentials" "WARN" "Harbor database credentials secret not found"
  fi
}

validate_harbor_pods() {
  log_info "Checking Harbor pods..."

  local required_components=("core" "portal" "registry" "jobservice")
  local found_count=0
  local running_count=0

  for component in "${required_components[@]}"; do
    local pod_count=$(kubectl get pods -n "$NAMESPACE" -l "component=harbor-${component}" -o json 2> /dev/null | jq '.items | length' || echo "0")

    if [ -z "$pod_count" ] || [ "$pod_count" = "null" ]; then
      pod_count=0
    fi

    if [ "$pod_count" -gt 0 ]; then
      found_count=$((found_count + 1))
      local running=$(kubectl get pods -n "$NAMESPACE" -l "component=harbor-${component}" -o json 2> /dev/null | jq '[.items[] | select(.status.phase=="Running")] | length' || echo "0")
      if [ -z "$running" ] || [ "$running" = "null" ]; then
        running=0
      fi
      if [ "$running" -eq "$pod_count" ]; then
        running_count=$((running_count + 1))
        log_success "Harbor $component pod(s) running"
      else
        log_warning "Harbor $component pod(s) not all running ($running/$pod_count)"
      fi
    else
      # Try alternative label format
      pod_count=$(kubectl get pods -n "$NAMESPACE" -l "app.kubernetes.io/component=${component}" -o json 2> /dev/null | jq '.items | length' || echo "0")
      if [ -z "$pod_count" ] || [ "$pod_count" = "null" ]; then
        pod_count=0
      fi
      if [ "$pod_count" -gt 0 ]; then
        found_count=$((found_count + 1))
        local running=$(kubectl get pods -n "$NAMESPACE" -l "app.kubernetes.io/component=${component}" -o json 2> /dev/null | jq '[.items[] | select(.status.phase=="Running")] | length' || echo "0")
        if [ -z "$running" ] || [ "$running" = "null" ]; then
          running=0
        fi
        if [ "$running" -eq "$pod_count" ]; then
          running_count=$((running_count + 1))
          log_success "Harbor $component pod(s) running"
        fi
      fi
    fi
  done

  if [ "$found_count" -ge 3 ] && [ "$running_count" -ge 3 ]; then
    record_test "Harbor Pods" "PASS" "Harbor core pods running ($running_count/$found_count components)"
  elif [ "$found_count" -gt 0 ]; then
    record_test "Harbor Pods" "PARTIAL" "Some Harbor pods found ($found_count components, $running_count running)"
  else
    record_test "Harbor Pods" "FAIL" "Harbor pods not found"
    return 1
  fi
}

validate_trivy_scanner() {
  log_info "Checking Trivy scanner..."

  if kubectl get pods -n "$NAMESPACE" -l "component=trivy" -o json 2> /dev/null | jq -e '.items[] | select(.status.phase=="Running")' &> /dev/null; then
    record_test "Trivy Scanner" "PASS" "Trivy scanner pod running"
  elif kubectl get pods -n "$NAMESPACE" -l "app.kubernetes.io/component=trivy" -o json 2> /dev/null | jq -e '.items[] | select(.status.phase=="Running")' &> /dev/null; then
    record_test "Trivy Scanner" "PASS" "Trivy scanner pod running"
  else
    record_test "Trivy Scanner" "FAIL" "Trivy scanner pod not found or not running"
    return 1
  fi
}

validate_harbor_services() {
  log_info "Checking Harbor services..."

  if kubectl get service -n "$NAMESPACE" | grep -q harbor; then
    local service_count=$(kubectl get service -n "$NAMESPACE" | grep -c harbor || echo "0")
    record_test "Harbor Services" "PASS" "Found $service_count Harbor service(s)"
  else
    record_test "Harbor Services" "FAIL" "No Harbor services found"
    return 1
  fi
}

validate_harbor_ingress() {
  log_info "Checking Harbor ingress..."

  if kubectl get ingress -n "$NAMESPACE" -o json | jq -e '.items[] | select(.metadata.name | contains("harbor"))' &> /dev/null; then
    local host=$(kubectl get ingress -n "$NAMESPACE" -o json | jq -r '.items[] | select(.metadata.name | contains("harbor")) | .spec.rules[0].host' | head -1)
    local ingress_class=$(kubectl get ingress -n "$NAMESPACE" -o json | jq -r '.items[] | select(.metadata.name | contains("harbor")) | .spec.ingressClassName' | head -1)
    record_test "Harbor Ingress" "PASS" "Harbor ingress configured (host: $host, class: $ingress_class)"
  else
    record_test "Harbor Ingress" "WARN" "Harbor ingress not found (may not be configured yet)"
  fi
}

validate_harbor_ui_accessibility() {
  log_info "Checking Harbor UI accessibility..."

  if command -v curl &> /dev/null; then
    local response_code=$(curl -s -o /dev/null -w "%{http_code}" "$HARBOR_URL" 2> /dev/null || echo "000")

    # Harbor typically redirects to login page (302) or returns 200
    if [ "$response_code" = "200" ] || [ "$response_code" = "302" ] || [ "$response_code" = "301" ]; then
      record_test "Harbor UI" "PASS" "Harbor UI accessible (HTTP $response_code)"
    else
      record_test "Harbor UI" "WARN" "Harbor UI returned HTTP $response_code (may need DNS/ingress configuration)"
    fi
  else
    record_test "Harbor UI" "SKIP" "curl not available to test UI"
  fi
}

validate_harbor_api() {
  log_info "Checking Harbor API..."

  if command -v curl &> /dev/null; then
    local response_code=$(curl -s -o /dev/null -w "%{http_code}" "$HARBOR_URL/api/v2.0/systeminfo" 2> /dev/null || echo "000")

    # Harbor API returns 401 (unauthorized) or 200 (if anonymous access allowed)
    if [ "$response_code" = "200" ] || [ "$response_code" = "401" ]; then
      record_test "Harbor API" "PASS" "Harbor API responding (HTTP $response_code)"
    else
      record_test "Harbor API" "WARN" "Harbor API returned HTTP $response_code (may need configuration)"
    fi
  else
    record_test "Harbor API" "SKIP" "curl not available to test API"
  fi
}

validate_redis_cache() {
  log_info "Checking Redis cache..."

  if kubectl get pods -n "$NAMESPACE" -l "component=redis" -o json 2> /dev/null | jq -e '.items[] | select(.status.phase=="Running")' &> /dev/null; then
    record_test "Redis Cache" "PASS" "Redis pod running"
  elif kubectl get pods -n "$NAMESPACE" -l "app=redis" -o json 2> /dev/null | jq -e '.items[] | select(.status.phase=="Running")' &> /dev/null; then
    record_test "Redis Cache" "PASS" "Redis pod running"
  else
    record_test "Redis Cache" "WARN" "Redis pod not found (Harbor may use external Redis)"
  fi
}

validate_persistent_storage() {
  log_info "Checking Harbor persistent storage..."

  local pvc_count=$(kubectl get pvc -n "$NAMESPACE" | grep -c harbor || echo "0")

  if [ "$pvc_count" -gt 0 ]; then
    local bound_count=$(kubectl get pvc -n "$NAMESPACE" | grep harbor | grep -c Bound || echo "0")
    if [ "$bound_count" -eq "$pvc_count" ]; then
      record_test "Persistent Storage" "PASS" "All Harbor PVCs bound ($bound_count/$pvc_count)"
    else
      record_test "Persistent Storage" "FAIL" "Not all Harbor PVCs bound ($bound_count/$pvc_count)"
      return 1
    fi
  else
    record_test "Persistent Storage" "WARN" "No Harbor PVCs found (may use external storage)"
  fi
}

validate_harbor_credentials() {
  log_info "Checking Harbor admin credentials..."

  if kubectl get secret harbor-admin-credentials -n "$NAMESPACE" &> /dev/null \
    || kubectl get secret harbor-admin -n "$NAMESPACE" &> /dev/null \
    || kubectl get secret -n "$NAMESPACE" | grep -q "harbor.*admin"; then
    record_test "Admin Credentials" "PASS" "Harbor admin credentials secret exists"
  else
    record_test "Admin Credentials" "WARN" "Harbor admin credentials secret not found with expected name"
  fi
}

validate_harbor_configuration() {
  log_info "Checking Harbor configuration files..."

  if [ -d "platform/apps/harbor" ]; then
    record_test "Harbor Config Directory" "PASS" "Harbor configuration directory exists"

    # Check for values.yaml or kustomization
    if [ -f "platform/apps/harbor/values.yaml" ] || [ -f "platform/apps/harbor/kustomization.yaml" ]; then
      record_test "Harbor Config Files" "PASS" "Harbor configuration files found"
    else
      record_test "Harbor Config Files" "WARN" "Harbor configuration files not found in expected location"
    fi
  else
    record_test "Harbor Config Directory" "FAIL" "Harbor configuration directory not found"
    return 1
  fi
}

validate_argocd_application() {
  log_info "Checking Harbor ArgoCD application..."

  if kubectl get application harbor -n argocd &> /dev/null 2>&1 \
    || [ -f "platform/apps/harbor-application.yaml" ]; then
    record_test "ArgoCD Application" "PASS" "Harbor ArgoCD application configured"
  else
    record_test "ArgoCD Application" "WARN" "Harbor ArgoCD application not found"
  fi
}

# =============================================================================
# Main Execution
# =============================================================================

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -n | --namespace)
        NAMESPACE="$2"
        shift 2
        ;;
      -v | --verbose)
        VERBOSE=true
        shift
        ;;
      -r | --report)
        REPORT_FILE="$2"
        shift 2
        ;;
      -u | --url)
        HARBOR_URL="$2"
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
}

main() {
  parse_args "$@"

  echo ""
  log_info "=============================================="
  log_info "AT-E1-009: Harbor Container Registry Validation"
  log_info "=============================================="
  log_info "Namespace: $NAMESPACE"
  log_info "Harbor URL: $HARBOR_URL"
  echo ""

  # Run all validations
  validate_prerequisites || true
  validate_namespace || true
  validate_harbor_configuration || true
  validate_argocd_application || true
  validate_harbor_database || true
  validate_harbor_pods || true
  validate_trivy_scanner || true
  validate_harbor_services || true
  validate_harbor_ingress || true
  validate_harbor_ui_accessibility || true
  validate_harbor_api || true
  validate_redis_cache || true
  validate_persistent_storage || true
  validate_harbor_credentials || true

  echo ""
  log_info "=============================================="
  log_info "Validation Summary"
  log_info "=============================================="
  log_info "Total Tests: $TOTAL_TESTS"
  log_success "Passed: $PASSED_TESTS"
  log_error "Failed: $FAILED_TESTS"
  echo ""

  # Generate report
  generate_report

  # Exit with appropriate code
  if [ "$FAILED_TESTS" -eq 0 ]; then
    log_success "AT-E1-009 validation PASSED!"
    exit 0
  else
    log_error "AT-E1-009 validation FAILED!"
    exit 1
  fi
}

main "$@"
