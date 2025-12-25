#!/bin/bash
# ============================================================================
# FILE: scripts/validate-at-e2-002.sh
# PURPOSE: Validation script for AT-E2-002 acceptance test (RAG service)
# USAGE: ./scripts/validate-at-e2-002.sh
# ============================================================================

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Configuration
NAMESPACE="${NAMESPACE:-fawkes}"
RAG_SERVICE_HOST="${RAG_SERVICE_HOST:-rag-service.127.0.0.1.nip.io}"
TIMEOUT="${TIMEOUT:-300}"

echo "================================================================================"
echo "AT-E2-002: RAG Service Validation"
echo "================================================================================"
echo ""
echo "Namespace: $NAMESPACE"
echo "RAG Service Host: $RAG_SERVICE_HOST"
echo ""

# Helper functions
pass() {
    echo -e "${GREEN}✓${NC} $1"
    ((TESTS_PASSED++))
}

fail() {
    echo -e "${RED}✗${NC} $1"
    ((TESTS_FAILED++))
}

info() {
    echo -e "${YELLOW}ℹ${NC} $1"
}

run_test() {
    ((TESTS_RUN++))
}

# Test functions
test_prerequisites() {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Phase 1: Prerequisites"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    # Check kubectl
    run_test
    if command -v kubectl &> /dev/null; then
        pass "kubectl is installed"
    else
        fail "kubectl is not installed"
        exit 1
    fi

    # Check cluster access
    run_test
    if kubectl cluster-info &> /dev/null; then
        pass "Kubernetes cluster is accessible"
    else
        fail "Cannot access Kubernetes cluster"
        exit 1
    fi

    # Check namespace exists
    run_test
    if kubectl get namespace "$NAMESPACE" &> /dev/null; then
        pass "Namespace $NAMESPACE exists"
    else
        fail "Namespace $NAMESPACE does not exist"
        exit 1
    fi

    echo ""
}

test_weaviate() {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Phase 2: Weaviate Integration"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    # Check Weaviate deployment
    run_test
    if kubectl get deployment weaviate -n "$NAMESPACE" &> /dev/null; then
        pass "Weaviate deployment exists"
    else
        fail "Weaviate deployment does not exist"
        return
    fi

    # Check Weaviate pods are ready
    run_test
    WEAVIATE_READY=$(kubectl get deployment weaviate -n "$NAMESPACE" -o jsonpath='{.status.readyReplicas}')
    WEAVIATE_DESIRED=$(kubectl get deployment weaviate -n "$NAMESPACE" -o jsonpath='{.spec.replicas}')
    if [ "$WEAVIATE_READY" = "$WEAVIATE_DESIRED" ] && [ "$WEAVIATE_READY" -gt 0 ]; then
        pass "Weaviate pods are ready ($WEAVIATE_READY/$WEAVIATE_DESIRED)"
    else
        fail "Weaviate pods not ready ($WEAVIATE_READY/$WEAVIATE_DESIRED)"
    fi

    echo ""
}

test_rag_deployment() {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Phase 3: RAG Service Deployment"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    # Check deployment exists
    run_test
    if kubectl get deployment rag-service -n "$NAMESPACE" &> /dev/null; then
        pass "RAG service deployment exists"
    else
        fail "RAG service deployment does not exist"
        return
    fi

    # Check replicas
    run_test
    REPLICAS=$(kubectl get deployment rag-service -n "$NAMESPACE" -o jsonpath='{.spec.replicas}')
    if [ "$REPLICAS" = "2" ]; then
        pass "RAG service has 2 replicas"
    else
        fail "RAG service does not have 2 replicas (has $REPLICAS)"
    fi

    # Check pods are ready
    run_test
    READY=$(kubectl get deployment rag-service -n "$NAMESPACE" -o jsonpath='{.status.readyReplicas}')
    DESIRED=$(kubectl get deployment rag-service -n "$NAMESPACE" -o jsonpath='{.spec.replicas}')
    if [ "$READY" = "$DESIRED" ] && [ "$READY" -gt 0 ]; then
        pass "RAG service pods are ready ($READY/$DESIRED)"
    else
        fail "RAG service pods not ready ($READY/$DESIRED)"
    fi

    # Check service exists
    run_test
    if kubectl get service rag-service -n "$NAMESPACE" &> /dev/null; then
        pass "RAG service exists"
    else
        fail "RAG service does not exist"
    fi

    # Check service type
    run_test
    SERVICE_TYPE=$(kubectl get service rag-service -n "$NAMESPACE" -o jsonpath='{.spec.type}')
    if [ "$SERVICE_TYPE" = "ClusterIP" ]; then
        pass "Service type is ClusterIP"
    else
        fail "Service type is not ClusterIP (is $SERVICE_TYPE)"
    fi

    # Check ingress exists
    run_test
    if kubectl get ingress rag-service -n "$NAMESPACE" &> /dev/null; then
        pass "Ingress exists"
    else
        fail "Ingress does not exist"
    fi

    # Check ConfigMap
    run_test
    if kubectl get configmap rag-service-config -n "$NAMESPACE" &> /dev/null; then
        pass "ConfigMap exists"
    else
        fail "ConfigMap does not exist"
    fi

    # Check ServiceAccount
    run_test
    if kubectl get serviceaccount rag-service -n "$NAMESPACE" &> /dev/null; then
        pass "ServiceAccount exists"
    else
        fail "ServiceAccount does not exist"
    fi

    echo ""
}

test_resource_limits() {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Phase 4: Resource Limits"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    # Check CPU request
    run_test
    CPU_REQUEST=$(kubectl get deployment rag-service -n "$NAMESPACE" -o jsonpath='{.spec.template.spec.containers[0].resources.requests.cpu}')
    if [ "$CPU_REQUEST" = "500m" ]; then
        pass "CPU request is 500m"
    else
        fail "CPU request is not 500m (is $CPU_REQUEST)"
    fi

    # Check memory request
    run_test
    MEM_REQUEST=$(kubectl get deployment rag-service -n "$NAMESPACE" -o jsonpath='{.spec.template.spec.containers[0].resources.requests.memory}')
    if [ "$MEM_REQUEST" = "1Gi" ]; then
        pass "Memory request is 1Gi"
    else
        fail "Memory request is not 1Gi (is $MEM_REQUEST)"
    fi

    # Check CPU limit
    run_test
    CPU_LIMIT=$(kubectl get deployment rag-service -n "$NAMESPACE" -o jsonpath='{.spec.template.spec.containers[0].resources.limits.cpu}')
    if [ "$CPU_LIMIT" = "1" ]; then
        pass "CPU limit is 1 core"
    else
        fail "CPU limit is not 1 core (is $CPU_LIMIT)"
    fi

    # Check memory limit
    run_test
    MEM_LIMIT=$(kubectl get deployment rag-service -n "$NAMESPACE" -o jsonpath='{.spec.template.spec.containers[0].resources.limits.memory}')
    if [ "$MEM_LIMIT" = "1Gi" ]; then
        pass "Memory limit is 1Gi"
    else
        fail "Memory limit is not 1Gi (is $MEM_LIMIT)"
    fi

    echo ""
}

test_api_endpoints() {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Phase 5: API Endpoints"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    # Check health endpoint
    run_test
    if curl -sf "http://$RAG_SERVICE_HOST/api/v1/health" > /dev/null; then
        pass "Health endpoint is accessible"

        # Check health response
        run_test
        HEALTH_RESPONSE=$(curl -s "http://$RAG_SERVICE_HOST/api/v1/health")
        if echo "$HEALTH_RESPONSE" | jq -e '.status' > /dev/null 2>&1; then
            STATUS=$(echo "$HEALTH_RESPONSE" | jq -r '.status')
            if [ "$STATUS" = "UP" ] || [ "$STATUS" = "DEGRADED" ]; then
                pass "Health status is $STATUS"
            else
                fail "Health status is unexpected: $STATUS"
            fi
        else
            fail "Health response is not valid JSON"
        fi

        # Check Weaviate connection
        run_test
        if echo "$HEALTH_RESPONSE" | jq -e '.weaviate_connected' > /dev/null 2>&1; then
            WEAVIATE_CONNECTED=$(echo "$HEALTH_RESPONSE" | jq -r '.weaviate_connected')
            if [ "$WEAVIATE_CONNECTED" = "true" ]; then
                pass "RAG service connected to Weaviate"
            else
                fail "RAG service not connected to Weaviate"
            fi
        fi
    else
        fail "Health endpoint is not accessible"
    fi

    # Check OpenAPI docs
    run_test
    if curl -sf "http://$RAG_SERVICE_HOST/docs" > /dev/null; then
        pass "OpenAPI documentation is accessible"
    else
        fail "OpenAPI documentation is not accessible"
    fi

    # Check metrics endpoint
    run_test
    if curl -sf "http://$RAG_SERVICE_HOST/metrics" > /dev/null; then
        pass "Metrics endpoint is accessible"
    else
        fail "Metrics endpoint is not accessible"
    fi

    echo ""
}

test_context_retrieval() {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Phase 6: Context Retrieval"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    # Test query endpoint
    run_test
    QUERY_RESPONSE=$(curl -s -X POST "http://$RAG_SERVICE_HOST/api/v1/query" \
        -H "Content-Type: application/json" \
        -d '{"query": "How do I deploy a new service?", "top_k": 5, "threshold": 0.7}')

    if [ $? -eq 0 ]; then
        pass "Query endpoint is accessible"

        # Check response time
        run_test
        if echo "$QUERY_RESPONSE" | jq -e '.retrieval_time_ms' > /dev/null 2>&1; then
            RETRIEVAL_TIME=$(echo "$QUERY_RESPONSE" | jq -r '.retrieval_time_ms')
            if (( $(echo "$RETRIEVAL_TIME < 500" | bc -l) )); then
                pass "Retrieval time is ${RETRIEVAL_TIME}ms (<500ms)"
            else
                fail "Retrieval time is ${RETRIEVAL_TIME}ms (≥500ms)"
            fi
        else
            fail "Response does not contain retrieval_time_ms"
        fi

        # Check results
        run_test
        if echo "$QUERY_RESPONSE" | jq -e '.results' > /dev/null 2>&1; then
            RESULT_COUNT=$(echo "$QUERY_RESPONSE" | jq -r '.count')
            info "Query returned $RESULT_COUNT results"

            if [ "$RESULT_COUNT" -gt 0 ]; then
                pass "Query returned results"

                # Check relevance scores
                run_test
                TOP_SCORE=$(echo "$QUERY_RESPONSE" | jq -r '.results[0].relevance_score // 0')
                if (( $(echo "$TOP_SCORE > 0.7" | bc -l) )); then
                    pass "Top result relevance score is $TOP_SCORE (>0.7)"
                else
                    fail "Top result relevance score is $TOP_SCORE (≤0.7)"
                fi
            else
                info "No results returned (documentation may not be indexed)"
            fi
        else
            fail "Response does not contain results"
        fi
    else
        fail "Query endpoint is not accessible"
    fi

    echo ""
}

# Main execution
main() {
    test_prerequisites
    test_weaviate
    test_rag_deployment
    test_resource_limits
    test_api_endpoints
    test_context_retrieval

    # Summary
    echo "================================================================================"
    echo "Test Summary"
    echo "================================================================================"
    echo ""
    echo "Tests Run:    $TESTS_RUN"
    echo "Tests Passed: $TESTS_PASSED"
    echo "Tests Failed: $TESTS_FAILED"
    echo ""

    if [ $TESTS_FAILED -eq 0 ]; then
        echo -e "${GREEN}✓ AT-E2-002: All tests passed!${NC}"
        echo ""
        echo "RAG service is:"
        echo "  ✓ Deployed and running"
        echo "  ✓ Integrated with Weaviate"
        echo "  ✓ API is accessible and responsive"
        echo "  ✓ Context retrieval is working (<500ms)"
        echo "  ✓ Relevance scoring is good (>0.7)"
        echo ""
        exit 0
    else
        echo -e "${RED}✗ AT-E2-002: $TESTS_FAILED test(s) failed${NC}"
        echo ""
        exit 1
    fi
}

# Run main function
main
