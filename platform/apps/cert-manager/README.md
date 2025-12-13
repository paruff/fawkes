# cert-manager

This directory contains cert-manager deployment for automated TLS certificate management.

## Overview

cert-manager is a Kubernetes add-on that automates the management and issuance of TLS certificates from various issuing sources, including Let's Encrypt.

## Features

- Automated certificate issuance and renewal
- Let's Encrypt integration (staging and production)
- HTTP-01 and DNS-01 challenge support
- Azure DNS integration for wildcard certificates
- Prometheus metrics
- Certificate lifecycle management

## Files

- `cert-manager-application.yaml` - ArgoCD Application for cert-manager
- `cluster-issuers-application.yaml` - ArgoCD Application for ClusterIssuers
- `cluster-issuer-letsencrypt-staging.yaml` - Let's Encrypt staging issuer (HTTP-01)
- `cluster-issuer-letsencrypt-prod.yaml` - Let's Encrypt production issuer (HTTP-01)
- `cluster-issuer-letsencrypt-dns-azure.yaml` - Let's Encrypt issuer with Azure DNS (DNS-01)
- `certificate-example.yaml` - Example Certificate resources

## Deployment

### 1. Deploy cert-manager

```bash
kubectl apply -f cert-manager-application.yaml
```

Wait for cert-manager to be ready:

```bash
kubectl wait --for=condition=available --timeout=300s deployment/cert-manager -n cert-manager
kubectl wait --for=condition=available --timeout=300s deployment/cert-manager-webhook -n cert-manager
kubectl wait --for=condition=available --timeout=300s deployment/cert-manager-cainjector -n cert-manager
```

### 2. Configure ClusterIssuers

Update the email address in the ClusterIssuer files before deploying:

```bash
# Edit the email address
sed -i 's/platform-team@example.com/your-email@example.com/g' cluster-issuer-*.yaml
```

Deploy ClusterIssuers:

```bash
kubectl apply -f cluster-issuer-letsencrypt-staging.yaml
kubectl apply -f cluster-issuer-letsencrypt-prod.yaml
```

Or use ArgoCD:

```bash
kubectl apply -f cluster-issuers-application.yaml
```

### 3. Verify Installation

```bash
# Check cert-manager pods
kubectl get pods -n cert-manager

# Check ClusterIssuers
kubectl get clusterissuer

# Check if issuers are ready
kubectl describe clusterissuer letsencrypt-prod
```

## Usage

### Using Ingress Annotations (Automatic)

Add cert-manager annotations to your Ingress:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: myapp
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
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

cert-manager will automatically create a Certificate resource and obtain a TLS certificate.

### Using Certificate Resources (Explicit)

Create a Certificate resource:

```yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: myapp-tls
  namespace: myapp-namespace
spec:
  secretName: myapp-tls
  duration: 2160h  # 90 days
  renewBefore: 360h  # 15 days
  commonName: myapp.fawkes.yourdomain.com
  dnsNames:
    - myapp.fawkes.yourdomain.com
  issuerRef:
    name: letsencrypt-prod
    kind: ClusterIssuer
```

### Testing with Staging

Always test with the staging issuer first to avoid rate limits:

```yaml
annotations:
  cert-manager.io/cluster-issuer: "letsencrypt-staging"
```

Once verified, switch to production:

```yaml
annotations:
  cert-manager.io/cluster-issuer: "letsencrypt-prod"
```

## Azure DNS Challenge (Wildcard Certificates)

For wildcard certificates (e.g., `*.fawkes.yourdomain.com`), you must use DNS-01 challenge.

### Prerequisites

1. Azure DNS zone created
2. Azure Workload Identity or Service Principal configured
3. Permissions to manage DNS records in the zone

### Configure Azure DNS Issuer

1. Update `cluster-issuer-letsencrypt-dns-azure.yaml` with your Azure details:
   - Subscription ID
   - Resource Group
   - DNS Zone Name
   - Managed Identity Client ID or Service Principal

2. Deploy the issuer:

```bash
kubectl apply -f cluster-issuer-letsencrypt-dns-azure.yaml
```

3. Create a wildcard certificate:

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

## Monitoring

### Check Certificate Status

```bash
# List all certificates
kubectl get certificate -A

# Check certificate details
kubectl describe certificate myapp-tls -n myapp-namespace

# Check certificate events
kubectl get events -n myapp-namespace --field-selector involvedObject.name=myapp-tls
```

### Certificate Ready Conditions

A certificate is ready when:

```bash
kubectl get certificate myapp-tls -n myapp-namespace -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}'
# Should output: True
```

### Check Certificate Expiration

```bash
kubectl get secret myapp-tls -n myapp-namespace -o jsonpath='{.data.tls\.crt}' | base64 -d | openssl x509 -noout -enddate
```

### Prometheus Metrics

cert-manager exposes metrics on port 9402:

```bash
kubectl port-forward -n cert-manager svc/cert-manager 9402:9402
curl http://localhost:9402/metrics
```

Key metrics:
- `certmanager_certificate_expiration_timestamp_seconds` - Certificate expiration time
- `certmanager_certificate_ready_status` - Certificate ready status

## Troubleshooting

### Certificate Not Issuing

1. Check Certificate status:
   ```bash
   kubectl describe certificate myapp-tls -n myapp-namespace
   ```

2. Check CertificateRequest:
   ```bash
   kubectl get certificaterequest -n myapp-namespace
   kubectl describe certificaterequest <name> -n myapp-namespace
   ```

3. Check Order and Challenge (for ACME):
   ```bash
   kubectl get order -n myapp-namespace
   kubectl get challenge -n myapp-namespace
   kubectl describe challenge <name> -n myapp-namespace
   ```

4. Check cert-manager logs:
   ```bash
   kubectl logs -n cert-manager deployment/cert-manager
   kubectl logs -n cert-manager deployment/cert-manager-webhook
   ```

### HTTP-01 Challenge Failing

- Ensure ingress-nginx is running
- Verify the domain resolves to your ingress IP
- Check that port 80 is accessible
- Verify ingress class is set correctly

### DNS-01 Challenge Failing

- Verify Azure credentials are correct
- Check DNS zone permissions
- Ensure the DNS zone exists
- Check cert-manager logs for Azure API errors

### Rate Limiting

Let's Encrypt has rate limits:
- 50 certificates per registered domain per week
- 5 duplicate certificates per week

Use staging issuer for testing to avoid hitting limits.

### Certificate Not Renewing

cert-manager automatically renews certificates when `renewBefore` time is reached (default: 30 days before expiration).

Check:
```bash
kubectl get certificate myapp-tls -n myapp-namespace -o yaml
```

Look for `status.renewalTime` to see when renewal will occur.

## Security Best Practices

1. Use production issuer only after testing with staging
2. Regularly rotate certificates (automatic with cert-manager)
3. Monitor certificate expiration
4. Use separate ClusterIssuers for different environments
5. Limit access to Certificate resources with RBAC
6. Store ACME account keys securely (managed by cert-manager)

## Related Documentation

- [cert-manager Documentation](https://cert-manager.io/docs/)
- [Let's Encrypt Documentation](https://letsencrypt.org/docs/)
- [Azure DNS for cert-manager](https://cert-manager.io/docs/configuration/acme/dns01/azuredns/)
- [Ingress NGINX + cert-manager](https://cert-manager.io/docs/usage/ingress/)
