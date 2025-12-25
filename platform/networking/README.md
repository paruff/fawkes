# Fawkes Networking Stack

This directory contains the networking infrastructure for the Fawkes platform, providing secure ingress access with automated DNS and TLS management.

## Components

### 1. NGINX Ingress Controller (`ingress-controller/`)

High-availability Layer 7 Ingress Controller with:
- 2 replicas with pod anti-affinity for HA
- TLS termination and automatic HTTPS redirect
- Security headers (HSTS, hide server tokens)
- Prometheus metrics
- Default backend for 404 responses

### 2. cert-manager (`cert-manager/`)

Automatic TLS certificate provisioning with:
- Let's Encrypt integration (staging and production)
- Self-signed issuer for internal services
- Automatic certificate renewal
- High availability configuration

### 3. ExternalDNS (`external-dns/`)

Automated DNS record management with:
- AWS Route53 support (configurable for other providers)
- Automatic record creation from Ingress resources
- TXT record ownership tracking
- Upsert-only policy for safety

### 4. ClusterIssuer (`tls-cluster-issuer.yaml`)

Certificate issuers for cert-manager:
- `letsencrypt-staging`: Testing without rate limits
- `letsencrypt-prod`: Production certificates
- `selfsigned-issuer`: Internal/development use

### 5. Load Balancer Provisioning (`loadbalancer-provisioning/`)

Terraform configuration for:
- Static Elastic IP allocation
- AWS NLB configuration
- DNS record value output

## Deployment Order

Components are deployed in the following order using ArgoCD sync waves:

1. `cert-manager` (wave -3): Required for TLS
2. `ingress-nginx` (wave -2): Ingress controller
3. `external-dns` (wave -1): DNS management
4. `ClusterIssuers` (wave 0): Certificate issuers

## Prerequisites

1. **Kubernetes cluster** with ArgoCD installed
2. **Cloud provider credentials** for:
   - Load balancer provisioning
   - DNS management (Route53, Azure DNS, etc.)
3. **Domain configured**: `*.fawkes.idp` pointing to Load Balancer IP

## Quick Start

1. Deploy the networking stack via ArgoCD:
   ```bash
   kubectl apply -f platform/networking/networking-application.yaml
   ```

2. Provision the static IP (optional, for predictable DNS):
   ```bash
   cd platform/networking/loadbalancer-provisioning
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your values
   terraform init && terraform apply
   ```

3. Configure wildcard DNS:
   ```bash
   # Get the Load Balancer IP
   kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}'

   # Create DNS record: *.fawkes.idp -> <Load Balancer IP>
   ```

## Creating Ingress Resources

See [Ingress Access Guide](../../docs/ingress-access.md) for detailed instructions on creating Ingress resources with TLS.

### Quick Example

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-service
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
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

## Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `INGRESS_DOMAIN` | `fawkes.idp` | Base domain for ingress |
| `TLS_CLUSTER_ISSUER` | `letsencrypt-prod` | Default certificate issuer |
| `LETSENCRYPT_EMAIL` | `platform-admin@fawkes.idp` | Let's Encrypt notification email |
| `DNS_PROVIDER` | `aws` | DNS provider for ExternalDNS |

### Cloud Provider Setup

#### AWS

1. Create IAM role for ExternalDNS with Route53 permissions
2. Configure IRSA (IAM Roles for Service Accounts)
3. Update `external-dns/helm-release.yaml` with role ARN

#### Azure

1. Create Managed Identity with DNS Zone Contributor role
2. Configure Workload Identity
3. Update ExternalDNS provider to `azure`

## Monitoring

### Prometheus Metrics

- NGINX Ingress: `nginx_ingress_controller_*`
- cert-manager: `certmanager_*`
- ExternalDNS: `external_dns_*`

### Grafana Dashboards

Import the following dashboards:
- NGINX Ingress: [Dashboard 9614](https://grafana.com/grafana/dashboards/9614)
- cert-manager: [Dashboard 11001](https://grafana.com/grafana/dashboards/11001)

## Troubleshooting

### Certificate Not Ready

```bash
kubectl get certificate -A
kubectl describe certificaterequest <name> -n <namespace>
kubectl logs -n cert-manager -l app=cert-manager
```

### DNS Not Resolving

```bash
kubectl get pods -n external-dns
kubectl logs -n external-dns -l app.kubernetes.io/name=external-dns
```

### Ingress Not Working

```bash
kubectl get pods -n ingress-nginx
kubectl logs -n ingress-nginx -l app.kubernetes.io/component=controller
kubectl describe ingress <name> -n <namespace>
```

## Security Considerations

- TLS termination occurs at the Ingress Controller
- Traffic within the cluster is plaintext
- HSTS is enabled by default
- Server tokens are hidden
- HTTP is automatically redirected to HTTPS
