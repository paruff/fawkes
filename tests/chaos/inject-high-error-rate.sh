#!/bin/bash
# Chaos test script to inject high error rate for anomaly detection testing

set -e

echo "🔥 Starting chaos test: Injecting high error rate"

# Configuration
NAMESPACE="${NAMESPACE:-fawkes}"
DURATION="${DURATION:-300}"  # 5 minutes
ERROR_RATE="${ERROR_RATE:-0.5}"  # 50% error rate

echo "Configuration:"
echo "  Namespace: $NAMESPACE"
echo "  Duration: ${DURATION}s"
echo "  Error Rate: ${ERROR_RATE}"

echo ""
echo "📊 Simulating high error rate..."
echo "💡 In a real scenario, this would call actual endpoints"
echo ""
echo "🔍 Check for detected anomalies:"
echo "   curl http://anomaly-detection.local/api/v1/anomalies"
echo ""
echo "✅ Chaos test script ready"
