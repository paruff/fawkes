#!/bin/bash
# ============================================================================
# FILE: scripts/validate-discovery-metrics.sh
# PURPOSE: Validation script for Discovery Metrics Dashboard (Issue #105)
# DESCRIPTION: Checks deployment, database, API, metrics, and dashboard
# ============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default values
NAMESPACE="${1:-fawkes}"
VERBOSE="${VERBOSE:-false}"

echo "================================================"
echo "Discovery Metrics Dashboard Validation (Issue #105)"
echo "================================================"
echo ""

# Track validation results
PASSED=0
FAILED=0

# Function to print test result
print_result() {
    local test_name="$1"
    local result="$2"
    local details="$3"
    
    if [ "$result" == "PASS" ]; then
        echo -e "${GREEN}✓${NC} $test_name"
        PASSED=$((PASSED + 1))
    else
        echo -e "${RED}✗${NC} $test_name"
        if [ -n "$details" ]; then
            echo -e "  ${RED}Details: $details${NC}"
        fi
        FAILED=$((FAILED + 1))
    fi
}

# Check 1: PostgreSQL cluster health
echo "Checking PostgreSQL cluster..."
if kubectl get cluster -n "$NAMESPACE" db-discovery-dev &>/dev/null; then
    CLUSTER_STATUS=$(kubectl get cluster -n "$NAMESPACE" db-discovery-dev -o jsonpath='{.status.phase}')
    if [ "$CLUSTER_STATUS" == "Cluster in healthy state" ] || [ "$CLUSTER_STATUS" == "Healthy" ]; then
        print_result "PostgreSQL cluster db-discovery-dev is healthy" "PASS"
    else
        print_result "PostgreSQL cluster db-discovery-dev is healthy" "FAIL" "Status: $CLUSTER_STATUS"
    fi
else
    print_result "PostgreSQL cluster db-discovery-dev exists" "FAIL" "Cluster not found"
fi

# Check 2: Service deployment
echo ""
echo "Checking Discovery Metrics service..."
if kubectl get deployment -n "$NAMESPACE" discovery-metrics &>/dev/null; then
    REPLICAS=$(kubectl get deployment -n "$NAMESPACE" discovery-metrics -o jsonpath='{.status.replicas}')
    READY=$(kubectl get deployment -n "$NAMESPACE" discovery-metrics -o jsonpath='{.status.readyReplicas}')
    
    if [ "$REPLICAS" == "2" ] && [ "$READY" == "2" ]; then
        print_result "Discovery Metrics deployment has 2/2 replicas ready" "PASS"
    else
        print_result "Discovery Metrics deployment has 2/2 replicas ready" "FAIL" "Ready: $READY/$REPLICAS"
    fi
else
    print_result "Discovery Metrics deployment exists" "FAIL" "Deployment not found"
fi

# Check 3: Pod status
echo ""
echo "Checking pod status..."
PODS=$(kubectl get pods -n "$NAMESPACE" -l app=discovery-metrics -o jsonpath='{.items[*].metadata.name}')
if [ -n "$PODS" ]; then
    ALL_RUNNING=true
    for POD in $PODS; do
        STATUS=$(kubectl get pod -n "$NAMESPACE" "$POD" -o jsonpath='{.status.phase}')
        if [ "$STATUS" != "Running" ]; then
            ALL_RUNNING=false
            print_result "Pod $POD is running" "FAIL" "Status: $STATUS"
        fi
    done
    
    if [ "$ALL_RUNNING" == "true" ]; then
        print_result "All Discovery Metrics pods are running" "PASS"
    fi
else
    print_result "Discovery Metrics pods exist" "FAIL" "No pods found"
fi

# Check 4: Service and Ingress
echo ""
echo "Checking service and ingress..."
if kubectl get service -n "$NAMESPACE" discovery-metrics &>/dev/null; then
    print_result "Discovery Metrics service exists" "PASS"
else
    print_result "Discovery Metrics service exists" "FAIL"
fi

if kubectl get ingress -n "$NAMESPACE" discovery-metrics &>/dev/null; then
    print_result "Discovery Metrics ingress exists" "PASS"
else
    print_result "Discovery Metrics ingress exists" "FAIL"
fi

# Check 5: Health endpoint
echo ""
echo "Checking API health..."
if [ -n "$PODS" ]; then
    POD=$(echo "$PODS" | awk '{print $1}')
    if kubectl exec -n "$NAMESPACE" "$POD" -- curl -s http://localhost:8000/health > /dev/null 2>&1; then
        HEALTH_RESPONSE=$(kubectl exec -n "$NAMESPACE" "$POD" -- curl -s http://localhost:8000/health)
        if echo "$HEALTH_RESPONSE" | grep -q '"status":"healthy"'; then
            print_result "Health endpoint returns healthy status" "PASS"
        else
            print_result "Health endpoint returns healthy status" "FAIL" "Response: $HEALTH_RESPONSE"
        fi
    else
        print_result "Health endpoint is accessible" "FAIL"
    fi
fi

# Check 6: Database connectivity
echo ""
echo "Checking database connectivity..."
if [ -n "$PODS" ]; then
    POD=$(echo "$PODS" | awk '{print $1}')
    if kubectl exec -n "$NAMESPACE" "$POD" -- curl -s http://localhost:8000/health | grep -q '"database_connected":true'; then
        print_result "Service can connect to database" "PASS"
    else
        print_result "Service can connect to database" "FAIL"
    fi
fi

# Check 7: Database schema
echo ""
echo "Checking database schema..."
DB_POD=$(kubectl get pod -n "$NAMESPACE" -l cnpg.io/cluster=db-discovery-dev,role=primary -o jsonpath='{.items[0].metadata.name}')
if [ -n "$DB_POD" ]; then
    TABLES=$(kubectl exec -n "$NAMESPACE" "$DB_POD" -- psql -U discovery_user -d discovery_metrics -c "\dt" 2>/dev/null || echo "")
    
    if echo "$TABLES" | grep -q "interviews"; then
        print_result "Table 'interviews' exists" "PASS"
    else
        print_result "Table 'interviews' exists" "FAIL"
    fi
    
    if echo "$TABLES" | grep -q "discovery_insights"; then
        print_result "Table 'discovery_insights' exists" "PASS"
    else
        print_result "Table 'discovery_insights' exists" "FAIL"
    fi
    
    if echo "$TABLES" | grep -q "experiments"; then
        print_result "Table 'experiments' exists" "PASS"
    else
        print_result "Table 'experiments' exists" "FAIL"
    fi
    
    if echo "$TABLES" | grep -q "feature_validations"; then
        print_result "Table 'feature_validations' exists" "PASS"
    else
        print_result "Table 'feature_validations' exists" "FAIL"
    fi
    
    if echo "$TABLES" | grep -q "team_performance"; then
        print_result "Table 'team_performance' exists" "PASS"
    else
        print_result "Table 'team_performance' exists" "FAIL"
    fi
fi

# Check 8: Prometheus metrics
echo ""
echo "Checking Prometheus metrics..."
if [ -n "$PODS" ]; then
    POD=$(echo "$PODS" | awk '{print $1}')
    METRICS=$(kubectl exec -n "$NAMESPACE" "$POD" -- curl -s http://localhost:8000/metrics 2>/dev/null || echo "")
    
    if echo "$METRICS" | grep -q "discovery_interviews_total"; then
        print_result "Metric 'discovery_interviews_total' is exposed" "PASS"
    else
        print_result "Metric 'discovery_interviews_total' is exposed" "FAIL"
    fi
    
    if echo "$METRICS" | grep -q "discovery_insights_total"; then
        print_result "Metric 'discovery_insights_total' is exposed" "PASS"
    else
        print_result "Metric 'discovery_insights_total' is exposed" "FAIL"
    fi
    
    if echo "$METRICS" | grep -q "discovery_experiments_total"; then
        print_result "Metric 'discovery_experiments_total' is exposed" "PASS"
    else
        print_result "Metric 'discovery_experiments_total' is exposed" "FAIL"
    fi
    
    if echo "$METRICS" | grep -q "discovery_features_validated"; then
        print_result "Metric 'discovery_features_validated' is exposed" "PASS"
    else
        print_result "Metric 'discovery_features_validated' is exposed" "FAIL"
    fi
fi

# Check 9: ServiceMonitor
echo ""
echo "Checking ServiceMonitor..."
if kubectl get servicemonitor -n "$NAMESPACE" discovery-metrics &>/dev/null; then
    print_result "ServiceMonitor exists" "PASS"
    
    INTERVAL=$(kubectl get servicemonitor -n "$NAMESPACE" discovery-metrics -o jsonpath='{.spec.endpoints[0].interval}')
    if [ "$INTERVAL" == "30s" ]; then
        print_result "ServiceMonitor scrape interval is 30s" "PASS"
    else
        print_result "ServiceMonitor scrape interval is 30s" "FAIL" "Interval: $INTERVAL"
    fi
else
    print_result "ServiceMonitor exists" "FAIL"
fi

# Check 10: Resource usage (should be <70% of limits)
echo ""
echo "Checking resource usage..."
if [ -n "$PODS" ]; then
    for POD in $PODS; do
        # CPU usage
        CPU_USAGE=$(kubectl top pod -n "$NAMESPACE" "$POD" 2>/dev/null | tail -1 | awk '{print $2}' | sed 's/m//')
        CPU_LIMIT=1000  # 1 CPU = 1000m
        
        if [ -n "$CPU_USAGE" ] && [ "$CPU_USAGE" -lt 700 ]; then
            print_result "Pod $POD CPU usage <70% of limit" "PASS"
        elif [ -n "$CPU_USAGE" ]; then
            print_result "Pod $POD CPU usage <70% of limit" "FAIL" "Usage: ${CPU_USAGE}m"
        fi
        
        # Memory usage
        MEM_USAGE=$(kubectl top pod -n "$NAMESPACE" "$POD" 2>/dev/null | tail -1 | awk '{print $3}' | sed 's/Mi//')
        MEM_LIMIT=1024  # 1Gi = 1024Mi
        
        if [ -n "$MEM_USAGE" ] && [ "$MEM_USAGE" -lt 717 ]; then
            print_result "Pod $POD memory usage <70% of limit" "PASS"
        elif [ -n "$MEM_USAGE" ]; then
            print_result "Pod $POD memory usage <70% of limit" "FAIL" "Usage: ${MEM_USAGE}Mi"
        fi
    done
fi

# Summary
echo ""
echo "================================================"
echo "Validation Summary"
echo "================================================"
echo -e "${GREEN}Passed: $PASSED${NC}"
echo -e "${RED}Failed: $FAILED${NC}"
echo ""

if [ "$FAILED" -eq 0 ]; then
    echo -e "${GREEN}✓ All validation checks passed!${NC}"
    exit 0
else
    echo -e "${RED}✗ Some validation checks failed.${NC}"
    exit 1
fi
