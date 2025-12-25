#!/bin/bash
# Validation script for Analytics Dashboard Service (Issue #101)

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
NAMESPACE="${NAMESPACE:-fawkes}"
SERVICE_NAME="analytics-dashboard"
API_URL="http://${SERVICE_NAME}.${NAMESPACE}.svc:8000"

echo -e "${GREEN}=== Analytics Dashboard Validation ===${NC}"
echo "Namespace: $NAMESPACE"
echo "Service: $SERVICE_NAME"
echo ""

# Test counter
TESTS_PASSED=0
TESTS_FAILED=0

# Function to run a test
run_test() {
    local test_name="$1"
    local test_command="$2"
    
    echo -n "Testing: $test_name... "
    if eval "$test_command" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ PASSED${NC}"
        ((TESTS_PASSED++))
        return 0
    else
        echo -e "${RED}✗ FAILED${NC}"
        ((TESTS_FAILED++))
        return 1
    fi
}

# 1. Check if namespace exists
echo -e "${YELLOW}1. Checking namespace...${NC}"
run_test "Namespace exists" "kubectl get namespace $NAMESPACE"

# 2. Check deployment
echo -e "${YELLOW}2. Checking deployment...${NC}"
run_test "Deployment exists" "kubectl get deployment $SERVICE_NAME -n $NAMESPACE"
run_test "Deployment has correct replicas" "[ \$(kubectl get deployment $SERVICE_NAME -n $NAMESPACE -o jsonpath='{.spec.replicas}') -eq 2 ]"

# 3. Check pods
echo -e "${YELLOW}3. Checking pods...${NC}"
run_test "Pods are running" "kubectl get pods -n $NAMESPACE -l app=$SERVICE_NAME | grep -q Running"
run_test "All pods are ready" "[ \$(kubectl get pods -n $NAMESPACE -l app=$SERVICE_NAME -o jsonpath='{.items[*].status.containerStatuses[*].ready}' | grep -o true | wc -l) -ge 2 ]"

# 4. Check service
echo -e "${YELLOW}4. Checking service...${NC}"
run_test "Service exists" "kubectl get service $SERVICE_NAME -n $NAMESPACE"
run_test "Service has endpoints" "kubectl get endpoints $SERVICE_NAME -n $NAMESPACE | grep -q $SERVICE_NAME"

# 5. Check ConfigMap
echo -e "${YELLOW}5. Checking configuration...${NC}"
run_test "ConfigMap exists" "kubectl get configmap ${SERVICE_NAME}-config -n $NAMESPACE"

# 6. Check ServiceMonitor
echo -e "${YELLOW}6. Checking monitoring...${NC}"
run_test "ServiceMonitor exists" "kubectl get servicemonitor $SERVICE_NAME -n $NAMESPACE"

# 7. Check Ingress
echo -e "${YELLOW}7. Checking ingress...${NC}"
run_test "Ingress exists" "kubectl get ingress $SERVICE_NAME -n $NAMESPACE"

# 8. Check PodDisruptionBudget
echo -e "${YELLOW}8. Checking high availability...${NC}"
run_test "PodDisruptionBudget exists" "kubectl get pdb $SERVICE_NAME -n $NAMESPACE"

# 9. Test health endpoint
echo -e "${YELLOW}9. Testing health endpoint...${NC}"
POD_NAME=$(kubectl get pods -n $NAMESPACE -l app=$SERVICE_NAME -o jsonpath='{.items[0].metadata.name}')
if [ -n "$POD_NAME" ]; then
    run_test "Health endpoint responds" "kubectl exec -n $NAMESPACE $POD_NAME -- wget -q -O- http://localhost:8000/health | grep -q healthy"
fi

# 10. Test API endpoints
echo -e "${YELLOW}10. Testing API endpoints...${NC}"
if [ -n "$POD_NAME" ]; then
    run_test "Dashboard endpoint responds" "kubectl exec -n $NAMESPACE $POD_NAME -- wget -q -O- 'http://localhost:8000/api/v1/dashboard?time_range=7d' | grep -q usage_trends"
    run_test "Usage trends endpoint responds" "kubectl exec -n $NAMESPACE $POD_NAME -- wget -q -O- 'http://localhost:8000/api/v1/usage-trends?time_range=7d' | grep -q total_users"
    run_test "Feature adoption endpoint responds" "kubectl exec -n $NAMESPACE $POD_NAME -- wget -q -O- 'http://localhost:8000/api/v1/feature-adoption?time_range=30d' | grep -q features"
    run_test "Experiment results endpoint responds" "kubectl exec -n $NAMESPACE $POD_NAME -- wget -q -O- 'http://localhost:8000/api/v1/experiment-results' | grep -q experiment_id"
    run_test "User segments endpoint responds" "kubectl exec -n $NAMESPACE $POD_NAME -- wget -q -O- 'http://localhost:8000/api/v1/user-segments?time_range=30d' | grep -q segments"
    run_test "Funnel endpoint responds" "kubectl exec -n $NAMESPACE $POD_NAME -- wget -q -O- 'http://localhost:8000/api/v1/funnel/onboarding?time_range=30d' | grep -q steps"
fi

# 11. Test metrics endpoint
echo -e "${YELLOW}11. Testing Prometheus metrics...${NC}"
if [ -n "$POD_NAME" ]; then
    run_test "Metrics endpoint accessible" "kubectl exec -n $NAMESPACE $POD_NAME -- wget -q -O- http://localhost:8000/metrics | grep -q analytics_"
    run_test "Usage metrics present" "kubectl exec -n $NAMESPACE $POD_NAME -- wget -q -O- http://localhost:8000/metrics | grep -q analytics_total_users"
    run_test "Feature metrics present" "kubectl exec -n $NAMESPACE $POD_NAME -- wget -q -O- http://localhost:8000/metrics | grep -q analytics_feature_adoption_rate"
    run_test "Experiment metrics present" "kubectl exec -n $NAMESPACE $POD_NAME -- wget -q -O- http://localhost:8000/metrics | grep -q analytics_active_experiments"
    run_test "Segment metrics present" "kubectl exec -n $NAMESPACE $POD_NAME -- wget -q -O- http://localhost:8000/metrics | grep -q analytics_segment_size"
    run_test "Funnel metrics present" "kubectl exec -n $NAMESPACE $POD_NAME -- wget -q -O- http://localhost:8000/metrics | grep -q analytics_funnel_conversion_rate"
fi

# 12. Check resource limits
echo -e "${YELLOW}12. Checking resource configuration...${NC}"
run_test "CPU requests set" "kubectl get deployment $SERVICE_NAME -n $NAMESPACE -o jsonpath='{.spec.template.spec.containers[0].resources.requests.cpu}' | grep -q 200m"
run_test "Memory requests set" "kubectl get deployment $SERVICE_NAME -n $NAMESPACE -o jsonpath='{.spec.template.spec.containers[0].resources.requests.memory}' | grep -q 256Mi"
run_test "CPU limits set" "kubectl get deployment $SERVICE_NAME -n $NAMESPACE -o jsonpath='{.spec.template.spec.containers[0].resources.limits.cpu}' | grep -q 500m"
run_test "Memory limits set" "kubectl get deployment $SERVICE_NAME -n $NAMESPACE -o jsonpath='{.spec.template.spec.containers[0].resources.limits.memory}' | grep -q 512Mi"

# 13. Check security context
echo -e "${YELLOW}13. Checking security configuration...${NC}"
run_test "Non-root user" "kubectl get deployment $SERVICE_NAME -n $NAMESPACE -o jsonpath='{.spec.template.spec.securityContext.runAsNonRoot}' | grep -q true"
run_test "Read-only root filesystem" "kubectl get deployment $SERVICE_NAME -n $NAMESPACE -o jsonpath='{.spec.template.spec.containers[0].securityContext.readOnlyRootFilesystem}' | grep -q true"
run_test "No privilege escalation" "kubectl get deployment $SERVICE_NAME -n $NAMESPACE -o jsonpath='{.spec.template.spec.containers[0].securityContext.allowPrivilegeEscalation}' | grep -q false"

# 14. Check probes
echo -e "${YELLOW}14. Checking health probes...${NC}"
run_test "Liveness probe configured" "kubectl get deployment $SERVICE_NAME -n $NAMESPACE -o yaml | grep -q livenessProbe"
run_test "Readiness probe configured" "kubectl get deployment $SERVICE_NAME -n $NAMESPACE -o yaml | grep -q readinessProbe"

# 15. Check Grafana dashboard
echo -e "${YELLOW}15. Checking Grafana dashboard...${NC}"
run_test "Dashboard ConfigMap exists" "kubectl get configmap analytics-dashboard -n monitoring"
run_test "Dashboard has correct label" "kubectl get configmap analytics-dashboard -n monitoring -o jsonpath='{.metadata.labels.grafana_dashboard}' | grep -q 1"

# 16. Test export functionality
echo -e "${YELLOW}16. Testing export functionality...${NC}"
if [ -n "$POD_NAME" ]; then
    run_test "JSON export works" "kubectl exec -n $NAMESPACE $POD_NAME -- wget -q -O- 'http://localhost:8000/api/v1/export/json?time_range=7d' | grep -q timestamp"
fi

# 17. Check pod anti-affinity
echo -e "${YELLOW}17. Checking high availability configuration...${NC}"
run_test "Pod anti-affinity configured" "kubectl get deployment $SERVICE_NAME -n $NAMESPACE -o yaml | grep -q podAntiAffinity"

# 18. Verify labels
echo -e "${YELLOW}18. Checking labels...${NC}"
run_test "App label set" "kubectl get deployment $SERVICE_NAME -n $NAMESPACE -o jsonpath='{.metadata.labels.app}' | grep -q $SERVICE_NAME"
run_test "Component label set" "kubectl get deployment $SERVICE_NAME -n $NAMESPACE -o jsonpath='{.metadata.labels.component}' | grep -q analytics"

# Summary
echo ""
echo -e "${GREEN}=== Validation Summary ===${NC}"
echo -e "Tests Passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Tests Failed: ${RED}$TESTS_FAILED${NC}"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ All validation tests passed!${NC}"
    exit 0
else
    echo -e "${RED}✗ Some validation tests failed.${NC}"
    exit 1
fi
