# Harbor - Container Registry with Security Scanning

## Purpose

Harbor is an open-source container and Helm chart registry that extends Docker Registry with security, identity, and management features. It provides vulnerability scanning, content signing, and role-based access control for all artifacts.

## Key Features

- **Security Scanning**: Integrated Trivy scanner for CVE detection
- **Content Trust**: Image signing and verification
- **RBAC**: Fine-grained access control for projects
- **Replication**: Multi-site image replication
- **Webhook**: Notifications for image events
- **OCI Compliance**: Full OCI artifact support
- **Helm Charts**: Native Helm chart repository

## Deployment

Harbor is deployed via ArgoCD using the official Helm chart. The deployment includes:

- **PostgreSQL Database**: CloudNativePG cluster (db-harbor-dev) with 3 replicas for HA
- **Redis Cache**: Internal Redis for session management and caching
- **Trivy Scanner**: Integrated vulnerability scanner
- **Ingress**: Exposed via nginx-ingress at `harbor.127.0.0.1.nip.io`

### Prerequisites

1. CloudNativePG Operator deployed
2. Ingress-nginx controller running
3. Sufficient storage for container images

### Deploy Harbor

```bash
# Harbor is deployed automatically via ArgoCD
# Check deployment status
kubectl get application harbor -n fawkes

# Monitor pod status
kubectl get pods -n fawkes -l app=harbor

# Wait for all pods to be ready
kubectl wait --for=condition=ready pod -l app=harbor -n fawkes --timeout=600s
```

## Quick Start

### Accessing Harbor

Local development:
```bash
# Access UI
http://harbor.127.0.0.1.nip.io
```

Default credentials:
- Username: `admin`
- Password: `Harbor12345` (⚠️ CHANGE IN PRODUCTION!)

**⚠️ Security Note**: The default password is only suitable for local development. For production deployments:
1. Change the admin password immediately after first login via Harbor UI
2. Generate a secure secret key: `openssl rand -base64 32`
3. Use External Secrets Operator to manage credentials from Vault/cloud provider
4. Enable HTTPS/TLS with proper certificates via cert-manager

### Docker Login

```bash
# Login to Harbor
docker login harbor.127.0.0.1.nip.io
```

### Push an Image

```bash
# Tag image
docker tag myapp:latest harbor.127.0.0.1.nip.io/fawkes/myapp:latest

# Push image
docker push harbor.127.0.0.1.nip.io/fawkes/myapp:latest
```

## Project Structure

| Project | Purpose | Access |
|---------|---------|--------|
| `fawkes` | Platform components | Platform team |
| `library` | Public base images | All users (read) |
| `apps` | Application images | Development teams |

## Security Scanning

Harbor automatically scans all pushed images:

```bash
# View scan results
curl -u admin:Harbor12345 \
  http://harbor.127.0.0.1.nip.io/api/v2.0/projects/fawkes/repositories/myapp/artifacts/latest/scan
```

### Scan Policies

- **On Push**: Scan immediately after image push
- **Daily**: Scheduled scan of all images
- **Critical CVEs**: Block deployment if critical vulnerabilities found

## Integration with Jenkins

```groovy
stage('Build and Push Image') {
    steps {
        script {
            docker.withRegistry('https://harbor.127.0.0.1.nip.io', 'harbor-credentials') {
                def image = docker.build("fawkes/myapp:${BUILD_NUMBER}")
                image.push()
                image.push('latest')
            }
        }
    }
}
```

## Replication

Harbor supports multi-registry replication for disaster recovery:

```yaml
# Replication policy example
name: prod-to-dr
src_registry: harbor.prod.fawkes.io
dest_registry: harbor.dr.fawkes.io
trigger: manual
filters:
  - type: name
    value: "fawkes/**"
```

## Troubleshooting

### Push Failures

```bash
# Check registry connectivity
curl -k https://harbor.127.0.0.1.nip.io/api/v2.0/systeminfo

# View Harbor logs
kubectl logs -n harbor deployment/harbor-core -f
```

### Scan Failures

```bash
# Manually trigger scan
curl -X POST -u admin:Harbor12345 \
  http://harbor.127.0.0.1.nip.io/api/v2.0/projects/fawkes/repositories/myapp/artifacts/latest/scan
```

## Post-Deployment Configuration

After Harbor is deployed, run the configuration script to set up projects and robot accounts:

```bash
# Install dependencies
pip install requests

# Run configuration script
cd platform/apps/harbor
python3 configure_harbor.py \
  --harbor-url http://harbor.127.0.0.1.nip.io \
  --admin-password Harbor12345
```

This script will:
- Create projects: `fawkes`, `apps`, `library`
- Configure automatic vulnerability scanning
- Create robot accounts for CI/CD pipelines
- Display robot tokens for Jenkins/GitLab configuration

## Database Management

Harbor uses an external PostgreSQL database managed by CloudNativePG:

```bash
# Check database cluster status
kubectl get cluster db-harbor-dev -n fawkes

# View database pods
kubectl get pods -n fawkes -l cnpg.io/cluster=db-harbor-dev

# Connect to database (for debugging)
kubectl exec -it db-harbor-dev-1 -n fawkes -- psql -U harbor_user -d harbor
```

## Related Documentation

- [Harbor Documentation](https://goharbor.io/docs/)
- [Trivy Scanner](https://github.com/aquasecurity/trivy)
- [CloudNativePG](https://cloudnative-pg.io/)
