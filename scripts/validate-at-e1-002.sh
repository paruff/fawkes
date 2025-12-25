#!/bin/bash
# =============================================================================
# Script: validate-at-e1-002.sh
# Purpose: Validate AT-E1-002 acceptance criteria for GitOps with ArgoCD
# Usage: ./scripts/validate-at-e1-002.sh [--namespace NAMESPACE]
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
ARGO_NAMESPACE="${ARGOCD_NAMESPACE:-fawkes}"
VERBOSE=false
REPORT_FILE="reports/at-e1-002-validation-$(date +%Y%m%d-%H%M%S).json"
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

Validate AT-E1-002 acceptance criteria for GitOps with ArgoCD.

OPTIONS:
    -n, --namespace         ArgoCD namespace (default: $ARGO_NAMESPACE)
    -v, --verbose           Verbose output
    -r, --report            Report file path (default: $REPORT_FILE)
    -h, --help              Show this help message

ENVIRONMENT VARIABLES:
    ARGOCD_NAMESPACE        Override default ArgoCD namespace

ACCEPTANCE CRITERIA:
    - ArgoCD deployed via Helm to local cluster
    - ArgoCD CLI installed and configured
    - Git repository structure created (platform/apps/)
    - App-of-apps pattern implemented
    - All platform components synced from Git
    - Auto-sync enabled with self-heal
    - Rollback tested successfully
    - ArgoCD UI accessible via ingress

EXAMPLES:
    $0
    $0 --namespace argocd
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

    # Use jq to properly escape JSON strings
    local json_entry
    json_entry=$(jq -n \
        --arg name "$test_name" \
        --arg status "$status" \
        --arg message "$message" \
        '{name: $name, status: $status, message: $message}')
    TEST_RESULTS+=("$json_entry")
}

check_prerequisites() {
    log_info "Checking prerequisites..."

    # Check kubectl
    if ! command -v kubectl &> /dev/null; then
        record_test "Prerequisites" "FAIL" "kubectl not found"
        return 1
    fi
    record_test "Prerequisites" "PASS" "kubectl is installed"

    # Check argocd CLI (optional but recommended)
    if command -v argocd &> /dev/null; then
        local argocd_version=$(argocd version --client --short 2>/dev/null || echo "unknown")
        record_test "ArgoCD CLI" "PASS" "argocd CLI is installed (version: $argocd_version)"
    else
        record_test "ArgoCD CLI" "FAIL" "argocd CLI not found - install from https://argo-cd.readthedocs.io/en/stable/cli_installation/"
    fi
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

check_argocd_namespace() {
    log_info "Checking ArgoCD namespace..."

    if kubectl get namespace "$ARGO_NAMESPACE" &> /dev/null; then
        local phase=$(kubectl get namespace "$ARGO_NAMESPACE" -o jsonpath='{.status.phase}')
        if [ "$phase" = "Active" ]; then
            record_test "ArgoCD Namespace" "PASS" "Namespace '$ARGO_NAMESPACE' exists and is Active"
        else
            record_test "ArgoCD Namespace" "FAIL" "Namespace '$ARGO_NAMESPACE' exists but phase is '$phase'"
            return 1
        fi
    else
        record_test "ArgoCD Namespace" "FAIL" "Namespace '$ARGO_NAMESPACE' does not exist"
        return 1
    fi
}

check_argocd_deployment() {
    log_info "Checking ArgoCD deployment..."

    local required_components=("argocd-server" "argocd-application-controller" "argocd-repo-server" "argocd-redis")
    local all_running=true

    for component in "${required_components[@]}"; do
        if kubectl get deployment -n "$ARGO_NAMESPACE" -l "app.kubernetes.io/name=$component" &> /dev/null 2>&1 || \
           kubectl get statefulset -n "$ARGO_NAMESPACE" -l "app.kubernetes.io/name=$component" &> /dev/null 2>&1 || \
           kubectl get deployment -n "$ARGO_NAMESPACE" "$component" &> /dev/null 2>&1 || \
           kubectl get statefulset -n "$ARGO_NAMESPACE" "$component" &> /dev/null 2>&1; then
            record_test "ArgoCD Component" "PASS" "$component is deployed"
        else
            record_test "ArgoCD Component" "FAIL" "$component is not deployed"
            all_running=false
        fi
    done

    if [ "$all_running" = false ]; then
        return 1
    fi
}

check_argocd_pods() {
    log_info "Checking ArgoCD pods..."

    local pods=$(kubectl get pods -n "$ARGO_NAMESPACE" -o json)
    local pod_count=$(echo "$pods" | jq -r '.items | length')

    if [ "$pod_count" -eq 0 ]; then
        record_test "ArgoCD Pods" "FAIL" "No pods found in namespace '$ARGO_NAMESPACE'"
        return 1
    fi

    local running_count=$(echo "$pods" | jq -r '[.items[] | select(.status.phase=="Running")] | length')
    local ready_count=$(echo "$pods" | jq -r '[.items[] | select(.status.conditions[]? | select(.type=="Ready" and .status=="True"))] | length')

    if [ "$running_count" -eq "$pod_count" ] && [ "$ready_count" -eq "$pod_count" ]; then
        record_test "ArgoCD Pods" "PASS" "All $pod_count pods are Running and Ready"
    else
        record_test "ArgoCD Pods" "FAIL" "$running_count/$pod_count Running, $ready_count/$pod_count Ready"
        return 1
    fi
}

check_argocd_crds() {
    log_info "Checking ArgoCD CRDs..."

    local required_crds=("applications.argoproj.io" "applicationsets.argoproj.io" "appprojects.argoproj.io")
    local all_installed=true

    for crd in "${required_crds[@]}"; do
        if kubectl get crd "$crd" &> /dev/null; then
            record_test "ArgoCD CRD" "PASS" "$crd is installed"
        else
            record_test "ArgoCD CRD" "FAIL" "$crd is not installed"
            all_installed=false
        fi
    done

    if [ "$all_installed" = false ]; then
        return 1
    fi
}

check_git_repo_structure() {
    log_info "Checking Git repository structure..."

    local required_dirs=("platform/apps" "platform/bootstrap")
    local all_exist=true

    for dir in "${required_dirs[@]}"; do
        if [ -d "$dir" ]; then
            record_test "Git Structure" "PASS" "Directory '$dir' exists"
        else
            record_test "Git Structure" "FAIL" "Directory '$dir' does not exist"
            all_exist=false
        fi
    done

    if [ "$all_exist" = false ]; then
        return 1
    fi
}

check_app_of_apps() {
    log_info "Checking app-of-apps pattern..."

    # Check for root applications
    local root_apps=("platform-bootstrap" "fawkes-app" "fawkes-infra")
    local found_apps=0

    for app in "${root_apps[@]}"; do
        if kubectl get application "$app" -n "$ARGO_NAMESPACE" &> /dev/null; then
            record_test "Root Application" "PASS" "Application '$app' exists"
            found_apps=$((found_apps + 1))
        else
            record_test "Root Application" "FAIL" "Application '$app' not found"
        fi
    done

    if [ $found_apps -eq 0 ]; then
        log_warning "No root applications found. Checking for any applications..."
        local app_count=$(kubectl get applications -n "$ARGO_NAMESPACE" --no-headers 2>/dev/null | wc -l)
        if [ "$app_count" -gt 0 ]; then
            record_test "Applications" "PASS" "Found $app_count ArgoCD Application(s)"
        else
            record_test "Applications" "FAIL" "No ArgoCD Applications found"
            return 1
        fi
    fi
}

check_applications_synced() {
    log_info "Checking application sync status..."

    local apps=$(kubectl get applications -n "$ARGO_NAMESPACE" -o json 2>/dev/null)
    if [ $? -ne 0 ]; then
        record_test "Application Sync" "FAIL" "Cannot retrieve applications"
        return 1
    fi

    local app_count=$(echo "$apps" | jq -r '.items | length')
    if [ "$app_count" -eq 0 ]; then
        record_test "Application Sync" "FAIL" "No applications found to check sync status"
        return 1
    fi

    local synced_count=$(echo "$apps" | jq -r '[.items[] | select(.status.sync.status=="Synced")] | length')
    local healthy_count=$(echo "$apps" | jq -r '[.items[] | select(.status.health.status=="Healthy")] | length')

    if [ "$synced_count" -eq "$app_count" ]; then
        record_test "Application Sync" "PASS" "All $app_count applications are Synced"
    else
        record_test "Application Sync" "FAIL" "$synced_count/$app_count applications are Synced"

        # List out-of-sync apps
        local out_of_sync=$(echo "$apps" | jq -r '.items[] | select(.status.sync.status!="Synced") | .metadata.name')
        if [ -n "$out_of_sync" ]; then
            log_warning "Out-of-sync applications: $out_of_sync"
        fi
    fi

    if [ "$healthy_count" -eq "$app_count" ]; then
        record_test "Application Health" "PASS" "All $app_count applications are Healthy"
    else
        record_test "Application Health" "FAIL" "$healthy_count/$app_count applications are Healthy"

        # List unhealthy apps
        local unhealthy=$(echo "$apps" | jq -r '.items[] | select(.status.health.status!="Healthy") | .metadata.name')
        if [ -n "$unhealthy" ]; then
            log_warning "Unhealthy applications: $unhealthy"
        fi
    fi
}

check_auto_sync() {
    log_info "Checking auto-sync configuration..."

    local apps=$(kubectl get applications -n "$ARGO_NAMESPACE" -o json 2>/dev/null)
    if [ $? -ne 0 ]; then
        record_test "Auto-Sync" "FAIL" "Cannot retrieve applications"
        return 1
    fi

    local app_count=$(echo "$apps" | jq -r '.items | length')
    if [ "$app_count" -eq 0 ]; then
        record_test "Auto-Sync" "FAIL" "No applications found"
        return 1
    fi

    local auto_sync_count=$(echo "$apps" | jq -r '[.items[] | select(.spec.syncPolicy.automated != null)] | length')
    local self_heal_count=$(echo "$apps" | jq -r '[.items[] | select(.spec.syncPolicy.automated.selfHeal == true)] | length')

    if [ "$auto_sync_count" -gt 0 ]; then
        record_test "Auto-Sync Enabled" "PASS" "$auto_sync_count/$app_count applications have auto-sync enabled"
    else
        record_test "Auto-Sync Enabled" "FAIL" "No applications have auto-sync enabled"
    fi

    if [ "$self_heal_count" -gt 0 ]; then
        record_test "Self-Heal Enabled" "PASS" "$self_heal_count/$app_count applications have self-heal enabled"
    else
        record_test "Self-Heal Enabled" "FAIL" "No applications have self-heal enabled"
    fi
}

check_argocd_ingress() {
    log_info "Checking ArgoCD ingress..."

    if kubectl get ingress -n "$ARGO_NAMESPACE" &> /dev/null 2>&1; then
        local ingress_count=$(kubectl get ingress -n "$ARGO_NAMESPACE" --no-headers 2>/dev/null | wc -l)
        if [ "$ingress_count" -gt 0 ]; then
            local ingress_name=$(kubectl get ingress -n "$ARGO_NAMESPACE" -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
            local ingress_host=$(kubectl get ingress -n "$ARGO_NAMESPACE" -o jsonpath='{.items[0].spec.rules[0].host}' 2>/dev/null)
            record_test "ArgoCD Ingress" "PASS" "Ingress '$ingress_name' found with host '$ingress_host'"
        else
            record_test "ArgoCD Ingress" "FAIL" "No ingress found in namespace '$ARGO_NAMESPACE'"
        fi
    else
        record_test "ArgoCD Ingress" "FAIL" "Cannot check ingress resources"
    fi
}

generate_report() {
    log_info "Generating test report..."

    # Create reports directory if it doesn't exist
    mkdir -p "$REPORT_DIR"

    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    local pass_rate=0
    if [ $TOTAL_TESTS -gt 0 ]; then
        pass_rate=$(awk "BEGIN {printf \"%.2f\", ($PASSED_TESTS/$TOTAL_TESTS)*100}")
    fi

    # Build results array properly
    local results_json="[]"
    if [ ${#TEST_RESULTS[@]} -gt 0 ]; then
        results_json=$(printf '%s\n' "${TEST_RESULTS[@]}" | jq -s '.')
    fi

    # Generate report using jq for proper JSON formatting
    jq -n \
        --arg test_id "AT-E1-002" \
        --arg test_name "GitOps with ArgoCD" \
        --arg timestamp "$timestamp" \
        --arg namespace "$ARGO_NAMESPACE" \
        --argjson total "$TOTAL_TESTS" \
        --argjson passed "$PASSED_TESTS" \
        --argjson failed "$FAILED_TESTS" \
        --arg pass_rate "${pass_rate}%" \
        --argjson results "$results_json" \
        '{
            test_id: $test_id,
            test_name: $test_name,
            timestamp: $timestamp,
            namespace: $namespace,
            summary: {
                total: $total,
                passed: $passed,
                failed: $failed,
                pass_rate: $pass_rate
            },
            results: $results
        }' > "$REPORT_FILE"

    log_info "Report saved to: $REPORT_FILE"
}

print_summary() {
    echo ""
    echo "=========================================="
    echo "AT-E1-002 Validation Summary"
    echo "=========================================="
    echo "Total Tests: $TOTAL_TESTS"
    echo "Passed: $PASSED_TESTS"
    echo "Failed: $FAILED_TESTS"
    echo ""

    if [ $FAILED_TESTS -eq 0 ]; then
        log_success "All tests passed! ✅"
        echo ""
        echo "ArgoCD is properly deployed and managing platform components via GitOps."
        return 0
    else
        log_error "Some tests failed! ❌"
        echo ""
        echo "Please review the failures above and ensure:"
        echo "  - ArgoCD is deployed and running"
        echo "  - Applications are defined and synced"
        echo "  - Auto-sync and self-heal are configured"
        echo "  - Git repository structure is correct"
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
            -n|--namespace)
                ARGO_NAMESPACE="$2"
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

    log_info "Starting AT-E1-002 validation..."
    log_info "ArgoCD Namespace: $ARGO_NAMESPACE"
    echo ""

    # Run validation checks
    check_prerequisites
    check_cluster_access || exit 1
    check_argocd_namespace || exit 1
    check_argocd_deployment
    check_argocd_pods
    check_argocd_crds
    check_git_repo_structure
    check_app_of_apps
    check_applications_synced
    check_auto_sync
    check_argocd_ingress

    # Generate report
    generate_report

    # Print summary and exit
    print_summary
}

main "$@"
