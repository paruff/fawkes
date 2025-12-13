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

- `ingress-nginx-application.yaml` - ArgoCD Application manifest (local/generic)
- `ingress-nginx-azure-application.yaml` - ArgoCD Application manifest for Azure AKS
- `values.yaml` - Helm values for local development
- `values-azure.yaml` - Helm values for Azure AKS
- `test-ingress.yaml` - Test ingress resource with echo server

## Deployment

### Via ArgoCD

For local development:
```bash
kubectl apply -f ingress-nginx-application.yaml
```

For Azure AKS:
```bash
kubectl apply -f ingress-nginx-azure-application.yaml
```

### Via Helm (for local testing)

For local development:
```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  -f values.yaml
```

For Azure AKS:
```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  -f values-azure.yaml
```

## Testing

### Automated Validation

Run the validation script to check the deployment:

```bash
./validate.sh
```

### Manual Testing

#### 1. Generate TLS Certificate (Required for HTTPS testing)

Before deploying the test ingress, generate a self-signed TLS certificate:

```bash
./generate-test-cert.sh
```

This will create a self-signed certificate valid for `*.127.0.0.1.nip.io` and store it in a Kubernetes secret.

#### 2. Deploy Test Ingress

Deploy the test ingress:

```bash
kubectl apply -f test-ingress.yaml
```

Verify the ingress controller is running:

```bash
kubectl get pods -n ingress-nginx
kubectl get svc -n ingress-nginx
```

#### 3. Test HTTP and HTTPS Access

Test the HTTP endpoint:

```bash
# Get the LoadBalancer IP
kubectl get svc -n ingress-nginx ingress-nginx-controller

# Test HTTP endpoint
curl http://test.127.0.0.1.nip.io
```

Test the HTTPS endpoint (requires generate-test-cert.sh to be run first):

```bash
# Test HTTPS endpoint (use -k to accept self-signed certificate)
curl -k https://test-tls.127.0.0.1.nip.io
```

## Configuration

### Local Development

For local development (Docker Desktop, Minikube, etc.):
- Single replica for resource efficiency
- Reduced resource requests/limits
- TLS redirect disabled
- Uses nip.io for DNS resolution

### Azure AKS

For Azure AKS environments, use `ingress-nginx-azure-application.yaml` which includes:
- Azure Load Balancer annotations
- Health probe configuration
- High availability (2+ replicas with auto-scaling)
- TLS redirect enabled
- Prometheus metrics with ServiceMonitor
- Performance tuning for Azure
- Session affinity for better performance

Azure-specific configuration options (in values-azure.yaml):
- Static public IP (requires pre-created IP in node resource group)
- Internal Load Balancer (for private ingress)
- PROXY protocol support (if needed)
- External-DNS integration (for automatic DNS management)

To use a static public IP:
1. Create a public IP in the node resource group:
   ```bash
   az network public-ip create \
     --resource-group MC_fawkes-rg_fawkes-aks_eastus \
     --name fawkes-ingress-pip \
     --sku Standard \
     --allocation-method Static
   ```
2. Uncomment the annotations in `values-azure.yaml`:
   - `service.beta.kubernetes.io/azure-load-balancer-resource-group`
   - `service.beta.kubernetes.io/azure-pip-name`

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
