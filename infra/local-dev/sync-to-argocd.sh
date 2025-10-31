#!/bin/bash
set -e

ENVIRONMENT="${1:-dev}"

echo "📝 Preparing to sync to GitOps for environment: $ENVIRONMENT"

# Validate manifests before commit
echo "Validating manifests..."
./infra/local-dev/validate.sh fawkes-local

# Run pre-commit checks
echo "Running pre-commit checks..."
pre-commit run --all-files

# Commit and push
echo "Committing changes..."
git add manifests/overlays/"$ENVIRONMENT"/
git commit -m "feat: update $ENVIRONMENT manifests [skip ci]"
git push origin main

echo "🔄 Waiting for ArgoCD to sync..."
argocd app wait fawkes-"$ENVIRONMENT" --timeout 300

echo "✅ Sync complete. Check ArgoCD: https://argocd.fawkes.io"