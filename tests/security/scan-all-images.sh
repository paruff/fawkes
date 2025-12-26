#!/bin/bash
# =============================================================================
# Script: scan-all-images.sh
# Purpose: Scan all container images in the cluster for vulnerabilities using Trivy
# Usage: ./tests/security/scan-all-images.sh [NAMESPACE]
# =============================================================================

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
NAMESPACE="${1:-fawkes}"
SEVERITY="HIGH,CRITICAL"
REPORT_DIR="reports/trivy-scans"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)

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

# Track results
TOTAL_IMAGES=0
SCANNED_IMAGES=0
VULNERABLE_IMAGES=0
FAILED_SCANS=0

echo ""
log_info "=============================================="
log_info "Trivy Security Scan - All Images"
log_info "=============================================="
log_info "Namespace: $NAMESPACE"
log_info "Severity Filter: $SEVERITY"
log_info "Report Directory: $REPORT_DIR"
echo ""

# Create report directory
mkdir -p "$REPORT_DIR"

# Check prerequisites
if ! command -v kubectl &> /dev/null; then
  log_error "kubectl not found. Please install kubectl."
  exit 1
fi

if ! command -v trivy &> /dev/null; then
  log_error "trivy not found. Please install Trivy: https://aquasecurity.github.io/trivy/"
  log_info "Alternative: Use 'docker run aquasec/trivy:latest' to run Trivy in container"
  exit 1
fi

# Check cluster access
if ! kubectl cluster-info &> /dev/null; then
  log_error "Cannot access Kubernetes cluster"
  exit 1
fi

log_info "Discovering container images in namespace '$NAMESPACE'..."
echo ""

# Get all unique images from pods
IMAGES=$(kubectl get pods -n "$NAMESPACE" -o jsonpath='{.items[*].spec.containers[*].image}' 2> /dev/null | tr ' ' '\n' | sort -u)

if [ -z "$IMAGES" ]; then
  log_warning "No images found in namespace '$NAMESPACE'"
  exit 0
fi

# Count images
TOTAL_IMAGES=$(echo "$IMAGES" | wc -l)
log_info "Found $TOTAL_IMAGES unique image(s) to scan"
echo ""

# Scan each image
for IMAGE in $IMAGES; do
  ((SCANNED_IMAGES++))

  log_info "[$SCANNED_IMAGES/$TOTAL_IMAGES] Scanning: $IMAGE"

  # Create safe filename
  SAFE_NAME=$(echo "$IMAGE" | sed 's/[^a-zA-Z0-9._-]/_/g')
  REPORT_FILE="$REPORT_DIR/trivy-scan-${SAFE_NAME}-${TIMESTAMP}.txt"
  JSON_REPORT_FILE="$REPORT_DIR/trivy-scan-${SAFE_NAME}-${TIMESTAMP}.json"

  # Run Trivy scan
  if trivy image \
    --severity "$SEVERITY" \
    --timeout 5m \
    --output "$REPORT_FILE" \
    "$IMAGE" 2>&1 | tee /tmp/trivy-output.log; then

    # Also generate JSON report
    trivy image \
      --severity "$SEVERITY" \
      --format json \
      --timeout 5m \
      --output "$JSON_REPORT_FILE" \
      "$IMAGE" &> /dev/null || true

    # Check if vulnerabilities were found
    if grep -q "Total: 0" "$REPORT_FILE" 2> /dev/null \
      || ! grep -q "Total:" "$REPORT_FILE" 2> /dev/null; then
      log_success "No $SEVERITY vulnerabilities found"
    else
      log_warning "Vulnerabilities found - see $REPORT_FILE"
      ((VULNERABLE_IMAGES++))
    fi
  else
    log_error "Scan failed for $IMAGE"
    ((FAILED_SCANS++))
  fi

  echo ""
done

# Generate summary report
SUMMARY_FILE="$REPORT_DIR/scan-summary-${TIMESTAMP}.txt"
cat > "$SUMMARY_FILE" << EOF
==============================================
Trivy Security Scan Summary
==============================================
Timestamp: $(date)
Namespace: $NAMESPACE
Severity Filter: $SEVERITY

Results:
  Total Images:        $TOTAL_IMAGES
  Successfully Scanned: $SCANNED_IMAGES
  With Vulnerabilities: $VULNERABLE_IMAGES
  Failed Scans:        $FAILED_SCANS

Individual Reports:
  Location: $REPORT_DIR/trivy-scan-*-${TIMESTAMP}.txt
  JSON Reports: $REPORT_DIR/trivy-scan-*-${TIMESTAMP}.json

==============================================
EOF

# Display summary
echo ""
log_info "=============================================="
log_info "Scan Summary"
log_info "=============================================="
log_info "Total Images:        $TOTAL_IMAGES"
log_info "Successfully Scanned: $SCANNED_IMAGES"
log_success "Clean Images:        $((SCANNED_IMAGES - VULNERABLE_IMAGES))"
log_warning "Vulnerable Images:   $VULNERABLE_IMAGES"
log_error "Failed Scans:        $FAILED_SCANS"
echo ""
log_info "Summary report: $SUMMARY_FILE"
log_info "Individual reports: $REPORT_DIR/trivy-scan-*-${TIMESTAMP}.txt"
echo ""

# Exit with appropriate code
if [ $VULNERABLE_IMAGES -gt 0 ]; then
  log_error "Found images with $SEVERITY vulnerabilities!"
  exit 1
elif [ $FAILED_SCANS -gt 0 ]; then
  log_error "Some scans failed!"
  exit 1
else
  log_success "All images are clean!"
  exit 0
fi
