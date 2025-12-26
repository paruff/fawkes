#!/bin/bash
# Validation script for VSM service

set -euo pipefail

VSM_URL="${VSM_URL:-http://vsm-service.127.0.0.1.nip.io}"

echo "🔍 Validating VSM Service at $VSM_URL"
echo ""

# Test 1: Health check
echo "1️⃣  Testing health endpoint..."
HEALTH=$(curl -s "$VSM_URL/api/v1/health")
echo "   Response: $HEALTH"
STATUS=$(echo "$HEALTH" | jq -r '.status')
if [ "$STATUS" = "UP" ] || [ "$STATUS" = "DEGRADED" ]; then
  echo "   ✅ Health check passed"
else
  echo "   ❌ Health check failed"
  exit 1
fi
echo ""

# Test 2: Create work item
echo "2️⃣  Testing work item creation..."
WORK_ITEM=$(curl -s -X POST "$VSM_URL/api/v1/work-items" \
  -H "Content-Type: application/json" \
  -d '{"title": "Test feature", "type": "feature"}')
echo "   Response: $WORK_ITEM"
WORK_ITEM_ID=$(echo "$WORK_ITEM" | jq -r '.id')
if [ ! -z "$WORK_ITEM_ID" ] && [ "$WORK_ITEM_ID" != "null" ]; then
  echo "   ✅ Work item created: ID=$WORK_ITEM_ID"
else
  echo "   ❌ Work item creation failed"
  exit 1
fi
echo ""

# Test 3: Transition work item
echo "3️⃣  Testing stage transition..."
TRANSITION=$(curl -s -X PUT "$VSM_URL/api/v1/work-items/$WORK_ITEM_ID/transition" \
  -H "Content-Type: application/json" \
  -d '{"to_stage": "Development"}')
echo "   Response: $TRANSITION"
TO_STAGE=$(echo "$TRANSITION" | jq -r '.to_stage')
if [ "$TO_STAGE" = "Development" ]; then
  echo "   ✅ Work item transitioned to Development"
else
  echo "   ❌ Stage transition failed"
  exit 1
fi
echo ""

# Test 4: Get work item history
echo "4️⃣  Testing work item history..."
HISTORY=$(curl -s "$VSM_URL/api/v1/work-items/$WORK_ITEM_ID/history")
echo "   Response: $HISTORY"
TRANSITIONS=$(echo "$HISTORY" | jq -r '.transitions | length')
if [ "$TRANSITIONS" -ge "2" ]; then
  echo "   ✅ History retrieved: $TRANSITIONS transitions"
else
  echo "   ❌ History retrieval failed"
  exit 1
fi
echo ""

# Test 5: Get flow metrics
echo "5️⃣  Testing flow metrics..."
METRICS=$(curl -s "$VSM_URL/api/v1/metrics")
echo "   Response: $METRICS"
THROUGHPUT=$(echo "$METRICS" | jq -r '.throughput')
if [ ! -z "$THROUGHPUT" ] && [ "$THROUGHPUT" != "null" ]; then
  echo "   ✅ Flow metrics retrieved: throughput=$THROUGHPUT"
else
  echo "   ❌ Flow metrics retrieval failed"
  exit 1
fi
echo ""

# Test 6: List stages
echo "6️⃣  Testing stages listing..."
STAGES=$(curl -s "$VSM_URL/api/v1/stages")
echo "   Response: $STAGES"
STAGE_COUNT=$(echo "$STAGES" | jq '. | length')
if [ "$STAGE_COUNT" -ge "6" ]; then
  echo "   ✅ Stages listed: $STAGE_COUNT stages"
else
  echo "   ❌ Stages listing failed"
  exit 1
fi
echo ""

echo "✅ All validation tests passed!"
