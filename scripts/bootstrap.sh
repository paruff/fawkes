#!/usr/bin/env bash
# =============================================================================
# FILE: scripts/bootstrap.sh
# PURPOSE: Bootstrap Fawkes platform using app-of-apps pattern
#          Applies the root Application that manages all platform components
# USAGE: ./scripts/bootstrap.sh [--dry-run] [--namespace <ns>]
# DEPENDENCIES: kubectl, argocd (optional)
# =============================================================================
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
ARGO_NS="${ARGOCD_NAMESPACE:-fawkes}"
DRY_RUN=0
VERBOSE=0
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# =============================================================================
# Helper Functions
# =============================================================================

log_info() {
  echo -e "${BLUE}ℹ ${NC}$*"
}

log_success() {
  echo -e "${GREEN}✅${NC} $*"
}

log_warning() {
  echo -e "${YELLOW}⚠️ ${NC}$*"
}

log_error() {
  echo -e "${RED}❌${NC} $*" >&2
}

error_exit() {
  log_error "$1"
  exit 1
}

usage() {
  cat <<EOF
Bootstrap Fawkes platform using app-of-apps pattern

Usage: $0 [OPTIONS]

Options:
  -h, --help            Show this help message
  -n, --namespace NS    ArgoCD namespace (default: ${ARGO_NS})
  -d, --dry-run         Show what would be applied without applying
  -v, --verbose         Enable verbose output
  --wait                Wait for applications to sync (default: false)
  --timeout SECONDS     Timeout for waiting (default: 300)

Examples:
  # Bootstrap with default settings
  $0

  # Bootstrap with custom namespace
  $0 --namespace argocd

  # Dry run to see what would be applied
  $0 --dry-run

  # Bootstrap and wait for sync
  $0 --wait --timeout 600

EOF
  exit 0
}

# =============================================================================
# Validation Functions
# =============================================================================

check_prerequisites() {
  log_info "Checking prerequisites..."
  
  # Check kubectl
  if ! command -v kubectl >/dev/null 2>&1; then
    error_exit "kubectl is not installed. Please install kubectl."
  fi
  
  # Check cluster connectivity
  if ! kubectl cluster-info >/dev/null 2>&1; then
    error_exit "Cannot connect to Kubernetes cluster. Check your kubeconfig."
  fi
  
  # Check if ArgoCD namespace exists
  if ! kubectl get namespace "${ARGO_NS}" >/dev/null 2>&1; then
    error_exit "ArgoCD namespace '${ARGO_NS}' does not exist. Please install ArgoCD first."
  fi
  
  # Check if ArgoCD is running
  if ! kubectl get deployment argocd-server -n "${ARGO_NS}" >/dev/null 2>&1; then
    error_exit "ArgoCD is not installed in namespace '${ARGO_NS}'. Please install ArgoCD first."
  fi
  
  # Check argocd CLI (optional)
  if command -v argocd >/dev/null 2>&1; then
    log_success "argocd CLI found (optional features enabled)"
  else
    log_warning "argocd CLI not found (optional features disabled)"
  fi
  
  log_success "Prerequisites check passed"
}

validate_manifests() {
  log_info "Validating bootstrap manifests..."
  
  local bootstrap_dir="${ROOT_DIR}/platform/bootstrap"
  
  # Check if required files exist
  local required_files=(
    "app-of-apps.yaml"
    "applicationset.yaml"
    "kustomization.yaml"
    "project-default.yaml"
  )
  
  for file in "${required_files[@]}"; do
    if [[ ! -f "${bootstrap_dir}/${file}" ]]; then
      error_exit "Required file not found: ${bootstrap_dir}/${file}"
    fi
  done
  
  # Validate kustomization
  if ! kubectl kustomize "${bootstrap_dir}" >/dev/null 2>&1; then
    error_exit "Invalid kustomization in ${bootstrap_dir}"
  fi
  
  log_success "Manifest validation passed"
}

# =============================================================================
# Bootstrap Functions
# =============================================================================

apply_bootstrap() {
  log_info "Applying bootstrap configuration..."
  
  local bootstrap_dir="${ROOT_DIR}/platform/bootstrap"
  
  if [[ $DRY_RUN -eq 1 ]]; then
    log_info "[DRY-RUN] Would apply:"
    kubectl kustomize "${bootstrap_dir}"
    return 0
  fi
  
  # Apply the bootstrap kustomization
  if kubectl apply -k "${bootstrap_dir}"; then
    log_success "Bootstrap configuration applied"
  else
    error_exit "Failed to apply bootstrap configuration"
  fi
}

wait_for_sync() {
  local timeout="${1:-300}"
  log_info "Waiting for applications to sync (timeout: ${timeout}s)..."
  
  local end=$((SECONDS + timeout))
  
  # Wait for app-of-apps to sync
  log_info "Waiting for platform-bootstrap to sync..."
  while [[ ${SECONDS} -lt ${end} ]]; do
    local status
    status=$(kubectl get application platform-bootstrap -n "${ARGO_NS}" \
      -o jsonpath='{.status.sync.status}' 2>/dev/null || echo "Unknown")
    
    if [[ "$status" == "Synced" ]]; then
      log_success "platform-bootstrap synced successfully"
      break
    elif [[ "$status" == "Unknown" ]]; then
      log_warning "Application platform-bootstrap not found yet, waiting..."
    else
      log_info "Sync status: $status (waiting...)"
    fi
    
    sleep 5
  done
  
  if [[ ${SECONDS} -ge ${end} ]]; then
    log_error "Timeout waiting for sync"
    return 1
  fi
  
  # List all applications
  log_info "Discovered applications:"
  kubectl get applications -n "${ARGO_NS}"
  
  log_success "All applications discovered"
}

show_status() {
  log_info "Platform status:"
  echo ""
  
  # ArgoCD Applications
  echo "=== ArgoCD Applications ==="
  kubectl get applications -n "${ARGO_NS}" -o wide 2>/dev/null || \
    log_warning "No applications found yet"
  echo ""
  
  # ApplicationSets
  echo "=== ApplicationSets ==="
  kubectl get applicationsets -n "${ARGO_NS}" 2>/dev/null || \
    log_warning "No applicationsets found yet"
  echo ""
  
  # ArgoCD access
  echo "=== ArgoCD Access ==="
  echo "To access ArgoCD UI:"
  echo "  kubectl -n ${ARGO_NS} port-forward svc/argocd-server 8080:80"
  echo "  Open: http://localhost:8080"
  echo ""
  
  if command -v argocd >/dev/null 2>&1; then
    echo "To use ArgoCD CLI:"
    echo "  argocd login localhost:8080 --username admin"
    echo "  argocd app list"
  fi
}

# =============================================================================
# Main Function
# =============================================================================

main() {
  local wait_for_apps=0
  local timeout=300
  
  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case $1 in
      -h|--help)
        usage
        ;;
      -n|--namespace)
        ARGO_NS="$2"
        shift 2
        ;;
      -d|--dry-run)
        DRY_RUN=1
        shift
        ;;
      -v|--verbose)
        VERBOSE=1
        set -x
        shift
        ;;
      --wait)
        wait_for_apps=1
        shift
        ;;
      --timeout)
        timeout="$2"
        shift 2
        ;;
      *)
        log_error "Unknown option: $1"
        usage
        ;;
    esac
  done
  
  echo ""
  echo "╔═══════════════════════════════════════════════════════════╗"
  echo "║         Fawkes Platform Bootstrap (App-of-Apps)          ║"
  echo "╚═══════════════════════════════════════════════════════════╝"
  echo ""
  
  # Run bootstrap steps
  check_prerequisites
  validate_manifests
  apply_bootstrap
  
  if [[ $DRY_RUN -eq 0 ]]; then
    if [[ $wait_for_apps -eq 1 ]]; then
      wait_for_sync "$timeout"
    fi
    
    show_status
    
    echo ""
    log_success "Bootstrap complete!"
    echo ""
    echo "Next steps:"
    echo "  1. Monitor application sync: argocd app list"
    echo "  2. Watch application status: kubectl get applications -n ${ARGO_NS} -w"
    echo "  3. Access ArgoCD UI: kubectl -n ${ARGO_NS} port-forward svc/argocd-server 8080:80"
    echo ""
  else
    log_info "[DRY-RUN] No changes applied"
  fi
}

# =============================================================================
# Script Entry Point
# =============================================================================

main "$@"
