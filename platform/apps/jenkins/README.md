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

- `jcasc.yaml` - Jenkins Configuration as Code (JCasC) - Main configuration file
- `jenkins-application.yaml` - ArgoCD Application with Helm values and plugin list
- `credentials-secrets.yaml` - Kubernetes Secrets for Jenkins credentials (template)
- `jenkins-admin-secret.yaml` - Admin credentials secret (deprecated, use credentials-secrets.yaml)
- `jenkins-casc-configmap.yaml` - JCasC ConfigMap (standalone deployment option)
- `secrets.yaml` - Legacy secrets file (superseded by credentials-secrets.yaml)
- `values.yaml` - Standalone Helm values file (optional)

## Jenkins Configuration as Code (JCasC)

Jenkins is configured entirely through code using the JCasC plugin. This provides:

✅ **Reproducible Configuration** - Same setup every time
✅ **Version Control** - All config changes tracked in Git
✅ **GitOps Ready** - ArgoCD manages Jenkins deployment
✅ **No Manual Setup** - Zero UI clicks required
✅ **Disaster Recovery** - Restore from Git in minutes

### Quick Start with JCasC

1. **Review Configuration**: See `jcasc.yaml` for full configuration
2. **Set Credentials**: Create secrets in Kubernetes (see `credentials-secrets.yaml`)
3. **Deploy**: ArgoCD automatically deploys and applies configuration
4. **Verify**: Check Jenkins UI to confirm settings

### JCasC Configuration Sections

| Section                 | Purpose           | Configured Items                      |
| ----------------------- | ----------------- | ------------------------------------- |
| `jenkins`               | Core settings     | System message, executors, mode       |
| `clouds`                | Kubernetes plugin | Agent templates, pod specs            |
| `credentials`           | Secret management | GitHub, SonarQube, Docker credentials |
| `securityRealm`         | Authentication    | Local users, OAuth/OIDC               |
| `authorizationStrategy` | Access control    | Permissions, RBAC                     |
| `unclassified`          | Integrations      | Libraries, SonarQube, Mattermost      |
| `tool`                  | Build tools       | Git, Maven, Node.js                   |
| `security`              | Script approval   | Whitelisted methods                   |

### Documentation

📚 **Comprehensive Guide**: See [docs/how-to/jenkins-casc-configuration.md](../../../docs/how-to/jenkins-casc-configuration.md) for:

- Architecture overview
- Configuration examples
- Credentials management
- Troubleshooting guide
- Best practices

## Configuration

### Kubernetes Plugin

Jenkins uses the Kubernetes plugin for dynamic agent provisioning:

- Agents are created on-demand as Kubernetes pods
- Each build runs in isolated containers
- Agents are destroyed after build completion
- Resource-efficient and scalable

### Pre-configured Agent Templates

| Agent        | Labels           | Languages/Tools |
| ------------ | ---------------- | --------------- |
| maven-agent  | `maven`, `java`  | Java, Maven     |
| python-agent | `python`         | Python, pip     |
| node-agent   | `node`, `nodejs` | Node.js, npm    |
| go-agent     | `go`, `golang`   | Go              |

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

The default configuration uses placeholder credentials that must be changed:

- Username: `admin`
- Password: `CHANGE_ME_jenkins_admin_password`

**🔒 Production Deployment:**

For production deployments, you MUST:

1. Update the secrets file:

   ```bash
   # Edit platform/apps/jenkins/secrets.yaml
   # Replace CHANGE_ME_jenkins_admin_password with a strong password

   # Apply the secret
   kubectl apply -f platform/apps/jenkins/secrets.yaml
   ```

2. Update jenkins-application.yaml to reference the secret:

   ```yaml
   extraEnv:
     - name: ADMIN_PASSWORD
       valueFrom:
         secretKeyRef:
           name: jenkins-admin-credentials
           key: password

   admin:
     password: "{{ .Values.adminPassword }}" # Reference from secret

   JENKINS_OPTS: "--argumentsRealm.passwd.admin={{ .Values.adminPassword }} -Djenkins.install.runSetupWizard=false"
   ```

3. For production, use External Secrets Operator:

   ```bash
   # Configure external secret to pull from AWS Secrets Manager or Azure Key Vault
   kubectl apply -f platform/apps/external-secrets/externalsecret-jenkins-admin.yaml
   ```

4. Consider using OAuth/OIDC integration for authentication (see `jcasc.yaml` for GitHub OAuth example)

**Note:** Never commit actual passwords to Git. Always use `CHANGE_ME_*` placeholders.

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

Credentials:

- Username: `admin`
- Password: Set in `platform/apps/jenkins/secrets.yaml` (must be configured before deployment)
