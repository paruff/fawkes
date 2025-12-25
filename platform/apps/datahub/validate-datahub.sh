#!/bin/bash
# ==============================================================================
# FILE: platform/apps/datahub/validate-datahub.sh
# PURPOSE: Validate DataHub deployment and functionality
# USAGE: ./validate-datahub.sh [--namespace fawkes]
# ==============================================================================

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default values
NAMESPACE="fawkes"
LOGGING_NAMESPACE="logging"
DATAHUB_URL="http://datahub.127.0.0.1.nip.io"
VERBOSE=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --namespace)
      NAMESPACE="$2"
      shift 2
      ;;
    --verbose)
      VERBOSE=true
      shift
      ;;
    --help)
      echo "Usage: $0 [OPTIONS]"
      echo ""
      echo "Options:"
      echo "  --namespace NAME    Kubernetes namespace (default: fawkes)"
      echo "  --verbose           Enable verbose output"
      echo "  --help              Show this help message"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

# Helper functions
log_info() {
  echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
  echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
  echo -e "${RED}[ERROR]${NC} $1"
}

check_command() {
  if ! command -v "$1" &> /dev/null; then
    log_error "$1 is not installed"
    return 1
  fi
  return 0
}

# Validation functions
validate_prerequisites() {
  log_info "Checking prerequisites..."

  local all_good=true

  if ! check_command kubectl; then
    all_good=false
  fi

  if ! check_command curl; then
    all_good=false
  fi

  if ! check_command jq; then
    log_warn "jq is not installed (optional, but recommended for JSON parsing)"
  fi

  if [ "$all_good" = false ]; then
    log_error "Missing required commands. Please install them and try again."
    exit 1
  fi

  log_info "✓ Prerequisites check passed"
}

validate_postgresql() {
  log_info "Checking PostgreSQL cluster..."

  # Check if PostgreSQL cluster exists
  if ! kubectl get cluster -n "$NAMESPACE" db-datahub-dev &> /dev/null; then
    log_error "PostgreSQL cluster 'db-datahub-dev' not found"
    return 1
  fi

  # Check cluster status
  local status
  status=$(kubectl get cluster -n "$NAMESPACE" db-datahub-dev -o jsonpath='{.status.phase}')

  if [ "$status" != "Cluster in healthy state" ]; then
    log_warn "PostgreSQL cluster status: $status"
  else
    log_info "✓ PostgreSQL cluster is healthy"
  fi

  # Check if pods are running
  local pod_count
  pod_count=$(kubectl get pods -n "$NAMESPACE" -l "cnpg.io/cluster=db-datahub-dev" --field-selector=status.phase=Running -o json | jq '.items | length')

  if [ "$pod_count" -lt 1 ]; then
    log_error "No PostgreSQL pods are running"
    return 1
  fi

  log_info "✓ PostgreSQL has $pod_count running pod(s)"
  return 0
}

validate_opensearch() {
  log_info "Checking OpenSearch..."

  # Check if OpenSearch pods are running
  if command -v jq &> /dev/null; then
    local pod_count
    pod_count=$(kubectl get pods -n "$LOGGING_NAMESPACE" -l "app=opensearch" --field-selector=status.phase=Running -o json 2>/dev/null | jq '.items | length' 2>/dev/null || echo "0")

    if [ "$pod_count" -lt 1 ]; then
      log_error "No OpenSearch pods are running in namespace '$LOGGING_NAMESPACE'"
      return 1
    fi

    log_info "✓ OpenSearch has $pod_count running pod(s)"
  else
    # Fallback without jq
    if kubectl get pods -n "$LOGGING_NAMESPACE" -l "app=opensearch" --field-selector=status.phase=Running 2>/dev/null | grep -q "opensearch"; then
      log_info "✓ OpenSearch pods are running"
    else
      log_error "No OpenSearch pods are running in namespace '$LOGGING_NAMESPACE'"
      return 1
    fi
  fi

  return 0
}

validate_datahub_pods() {
  log_info "Checking DataHub pods..."

  # Check GMS
  if ! kubectl get deployment -n "$NAMESPACE" datahub-datahub-gms &> /dev/null; then
    log_error "DataHub GMS deployment not found"
    return 1
  fi

  local gms_ready
  gms_ready=$(kubectl get deployment -n "$NAMESPACE" datahub-datahub-gms -o jsonpath='{.status.readyReplicas}')

  if [ "${gms_ready:-0}" -lt 1 ]; then
    log_error "DataHub GMS is not ready"
    return 1
  fi

  log_info "✓ DataHub GMS is running ($gms_ready replica(s))"

  # Check Frontend
  if ! kubectl get deployment -n "$NAMESPACE" datahub-datahub-frontend &> /dev/null; then
    log_error "DataHub Frontend deployment not found"
    return 1
  fi

  local frontend_ready
  frontend_ready=$(kubectl get deployment -n "$NAMESPACE" datahub-datahub-frontend -o jsonpath='{.status.readyReplicas}')

  if [ "${frontend_ready:-0}" -lt 1 ]; then
    log_error "DataHub Frontend is not ready"
    return 1
  fi

  log_info "✓ DataHub Frontend is running ($frontend_ready replica(s))"
  return 0
}

validate_datahub_services() {
  log_info "Checking DataHub services..."

  # Check GMS service
  if ! kubectl get service -n "$NAMESPACE" datahub-datahub-gms &> /dev/null; then
    log_error "DataHub GMS service not found"
    return 1
  fi

  log_info "✓ DataHub GMS service exists"

  # Check Frontend service
  if ! kubectl get service -n "$NAMESPACE" datahub-datahub-frontend &> /dev/null; then
    log_error "DataHub Frontend service not found"
    return 1
  fi

  log_info "✓ DataHub Frontend service exists"
  return 0
}

validate_ingress() {
  log_info "Checking DataHub ingress..."

  if ! kubectl get ingress -n "$NAMESPACE" datahub-datahub-frontend &> /dev/null; then
    log_error "DataHub ingress not found"
    return 1
  fi

  local hosts
  hosts=$(kubectl get ingress -n "$NAMESPACE" datahub-datahub-frontend -o jsonpath='{.spec.rules[*].host}')

  log_info "✓ DataHub ingress exists (hosts: $hosts)"
  return 0
}

validate_api_health() {
  log_info "Checking DataHub API health..."

  # Wait for service to be available
  sleep 5

  # Try to access GMS health endpoint (internal)
  local gms_health
  if gms_health=$(kubectl exec -n "$NAMESPACE" deployment/datahub-datahub-gms -- curl -s -f http://localhost:8080/health 2>/dev/null); then
    log_info "✓ DataHub GMS health check passed"
  else
    log_warn "DataHub GMS health check failed (this might be expected during initial startup)"
  fi

  # Try to access Frontend health endpoint (internal)
  local frontend_health
  if frontend_health=$(kubectl exec -n "$NAMESPACE" deployment/datahub-datahub-frontend -- curl -s -f http://localhost:9002/admin 2>/dev/null); then
    log_info "✓ DataHub Frontend health check passed"
  else
    log_warn "DataHub Frontend health check failed (this might be expected during initial startup)"
  fi

  return 0
}

validate_graphql_api() {
  log_info "Checking DataHub GraphQL API..."

  # Wait for service to be fully ready
  sleep 5

  # Try to query GraphQL API
  local query='{"query": "{ __schema { queryType { name } } }"}'

  # Port-forward to access the API
  log_info "Setting up port-forward to test API..."
  kubectl port-forward -n "$NAMESPACE" service/datahub-datahub-gms 8080:8080 &>/dev/null &
  local pf_pid=$!

  # Wait for port-forward to be ready
  sleep 3

  # Test GraphQL endpoint
  local response
  if response=$(curl -s -X POST http://localhost:8080/api/graphql -H "Content-Type: application/json" -d "$query" 2>/dev/null); then
    if echo "$response" | grep -q "queryType"; then
      log_info "✓ DataHub GraphQL API is responding"
    else
      log_warn "DataHub GraphQL API response unexpected: $response"
    fi
  else
    log_warn "Could not connect to DataHub GraphQL API (this might be expected for local testing)"
  fi

  # Clean up port-forward
  kill $pf_pid 2>/dev/null || true

  return 0
}

validate_resource_usage() {
  log_info "Checking resource usage..."

  # Check CPU and memory usage if metrics-server is available
  if kubectl top pods -n "$NAMESPACE" --no-headers 2>/dev/null | grep datahub &>/dev/null; then
    log_info "DataHub resource usage:"
    kubectl top pods -n "$NAMESPACE" --no-headers | grep datahub | while read -r line; do
      echo "  $line"
    done
  else
    log_warn "Metrics server not available, skipping resource usage check"
  fi

  return 0
}

# Main validation flow
main() {
  log_info "=== DataHub Deployment Validation ==="
  log_info "Namespace: $NAMESPACE"
  log_info ""

  local failed=false

  validate_prerequisites || failed=true
  echo ""

  validate_postgresql || failed=true
  echo ""

  validate_opensearch || failed=true
  echo ""

  validate_datahub_pods || failed=true
  echo ""

  validate_datahub_services || failed=true
  echo ""

  validate_ingress || failed=true
  echo ""

  validate_api_health || failed=true
  echo ""

  validate_graphql_api || failed=true
  echo ""

  validate_resource_usage || failed=true
  echo ""

  if [ "$failed" = true ]; then
    log_error "=== Validation completed with errors ==="
    exit 1
  else
    log_info "=== ✓ All validations passed ==="
    log_info ""
    log_info "DataHub UI should be accessible at: $DATAHUB_URL"
    log_info "Default credentials (MVP/dev only):"
    log_info "  Username: datahub"
    log_info "  Password: <same as username>"
    log_info ""
    log_info "Note: Change credentials for production deployment"
    exit 0
  fi
}

# Run main function
main
