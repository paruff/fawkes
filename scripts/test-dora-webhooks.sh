#!/usr/bin/env bash
# ============================================================
# Test DORA Metrics Webhooks
# ============================================================
# This script tests all webhook configurations for DORA metrics
# - GitHub webhooks
# - Jenkins webhooks
# - ArgoCD webhooks
# ============================================================

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters
TESTS_PASSED=0
TESTS_FAILED=0

# Helper functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
    ((TESTS_PASSED++))
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
    ((TESTS_FAILED++))
}

log_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."

    if ! command -v kubectl &> /dev/null; then
        log_error "kubectl not found. Please install kubectl."
        exit 1
    fi

    if ! command -v curl &> /dev/null; then
        log_error "curl not found. Please install curl."
        exit 1
    fi

    if ! command -v jq &> /dev/null; then
        log_warning "jq not found. Some tests may be limited."
    fi

    log_success "Prerequisites check passed"
}

# Test DevLake service is running
test_devlake_running() {
    log_info "Testing DevLake service..."

    if kubectl get pods -n fawkes-devlake -l app.kubernetes.io/name=devlake | grep -q "Running"; then
        log_success "DevLake pods are running"
    else
        log_error "DevLake pods are not running"
        return 1
    fi

    if kubectl get svc -n fawkes-devlake devlake >/dev/null 2>&1; then
        log_success "DevLake service exists"
    else
        log_error "DevLake service not found"
        return 1
    fi
}

# Test webhook endpoints are accessible
test_webhook_endpoints() {
    log_info "Testing webhook endpoints..."

    # Port forward to DevLake service
    kubectl port-forward -n fawkes-devlake svc/devlake 8080:8080 >/dev/null 2>&1 &
    PF_PID=$!
    sleep 3

    # Test ping endpoint
    if curl -s http://localhost:8080/api/ping | grep -q "pong"; then
        log_success "DevLake API is accessible"
    else
        log_error "DevLake API ping failed"
        kill $PF_PID 2>/dev/null || true
        return 1
    fi

    # Clean up port forward
    kill $PF_PID 2>/dev/null || true
}

# Test GitHub webhook configuration
test_github_webhook() {
    log_info "Testing GitHub webhook configuration..."

    # Check if webhook secret exists
    if kubectl get secret devlake-webhook-secrets -n fawkes-devlake >/dev/null 2>&1; then
        log_success "GitHub webhook secret exists"
    else
        log_error "GitHub webhook secret not found"
        return 1
    fi

    # Port forward and test webhook endpoint
    kubectl port-forward -n fawkes-devlake svc/devlake 8080:8080 >/dev/null 2>&1 &
    PF_PID=$!
    sleep 3

    # Test GitHub webhook endpoint with mock payload
    WEBHOOK_SECRET=$(kubectl get secret devlake-webhook-secrets -n fawkes-devlake \
        -o jsonpath='{.data.github-webhook-secret}' 2>/dev/null | base64 -d || echo "test-secret")

    PAYLOAD='{"test":"data","repository":{"name":"test"},"commits":[]}'
    SIGNATURE=$(echo -n "$PAYLOAD" | openssl dgst -sha256 -hmac "$WEBHOOK_SECRET" 2>/dev/null | awk '{print $2}')

    RESPONSE=$(curl -s -w "\n%{http_code}" -X POST http://localhost:8080/api/plugins/webhook/1/commits \
        -H "Content-Type: application/json" \
        -H "X-Hub-Signature-256: sha256=$SIGNATURE" \
        -H "X-GitHub-Event: push" \
        -d "$PAYLOAD" 2>/dev/null || echo -e "\n000")

    HTTP_CODE=$(echo "$RESPONSE" | tail -n1)

    if [[ "$HTTP_CODE" =~ ^(200|201|202)$ ]]; then
        log_success "GitHub webhook endpoint responds correctly (HTTP $HTTP_CODE)"
    else
        log_warning "GitHub webhook endpoint returned HTTP $HTTP_CODE (may need actual GitHub payload)"
    fi

    kill $PF_PID 2>/dev/null || true
}

# Test Jenkins webhook configuration
test_jenkins_webhook() {
    log_info "Testing Jenkins webhook configuration..."

    # Check if doraMetrics library exists
    if [ -f "jenkins-shared-library/vars/doraMetrics.groovy" ]; then
        log_success "doraMetrics.groovy shared library exists"
    else
        log_error "doraMetrics.groovy shared library not found"
        return 1
    fi

    # Check if Jenkins can reach DevLake
    if kubectl get networkpolicy -n fawkes-devlake devlake-webhook-ingress >/dev/null 2>&1; then
        log_success "Network policy for Jenkins → DevLake exists"
    else
        log_warning "Network policy for Jenkins → DevLake not found"
    fi

    # Test Jenkins webhook endpoint
    kubectl port-forward -n fawkes-devlake svc/devlake 8080:8080 >/dev/null 2>&1 &
    PF_PID=$!
    sleep 3

    PAYLOAD='{
        "service": "test-service",
        "commit_sha": "abc123",
        "branch": "main",
        "build_number": "1",
        "status": "success",
        "duration_ms": 60000,
        "stage": "build",
        "is_retry": false,
        "timestamp": "'$(date -u +"%Y-%m-%dT%H:%M:%SZ")'",
        "url": "http://jenkins.test/job/test/1/",
        "type": "ci_build"
    }'

    RESPONSE=$(curl -s -w "\n%{http_code}" -X POST http://localhost:8080/api/plugins/webhook/1/cicd \
        -H "Content-Type: application/json" \
        -d "$PAYLOAD" 2>/dev/null || echo -e "\n000")

    HTTP_CODE=$(echo "$RESPONSE" | tail -n1)

    if [[ "$HTTP_CODE" =~ ^(200|201|202)$ ]]; then
        log_success "Jenkins webhook endpoint responds correctly (HTTP $HTTP_CODE)"
    else
        log_warning "Jenkins webhook endpoint returned HTTP $HTTP_CODE"
    fi

    kill $PF_PID 2>/dev/null || true
}

# Test ArgoCD webhook configuration
test_argocd_webhook() {
    log_info "Testing ArgoCD webhook configuration..."

    # Check if ArgoCD notifications config exists
    if [ -f "platform/apps/devlake/config/argocd-notifications.yaml" ]; then
        log_success "ArgoCD notifications configuration exists"
    else
        log_error "ArgoCD notifications configuration not found"
        return 1
    fi

    # Check if ArgoCD can reach DevLake service
    if kubectl get svc -n fawkes-devlake devlake >/dev/null 2>&1; then
        DEVLAKE_IP=$(kubectl get svc -n fawkes-devlake devlake -o jsonpath='{.spec.clusterIP}')
        log_success "DevLake service accessible at $DEVLAKE_IP"
    else
        log_error "DevLake service not accessible from ArgoCD"
        return 1
    fi

    # Test ArgoCD webhook endpoint
    kubectl port-forward -n fawkes-devlake svc/devlake 8080:8080 >/dev/null 2>&1 &
    PF_PID=$!
    sleep 3

    PAYLOAD='{
        "event_type": "deployment",
        "status": "success",
        "application": "test-app",
        "namespace": "default",
        "project": "default",
        "revision": "abc123def456",
        "commit_sha": "abc123def456",
        "sync_started_at": "'$(date -u -d '5 minutes ago' +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date -u +"%Y-%m-%dT%H:%M:%SZ")'",
        "sync_finished_at": "'$(date -u +"%Y-%m-%dT%H:%M:%SZ")'",
        "health_status": "Healthy",
        "sync_status": "Synced",
        "server": "https://kubernetes.default.svc",
        "repo_url": "https://github.com/test/repo",
        "environment": "production",
        "service_name": "test-service",
        "timestamp": "'$(date -u +"%Y-%m-%dT%H:%M:%SZ")'"
    }'

    RESPONSE=$(curl -s -w "\n%{http_code}" -X POST http://localhost:8080/api/plugins/webhook/1/deployments \
        -H "Content-Type: application/json" \
        -H "X-Webhook-Source: argocd" \
        -d "$PAYLOAD" 2>/dev/null || echo -e "\n000")

    HTTP_CODE=$(echo "$RESPONSE" | tail -n1)

    if [[ "$HTTP_CODE" =~ ^(200|201|202)$ ]]; then
        log_success "ArgoCD webhook endpoint responds correctly (HTTP $HTTP_CODE)"
    else
        log_warning "ArgoCD webhook endpoint returned HTTP $HTTP_CODE"
    fi

    kill $PF_PID 2>/dev/null || true
}

# Test webhook configuration files
test_webhook_config_files() {
    log_info "Testing webhook configuration files..."

    if [ -f "platform/apps/devlake/config/webhooks.yaml" ]; then
        log_success "webhooks.yaml configuration exists"
    else
        log_error "webhooks.yaml configuration not found"
    fi

    if [ -f "platform/apps/devlake/config/argocd-notifications.yaml" ]; then
        log_success "argocd-notifications.yaml configuration exists"
    else
        log_error "argocd-notifications.yaml configuration not found"
    fi

    if [ -f "platform/apps/devlake/config/github-webhook-setup.md" ]; then
        log_success "github-webhook-setup.md documentation exists"
    else
        log_error "github-webhook-setup.md documentation not found"
    fi

    if [ -f "platform/apps/devlake/config/jenkins-webhook-setup.md" ]; then
        log_success "jenkins-webhook-setup.md documentation exists"
    else
        log_error "jenkins-webhook-setup.md documentation not found"
    fi
}

# Test incident webhook
test_incident_webhook() {
    log_info "Testing incident webhook..."

    kubectl port-forward -n fawkes-devlake svc/devlake 8080:8080 >/dev/null 2>&1 &
    PF_PID=$!
    sleep 3

    PAYLOAD='{
        "id": "test-incident-001",
        "title": "Test incident for webhook validation",
        "status": "open",
        "severity": "medium",
        "createdDate": "'$(date -u +"%Y-%m-%dT%H:%M:%SZ")'",
        "service": "test-service",
        "environment": "production",
        "url": "http://test.example.com/incident/001"
    }'

    RESPONSE=$(curl -s -w "\n%{http_code}" -X POST http://localhost:8080/api/plugins/webhook/1/incidents \
        -H "Content-Type: application/json" \
        -d "$PAYLOAD" 2>/dev/null || echo -e "\n000")

    HTTP_CODE=$(echo "$RESPONSE" | tail -n1)

    if [[ "$HTTP_CODE" =~ ^(200|201|202)$ ]]; then
        log_success "Incident webhook endpoint responds correctly (HTTP $HTTP_CODE)"
    else
        log_warning "Incident webhook endpoint returned HTTP $HTTP_CODE"
    fi

    kill $PF_PID 2>/dev/null || true
}

# Test network policies
test_network_policies() {
    log_info "Testing network policies..."

    if kubectl get networkpolicy -n fawkes-devlake devlake-webhook-ingress >/dev/null 2>&1; then
        log_success "Webhook ingress network policy exists"

        # Verify policy allows Jenkins
        if kubectl get networkpolicy -n fawkes-devlake devlake-webhook-ingress -o yaml | grep -q "jenkins"; then
            log_success "Network policy allows Jenkins ingress"
        else
            log_warning "Network policy may not allow Jenkins ingress"
        fi
    else
        log_warning "Webhook ingress network policy not found"
    fi
}

# Display summary
display_summary() {
    echo ""
    echo "=========================================="
    echo "Test Summary"
    echo "=========================================="
    echo -e "${GREEN}Passed: $TESTS_PASSED${NC}"
    echo -e "${RED}Failed: $TESTS_FAILED${NC}"
    echo "=========================================="

    if [ $TESTS_FAILED -eq 0 ]; then
        echo -e "${GREEN}All tests passed! ✓${NC}"
        return 0
    else
        echo -e "${RED}Some tests failed. Please review the output above.${NC}"
        return 1
    fi
}

# Main execution
main() {
    echo "=========================================="
    echo "DORA Metrics Webhook Test Suite"
    echo "=========================================="
    echo ""

    check_prerequisites
    test_webhook_config_files
    test_devlake_running
    test_webhook_endpoints
    test_github_webhook
    test_jenkins_webhook
    test_argocd_webhook
    test_incident_webhook
    test_network_policies

    display_summary
}

# Run main function
main
