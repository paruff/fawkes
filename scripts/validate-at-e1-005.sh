#!/bin/bash
# =============================================================================
# Script: validate-at-e1-005.sh
# Purpose: Validate AT-E1-005 acceptance criteria for DevSecOps security scanning
# Usage: ./scripts/validate-at-e1-005.sh [--namespace NAMESPACE]
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
VERBOSE=false
REPORT_FILE="reports/at-e1-005-validation-$(date +%Y%m%d-%H%M%S).json"
REPORT_DIR="reports"
SONARQUBE_URL="http://sonarqube.127.0.0.1.nip.io"
JENKINS_URL="http://jenkins.127.0.0.1.nip.io"

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

Validate AT-E1-005 acceptance criteria for DevSecOps security scanning.

OPTIONS:
    -n, --namespace         Namespace (default: $NAMESPACE)
    -v, --verbose           Verbose output
    -r, --report            Report file path (default: $REPORT_FILE)
    -s, --sonarqube-url     SonarQube URL (default: $SONARQUBE_URL)
    -j, --jenkins-url       Jenkins URL (default: $JENKINS_URL)
    -h, --help              Show this help message

ENVIRONMENT VARIABLES:
    NAMESPACE               Override default namespace
    SONARQUBE_URL           Override SonarQube URL
    JENKINS_URL             Override Jenkins URL

ACCEPTANCE CRITERIA:
    - SonarQube deployed and integrated with Jenkins
    - Trivy scanning all container images
    - git-secrets or TruffleHog in pipelines
    - Quality gates enforced (fail on high/critical)
    - Security scan results in Backstage
    - No critical/high vulnerabilities in platform components
    - SBOM generation for all images (Syft)
    - Security policy-as-code (OPA/Kyverno) deployed

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
  "test_id": "AT-E1-005",
  "test_name": "DevSecOps Security Scanning Validation",
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
    
    # Check kubectl
    if ! command -v kubectl &> /dev/null; then
        record_test "Prerequisites" "FAIL" "kubectl not found"
        return 1
    fi
    
    # Check jq (optional but helpful)
    if ! command -v jq &> /dev/null; then
        log_warning "jq not found - some tests may be limited"
    fi
    
    record_test "Prerequisites" "PASS" "kubectl available"
    
    # Check cluster access
    if ! kubectl cluster-info &> /dev/null; then
        record_test "Cluster Access" "FAIL" "Cannot access Kubernetes cluster"
        return 1
    fi
    record_test "Cluster Access" "PASS" "Cluster accessible"
}

validate_namespace() {
    log_info "Checking namespace '$NAMESPACE'..."
    
    if kubectl get namespace "$NAMESPACE" &> /dev/null; then
        local status=$(kubectl get namespace "$NAMESPACE" -o jsonpath='{.status.phase}')
        if [ "$status" = "Active" ]; then
            record_test "Namespace" "PASS" "Namespace $NAMESPACE is Active"
        else
            record_test "Namespace" "FAIL" "Namespace $NAMESPACE status: $status"
            return 1
        fi
    else
        record_test "Namespace" "FAIL" "Namespace $NAMESPACE does not exist"
        return 1
    fi
}

validate_sonarqube_deployment() {
    log_info "Checking SonarQube deployment..."
    
    # Check SonarQube pods
    if kubectl get pods -n "$NAMESPACE" -l app=sonarqube -o json 2>/dev/null | grep -q "Running"; then
        local pod_count=$(kubectl get pods -n "$NAMESPACE" -l app=sonarqube -o json 2>/dev/null | jq '.items | length' || echo "0")
        local running=$(kubectl get pods -n "$NAMESPACE" -l app=sonarqube -o json 2>/dev/null | jq '[.items[] | select(.status.phase=="Running")] | length' || echo "0")
        
        if [ "$running" -gt 0 ]; then
            record_test "SonarQube Deployment" "PASS" "SonarQube pod(s) running ($running/$pod_count)"
        else
            record_test "SonarQube Deployment" "FAIL" "SonarQube pods not running"
            return 1
        fi
    else
        record_test "SonarQube Deployment" "FAIL" "SonarQube pods not found"
        return 1
    fi
    
    # Check SonarQube service
    if kubectl get service -n "$NAMESPACE" -l app=sonarqube &> /dev/null; then
        record_test "SonarQube Service" "PASS" "SonarQube service exists"
    else
        record_test "SonarQube Service" "FAIL" "SonarQube service not found"
    fi
}

validate_sonarqube_database() {
    log_info "Checking SonarQube PostgreSQL database..."
    
    # Check for CloudNativePG cluster
    if kubectl get cluster db-sonarqube-dev -n "$NAMESPACE" &> /dev/null 2>&1; then
        local instances=$(kubectl get cluster db-sonarqube-dev -n "$NAMESPACE" -o jsonpath='{.spec.instances}' 2>/dev/null || echo "0")
        record_test "SonarQube Database Cluster" "PASS" "SonarQube PostgreSQL cluster exists with $instances instances"
    else
        record_test "SonarQube Database" "WARN" "SonarQube database configuration not found (may use embedded DB)"
    fi
    
    # Check for database credentials secret
    if kubectl get secret db-sonarqube-credentials -n "$NAMESPACE" &> /dev/null 2>&1 || \
       kubectl get secret sonarqube-postgresql -n "$NAMESPACE" &> /dev/null 2>&1; then
        record_test "Database Credentials" "PASS" "SonarQube database credentials secret exists"
    else
        record_test "Database Credentials" "WARN" "SonarQube database credentials secret not found"
    fi
}

validate_sonarqube_accessibility() {
    log_info "Checking SonarQube accessibility..."
    
    # Check ingress
    if kubectl get ingress -n "$NAMESPACE" -o json 2>/dev/null | jq -e '.items[] | select(.metadata.name | contains("sonarqube"))' &> /dev/null; then
        local host=$(kubectl get ingress -n "$NAMESPACE" -o json 2>/dev/null | jq -r '.items[] | select(.metadata.name | contains("sonarqube")) | .spec.rules[0].host' | head -1)
        record_test "SonarQube Ingress" "PASS" "SonarQube ingress configured (host: $host)"
    else
        record_test "SonarQube Ingress" "WARN" "SonarQube ingress not found"
    fi
    
    # Try to access SonarQube API (may fail if ingress not reachable from test environment)
    if command -v curl &> /dev/null; then
        if curl -f -s --connect-timeout 5 "$SONARQUBE_URL/api/system/health" &> /dev/null; then
            record_test "SonarQube API" "PASS" "SonarQube API accessible at $SONARQUBE_URL"
        else
            record_test "SonarQube API" "WARN" "SonarQube API not accessible at $SONARQUBE_URL (may require port-forward)"
        fi
    fi
}

validate_trivy_integration() {
    log_info "Checking Trivy integration..."
    
    # Check if Trivy is available in Harbor
    if kubectl get pods -n "$NAMESPACE" -l component=trivy -o json 2>/dev/null | jq -e '.items[] | select(.status.phase=="Running")' &> /dev/null; then
        record_test "Trivy Scanner (Harbor)" "PASS" "Trivy scanner pod running in Harbor"
    elif kubectl get pods -n "$NAMESPACE" -l app.kubernetes.io/component=trivy -o json 2>/dev/null | jq -e '.items[] | select(.status.phase=="Running")' &> /dev/null; then
        record_test "Trivy Scanner (Harbor)" "PASS" "Trivy scanner pod running in Harbor"
    else
        record_test "Trivy Scanner (Harbor)" "WARN" "Trivy scanner pod not found in Harbor (may be in different namespace)"
    fi
    
    # Check Trivy integration in Jenkins shared library
    if [ -f "jenkins-shared-library/vars/securityScan.groovy" ] && \
       grep -q "trivy image" jenkins-shared-library/vars/securityScan.groovy; then
        record_test "Trivy Integration (Jenkins)" "PASS" "Trivy integrated in Jenkins shared library"
    else
        record_test "Trivy Integration (Jenkins)" "FAIL" "Trivy not integrated in Jenkins shared library"
    fi
}

validate_secrets_scanning() {
    log_info "Checking secrets scanning integration..."
    
    # Check for Gitleaks integration
    if [ -f "jenkins-shared-library/vars/securityScan.groovy" ] && \
       grep -q "gitleaks detect" jenkins-shared-library/vars/securityScan.groovy; then
        record_test "Secrets Scanning (Gitleaks)" "PASS" "Gitleaks integrated in Jenkins shared library"
    elif [ -f ".gitleaks.toml" ] || [ -f ".pre-commit-config.yaml" ]; then
        record_test "Secrets Scanning (Gitleaks)" "PASS" "Gitleaks configuration found"
    else
        record_test "Secrets Scanning (Gitleaks)" "WARN" "Gitleaks configuration not found"
    fi
    
    # Check for git-secrets or TruffleHog
    if [ -f "jenkins-shared-library/vars/goldenPathPipeline.groovy" ] && \
       grep -qi "gitleaks\|trufflehog\|git-secrets" jenkins-shared-library/vars/goldenPathPipeline.groovy; then
        record_test "Secrets Scanning (Pipeline)" "PASS" "Secrets scanning integrated in pipeline"
    else
        record_test "Secrets Scanning (Pipeline)" "WARN" "Secrets scanning not found in pipeline"
    fi
}

validate_quality_gates() {
    log_info "Checking security quality gates configuration..."
    
    # Check SonarQube quality gate in shared library
    if [ -f "jenkins-shared-library/vars/securityScan.groovy" ] && \
       grep -q "waitForQualityGate" jenkins-shared-library/vars/securityScan.groovy; then
        record_test "SonarQube Quality Gate" "PASS" "SonarQube quality gate check implemented"
    else
        record_test "SonarQube Quality Gate" "WARN" "SonarQube quality gate check not found"
    fi
    
    # Check Trivy severity threshold
    if [ -f "jenkins-shared-library/vars/goldenPathPipeline.groovy" ] && \
       grep -q "trivySeverity.*HIGH,CRITICAL" jenkins-shared-library/vars/goldenPathPipeline.groovy; then
        record_test "Trivy Quality Gate" "PASS" "Trivy quality gate set to HIGH,CRITICAL"
    else
        record_test "Trivy Quality Gate" "WARN" "Trivy quality gate configuration not found"
    fi
    
    # Check quality gate enforcement
    if [ -f "jenkins-shared-library/vars/goldenPathPipeline.groovy" ] && \
       grep -q "failOnVulnerabilities\|trivyExitCode" jenkins-shared-library/vars/goldenPathPipeline.groovy; then
        record_test "Quality Gate Enforcement" "PASS" "Quality gates configured to fail on vulnerabilities"
    else
        record_test "Quality Gate Enforcement" "WARN" "Quality gate enforcement configuration not clear"
    fi
}

validate_jenkins_integration() {
    log_info "Checking Jenkins security scanning integration..."
    
    # Check Jenkins is deployed
    if kubectl get pods -n "$NAMESPACE" -l app.kubernetes.io/name=jenkins -o json 2>/dev/null | grep -q "Running"; then
        record_test "Jenkins Deployment" "PASS" "Jenkins pod(s) running"
    else
        record_test "Jenkins Deployment" "WARN" "Jenkins pods not found or not running"
    fi
    
    # Check shared library exists
    if [ -d "jenkins-shared-library/vars" ]; then
        record_test "Jenkins Shared Library" "PASS" "Jenkins shared library directory exists"
    else
        record_test "Jenkins Shared Library" "FAIL" "Jenkins shared library not found"
    fi
    
    # Check security scan function
    if [ -f "jenkins-shared-library/vars/securityScan.groovy" ]; then
        record_test "Security Scan Function" "PASS" "securityScan.groovy exists"
    else
        record_test "Security Scan Function" "FAIL" "securityScan.groovy not found"
    fi
}

validate_security_documentation() {
    log_info "Checking security scanning documentation..."
    
    # Check for security documentation
    if [ -f "docs/how-to/security/quality-gates-configuration.md" ]; then
        record_test "Quality Gates Documentation" "PASS" "Quality gates configuration documentation exists"
    else
        record_test "Quality Gates Documentation" "WARN" "Quality gates configuration documentation not found"
    fi
    
    # Check Trivy documentation
    if [ -f "platform/apps/trivy/README.md" ]; then
        record_test "Trivy Documentation" "PASS" "Trivy documentation exists"
    else
        record_test "Trivy Documentation" "WARN" "Trivy documentation not found"
    fi
    
    # Check SonarQube documentation
    if [ -f "platform/apps/sonarqube/README.md" ] || \
       [ -f "platform/apps/sonarqube/sonarqube-notes.md" ]; then
        record_test "SonarQube Documentation" "PASS" "SonarQube documentation exists"
    else
        record_test "SonarQube Documentation" "WARN" "SonarQube documentation not found"
    fi
}

validate_sbom_capability() {
    log_info "Checking SBOM generation capability..."
    
    # Check for Syft or similar SBOM tool integration
    if [ -f "jenkins-shared-library/vars/securityScan.groovy" ] && \
       grep -qi "syft\|sbom\|cyclonedx" jenkins-shared-library/vars/securityScan.groovy; then
        record_test "SBOM Generation" "PASS" "SBOM generation integrated in pipeline"
    elif grep -qi "trivy.*sbom\|trivy.*spdx\|trivy.*cyclonedx" jenkins-shared-library/vars/securityScan.groovy 2>/dev/null; then
        record_test "SBOM Generation" "PASS" "SBOM generation via Trivy available"
    else
        record_test "SBOM Generation" "WARN" "SBOM generation capability not found (can use Trivy)"
    fi
}

validate_security_policy() {
    log_info "Checking security policy-as-code deployment..."
    
    # Check for OPA/Gatekeeper
    if kubectl get pods -n gatekeeper-system &> /dev/null 2>&1 || \
       kubectl get constrainttemplates &> /dev/null 2>&1; then
        record_test "Policy-as-Code (OPA)" "PASS" "OPA Gatekeeper deployed"
    elif kubectl get pods -n "$NAMESPACE" -l app=opa &> /dev/null 2>&1; then
        record_test "Policy-as-Code (OPA)" "PASS" "OPA deployed"
    else
        # Check for Kyverno
        if kubectl get pods -n kyverno &> /dev/null 2>&1 || \
           kubectl get clusterpolicies &> /dev/null 2>&1; then
            record_test "Policy-as-Code (Kyverno)" "PASS" "Kyverno deployed"
        else
            record_test "Policy-as-Code" "WARN" "Neither OPA nor Kyverno found (optional for AT-E1-005)"
        fi
    fi
}

validate_bdd_tests() {
    log_info "Checking BDD test coverage for security scanning..."
    
    # Check for security-related BDD tests
    if [ -f "tests/bdd/features/security-quality-gates.feature" ]; then
        record_test "BDD Tests (Quality Gates)" "PASS" "Security quality gates BDD tests exist"
    else
        record_test "BDD Tests (Quality Gates)" "WARN" "Security quality gates BDD tests not found"
    fi
    
    if [ -f "tests/bdd/features/secrets-scanning.feature" ]; then
        record_test "BDD Tests (Secrets)" "PASS" "Secrets scanning BDD tests exist"
    else
        record_test "BDD Tests (Secrets)" "WARN" "Secrets scanning BDD tests not found"
    fi
}

# =============================================================================
# Main Execution
# =============================================================================

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -n|--namespace)
                NAMESPACE="$2"
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
            -s|--sonarqube-url)
                SONARQUBE_URL="$2"
                shift 2
                ;;
            -j|--jenkins-url)
                JENKINS_URL="$2"
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
}

main() {
    parse_args "$@"
    
    echo ""
    log_info "=============================================="
    log_info "AT-E1-005: DevSecOps Security Scanning Validation"
    log_info "=============================================="
    log_info "Namespace: $NAMESPACE"
    log_info "SonarQube URL: $SONARQUBE_URL"
    log_info "Jenkins URL: $JENKINS_URL"
    echo ""
    
    # Run all validations
    validate_prerequisites || true
    validate_namespace || true
    validate_sonarqube_deployment || true
    validate_sonarqube_database || true
    validate_sonarqube_accessibility || true
    validate_trivy_integration || true
    validate_secrets_scanning || true
    validate_quality_gates || true
    validate_jenkins_integration || true
    validate_security_documentation || true
    validate_sbom_capability || true
    validate_security_policy || true
    validate_bdd_tests || true
    
    echo ""
    log_info "=============================================="
    log_info "Validation Summary"
    log_info "=============================================="
    log_info "Total Tests: $TOTAL_TESTS"
    log_success "Passed: $PASSED_TESTS"
    log_error "Failed: $FAILED_TESTS"
    echo ""
    
    # Generate report
    generate_report
    
    # Exit with appropriate code
    if [ "$FAILED_TESTS" -eq 0 ]; then
        log_success "AT-E1-005 validation PASSED!"
        exit 0
    else
        log_error "AT-E1-005 validation FAILED!"
        exit 1
    fi
}

main "$@"
