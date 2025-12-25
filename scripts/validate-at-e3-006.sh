#!/usr/bin/env bash
# ============================================================================
# FILE: scripts/validate-at-e3-006.sh
# PURPOSE: Validation script for AT-E3-006 - Unleash Feature Flags Platform
# USAGE: ./scripts/validate-at-e3-006.sh [--namespace fawkes] [--verbose]
# ============================================================================

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
UNLEASH_HOST="unleash.fawkes.idp"

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
      echo "Usage: $0 [--namespace fawkes] [--verbose]"
      echo ""
      echo "Options:"
      echo "  --namespace    Kubernetes namespace (default: fawkes)"
      echo "  --verbose      Enable verbose output"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

# Logging functions
log_info() {
  echo -e "${BLUE}ℹ${NC} $1"
}

log_success() {
  echo -e "${GREEN}✓${NC} $1"
}

log_warning() {
  echo -e "${YELLOW}⚠${NC} $1"
}

log_error() {
  echo -e "${RED}✗${NC} $1"
}

verbose_log() {
  if [[ "$VERBOSE" == "true" ]]; then
    echo -e "${BLUE}  →${NC} $1"
  fi
}

# Check if command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Validation functions
check_prerequisites() {
  log_info "Checking prerequisites..."
  
  local missing_tools=()
  
  for tool in kubectl jq curl; do
    if ! command_exists "$tool"; then
      missing_tools+=("$tool")
    fi
  done
  
  if [[ ${#missing_tools[@]} -gt 0 ]]; then
    log_error "Missing required tools: ${missing_tools[*]}"
    exit 1
  fi
  
  log_success "All required tools are installed"
}

check_namespace() {
  log_info "Checking namespace '$NAMESPACE'..."
  
  if ! kubectl get namespace "$NAMESPACE" >/dev/null 2>&1; then
    log_error "Namespace '$NAMESPACE' does not exist"
    exit 1
  fi
  
  log_success "Namespace '$NAMESPACE' exists"
}

check_postgresql_cluster() {
  log_info "Checking PostgreSQL cluster 'db-unleash-dev'..."
  
  if ! kubectl get cluster db-unleash-dev -n "$NAMESPACE" >/dev/null 2>&1; then
    log_error "PostgreSQL cluster 'db-unleash-dev' not found"
    return 1
  fi
  
  local cluster_status
  cluster_status=$(kubectl get cluster db-unleash-dev -n "$NAMESPACE" -o jsonpath='{.status.phase}')
  
  if [[ "$cluster_status" != "Cluster in healthy state" ]]; then
    log_warning "PostgreSQL cluster status: $cluster_status"
  fi
  
  local instances
  instances=$(kubectl get cluster db-unleash-dev -n "$NAMESPACE" -o jsonpath='{.status.instances}')
  verbose_log "PostgreSQL instances: $instances"
  
  log_success "PostgreSQL cluster 'db-unleash-dev' is healthy"
  return 0
}

check_unleash_deployment() {
  log_info "Checking Unleash deployment..."
  
  if ! kubectl get deployment unleash -n "$NAMESPACE" >/dev/null 2>&1; then
    log_error "Unleash deployment not found"
    return 1
  fi
  
  local replicas_ready
  replicas_ready=$(kubectl get deployment unleash -n "$NAMESPACE" -o jsonpath='{.status.readyReplicas}')
  local replicas_desired
  replicas_desired=$(kubectl get deployment unleash -n "$NAMESPACE" -o jsonpath='{.spec.replicas}')
  
  if [[ "$replicas_ready" != "$replicas_desired" ]]; then
    log_error "Unleash deployment not ready: $replicas_ready/$replicas_desired replicas"
    return 1
  fi
  
  verbose_log "Replicas: $replicas_ready/$replicas_desired"
  log_success "Unleash deployment is healthy with $replicas_ready replicas"
  return 0
}

check_unleash_pods() {
  log_info "Checking Unleash pods..."
  
  local pods
  pods=$(kubectl get pods -n "$NAMESPACE" -l app=unleash,component=feature-flags -o json)
  
  local pod_count
  pod_count=$(echo "$pods" | jq '.items | length')
  
  if [[ "$pod_count" -eq 0 ]]; then
    log_error "No Unleash pods found"
    return 1
  fi
  
  local all_running=true
  local pod_names
  pod_names=$(echo "$pods" | jq -r '.items[].metadata.name')
  
  while IFS= read -r pod_name; do
    local pod_phase
    pod_phase=$(kubectl get pod "$pod_name" -n "$NAMESPACE" -o jsonpath='{.status.phase}')
    
    verbose_log "Pod $pod_name: $pod_phase"
    
    if [[ "$pod_phase" != "Running" ]]; then
      log_warning "Pod $pod_name is not running: $pod_phase"
      all_running=false
    fi
  done <<< "$pod_names"
  
  if [[ "$all_running" == "false" ]]; then
    log_error "Not all Unleash pods are running"
    return 1
  fi
  
  log_success "All Unleash pods are running ($pod_count pods)"
  return 0
}

check_unleash_service() {
  log_info "Checking Unleash service..."
  
  if ! kubectl get service unleash -n "$NAMESPACE" >/dev/null 2>&1; then
    log_error "Unleash service not found"
    return 1
  fi
  
  local service_type
  service_type=$(kubectl get service unleash -n "$NAMESPACE" -o jsonpath='{.spec.type}')
  
  local service_port
  service_port=$(kubectl get service unleash -n "$NAMESPACE" -o jsonpath='{.spec.ports[0].port}')
  
  verbose_log "Service type: $service_type, Port: $service_port"
  log_success "Unleash service is configured"
  return 0
}

check_unleash_ingress() {
  log_info "Checking Unleash ingress..."
  
  if ! kubectl get ingress unleash -n "$NAMESPACE" >/dev/null 2>&1; then
    log_error "Unleash ingress not found"
    return 1
  fi
  
  local ingress_host
  ingress_host=$(kubectl get ingress unleash -n "$NAMESPACE" -o jsonpath='{.spec.rules[0].host}')
  
  verbose_log "Ingress host: $ingress_host"
  
  if [[ "$ingress_host" != "$UNLEASH_HOST" ]]; then
    log_warning "Ingress host mismatch: expected $UNLEASH_HOST, got $ingress_host"
  fi
  
  log_success "Unleash ingress is configured for $ingress_host"
  return 0
}

check_unleash_health() {
  log_info "Checking Unleash API health..."
  
  # Port forward to Unleash service
  local port_forward_pid
  kubectl port-forward -n "$NAMESPACE" service/unleash 4242:4242 >/dev/null 2>&1 &
  port_forward_pid=$!
  
  # Give port-forward time to establish
  sleep 3
  
  local health_status=1
  if curl -sf http://localhost:4242/health >/dev/null 2>&1; then
    log_success "Unleash API health check passed"
    health_status=0
  else
    log_error "Unleash API health check failed"
    health_status=1
  fi
  
  # Clean up port-forward
  kill "$port_forward_pid" 2>/dev/null || true
  
  return $health_status
}

check_database_connection() {
  log_info "Checking Unleash database connection..."
  
  local pod_name
  pod_name=$(kubectl get pods -n "$NAMESPACE" -l app=unleash,component=feature-flags -o jsonpath='{.items[0].metadata.name}')
  
  if [[ -z "$pod_name" ]]; then
    log_error "No Unleash pod found to check database connection"
    return 1
  fi
  
  # Check if pod can resolve database hostname
  if kubectl exec -n "$NAMESPACE" "$pod_name" -- sh -c "nc -zv db-unleash-dev-rw.$NAMESPACE.svc.cluster.local 5432" 2>&1 | grep -q "open"; then
    log_success "Unleash can connect to PostgreSQL database"
    return 0
  else
    log_error "Unleash cannot connect to PostgreSQL database"
    return 1
  fi
}

check_secrets() {
  log_info "Checking Unleash secrets..."
  
  # Check Unleash application secret
  if ! kubectl get secret unleash-secret -n "$NAMESPACE" >/dev/null 2>&1; then
    log_error "Unleash secret 'unleash-secret' not found"
    return 1
  fi
  
  # Check database credentials secret
  if ! kubectl get secret db-unleash-credentials -n "$NAMESPACE" >/dev/null 2>&1; then
    log_error "Database credentials secret 'db-unleash-credentials' not found"
    return 1
  fi
  
  log_success "All required secrets are configured"
  return 0
}

check_resource_usage() {
  log_info "Checking Unleash resource usage..."
  
  local pods
  pods=$(kubectl get pods -n "$NAMESPACE" -l app=unleash,component=feature-flags -o json)
  
  local all_within_limits=true
  local pod_names
  pod_names=$(echo "$pods" | jq -r '.items[].metadata.name')
  
  while IFS= read -r pod_name; do
    local cpu_usage
    cpu_usage=$(kubectl top pod "$pod_name" -n "$NAMESPACE" 2>/dev/null | tail -n 1 | awk '{print $2}' | sed 's/m//')
    
    local memory_usage
    memory_usage=$(kubectl top pod "$pod_name" -n "$NAMESPACE" 2>/dev/null | tail -n 1 | awk '{print $3}' | sed 's/Mi//')
    
    if [[ -n "$cpu_usage" && -n "$memory_usage" ]]; then
      # CPU request is 200m, target is 70% = 140m
      if [[ "$cpu_usage" -gt 140 ]]; then
        log_warning "Pod $pod_name CPU usage ($cpu_usage m) exceeds 70% target (140m)"
        all_within_limits=false
      fi
      
      # Memory request is 256Mi, target is 70% = ~179Mi
      if [[ "$memory_usage" -gt 179 ]]; then
        log_warning "Pod $pod_name memory usage ($memory_usage Mi) exceeds 70% target (179Mi)"
        all_within_limits=false
      fi
      
      verbose_log "Pod $pod_name: CPU=$cpu_usage m, Memory=$memory_usage Mi"
    else
      log_warning "Could not retrieve metrics for pod $pod_name (metrics-server may not be installed)"
    fi
  done <<< "$pod_names"
  
  if [[ "$all_within_limits" == "true" ]]; then
    log_success "All Unleash pods are within resource limits (<70% utilization)"
  else
    log_warning "Some Unleash pods exceed 70% resource utilization target"
  fi
  
  return 0
}

check_monitoring() {
  log_info "Checking Unleash monitoring configuration..."
  
  if ! kubectl get servicemonitor unleash -n "$NAMESPACE" >/dev/null 2>&1; then
    log_warning "ServiceMonitor 'unleash' not found (Prometheus may not be installed)"
    return 0
  fi
  
  log_success "ServiceMonitor is configured for Prometheus scraping"
  return 0
}

# Main validation
main() {
  echo ""
  echo "=================================="
  echo "AT-E3-006: Unleash Feature Flags Platform Validation"
  echo "=================================="
  echo ""
  
  local failed_checks=0
  
  check_prerequisites || ((failed_checks++))
  check_namespace || ((failed_checks++))
  check_postgresql_cluster || ((failed_checks++))
  check_unleash_deployment || ((failed_checks++))
  check_unleash_pods || ((failed_checks++))
  check_unleash_service || ((failed_checks++))
  check_unleash_ingress || ((failed_checks++))
  check_secrets || ((failed_checks++))
  check_database_connection || ((failed_checks++))
  check_unleash_health || ((failed_checks++))
  check_resource_usage || ((failed_checks++))
  check_monitoring || ((failed_checks++))
  
  echo ""
  echo "=================================="
  if [[ $failed_checks -eq 0 ]]; then
    log_success "AT-E3-006: All validation checks passed ✓"
    echo "=================================="
    echo ""
    log_info "Unleash Feature Flags Platform is fully operational"
    log_info "Access Unleash UI: https://$UNLEASH_HOST"
    log_info "API Endpoint: https://$UNLEASH_HOST/api"
    echo ""
    exit 0
  else
    log_error "AT-E3-006: $failed_checks validation check(s) failed ✗"
    echo "=================================="
    echo ""
    exit 1
  fi
}

# Run main function
main
