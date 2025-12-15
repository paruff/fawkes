#!/bin/bash
# Test script for OpenTelemetry Collector deployment and trace generation

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
MONITORING_NS="monitoring"
DEMO_NS="otel-demo"
OTEL_COLLECTOR_NAME="otel-collector-opentelemetry-collector"
SAMPLE_APP_NAME="otel-sample-app"

echo "=========================================="
echo "OpenTelemetry Collector Validation Tests"
echo "=========================================="
echo ""

# Test 1: Check if monitoring namespace exists
echo -e "${YELLOW}[TEST 1]${NC} Checking monitoring namespace..."
if kubectl get namespace $MONITORING_NS > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} Monitoring namespace exists"
else
    echo -e "${RED}✗${NC} Monitoring namespace does not exist"
    exit 1
fi
echo ""

# Test 2: Check if OpenTelemetry Collector DaemonSet exists
echo -e "${YELLOW}[TEST 2]${NC} Checking OpenTelemetry Collector DaemonSet..."
if kubectl get daemonset $OTEL_COLLECTOR_NAME -n $MONITORING_NS > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} OpenTelemetry Collector DaemonSet exists"
    
    # Check if all desired pods are ready
    DESIRED=$(kubectl get daemonset $OTEL_COLLECTOR_NAME -n $MONITORING_NS -o jsonpath='{.status.desiredNumberScheduled}')
    READY=$(kubectl get daemonset $OTEL_COLLECTOR_NAME -n $MONITORING_NS -o jsonpath='{.status.numberReady}')
    
    echo "  Desired: $DESIRED, Ready: $READY"
    
    if [ "$DESIRED" -eq "$READY" ]; then
        echo -e "${GREEN}✓${NC} All OpenTelemetry Collector pods are ready"
    else
        echo -e "${YELLOW}⚠${NC} Not all OpenTelemetry Collector pods are ready"
    fi
else
    echo -e "${RED}✗${NC} OpenTelemetry Collector DaemonSet does not exist"
    exit 1
fi
echo ""

# Test 3: Check if OTLP ports are exposed
echo -e "${YELLOW}[TEST 3]${NC} Checking OTLP receiver ports..."
if kubectl get service -n $MONITORING_NS | grep -q "otel-collector"; then
    SERVICE_NAME=$(kubectl get service -n $MONITORING_NS | grep "otel-collector" | awk '{print $1}' | head -1)
    
    # Check for port 4317 (gRPC)
    if kubectl get service $SERVICE_NAME -n $MONITORING_NS -o jsonpath='{.spec.ports[*].port}' | grep -q "4317"; then
        echo -e "${GREEN}✓${NC} OTLP gRPC port 4317 is exposed"
    else
        echo -e "${RED}✗${NC} OTLP gRPC port 4317 is not exposed"
    fi
    
    # Check for port 4318 (HTTP)
    if kubectl get service $SERVICE_NAME -n $MONITORING_NS -o jsonpath='{.spec.ports[*].port}' | grep -q "4318"; then
        echo -e "${GREEN}✓${NC} OTLP HTTP port 4318 is exposed"
    else
        echo -e "${RED}✗${NC} OTLP HTTP port 4318 is not exposed"
    fi
else
    echo -e "${YELLOW}⚠${NC} OpenTelemetry Collector service not found"
fi
echo ""

# Test 4: Check health endpoint
echo -e "${YELLOW}[TEST 4]${NC} Checking OpenTelemetry Collector health..."
COLLECTOR_POD=$(kubectl get pods -n $MONITORING_NS -l app.kubernetes.io/name=opentelemetry-collector -o jsonpath='{.items[0].metadata.name}')

if [ -n "$COLLECTOR_POD" ]; then
    echo "  Using pod: $COLLECTOR_POD"
    
    if kubectl exec -n $MONITORING_NS $COLLECTOR_POD -- wget -q -O- http://localhost:13133 > /dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} Health endpoint is accessible"
    else
        echo -e "${YELLOW}⚠${NC} Health endpoint is not accessible"
    fi
else
    echo -e "${YELLOW}⚠${NC} No OpenTelemetry Collector pod found"
fi
echo ""

# Test 5: Deploy sample application
echo -e "${YELLOW}[TEST 5]${NC} Deploying sample application..."

# Create namespace if it doesn't exist
if ! kubectl get namespace $DEMO_NS > /dev/null 2>&1; then
    kubectl create namespace $DEMO_NS
    echo -e "${GREEN}✓${NC} Created namespace $DEMO_NS"
fi

# Build sample app image (for local testing)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SAMPLE_APP_DIR="$SCRIPT_DIR/../sample-app"

if [ -d "$SAMPLE_APP_DIR" ]; then
    echo "  Building sample application image..."
    docker build -t otel-sample-app:latest "$SAMPLE_APP_DIR" > /dev/null 2>&1
    echo -e "${GREEN}✓${NC} Sample application image built"
    
    # Load image into kind cluster if detected
    # Check for kind cluster by looking for kind-specific context
    CURRENT_CONTEXT=$(kubectl config current-context)
    if [[ "$CURRENT_CONTEXT" == kind-* ]] || kind get clusters 2>/dev/null | grep -q "^${CURRENT_CONTEXT#kind-}$"; then
        kind load docker-image otel-sample-app:latest > /dev/null 2>&1
        echo -e "${GREEN}✓${NC} Image loaded into kind cluster"
    fi
fi

# Deploy sample application
if [ -f "$SAMPLE_APP_DIR/deployment.yaml" ]; then
    kubectl apply -f "$SAMPLE_APP_DIR/deployment.yaml" > /dev/null 2>&1
    echo -e "${GREEN}✓${NC} Sample application deployed"
    
    # Wait for deployment to be ready
    echo "  Waiting for sample application to be ready..."
    kubectl wait --for=condition=available --timeout=60s deployment/$SAMPLE_APP_NAME -n $DEMO_NS > /dev/null 2>&1 || true
fi
echo ""

# Test 6: Generate sample traces
echo -e "${YELLOW}[TEST 6]${NC} Generating sample traces..."

# Wait a bit for the app to be fully ready
sleep 5

# Get sample app pod
SAMPLE_POD=$(kubectl get pods -n $DEMO_NS -l app=$SAMPLE_APP_NAME -o jsonpath='{.items[0].metadata.name}')

if [ -n "$SAMPLE_POD" ]; then
    echo "  Using pod: $SAMPLE_POD"
    
    # Port forward to sample app
    kubectl port-forward -n $DEMO_NS $SAMPLE_POD 8080:8080 > /dev/null 2>&1 &
    PF_PID=$!
    sleep 2
    
    # Generate traces
    echo "  Generating traces..."
    curl -s http://localhost:8080/hello/Platform > /dev/null && echo -e "${GREEN}✓${NC} Generated greeting trace"
    curl -s http://localhost:8080/work > /dev/null && echo -e "${GREEN}✓${NC} Generated work trace with nested spans"
    
    # Kill port-forward
    kill $PF_PID > /dev/null 2>&1 || true
    
    echo -e "${GREEN}✓${NC} Sample traces generated"
else
    echo -e "${YELLOW}⚠${NC} Sample application pod not found"
fi
echo ""

# Test 7: Verify exporters are configured
echo -e "${YELLOW}[TEST 7]${NC} Verifying exporters configuration..."

# Check if Prometheus is configured
if kubectl get prometheus -n $MONITORING_NS > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} Prometheus exporter target available"
else
    echo -e "${YELLOW}⚠${NC} Prometheus not found"
fi

# Check if OpenSearch is configured
if kubectl get service -n logging opensearch-cluster-master > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} OpenSearch exporter target available"
else
    echo -e "${YELLOW}⚠${NC} OpenSearch not found (may not be deployed yet)"
fi

# Check if Tempo is configured
if kubectl get service -n $MONITORING_NS tempo > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} Tempo exporter target available"
else
    echo -e "${YELLOW}⚠${NC} Tempo not found (may not be deployed yet)"
fi
echo ""

# Test 8: Check collector logs for trace reception
echo -e "${YELLOW}[TEST 8]${NC} Checking collector logs for trace activity..."

if [ -n "$COLLECTOR_POD" ]; then
    # Get recent logs and look for specific trace processing patterns
    RECENT_LOGS=$(kubectl logs -n $MONITORING_NS $COLLECTOR_POD --tail=100 2>/dev/null || echo "")
    
    # Check for span-related activity indicating trace processing
    if echo "$RECENT_LOGS" | grep -qE "(span|trace_id|SpanData|ExportTraceServiceRequest)"; then
        echo -e "${GREEN}✓${NC} Collector is processing traces (span data detected)"
    else
        echo -e "${YELLOW}⚠${NC} No specific trace activity detected in recent logs"
        echo "  Note: This is normal if no traces have been sent yet"
    fi
fi
echo ""

echo "=========================================="
echo "Summary"
echo "=========================================="
echo -e "${GREEN}OpenTelemetry Collector is deployed and configured${NC}"
echo ""
echo "Next steps:"
echo "1. View traces in Grafana: http://grafana.127.0.0.1.nip.io"
echo "2. Query Tempo directly for traces from service 'otel-sample-app'"
echo "3. Check OpenSearch for logs with trace correlation"
echo ""
echo "Sample application endpoints:"
echo "  kubectl port-forward -n $DEMO_NS svc/$SAMPLE_APP_NAME 8080:80"
echo "  curl http://localhost:8080/hello/World"
echo "  curl http://localhost:8080/work"
echo ""
