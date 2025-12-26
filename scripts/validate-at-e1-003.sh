#!/bin/bash
# =============================================================================
# Script: validate-at-e1-003.sh
# Purpose: Validate AT-E1-003 acceptance criteria for Backstage Developer Portal
# Usage: ./scripts/validate-at-e1-003.sh [--namespace NAMESPACE]
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
REPORT_FILE="reports/at-e1-003-validation-$(date +%Y%m%d-%H%M%S).json"
REPORT_DIR="reports"

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

Validate AT-E1-003 acceptance criteria for Backstage Developer Portal.

OPTIONS:
    -n, --namespace         Namespace (default: $NAMESPACE)
    -v, --verbose           Verbose output
    -r, --report            Report file path (default: $REPORT_FILE)
    -h, --help              Show this help message

ENVIRONMENT VARIABLES:
    NAMESPACE               Override default namespace

ACCEPTANCE CRITERIA:
    - Backstage deployed from platform/apps/backstage/
    - PostgreSQL backend deployed and initialized
    - GitHub OAuth configured
    - Software catalog populated with 3 templates:
      * Java Spring Boot
      * Python FastAPI
      * Node.js Express
    - TechDocs plugin enabled and rendering
    - Service catalog shows deployed apps
    - Backstage UI loads in <3 seconds
    - API responds with <500ms latency

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

  TEST_RESULTS+=("{\"name\":\"$test_name\",\"status\":\"$status\",\"message\":\"$message\"}")
}

generate_report() {
  mkdir -p "$REPORT_DIR"

  local status="FAILED"
  if [ "$FAILED_TESTS" -eq 0 ]; then
    status="PASSED"
  fi

  cat > "$REPORT_FILE" << EOF
{
  "test_id": "AT-E1-003",
  "test_name": "Backstage Developer Portal Validation",
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "status": "$status",
  "summary": {
    "total": $TOTAL_TESTS,
    "passed": $PASSED_TESTS,
    "failed": $FAILED_TESTS
  },
  "tests": [
    $(
    IFS=,
    echo "${TEST_RESULTS[*]}"
  )
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
  record_test "Prerequisites" "PASS" "kubectl available"

  # Check cluster access
  if ! kubectl cluster-info &> /dev/null; then
    record_test "Cluster Access" "FAIL" "Cannot access Kubernetes cluster"
    return 1
  fi
  record_test "Cluster Access" "PASS" "Kubernetes cluster accessible"

  return 0
}

validate_namespace() {
  log_info "Validating namespace..."

  if ! kubectl get namespace "$NAMESPACE" &> /dev/null; then
    record_test "Namespace" "FAIL" "Namespace $NAMESPACE does not exist"
    return 1
  fi
  record_test "Namespace" "PASS" "Namespace $NAMESPACE exists"

  return 0
}

validate_backstage_deployment() {
  log_info "Validating Backstage deployment..."

  # Check if deployment exists
  if ! kubectl get deployment backstage -n "$NAMESPACE" &> /dev/null; then
    record_test "Backstage Deployment" "FAIL" "Backstage deployment not found"
    return 1
  fi

  # Check deployment status
  local ready_replicas=$(kubectl get deployment backstage -n "$NAMESPACE" -o jsonpath='{.status.readyReplicas}' 2> /dev/null || echo "0")
  local desired_replicas=$(kubectl get deployment backstage -n "$NAMESPACE" -o jsonpath='{.spec.replicas}' 2> /dev/null || echo "0")

  if [ "$ready_replicas" -lt "$desired_replicas" ]; then
    record_test "Backstage Deployment" "FAIL" "Only $ready_replicas/$desired_replicas replicas ready"
    return 1
  fi

  record_test "Backstage Deployment" "PASS" "$ready_replicas/$desired_replicas replicas running"
  return 0
}

validate_postgresql_backend() {
  log_info "Validating PostgreSQL backend..."

  # Check for PostgreSQL cluster
  if kubectl get cluster db-backstage-dev -n "$NAMESPACE" &> /dev/null; then
    local cluster_status=$(kubectl get cluster db-backstage-dev -n "$NAMESPACE" -o jsonpath='{.status.phase}' 2> /dev/null || echo "Unknown")

    if [ "$cluster_status" != "Cluster in healthy state" ]; then
      record_test "PostgreSQL Backend" "FAIL" "PostgreSQL cluster status: $cluster_status"
      return 1
    fi
    record_test "PostgreSQL Backend" "PASS" "PostgreSQL cluster healthy"
  else
    log_warning "PostgreSQL cluster not found, checking for pods..."

    # Fallback: check for PostgreSQL pods
    local pg_pods=$(kubectl get pods -n "$NAMESPACE" -l app=postgresql -o name 2> /dev/null | wc -l)
    if [ "$pg_pods" -gt 0 ]; then
      record_test "PostgreSQL Backend" "PASS" "PostgreSQL pods running ($pg_pods pods)"
    else
      record_test "PostgreSQL Backend" "WARN" "PostgreSQL backend not found (may be external)"
    fi
  fi

  return 0
}

validate_oauth_configuration() {
  log_info "Validating GitHub OAuth configuration..."

  # Check if OAuth secret exists
  if ! kubectl get secret backstage-oauth-credentials -n "$NAMESPACE" &> /dev/null; then
    record_test "GitHub OAuth Config" "WARN" "OAuth secret not found (optional for local testing)"
    return 0
  fi

  # Check if secret has required keys
  local has_client_id=$(kubectl get secret backstage-oauth-credentials -n "$NAMESPACE" -o jsonpath='{.data.github-client-id}' 2> /dev/null)
  local has_client_secret=$(kubectl get secret backstage-oauth-credentials -n "$NAMESPACE" -o jsonpath='{.data.github-client-secret}' 2> /dev/null)

  if [ -z "$has_client_id" ] || [ -z "$has_client_secret" ]; then
    record_test "GitHub OAuth Config" "WARN" "OAuth credentials incomplete (optional for local testing)"
    return 0
  fi

  record_test "GitHub OAuth Config" "PASS" "OAuth credentials configured"
  return 0
}

validate_catalog_templates() {
  log_info "Validating software catalog templates..."

  # Find a running Backstage pod
  local pod_name=$(kubectl get pods -n "$NAMESPACE" -l app.kubernetes.io/name=backstage -o jsonpath='{.items[0].metadata.name}' 2> /dev/null)

  if [ -z "$pod_name" ]; then
    record_test "Software Catalog" "FAIL" "Cannot find Backstage pod"
    return 1
  fi

  # Check catalog API for templates
  local catalog_response=$(kubectl exec -n "$NAMESPACE" "$pod_name" -- curl -s -f http://127.0.0.1:7007/api/catalog/entities?filter=kind=Template 2> /dev/null || echo "")

  if [ -z "$catalog_response" ]; then
    record_test "Software Catalog" "WARN" "Cannot query catalog API (service may be starting)"
    return 0
  fi

  # Count templates (looking for Java, Python, Node.js)
  local template_count=$(echo "$catalog_response" | jq '.items | length' 2> /dev/null || echo "0")

  if [ "$template_count" -ge 3 ]; then
    record_test "Software Catalog" "PASS" "Found $template_count templates in catalog"

    # Check for specific templates
    local java_template=$(echo "$catalog_response" | jq '.items[] | select(.metadata.name | contains("java"))' 2> /dev/null)
    local python_template=$(echo "$catalog_response" | jq '.items[] | select(.metadata.name | contains("python"))' 2> /dev/null)
    local nodejs_template=$(echo "$catalog_response" | jq '.items[] | select(.metadata.name | contains("node"))' 2> /dev/null)

    if [ -n "$java_template" ]; then
      record_test "Java Template" "PASS" "Java Spring Boot template found"
    else
      record_test "Java Template" "WARN" "Java template not found in catalog"
    fi

    if [ -n "$python_template" ]; then
      record_test "Python Template" "PASS" "Python FastAPI template found"
    else
      record_test "Python Template" "WARN" "Python template not found in catalog"
    fi

    if [ -n "$nodejs_template" ]; then
      record_test "Node.js Template" "PASS" "Node.js Express template found"
    else
      record_test "Node.js Template" "WARN" "Node.js template not found in catalog"
    fi
  else
    record_test "Software Catalog" "WARN" "Only $template_count templates found (expected ≥3)"
  fi

  return 0
}

validate_techdocs_plugin() {
  log_info "Validating TechDocs plugin..."

  # Check app-config for TechDocs configuration
  if ! kubectl get configmap backstage-app-config -n "$NAMESPACE" &> /dev/null; then
    record_test "TechDocs Plugin" "FAIL" "Backstage ConfigMap not found"
    return 1
  fi

  local app_config=$(kubectl get configmap backstage-app-config -n "$NAMESPACE" -o jsonpath='{.data.app-config\.yaml}' 2> /dev/null)

  if echo "$app_config" | grep -q "techdocs:"; then
    record_test "TechDocs Plugin" "PASS" "TechDocs configured in app-config"

    # Check for TechDocs volume mount
    local has_techdocs_volume=$(kubectl get deployment backstage -n "$NAMESPACE" -o json 2> /dev/null | jq '.spec.template.spec.volumes[] | select(.name == "techdocs")' 2> /dev/null)

    if [ -n "$has_techdocs_volume" ]; then
      record_test "TechDocs Volume" "PASS" "TechDocs volume mounted"
    else
      record_test "TechDocs Volume" "WARN" "TechDocs volume not found"
    fi
  else
    record_test "TechDocs Plugin" "WARN" "TechDocs not found in app-config"
  fi

  return 0
}

validate_service_catalog() {
  log_info "Validating service catalog..."

  # Find a running Backstage pod
  local pod_name=$(kubectl get pods -n "$NAMESPACE" -l app.kubernetes.io/name=backstage -o jsonpath='{.items[0].metadata.name}' 2> /dev/null)

  if [ -z "$pod_name" ]; then
    record_test "Service Catalog" "FAIL" "Cannot find Backstage pod"
    return 1
  fi

  # Check catalog API for components
  local catalog_response=$(kubectl exec -n "$NAMESPACE" "$pod_name" -- curl -s -f http://127.0.0.1:7007/api/catalog/entities?filter=kind=Component 2> /dev/null || echo "")

  if [ -z "$catalog_response" ]; then
    record_test "Service Catalog" "WARN" "Cannot query catalog API (service may be starting)"
    return 0
  fi

  local component_count=$(echo "$catalog_response" | jq '.items | length' 2> /dev/null || echo "0")

  if [ "$component_count" -gt 0 ]; then
    record_test "Service Catalog" "PASS" "Found $component_count components in catalog"
  else
    record_test "Service Catalog" "WARN" "No components found in catalog"
  fi

  return 0
}

validate_health_check() {
  log_info "Validating health check endpoint..."

  # Find a running Backstage pod
  local pod_name=$(kubectl get pods -n "$NAMESPACE" -l app.kubernetes.io/name=backstage -o jsonpath='{.items[0].metadata.name}' 2> /dev/null)

  if [ -z "$pod_name" ]; then
    record_test "Health Check" "FAIL" "Cannot find Backstage pod"
    return 1
  fi

  # Check health endpoint
  local health_status=$(kubectl exec -n "$NAMESPACE" "$pod_name" -- curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1:7007/healthcheck 2> /dev/null || echo "000")

  if [ "$health_status" = "200" ]; then
    record_test "Health Check" "PASS" "Health check endpoint returns 200"
  else
    record_test "Health Check" "FAIL" "Health check returned status $health_status"
    return 1
  fi

  return 0
}

validate_api_performance() {
  log_info "Validating API performance..."

  # Find a running Backstage pod
  local pod_name=$(kubectl get pods -n "$NAMESPACE" -l app.kubernetes.io/name=backstage -o jsonpath='{.items[0].metadata.name}' 2> /dev/null)

  if [ -z "$pod_name" ]; then
    record_test "API Performance" "FAIL" "Cannot find Backstage pod"
    return 1
  fi

  # Measure API response time
  local response_time=$(kubectl exec -n "$NAMESPACE" "$pod_name" -- curl -s -o /dev/null -w '%{time_total}' http://127.0.0.1:7007/api/catalog/entities 2> /dev/null || echo "999")

  # Convert to milliseconds (response_time is in seconds)
  local response_time_ms=$(echo "$response_time" | awk '{print int($1 * 1000)}')

  if [ "$response_time_ms" -lt 500 ]; then
    record_test "API Performance" "PASS" "API responds in ${response_time_ms}ms (<500ms)"
  else
    record_test "API Performance" "WARN" "API responds in ${response_time_ms}ms (target: <500ms)"
  fi

  return 0
}

validate_ingress() {
  log_info "Validating ingress configuration..."

  # Check if ingress exists
  if ! kubectl get ingress -n "$NAMESPACE" -l app.kubernetes.io/name=backstage &> /dev/null; then
    record_test "Ingress" "WARN" "No ingress found for Backstage (optional for local)"
    return 0
  fi

  local ingress_name=$(kubectl get ingress -n "$NAMESPACE" -l app.kubernetes.io/name=backstage -o jsonpath='{.items[0].metadata.name}' 2> /dev/null)

  if [ -n "$ingress_name" ]; then
    # Check for TLS
    local has_tls=$(kubectl get ingress "$ingress_name" -n "$NAMESPACE" -o jsonpath='{.spec.tls}' 2> /dev/null)

    if [ -n "$has_tls" ] && [ "$has_tls" != "null" ]; then
      record_test "Ingress" "PASS" "Ingress configured with TLS"
    else
      record_test "Ingress" "PASS" "Ingress configured (without TLS)"
    fi
  else
    record_test "Ingress" "WARN" "Ingress not found (optional for local)"
  fi

  return 0
}

# =============================================================================
# Main Execution
# =============================================================================

main() {
  echo ""
  echo "============================================================"
  echo "  AT-E1-003: Backstage Developer Portal Validation"
  echo "============================================================"
  echo ""

  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case $1 in
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

  log_info "Namespace: $NAMESPACE"
  echo ""

  # Run validations
  validate_prerequisites || true
  validate_namespace || true
  validate_backstage_deployment || true
  validate_postgresql_backend || true
  validate_oauth_configuration || true
  validate_catalog_templates || true
  validate_techdocs_plugin || true
  validate_service_catalog || true
  validate_health_check || true
  validate_api_performance || true
  validate_ingress || true

  # Generate report
  echo ""
  generate_report

  # Print summary
  echo ""
  echo "============================================================"
  echo "  Validation Summary"
  echo "============================================================"
  echo "Total Tests:  $TOTAL_TESTS"
  echo "Passed:       $PASSED_TESTS"
  echo "Failed:       $FAILED_TESTS"
  echo ""

  if [ "$FAILED_TESTS" -eq 0 ]; then
    log_success "AT-E1-003 validation PASSED!"
    echo ""
    return 0
  else
    log_error "AT-E1-003 validation FAILED!"
    echo ""
    return 1
  fi
}

main "$@"
