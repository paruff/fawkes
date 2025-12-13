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

## Quick Start

### Accessing Harbor

Local development:
```bash
# Access UI
http://harbor.127.0.0.1.nip.io
```

Default credentials:
- Username: `admin`
- Password: `Harbor12345` (change in production!)

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

## Related Documentation

- [Harbor Documentation](https://goharbor.io/docs/)
- [Trivy Scanner](https://github.com/aquasecurity/trivy)
