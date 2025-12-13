#!/bin/bash
# =============================================================================
# Script: validate-at-e1-001.sh
# Purpose: Validate AT-E1-001 acceptance criteria for AKS cluster
# Usage: ./scripts/validate-at-e1-001.sh [--resource-group RG] [--cluster-name NAME]
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
RESOURCE_GROUP="${AZURE_RESOURCE_GROUP:-fawkes-rg}"
CLUSTER_NAME="${AZURE_CLUSTER_NAME:-fawkes-aks}"
MIN_NODES=4
MAX_CPU_PERCENT=70
MAX_MEMORY_PERCENT=70
MAX_DISK_PERCENT=80
VERBOSE=false
REPORT_FILE="reports/at-e1-001-validation-$(date +%Y%m%d-%H%M%S).json"

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

Validate AT-E1-001 acceptance criteria for AKS cluster.

OPTIONS:
    -g, --resource-group    Azure resource group name (default: $RESOURCE_GROUP)
    -c, --cluster-name      AKS cluster name (default: $CLUSTER_NAME)
    -m, --min-nodes         Minimum required nodes (default: $MIN_NODES)
    -v, --verbose           Verbose output
    -h, --help              Show this help message

ENVIRONMENT VARIABLES:
    AZURE_RESOURCE_GROUP    Override default resource group
    AZURE_CLUSTER_NAME      Override default cluster name

ACCEPTANCE CRITERIA:
    - K8s cluster running (azure aks)
    - 4 worker nodes healthy and schedulable
    - Cluster metrics available (kubelet, cAdvisor)
    - StorageClass configured for persistent volumes
    - Ingress controller deployed (nginx/traefik)
    - Cluster resource limits: CPU <70%, Memory <70%, Disk <80%

EXAMPLES:
    $0
    $0 --resource-group my-rg --cluster-name my-aks
    $0 --verbose

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
    
    # Store result for JSON report (escape quotes in message)
    local escaped_message="${message//\"/\\\"}"
    TEST_RESULTS+=("{\"test\":\"$test_name\",\"status\":\"$status\",\"message\":\"$escaped_message\"}")
}

# =============================================================================
# Validation Tests
# =============================================================================

check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check Azure CLI
    if ! command -v az &> /dev/null; then
        record_test "Prerequisites - Azure CLI" "FAIL" "Azure CLI not installed"
        return 1
    fi
    record_test "Prerequisites - Azure CLI" "PASS" "Azure CLI installed"
    
    # Check kubectl
    if ! command -v kubectl &> /dev/null; then
        record_test "Prerequisites - kubectl" "FAIL" "kubectl not installed"
        return 1
    fi
    record_test "Prerequisites - kubectl" "PASS" "kubectl installed"
    
    # Check Azure authentication
    if ! az account show &> /dev/null; then
        record_test "Prerequisites - Azure Auth" "FAIL" "Not authenticated to Azure"
        return 1
    fi
    record_test "Prerequisites - Azure Auth" "PASS" "Authenticated to Azure"
    
    return 0
}

check_cluster_exists() {
    log_info "Checking if AKS cluster exists..."
    
    if az aks show --resource-group "$RESOURCE_GROUP" --name "$CLUSTER_NAME" &> /dev/null; then
        local provisioning_state=$(az aks show --resource-group "$RESOURCE_GROUP" --name "$CLUSTER_NAME" --query "provisioningState" -o tsv)
        local power_state=$(az aks show --resource-group "$RESOURCE_GROUP" --name "$CLUSTER_NAME" --query "powerState.code" -o tsv)
        
        if [ "$provisioning_state" = "Succeeded" ] && [ "$power_state" = "Running" ]; then
            record_test "Cluster Exists" "PASS" "Cluster is provisioned and running"
            return 0
        else
            record_test "Cluster Exists" "FAIL" "Cluster state: $provisioning_state, Power: $power_state"
            return 1
        fi
    else
        record_test "Cluster Exists" "FAIL" "Cluster $CLUSTER_NAME not found in $RESOURCE_GROUP"
        return 1
    fi
}

check_kubectl_configured() {
    log_info "Checking kubectl configuration..."
    
    # Get credentials
    if ! az aks get-credentials --resource-group "$RESOURCE_GROUP" --name "$CLUSTER_NAME" --overwrite-existing &> /dev/null; then
        record_test "kubectl Configuration" "FAIL" "Failed to get cluster credentials"
        return 1
    fi
    
    # Test connection
    if kubectl cluster-info &> /dev/null; then
        record_test "kubectl Configuration" "PASS" "kubectl can connect to cluster"
        return 0
    else
        record_test "kubectl Configuration" "FAIL" "kubectl cannot connect to cluster"
        return 1
    fi
}

check_node_count() {
    log_info "Checking node count..."
    
    local node_count=$(kubectl get nodes --no-headers 2>/dev/null | wc -l)
    
    if [ "$node_count" -ge "$MIN_NODES" ]; then
        record_test "Node Count" "PASS" "$node_count nodes found (minimum: $MIN_NODES)"
        return 0
    else
        record_test "Node Count" "FAIL" "Only $node_count nodes found (minimum: $MIN_NODES required)"
        return 1
    fi
}

check_nodes_ready() {
    log_info "Checking if all nodes are Ready..."
    
    local not_ready=$(kubectl get nodes --no-headers 2>/dev/null | grep -v " Ready " | wc -l)
    local total=$(kubectl get nodes --no-headers 2>/dev/null | wc -l)
    
    if [ "$not_ready" -eq 0 ]; then
        record_test "Nodes Ready" "PASS" "All $total nodes are Ready"
        return 0
    else
        record_test "Nodes Ready" "FAIL" "$not_ready out of $total nodes are not Ready"
        return 1
    fi
}

check_nodes_schedulable() {
    log_info "Checking if nodes are schedulable..."
    
    local unschedulable=$(kubectl get nodes -o json 2>/dev/null | jq '[.items[] | select(.spec.unschedulable // false == true)] | length')
    local total=$(kubectl get nodes --no-headers 2>/dev/null | wc -l)
    
    if [ "$unschedulable" -eq 0 ]; then
        record_test "Nodes Schedulable" "PASS" "All $total nodes are schedulable"
        return 0
    else
        record_test "Nodes Schedulable" "FAIL" "$unschedulable nodes are unschedulable"
        return 1
    fi
}

check_system_pods() {
    log_info "Checking system pods..."
    
    local not_running=$(kubectl get pods -n kube-system --no-headers 2>/dev/null | grep -v "Running\|Succeeded" | wc -l)
    local total=$(kubectl get pods -n kube-system --no-headers 2>/dev/null | wc -l)
    
    if [ "$not_running" -eq 0 ]; then
        record_test "System Pods Running" "PASS" "All $total system pods are Running"
        return 0
    else
        record_test "System Pods Running" "FAIL" "$not_running out of $total system pods not Running"
        return 1
    fi
}

check_metrics_available() {
    log_info "Checking if cluster metrics are available..."
    
    # Check if metrics-server is deployed
    if kubectl get deployment metrics-server -n kube-system &> /dev/null; then
        # Try to get node metrics
        if kubectl top nodes &> /dev/null; then
            record_test "Cluster Metrics" "PASS" "Metrics available (metrics-server working)"
            return 0
        else
            record_test "Cluster Metrics" "FAIL" "metrics-server deployed but not returning data"
            return 1
        fi
    else
        record_test "Cluster Metrics" "FAIL" "metrics-server not deployed"
        return 1
    fi
}

check_storage_class() {
    log_info "Checking StorageClass configuration..."
    
    local storage_classes=$(kubectl get storageclass --no-headers 2>/dev/null | wc -l)
    local default_sc=$(kubectl get storageclass -o json 2>/dev/null | jq '[.items[] | select(.metadata.annotations["storageclass.kubernetes.io/is-default-class"] == "true")] | length')
    
    if [ "$storage_classes" -gt 0 ] && [ "$default_sc" -gt 0 ]; then
        record_test "StorageClass Configured" "PASS" "$storage_classes StorageClass(es) found, $default_sc default"
        return 0
    elif [ "$storage_classes" -gt 0 ]; then
        record_test "StorageClass Configured" "FAIL" "$storage_classes StorageClass(es) found but no default configured"
        return 1
    else
        record_test "StorageClass Configured" "FAIL" "No StorageClass configured"
        return 1
    fi
}

check_ingress_controller() {
    log_info "Checking ingress controller..."
    
    # Check for common ingress controllers
    local nginx_exists=$(kubectl get deployment -A -l app.kubernetes.io/name=ingress-nginx --no-headers 2>/dev/null | wc -l)
    local traefik_exists=$(kubectl get deployment -A -l app.kubernetes.io/name=traefik --no-headers 2>/dev/null | wc -l)
    
    if [ "$nginx_exists" -gt 0 ]; then
        record_test "Ingress Controller" "PASS" "nginx-ingress controller deployed"
        return 0
    elif [ "$traefik_exists" -gt 0 ]; then
        record_test "Ingress Controller" "PASS" "traefik controller deployed"
        return 0
    else
        record_test "Ingress Controller" "FAIL" "No ingress controller (nginx/traefik) found"
        return 1
    fi
}

check_resource_limits() {
    log_info "Checking cluster resource limits..."
    
    # Check if we can get metrics
    if ! kubectl top nodes &> /dev/null; then
        record_test "Resource Limits" "FAIL" "Cannot retrieve node metrics"
        return 1
    fi
    
    # Get node metrics and check CPU/Memory
    local nodes_over_limit=0
    while IFS= read -r line; do
        # Skip header
        if [[ "$line" =~ ^NAME ]]; then
            continue
        fi
        
        # Parse metrics (format: NAME CPU(cores) CPU% MEMORY(bytes) MEMORY%)
        local cpu_percent=$(echo "$line" | awk '{print $3}' | tr -d '%' | xargs)
        local memory_percent=$(echo "$line" | awk '{print $5}' | tr -d '%' | xargs)
        local node_name=$(echo "$line" | awk '{print $1}')
        
        # Validate that percentages are numeric (integer or decimal)
        if ! [[ "$cpu_percent" =~ ^[0-9]+(\.[0-9]+)?$ ]] || ! [[ "$memory_percent" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
            [ "$VERBOSE" = true ] && log_warning "Node $node_name: Invalid metrics format"
            continue
        fi
        
        # Check if over limits using awk for proper decimal comparison
        local cpu_over=$(awk "BEGIN {print ($cpu_percent >= $MAX_CPU_PERCENT) ? 1 : 0}")
        local memory_over=$(awk "BEGIN {print ($memory_percent >= $MAX_MEMORY_PERCENT) ? 1 : 0}")
        
        if [ "$cpu_over" -eq 1 ] || [ "$memory_over" -eq 1 ]; then
            nodes_over_limit=$((nodes_over_limit + 1))
            [ "$VERBOSE" = true ] && log_warning "Node $node_name: CPU=${cpu_percent}%, Memory=${memory_percent}%"
        fi
    done < <(kubectl top nodes)
    
    if [ "$nodes_over_limit" -eq 0 ]; then
        record_test "Resource Limits" "PASS" "All nodes within limits (CPU<${MAX_CPU_PERCENT}%, Memory<${MAX_MEMORY_PERCENT}%)"
        return 0
    else
        record_test "Resource Limits" "FAIL" "$nodes_over_limit node(s) over resource limits"
        return 1
    fi
}

# =============================================================================
# Report Generation
# =============================================================================

generate_report() {
    log_info "Generating validation report..."
    
    mkdir -p "$(dirname "$REPORT_FILE")"
    
    # Calculate success rate, handling division by zero
    local success_rate=0
    if [ "$TOTAL_TESTS" -gt 0 ]; then
        success_rate=$(awk "BEGIN {printf \"%.2f\", ($PASSED_TESTS/$TOTAL_TESTS)*100}")
    fi
    
    # Build test results JSON array
    local tests_json="[]"
    if [ "${#TEST_RESULTS[@]}" -gt 0 ]; then
        tests_json="[$(IFS=,; echo "${TEST_RESULTS[*]}")]"
    fi
    
    # Create JSON report
    cat > "$REPORT_FILE" << EOF
{
  "test_suite": "AT-E1-001",
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "cluster": {
    "resource_group": "$RESOURCE_GROUP",
    "name": "$CLUSTER_NAME"
  },
  "summary": {
    "total": $TOTAL_TESTS,
    "passed": $PASSED_TESTS,
    "failed": $FAILED_TESTS,
    "success_rate": $success_rate
  },
  "tests": $tests_json
}
EOF
    
    log_success "Report saved to: $REPORT_FILE"
}

print_summary() {
    # Calculate success rate, handling division by zero
    local success_rate=0
    if [ "$TOTAL_TESTS" -gt 0 ]; then
        success_rate=$(awk "BEGIN {printf \"%.1f\", ($PASSED_TESTS/$TOTAL_TESTS)*100}")
    fi
    
    echo ""
    echo "========================================"
    echo "  AT-E1-001 Validation Summary"
    echo "========================================"
    echo "Cluster: $CLUSTER_NAME ($RESOURCE_GROUP)"
    echo "Total Tests: $TOTAL_TESTS"
    echo -e "Passed: ${GREEN}$PASSED_TESTS${NC}"
    echo -e "Failed: ${RED}$FAILED_TESTS${NC}"
    echo "Success Rate: ${success_rate}%"
    echo "========================================"
    echo ""
    
    if [ "$FAILED_TESTS" -eq 0 ] && [ "$TOTAL_TESTS" -gt 0 ]; then
        log_success "All AT-E1-001 acceptance criteria validated successfully!"
        return 0
    else
        log_error "AT-E1-001 validation failed. Please review the errors above."
        return 1
    fi
}

# =============================================================================
# Main
# =============================================================================

main() {
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -g|--resource-group)
                RESOURCE_GROUP="$2"
                shift 2
                ;;
            -c|--cluster-name)
                CLUSTER_NAME="$2"
                shift 2
                ;;
            -m|--min-nodes)
                MIN_NODES="$2"
                shift 2
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
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
    echo "========================================"
    echo "  AT-E1-001 Acceptance Test Validation"
    echo "========================================"
    echo "Cluster: $CLUSTER_NAME"
    echo "Resource Group: $RESOURCE_GROUP"
    echo "Min Nodes: $MIN_NODES"
    echo "========================================"
    echo ""
    
    # Run all validation checks
    check_prerequisites || true
    check_cluster_exists || true
    check_kubectl_configured || true
    check_node_count || true
    check_nodes_ready || true
    check_nodes_schedulable || true
    check_system_pods || true
    check_metrics_available || true
    check_storage_class || true
    check_ingress_controller || true
    check_resource_limits || true
    
    # Generate report
    generate_report
    
    # Print summary and exit with appropriate code
    if print_summary; then
        exit 0
    else
        exit 1
    fi
}

# Run main function
main "$@"
