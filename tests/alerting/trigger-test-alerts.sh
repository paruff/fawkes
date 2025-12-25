#!/bin/bash
# Script to trigger test alerts for validation

set -e

SMART_ALERTING_URL="${SMART_ALERTING_URL:-http://smart-alerting.fawkes.local}"

# Check for jq
if ! command -v jq &> /dev/null; then
  echo "Warning: jq is not installed. Output will not be formatted."
  JQ_AVAILABLE=false
else
  JQ_AVAILABLE=true
fi

echo "🔔 Triggering test alerts to Smart Alerting Service"
echo "Target: $SMART_ALERTING_URL"
echo ""

# Function to send alert
send_alert() {
  local alertname="$1"
  local service="$2"
  local severity="$3"
  local summary="$4"

  echo "Sending alert: $alertname (severity: $severity, service: $service)"

  response=$(curl -X POST "$SMART_ALERTING_URL/api/v1/alerts/generic" \
    -H "Content-Type: application/json" \
    -d "{
            \"alerts\": [{
                \"labels\": {
                    \"alertname\": \"$alertname\",
                    \"service\": \"$service\",
                    \"severity\": \"$severity\",
                    \"namespace\": \"fawkes\"
                },
                \"annotations\": {
                    \"summary\": \"$summary\",
                    \"description\": \"Test alert for validation\"
                },
                \"startsAt\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",
                \"status\": \"firing\"
            }]
        }" \
    --silent --show-error)

  if [ "$JQ_AVAILABLE" = true ]; then
    echo "$response" | jq .
  else
    echo "$response"
  fi

  echo ""
}

# Test 1: Send related alerts that should be grouped
echo "Test 1: Related alerts (should be grouped)"
echo "=========================================="
send_alert "HighErrorRate" "api-gateway" "critical" "Error rate above 5%"
sleep 1
send_alert "HighErrorRate" "api-gateway" "critical" "Error rate above 5%"
sleep 1
send_alert "HighErrorRate" "api-gateway" "critical" "Error rate above 5%"
sleep 2

# Test 2: Flapping alert (should be suppressed after 3 occurrences)
echo "Test 2: Flapping alert (should be suppressed)"
echo "=============================================="
send_alert "NetworkLatency" "frontend" "warning" "Network latency spike"
sleep 1
send_alert "NetworkLatency" "frontend" "warning" "Network latency spike"
sleep 1
send_alert "NetworkLatency" "frontend" "warning" "Network latency spike"
sleep 1
send_alert "NetworkLatency" "frontend" "warning" "Network latency spike"
sleep 2

# Test 3: Different severity levels
echo "Test 3: Different severity levels"
echo "=================================="
send_alert "CPUHigh" "backend" "critical" "CPU usage above 90%"
sleep 1
send_alert "MemoryHigh" "backend" "warning" "Memory usage above 80%"
sleep 1
send_alert "DiskSpaceLow" "backend" "info" "Disk space below 20%"
sleep 2

# Test 4: Multiple services
echo "Test 4: Multiple services (should be separate groups)"
echo "====================================================="
send_alert "DatabaseConnectionTimeout" "auth-service" "high" "Database connection timeout"
sleep 1
send_alert "DatabaseConnectionTimeout" "user-service" "high" "Database connection timeout"
sleep 1
send_alert "DatabaseConnectionTimeout" "payment-service" "high" "Database connection timeout"
sleep 2

echo "✅ Test alerts sent successfully!"
echo ""
echo "Verify results:"
if [ "$JQ_AVAILABLE" = true ]; then
  echo "  - View alert groups: curl $SMART_ALERTING_URL/api/v1/alert-groups | jq ."
  echo "  - View statistics: curl $SMART_ALERTING_URL/api/v1/stats | jq ."
  echo "  - View reduction: curl $SMART_ALERTING_URL/api/v1/stats/reduction | jq ."
else
  echo "  - View alert groups: curl $SMART_ALERTING_URL/api/v1/alert-groups"
  echo "  - View statistics: curl $SMART_ALERTING_URL/api/v1/stats"
  echo "  - View reduction: curl $SMART_ALERTING_URL/api/v1/stats/reduction"
fi
