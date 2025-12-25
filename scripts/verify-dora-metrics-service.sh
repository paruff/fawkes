#!/usr/bin/env bash
# ============================================================================
# FILE: scripts/verify-dora-metrics-service.sh
# PURPOSE: Verify DORA Metrics Service (DevLake) deployment and functionality
# USAGE: ./scripts/verify-dora-metrics-service.sh
# ============================================================================

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
DEVLAKE_NAMESPACE="${DEVLAKE_NAMESPACE:-fawkes}"
MONITORING_NAMESPACE="${MONITORING_NAMESPACE:-monitoring}"

# Counters
PASSED=0
FAILED=0

# Helper functions
print_header() {
  echo ""
  echo "============================================"
  echo "$1"
  echo "============================================"
}

print_success() {
  echo -e "${GREEN}✓${NC} $1"
  ((PASSED++))
}

print_failure() {
  echo -e "${RED}✗${NC} $1"
  ((FAILED++))
}

print_warning() {
  echo -e "${YELLOW}⚠${NC} $1"
}

# Check function
check_condition() {
  local description="$1"
  local command="$2"

  if eval "$command" &> /dev/null; then
    print_success "$description"
    return 0
  else
    print_failure "$description"
    return 1
  fi
}

# ============================================================================
# 1. Check DevLake Deployment
# ============================================================================
print_header "1. Checking DevLake Deployment"

# Check namespace exists
check_condition "DevLake namespace exists" \
  "kubectl get namespace $DEVLAKE_NAMESPACE"

# Check ArgoCD Application
check_condition "DevLake ArgoCD Application exists" \
  "kubectl get application devlake -n fawkes"

# Check pods
echo ""
echo "Checking DevLake pods..."
PODS=(
  "app.kubernetes.io/name=devlake,app.kubernetes.io/component=lake"
  "app.kubernetes.io/name=devlake,app.kubernetes.io/component=ui"
  "app.kubernetes.io/name=devlake,app.kubernetes.io/component=grafana"
  "app.kubernetes.io/name=devlake,app.kubernetes.io/component=mysql"
)

for label in "${PODS[@]}"; do
  pod_name=$(echo "$label" | cut -d',' -f2 | cut -d'=' -f2)
  if kubectl get pods -n "$DEVLAKE_NAMESPACE" -l "$label" -o jsonpath='{.items[0].status.phase}' 2> /dev/null | grep -q "Running"; then
    print_success "DevLake $pod_name pod is running"
  else
    print_failure "DevLake $pod_name pod is not running"
    echo "  Debug: kubectl get pods -n $DEVLAKE_NAMESPACE -l $label"
  fi
done

# Check services
echo ""
echo "Checking DevLake services..."
SERVICES=("devlake-lake" "devlake-ui" "devlake-grafana" "devlake-mysql")

for svc in "${SERVICES[@]}"; do
  if kubectl get svc "$svc" -n "$DEVLAKE_NAMESPACE" &> /dev/null; then
    print_success "Service $svc exists"
  else
    print_failure "Service $svc does not exist"
  fi
done

# ============================================================================
# 2. Check Database Schema
# ============================================================================
print_header "2. Checking Database Schema"

# Check MySQL pod is ready
if kubectl get pods -n "$DEVLAKE_NAMESPACE" -l app.kubernetes.io/component=mysql -o jsonpath='{.items[0].status.phase}' | grep -q "Running"; then
  print_success "MySQL pod is running"

  # Get MySQL root password
  MYSQL_ROOT_PASSWORD=$(kubectl get secret devlake-db -n "$DEVLAKE_NAMESPACE" -o jsonpath='{.data.mysql-root-password}' 2> /dev/null | base64 -d || echo "")
  MYSQL_POD=$(kubectl get pods -n "$DEVLAKE_NAMESPACE" -l app.kubernetes.io/component=mysql -o jsonpath='{.items[0].metadata.name}')

  if [ -n "$MYSQL_ROOT_PASSWORD" ] && [ -n "$MYSQL_POD" ]; then
    # Check if database exists
    DB_CHECK=$(kubectl exec -n "$DEVLAKE_NAMESPACE" "$MYSQL_POD" -- \
      mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "SHOW DATABASES LIKE 'lake';" 2> /dev/null | grep -c "lake" || echo "0")

    if [ "$DB_CHECK" -gt 0 ]; then
      print_success "Database 'lake' exists"

      # Check key tables
      TABLES=("deployments" "commits" "incidents" "cicd_deployments" "project_metric_settings")
      for table in "${TABLES[@]}"; do
        TABLE_CHECK=$(kubectl exec -n "$DEVLAKE_NAMESPACE" "$MYSQL_POD" -- \
          mysql -u root -p"${MYSQL_ROOT_PASSWORD}" lake -e "SHOW TABLES LIKE '$table';" 2> /dev/null | grep -c "$table" || echo "0")

        if [ "$TABLE_CHECK" -gt 0 ]; then
          print_success "Table '$table' exists"
        else
          print_failure "Table '$table' does not exist"
        fi
      done
    else
      print_failure "Database 'lake' does not exist"
    fi
  else
    print_warning "MySQL credentials not available, skipping database schema checks"
    echo "  To check manually: kubectl exec -n $DEVLAKE_NAMESPACE \$MYSQL_POD -- mysql -u root -p"
  fi
else
  print_failure "MySQL pod is not running, skipping database checks"
fi

# ============================================================================
# 3. Check API Endpoints
# ============================================================================
print_header "3. Checking API Endpoints"

# Check if DevLake API is accessible
DEVLAKE_POD=$(kubectl get pods -n "$DEVLAKE_NAMESPACE" -l app.kubernetes.io/component=lake -o jsonpath='{.items[0].metadata.name}' 2> /dev/null || echo "")

if [ -n "$DEVLAKE_POD" ]; then
  print_success "DevLake API pod found: $DEVLAKE_POD"

  # Check health endpoint
  HEALTH_CHECK=$(kubectl exec -n "$DEVLAKE_NAMESPACE" "$DEVLAKE_POD" -- curl -s http://localhost:8080/api/ping 2> /dev/null || echo "")
  if echo "$HEALTH_CHECK" | grep -q "pong"; then
    print_success "API health endpoint responds"
  else
    print_failure "API health endpoint not responding"
    echo "  Debug: kubectl exec -n $DEVLAKE_NAMESPACE $DEVLAKE_POD -- curl http://localhost:8080/api/ping"
  fi

  # Check metrics endpoint
  METRICS_CHECK=$(kubectl exec -n "$DEVLAKE_NAMESPACE" "$DEVLAKE_POD" -- curl -s http://localhost:8080/metrics 2> /dev/null || echo "")
  if echo "$METRICS_CHECK" | grep -q "dora"; then
    print_success "Prometheus metrics endpoint exposes DORA metrics"
  else
    print_warning "Prometheus metrics endpoint accessible but may not expose DORA metrics yet"
  fi

  # Check GraphQL endpoint
  GRAPHQL_CHECK=$(kubectl exec -n "$DEVLAKE_NAMESPACE" "$DEVLAKE_POD" -- curl -s -X POST http://localhost:8080/api/graphql -H "Content-Type: application/json" -d '{"query":"{ __schema { types { name } } }"}' 2> /dev/null || echo "")
  if echo "$GRAPHQL_CHECK" | grep -q "types"; then
    print_success "GraphQL API endpoint responds"
  else
    print_failure "GraphQL API endpoint not responding"
  fi
else
  print_failure "DevLake API pod not found"
fi

# ============================================================================
# 4. Check Prometheus Integration
# ============================================================================
print_header "4. Checking Prometheus Integration"

# Check ServiceMonitor exists
check_condition "DevLake ServiceMonitor exists" \
  "kubectl get servicemonitor devlake-metrics -n $MONITORING_NAMESPACE"

# Check if Prometheus is scraping DevLake
if kubectl get pods -n "$MONITORING_NAMESPACE" -l app.kubernetes.io/name=prometheus &> /dev/null; then
  PROM_POD=$(kubectl get pods -n "$MONITORING_NAMESPACE" -l app.kubernetes.io/name=prometheus -o jsonpath='{.items[0].metadata.name}' 2> /dev/null)
  if [ -n "$PROM_POD" ]; then
    print_success "Prometheus pod found: $PROM_POD"

    # Check if DevLake target exists in Prometheus
    echo ""
    print_warning "Manual check required: Verify DevLake target in Prometheus UI"
    echo "  1. Port-forward: kubectl port-forward -n $MONITORING_NAMESPACE svc/prometheus-kube-prometheus-prometheus 9090:9090"
    echo "  2. Open: http://localhost:9090/targets"
    echo "  3. Search for 'devlake' target"
  else
    print_warning "Prometheus pod not found"
  fi
else
  print_warning "Prometheus not deployed, skipping Prometheus integration checks"
fi

# ============================================================================
# 5. Check Ingress Configuration
# ============================================================================
print_header "5. Checking Ingress Configuration"

# Check DevLake ingress
INGRESSES=("devlake" "devlake-grafana")
for ingress in "${INGRESSES[@]}"; do
  if kubectl get ingress "$ingress" -n "$DEVLAKE_NAMESPACE" &> /dev/null; then
    print_success "Ingress $ingress exists"

    # Get ingress host
    HOST=$(kubectl get ingress "$ingress" -n "$DEVLAKE_NAMESPACE" -o jsonpath='{.spec.rules[0].host}' 2> /dev/null)
    if [ -n "$HOST" ]; then
      echo "  Host: http://$HOST"
    fi
  else
    print_warning "Ingress $ingress does not exist (optional)"
  fi
done

# ============================================================================
# 6. Check Data Source Configuration
# ============================================================================
print_header "6. Checking Data Source Configuration"

# Check ConfigMap for data sources
if kubectl get configmap devlake-data-sources -n "$DEVLAKE_NAMESPACE" &> /dev/null; then
  print_success "DevLake data sources ConfigMap exists"

  # Check if GitHub, ArgoCD, Jenkins are configured
  CONFIG=$(kubectl get configmap devlake-data-sources -n "$DEVLAKE_NAMESPACE" -o yaml 2> /dev/null || echo "")

  for source in "github" "argocd" "jenkins" "webhook"; do
    if echo "$CONFIG" | grep -iq "$source"; then
      print_success "Data source '$source' is configured"
    else
      print_warning "Data source '$source' may not be configured"
    fi
  done
else
  print_warning "DevLake data sources ConfigMap not found"
  echo "  Expected: kubectl get configmap devlake-data-sources -n $DEVLAKE_NAMESPACE"
fi

# ============================================================================
# 7. Check Grafana Dashboards
# ============================================================================
print_header "7. Checking Grafana Dashboards"

# Check if Grafana is accessible
GRAFANA_POD=$(kubectl get pods -n "$DEVLAKE_NAMESPACE" -l app.kubernetes.io/component=grafana -o jsonpath='{.items[0].metadata.name}' 2> /dev/null || echo "")

if [ -n "$GRAFANA_POD" ]; then
  print_success "Grafana pod found: $GRAFANA_POD"

  # Check Grafana health
  GRAFANA_HEALTH=$(kubectl exec -n "$DEVLAKE_NAMESPACE" "$GRAFANA_POD" -- curl -s http://localhost:3000/api/health 2> /dev/null || echo "")
  if echo "$GRAFANA_HEALTH" | grep -q "ok"; then
    print_success "Grafana health check passed"
  else
    print_failure "Grafana health check failed"
  fi

  echo ""
  print_warning "Manual check required: Verify DORA dashboards in Grafana UI"
  echo "  1. Get Grafana password: kubectl get secret -n $DEVLAKE_NAMESPACE devlake-grafana-secrets -o jsonpath='{.data.admin-password}' | base64 -d"
  echo "  2. Access Grafana: http://devlake-grafana.127.0.0.1.nip.io (or port-forward)"
  echo "  3. Check for DORA Metrics dashboards"
else
  print_warning "Grafana pod not found"
fi

# ============================================================================
# Summary
# ============================================================================
print_header "Verification Summary"

echo ""
echo -e "${GREEN}Passed: $PASSED${NC}"
echo -e "${RED}Failed: $FAILED${NC}"
echo ""

if [ $FAILED -eq 0 ]; then
  echo -e "${GREEN}✓ DORA Metrics Service verification completed successfully!${NC}"
  echo ""
  echo "Next steps:"
  echo "  1. Configure data sources in DevLake UI: http://devlake.127.0.0.1.nip.io"
  echo "  2. View DORA metrics in Grafana: http://devlake-grafana.127.0.0.1.nip.io"
  echo "  3. Query metrics via API: http://devlake.127.0.0.1.nip.io/api"
  echo ""
  exit 0
else
  echo -e "${RED}✗ DORA Metrics Service verification found $FAILED issues${NC}"
  echo ""
  echo "Troubleshooting:"
  echo "  1. Check pod logs: kubectl logs -n $DEVLAKE_NAMESPACE -l app.kubernetes.io/name=devlake"
  echo "  2. Check ArgoCD sync: kubectl get application devlake -n fawkes -o yaml"
  echo "  3. Check events: kubectl get events -n $DEVLAKE_NAMESPACE --sort-by='.lastTimestamp'"
  echo ""
  exit 1
fi
