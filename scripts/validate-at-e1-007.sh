#!/bin/bash
# =============================================================================
# Script: validate-at-e1-007.sh
# Purpose: Validate AT-E1-007 acceptance criteria for DORA Metrics
# Usage: ./scripts/validate-at-e1-007.sh [--namespace NAMESPACE]
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
DEVLAKE_NAMESPACE="${DEVLAKE_NAMESPACE:-fawkes-devlake}"
MONITORING_NAMESPACE="${MONITORING_NAMESPACE:-monitoring}"
VERBOSE=false
REPORT_FILE="reports/at-e1-007-validation-$(date +%Y%m%d-%H%M%S).json"
REPORT_DIR="reports"
DEVLAKE_URL="http://devlake.127.0.0.1.nip.io"
GRAFANA_URL="http://devlake-grafana.127.0.0.1.nip.io"

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

Validate AT-E1-007 acceptance criteria for DORA Metrics.

OPTIONS:
    -n, --namespace         Namespace (default: $NAMESPACE)
    -d, --devlake-namespace DevLake namespace (default: $DEVLAKE_NAMESPACE)
    -m, --monitoring        Monitoring namespace (default: $MONITORING_NAMESPACE)
    -v, --verbose           Verbose output
    -r, --report            Report file path (default: $REPORT_FILE)
    -u, --devlake-url       DevLake URL (default: $DEVLAKE_URL)
    -g, --grafana-url       Grafana URL (default: $GRAFANA_URL)
    -h, --help              Show this help message

ENVIRONMENT VARIABLES:
    NAMESPACE               Override default namespace
    DEVLAKE_NAMESPACE       Override DevLake namespace
    MONITORING_NAMESPACE    Override monitoring namespace
    DEVLAKE_URL             Override DevLake URL
    GRAFANA_URL             Override Grafana URL

ACCEPTANCE CRITERIA:
    - DORA metrics service deployed (DevLake)
    - Webhook receivers for GitHub, Jenkins, ArgoCD, Incidents
    - All 4 metrics calculated and exposed:
      * Deployment Frequency (per day)
      * Lead Time for Changes (hours)
      * Change Failure Rate (%)
      * Time to Restore Service (hours)
    - Grafana DORA dashboard deployed
    - Historical data stored (PostgreSQL/MySQL)
    - Metrics updated in real-time (<1 min lag)
    - Benchmark comparison (elite/high/medium/low)

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
    
    cat > "$REPORT_FILE" <<EOF
{
  "test_id": "AT-E1-007",
  "test_name": "DORA Metrics Validation",
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
    
    local prereqs_ok=true
    
    # Check kubectl
    if ! command -v kubectl &> /dev/null; then
        record_test "Prerequisite: kubectl" "FAIL" "kubectl not installed"
        prereqs_ok=false
    else
        record_test "Prerequisite: kubectl" "PASS" "kubectl installed"
    fi
    
    # Check cluster access
    if ! kubectl cluster-info &> /dev/null; then
        record_test "Prerequisite: cluster access" "FAIL" "Cannot access Kubernetes cluster"
        prereqs_ok=false
    else
        record_test "Prerequisite: cluster access" "PASS" "Cluster is accessible"
    fi
    
    # Check curl
    if ! command -v curl &> /dev/null; then
        record_test "Prerequisite: curl" "FAIL" "curl not installed"
        prereqs_ok=false
    else
        record_test "Prerequisite: curl" "PASS" "curl installed"
    fi
    
    if [ "$prereqs_ok" = false ]; then
        log_error "Prerequisites validation failed"
        return 1
    fi
}

validate_devlake_deployment() {
    log_info "Validating DevLake deployment..."
    
    # Check namespace
    if kubectl get namespace "$DEVLAKE_NAMESPACE" &> /dev/null; then
        record_test "DevLake namespace" "PASS" "Namespace $DEVLAKE_NAMESPACE exists"
    else
        record_test "DevLake namespace" "FAIL" "Namespace $DEVLAKE_NAMESPACE not found"
        return 1
    fi
    
    # Check ArgoCD Application
    if kubectl get application devlake -n "$NAMESPACE" &> /dev/null; then
        record_test "DevLake ArgoCD Application" "PASS" "Application exists"
        
        # Check sync status
        local sync_status=$(kubectl get application devlake -n "$NAMESPACE" -o jsonpath='{.status.sync.status}' 2>/dev/null)
        if [ "$sync_status" = "Synced" ]; then
            record_test "DevLake sync status" "PASS" "Application is Synced"
        else
            record_test "DevLake sync status" "FAIL" "Application is $sync_status"
        fi
        
        # Check health status
        local health_status=$(kubectl get application devlake -n "$NAMESPACE" -o jsonpath='{.status.health.status}' 2>/dev/null)
        if [ "$health_status" = "Healthy" ]; then
            record_test "DevLake health status" "PASS" "Application is Healthy"
        else
            record_test "DevLake health status" "FAIL" "Application is $health_status"
        fi
    else
        record_test "DevLake ArgoCD Application" "FAIL" "Application not found"
    fi
    
    # Check DevLake pods
    local pod_labels=("app.kubernetes.io/component=lake" "app.kubernetes.io/component=ui" "app.kubernetes.io/component=mysql")
    for label in "${pod_labels[@]}"; do
        local component=$(echo "$label" | cut -d'=' -f2)
        local pod_status=$(kubectl get pods -n "$DEVLAKE_NAMESPACE" -l "$label" -o jsonpath='{.items[0].status.phase}' 2>/dev/null)
        
        if [ "$pod_status" = "Running" ]; then
            record_test "DevLake $component pod" "PASS" "Pod is Running"
        else
            record_test "DevLake $component pod" "FAIL" "Pod status: $pod_status"
        fi
    done
    
    # Check DevLake services
    local services=("devlake-lake" "devlake-ui" "devlake-mysql")
    for svc in "${services[@]}"; do
        if kubectl get svc "$svc" -n "$DEVLAKE_NAMESPACE" &> /dev/null; then
            record_test "Service $svc" "PASS" "Service exists"
        else
            record_test "Service $svc" "FAIL" "Service not found"
        fi
    done
}

validate_database() {
    log_info "Validating database..."
    
    # Check MySQL pod is ready
    local mysql_pod=$(kubectl get pods -n "$DEVLAKE_NAMESPACE" -l app.kubernetes.io/component=mysql -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
    
    if [ -z "$mysql_pod" ]; then
        record_test "Database pod" "FAIL" "MySQL pod not found"
        return 1
    fi
    
    record_test "Database pod" "PASS" "MySQL pod found: $mysql_pod"
    
    # Check database exists
    local db_check=$(kubectl exec -n "$DEVLAKE_NAMESPACE" "$mysql_pod" -- mysql -u root -p"${MYSQL_ROOT_PASSWORD:-devlake}" -e "SHOW DATABASES LIKE 'lake';" 2>/dev/null | grep -c "lake" || echo "0")
    
    if [ "$db_check" -gt 0 ]; then
        record_test "Database lake" "PASS" "Database exists"
        
        # Check key tables for DORA metrics
        local tables=("deployments" "commits" "incidents" "cicd_deployments")
        for table in "${tables[@]}"; do
            local table_check=$(kubectl exec -n "$DEVLAKE_NAMESPACE" "$mysql_pod" -- mysql -u root -p"${MYSQL_ROOT_PASSWORD:-devlake}" lake -e "SHOW TABLES LIKE '$table';" 2>/dev/null | grep -c "$table" || echo "0")
            
            if [ "$table_check" -gt 0 ]; then
                record_test "Database table $table" "PASS" "Table exists"
            else
                record_test "Database table $table" "FAIL" "Table not found"
            fi
        done
    else
        record_test "Database lake" "FAIL" "Database not found"
    fi
}

validate_api_endpoints() {
    log_info "Validating API endpoints..."
    
    # Get DevLake pod
    local devlake_pod=$(kubectl get pods -n "$DEVLAKE_NAMESPACE" -l app.kubernetes.io/component=lake -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
    
    if [ -z "$devlake_pod" ]; then
        record_test "DevLake API pod" "FAIL" "Pod not found"
        return 1
    fi
    
    record_test "DevLake API pod" "PASS" "Pod found: $devlake_pod"
    
    # Check health endpoint
    local health_check=$(kubectl exec -n "$DEVLAKE_NAMESPACE" "$devlake_pod" -- curl -s http://localhost:8080/api/ping 2>/dev/null || echo "")
    if echo "$health_check" | grep -q "pong"; then
        record_test "API health endpoint" "PASS" "Health check responds with pong"
    else
        record_test "API health endpoint" "FAIL" "Health check failed"
    fi
    
    # Check metrics endpoint
    local metrics_check=$(kubectl exec -n "$DEVLAKE_NAMESPACE" "$devlake_pod" -- curl -s http://localhost:8080/metrics 2>/dev/null || echo "")
    if [ -n "$metrics_check" ]; then
        record_test "Prometheus metrics endpoint" "PASS" "Metrics endpoint responds"
        
        # Check for DORA metrics
        if echo "$metrics_check" | grep -q "dora"; then
            record_test "DORA metrics exposure" "PASS" "DORA metrics found in Prometheus endpoint"
        else
            record_test "DORA metrics exposure" "FAIL" "DORA metrics not found"
        fi
    else
        record_test "Prometheus metrics endpoint" "FAIL" "Metrics endpoint not responding"
    fi
    
    # Check GraphQL endpoint
    local graphql_check=$(kubectl exec -n "$DEVLAKE_NAMESPACE" "$devlake_pod" -- curl -s -X POST http://localhost:8080/api/graphql -H "Content-Type: application/json" -d '{"query":"{ __schema { types { name } } }"}' 2>/dev/null || echo "")
    if echo "$graphql_check" | grep -q "types"; then
        record_test "GraphQL API endpoint" "PASS" "GraphQL responds"
    else
        record_test "GraphQL API endpoint" "FAIL" "GraphQL not responding"
    fi
}

validate_webhook_receivers() {
    log_info "Validating webhook receivers..."
    
    # Check webhook configuration documentation
    local webhook_docs=("platform/apps/devlake/config/github-webhook-setup.md" 
                        "platform/apps/devlake/config/jenkins-webhook-setup.md"
                        "platform/apps/devlake/config/argocd-webhook-setup.md")
    
    for doc in "${webhook_docs[@]}"; do
        if [ -f "$doc" ]; then
            record_test "Webhook documentation $(basename $doc)" "PASS" "Documentation exists"
        else
            record_test "Webhook documentation $(basename $doc)" "FAIL" "Documentation not found"
        fi
    done
    
    # Check Jenkins shared library for DORA metrics
    if [ -f "jenkins-shared-library/vars/doraMetrics.groovy" ]; then
        record_test "Jenkins DORA metrics library" "PASS" "doraMetrics.groovy exists"
        
        # Check for webhook functions
        if grep -q "recordBuild" "jenkins-shared-library/vars/doraMetrics.groovy"; then
            record_test "Jenkins recordBuild function" "PASS" "Function found"
        else
            record_test "Jenkins recordBuild function" "FAIL" "Function not found"
        fi
        
        if grep -q "recordDeployment" "jenkins-shared-library/vars/doraMetrics.groovy"; then
            record_test "Jenkins recordDeployment function" "PASS" "Function found"
        else
            record_test "Jenkins recordDeployment function" "FAIL" "Function not found"
        fi
    else
        record_test "Jenkins DORA metrics library" "FAIL" "doraMetrics.groovy not found"
    fi
}

validate_dora_metrics() {
    log_info "Validating DORA metrics calculation..."
    
    # Check for metric calculation queries/scripts
    local metrics=("Deployment Frequency" "Lead Time for Changes" "Change Failure Rate" "Mean Time to Restore")
    
    # Validate dashboard contains all 4 metrics
    local dashboard_file="platform/apps/grafana/dashboards/dora-metrics-dashboard.json"
    if [ -f "$dashboard_file" ]; then
        record_test "DORA dashboard file" "PASS" "Dashboard file exists"
        
        for metric in "${metrics[@]}"; do
            if grep -q "$metric" "$dashboard_file"; then
                record_test "Metric: $metric" "PASS" "Metric found in dashboard"
            else
                record_test "Metric: $metric" "FAIL" "Metric not found in dashboard"
            fi
        done
    else
        record_test "DORA dashboard file" "FAIL" "Dashboard file not found"
    fi
}

validate_grafana_dashboard() {
    log_info "Validating Grafana dashboard deployment..."
    
    # Check Grafana pod
    local grafana_pod=$(kubectl get pods -n "$DEVLAKE_NAMESPACE" -l app.kubernetes.io/component=grafana -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
    
    if [ -n "$grafana_pod" ]; then
        record_test "Grafana pod" "PASS" "Pod found: $grafana_pod"
        
        # Check Grafana health
        local grafana_health=$(kubectl exec -n "$DEVLAKE_NAMESPACE" "$grafana_pod" -- curl -s http://localhost:3000/api/health 2>/dev/null || echo "")
        if echo "$grafana_health" | grep -q "ok"; then
            record_test "Grafana health" "PASS" "Health check passed"
        else
            record_test "Grafana health" "FAIL" "Health check failed"
        fi
    else
        record_test "Grafana pod" "FAIL" "Pod not found"
    fi
    
    # Check Grafana service
    if kubectl get svc devlake-grafana -n "$DEVLAKE_NAMESPACE" &> /dev/null; then
        record_test "Grafana service" "PASS" "Service exists"
    else
        record_test "Grafana service" "FAIL" "Service not found"
    fi
    
    # Check Grafana ingress
    if kubectl get ingress devlake-grafana -n "$DEVLAKE_NAMESPACE" &> /dev/null; then
        record_test "Grafana ingress" "PASS" "Ingress configured"
    else
        record_test "Grafana ingress" "FAIL" "Ingress not found"
    fi
}

validate_prometheus_integration() {
    log_info "Validating Prometheus integration..."
    
    # Check ServiceMonitor exists
    if kubectl get servicemonitor -n "$MONITORING_NAMESPACE" 2>/dev/null | grep -q "devlake"; then
        record_test "DevLake ServiceMonitor" "PASS" "ServiceMonitor exists"
    else
        record_test "DevLake ServiceMonitor" "FAIL" "ServiceMonitor not found"
    fi
}

validate_benchmark_comparison() {
    log_info "Validating benchmark comparison..."
    
    # Check dashboard includes benchmark thresholds
    local dashboard_file="platform/apps/grafana/dashboards/dora-metrics-dashboard.json"
    if [ -f "$dashboard_file" ]; then
        local has_benchmarks=false
        
        # Check for DORA performance levels
        if grep -q "Elite" "$dashboard_file" && \
           grep -q "High" "$dashboard_file" && \
           grep -q "Medium" "$dashboard_file" && \
           grep -q "Low" "$dashboard_file"; then
            record_test "Benchmark thresholds" "PASS" "All DORA performance levels included"
            has_benchmarks=true
        fi
        
        if grep -q "Benchmark" "$dashboard_file"; then
            record_test "Benchmark comparison panel" "PASS" "Benchmark panel found"
        else
            record_test "Benchmark comparison panel" "FAIL" "Benchmark panel not found"
        fi
        
        if [ "$has_benchmarks" = false ]; then
            record_test "Benchmark thresholds" "FAIL" "Performance levels not found"
        fi
    fi
}

# =============================================================================
# Main Function
# =============================================================================

main() {
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -n|--namespace)
                NAMESPACE="$2"
                shift 2
                ;;
            -d|--devlake-namespace)
                DEVLAKE_NAMESPACE="$2"
                shift 2
                ;;
            -m|--monitoring)
                MONITORING_NAMESPACE="$2"
                shift 2
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -r|--report)
                REPORT_FILE="$2"
                shift 2
                ;;
            -u|--devlake-url)
                DEVLAKE_URL="$2"
                shift 2
                ;;
            -g|--grafana-url)
                GRAFANA_URL="$2"
                shift 2
                ;;
            -h|--help)
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
    echo "  AT-E1-007: DORA Metrics Validation"
    echo "========================================================================"
    echo ""
    echo "  Namespace:           $NAMESPACE"
    echo "  DevLake Namespace:   $DEVLAKE_NAMESPACE"
    echo "  Monitoring Namespace: $MONITORING_NAMESPACE"
    echo "  DevLake URL:         $DEVLAKE_URL"
    echo "  Grafana URL:         $GRAFANA_URL"
    echo ""
    
    # Run validations
    validate_prerequisites || true
    validate_devlake_deployment || true
    validate_database || true
    validate_api_endpoints || true
    validate_webhook_receivers || true
    validate_dora_metrics || true
    validate_grafana_dashboard || true
    validate_prometheus_integration || true
    validate_benchmark_comparison || true
    
    # Generate report
    generate_report
    
    echo ""
    echo "========================================================================"
    echo "  Summary"
    echo "========================================================================"
    echo ""
    echo "  Total Tests:   $TOTAL_TESTS"
    echo "  Passed:        $PASSED_TESTS"
    echo "  Failed:        $FAILED_TESTS"
    echo ""
    
    if [ "$FAILED_TESTS" -eq 0 ]; then
        log_success "All AT-E1-007 acceptance criteria validated successfully!"
        echo ""
        echo "Next steps:"
        echo "  1. View DORA metrics: $GRAFANA_URL"
        echo "  2. Check DevLake UI: $DEVLAKE_URL"
        echo "  3. Review test report: $REPORT_FILE"
        echo ""
        exit 0
    else
        log_error "AT-E1-007 validation failed with $FAILED_TESTS failures"
        echo ""
        echo "Troubleshooting:"
        echo "  1. Check DevLake logs: kubectl logs -n $DEVLAKE_NAMESPACE -l app.kubernetes.io/name=devlake"
        echo "  2. Check ArgoCD application: kubectl get application devlake -n $NAMESPACE"
        echo "  3. Verify database: kubectl exec -n $DEVLAKE_NAMESPACE <mysql-pod> -- mysql -u root -p"
        echo "  4. Review test report: $REPORT_FILE"
        echo ""
        exit 1
    fi
}

# Run main function
main "$@"
