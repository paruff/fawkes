# Jenkins Deployment with Kubernetes Plugin - Verification Guide

## Overview

This guide provides step-by-step instructions to verify that Jenkins has been successfully deployed via ArgoCD with the Kubernetes plugin configured for dynamic agent provisioning.

## Prerequisites

- Kubernetes cluster access
- `kubectl` CLI configured
- ArgoCD CLI (`argocd`) installed (optional)
- Access to Jenkins URL: `http://jenkins.127.0.0.1.nip.io`

## Verification Steps

### 1. Verify ArgoCD Application

Check that the Jenkins ArgoCD Application exists and is synced:

```bash
# Using kubectl
kubectl get application jenkins -n fawkes -o yaml

# Or using ArgoCD CLI
argocd app get jenkins
```

**Expected output:**
- Status: `Synced` and `Healthy`
- Sync Status: `Synced`
- Health Status: `Healthy`

### 2. Verify Jenkins Deployment

Check that the Jenkins deployment is running:

```bash
kubectl get deployment jenkins -n fawkes
```

**Expected output:**
```
NAME      READY   UP-TO-DATE   AVAILABLE   AGE
jenkins   1/1     1            1           5m
```

### 3. Verify Jenkins Pod

Check that the Jenkins pod is running:

```bash
kubectl get pods -n fawkes -l app.kubernetes.io/name=jenkins
```

**Expected output:**
```
NAME        READY   STATUS    RESTARTS   AGE
jenkins-0   2/2     Running   0          5m
```

Check pod logs:
```bash
kubectl logs -n fawkes jenkins-0 -c jenkins --tail=50
```

Look for: `Jenkins is fully up and running`

### 4. Verify Jenkins Service

Check that the Jenkins service is created:

```bash
kubectl get service jenkins -n fawkes
```

**Expected output:**
```
NAME      TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
jenkins   ClusterIP   10.96.xxx.xxx   <none>        8080/TCP   5m
```

### 5. Verify Jenkins Ingress

Check that the Jenkins Ingress is configured:

```bash
kubectl get ingress jenkins -n fawkes
```

**Expected output:**
```
NAME      CLASS   HOSTS                          ADDRESS         PORTS   AGE
jenkins   nginx   jenkins.127.0.0.1.nip.io       192.168.x.x     80      5m
```

### 6. Verify Jenkins UI Access

Open a browser and navigate to: `http://jenkins.127.0.0.1.nip.io`

**Expected result:**
- Jenkins login page displayed
- No certificate errors (if TLS is configured)
- Page loads without errors

Login with credentials (after setting them up):
- **Username:** `admin`
- **Password:** Value from `platform/apps/jenkins/secrets.yaml`

**⚠️ Important:** Before accessing Jenkins:
1. Update password in `platform/apps/jenkins/secrets.yaml`
2. Apply the secret: `kubectl apply -f platform/apps/jenkins/secrets.yaml`
3. Sync ArgoCD: `argocd app sync jenkins`

**Note:** Never commit actual passwords to Git!

### 7. Verify JCasC Configuration

Once logged in, navigate to **Manage Jenkins** → **Configuration as Code**

**Expected result:**
- Configuration loaded successfully
- System message: "Fawkes CI/CD Platform - Golden Path Enabled"
- No configuration errors

Check system message:
```bash
kubectl exec -n fawkes jenkins-0 -c jenkins -- \
  curl -s http://localhost:8080/api/json | grep -o '"systemMessage":"[^"]*"'
```

**Expected output:**
```json
"systemMessage":"Fawkes CI/CD Platform - Golden Path Enabled"
```

### 8. Verify Kubernetes Cloud Configuration

Navigate to **Manage Jenkins** → **Nodes and Clouds** → **Configure Clouds**

**Expected configuration:**
- Cloud name: `kubernetes`
- Kubernetes URL: Default (in-cluster)
- Kubernetes Namespace: `fawkes`
- Jenkins URL: `http://jenkins:8080`
- Jenkins tunnel: `jenkins-agent:50000`
- Container Cap: `20`

Or check via CLI:
```bash
kubectl get configmap jenkins-casc -n fawkes -o yaml | grep -A 10 "clouds:"
```

### 9. Verify Agent Templates

Navigate to **Manage Jenkins** → **Nodes and Clouds** → **Configure Clouds** → **Pod Templates**

**Expected agent templates:**

| Template Name  | Label          | Container Image                 | CPU Request | Memory Request | Idle Termination |
|---------------|----------------|----------------------------------|-------------|----------------|------------------|
| jnlp-agent    | k8s-agent      | jenkins/inbound-agent:latest    | -           | -              | 10 min           |
| maven-agent   | maven, java    | maven:3.9-eclipse-temurin-17    | 1           | 2Gi            | 10 min           |
| python-agent  | python         | python:3.11-slim                | 500m        | 1Gi            | 10 min           |
| node-agent    | node, nodejs   | node:20-slim                    | 500m        | 1Gi            | 10 min           |
| go-agent      | go, golang     | golang:1.21                     | 500m        | 1Gi            | 10 min           |

Or check via CLI:
```bash
kubectl get configmap jenkins-casc -n fawkes -o yaml | grep -A 5 "templates:"
```

### 10. Test Dynamic Agent Provisioning

Create a test pipeline to verify dynamic agent provisioning:

1. Navigate to **Dashboard** → **New Item**
2. Enter name: `test-k8s-agent`
3. Select **Pipeline** and click **OK**
4. In the Pipeline script box, enter:

```groovy
pipeline {
    agent {
        label 'k8s-agent'
    }
    stages {
        stage('Test') {
            steps {
                echo 'Running on Kubernetes agent'
                sh 'hostname'
                sh 'uname -a'
            }
        }
    }
}
```

5. Click **Save** and then **Build Now**

**Expected result:**
- Build starts successfully
- A new pod is created in the `fawkes` namespace
- Build executes on the dynamic agent
- Pod is terminated after build completion (within 10 minutes)

Monitor agent pods:
```bash
# Watch for agent pods being created
kubectl get pods -n fawkes --watch | grep -E "jenkins-agent|jnlp"
```

**Expected output:**
```
jenkins-agent-xxxxx   0/2     Pending   0          0s
jenkins-agent-xxxxx   0/2     ContainerCreating   0          1s
jenkins-agent-xxxxx   2/2     Running   0          10s
jenkins-agent-xxxxx   2/2     Completed   0          30s
jenkins-agent-xxxxx   0/2     Terminating   0          40s
```

### 11. Verify Security Configuration

Check authentication is required:
```bash
# Should return 403 or redirect to login
curl -I http://jenkins.127.0.0.1.nip.io/
```

**Expected response:**
- HTTP 403 Forbidden OR
- HTTP 302 redirect to login page

Anonymous access should be denied:
```bash
curl -I http://jenkins.127.0.0.1.nip.io/api/json
```

**Expected response:**
- HTTP 403 Forbidden

### 12. Verify Executor Configuration

Check that the controller has 0 executors (builds only run on agents):

Navigate to **Manage Jenkins** → **System Information**

Look for: `Number of executors: 0`

Or via CLI:
```bash
kubectl exec -n fawkes jenkins-0 -c jenkins -- \
  curl -s http://localhost:8080/computer/api/json | grep -o '"numExecutors":[0-9]*'
```

**Expected output:**
```json
"numExecutors":0
```

### 13. Run BDD Acceptance Tests

Run the automated BDD tests to verify all acceptance criteria:

```bash
cd /path/to/fawkes
python3 -m pytest tests/bdd/step_definitions/test_jenkins_kubernetes_deployment.py -v
```

**Expected result:**
```
10 passed in 0.10s
```

All tests should pass:
- ✅ Jenkins is deployed via ArgoCD
- ✅ Kubernetes plugin is configured
- ✅ Agent templates are configured
- ✅ Dynamic agent provisioning works
- ✅ Jenkins UI is accessible via Ingress
- ✅ Jenkins authentication is configured
- ✅ Agent resource limits are configured
- ✅ Agent idle termination is configured
- ✅ Agent capacity limits are configured
- ✅ Jenkins Configuration as Code is working

## Troubleshooting

### Jenkins Pod Not Starting

Check pod events:
```bash
kubectl describe pod jenkins-0 -n fawkes
```

Common issues:
- **PVC not bound**: Check storage class availability
- **Image pull errors**: Verify network connectivity
- **Resource limits**: Check cluster has sufficient resources

### Agent Pods Not Starting

Check Jenkins logs:
```bash
kubectl logs -n fawkes jenkins-0 -c jenkins | grep -i kubernetes
```

Common issues:
- **RBAC permissions**: Verify ServiceAccount has correct permissions
- **Network policies**: Check network access from Jenkins to agents
- **Resource quotas**: Verify namespace has sufficient quotas

### UI Not Accessible

Check Ingress status:
```bash
kubectl describe ingress jenkins -n fawkes
```

Common issues:
- **Ingress controller not installed**: Install nginx-ingress
- **DNS resolution**: Verify DNS resolves to cluster
- **TLS certificate**: Check cert-manager is working

### Configuration Not Loading

Check ConfigMap exists:
```bash
kubectl get configmap jenkins-casc -n fawkes
```

Check Jenkins logs for JCasC errors:
```bash
kubectl logs -n fawkes jenkins-0 -c jenkins | grep -i casc
```

## Success Criteria

✅ All verification steps completed successfully
✅ Jenkins UI accessible at http://jenkins.127.0.0.1.nip.io
✅ Login with admin credentials works
✅ System message displays "Fawkes CI/CD Platform - Golden Path Enabled"
✅ Kubernetes cloud is configured
✅ 5 agent templates are configured
✅ Test pipeline runs on dynamic agent
✅ Agent pod is created and terminated automatically
✅ Anonymous access is denied
✅ Controller has 0 executors
✅ All BDD tests pass

## Next Steps

After successful verification:

1. **Update credentials**: Change admin password in production
2. **Configure GitHub integration**: Set up GitHub webhooks
3. **Configure SonarQube**: Connect to SonarQube for code quality
4. **Configure Mattermost**: Set up build notifications
5. **Create shared libraries**: Implement Golden Path pipelines
6. **Set up DORA metrics**: Configure deployment event tracking

## References

- [Jenkins Documentation](https://www.jenkins.io/doc/)
- [Kubernetes Plugin](https://plugins.jenkins.io/kubernetes/)
- [Configuration as Code](https://github.com/jenkinsci/configuration-as-code-plugin)
- [ADR-004: Jenkins for CI/CD](../adr/ADR-004%20jenkins%204%20ci.md)
- [Jenkins README](../../platform/apps/jenkins/README.md)
