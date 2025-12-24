# Design System Storybook Deployment

This directory contains Kubernetes manifests for deploying the Fawkes Design System Storybook to the cluster.

## Components

- **Deployment**: 2 replicas of the Storybook application
- **Service**: ClusterIP service exposing port 80
- **Ingress**: NGINX ingress with TLS support

## Accessing

Once deployed, the Storybook will be available at:
- Local: http://design-system.fawkes.local
- With TLS: https://design-system.fawkes.local

## Building the Docker Image

```bash
cd design-system
docker build -t fawkes/design-system-storybook:latest .
```

## Manual Deployment

```bash
kubectl apply -f platform/apps/design-system/deployment.yaml
```

## ArgoCD Deployment

The design system is automatically deployed via ArgoCD:

```bash
kubectl apply -f platform/apps/design-system-application.yaml
```

## Resource Requirements

- CPU: 100m request, 500m limit
- Memory: 128Mi request, 512Mi limit
- Replicas: 2 (for high availability)
