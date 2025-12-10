# NGINX Ingress Controller

This directory contains the NGINX Ingress Controller deployment for the Fawkes platform.

## Overview

The NGINX Ingress Controller provides Layer 7 HTTP/HTTPS routing for Kubernetes services with:
- High availability (2 replicas with pod anti-affinity)
- TLS termination
- Prometheus metrics
- LoadBalancer service
- Default backend for 404 responses

## Files

- `ingress-nginx-application.yaml` - ArgoCD Application manifest
- `values.yaml` - Helm values for local development
- `test-ingress.yaml` - Test ingress resource with echo server

## Deployment

### Via ArgoCD

```bash
kubectl apply -f ingress-nginx-application.yaml
```

### Via Helm (for local testing)

```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  -f values.yaml
```

## Testing

Deploy the test ingress:

```bash
kubectl apply -f test-ingress.yaml
```

Verify the ingress controller is running:

```bash
kubectl get pods -n ingress-nginx
kubectl get svc -n ingress-nginx
```

Test the ingress route:

```bash
# Get the LoadBalancer IP
kubectl get svc -n ingress-nginx ingress-nginx-controller

# Test HTTP endpoint
curl http://test.127.0.0.1.nip.io
```

## Configuration

### Local Development

For local development (Docker Desktop, Minikube, etc.):
- Single replica for resource efficiency
- Reduced resource requests/limits
- TLS redirect disabled
- Uses nip.io for DNS resolution

### Production

For production environments, update the following in `ingress-nginx-application.yaml`:
- Increase replica count (2+)
- Enable TLS redirect
- Configure proper domain names
- Adjust resource limits based on load
- Enable ServiceMonitor for Prometheus

## Metrics

Prometheus metrics are exposed on port 10254:

```bash
kubectl port-forward -n ingress-nginx svc/ingress-nginx-controller-metrics 10254:10254
curl http://localhost:10254/metrics
```

Key metrics:
- `nginx_ingress_controller_requests` - Total requests
- `nginx_ingress_controller_request_duration_seconds` - Request latency
- `nginx_ingress_controller_ssl_expire_time_seconds` - Certificate expiration

## Troubleshooting

### Pods not running

```bash
kubectl describe pods -n ingress-nginx
kubectl logs -n ingress-nginx -l app.kubernetes.io/component=controller
```

### Ingress not accessible

1. Check service status:
   ```bash
   kubectl get svc -n ingress-nginx
   ```

2. Check ingress resources:
   ```bash
   kubectl get ingress -A
   kubectl describe ingress <name> -n <namespace>
   ```

3. Check controller logs:
   ```bash
   kubectl logs -n ingress-nginx -l app.kubernetes.io/component=controller
   ```

## Related Documentation

- [Ingress Access Guide](../../../docs/ingress-access.md)
- [NGINX Ingress Controller Docs](https://kubernetes.github.io/ingress-nginx/)
- [Networking Stack README](../../networking/README.md)
