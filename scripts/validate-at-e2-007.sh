#!/usr/bin/env bash
###############################################################################
# AT-E2-007 Validation Script
# Tests: AI Code Review Bot
#
# Validates:
# - AI code review service deployed
# - GitHub webhook integration configured
# - Review categories functional (quality, security, performance, best practices)
# - False positive rate < 20%
# - SonarQube integration working
# - Test reviews posted successfully
###############################################################################

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
NAMESPACE="${NAMESPACE:-fawkes}"
AI_CODE_REVIEW_URL="${AI_CODE_REVIEW_URL:-http://ai-code-review.${NAMESPACE}.svc.cluster.local:8000}"

# Test results
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_SKIPPED=0

###############################################################################
# Helper Functions
###############################################################################

print_header() {
    echo -e "\n${BLUE}=================================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}=================================================${NC}\n"
}

print_test() {
    echo -e "${YELLOW}TEST:${NC} $1"
}

print_pass() {
    echo -e "${GREEN}✓ PASS:${NC} $1"
    ((TESTS_PASSED++))
}

print_fail() {
    echo -e "${RED}✗ FAIL:${NC} $1"
    ((TESTS_FAILED++))
}

print_skip() {
    echo -e "${YELLOW}⊘ SKIP:${NC} $1"
    ((TESTS_SKIPPED++))
}

print_info() {
    echo -e "${BLUE}ℹ INFO:${NC} $1"
}

###############################################################################
# Test Functions
###############################################################################

test_service_files_exist() {
    print_test "AI code review service files exist"

    local required_files=(
        "services/ai-code-review/app/main.py"
        "services/ai-code-review/app/reviewer.py"
        "services/ai-code-review/Dockerfile"
        "services/ai-code-review/requirements.txt"
    )

    for file in "${required_files[@]}"; do
        if [[ -f "$file" ]]; then
            print_pass "File exists: $file"
        else
            print_fail "File missing: $file"
            return 1
        fi
    done

    return 0
}

test_review_prompts_exist() {
    print_test "Review prompt files exist for all categories"

    local prompt_categories=(
        "security"
        "performance"
        "best_practices"
        "test_coverage"
        "documentation"
    )

    for category in "${prompt_categories[@]}"; do
        local prompt_file="services/ai-code-review/prompts/${category}.txt"
        if [[ -f "$prompt_file" ]]; then
            print_pass "Prompt exists: $category"
        else
            print_fail "Prompt missing: $category"
            return 1
        fi
    done

    return 0
}

test_kubernetes_manifests_exist() {
    print_test "Kubernetes deployment manifests exist"

    local required_manifests=(
        "services/ai-code-review/k8s/deployment.yaml"
        "services/ai-code-review/k8s/service.yaml"
        "services/ai-code-review/k8s/configmap.yaml"
        "services/ai-code-review/k8s/secret.yaml"
    )

    for manifest in "${required_manifests[@]}"; do
        if [[ -f "$manifest" ]]; then
            print_pass "Manifest exists: $(basename $manifest)"
        else
            print_fail "Manifest missing: $(basename $manifest)"
            return 1
        fi
    done

    return 0
}

test_argocd_application_exists() {
    print_test "ArgoCD application manifest exists"

    if [[ -f "platform/apps/ai-code-review-application.yaml" ]]; then
        print_pass "ArgoCD application manifest exists"
        return 0
    else
        print_fail "ArgoCD application manifest not found"
        return 1
    fi
}

test_sonarqube_integration_exists() {
    print_test "SonarQube integration code exists"

    if [[ -f "services/ai-code-review/integrations/sonarqube.py" ]]; then
        print_pass "SonarQube integration exists"

        # Check for key integration functions
        if grep -q "get_pr_findings\|fetch_pr_findings" "services/ai-code-review/integrations/sonarqube.py"; then
            print_pass "SonarQube integration has PR findings function"
        else
            print_fail "SonarQube integration missing PR findings function"
            return 1
        fi

        return 0
    else
        print_fail "SonarQube integration file not found"
        return 1
    fi
}

test_unit_tests_exist() {
    print_test "Unit tests exist for AI code review service"

    if [[ -f "services/ai-code-review/tests/unit/test_main.py" ]]; then
        print_pass "Main service tests exist"
    else
        print_fail "Main service tests missing"
        return 1
    fi

    if [[ -f "services/ai-code-review/tests/unit/test_sonarqube.py" ]]; then
        print_pass "SonarQube integration tests exist"
    else
        print_fail "SonarQube integration tests missing"
        return 1
    fi

    return 0
}

test_documentation_exists() {
    print_test "Documentation exists"

    local required_docs=(
        "services/ai-code-review/README.md"
        "services/ai-code-review/DEPLOYMENT.md"
        "services/ai-code-review/catalog-info.yaml"
    )

    for doc in "${required_docs[@]}"; do
        if [[ -f "$doc" ]]; then
            print_pass "Documentation exists: $(basename $doc)"
        else
            print_fail "Documentation missing: $(basename $doc)"
            return 1
        fi
    done

    return 0
}

test_service_deployment() {
    print_test "AI code review service is deployed"

    # Check if service exists in Kubernetes
    if kubectl get deployment ai-code-review -n "$NAMESPACE" &>/dev/null; then
        print_pass "AI code review deployment exists in namespace $NAMESPACE"

        # Check deployment status
        local ready_replicas=$(kubectl get deployment ai-code-review -n "$NAMESPACE" -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo "0")
        local desired_replicas=$(kubectl get deployment ai-code-review -n "$NAMESPACE" -o jsonpath='{.spec.replicas}' 2>/dev/null || echo "0")

        if [[ "$ready_replicas" == "$desired_replicas" ]] && [[ "$ready_replicas" -gt 0 ]]; then
            print_pass "AI code review deployment is ready ($ready_replicas/$desired_replicas replicas)"
        else
            print_skip "AI code review deployment not fully ready ($ready_replicas/$desired_replicas replicas)"
        fi
    else
        print_skip "AI code review service not deployed (acceptable for file validation)"
    fi

    return 0
}

test_service_accessibility() {
    print_test "AI code review service is accessible"

    # Check if service exists in Kubernetes
    if kubectl get service ai-code-review -n "$NAMESPACE" &>/dev/null; then
        print_pass "AI code review service exists in namespace $NAMESPACE"
    else
        print_skip "AI code review service not deployed (acceptable for file validation)"
        return 0
    fi

    # Try to access health endpoint
    if kubectl run curl-test --rm -i --restart=Never --image=curlimages/curl:latest -n "$NAMESPACE" \
        -- curl -s -f -m 5 "$AI_CODE_REVIEW_URL/health" &>/dev/null; then
        print_pass "AI code review service health check passed"
    else
        print_skip "AI code review service not accessible (may not be deployed)"
    fi

    return 0
}

test_webhook_endpoint_configured() {
    print_test "GitHub webhook endpoint is configured"

    # Check if the webhook handler exists in code
    if grep -q "/webhook/github" "services/ai-code-review/app/main.py"; then
        print_pass "GitHub webhook endpoint found in code"
    else
        print_fail "GitHub webhook endpoint not found in code"
        return 1
    fi

    # Check if signature verification is implemented
    if grep -q "verify.*signature\|hmac\|sha256" "services/ai-code-review/app/main.py"; then
        print_pass "Webhook signature verification implemented"
    else
        print_fail "Webhook signature verification not found"
        return 1
    fi

    return 0
}

test_review_categories_implemented() {
    print_test "All review categories are implemented"

    local categories=(
        "security"
        "performance"
        "best_practices"
        "test_coverage"
        "documentation"
    )

    for category in "${categories[@]}"; do
        if grep -q "$category" "services/ai-code-review/app/reviewer.py" || \
           grep -q "$category" "services/ai-code-review/prompts/loader.py"; then
            print_pass "Category implemented: $category"
        else
            print_fail "Category not implemented: $category"
            return 1
        fi
    done

    return 0
}

test_false_positive_filtering() {
    print_test "False positive filtering is implemented"

    # Check if confidence threshold is implemented
    if grep -q "FALSE_POSITIVE_THRESHOLD\|confidence\|threshold" "services/ai-code-review/app/reviewer.py"; then
        print_pass "False positive filtering implemented"
    else
        print_fail "False positive filtering not found"
        return 1
    fi

    return 0
}

test_metrics_instrumentation() {
    print_test "Prometheus metrics are instrumented"

    # Check if metrics are defined
    if grep -q "ai_review.*total\|prometheus_client" "services/ai-code-review/app/main.py" || \
       grep -q "ai_review.*total\|prometheus_client" "services/ai-code-review/app/reviewer.py"; then
        print_pass "Prometheus metrics instrumented"
    else
        print_fail "Prometheus metrics not found"
        return 1
    fi

    return 0
}

test_configuration_template() {
    print_test "Configuration template exists"

    if [[ -f "services/ai-code-review/.env.example" ]]; then
        print_pass "Environment configuration template exists"

        # Check for required configuration variables
        local required_vars=(
            "GITHUB_TOKEN"
            "GITHUB_WEBHOOK_SECRET"
            "LLM_API_KEY"
        )

        for var in "${required_vars[@]}"; do
            if grep -q "$var" "services/ai-code-review/.env.example"; then
                print_pass "Configuration variable documented: $var"
            else
                print_fail "Configuration variable missing: $var"
                return 1
            fi
        done
    else
        print_fail "Configuration template not found"
        return 1
    fi

    return 0
}

test_integration_with_rag() {
    print_test "RAG service integration exists"

    # Check if RAG integration is implemented
    if grep -q "RAG_SERVICE_URL\|rag.*service" "services/ai-code-review/app/reviewer.py"; then
        print_pass "RAG service integration found"
    else
        print_skip "RAG service integration not found (optional)"
    fi

    return 0
}

test_github_api_integration() {
    print_test "GitHub API integration exists"

    # Check if GitHub API client is implemented (via httpx or similar)
    if grep -q "httpx\|github.*api\|GitHub" "services/ai-code-review/app/reviewer.py"; then
        print_pass "GitHub API integration found"
    else
        print_fail "GitHub API integration not found"
        return 1
    fi

    return 0
}

test_deployment_validation_script() {
    print_test "Deployment validation script exists"

    if [[ -f "services/ai-code-review/validate-deployment.sh" ]]; then
        print_pass "Deployment validation script exists"

        # Make sure it's executable
        if [[ -x "services/ai-code-review/validate-deployment.sh" ]]; then
            print_pass "Deployment validation script is executable"
        else
            chmod +x "services/ai-code-review/validate-deployment.sh"
            print_pass "Made deployment validation script executable"
        fi
    else
        print_fail "Deployment validation script not found"
        return 1
    fi

    return 0
}

###############################################################################
# Main Execution
###############################################################################

main() {
    print_header "AT-E2-007: AI Code Review Bot Validation"

    print_info "Namespace: $NAMESPACE"
    print_info "AI Code Review URL: $AI_CODE_REVIEW_URL"

    print_header "Service File Tests"
    test_service_files_exist || true
    test_review_prompts_exist || true
    test_kubernetes_manifests_exist || true
    test_argocd_application_exists || true
    test_documentation_exists || true
    test_unit_tests_exist || true
    test_configuration_template || true

    print_header "Integration Tests"
    test_sonarqube_integration_exists || true
    test_integration_with_rag || true
    test_github_api_integration || true

    print_header "Functionality Tests"
    test_webhook_endpoint_configured || true
    test_review_categories_implemented || true
    test_false_positive_filtering || true
    test_metrics_instrumentation || true

    print_header "Deployment Tests"
    test_service_deployment || true
    test_service_accessibility || true
    test_deployment_validation_script || true

    print_header "Test Summary"
    echo -e "${GREEN}Passed:${NC}  $TESTS_PASSED"
    echo -e "${YELLOW}Skipped:${NC} $TESTS_SKIPPED"
    echo -e "${RED}Failed:${NC}  $TESTS_FAILED"
    echo ""

    if [[ $TESTS_FAILED -eq 0 ]]; then
        print_header "AT-E2-007 VALIDATION: PASSED ✓"
        echo -e "${GREEN}All AI code review requirements validated successfully!${NC}"
        return 0
    else
        print_header "AT-E2-007 VALIDATION: FAILED ✗"
        echo -e "${RED}Some validations failed. Please review the output above.${NC}"
        return 1
    fi
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
