#!/usr/bin/env bash
# ============================================================================
# FILE: platform/apps/unleash/validate-unleash.sh
# PURPOSE: Quick validation script for Unleash deployment
# USAGE: ./validate-unleash.sh
# ============================================================================

set -euo pipefail

NAMESPACE="fawkes"

echo "🔍 Validating Unleash deployment..."
echo ""

# Check deployment
echo "✓ Checking Unleash deployment..."
kubectl get deployment unleash -n $NAMESPACE

# Check pods
echo ""
echo "✓ Checking Unleash pods..."
kubectl get pods -n $NAMESPACE -l app=unleash,component=feature-flags

# Check service
echo ""
echo "✓ Checking Unleash service..."
kubectl get svc unleash -n $NAMESPACE

# Check ingress
echo ""
echo "✓ Checking Unleash ingress..."
kubectl get ingress unleash -n $NAMESPACE

# Check database
echo ""
echo "✓ Checking PostgreSQL cluster..."
kubectl get cluster db-unleash-dev -n $NAMESPACE

# Check secrets
echo ""
echo "✓ Checking secrets..."
kubectl get secret unleash-secret -n $NAMESPACE
kubectl get secret db-unleash-credentials -n $NAMESPACE

# Port forward and health check
echo ""
echo "✓ Testing Unleash health endpoint..."
kubectl port-forward -n $NAMESPACE service/unleash 4242:4242 >/dev/null 2>&1 &
PID=$!
sleep 3

if curl -sf http://localhost:4242/health >/dev/null 2>&1; then
  echo "✅ Unleash health check passed"
else
  echo "❌ Unleash health check failed"
fi

kill $PID 2>/dev/null || true

echo ""
echo "✅ Validation complete!"
echo ""
echo "Access Unleash:"
echo "  UI:  https://unleash.fawkes.idp"
echo "  API: https://unleash.fawkes.idp/api"
echo ""
echo "Get admin password:"
echo "  kubectl get secret unleash-secret -n fawkes -o jsonpath='{.data.ADMIN_PASSWORD}' | base64 -d"
echo ""
