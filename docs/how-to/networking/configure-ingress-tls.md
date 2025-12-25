---
title: Configure Ingress with TLS
description: Set up external HTTPS access to services using NGINX Ingress and cert-manager
---

# Configure Ingress with TLS

## Goal

Expose a Kubernetes service to external HTTPS traffic using NGINX Ingress Controller with automatic TLS certificate management via cert-manager.

## Prerequisites

Before you begin, ensure you have:

- [ ] NGINX Ingress Controller deployed in the cluster
- [ ] cert-manager deployed and configured
- [ ] A Kubernetes Service to expose (ClusterIP or LoadBalancer)
- [ ] DNS record pointing to the Ingress Controller's external IP
- [ ] `kubectl` configured with cluster access

## Steps

### 1. Verify Prerequisites

#### Check NGINX Ingress Controller

```bash
# Verify Ingress Controller is running
kubectl get pods -n ingress-nginx -l app.kubernetes.io/component=controller

# Get Ingress Controller external IP
kubectl get svc -n ingress-nginx ingress-nginx-controller

# Should show EXTERNAL-IP (not <pending>)
```

#### Check cert-manager

```bash
# Verify cert-manager is running
kubectl get pods -n cert-manager

# Should show 3 pods: cert-manager, cert-manager-cainjector, cert-manager-webhook
# All should be Running
```

#### Verify Your Service Exists

```bash
# List services in your namespace
kubectl get svc -n my-namespace

# Your service should exist with type ClusterIP or LoadBalancer
```

### 2. Create a ClusterIssuer for Let's Encrypt

#### Create ClusterIssuer Manifest

A ClusterIssuer configures cert-manager to obtain certificates from Let's Encrypt:

**File:** `cluster-issuer-letsencrypt.yaml`

```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    # Let's Encrypt production server
    server: https://acme-v02.api.letsencrypt.org/directory

    # Email for certificate expiration notifications
    email: platform-team@example.com

    # Secret to store ACME account private key
    privateKeySecretRef:
      name: letsencrypt-prod-account-key

    # HTTP-01 challenge solver using NGINX Ingress
    solvers:
    - http01:
        ingress:
          class: nginx
```

**For staging/testing, use Let's Encrypt staging:**

```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-staging
spec:
  acme:
    # Let's Encrypt staging server (higher rate limits, use for testing)
    server: https://acme-staging-v02.api.letsencrypt.org/directory
    email: platform-team@example.com
    privateKeySecretRef:
      name: letsencrypt-staging-account-key
    solvers:
    - http01:
        ingress:
          class: nginx
```

#### Apply ClusterIssuer

```bash
# Create production issuer
kubectl apply -f cluster-issuer-letsencrypt.yaml

# Verify ClusterIssuer is ready
kubectl get clusterissuer letsencrypt-prod

# Should show: READY=True
```

### 3. Create DNS Record

#### Point Your Domain to Ingress

Get the Ingress Controller external IP:

```bash
# Get external IP
INGRESS_IP=$(kubectl get svc -n ingress-nginx ingress-nginx-controller \
  -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

echo "Ingress IP: $INGRESS_IP"
```

Create a DNS A record:

```text
Type: A
Name: my-app.example.com
Value: <INGRESS_IP>
TTL: 300
```

**For development (using nip.io):**

You can use `nip.io` for automatic DNS resolution without creating records:

```text
my-app.127.0.0.1.nip.io → resolves to 127.0.0.1
my-app.10.0.0.5.nip.io → resolves to 10.0.0.5
```

#### Verify DNS Resolution

```bash
# Check DNS resolution
nslookup my-app.example.com

# Should return the Ingress IP
# May take 5-10 minutes to propagate
```

### 4. Create Ingress Resource

#### Create Ingress Manifest

**File:** `my-app-ingress.yaml`

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-app-ingress
  namespace: my-namespace
  annotations:
    # Use NGINX Ingress Controller
    kubernetes.io/ingress.class: nginx

    # Enable cert-manager for automatic TLS
    cert-manager.io/cluster-issuer: letsencrypt-prod

    # NGINX-specific annotations
    nginx.ingress.kubernetes.io/ssl-redirect: "true"  # Force HTTPS
    nginx.ingress.kubernetes.io/force-ssl-redirect: "true"

    # Optional: Client body size limit (for file uploads)
    nginx.ingress.kubernetes.io/proxy-body-size: "10m"

    # Optional: Request timeout
    nginx.ingress.kubernetes.io/proxy-read-timeout: "600"

    # Optional: CORS headers
    nginx.ingress.kubernetes.io/enable-cors: "true"
    nginx.ingress.kubernetes.io/cors-allow-origin: "https://example.com"

spec:
  # TLS configuration
  tls:
  - hosts:
    - my-app.example.com
    secretName: my-app-tls-cert  # cert-manager creates this secret

  # Routing rules
  rules:
  - host: my-app.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: my-app-service
            port:
              number: 80
```

#### Apply Ingress

```bash
# Create Ingress
kubectl apply -f my-app-ingress.yaml

# Verify Ingress created
kubectl get ingress -n my-namespace
```

### 5. Monitor Certificate Issuance

#### Watch Certificate Creation

```bash
# Watch Certificate resource
kubectl get certificate -n my-namespace -w

# Should transition from False → True in 1-3 minutes
```

#### Check Certificate Status

```bash
# Describe Certificate
kubectl describe certificate my-app-tls-cert -n my-namespace

# Look for events like:
# - Requesting new certificate
# - Waiting for http-01 challenge propagation
# - Certificate issued successfully
```

#### Verify Certificate Secret

```bash
# Check if secret was created by cert-manager
kubectl get secret my-app-tls-cert -n my-namespace

# View certificate details
kubectl get secret my-app-tls-cert -n my-namespace \
  -o jsonpath='{.data.tls\.crt}' | base64 -d | openssl x509 -text -noout
```

### 6. Test HTTPS Access

#### Access via Browser

Open browser and navigate to:

```
https://my-app.example.com
```

Verify:

- ✅ HTTPS padlock icon appears (not "Not Secure")
- ✅ Certificate issued by "Let's Encrypt"
- ✅ Certificate valid for your domain
- ✅ No certificate warnings

#### Test with curl

```bash
# Test HTTPS endpoint
curl -v https://my-app.example.com

# Should return:
# * SSL connection using TLSv1.3 / TLS_AES_256_GCM_SHA384
# * Server certificate:
# *  subject: CN=my-app.example.com
# *  issuer: C=US; O=Let's Encrypt; CN=R3
# HTTP/2 200
```

#### Test HTTP Redirect

```bash
# HTTP should redirect to HTTPS
curl -I http://my-app.example.com

# Should return:
# HTTP/1.1 308 Permanent Redirect
# Location: https://my-app.example.com/
```

## Verification

### 1. Verify Ingress Configuration

```bash
# Get Ingress details
kubectl get ingress my-app-ingress -n my-namespace -o yaml

# Check for:
# - rules[].host matches your domain
# - tls[].hosts matches your domain
# - tls[].secretName exists
```

### 2. Verify Certificate is Valid

```bash
# Check certificate expiration
kubectl get certificate my-app-tls-cert -n my-namespace \
  -o jsonpath='{.status.notAfter}'

# Should show expiration ~90 days in the future
```

### 3. Verify NGINX Configuration

```bash
# Get NGINX Ingress Controller pod
NGINX_POD=$(kubectl get pod -n ingress-nginx \
  -l app.kubernetes.io/component=controller \
  -o jsonpath='{.items[0].metadata.name}')

# Check NGINX configuration for your ingress
kubectl exec -n ingress-nginx $NGINX_POD -- cat /etc/nginx/nginx.conf | grep my-app

# Should show SSL configuration and upstream backend
```

### 4. Test TLS Certificate Chain

```bash
# Test certificate chain
openssl s_client -connect my-app.example.com:443 -servername my-app.example.com </dev/null

# Verify:
# - Certificate chain OK
# - No errors
# - Issuer: Let's Encrypt
```

### 5. Verify Auto-Renewal

cert-manager automatically renews certificates 30 days before expiration.

```bash
# Check cert-manager logs for renewal
kubectl logs -n cert-manager deployment/cert-manager | grep renewal

# Force renewal test (optional)
kubectl delete secret my-app-tls-cert -n my-namespace
# Certificate should be automatically re-issued
```

## Advanced Configurations

### Multiple Hosts (One Ingress)

```yaml
spec:
  tls:
  - hosts:
    - app.example.com
    - www.app.example.com
    secretName: app-tls-cert

  rules:
  - host: app.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: my-app
            port:
              number: 80

  - host: www.app.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: my-app
            port:
              number: 80
```

### Path-Based Routing

```yaml
spec:
  rules:
  - host: my-app.example.com
    http:
      paths:
      - path: /api
        pathType: Prefix
        backend:
          service:
            name: api-service
            port:
              number: 8080

      - path: /web
        pathType: Prefix
        backend:
          service:
            name: web-service
            port:
              number: 80
```

### Custom TLS Certificate (Not Let's Encrypt)

```bash
# Create secret from existing certificate
kubectl create secret tls my-custom-cert \
  --cert=path/to/tls.crt \
  --key=path/to/tls.key \
  -n my-namespace

# Reference in Ingress (remove cert-manager annotation)
```

```yaml
spec:
  tls:
  - hosts:
    - my-app.example.com
    secretName: my-custom-cert  # Use custom cert
```

### Rate Limiting

```yaml
metadata:
  annotations:
    nginx.ingress.kubernetes.io/limit-rps: "10"  # 10 requests per second
    nginx.ingress.kubernetes.io/limit-connections: "5"  # 5 concurrent connections
```

### Basic Authentication

```bash
# Create htpasswd file
htpasswd -c auth username

# Create secret
kubectl create secret generic basic-auth \
  --from-file=auth \
  -n my-namespace
```

```yaml
metadata:
  annotations:
    nginx.ingress.kubernetes.io/auth-type: basic
    nginx.ingress.kubernetes.io/auth-secret: basic-auth
    nginx.ingress.kubernetes.io/auth-realm: "Authentication Required"
```

## Troubleshooting

### Certificate Stuck in "False" Status

**Cause**: HTTP-01 challenge failing.

**Solution**:

```bash
# Check CertificateRequest
kubectl get certificaterequest -n my-namespace

# Describe for errors
kubectl describe certificaterequest <name> -n my-namespace

# Common issues:
# 1. DNS not pointing to Ingress IP
# 2. Firewall blocking port 80
# 3. Ingress class mismatch
```

### "404 Not Found" on HTTPS

**Cause**: Service not reachable or incorrect backend.

**Solution**:

```bash
# Verify service exists and has endpoints
kubectl get svc my-app-service -n my-namespace
kubectl get endpoints my-app-service -n my-namespace

# Test service directly
kubectl port-forward -n my-namespace svc/my-app-service 8080:80
curl http://localhost:8080

# Check Ingress backend
kubectl describe ingress my-app-ingress -n my-namespace
```

### "Too Many Redirects"

**Cause**: Application also redirecting to HTTPS.

**Solution**:

```yaml
metadata:
  annotations:
    # Tell app it's already behind HTTPS
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
    nginx.ingress.kubernetes.io/backend-protocol: "HTTP"
```

### Let's Encrypt Rate Limit Exceeded

**Cause**: Too many certificate requests (5 per week for same domain).

**Solution**:

```bash
# Use staging issuer for testing
# Update Ingress annotation
cert-manager.io/cluster-issuer: letsencrypt-staging

# After testing, switch back to prod
```

## Next Steps

After configuring Ingress with TLS:

- [Onboard Service to ArgoCD](../gitops/onboard-service-argocd.md) - Automate Ingress deployment
- [Rotate Vault Secrets](../security/rotate-vault-secrets.md) - Manage TLS certificate secrets
- [Trace Requests with Tempo](../observability/trace-request-tempo.md) - Monitor HTTPS traffic
- [Ingress Access Guide](../../ingress-access.md) - Advanced routing patterns

## Related Documentation

- [Networking Configuration](../../platform/networking/README.md) - NGINX Ingress setup
- [Security Best Practices](../../security.md) - TLS configuration
- [cert-manager Documentation](https://cert-manager.io/docs/) - Certificate management
- [NGINX Ingress Annotations](https://kubernetes.github.io/ingress-nginx/user-guide/nginx-configuration/annotations/) - Full annotation reference
