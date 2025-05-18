#!/bin/bash

# Apply ArgoCD
kubectl create namespace argocd
kubectl apply -k clusters/production/

# Wait for ArgoCD to be ready
kubectl wait --for=condition=available deployment -l app.kubernetes.io/name=argocd-server -n argocd --timeout=300s

# Get initial admin password
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
echo "ArgoCD admin password: $ARGOCD_PASSWORD"

# Port-forward ArgoCD UI
kubectl port-forward svc/argocd-server -n argocd 8080:443 &