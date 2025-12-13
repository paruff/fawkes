# Quick Start: Azure Ingress & TLS Setup

This is a quick reference guide for deploying nginx-ingress and cert-manager on Azure AKS.

## Prerequisites

✅ Azure AKS cluster provisioned
✅ kubectl configured
✅ ArgoCD installed (optional)

## 1. Deploy nginx-ingress (5 minutes)

```bash
# Apply ArgoCD Application
kubectl apply -f platform/apps/ingress-nginx/ingress-nginx-azure-application.yaml

# Wait for deployment
kubectl wait --for=condition=available --timeout=300s \
  deployment/ingress-nginx-controller -n ingress-nginx

# Get external IP (may take 2-3 minutes)
kubectl get svc ingress-nginx-controller -n ingress-nginx -w
```

**Validation:**
```bash
./platform/apps/ingress-nginx/validate-azure.sh
```

## 2. Configure DNS (Optional, 10 minutes)

```bash
# Edit infra/azure/terraform.tfvars
dns_zone_name = "fawkes.yourdomain.com"
create_dns_records = true

# Apply Terraform
cd infra/azure
terraform apply

# Get nameservers for delegation
terraform output dns_zone_name_servers
```

**Update your domain registrar** with the nameservers from the output.

## 3. Deploy cert-manager (5 minutes)

```bash
# Deploy cert-manager
kubectl apply -f platform/apps/cert-manager/cert-manager-application.yaml

# Wait for cert-manager
kubectl wait --for=condition=available --timeout=300s \
  deployment/cert-manager -n cert-manager

# Update email address
sed -i 's/platform-team@example.com/your-email@example.com/g' \
  platform/apps/cert-manager/cluster-issuer-*.yaml

# Deploy ClusterIssuers
kubectl apply -f platform/apps/cert-manager/cluster-issuer-letsencrypt-staging.yaml
kubectl apply -f platform/apps/cert-manager/cluster-issuer-letsencrypt-prod.yaml
```

**Validation:**
```bash
./platform/apps/cert-manager/validate.sh
```

## 4. Test with Echo Server (5 minutes)

```bash
# Deploy test app
kubectl apply -f platform/apps/ingress-nginx/test-ingress.yaml

# Get external IP
EXTERNAL_IP=$(kubectl get svc ingress-nginx-controller -n ingress-nginx \
  -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

# Test HTTP
curl http://test.${EXTERNAL_IP}.nip.io
```

## 5. Request TLS Certificate (5 minutes)

Create ingress with cert-manager annotation:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: myapp
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-staging"
spec:
  ingressClassName: nginx
  tls:
    - hosts:
        - myapp.fawkes.yourdomain.com
      secretName: myapp-tls
  rules:
    - host: myapp.fawkes.yourdomain.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: myapp
                port:
                  number: 80
```

**Watch certificate creation:**
```bash
kubectl get certificate -A -w
```

**Once verified, switch to production:**
```bash
kubectl annotate ingress myapp \
  cert-manager.io/cluster-issuer=letsencrypt-prod --overwrite
```

## Common Issues

### External IP Pending
Wait 2-3 minutes. Azure Load Balancer creation takes time.

### Certificate Not Issuing
1. Check DNS points to ingress IP: `dig myapp.fawkes.yourdomain.com`
2. Check challenge: `kubectl get challenge -A`
3. Check logs: `kubectl logs -n cert-manager deployment/cert-manager`

### 404 Not Found
1. Check ingress: `kubectl get ingress -A`
2. Check backend service: `kubectl get svc myapp`
3. Check controller logs: `kubectl logs -n ingress-nginx -l app.kubernetes.io/component=controller`

## Next Steps

- Configure monitoring: See `docs/azure-ingress-setup.md`
- Add more services: Update ingress resources
- Wildcard certificates: Configure Azure DNS issuer
- Static IP: See `platform/apps/ingress-nginx/README.md`

## Full Documentation

- [Azure Ingress Setup Guide](../docs/azure-ingress-setup.md)
- [nginx-ingress README](../platform/apps/ingress-nginx/README.md)
- [cert-manager README](../platform/apps/cert-manager/README.md)
- [BDD Tests](../tests/bdd/features/azure_ingress_loadbalancer.feature)
