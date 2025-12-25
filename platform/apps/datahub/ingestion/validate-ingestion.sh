#!/bin/bash
# ==============================================================================
# FILE: platform/apps/datahub/ingestion/validate-ingestion.sh
# PURPOSE: Validate DataHub ingestion configuration and automated jobs
# USAGE: ./validate-ingestion.sh [--namespace fawkes]
# ==============================================================================

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
NAMESPACE="fawkes"
DATAHUB_GMS_URL="http://datahub-datahub-gms.${NAMESPACE}.svc:8080"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --namespace)
      NAMESPACE="$2"
      shift 2
      ;;
    --help)
      echo "Usage: $0 [--namespace NAMESPACE]"
      echo ""
      echo "Options:"
      echo "  --namespace   Kubernetes namespace (default: fawkes)"
      echo "  --help        Show this help message"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

echo -e "${BLUE}==============================================================================${NC}"
echo -e "${BLUE}DataHub Ingestion Validation${NC}"
echo -e "${BLUE}==============================================================================${NC}"
echo ""
echo "Namespace: $NAMESPACE"
echo ""

# Track overall status
VALIDATION_FAILED=0

# Function to print test result
print_result() {
  local test_name=$1
  local result=$2
  local details=$3

  if [ "$result" = "PASS" ]; then
    echo -e "  ${GREEN}✓${NC} $test_name"
    [ -n "$details" ] && echo -e "    ${details}"
  elif [ "$result" = "WARN" ]; then
    echo -e "  ${YELLOW}⚠${NC} $test_name"
    [ -n "$details" ] && echo -e "    ${details}"
  else
    echo -e "  ${RED}✗${NC} $test_name"
    [ -n "$details" ] && echo -e "    ${details}"
    VALIDATION_FAILED=1
  fi
}

# ==============================================================================
# Test 1: Check DataHub GMS is running
# ==============================================================================
echo -e "${BLUE}1. DataHub GMS Status${NC}"

if kubectl get pods -n "$NAMESPACE" -l app.kubernetes.io/name=datahub,app.kubernetes.io/component=datahub-gms -o jsonpath='{.items[0].status.phase}' 2> /dev/null | grep -q "Running"; then
  print_result "DataHub GMS pod is running" "PASS"

  # Check GMS health endpoint
  if kubectl exec -n "$NAMESPACE" deployment/datahub-datahub-gms -- curl -f -s http://localhost:8080/health > /dev/null 2>&1; then
    print_result "DataHub GMS health endpoint is accessible" "PASS"
  else
    print_result "DataHub GMS health endpoint is not accessible" "FAIL"
  fi
else
  print_result "DataHub GMS pod is not running" "FAIL"
fi
echo ""

# ==============================================================================
# Test 2: Check CronJobs are deployed
# ==============================================================================
echo -e "${BLUE}2. Ingestion CronJobs${NC}"

CRONJOBS=(
  "datahub-postgres-ingestion:PostgreSQL ingestion (daily)"
  "datahub-kubernetes-ingestion:Kubernetes ingestion (hourly)"
  "datahub-git-ci-ingestion:Git/CI ingestion (6-hourly)"
)

for cronjob_info in "${CRONJOBS[@]}"; do
  IFS=':' read -r cronjob_name description <<< "$cronjob_info"

  if kubectl get cronjob "$cronjob_name" -n "$NAMESPACE" &> /dev/null; then
    schedule=$(kubectl get cronjob "$cronjob_name" -n "$NAMESPACE" -o jsonpath='{.spec.schedule}')
    print_result "$description CronJob exists" "PASS" "Schedule: $schedule"
  else
    print_result "$description CronJob exists" "FAIL"
  fi
done
echo ""

# ==============================================================================
# Test 3: Check Secrets are configured
# ==============================================================================
echo -e "${BLUE}3. Ingestion Secrets${NC}"

SECRETS=(
  "datahub-postgres-ingestion-credentials:PostgreSQL credentials"
  "datahub-git-ci-ingestion-credentials:Git/CI credentials"
)

for secret_info in "${SECRETS[@]}"; do
  IFS=':' read -r secret_name description <<< "$secret_info"

  if kubectl get secret "$secret_name" -n "$NAMESPACE" &> /dev/null; then
    print_result "$description secret exists" "PASS"
  else
    print_result "$description secret exists" "FAIL"
  fi
done
echo ""

# ==============================================================================
# Test 4: Check ConfigMaps are deployed
# ==============================================================================
echo -e "${BLUE}4. Ingestion ConfigMaps${NC}"

CONFIGMAPS=(
  "datahub-postgres-ingestion-config:PostgreSQL ingestion config"
  "datahub-kubernetes-ingestion-config:Kubernetes ingestion config"
  "datahub-git-ci-ingestion-config:Git/CI ingestion config"
)

for cm_info in "${CONFIGMAPS[@]}"; do
  IFS=':' read -r cm_name description <<< "$cm_info"

  if kubectl get configmap "$cm_name" -n "$NAMESPACE" &> /dev/null; then
    print_result "$description exists" "PASS"
  else
    print_result "$description exists" "FAIL"
  fi
done
echo ""

# ==============================================================================
# Test 5: Check ServiceAccounts and RBAC
# ==============================================================================
echo -e "${BLUE}5. RBAC Configuration${NC}"

if kubectl get serviceaccount datahub-ingestion -n "$NAMESPACE" &> /dev/null; then
  print_result "Ingestion ServiceAccount exists" "PASS"
else
  print_result "Ingestion ServiceAccount exists" "FAIL"
fi

if kubectl get serviceaccount datahub-k8s-ingestion -n "$NAMESPACE" &> /dev/null; then
  print_result "Kubernetes ingestion ServiceAccount exists" "PASS"
else
  print_result "Kubernetes ingestion ServiceAccount exists" "FAIL"
fi

if kubectl get clusterrole datahub-k8s-ingestion &> /dev/null; then
  print_result "Kubernetes ingestion ClusterRole exists" "PASS"
else
  print_result "Kubernetes ingestion ClusterRole exists" "FAIL"
fi

if kubectl get clusterrolebinding datahub-k8s-ingestion &> /dev/null; then
  print_result "Kubernetes ingestion ClusterRoleBinding exists" "PASS"
else
  print_result "Kubernetes ingestion ClusterRoleBinding exists" "FAIL"
fi
echo ""

# ==============================================================================
# Test 6: Check recent job runs
# ==============================================================================
echo -e "${BLUE}6. Recent Ingestion Jobs${NC}"

for cronjob_info in "${CRONJOBS[@]}"; do
  IFS=':' read -r cronjob_name description <<< "$cronjob_info"

  if kubectl get cronjob "$cronjob_name" -n "$NAMESPACE" &> /dev/null; then
    # Get the most recent job
    latest_job=$(kubectl get jobs -n "$NAMESPACE" -l cronjob="$cronjob_name" --sort-by=.metadata.creationTimestamp -o jsonpath='{.items[-1].metadata.name}' 2> /dev/null)

    if [ -n "$latest_job" ]; then
      job_status=$(kubectl get job "$latest_job" -n "$NAMESPACE" -o jsonpath='{.status.conditions[0].type}' 2> /dev/null)

      if [ "$job_status" = "Complete" ]; then
        print_result "$description - Latest job completed" "PASS" "Job: $latest_job"
      elif [ "$job_status" = "Failed" ]; then
        print_result "$description - Latest job failed" "WARN" "Job: $latest_job"
      else
        print_result "$description - No completed jobs yet" "WARN" "This is normal if CronJobs were just deployed"
      fi
    else
      print_result "$description - No jobs found" "WARN" "CronJob has not run yet"
    fi
  fi
done
echo ""

# ==============================================================================
# Test 7: Verify database connectivity
# ==============================================================================
echo -e "${BLUE}7. Database Connectivity${NC}"

DATABASES=(
  "db-backstage-dev-rw.${NAMESPACE}.svc.cluster.local:5432:Backstage DB"
  "db-harbor-dev-rw.${NAMESPACE}.svc.cluster.local:5432:Harbor DB"
  "db-sonarqube-dev-rw.${NAMESPACE}.svc.cluster.local:5432:SonarQube DB"
)

for db_info in "${DATABASES[@]}"; do
  IFS=':' read -r db_host db_port description <<< "$db_info"

  # Try to connect using a temporary pod
  if kubectl run --rm -i --restart=Never --image=postgres:16 test-db-conn-$RANDOM -n "$NAMESPACE" -- \
    timeout 5 bash -c "pg_isready -h $db_host -p $db_port" &> /dev/null; then
    print_result "$description is reachable" "PASS"
  else
    print_result "$description is reachable" "WARN" "Connection test failed - may be normal if DB is not deployed"
  fi
done
echo ""

# ==============================================================================
# Test 8: Check ingestion recipe files
# ==============================================================================
echo -e "${BLUE}8. Ingestion Recipe Files${NC}"

RECIPE_DIR="$(dirname "$0")"
RECIPES=(
  "$RECIPE_DIR/postgres.yaml:PostgreSQL recipe"
  "$RECIPE_DIR/kubernetes.yaml:Kubernetes recipe"
  "$RECIPE_DIR/github-jenkins.yaml:GitHub/Jenkins recipe"
)

for recipe_info in "${RECIPES[@]}"; do
  IFS=':' read -r recipe_path description <<< "$recipe_info"

  if [ -f "$recipe_path" ]; then
    print_result "$description file exists" "PASS"
  else
    print_result "$description file exists" "FAIL"
  fi
done
echo ""

# ==============================================================================
# Summary
# ==============================================================================
echo -e "${BLUE}==============================================================================${NC}"
if [ $VALIDATION_FAILED -eq 0 ]; then
  echo -e "${GREEN}✓ All validations passed!${NC}"
  echo ""
  echo "Next steps:"
  echo "1. Wait for CronJobs to run (or manually trigger them)"
  echo "2. Check DataHub UI for ingested metadata: http://datahub.127.0.0.1.nip.io"
  echo "3. Verify metadata lineage is visible"
  echo ""
  echo "Manual trigger example:"
  echo "  kubectl create job --from=cronjob/datahub-postgres-ingestion -n $NAMESPACE manual-test-\$(date +%s)"
  exit 0
else
  echo -e "${RED}✗ Some validations failed${NC}"
  echo ""
  echo "Troubleshooting:"
  echo "1. Check pod logs: kubectl logs -n $NAMESPACE -l component=ingestion"
  echo "2. Describe failed resources: kubectl describe cronjob -n $NAMESPACE"
  echo "3. Verify DataHub is running: kubectl get pods -n $NAMESPACE -l app.kubernetes.io/name=datahub"
  exit 1
fi
