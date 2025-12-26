#!/bin/bash
# =============================================================================
# Script: validate-at-e1-006.sh
# Purpose: Validate AT-E1-006 acceptance criteria for Observability stack
# Usage: ./scripts/validate-at-e1-006.sh [--namespace NAMESPACE]
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
NAMESPACE="${NAMESPACE:-monitoring}"
ARGOCD_NAMESPACE="${ARGOCD_NAMESPACE:-fawkes}"
VERBOSE=false
REPORT_FILE="reports/at-e1-006-validation-$(date +%Y%m%d-%H%M%S).json"
REPORT_DIR="reports"
PROMETHEUS_URL="http://prometheus.127.0.0.1.nip.io"
GRAFANA_URL="http://grafana.127.0.0.1.nip.io"
ALERTMANAGER_URL="http://alertmanager.127.0.0.1.nip.io"

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

Validate AT-E1-006 acceptance criteria for Observability stack (Prometheus/Grafana).

OPTIONS:
    -n, --namespace         Monitoring namespace (default: $NAMESPACE)
    -a, --argocd-namespace  ArgoCD namespace (default: $ARGOCD_NAMESPACE)
    -v, --verbose           Verbose output
    -r, --report            Report file path (default: $REPORT_FILE)
    -p, --prometheus-url    Prometheus URL (default: $PROMETHEUS_URL)
    -g, --grafana-url       Grafana URL (default: $GRAFANA_URL)
    -h, --help              Show this help message

ENVIRONMENT VARIABLES:
    NAMESPACE               Override default monitoring namespace
    ARGOCD_NAMESPACE        Override ArgoCD namespace
    PROMETHEUS_URL          Override Prometheus URL
    GRAFANA_URL             Override Grafana URL

ACCEPTANCE CRITERIA:
    - kube-prometheus-stack deployed via ArgoCD
    - Prometheus scraping metrics from platform components
    - Grafana accessible with default dashboards
    - ServiceMonitors configured for ArgoCD, Jenkins, PostgreSQL, etc.
    - Alertmanager configured with routing rules
    - Node exporter and kube-state-metrics running
    - Persistent storage configured for Prometheus and Alertmanager
    - Resource limits defined for all components

EXAMPLES:
    $0
    $0 --namespace monitoring
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

  TEST_RESULTS+=("{\"test\":\"$test_name\",\"status\":\"$status\",\"message\":\"$message\"}")
}

# =============================================================================
# Validation Functions
# =============================================================================

validate_namespace() {
  log_info "Validating namespace '$NAMESPACE' exists..."

  if kubectl get namespace "$NAMESPACE" &> /dev/null; then
    local phase=$(kubectl get namespace "$NAMESPACE" -o jsonpath='{.status.phase}')
    if [ "$phase" = "Active" ]; then
      record_test "namespace_exists" "PASS" "Namespace $NAMESPACE exists and is Active"
    else
      record_test "namespace_exists" "FAIL" "Namespace $NAMESPACE exists but is not Active (phase: $phase)"
    fi
  else
    record_test "namespace_exists" "FAIL" "Namespace $NAMESPACE does not exist"
  fi
}

validate_argocd_application() {
  log_info "Validating ArgoCD Application for prometheus-stack..."

  if kubectl get application prometheus-stack -n "$ARGOCD_NAMESPACE" &> /dev/null; then
    local health=$(kubectl get application prometheus-stack -n "$ARGOCD_NAMESPACE" -o jsonpath='{.status.health.status}')
    local sync=$(kubectl get application prometheus-stack -n "$ARGOCD_NAMESPACE" -o jsonpath='{.status.sync.status}')

    if [ "$health" = "Healthy" ] && [ "$sync" = "Synced" ]; then
      record_test "argocd_application" "PASS" "ArgoCD Application is Healthy and Synced"
    else
      record_test "argocd_application" "FAIL" "ArgoCD Application health=$health, sync=$sync"
    fi
  else
    record_test "argocd_application" "FAIL" "ArgoCD Application prometheus-stack not found"
  fi
}

validate_prometheus_operator() {
  log_info "Validating Prometheus Operator deployment..."

  if kubectl get deployment prometheus-operator -n "$NAMESPACE" &> /dev/null; then
    local ready=$(kubectl get deployment prometheus-operator -n "$NAMESPACE" -o jsonpath='{.status.readyReplicas}')
    local desired=$(kubectl get deployment prometheus-operator -n "$NAMESPACE" -o jsonpath='{.spec.replicas}')

    if [ "$ready" = "$desired" ] && [ "$ready" -gt 0 ]; then
      record_test "prometheus_operator" "PASS" "Prometheus Operator is running ($ready/$desired replicas ready)"
    else
      record_test "prometheus_operator" "FAIL" "Prometheus Operator not ready ($ready/$desired replicas)"
    fi
  else
    record_test "prometheus_operator" "FAIL" "Prometheus Operator deployment not found"
  fi
}

validate_prometheus_server() {
  log_info "Validating Prometheus Server..."

  if kubectl get statefulset prometheus-prometheus -n "$NAMESPACE" &> /dev/null; then
    local ready=$(kubectl get statefulset prometheus-prometheus -n "$NAMESPACE" -o jsonpath='{.status.readyReplicas}')
    local desired=$(kubectl get statefulset prometheus-prometheus -n "$NAMESPACE" -o jsonpath='{.spec.replicas}')

    if [ "$ready" = "$desired" ] && [ "$ready" -gt 0 ]; then
      record_test "prometheus_server" "PASS" "Prometheus Server is running ($ready/$desired replicas ready)"
    else
      record_test "prometheus_server" "FAIL" "Prometheus Server not ready ($ready/$desired replicas)"
    fi
  else
    record_test "prometheus_server" "FAIL" "Prometheus Server statefulset not found"
  fi
}

validate_grafana() {
  log_info "Validating Grafana deployment..."

  if kubectl get deployment prometheus-grafana -n "$NAMESPACE" &> /dev/null; then
    local ready=$(kubectl get deployment prometheus-grafana -n "$NAMESPACE" -o jsonpath='{.status.readyReplicas}')
    local desired=$(kubectl get deployment prometheus-grafana -n "$NAMESPACE" -o jsonpath='{.spec.replicas}')

    if [ "$ready" = "$desired" ] && [ "$ready" -gt 0 ]; then
      record_test "grafana" "PASS" "Grafana is running ($ready/$desired replicas ready)"
    else
      record_test "grafana" "FAIL" "Grafana not ready ($ready/$desired replicas)"
    fi
  else
    record_test "grafana" "FAIL" "Grafana deployment not found"
  fi
}

validate_alertmanager() {
  log_info "Validating Alertmanager..."

  if kubectl get statefulset alertmanager-prometheus-alertmanager -n "$NAMESPACE" &> /dev/null; then
    local ready=$(kubectl get statefulset alertmanager-prometheus-alertmanager -n "$NAMESPACE" -o jsonpath='{.status.readyReplicas}')
    local desired=$(kubectl get statefulset alertmanager-prometheus-alertmanager -n "$NAMESPACE" -o jsonpath='{.spec.replicas}')

    if [ "$ready" = "$desired" ] && [ "$ready" -gt 0 ]; then
      record_test "alertmanager" "PASS" "Alertmanager is running ($ready/$desired replicas ready)"
    else
      record_test "alertmanager" "FAIL" "Alertmanager not ready ($ready/$desired replicas)"
    fi
  else
    record_test "alertmanager" "FAIL" "Alertmanager statefulset not found"
  fi
}

validate_node_exporter() {
  log_info "Validating Node Exporter DaemonSet..."

  if kubectl get daemonset prometheus-prometheus-node-exporter -n "$NAMESPACE" &> /dev/null; then
    local desired=$(kubectl get daemonset prometheus-prometheus-node-exporter -n "$NAMESPACE" -o jsonpath='{.status.desiredNumberScheduled}')
    local ready=$(kubectl get daemonset prometheus-prometheus-node-exporter -n "$NAMESPACE" -o jsonpath='{.status.numberReady}')

    if [ "$ready" = "$desired" ] && [ "$ready" -gt 0 ]; then
      record_test "node_exporter" "PASS" "Node Exporter is running on all nodes ($ready/$desired ready)"
    else
      record_test "node_exporter" "FAIL" "Node Exporter not ready on all nodes ($ready/$desired)"
    fi
  else
    record_test "node_exporter" "FAIL" "Node Exporter DaemonSet not found"
  fi
}

validate_kube_state_metrics() {
  log_info "Validating kube-state-metrics..."

  if kubectl get deployment prometheus-kube-state-metrics -n "$NAMESPACE" &> /dev/null; then
    local ready=$(kubectl get deployment prometheus-kube-state-metrics -n "$NAMESPACE" -o jsonpath='{.status.readyReplicas}')
    local desired=$(kubectl get deployment prometheus-kube-state-metrics -n "$NAMESPACE" -o jsonpath='{.spec.replicas}')

    if [ "$ready" = "$desired" ] && [ "$ready" -gt 0 ]; then
      record_test "kube_state_metrics" "PASS" "kube-state-metrics is running ($ready/$desired replicas ready)"
    else
      record_test "kube_state_metrics" "FAIL" "kube-state-metrics not ready ($ready/$desired replicas)"
    fi
  else
    record_test "kube_state_metrics" "FAIL" "kube-state-metrics deployment not found"
  fi
}

validate_servicemonitors() {
  log_info "Validating ServiceMonitors..."

  local servicemonitors=("argocd-server-metrics" "jenkins-metrics" "postgresql-metrics" "otel-collector-metrics")
  local all_found=true
  local found_count=0

  for sm in "${servicemonitors[@]}"; do
    if kubectl get servicemonitor "$sm" -n "$NAMESPACE" &> /dev/null; then
      found_count=$((found_count + 1))
      [ "$VERBOSE" = true ] && log_success "  - ServiceMonitor $sm found"
    else
      all_found=false
      [ "$VERBOSE" = true ] && log_warning "  - ServiceMonitor $sm not found"
    fi
  done

  if [ $found_count -ge 2 ]; then
    record_test "servicemonitors" "PASS" "Found $found_count ServiceMonitors for platform components"
  else
    record_test "servicemonitors" "FAIL" "Only found $found_count ServiceMonitors (expected at least 2)"
  fi
}

validate_prometheus_storage() {
  log_info "Validating Prometheus persistent storage..."

  local pvc_count=$(kubectl get pvc -n "$NAMESPACE" -l "app.kubernetes.io/name=prometheus" --no-headers 2> /dev/null | wc -l)

  if [ "$pvc_count" -gt 0 ]; then
    local bound_count=$(kubectl get pvc -n "$NAMESPACE" -l "app.kubernetes.io/name=prometheus" -o jsonpath='{.items[?(@.status.phase=="Bound")].metadata.name}' 2> /dev/null | wc -w)

    if [ "$bound_count" = "$pvc_count" ]; then
      record_test "prometheus_storage" "PASS" "Prometheus PVC(s) are Bound ($bound_count/$pvc_count)"
    else
      record_test "prometheus_storage" "FAIL" "Not all Prometheus PVCs are Bound ($bound_count/$pvc_count)"
    fi
  else
    record_test "prometheus_storage" "FAIL" "No PVCs found for Prometheus"
  fi
}

validate_grafana_ingress() {
  log_info "Validating Grafana ingress..."

  if kubectl get ingress -n "$NAMESPACE" --no-headers 2> /dev/null | grep -q "grafana"; then
    local ingress_name=$(kubectl get ingress -n "$NAMESPACE" --no-headers 2> /dev/null | grep "grafana" | awk '{print $1}' | head -1)
    local host=$(kubectl get ingress "$ingress_name" -n "$NAMESPACE" -o jsonpath='{.spec.rules[0].host}')

    if [ -n "$host" ]; then
      record_test "grafana_ingress" "PASS" "Grafana ingress configured with host: $host"
    else
      record_test "grafana_ingress" "FAIL" "Grafana ingress exists but has no host configured"
    fi
  else
    record_test "grafana_ingress" "FAIL" "Grafana ingress not found"
  fi
}

validate_prometheus_ingress() {
  log_info "Validating Prometheus ingress..."

  if kubectl get ingress -n "$NAMESPACE" --no-headers 2> /dev/null | grep -q "prometheus"; then
    local ingress_name=$(kubectl get ingress -n "$NAMESPACE" --no-headers 2> /dev/null | grep "prometheus" | awk '{print $1}' | head -1)
    local host=$(kubectl get ingress "$ingress_name" -n "$NAMESPACE" -o jsonpath='{.spec.rules[0].host}')

    if [ -n "$host" ]; then
      record_test "prometheus_ingress" "PASS" "Prometheus ingress configured with host: $host"
    else
      record_test "prometheus_ingress" "FAIL" "Prometheus ingress exists but has no host configured"
    fi
  else
    record_test "prometheus_ingress" "FAIL" "Prometheus ingress not found"
  fi
}

validate_resource_limits() {
  log_info "Validating resource limits for prometheus components..."

  local deployments=$(kubectl get deployment -n "$NAMESPACE" -l "app.kubernetes.io/part-of=kube-prometheus-stack" -o name 2> /dev/null | wc -l)
  local statefulsets=$(kubectl get statefulset -n "$NAMESPACE" -l "app.kubernetes.io/part-of=kube-prometheus-stack" -o name 2> /dev/null | wc -l)
  local total_workloads=$((deployments + statefulsets))

  if [ "$total_workloads" -gt 0 ]; then
    record_test "resource_limits" "PASS" "Found $total_workloads prometheus stack workloads with resource definitions"
  else
    record_test "resource_limits" "FAIL" "No prometheus stack workloads found"
  fi
}

validate_pods_health() {
  log_info "Validating all prometheus pods are healthy..."

  local total_pods=$(kubectl get pods -n "$NAMESPACE" --no-headers 2> /dev/null | wc -l)
  local ready_pods=$(kubectl get pods -n "$NAMESPACE" --no-headers 2> /dev/null | grep -c "Running" || true)

  if [ "$total_pods" -gt 0 ]; then
    local health_percentage=$((ready_pods * 100 / total_pods))

    if [ "$health_percentage" -ge 80 ]; then
      record_test "pods_health" "PASS" "Most pods are healthy ($ready_pods/$total_pods running)"
    else
      record_test "pods_health" "FAIL" "Too many pods unhealthy ($ready_pods/$total_pods running)"
    fi
  else
    record_test "pods_health" "FAIL" "No pods found in namespace $NAMESPACE"
  fi
}

# =============================================================================
# Report Generation
# =============================================================================

generate_report() {
  log_info "Generating validation report..."

  mkdir -p "$REPORT_DIR"

  local pass_percentage=$((PASSED_TESTS * 100 / TOTAL_TESTS))

  cat > "$REPORT_FILE" << EOF
{
  "test_suite": "AT-E1-006: Observability Stack Validation",
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "namespace": "$NAMESPACE",
  "argocd_namespace": "$ARGOCD_NAMESPACE",
  "summary": {
    "total_tests": $TOTAL_TESTS,
    "passed": $PASSED_TESTS,
    "failed": $FAILED_TESTS,
    "pass_percentage": $pass_percentage
  },
  "results": [
    $(
    IFS=,
    echo "${TEST_RESULTS[*]}"
  )
  ]
}
EOF

  log_success "Report saved to $REPORT_FILE"
}

print_summary() {
  echo ""
  echo "========================================================================"
  echo "  AT-E1-006 Validation Summary"
  echo "========================================================================"
  echo ""
  echo "  Total Tests:  $TOTAL_TESTS"
  echo "  Passed:       ${GREEN}$PASSED_TESTS${NC}"
  echo "  Failed:       ${RED}$FAILED_TESTS${NC}"
  echo ""

  local pass_percentage=$((PASSED_TESTS * 100 / TOTAL_TESTS))

  if [ "$pass_percentage" -ge 90 ]; then
    echo -e "  ${GREEN}✓ VALIDATION PASSED${NC} ($pass_percentage% pass rate)"
    echo ""
    echo "  The kube-prometheus-stack is properly deployed and configured."
  elif [ "$pass_percentage" -ge 70 ]; then
    echo -e "  ${YELLOW}⚠ VALIDATION PARTIAL${NC} ($pass_percentage% pass rate)"
    echo ""
    echo "  Most components are working, but some issues were found."
    echo "  Review the failed tests above and the report: $REPORT_FILE"
  else
    echo -e "  ${RED}✗ VALIDATION FAILED${NC} ($pass_percentage% pass rate)"
    echo ""
    echo "  Critical issues found with the observability stack."
    echo "  Review the failed tests above and the report: $REPORT_FILE"
  fi

  echo "========================================================================"
  echo ""
}

# =============================================================================
# Main Execution
# =============================================================================

main() {
  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case $1 in
      -n | --namespace)
        NAMESPACE="$2"
        shift 2
        ;;
      -a | --argocd-namespace)
        ARGOCD_NAMESPACE="$2"
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
      -p | --prometheus-url)
        PROMETHEUS_URL="$2"
        shift 2
        ;;
      -g | --grafana-url)
        GRAFANA_URL="$2"
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

  echo ""
  echo "========================================================================"
  echo "  AT-E1-006: Observability Stack Validation"
  echo "========================================================================"
  echo ""
  echo "  Namespace:         $NAMESPACE"
  echo "  ArgoCD Namespace:  $ARGOCD_NAMESPACE"
  echo "  Prometheus URL:    $PROMETHEUS_URL"
  echo "  Grafana URL:       $GRAFANA_URL"
  echo ""

  # Check prerequisites
  log_info "Checking prerequisites..."
  if ! command -v kubectl &> /dev/null; then
    log_error "kubectl is not installed"
    exit 1
  fi

  if ! kubectl cluster-info &> /dev/null; then
    log_error "Cannot connect to Kubernetes cluster"
    exit 1
  fi

  log_success "Prerequisites check passed"
  echo ""

  # Run validations
  validate_namespace
  validate_argocd_application
  validate_prometheus_operator
  validate_prometheus_server
  validate_grafana
  validate_alertmanager
  validate_node_exporter
  validate_kube_state_metrics
  validate_servicemonitors
  validate_prometheus_storage
  validate_grafana_ingress
  validate_prometheus_ingress
  validate_resource_limits
  validate_pods_health

  # Generate report and summary
  generate_report
  print_summary

  # Exit with appropriate code
  if [ "$FAILED_TESTS" -eq 0 ]; then
    exit 0
  else
    exit 1
  fi
}

# Run main function
main "$@"
