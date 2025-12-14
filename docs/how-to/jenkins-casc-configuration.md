# Jenkins Configuration as Code (JCasC) Guide

## Overview

Jenkins Configuration as Code (JCasC) allows you to define Jenkins configuration in YAML files, making it version-controlled, reproducible, and fully automated. This eliminates manual UI configuration and enables GitOps workflows.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    GitOps Repository                        │
│                                                             │
│  platform/apps/jenkins/                                     │
│    ├── jcasc.yaml                  # JCasC configuration   │
│    ├── credentials-secrets.yaml    # K8s secrets           │
│    └── jenkins-application.yaml    # ArgoCD app + plugins  │
└─────────────────┬───────────────────────────────────────────┘
                  │
                  ▼ (ArgoCD sync)
┌─────────────────────────────────────────────────────────────┐
│              Kubernetes Cluster (fawkes namespace)          │
│                                                             │
│  ┌───────────────────────────────────────────────────────┐ │
│  │ ConfigMap: jenkins-casc                                │ │
│  │   data:                                                │ │
│  │     jcasc.yaml: |                                      │ │
│  │       jenkins:                                         │ │
│  │         systemMessage: "..."                           │ │
│  │         clouds: ...                                    │ │
│  └───────────────────────────────────────────────────────┘ │
│                  │                                          │
│                  ▼ (mounted as volume)                      │
│  ┌───────────────────────────────────────────────────────┐ │
│  │ Pod: jenkins-0                                         │ │
│  │   Containers:                                          │ │
│  │     - jenkins                                          │ │
│  │       env:                                             │ │
│  │         - ADMIN_PASSWORD (from Secret)                 │ │
│  │         - GITHUB_TOKEN (from Secret)                   │ │
│  │         - SONARQUBE_TOKEN (from Secret)                │ │
│  │       volumeMounts:                                    │ │
│  │         - /var/jenkins_home/casc_configs/jcasc.yaml    │ │
│  └───────────────────────────────────────────────────────┘ │
│                  │                                          │
│                  ▼ (JCasC plugin loads)                     │
│  ┌───────────────────────────────────────────────────────┐ │
│  │ Jenkins Configuration Applied:                         │ │
│  │   ✅ System settings                                   │ │
│  │   ✅ Kubernetes cloud                                  │ │
│  │   ✅ Agent templates                                   │ │
│  │   ✅ Credentials                                       │ │
│  │   ✅ Global libraries                                  │ │
│  │   ✅ Security settings                                 │ │
│  │   ✅ Tool installations                                │ │
│  └───────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

## Configuration Structure

The JCasC configuration is organized into sections:

### 1. Jenkins Core Settings

```yaml
jenkins:
  systemMessage: "Fawkes CI/CD Platform - Golden Path Enabled"
  mode: NORMAL
  numExecutors: 0  # No builds on controller
```

### 2. Kubernetes Cloud Configuration

```yaml
  clouds:
    - kubernetes:
        name: "kubernetes"
        namespace: "fawkes"
        jenkinsUrl: "http://jenkins:8080"
        jenkinsTunnel: "jenkins-agent:50000"
        containerCapStr: "20"
        templates:
          - name: "maven-agent"
            label: "maven java"
            # ... agent configuration
```

### 3. Security Realm & Authorization

```yaml
securityRealm:
  local:
    allowsSignup: false
    users:
      - id: "admin"
        password: "${ADMIN_PASSWORD}"

authorizationStrategy:
  loggedInUsersCanDoAnything:
    allowAnonymousRead: false
```

### 4. Credentials

```yaml
credentials:
  system:
    domainCredentials:
      - credentials:
          - string:
              scope: GLOBAL
              id: "github-token"
              secret: "${GITHUB_TOKEN}"
          - string:
              scope: GLOBAL
              id: "sonarqube-token"
              secret: "${SONARQUBE_TOKEN}"
```

### 5. Global Libraries

```yaml
unclassified:
  globalLibraries:
    libraries:
      - name: "fawkes-pipeline-library"
        defaultVersion: "main"
        implicit: true
        retriever:
          modernSCM:
            scm:
              git:
                remote: "https://github.com/paruff/fawkes"
                credentialsId: "github-token"
            libraryPath: "jenkins-shared-library"
```

### 6. Tool Installations

```yaml
tool:
  git:
    installations:
      - name: "Default"
        home: "git"
  maven:
    installations:
      - name: "Maven 3.9"
        properties:
          - installSource:
              installers:
                - maven:
                    id: "3.9.6"
```

## Plugin Management

Plugins are managed via Helm values in `jenkins-application.yaml`:

```yaml
controller:
  installPlugins:
    # Core Pipeline
    - kubernetes:latest
    - workflow-aggregator:latest
    - configuration-as-code:latest
    # Source Control
    - git:latest
    - github:latest
    # Security Scanning
    - sonar:latest
    # ... see jenkins-application.yaml for full list
```

### Required Plugins for JCasC

The following plugins are **REQUIRED** for JCasC to work:

- `configuration-as-code` - JCasC plugin itself
- `kubernetes` - Kubernetes cloud configuration
- `workflow-aggregator` - Pipeline support
- `credentials` - Credentials management
- `git` - Git integration

See `platform/apps/jenkins/jcasc.yaml` (bottom section) for complete list.

## Credentials Management

### Development/Local Setup

1. Create a Kubernetes Secret (using secure method to avoid shell history):

```bash
# Method 1: Using --from-file (recommended)
echo -n "ghp_your_token" > /tmp/github-token
echo -n "squ_your_token" > /tmp/sonarqube-token
echo -n "admin" > /tmp/docker-username
echo -n "your_password" > /tmp/docker-password

kubectl create secret generic jenkins-credentials \
  -n fawkes \
  --from-file=GITHUB_TOKEN=/tmp/github-token \
  --from-file=SONARQUBE_TOKEN=/tmp/sonarqube-token \
  --from-file=DOCKER_REGISTRY_USERNAME=/tmp/docker-username \
  --from-file=DOCKER_REGISTRY_PASSWORD=/tmp/docker-password

# Clean up temporary files
shred -u /tmp/github-token /tmp/sonarqube-token /tmp/docker-username /tmp/docker-password

# Method 2: Using stdin (also recommended)
kubectl create secret generic jenkins-credentials -n fawkes \
  --from-literal=GITHUB_TOKEN="$(read -s -p 'GitHub Token: ' token && echo $token)" \
  --from-literal=SONARQUBE_TOKEN="$(read -s -p 'SonarQube Token: ' token && echo $token)" \
  --from-literal=DOCKER_REGISTRY_USERNAME="$(read -p 'Docker Username: ' user && echo $user)" \
  --from-literal=DOCKER_REGISTRY_PASSWORD="$(read -s -p 'Docker Password: ' pass && echo $pass)"
```

**Security Note**: Never use `--from-literal` with plaintext values as shown in simple examples, as this exposes credentials in:
- Shell history (`.bash_history`, `.zsh_history`)
- Process listings (`ps aux`)
- Kubernetes audit logs

2. Reference in Jenkins pod:

```yaml
extraEnv:
  - name: GITHUB_TOKEN
    valueFrom:
      secretKeyRef:
        name: jenkins-credentials
        key: GITHUB_TOKEN
  - name: SONARQUBE_TOKEN
    valueFrom:
      secretKeyRef:
        name: jenkins-credentials
        key: SONARQUBE_TOKEN
```

3. Use in JCasC:

```yaml
credentials:
  system:
    domainCredentials:
      - credentials:
          - string:
              id: "github-token"
              secret: "${GITHUB_TOKEN}"
```

### Production Setup with External Secrets Operator

For production environments, use External Secrets Operator to sync from:
- AWS Secrets Manager
- Azure Key Vault
- HashiCorp Vault
- GCP Secret Manager

1. Create ExternalSecret:

```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: jenkins-credentials
  namespace: fawkes
spec:
  refreshInterval: 1h
  secretStoreRef:
    kind: ClusterSecretStore
    name: aws-secrets-manager
  target:
    name: jenkins-credentials
    creationPolicy: Owner
  data:
    - secretKey: GITHUB_TOKEN
      remoteRef:
        key: jenkins/github/token
```

2. Deploy:

```bash
kubectl apply -f platform/apps/external-secrets/externalsecret-jenkins-credentials.yaml
```

3. Jenkins will automatically use the synced secret.

## Making Configuration Changes

### 1. Local Development Flow

```bash
# 1. Edit JCasC configuration
vim platform/apps/jenkins/jcasc.yaml

# 2. Validate YAML syntax
yamllint platform/apps/jenkins/jcasc.yaml

# 3. Apply ConfigMap (if using standalone ConfigMap)
kubectl apply -f platform/apps/jenkins/jenkins-casc-configmap.yaml

# 4. Restart Jenkins to reload configuration
kubectl rollout restart deployment/jenkins -n fawkes

# 5. Verify configuration loaded
kubectl logs -n fawkes deployment/jenkins | grep -i casc
```

### 2. GitOps Flow (Recommended)

```bash
# 1. Create feature branch
git checkout -b feature/jenkins-config-update

# 2. Edit JCasC configuration
vim platform/apps/jenkins/jcasc.yaml

# 3. Commit and push
git add platform/apps/jenkins/jcasc.yaml
git commit -m "Update Jenkins JCasC configuration"
git push origin feature/jenkins-config-update

# 4. Create pull request and merge

# 5. ArgoCD syncs automatically (or manually)
argocd app sync jenkins

# 6. Verify in Jenkins UI
# Configuration should be reloaded automatically
```

### 3. Testing Configuration Locally

```bash
# Use Jenkins Configuration as Code plugin CLI
docker run --rm -v $(pwd)/platform/apps/jenkins/jcasc.yaml:/jcasc.yaml \
  jenkins/jenkins:lts-jdk17 \
  jenkins-plugin-cli --list

# Or validate in live Jenkins
kubectl exec -n fawkes jenkins-0 -- \
  java -jar /usr/share/jenkins/jenkins.war \
  --version
```

## Troubleshooting

### Configuration Not Loading

1. Check JCasC plugin is installed:

```bash
kubectl exec -n fawkes jenkins-0 -- jenkins-plugin-cli --list | grep configuration-as-code
```

2. Check ConfigMap is mounted:

```bash
kubectl exec -n fawkes jenkins-0 -- ls -la /var/jenkins_home/casc_configs/
```

3. Check Jenkins logs for errors:

```bash
kubectl logs -n fawkes deployment/jenkins | grep -i "configuration as code"
```

### Environment Variables Not Resolved

1. Verify secret exists:

```bash
kubectl get secret jenkins-credentials -n fawkes -o yaml
```

2. Check environment variables in pod:

```bash
kubectl exec -n fawkes jenkins-0 -- env | grep -E "GITHUB_TOKEN|SONARQUBE_TOKEN"
```

### Plugin Compatibility Issues

1. Check plugin versions:

```bash
kubectl exec -n fawkes jenkins-0 -- jenkins-plugin-cli --list
```

2. Update plugins in `jenkins-application.yaml`:

```yaml
controller:
  installPlugins:
    - kubernetes:4029.v5712230ccb_f8  # Pin specific version
```

### Credentials Not Working in Pipelines

1. Verify credentials are loaded:

```bash
# Access Jenkins UI
# Manage Jenkins > Credentials > System > Global credentials
```

2. Check credential ID matches in pipeline:

```groovy
pipeline {
    stages {
        stage('Test') {
            steps {
                withCredentials([string(credentialsId: 'github-token', variable: 'GITHUB_TOKEN')]) {
                    sh 'echo "Token: $GITHUB_TOKEN"'
                }
            }
        }
    }
}
```

## Best Practices

### 1. Version Control Everything

✅ **DO:**
- Store all configuration in Git
- Use meaningful commit messages
- Create pull requests for changes
- Review changes before merging

❌ **DON'T:**
- Make manual changes via UI (they will be overwritten)
- Commit secrets to Git
- Skip code review for configuration changes

### 2. Secret Management

✅ **DO:**
- Use External Secrets Operator in production
- Rotate credentials regularly
- Use minimal required permissions
- Audit secret access

❌ **DON'T:**
- Commit real credentials to Git
- Use default/weak passwords
- Share credentials between environments

### 3. Plugin Management

✅ **DO:**
- Pin plugin versions in production
- Test plugin updates in dev first
- Document required plugins
- Keep plugins up to date

❌ **DON'T:**
- Use `:latest` tag in production
- Install unnecessary plugins
- Skip security updates

### 4. Testing

✅ **DO:**
- Test configuration in dev environment
- Validate YAML syntax before commit
- Check Jenkins logs after changes
- Have rollback plan

❌ **DON'T:**
- Test directly in production
- Skip validation
- Deploy without monitoring
- Forget to backup configuration

## Configuration Examples

### Adding a New Kubernetes Agent Template

```yaml
templates:
  - name: "rust-agent"
    label: "rust cargo"
    remoteFs: "/home/jenkins"
    instanceCapStr: "5"
    idleTerminationMinutes: 10
    containers:
      - name: "rust"
        image: "rust:1.75"
        command: "cat"
        ttyEnabled: true
        resourceRequestCpu: "500m"
        resourceRequestMemory: "1Gi"
        resourceLimitCpu: "2"
        resourceLimitMemory: "4Gi"
      - name: "jnlp"
        image: "jenkins/inbound-agent:latest"
        args: "${computer.jnlpmac} ${computer.name}"
```

### Adding OAuth/OIDC Authentication

```yaml
securityRealm:
  github:
    githubWebUri: "https://github.com"
    githubApiUri: "https://api.github.com"
    clientID: "${GITHUB_OAUTH_CLIENT_ID}"
    clientSecret: "${GITHUB_OAUTH_CLIENT_SECRET}"
    oauthScopes: "read:org,user:email"
```

### Adding Role-Based Access Control

```yaml
authorizationStrategy:
  roleBased:
    roles:
      global:
        - name: "admin"
          permissions:
            - "Overall/Administer"
          assignments:
            - "admin"
        - name: "developer"
          permissions:
            - "Overall/Read"
            - "Job/Build"
            - "Job/Read"
          assignments:
            - "authenticated"
```

## References

- [JCasC Plugin Documentation](https://github.com/jenkinsci/configuration-as-code-plugin)
- [JCasC Examples](https://github.com/jenkinsci/configuration-as-code-plugin/tree/master/demos)
- [Jenkins Kubernetes Plugin](https://plugins.jenkins.io/kubernetes/)
- [External Secrets Operator](https://external-secrets.io/)
- [Fawkes Architecture](../architecture.md)

## Related Documentation

- [Jenkins README](../../platform/apps/jenkins/README.md)
- [Jenkins Pipelines Guide](../copilot/jenkins-pipelines.md)
- [Golden Path CI/CD](../../jenkins-shared-library/README.md)
- [External Secrets Setup](../how-to/external-secrets-setup.md)
