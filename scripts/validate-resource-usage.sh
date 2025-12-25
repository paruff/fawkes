#!/bin/bash

# ============================================================================
# FILE: scripts/validate-resource-usage.sh
# PURPOSE: Validate that cluster resource usage stays within 70% target
# USAGE: ./scripts/validate-resource-usage.sh [--namespace NAMESPACE]
# ============================================================================

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default values
NAMESPACE="${NAMESPACE:-fawkes}"
TARGET_CPU_PERCENT=70
TARGET_MEMORY_PERCENT=70
VERBOSE="${VERBOSE:-false}"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --namespace)
      NAMESPACE="$2"
      shift 2
      ;;
    --target-cpu)
      TARGET_CPU_PERCENT="$2"
      shift 2
      ;;
    --target-memory)
      TARGET_MEMORY_PERCENT="$2"
      shift 2
      ;;
    --verbose)
      VERBOSE=true
      shift
      ;;
    --help)
      echo "Usage: $0 [OPTIONS]"
      echo ""
      echo "Options:"
      echo "  --namespace NAMESPACE     Namespace to check (default: fawkes)"
      echo "  --target-cpu PERCENT      Target CPU usage percentage (default: 70)"
      echo "  --target-memory PERCENT   Target memory usage percentage (default: 70)"
      echo "  --verbose                 Enable verbose output"
      echo "  --help                    Show this help message"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      echo "Use --help for usage information"
      exit 1
      ;;
  esac
done

echo "========================================"
echo "Resource Usage Validation"
echo "========================================"
echo "Namespace: $NAMESPACE"
echo "Target CPU: ${TARGET_CPU_PERCENT}%"
echo "Target Memory: ${TARGET_MEMORY_PERCENT}%"
echo "========================================"
echo ""

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
  echo -e "${RED}✗ kubectl not found${NC}"
  exit 1
fi

# Check if namespace exists
if ! kubectl get namespace "$NAMESPACE" &> /dev/null; then
  echo -e "${RED}✗ Namespace $NAMESPACE not found${NC}"
  exit 1
fi

# Function to calculate percentage
calculate_percentage() {
  local used=$1
  local limit=$2

  # Convert to same units (millicores for CPU, Mi for memory)
  if [[ "$used" =~ m$ ]]; then
    used="${used%m}"
  elif [[ "$used" =~ ^[0-9]+$ ]]; then
    # Assume cores, convert to millicores
    used=$((used * 1000))
  fi

  if [[ "$limit" =~ m$ ]]; then
    limit="${limit%m}"
  elif [[ "$limit" =~ ^[0-9]+$ ]]; then
    # Assume cores, convert to millicores
    limit=$((limit * 1000))
  fi

  # Calculate percentage
  if [ "$limit" -gt 0 ]; then
    percentage=$((used * 100 / limit))
  else
    percentage=0
  fi

  echo "$percentage"
}

# Function to convert memory to Mi
convert_to_mi() {
  local value=$1

  if [[ "$value" =~ Gi$ ]]; then
    value="${value%Gi}"
    value=$((value * 1024))
  elif [[ "$value" =~ Mi$ ]]; then
    value="${value%Mi}"
  elif [[ "$value" =~ Ki$ ]]; then
    value="${value%Ki}"
    value=$((value / 1024))
  fi

  echo "$value"
}

# Get pod metrics
echo "Checking pod resource usage..."
echo ""

# Check if metrics-server is available
if ! kubectl top nodes &> /dev/null; then
  echo -e "${YELLOW}⚠ Metrics server not available, skipping pod metrics${NC}"
  echo -e "${YELLOW}  Install metrics-server for detailed resource monitoring${NC}"
  echo ""
  METRICS_AVAILABLE=false
else
  METRICS_AVAILABLE=true
fi

# Initialize counters
total_pods=0
pods_within_target=0
pods_exceed_target=0
cpu_violations=()
memory_violations=()

# Get pods in namespace
pods=$(kubectl get pods -n "$NAMESPACE" -o json | jq -r '.items[] | select(.status.phase=="Running") | .metadata.name')

if [ -z "$pods" ]; then
  echo -e "${YELLOW}⚠ No running pods found in namespace $NAMESPACE${NC}"
  exit 0
fi

for pod in $pods; do
  total_pods=$((total_pods + 1))

  if [ "$VERBOSE" = true ]; then
    echo "Checking pod: $pod"
  fi

  # Get pod resource requests and limits
  pod_json=$(kubectl get pod "$pod" -n "$NAMESPACE" -o json)

  # Extract container resource limits
  containers=$(echo "$pod_json" | jq -r '.spec.containers[] | .name')

  pod_has_violation=false

  for container in $containers; do
    cpu_limit=$(echo "$pod_json" | jq -r ".spec.containers[] | select(.name==\"$container\") | .resources.limits.cpu // empty")
    memory_limit=$(echo "$pod_json" | jq -r ".spec.containers[] | select(.name==\"$container\") | .resources.limits.memory // empty")
    cpu_request=$(echo "$pod_json" | jq -r ".spec.containers[] | select(.name==\"$container\") | .resources.requests.cpu // empty")
    memory_request=$(echo "$pod_json" | jq -r ".spec.containers[] | select(.name==\"$container\") | .resources.requests.memory // empty")

    # Check if limits are defined
    if [ -z "$cpu_limit" ] || [ -z "$memory_limit" ]; then
      if [ "$VERBOSE" = true ]; then
        echo -e "  ${YELLOW}⚠ Container $container has no resource limits${NC}"
      fi
      continue
    fi

    # Get current usage if metrics are available
    if [ "$METRICS_AVAILABLE" = true ]; then
      metrics=$(kubectl top pod "$pod" -n "$NAMESPACE" --containers 2> /dev/null | grep "$container" || echo "")

      if [ -n "$metrics" ]; then
        cpu_usage=$(echo "$metrics" | awk '{print $2}')
        memory_usage=$(echo "$metrics" | awk '{print $3}')

        # Calculate percentages
        cpu_percent=$(calculate_percentage "$cpu_usage" "$cpu_limit")
        memory_usage_mi=$(convert_to_mi "$memory_usage")
        memory_limit_mi=$(convert_to_mi "$memory_limit")
        memory_percent=$((memory_usage_mi * 100 / memory_limit_mi))

        if [ "$VERBOSE" = true ]; then
          echo "  Container: $container"
          echo "    CPU: ${cpu_usage}/${cpu_limit} (${cpu_percent}%)"
          echo "    Memory: ${memory_usage}/${memory_limit} (${memory_percent}%)"
        fi

        # Check if usage exceeds target
        if [ "$cpu_percent" -gt "$TARGET_CPU_PERCENT" ]; then
          cpu_violations+=("$pod/$container: ${cpu_percent}% CPU (${cpu_usage}/${cpu_limit})")
          pod_has_violation=true
        fi

        if [ "$memory_percent" -gt "$TARGET_MEMORY_PERCENT" ]; then
          memory_violations+=("$pod/$container: ${memory_percent}% Memory (${memory_usage}/${memory_limit})")
          pod_has_violation=true
        fi
      fi
    fi
  done

  if [ "$pod_has_violation" = true ]; then
    pods_exceed_target=$((pods_exceed_target + 1))
  else
    pods_within_target=$((pods_within_target + 1))
  fi
done

echo ""
echo "========================================"
echo "Summary"
echo "========================================"
echo "Total pods checked: $total_pods"
echo "Pods within target: $pods_within_target"
echo "Pods exceeding target: $pods_exceed_target"
echo ""

# Report violations
if [ ${#cpu_violations[@]} -gt 0 ]; then
  echo -e "${RED}CPU Violations (>${TARGET_CPU_PERCENT}%):${NC}"
  for violation in "${cpu_violations[@]}"; do
    echo -e "  ${RED}✗${NC} $violation"
  done
  echo ""
fi

if [ ${#memory_violations[@]} -gt 0 ]; then
  echo -e "${RED}Memory Violations (>${TARGET_MEMORY_PERCENT}%):${NC}"
  for violation in "${memory_violations[@]}"; do
    echo -e "  ${RED}✗${NC} $violation"
  done
  echo ""
fi

# Node-level resource check
echo "Checking node-level resource usage..."
echo ""

if [ "$METRICS_AVAILABLE" = true ]; then
  node_metrics=$(kubectl top nodes --no-headers)

  while IFS= read -r line; do
    node=$(echo "$line" | awk '{print $1}')
    cpu_usage=$(echo "$line" | awk '{print $2}')
    cpu_percent=$(echo "$line" | awk '{print $3}' | tr -d '%')
    memory_usage=$(echo "$line" | awk '{print $4}')
    memory_percent=$(echo "$line" | awk '{print $5}' | tr -d '%')

    echo "Node: $node"
    echo "  CPU: ${cpu_usage} (${cpu_percent}%)"
    echo "  Memory: ${memory_usage} (${memory_percent}%)"

    if [ "$cpu_percent" -gt "$TARGET_CPU_PERCENT" ]; then
      echo -e "  ${RED}✗ CPU usage exceeds target${NC}"
    else
      echo -e "  ${GREEN}✓ CPU usage within target${NC}"
    fi

    if [ "$memory_percent" -gt "$TARGET_MEMORY_PERCENT" ]; then
      echo -e "  ${RED}✗ Memory usage exceeds target${NC}"
    else
      echo -e "  ${GREEN}✓ Memory usage within target${NC}"
    fi
    echo ""
  done <<< "$node_metrics"
fi

# Check for pod evictions
echo "Checking for pod evictions..."
evicted_pods=$(kubectl get pods -n "$NAMESPACE" --field-selector=status.phase=Failed -o json | jq -r '.items[] | select(.status.reason=="Evicted") | .metadata.name' || echo "")

if [ -z "$evicted_pods" ]; then
  echo -e "${GREEN}✓ No evicted pods found${NC}"
else
  echo -e "${RED}✗ Evicted pods found:${NC}"
  echo "$evicted_pods"
fi

echo ""
echo "========================================"

# Exit with appropriate code
if [ ${#cpu_violations[@]} -gt 0 ] || [ ${#memory_violations[@]} -gt 0 ] || [ -n "$evicted_pods" ]; then
  echo -e "${RED}✗ Resource validation FAILED${NC}"
  exit 1
else
  echo -e "${GREEN}✓ Resource validation PASSED${NC}"
  exit 0
fi
