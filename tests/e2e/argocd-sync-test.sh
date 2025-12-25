#!/bin/bash
# =============================================================================
# Script: argocd-sync-test.sh
# Purpose: E2E test for ArgoCD sync and GitOps workflow
# Usage: ./tests/e2e/argocd-sync-test.sh [--namespace NAMESPACE] [--app APP_NAME]
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
APP_NAME="${APP_NAME:-}"
TIMEOUT=300
VERBOSE=false

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

E2E test for ArgoCD sync and GitOps workflow.

OPTIONS:
    -n, --namespace         ArgoCD namespace (default: $ARGO_NAMESPACE)
    -a, --app               Specific application to test (default: all)
    -t, --timeout           Timeout in seconds (default: $TIMEOUT)
    -v, --verbose           Verbose output
    -h, --help              Show this help message

EXAMPLES:
    $0
    $0 --namespace argocd
    $0 --app platform-bootstrap --timeout 600

EOF
}

wait_for_sync() {
    local app_name="$1"
    local namespace="$2"
    local timeout="$3"

    log_info "Waiting for application '$app_name' to sync (timeout: ${timeout}s)..."

    local elapsed=0
    local interval=5

    while [ $elapsed -lt $timeout ]; do
        local sync_status=$(kubectl get application "$app_name" -n "$namespace" -o jsonpath='{.status.sync.status}' 2>/dev/null || echo "Unknown")

        if [ "$sync_status" = "Synced" ]; then
            log_success "Application '$app_name' is Synced"
            return 0
        fi

        if [ "$VERBOSE" = true ]; then
            log_info "Current sync status: $sync_status (elapsed: ${elapsed}s)"
        fi

        sleep $interval
        elapsed=$((elapsed + interval))
    done

    log_error "Timeout waiting for application '$app_name' to sync"
    return 1
}

wait_for_health() {
    local app_name="$1"
    local namespace="$2"
    local timeout="$3"

    log_info "Waiting for application '$app_name' to be healthy (timeout: ${timeout}s)..."

    local elapsed=0
    local interval=5

    while [ $elapsed -lt $timeout ]; do
        local health_status=$(kubectl get application "$app_name" -n "$namespace" -o jsonpath='{.status.health.status}' 2>/dev/null || echo "Unknown")

        if [ "$health_status" = "Healthy" ]; then
            log_success "Application '$app_name' is Healthy"
            return 0
        fi

        if [ "$VERBOSE" = true ]; then
            log_info "Current health status: $health_status (elapsed: ${elapsed}s)"
        fi

        sleep $interval
        elapsed=$((elapsed + interval))
    done

    log_error "Timeout waiting for application '$app_name' to be healthy"
    return 1
}

test_application_sync() {
    local app_name="$1"
    local namespace="$2"

    log_info "Testing sync for application: $app_name"

    # Check if application exists
    if ! kubectl get application "$app_name" -n "$namespace" &> /dev/null; then
        log_error "Application '$app_name' does not exist"
        return 1
    fi

    # Trigger hard refresh
    log_info "Triggering hard refresh for application '$app_name'..."
    if command -v argocd &> /dev/null; then
        argocd app get "$app_name" --hard-refresh &> /dev/null || true
    else
        log_warning "argocd CLI not found, skipping hard refresh"
    fi

    # Wait for sync
    if ! wait_for_sync "$app_name" "$namespace" "$TIMEOUT"; then
        return 1
    fi

    # Wait for health
    if ! wait_for_health "$app_name" "$namespace" "$TIMEOUT"; then
        return 1
    fi

    log_success "Application '$app_name' sync test passed"
    return 0
}

test_all_applications() {
    local namespace="$1"

    log_info "Testing sync for all applications in namespace '$namespace'..."

    local apps=$(kubectl get applications -n "$namespace" -o jsonpath='{.items[*].metadata.name}' 2>/dev/null)

    if [ -z "$apps" ]; then
        log_error "No applications found in namespace '$namespace'"
        return 1
    fi

    local total=0
    local passed=0
    local failed=0

    for app in $apps; do
        total=$((total + 1))
        if test_application_sync "$app" "$namespace"; then
            passed=$((passed + 1))
        else
            failed=$((failed + 1))
        fi
        echo ""
    done

    echo "=========================================="
    echo "Test Summary"
    echo "=========================================="
    echo "Total Applications: $total"
    echo "Passed: $passed"
    echo "Failed: $failed"
    echo ""

    if [ $failed -eq 0 ]; then
        log_success "All application sync tests passed!"
        return 0
    else
        log_error "Some application sync tests failed"
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
            -a|--app)
                APP_NAME="$2"
                shift 2
                ;;
            -t|--timeout)
                TIMEOUT="$2"
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

    log_info "Starting ArgoCD sync E2E tests..."
    log_info "Namespace: $ARGO_NAMESPACE"
    log_info "Timeout: ${TIMEOUT}s"
    echo ""

    # Check prerequisites
    if ! command -v kubectl &> /dev/null; then
        log_error "kubectl not found"
        exit 1
    fi

    # Check cluster access
    if ! kubectl cluster-info &> /dev/null; then
        log_error "Cannot access Kubernetes cluster"
        exit 1
    fi

    # Check namespace exists
    if ! kubectl get namespace "$ARGO_NAMESPACE" &> /dev/null; then
        log_error "Namespace '$ARGO_NAMESPACE' does not exist"
        exit 1
    fi

    # Run tests
    if [ -n "$APP_NAME" ]; then
        test_application_sync "$APP_NAME" "$ARGO_NAMESPACE"
    else
        test_all_applications "$ARGO_NAMESPACE"
    fi
}

main "$@"
