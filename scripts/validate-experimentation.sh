#!/usr/bin/env bash

# ============================================================================
# FILE: scripts/validate-experimentation.sh
# PURPOSE: Validation script for Experimentation Framework (AT-E3-012)
# DESCRIPTION: Validates deployment, database, API, and integration
# ============================================================================

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default values
NAMESPACE="${NAMESPACE:-fawkes}"
VERBOSE="${VERBOSE:-false}"

# Counters
TESTS_PASSED=0
TESTS_FAILED=0

# Helper functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

check_passed() {
    echo -e "${GREEN}✓${NC} $1"
    ((TESTS_PASSED++))
}

check_failed() {
    echo -e "${RED}✗${NC} $1"
    ((TESTS_FAILED++))
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --namespace)
            NAMESPACE="$2"
            shift 2
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

log_info "====================================================================="
log_info "Experimentation Framework Validation (AT-E3-012)"
log_info "Namespace: $NAMESPACE"
log_info "====================================================================="
echo

# ============================================================================
# Test 1: Check PostgreSQL Cluster
# ============================================================================
log_info "Test 1: Checking PostgreSQL cluster db-experiment-dev..."

if kubectl get cluster db-experiment-dev -n "$NAMESPACE" &>/dev/null; then
    CLUSTER_STATUS=$(kubectl get cluster db-experiment-dev -n "$NAMESPACE" -o jsonpath='{.status.phase}')
    if [[ "$CLUSTER_STATUS" == "Cluster in healthy state" ]]; then
        check_passed "PostgreSQL cluster db-experiment-dev is healthy"
    else
        check_failed "PostgreSQL cluster db-experiment-dev status: $CLUSTER_STATUS"
    fi
else
    check_failed "PostgreSQL cluster db-experiment-dev not found"
fi

# Check database credentials
if kubectl get secret db-experiment-credentials -n "$NAMESPACE" &>/dev/null; then
    check_passed "Database credentials secret exists"
else
    check_failed "Database credentials secret not found"
fi

echo

# ============================================================================
# Test 2: Check Experimentation Service Deployment
# ============================================================================
log_info "Test 2: Checking Experimentation service deployment..."

if kubectl get deployment experimentation -n "$NAMESPACE" &>/dev/null; then
    REPLICAS_READY=$(kubectl get deployment experimentation -n "$NAMESPACE" -o jsonpath='{.status.readyReplicas}')
    REPLICAS_DESIRED=$(kubectl get deployment experimentation -n "$NAMESPACE" -o jsonpath='{.spec.replicas}')
    
    if [[ "$REPLICAS_READY" == "$REPLICAS_DESIRED" ]] && [[ "$REPLICAS_READY" -ge 2 ]]; then
        check_passed "Experimentation deployment has $REPLICAS_READY/$REPLICAS_DESIRED replicas ready"
    else
        check_failed "Experimentation deployment has $REPLICAS_READY/$REPLICAS_DESIRED replicas ready"
    fi
else
    check_failed "Experimentation deployment not found"
fi

# Check pods are running
POD_COUNT=$(kubectl get pods -n "$NAMESPACE" -l app=experimentation -o json | jq -r '.items | length')
RUNNING_PODS=$(kubectl get pods -n "$NAMESPACE" -l app=experimentation -o json | jq -r '[.items[] | select(.status.phase == "Running")] | length')

if [[ "$POD_COUNT" -eq "$RUNNING_PODS" ]] && [[ "$POD_COUNT" -ge 2 ]]; then
    check_passed "All $POD_COUNT Experimentation pods are running"
else
    check_failed "Only $RUNNING_PODS/$POD_COUNT Experimentation pods are running"
fi

echo

# ============================================================================
# Test 3: Check Service and Ingress
# ============================================================================
log_info "Test 3: Checking Service and Ingress..."

if kubectl get service experimentation -n "$NAMESPACE" &>/dev/null; then
    SERVICE_TYPE=$(kubectl get service experimentation -n "$NAMESPACE" -o jsonpath='{.spec.type}')
    if [[ "$SERVICE_TYPE" == "ClusterIP" ]]; then
        check_passed "Experimentation service exists (type: $SERVICE_TYPE)"
    else
        check_warning "Experimentation service has unexpected type: $SERVICE_TYPE"
    fi
else
    check_failed "Experimentation service not found"
fi

if kubectl get ingress experimentation -n "$NAMESPACE" &>/dev/null; then
    INGRESS_HOST=$(kubectl get ingress experimentation -n "$NAMESPACE" -o jsonpath='{.spec.rules[0].host}')
    check_passed "Experimentation ingress exists (host: $INGRESS_HOST)"
else
    check_failed "Experimentation ingress not found"
fi

echo

# ============================================================================
# Test 4: Check API Health
# ============================================================================
log_info "Test 4: Checking API health..."

POD_NAME=$(kubectl get pods -n "$NAMESPACE" -l app=experimentation -o jsonpath='{.items[0].metadata.name}')

if [[ -n "$POD_NAME" ]]; then
    HEALTH_RESPONSE=$(kubectl exec -n "$NAMESPACE" "$POD_NAME" -- curl -s http://localhost:8000/health || echo "failed")
    
    if echo "$HEALTH_RESPONSE" | grep -q "healthy"; then
        check_passed "API health check returned healthy status"
        
        if echo "$HEALTH_RESPONSE" | grep -q "experimentation"; then
            check_passed "API identifies as experimentation service"
        else
            check_failed "API does not identify as experimentation service"
        fi
    else
        check_failed "API health check failed: $HEALTH_RESPONSE"
    fi
else
    check_failed "Could not find Experimentation pod to test health"
fi

echo

# ============================================================================
# Test 5: Check Database Connectivity
# ============================================================================
log_info "Test 5: Checking database connectivity..."

if [[ -n "$POD_NAME" ]]; then
    DB_TEST=$(kubectl exec -n "$NAMESPACE" "$POD_NAME" -- python3 -c "
from app.database import engine
try:
    conn = engine.connect()
    conn.close()
    print('SUCCESS')
except Exception as e:
    print(f'FAILED: {e}')
" 2>&1 || echo "FAILED")
    
    if echo "$DB_TEST" | grep -q "SUCCESS"; then
        check_passed "Database connectivity test successful"
    else
        check_failed "Database connectivity test failed: $DB_TEST"
    fi
fi

echo

# ============================================================================
# Test 6: Check Database Schema
# ============================================================================
log_info "Test 6: Checking database schema..."

if [[ -n "$POD_NAME" ]]; then
    TABLES_CHECK=$(kubectl exec -n "$NAMESPACE" "$POD_NAME" -- python3 -c "
from app.database import engine
from sqlalchemy import inspect
inspector = inspect(engine)
tables = inspector.get_table_names()
required = ['experiments', 'assignments', 'events']
missing = [t for t in required if t not in tables]
if not missing:
    print('SUCCESS')
else:
    print(f'MISSING: {missing}')
" 2>&1 || echo "FAILED")
    
    if echo "$TABLES_CHECK" | grep -q "SUCCESS"; then
        check_passed "Database schema tables exist (experiments, assignments, events)"
    else
        check_failed "Database schema incomplete: $TABLES_CHECK"
    fi
fi

echo

# ============================================================================
# Test 7: Check Prometheus Metrics
# ============================================================================
log_info "Test 7: Checking Prometheus metrics..."

if [[ -n "$POD_NAME" ]]; then
    METRICS_RESPONSE=$(kubectl exec -n "$NAMESPACE" "$POD_NAME" -- curl -s http://localhost:8000/metrics || echo "failed")
    
    if echo "$METRICS_RESPONSE" | grep -q "experimentation_experiments_total"; then
        check_passed "Prometheus metric 'experimentation_experiments_total' found"
    else
        check_failed "Prometheus metric 'experimentation_experiments_total' not found"
    fi
    
    if echo "$METRICS_RESPONSE" | grep -q "experimentation_variant_assignments_total"; then
        check_passed "Prometheus metric 'experimentation_variant_assignments_total' found"
    else
        check_failed "Prometheus metric 'experimentation_variant_assignments_total' not found"
    fi
    
    if echo "$METRICS_RESPONSE" | grep -q "experimentation_events_total"; then
        check_passed "Prometheus metric 'experimentation_events_total' found"
    else
        check_failed "Prometheus metric 'experimentation_events_total' not found"
    fi
fi

echo

# ============================================================================
# Test 8: Check ServiceMonitor
# ============================================================================
log_info "Test 8: Checking ServiceMonitor for Prometheus..."

if kubectl get servicemonitor experimentation -n "$NAMESPACE" &>/dev/null; then
    check_passed "ServiceMonitor for Prometheus exists"
else
    check_failed "ServiceMonitor for Prometheus not found"
fi

echo

# ============================================================================
# Test 9: Check Resource Usage
# ============================================================================
log_info "Test 9: Checking resource usage (<70% target)..."

PODS=$(kubectl get pods -n "$NAMESPACE" -l app=experimentation -o json)
POD_NAMES=$(echo "$PODS" | jq -r '.items[].metadata.name')

for POD in $POD_NAMES; do
    METRICS=$(kubectl top pod "$POD" -n "$NAMESPACE" --no-headers 2>/dev/null || echo "0m 0Mi")
    CPU=$(echo "$METRICS" | awk '{print $2}' | sed 's/m//')
    MEMORY=$(echo "$METRICS" | awk '{print $3}' | sed 's/Mi//')
    
    # Get requests
    CPU_REQUEST=$(kubectl get pod "$POD" -n "$NAMESPACE" -o json | jq -r '.spec.containers[0].resources.requests.cpu' | sed 's/m//')
    MEMORY_REQUEST=$(kubectl get pod "$POD" -n "$NAMESPACE" -o json | jq -r '.spec.containers[0].resources.requests.memory' | sed 's/Mi//')
    
    if [[ "$CPU" -gt 0 ]] && [[ "$CPU_REQUEST" -gt 0 ]]; then
        CPU_PCT=$((CPU * 100 / CPU_REQUEST))
        if [[ "$CPU_PCT" -lt 70 ]]; then
            check_passed "Pod $POD CPU usage: ${CPU_PCT}% (<70%)"
        else
            check_failed "Pod $POD CPU usage: ${CPU_PCT}% (>=70%)"
        fi
    fi
    
    if [[ "$MEMORY" -gt 0 ]] && [[ "$MEMORY_REQUEST" -gt 0 ]]; then
        MEMORY_PCT=$((MEMORY * 100 / MEMORY_REQUEST))
        if [[ "$MEMORY_PCT" -lt 70 ]]; then
            check_passed "Pod $POD memory usage: ${MEMORY_PCT}% (<70%)"
        else
            check_failed "Pod $POD memory usage: ${MEMORY_PCT}% (>=70%)"
        fi
    fi
done

echo

# ============================================================================
# Test 10: Check PodDisruptionBudget
# ============================================================================
log_info "Test 10: Checking PodDisruptionBudget..."

if kubectl get pdb experimentation -n "$NAMESPACE" &>/dev/null; then
    MIN_AVAILABLE=$(kubectl get pdb experimentation -n "$NAMESPACE" -o jsonpath='{.spec.minAvailable}')
    check_passed "PodDisruptionBudget exists (minAvailable: $MIN_AVAILABLE)"
else
    check_failed "PodDisruptionBudget not found"
fi

echo

# ============================================================================
# Summary
# ============================================================================
log_info "====================================================================="
log_info "Validation Summary"
log_info "====================================================================="
echo -e "${GREEN}Passed:${NC} $TESTS_PASSED"
echo -e "${RED}Failed:${NC} $TESTS_FAILED"
echo

if [[ "$TESTS_FAILED" -eq 0 ]]; then
    log_info "✅ AT-E3-012: Experimentation Framework validation PASSED"
    exit 0
else
    log_error "❌ AT-E3-012: Experimentation Framework validation FAILED"
    exit 1
fi
