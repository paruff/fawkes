#!/bin/bash
# =============================================================================
# Script: validate-at-e1-012.sh
# Purpose: AT-E1-012 validation runner - calls full platform test
# Description: Wrapper script for comprehensive Epic 1 validation
# Usage: ./scripts/validate-at-e1-012.sh [OPTIONS]
# =============================================================================

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get the root directory
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

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

AT-E1-012: Full platform workflow validation wrapper script.
Calls the comprehensive full-platform-test.sh end-to-end test.

OPTIONS:
    --template TEMPLATE         Template to use (default: python-service)
    --verify-metrics            Verify DORA metrics (default: enabled)
    --verify-observability      Verify observability data (default: enabled)
    --cleanup                   Cleanup after test (default: enabled)
    --no-cleanup                Skip cleanup after test
    -h, --help                  Show this help message

EXAMPLES:
    $0
    $0 --template java-spring-boot --verify-metrics --verify-observability
    $0 --no-cleanup

This script validates:
  ✓ All Epic 1 deliverables (AT-E1-001 through AT-E1-011)
  ✓ Full synthetic user workflow (scaffold → build → deploy → observe)
  ✓ Completion time <20 minutes
  ✓ Zero manual interventions
  ✓ All component health checks
  ✓ DORA metrics dashboard
  ✓ Error-free component logs
  ✓ Platform readiness for Epic 2

EOF
}

check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check required tools
    local required_tools=("kubectl" "jq")
    for tool in "${required_tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            log_error "Required tool not found: $tool"
            return 1
        fi
    done
    
    # Check cluster access
    if ! kubectl cluster-info &> /dev/null; then
        log_error "Cannot access Kubernetes cluster"
        return 1
    fi
    
    log_success "Prerequisites check passed"
    return 0
}

main() {
    echo ""
    echo "=========================================="
    echo "  AT-E1-012: Full Platform Validation"
    echo "=========================================="
    echo ""
    
    # Check for help flag first
    for arg in "$@"; do
        if [ "$arg" = "-h" ] || [ "$arg" = "--help" ]; then
            usage
            exit 0
        fi
    done
    
    # Check prerequisites
    if ! check_prerequisites; then
        log_error "Prerequisites check failed"
        exit 1
    fi
    
    # Run the full platform test
    log_info "Running full platform test..."
    echo ""
    
    if "${ROOT_DIR}/tests/e2e/full-platform-test.sh" "$@"; then
        echo ""
        log_success "AT-E1-012 validation PASSED"
        exit 0
    else
        echo ""
        log_error "AT-E1-012 validation FAILED"
        exit 1
    fi
}

main "$@"
