# Jenkins CI/CD Service

## Purpose

Jenkins provides automated build, test, and deployment pipelines for all Fawkes applications. It implements the **Golden Path CI/CD** pattern to ensure consistent, secure, and well-tested container images.

## Golden Path CI/CD

The Golden Path is a standardized pipeline that enforces trunk-based development principles:

- **Trunk-Based Development**: Artifacts are only produced from the main branch
- **Security First**: Mandatory security scanning (SonarQube, Trivy, dependency checks)
- **Quality Gates**: Automated testing and code quality enforcement
- **GitOps Ready**: Produces versioned artifacts for ArgoCD deployment

### Quick Start

Add a minimal `Jenkinsfile` to your repository:

```groovy
@Library('fawkes-pipeline-library') _

goldenPathPipeline {
    appName = 'my-service'
    language = 'java'  // java, python, node, go
}
```

See [jenkins-shared-library/README.md](../../jenkins-shared-library/README.md) for full documentation.

## Files

- `jcasc.yaml` - Jenkins Configuration as Code (JCasC)
- `values.yaml` - Helm values for Jenkins deployment
- `jenkins-admin-secret.yaml` - Admin credentials secret
- `jenkins-casc-configmap.yaml` - JCasC ConfigMap

## Configuration

### Kubernetes Plugin

Jenkins uses the Kubernetes plugin for dynamic agent provisioning:

- Agents are created on-demand as Kubernetes pods
- Each build runs in isolated containers
- Agents are destroyed after build completion
- Resource-efficient and scalable

### Pre-configured Agent Templates

| Agent | Labels | Languages/Tools |
|-------|--------|-----------------|
| maven-agent | `maven`, `java` | Java, Maven |
| python-agent | `python` | Python, pip |
| node-agent | `node`, `nodejs` | Node.js, npm |
| go-agent | `go`, `golang` | Go |

### Shared Library

The Fawkes shared library is automatically loaded:

```yaml
globalLibraries:
  libraries:
    - name: "fawkes-pipeline-library"
      defaultVersion: "main"
      implicit: true
```

## Dependencies

- PostgreSQL (job history)
- Harbor (artifact storage)
- GitHub (source code)
- SonarQube (code quality)
- ArgoCD (GitOps deployment)
- Mattermost (notifications)

## DORA Capabilities

- **Continuous Integration**: Automated build and test
- **Deployment Automation**: GitOps-triggered deployments
- **Test Automation**: Unit, BDD, and security testing
- **Metrics Collection**: Build and deployment metrics

## Security

- TLS/HTTPS via Ingress with cert-manager
- RBAC for access control
- Credentials managed via Kubernetes secrets
- Security scanning with SonarQube and Trivy

**⚠️ Development Credentials:**

The default configuration uses hardcoded credentials for local development:
- Username: `admin`
- Password: `fawkesidp`

**🔒 Production Deployment:**

For production deployments, you MUST:

1. Replace hardcoded password with Secret reference:
   ```yaml
   extraEnv:
     - name: ADMIN_PASSWORD
       valueFrom:
         secretKeyRef:
           name: jenkins-admin-secret
           key: password
   ```

2. Create the secret:
   ```bash
   kubectl create secret generic jenkins-admin-secret \
     --from-literal=password='YOUR_SECURE_PASSWORD' \
     -n fawkes
   ```

3. Update the ArgoCD Application to reference the secret instead of hardcoded value

4. Consider using OAuth/OIDC integration for authentication (see `jcasc.yaml` for GitHub OAuth example)

## Troubleshooting

### Common Issues

1. **Build timeout**: Increase `timeoutMinutes` in Jenkinsfile
2. **SonarQube fails**: Check SonarQube credentials and project configuration
3. **Docker push fails**: Verify registry credentials in Jenkins
4. **Agent not starting**: Check Kubernetes RBAC and service account

### View Logs

```bash
kubectl logs -n fawkes deployment/jenkins -f
```

### Access Jenkins

Local development:
```
http://jenkins.127.0.0.1.nip.io
```

Default credentials:
- Username: `admin`
- Password: `fawkesidp` (change in production!)
