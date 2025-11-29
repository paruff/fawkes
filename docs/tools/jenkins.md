---
title: Jenkins Integration
description: Implementing continuous integration and deployment with Jenkins in Fawkes
---

# Jenkins

![Jenkins Logo](../assets/images/tools/jenkins.png){ width="300" }

Jenkins is an open-source automation server that enables continuous integration and continuous delivery (CI/CD) for software development projects.

## Overview

Jenkins provides robust automation capabilities:
- **Build Automation** - Compile and test code automatically
- **Deployment Pipeline** - Create sophisticated deployment workflows
- **Plugin Ecosystem** - Extend functionality through thousands of plugins

## Key Features

| Feature | Description |
|---------|-------------|
| ![](../assets/images/icons/pipeline.png){ width="24" } Pipeline as Code | Define pipelines using Jenkinsfile |
| ![](../assets/images/icons/plugins.png){ width="24" } Plugin System | Extensive plugin ecosystem |
| ![](../assets/images/icons/distributed.png){ width="24" } Distributed Builds | Scale with master/agent architecture |
| ![](../assets/images/icons/security.png){ width="24" } Security Features | Built-in security and authentication |

## Quick Start - Local Access

### Step 1: Create Admin Secret

Before deploying Jenkins, create the admin credentials secret:

```bash
# Create namespace and secret
kubectl create namespace fawkes

# Create secret with your own secure password
kubectl create secret generic jenkins-admin \
  --from-literal=username=admin \
  --from-literal=password=YOUR_SECURE_PASSWORD \
  -n fawkes
```

> ⚠️ **Security Note**: Never commit plaintext passwords. Use Kubernetes secrets or External Secrets Operator.

### Step 2: Deploy Jenkins

Jenkins is automatically deployed by ArgoCD. Verify it's running:

```bash
kubectl get pods -n fawkes -l app.kubernetes.io/name=jenkins
```

### Step 3: Access Jenkins UI

```bash
# Port-forward to local machine
kubectl port-forward -n fawkes svc/jenkins 8080:8080

# Open in browser
open http://localhost:8080
```

### Step 4: Login

- **Username**: `admin`
- **Password**: Retrieve from secret:
  ```bash
  kubectl get secret jenkins-admin -n fawkes -o jsonpath='{.data.password}' | base64 -d
  ```

## Installation Methods

### Method 1: Via ArgoCD (Recommended)

ArgoCD automatically deploys Jenkins from `platform/apps/jenkins-application.yaml`:

```bash
# Ensure secret exists first
kubectl create secret generic jenkins-admin \
  --from-literal=username=admin \
  --from-literal=password=YOUR_PASSWORD -n fawkes

# Check ArgoCD sync status
argocd app get jenkins -n fawkes

# Force sync if needed
argocd app sync jenkins -n fawkes
```

### Method 2: Using Helm Directly

```bash
# Add Jenkins Helm repo
helm repo add jenkins https://charts.jenkins.io
helm repo update

# Create admin secret first
kubectl create secret generic jenkins-admin \
  --from-literal=username=admin \
  --from-literal=password=YOUR_PASSWORD -n fawkes

# Install with custom values
helm upgrade --install jenkins jenkins/jenkins \
  -f platform/apps/jenkins/values.yaml \
  -n fawkes \
  --create-namespace
```

### Method 3: Using deploy-local.sh

```bash
# Deploy Jenkins to local cluster (creates secret automatically)
./infra/local-dev/deploy-local.sh fawkes jenkins
```

## Configuration

### Helm Values

The main configuration is in `platform/apps/jenkins/values.yaml`:

```yaml
controller:
  image:
    tag: "2.479.1-lts-jdk21"
  admin:
    username: admin
    existingSecret: jenkins-admin  # Reference to Kubernetes secret
    userKey: username
    passwordKey: password
  serviceType: ClusterIP
  installPlugins:
    - kubernetes:4371.vb_33b_086d54a_1
    - workflow-aggregator:608.v67378e9d3db_1
    - git:5.7.0
    - configuration-as-code:1985.vdda_32d0c4ea_b_

persistence:
  enabled: false  # For local dev
```

### Credential Management

#### For Local Development

```bash
# Generate and create secret
JENKINS_PASSWORD=$(openssl rand -base64 24)
kubectl create secret generic jenkins-admin \
  --from-literal=username=admin \
  --from-literal=password="$JENKINS_PASSWORD" \
  -n fawkes
echo "Password: $JENKINS_PASSWORD"
```

#### For Production (External Secrets Operator)

```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: jenkins-admin
  namespace: fawkes
spec:
  secretStoreRef:
    kind: ClusterSecretStore
    name: aws-secrets-manager
  target:
    name: jenkins-admin
  data:
    - secretKey: username
      remoteRef:
        key: jenkins/admin/username
    - secretKey: password
      remoteRef:
        key: jenkins/admin/password
```

### Jenkins Configuration as Code (JCasC)

Jenkins is configured via JCasC in `platform/apps/jenkins/jcasc.yaml`:

- Security realm configuration
- Authorization strategy
- Kubernetes cloud for dynamic agents
- Agent pod templates

## Cloud Access

For cloud deployments with ingress enabled:

```yaml
controller:
  ingress:
    enabled: true
    ingressClassName: nginx
    hostName: jenkins.your-domain.com
```

Access via: `https://jenkins.your-domain.com`

## Kubernetes Agents

Jenkins uses Kubernetes plugin for dynamic agent provisioning:

```groovy
pipeline {
    agent {
        kubernetes {
            label 'k8s-agent'
            defaultContainer 'jnlp'
        }
    }
    stages {
        stage('Build') {
            steps {
                sh 'echo "Building on Kubernetes agent"'
            }
        }
    }
}
```

```groovy
// Jenkinsfile
pipeline {
    agent any

    stages {
        stage('Build') {
            steps {
                sh 'mvn clean package'
            }
        }
        stage('Test') {
            steps {
                sh 'mvn test'
            }
        }
        stage('Deploy') {
            steps {
                sh 'kubectl apply -f k8s/'
            }
        }
    }

    post {
        always {
            junit '**/target/surefire-reports/TEST-*.xml'
        }
    }
}
```

### Advanced Pipeline with Fawkes Integration

```groovy
// Jenkinsfile for Fawkes deployment
pipeline {
    agent {
        kubernetes {
            yaml '''
                apiVersion: v1
                kind: Pod
                spec:
                  containers:
                  - name: maven
                    image: maven:3.8.4-openjdk-11
                    command:
                    - cat
                    tty: true
                  - name: kubectl
                    image: bitnami/kubectl
                    command:
                    - cat
                    tty: true
            '''
        }
    }

    stages {
        stage('Build & Test') {
            steps {
                container('maven') {
                    sh 'mvn clean verify'
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                container('kubectl') {
                    sh '''
                        kubectl apply -f k8s/
                        kubectl rollout status deployment/fawkes-app
                    '''
                }
            }
        }
    }
}
```

## Best Practices

1. **Pipeline as Code**
   - Store Jenkinsfile in version control
   - Use declarative pipeline syntax
   - Keep pipelines simple and modular

2. **Security**
   - Use credentials management
   - Implement role-based access control
   - Regular security updates

3. **Performance**
   - Use agent nodes for distribution
   - Clean workspace regularly
   - Optimize build steps

## Troubleshooting

Common issues and solutions:

| Issue | Solution |
|-------|----------|
| Pipeline fails to start | Check Jenkins agent connectivity |
| Build fails | Verify build tool configuration |
| Deployment fails | Check Kubernetes credentials |

## Monitoring Jenkins

```yaml
# Prometheus configuration
- job_name: 'jenkins'
  metrics_path: /prometheus
  static_configs:
    - targets: ['jenkins.fawkes.local:8080']
```

## Additional Resources

- [Jenkins Documentation](https://www.jenkins.io/doc/)
- [Jenkins GitHub](https://github.com/jenkinsci/jenkins)
- [Jenkins Plugins](https://plugins.jenkins.io/)

[Configure Jenkins :octicons-gear-16:](../configuration.md#jenkins){ .md-button .md-button--primary }
[View Examples :octicons-code-16:](../examples/jenkins.md){ .md-button }