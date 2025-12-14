#!/bin/bash
# =============================================================================
# Script: validate-at-e1-004.sh
# Purpose: Validate AT-E1-004 acceptance criteria for Jenkins CI/CD
# Usage: ./scripts/validate-at-e1-004.sh [--namespace NAMESPACE]
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
REPORT_FILE="reports/at-e1-004-validation-$(date +%Y%m%d-%H%M%S).json"
REPORT_DIR="reports"
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

Validate AT-E1-004 acceptance criteria for Jenkins CI/CD.

OPTIONS:
    -n, --namespace         Namespace (default: $NAMESPACE)
    -v, --verbose           Verbose output
    -r, --report            Report file path (default: $REPORT_FILE)
    -u, --url               Jenkins URL (default: $JENKINS_URL)
    -h, --help              Show this help message

ENVIRONMENT VARIABLES:
    NAMESPACE               Override default namespace
    JENKINS_URL             Override Jenkins URL

ACCEPTANCE CRITERIA:
    - Jenkins deployed with Kubernetes plugin
    - Jenkins Configuration as Code (JCasC) working
    - 3 golden path Jenkinsfiles in shared library:
      * Java (Maven/Gradle)
      * Python (pytest)
      * Node.js (npm)
    - Dynamic agent provisioning on K8s pods
    - SonarQube integrated for code scanning
    - Trivy integrated for container scanning
    - Pipeline success rate >95% (synthetic runs)
    - Build time P95 <10 minutes

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
    
    TEST_RESULTS+=("{\"name\":\"$test_name\",\"status\":\"$status\",\"message\":\"$message\"}")
}

generate_report() {
    mkdir -p "$REPORT_DIR"
    
    local status="FAILED"
    if [ "$FAILED_TESTS" -eq 0 ]; then
        status="PASSED"
    fi
    
    cat > "$REPORT_FILE" <<EOF
{
  "test_id": "AT-E1-004",
  "test_name": "Jenkins CI/CD Validation",
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "status": "$status",
  "summary": {
    "total": $TOTAL_TESTS,
    "passed": $PASSED_TESTS,
    "failed": $FAILED_TESTS
  },
  "tests": [
    $(IFS=,; echo "${TEST_RESULTS[*]}")
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

validate_jenkins_deployment() {
    log_info "Checking Jenkins deployment..."
    
    if kubectl get deployment jenkins -n "$NAMESPACE" &> /dev/null; then
        local ready=$(kubectl get deployment jenkins -n "$NAMESPACE" -o jsonpath='{.status.readyReplicas}')
        local desired=$(kubectl get deployment jenkins -n "$NAMESPACE" -o jsonpath='{.spec.replicas}')
        
        if [ "$ready" = "$desired" ] && [ "$ready" -gt 0 ]; then
            record_test "Jenkins Deployment" "PASS" "Jenkins deployment ready ($ready/$desired replicas)"
        else
            record_test "Jenkins Deployment" "FAIL" "Jenkins deployment not ready ($ready/$desired replicas)"
            return 1
        fi
    else
        record_test "Jenkins Deployment" "FAIL" "Jenkins deployment does not exist"
        return 1
    fi
}

validate_jenkins_pods() {
    log_info "Checking Jenkins pods..."
    
    local pod_count=$(kubectl get pods -n "$NAMESPACE" -l app.kubernetes.io/name=jenkins -o json 2>/dev/null | jq '.items | length' || echo "0")
    
    if [ -z "$pod_count" ] || [ "$pod_count" = "null" ]; then
        pod_count=0
    fi
    
    if [ "$pod_count" -eq 0 ]; then
        record_test "Jenkins Pods" "FAIL" "No Jenkins pods found"
        return 1
    fi
    
    local running_count=$(kubectl get pods -n "$NAMESPACE" -l app.kubernetes.io/name=jenkins -o json 2>/dev/null | jq '[.items[] | select(.status.phase=="Running")] | length' || echo "0")
    
    if [ -z "$running_count" ] || [ "$running_count" = "null" ]; then
        running_count=0
    fi
    
    if [ "$running_count" -eq "$pod_count" ]; then
        record_test "Jenkins Pods" "PASS" "All Jenkins pods running ($running_count/$pod_count)"
    else
        record_test "Jenkins Pods" "FAIL" "Not all Jenkins pods running ($running_count/$pod_count)"
        return 1
    fi
}

validate_jenkins_service() {
    log_info "Checking Jenkins service..."
    
    if kubectl get service jenkins -n "$NAMESPACE" &> /dev/null; then
        record_test "Jenkins Service" "PASS" "Jenkins service exists"
    else
        record_test "Jenkins Service" "FAIL" "Jenkins service does not exist"
        return 1
    fi
}

validate_jcasc_configuration() {
    log_info "Checking Jenkins Configuration as Code (JCasC)..."
    
    # Check if JCasC ConfigMap exists
    if kubectl get configmap jenkins-casc-config -n "$NAMESPACE" &> /dev/null; then
        record_test "JCasC ConfigMap" "PASS" "JCasC ConfigMap exists"
    else
        record_test "JCasC ConfigMap" "FAIL" "JCasC ConfigMap not found"
        return 1
    fi
    
    # Check if jcasc.yaml exists in platform/apps/jenkins
    if [ -f "platform/apps/jenkins/jcasc.yaml" ]; then
        record_test "JCasC File" "PASS" "jcasc.yaml file exists in platform/apps/jenkins"
    else
        record_test "JCasC File" "FAIL" "jcasc.yaml file not found"
        return 1
    fi
}

validate_golden_path_jenkinsfiles() {
    log_info "Checking Golden Path Jenkinsfiles in shared library..."
    
    local library_path="jenkins-shared-library"
    local golden_paths=("java" "python" "node")
    local found_count=0
    
    for lang in "${golden_paths[@]}"; do
        # Check for Groovy files in vars/ directory
        if ls ${library_path}/vars/*${lang}* &> /dev/null 2>&1; then
            log_success "Found $lang golden path in vars/"
            found_count=$((found_count + 1))
        elif ls ${library_path}/resources/*${lang}* &> /dev/null 2>&1; then
            log_success "Found $lang golden path in resources/"
            found_count=$((found_count + 1))
        elif ls ${library_path}/examples/*${lang}* &> /dev/null 2>&1; then
            log_success "Found $lang golden path in examples/"
            found_count=$((found_count + 1))
        else
            log_warning "Golden path for $lang not found"
        fi
    done
    
    if [ "$found_count" -eq 3 ]; then
        record_test "Golden Path Jenkinsfiles" "PASS" "All 3 golden path Jenkinsfiles found (Java, Python, Node.js)"
    elif [ "$found_count" -gt 0 ]; then
        record_test "Golden Path Jenkinsfiles" "PARTIAL" "Found $found_count/3 golden path Jenkinsfiles"
    else
        record_test "Golden Path Jenkinsfiles" "FAIL" "No golden path Jenkinsfiles found"
        return 1
    fi
}

validate_kubernetes_plugin() {
    log_info "Checking Kubernetes plugin configuration..."
    
    # Check if Kubernetes cloud is configured in JCasC
    if [ -f "platform/apps/jenkins/jcasc.yaml" ]; then
        if grep -q "kubernetes:" platform/apps/jenkins/jcasc.yaml; then
            record_test "Kubernetes Plugin" "PASS" "Kubernetes cloud configured in JCasC"
        else
            record_test "Kubernetes Plugin" "FAIL" "Kubernetes cloud not configured in JCasC"
            return 1
        fi
    else
        record_test "Kubernetes Plugin" "FAIL" "Cannot verify Kubernetes plugin configuration"
        return 1
    fi
}

validate_agent_templates() {
    log_info "Checking agent templates configuration..."
    
    if [ -f "platform/apps/jenkins/jcasc.yaml" ]; then
        local required_agents=("jnlp-agent" "maven-agent" "python-agent" "node-agent")
        local found_count=0
        
        for agent in "${required_agents[@]}"; do
            if grep -q "$agent" platform/apps/jenkins/jcasc.yaml; then
                found_count=$((found_count + 1))
            fi
        done
        
        if [ "$found_count" -ge 3 ]; then
            record_test "Agent Templates" "PASS" "Found $found_count agent templates configured"
        else
            record_test "Agent Templates" "FAIL" "Only found $found_count agent templates, expected at least 3"
            return 1
        fi
    else
        record_test "Agent Templates" "FAIL" "Cannot verify agent templates"
        return 1
    fi
}

validate_sonarqube_integration() {
    log_info "Checking SonarQube integration..."
    
    if [ -f "platform/apps/jenkins/jcasc.yaml" ]; then
        if grep -q -i "sonarqube\|sonar" platform/apps/jenkins/jcasc.yaml; then
            record_test "SonarQube Integration" "PASS" "SonarQube configuration found in JCasC"
        else
            record_test "SonarQube Integration" "FAIL" "SonarQube not configured in JCasC"
            return 1
        fi
    else
        record_test "SonarQube Integration" "FAIL" "Cannot verify SonarQube integration"
        return 1
    fi
}

validate_trivy_integration() {
    log_info "Checking Trivy integration..."
    
    # Check if Trivy is available in the cluster or referenced in shared library
    if grep -r -q "trivy" jenkins-shared-library/ 2>/dev/null; then
        record_test "Trivy Integration" "PASS" "Trivy integration found in shared library"
    elif kubectl get pods -n "$NAMESPACE" -l app=trivy &> /dev/null; then
        record_test "Trivy Integration" "PASS" "Trivy pods found in cluster"
    else
        record_test "Trivy Integration" "WARN" "Trivy integration not clearly configured (may be in pipeline)"
    fi
}

validate_jenkins_api() {
    log_info "Checking Jenkins API accessibility..."
    
    # Try to access Jenkins API
    if command -v curl &> /dev/null; then
        local response_code=$(curl -s -o /dev/null -w "%{http_code}" "$JENKINS_URL/api/json" 2>/dev/null || echo "000")
        
        # Accept both 200 (success) and 403 (forbidden, but API is responding)
        if [ "$response_code" = "200" ] || [ "$response_code" = "403" ]; then
            record_test "Jenkins API" "PASS" "Jenkins API responding (HTTP $response_code)"
        else
            record_test "Jenkins API" "WARN" "Jenkins API returned HTTP $response_code (may need authentication or ingress not configured)"
        fi
    else
        record_test "Jenkins API" "SKIP" "curl not available to test API"
    fi
}

validate_ingress() {
    log_info "Checking Jenkins ingress..."
    
    if kubectl get ingress -n "$NAMESPACE" -o json | jq -e '.items[] | select(.metadata.name | contains("jenkins"))' &> /dev/null; then
        local host=$(kubectl get ingress -n "$NAMESPACE" -o json | jq -r '.items[] | select(.metadata.name | contains("jenkins")) | .spec.rules[0].host' | head -1)
        record_test "Jenkins Ingress" "PASS" "Jenkins ingress configured (host: $host)"
    else
        record_test "Jenkins Ingress" "WARN" "Jenkins ingress not found (may not be configured yet)"
    fi
}

validate_credentials() {
    log_info "Checking Jenkins credentials secrets..."
    
    if kubectl get secret jenkins-admin -n "$NAMESPACE" &> /dev/null; then
        record_test "Admin Credentials" "PASS" "Jenkins admin secret exists"
    else
        record_test "Admin Credentials" "FAIL" "Jenkins admin secret not found"
        return 1
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
            -u|--url)
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
    log_info "AT-E1-004: Jenkins CI/CD Validation"
    log_info "=============================================="
    log_info "Namespace: $NAMESPACE"
    log_info "Jenkins URL: $JENKINS_URL"
    echo ""
    
    # Run all validations
    validate_prerequisites || true
    validate_namespace || true
    validate_jenkins_deployment || true
    validate_jenkins_pods || true
    validate_jenkins_service || true
    validate_jcasc_configuration || true
    validate_golden_path_jenkinsfiles || true
    validate_kubernetes_plugin || true
    validate_agent_templates || true
    validate_sonarqube_integration || true
    validate_trivy_integration || true
    validate_jenkins_api || true
    validate_ingress || true
    validate_credentials || true
    
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
        log_success "AT-E1-004 validation PASSED!"
        exit 0
    else
        log_error "AT-E1-004 validation FAILED!"
        exit 1
    fi
}

main "$@"
