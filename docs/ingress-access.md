# Ingress Access Guide

This document describes how to configure external access for services on the Fawkes platform using Ingress resources with automated DNS management and TLS provisioning.

## Overview

The Fawkes platform provides:
- **NGINX Ingress Controller**: High availability Layer 7 routing
- **ExternalDNS**: Automated DNS record management
- **cert-manager**: Automatic TLS certificate provisioning via Let's Encrypt

All external-facing services are exposed via the Ingress Controller with mandatory TLS encryption.

## Architecture

```
Internet
    │
    ▼
┌─────────────────────────────┐
│  Wildcard DNS (*.fawkes.idp)│
│  Points to Load Balancer IP │
└─────────────────────────────┘
    │
    ▼
┌─────────────────────────────┐
│  AWS NLB / Cloud LB         │
│  (Static IP via Terraform)  │
└─────────────────────────────┘
    │
    ▼
┌─────────────────────────────┐
│  NGINX Ingress Controller   │
│  - TLS Termination          │
│  - HTTPS Redirect           │
│  - Path-based Routing       │
└─────────────────────────────┘
    │
    ▼
┌─────────────────────────────┐
│  Internal Services          │
│  (Plaintext within cluster) │
└─────────────────────────────┘
```

## Creating an Ingress Resource

### Basic Ingress with TLS

To expose a service externally, create an Ingress resource with the following mandatory annotations:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-service
  namespace: my-namespace
  annotations:
    # Required: Use nginx ingress class
    kubernetes.io/ingress.class: nginx
    
    # Required: TLS certificate issuer (use letsencrypt-prod for production)
    cert-manager.io/cluster-issuer: letsencrypt-prod
    
    # Optional: ExternalDNS will auto-create DNS record based on host
    external-dns.alpha.kubernetes.io/hostname: my-service.fawkes.idp
    
    # Optional: Force HTTPS redirect (enabled by default)
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
spec:
  ingressClassName: nginx
  tls:
    - hosts:
        - my-service.fawkes.idp
      secretName: my-service-tls
  rules:
    - host: my-service.fawkes.idp
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: my-service
                port:
                  number: 80
```

### Mandatory Annotations

| Annotation | Value | Description |
|------------|-------|-------------|
| `kubernetes.io/ingress.class` | `nginx` | Specifies the Ingress controller |
| `cert-manager.io/cluster-issuer` | `letsencrypt-prod` or `letsencrypt-staging` | TLS certificate issuer |

### Recommended Annotations

| Annotation | Default | Description |
|------------|---------|-------------|
| `nginx.ingress.kubernetes.io/ssl-redirect` | `true` | Force HTTPS redirect |
| `external-dns.alpha.kubernetes.io/hostname` | Auto from host | DNS record hostname |
| `nginx.ingress.kubernetes.io/proxy-body-size` | `50m` | Max request body size |
| `nginx.ingress.kubernetes.io/proxy-read-timeout` | `60` | Backend read timeout |

## Example Ingress Resources

### Jenkins

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: jenkins
  namespace: jenkins
  annotations:
    kubernetes.io/ingress.class: nginx
    cert-manager.io/cluster-issuer: letsencrypt-prod
    nginx.ingress.kubernetes.io/proxy-body-size: "100m"
spec:
  ingressClassName: nginx
  tls:
    - hosts:
        - jenkins.fawkes.idp
      secretName: jenkins-tls
  rules:
    - host: jenkins.fawkes.idp
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: jenkins
                port:
                  number: 8080
```

### SonarQube

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: sonarqube
  namespace: sonarqube
  annotations:
    kubernetes.io/ingress.class: nginx
    cert-manager.io/cluster-issuer: letsencrypt-prod
    nginx.ingress.kubernetes.io/proxy-body-size: "200m"
spec:
  ingressClassName: nginx
  tls:
    - hosts:
        - sonarqube.fawkes.idp
      secretName: sonarqube-tls
  rules:
    - host: sonarqube.fawkes.idp
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: sonarqube-sonarqube
                port:
                  number: 9000
```

### Grafana

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: grafana
  namespace: grafana
  annotations:
    kubernetes.io/ingress.class: nginx
    cert-manager.io/cluster-issuer: letsencrypt-prod
spec:
  ingressClassName: nginx
  tls:
    - hosts:
        - grafana.fawkes.idp
      secretName: grafana-tls
  rules:
    - host: grafana.fawkes.idp
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: grafana
                port:
                  number: 3000
```

### Focalboard

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: focalboard
  namespace: focalboard
  annotations:
    kubernetes.io/ingress.class: nginx
    cert-manager.io/cluster-issuer: letsencrypt-prod
spec:
  ingressClassName: nginx
  tls:
    - hosts:
        - focalboard.fawkes.idp
      secretName: focalboard-tls
  rules:
    - host: focalboard.fawkes.idp
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: focalboard
                port:
                  number: 8000
```

## TLS Certificate Management

### Issuers Available

| Issuer | Usage | Rate Limits |
|--------|-------|-------------|
| `letsencrypt-staging` | Development/Testing | No rate limits, untrusted certificates |
| `letsencrypt-prod` | Production | Rate limited, trusted certificates |
| `selfsigned-issuer` | Internal services | No rate limits, self-signed |

### Certificate Lifecycle

1. **Provisioning**: cert-manager automatically creates certificates when an Ingress with `cert-manager.io/cluster-issuer` annotation is created
2. **Renewal**: Certificates are automatically renewed 30 days before expiration
3. **Storage**: Certificates are stored in Kubernetes Secrets referenced by `secretName`

### Troubleshooting Certificates

Check certificate status:
```bash
kubectl get certificate -A
kubectl describe certificate <name> -n <namespace>
```

Check certificate requests:
```bash
kubectl get certificaterequest -A
kubectl describe certificaterequest <name> -n <namespace>
```

## DNS Configuration

### Wildcard DNS Setup

A wildcard DNS record `*.fawkes.idp` must point to the Ingress Controller's Load Balancer IP.

Get the Load Balancer IP:
```bash
kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
```

Or use the Terraform output:
```bash
cd platform/networking/loadbalancer-provisioning
terraform output ingress_lb_public_ip
```

### ExternalDNS Behavior

ExternalDNS automatically manages DNS records based on Ingress resources:
- Creates A records when Ingress is created
- Updates records when Ingress is modified
- Does not delete records by default (upsert-only policy)

## Security Considerations

### TLS Termination

- TLS termination occurs at the Ingress Controller layer
- Traffic between Ingress Controller and services is plaintext
- For sensitive services, consider using mTLS with a service mesh

### HTTP to HTTPS Redirect

All HTTP requests are automatically redirected to HTTPS. This is enforced at the Ingress Controller level.

### Security Headers

The Ingress Controller adds the following security headers by default:
- `Strict-Transport-Security: max-age=31536000; includeSubDomains`
- Server tokens are hidden

## Monitoring

### Ingress Controller Metrics

Prometheus metrics are available at `/metrics` on the Ingress Controller pods.

Key metrics:
- `nginx_ingress_controller_requests`: Total requests handled
- `nginx_ingress_controller_request_duration_seconds`: Request latency
- `nginx_ingress_controller_ssl_expire_time_seconds`: Certificate expiration

### Access Logs

Access logs are available via:
```bash
kubectl logs -n ingress-nginx -l app.kubernetes.io/component=controller
```

## Troubleshooting

### Common Issues

1. **404 Not Found**: Check that the Ingress host matches the request hostname
2. **503 Service Unavailable**: Verify the backend service is running and endpoints exist
3. **Certificate Not Ready**: Check cert-manager logs and Certificate/CertificateRequest status
4. **DNS Not Resolving**: Verify ExternalDNS is running and has permissions to manage DNS

### Debug Commands

```bash
# Check Ingress Controller status
kubectl get pods -n ingress-nginx

# View Ingress resources
kubectl get ingress -A

# Check cert-manager
kubectl get pods -n cert-manager
kubectl get certificates -A

# Check ExternalDNS
kubectl get pods -n external-dns
kubectl logs -n external-dns -l app.kubernetes.io/name=external-dns
```

## Environment Variables

Add the following to your `.env` file for ingress configuration:

```bash
# Ingress Domain
INGRESS_DOMAIN=fawkes.idp

# TLS Issuer (letsencrypt-staging or letsencrypt-prod)
TLS_CLUSTER_ISSUER=letsencrypt-prod

# Let's Encrypt email for certificate notifications
LETSENCRYPT_EMAIL=platform-admin@fawkes.idp
```
