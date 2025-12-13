# Azure Load Balancer and Ingress Setup Guide

This guide walks through the complete setup of Azure Load Balancer, nginx-ingress controller, and cert-manager for the Fawkes platform on Azure AKS.

## Architecture Overview

```
Internet
    ↓
Azure Load Balancer (Standard SKU)
    ↓
nginx-ingress-controller (2+ pods)
    ↓
Kubernetes Services (backstage, jenkins, etc.)
```

## Prerequisites

- Azure AKS cluster provisioned (see [Azure AKS Provisioning](../../../docs/azure-aks-provisioning.md))
- `kubectl` configured for the cluster
- ArgoCD installed (optional, for GitOps deployment)
- Azure CLI installed (for DNS and resource verification)

## Components

### 1. nginx-ingress Controller

The nginx-ingress controller provides:
- Layer 7 HTTP/HTTPS routing
- TLS termination
- Load balancing across service pods
- High availability with multiple replicas
- Auto-scaling based on CPU/memory
- Prometheus metrics

### 2. Azure Load Balancer

Azure automatically creates a Standard SKU Load Balancer when you deploy a LoadBalancer service:
- Public IP assignment
- Health probes
- Port forwarding (80, 443)
- Session affinity
- Zone redundancy (in supported regions)

### 3. cert-manager

Automates TLS certificate management:
- Let's Encrypt integration
- Automatic certificate issuance and renewal
- HTTP-01 and DNS-01 challenge support
- Azure DNS integration for wildcard certificates

## Deployment Steps

### Step 1: Deploy nginx-ingress Controller

#### Option A: Using ArgoCD (Recommended)

```bash
# Apply the ArgoCD Application
kubectl apply -f platform/apps/ingress-nginx/ingress-nginx-azure-application.yaml

# Check ArgoCD sync status
kubectl get application ingress-nginx -n fawkes
```

#### Option B: Using Helm

```bash
# Add the nginx-ingress Helm repository
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

# Install with Azure values
helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  -f platform/apps/ingress-nginx/values-azure.yaml
```

#### Verify Deployment

```bash
# Run validation script
./platform/apps/ingress-nginx/validate-azure.sh

# Check pods
kubectl get pods -n ingress-nginx

# Check service and get external IP
kubectl get svc ingress-nginx-controller -n ingress-nginx

# Wait for external IP to be assigned (can take 2-3 minutes)
kubectl wait --for=jsonpath='{.status.loadBalancer.ingress[0].ip}' \
  svc/ingress-nginx-controller -n ingress-nginx --timeout=300s
```

### Step 2: Configure Azure DNS (Optional)

#### Configure Terraform Variables

Edit `infra/azure/terraform.tfvars`:

```hcl
# Enable DNS zone creation
dns_zone_name = "fawkes.yourdomain.com"

# Set to true after ingress-nginx is deployed
create_dns_records = true

# Default name of the public IP (or your custom static IP name)
ingress_public_ip_name = "kubernetes"
```

#### Apply Terraform

```bash
cd infra/azure

# Initialize Terraform (if not done already)
terraform init

# Plan to see what will be created
terraform plan

# Apply changes
terraform apply

# Get nameservers for DNS delegation
terraform output dns_zone_name_servers
```

#### Delegate DNS (at your domain registrar)

Update your domain's nameservers with the values from the Terraform output.

#### Verify DNS

```bash
# Wait for DNS propagation (can take up to 48 hours)
dig jenkins.fawkes.yourdomain.com
dig focalboard.fawkes.yourdomain.com

# Should resolve to your ingress external IP
```

### Step 3: Deploy cert-manager

#### Deploy cert-manager

```bash
# Apply the ArgoCD Application
kubectl apply -f platform/apps/cert-manager/cert-manager-application.yaml

# Wait for cert-manager to be ready
kubectl wait --for=condition=available --timeout=300s \
  deployment/cert-manager -n cert-manager

kubectl wait --for=condition=available --timeout=300s \
  deployment/cert-manager-webhook -n cert-manager

kubectl wait --for=condition=available --timeout=300s \
  deployment/cert-manager-cainjector -n cert-manager
```

#### Configure ClusterIssuers

```bash
# Update email address in issuer files
sed -i 's/platform-team@example.com/your-email@example.com/g' \
  platform/apps/cert-manager/cluster-issuer-*.yaml

# Apply ClusterIssuers
kubectl apply -f platform/apps/cert-manager/cluster-issuer-letsencrypt-staging.yaml
kubectl apply -f platform/apps/cert-manager/cluster-issuer-letsencrypt-prod.yaml

# Verify issuers are ready
kubectl get clusterissuer
kubectl describe clusterissuer letsencrypt-prod
```

#### Verify cert-manager

```bash
# Run validation script
./platform/apps/cert-manager/validate.sh

# Check CRDs
kubectl get crd | grep cert-manager
```

### Step 4: Test with Sample Application

#### Deploy Test Echo Server

```bash
# Deploy test ingress with echo server
kubectl apply -f platform/apps/ingress-nginx/test-ingress.yaml

# Get external IP
EXTERNAL_IP=$(kubectl get svc ingress-nginx-controller -n ingress-nginx \
  -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

echo "External IP: $EXTERNAL_IP"
```

#### Test HTTP Access

```bash
# Test with nip.io (no DNS required)
curl http://test.${EXTERNAL_IP}.nip.io

# Or with custom domain (if DNS is configured)
curl http://test.fawkes.yourdomain.com
```

#### Request TLS Certificate

Create an Ingress with cert-manager annotation:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: test-app-tls
  namespace: ingress-test
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-staging  # Use staging first!
spec:
  ingressClassName: nginx
  tls:
    - hosts:
        - test.fawkes.yourdomain.com
      secretName: test-app-tls
  rules:
    - host: test.fawkes.yourdomain.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: echo-server
                port:
                  number: 80
```

```bash
# Apply the ingress
kubectl apply -f test-ingress-tls.yaml

# Watch certificate creation
kubectl get certificate -n ingress-test -w

# Check certificate details
kubectl describe certificate test-app-tls -n ingress-test

# Once ready, test HTTPS
curl https://test.fawkes.yourdomain.com
```

#### Switch to Production Issuer

Once verified with staging:

```bash
# Update annotation to use production issuer
kubectl annotate ingress test-app-tls -n ingress-test \
  cert-manager.io/cluster-issuer=letsencrypt-prod --overwrite

# Delete the staging certificate to trigger re-issuance
kubectl delete certificate test-app-tls -n ingress-test
kubectl delete secret test-app-tls -n ingress-test
```

## Advanced Configuration

### Static Public IP

To use a pre-created static public IP:

```bash
# Create public IP in node resource group
az network public-ip create \
  --resource-group MC_fawkes-rg_fawkes-aks_eastus \
  --name fawkes-ingress-pip \
  --sku Standard \
  --allocation-method Static \
  --dns-name fawkes-ingress

# Get the IP address
az network public-ip show \
  --resource-group MC_fawkes-rg_fawkes-aks_eastus \
  --name fawkes-ingress-pip \
  --query ipAddress -o tsv

# Update values-azure.yaml annotations:
# service.beta.kubernetes.io/azure-load-balancer-resource-group: "MC_fawkes-rg_fawkes-aks_eastus"
# service.beta.kubernetes.io/azure-pip-name: "fawkes-ingress-pip"
```

### Wildcard Certificates with Azure DNS

For wildcard certificates (e.g., `*.fawkes.yourdomain.com`):

1. Configure Azure DNS ClusterIssuer:

```bash
# Update cluster-issuer-letsencrypt-dns-azure.yaml with:
# - Azure subscription ID
# - Resource group
# - DNS zone name
# - Managed Identity client ID

kubectl apply -f platform/apps/cert-manager/cluster-issuer-letsencrypt-dns-azure.yaml
```

2. Create wildcard certificate:

```yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: wildcard-tls
  namespace: fawkes
spec:
  secretName: wildcard-tls
  dnsNames:
    - "*.fawkes.yourdomain.com"
    - fawkes.yourdomain.com
  issuerRef:
    name: letsencrypt-dns-azure
    kind: ClusterIssuer
```

### Internal Load Balancer

For private ingress (only accessible within VNet):

Add annotation to service:
```yaml
service.beta.kubernetes.io/azure-load-balancer-internal: "true"
```

### PROXY Protocol

If your Azure Load Balancer uses PROXY protocol:

Update values-azure.yaml:
```yaml
config:
  use-proxy-protocol: "true"
```

## Monitoring

### Prometheus Metrics

```bash
# Port-forward to metrics endpoint
kubectl port-forward -n ingress-nginx \
  svc/ingress-nginx-controller-metrics 9402:10254

# Query metrics
curl http://localhost:9402/metrics | grep nginx_ingress
```

### Grafana Dashboards

Import the official nginx-ingress dashboard:
- Dashboard ID: 9614 (from grafana.com)

### Alerts

PrometheusRules are configured for:
- Controller down alert
- High error rate alert
- Certificate expiration alert (via cert-manager)

## Troubleshooting

### External IP Not Assigned

```bash
# Check service events
kubectl describe svc ingress-nginx-controller -n ingress-nginx

# Check Azure Load Balancer
az network lb list --resource-group MC_fawkes-rg_fawkes-aks_*

# Check if quota is exceeded
az vm list-usage --location eastus -o table
```

### Ingress Not Accessible

```bash
# Check controller logs
kubectl logs -n ingress-nginx -l app.kubernetes.io/component=controller --tail=100

# Check ingress resource
kubectl describe ingress <name> -n <namespace>

# Verify IngressClass
kubectl get ingressclass
```

### Certificate Not Issuing

```bash
# Check certificate status
kubectl describe certificate <name> -n <namespace>

# Check certificate request
kubectl get certificaterequest -n <namespace>

# Check ACME challenge
kubectl get challenge -n <namespace>
kubectl describe challenge <name> -n <namespace>

# Check cert-manager logs
kubectl logs -n cert-manager deployment/cert-manager --tail=100
```

### DNS Not Resolving

```bash
# Check DNS records in Azure
az network dns record-set a list \
  --resource-group fawkes-rg \
  --zone-name fawkes.yourdomain.com

# Test DNS resolution
dig +short test.fawkes.yourdomain.com

# Check nameserver delegation
dig NS fawkes.yourdomain.com
```

## Security Best Practices

1. **Use Production Certificates**: Always test with staging issuer first
2. **Enable HSTS**: Force HTTPS with strict transport security
3. **Restrict Access**: Use Azure Network Security Groups
4. **Monitor Certificates**: Set up alerts for expiring certificates
5. **Use Strong TLS**: Disable weak cipher suites
6. **Rate Limiting**: Configure rate limits in nginx
7. **WAF Integration**: Consider Azure Application Gateway with WAF

## Cost Optimization

- Standard Load Balancer: ~$18/month + data processing
- Public IP: ~$3/month
- DNS Zone: $0.50/zone + queries
- cert-manager: Free (Let's Encrypt)

Total estimated cost: ~$22-25/month

## Reference Documentation

- [nginx-ingress Controller](https://kubernetes.github.io/ingress-nginx/)
- [cert-manager](https://cert-manager.io/docs/)
- [Azure Load Balancer](https://docs.microsoft.com/en-us/azure/load-balancer/)
- [Azure DNS](https://docs.microsoft.com/en-us/azure/dns/)
- [Let's Encrypt](https://letsencrypt.org/docs/)
