---
title: Jenkins Helm Values Reference
description: Complete configuration reference for Jenkins deployment in Fawkes platform
---

# Jenkins Helm Values Reference

## Overview

This document provides a complete field-level specification for the Jenkins Helm chart configuration used in the Fawkes platform. Jenkins is deployed as the CI/CD automation server for the Golden Path pipeline.

**Helm Chart:** `jenkins/jenkins` (official Jenkins Helm chart)

**Chart Repository:** `https://charts.jenkins.io`

**Values File Location:** `platform/apps/jenkins/values.yaml`

---

## Controller Configuration

### `controller.image`

Container image configuration for the Jenkins controller.

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `controller.image.repository` | String | No | `jenkins/jenkins` | Docker image repository. |
| `controller.image.tag` | String | No | `2.528.1-lts-jdk17` | Image tag. Use Jenkins LTS version with JDK 17 for plugin compatibility. |
| `controller.image.pullPolicy` | String | No | `IfNotPresent` | Image pull policy: `Always`, `IfNotPresent`, `Never`. |

**Example:**

```yaml
controller:
  image:
    repository: "jenkins/jenkins"
    tag: "2.528.1-lts-jdk17"
```

---

### `controller.admin`

Administrative user credentials.

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `controller.admin.username` | String | No | `admin` | Username for the Jenkins admin account. |
| `controller.admin.password` | String | No | - | Password for the Jenkins admin account. **Security Note:** Use Kubernetes Secret instead of plaintext. |

**Security Recommendation:**

Store credentials in a Kubernetes Secret and reference via `controller.extraEnv`:

```yaml
controller:
  admin:
    username: admin
  extraEnv:
    - name: ADMIN_PASSWORD
      valueFrom:
        secretKeyRef:
          name: jenkins-admin
          key: ADMIN_PASSWORD
```

---

### `controller.JENKINS_OPTS`

Java options and Jenkins runtime arguments.

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `controller.JENKINS_OPTS` | String | No | - | Command-line arguments passed to Jenkins on startup. |

**Common Options:**

- `--argumentsRealm.passwd.admin=<password>` - Set admin password (use with caution).
- `-Djenkins.install.runSetupWizard=false` - Skip the initial setup wizard.

**Example:**

```yaml
controller:
  JENKINS_OPTS: "--argumentsRealm.passwd.admin=changeme -Djenkins.install.runSetupWizard=false"
```

---

### `controller.serviceType`

Kubernetes Service type for the Jenkins controller.

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `controller.serviceType` | String | No | `ClusterIP` | Service type: `ClusterIP`, `NodePort`, `LoadBalancer`. |

**Fawkes Default:** `ClusterIP` (access via Ingress).

---

### `controller.executors`

Number of build executors on the controller node.

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `controller.executors` | Integer | No | `0` | Number of executors. **Best Practice:** Set to `0` to force builds on agents. |

**Fawkes Default:** `0` (builds run exclusively on Kubernetes agents).

---

### `controller.JCasC`

Jenkins Configuration as Code (JCasC) plugin configuration.

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `controller.JCasC.enabled` | Boolean | No | `true` | Enable JCasC plugin. |
| `controller.JCasC.defaultConfig` | Boolean | No | `false` | Use default JCasC configuration. Set to `false` for custom config. |
| `controller.JCasC.configScripts` | Object | No | `{}` | Inline JCasC YAML configurations (key-value pairs). |

**Example:**

```yaml
controller:
  JCasC:
    enabled: true
    defaultConfig: false
    configScripts:
      welcome-message: |
        jenkins:
          systemMessage: "Fawkes Platform Jenkins"
```

---

### `controller.extraEnv`

Additional environment variables injected into the Jenkins controller container.

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `controller.extraEnv` | Array[Object] | No | `[]` | Environment variables (standard Kubernetes `env` format). |

**Example:**

```yaml
controller:
  extraEnv:
    - name: ADMIN_PASSWORD
      valueFrom:
        secretKeyRef:
          name: jenkins-admin
          key: ADMIN_PASSWORD
    - name: JAVA_OPTS
      value: "-Xmx2048m"
```

---

## Plugin Installation

### `installPlugins`

List of Jenkins plugins to install on startup.

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `installPlugins` | Array[String] | No | `[]` | Plugin IDs with optional version (format: `plugin-name:version`). |

**Example:**

```yaml
installPlugins:
  - kubernetes:4253.v7700d91739e5
  - workflow-aggregator:596.v8c21c963d92d
  - git:5.2.2
  - configuration-as-code:1810.v9b_c30a_249a_4c
```

**Note:** Fawkes uses JCasC to manage plugin installation dynamically.

---

## Persistence

### `persistence`

Persistent storage configuration for Jenkins data (jobs, builds, plugins).

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `persistence.enabled` | Boolean | No | `false` | Enable persistent storage. |
| `persistence.size` | String | No | `8Gi` | Requested storage size. |
| `persistence.storageClass` | String | No | `standard` | Kubernetes StorageClass name. |
| `persistence.accessMode` | String | No | `ReadWriteOnce` | Volume access mode. |

**Environment-Specific Defaults:**

- **Local Development:** `enabled: false` (to avoid PVC pending issues).
- **Production:** `enabled: true` with `storageClass: gp3` (AWS EBS) or equivalent.

**Example:**

```yaml
persistence:
  enabled: true
  size: 20Gi
  storageClass: gp3
```

---

## Service Account and RBAC

### `serviceAccount`

Kubernetes ServiceAccount configuration.

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `serviceAccount.create` | Boolean | No | `true` | Create a ServiceAccount for Jenkins. |
| `serviceAccount.name` | String | No | `jenkins` | ServiceAccount name (auto-generated if not specified). |
| `serviceAccount.annotations` | Object | No | `{}` | Annotations for the ServiceAccount (e.g., IAM roles). |

**Example (AWS IRSA):**

```yaml
serviceAccount:
  create: true
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::123456789012:role/jenkins-role
```

---

### `rbac`

Role-Based Access Control configuration.

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `rbac.create` | Boolean | No | `true` | Create RBAC resources (Role, RoleBinding, ClusterRole). |
| `rbac.readSecrets` | Boolean | No | `false` | Grant permission to read Secrets (required for credentials binding). |

**Fawkes Default:** `rbac.create: true` (required for Kubernetes agent provisioning).

---

## Ingress

### `ingress`

Ingress configuration for external access to Jenkins.

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `ingress.enabled` | Boolean | No | `false` | Enable Ingress resource creation. |
| `ingress.annotations` | Object | No | `{}` | Ingress annotations (e.g., `cert-manager.io/cluster-issuer`). |
| `ingress.hosts` | Array[Object] | No | `[]` | Hostnames and paths for Ingress rules. |
| `ingress.tls` | Array[Object] | No | `[]` | TLS configuration for HTTPS. |

**Example:**

```yaml
ingress:
  enabled: true
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
  hosts:
    - host: jenkins.fawkes.example.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: jenkins-tls
      hosts:
        - jenkins.fawkes.example.com
```

---

## Agent Configuration

### `agent`

Kubernetes Pod Template configuration for dynamic Jenkins agents.

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `agent.enabled` | Boolean | No | `true` | Enable Kubernetes-based agent provisioning. |
| `agent.image` | String | No | `jenkins/inbound-agent` | Default agent image. |
| `agent.tag` | String | No | `latest-jdk17` | Agent image tag. |
| `agent.resources.requests.cpu` | String | No | `512m` | CPU request for agents. |
| `agent.resources.requests.memory` | String | No | `512Mi` | Memory request for agents. |
| `agent.resources.limits.cpu` | String | No | `1` | CPU limit for agents. |
| `agent.resources.limits.memory` | String | No | `1Gi` | Memory limit for agents. |

**Example:**

```yaml
agent:
  enabled: true
  resources:
    requests:
      cpu: "500m"
      memory: "1Gi"
    limits:
      cpu: "2"
      memory: "4Gi"
```

---

## Security Context

### `controller.podSecurityContext`

Security context for the Jenkins controller Pod.

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `controller.podSecurityContext.runAsUser` | Integer | No | `1000` | User ID to run the container as. |
| `controller.podSecurityContext.runAsNonRoot` | Boolean | No | `true` | Require running as non-root user. |
| `controller.podSecurityContext.fsGroup` | Integer | No | `1000` | Filesystem group ID for volume permissions. |

**Fawkes Default (Kyverno-compliant):**

```yaml
controller:
  podSecurityContext:
    runAsUser: 1000
    runAsNonRoot: true
    fsGroup: 1000
```

---

## Complete Example

```yaml
controller:
  image:
    repository: "jenkins/jenkins"
    tag: "2.528.1-lts-jdk17"
  admin:
    username: admin
  JENKINS_OPTS: "-Djenkins.install.runSetupWizard=false"
  serviceType: ClusterIP
  executors: 0
  JCasC:
    enabled: true
    defaultConfig: false
  extraEnv:
    - name: ADMIN_PASSWORD
      valueFrom:
        secretKeyRef:
          name: jenkins-admin
          key: ADMIN_PASSWORD

persistence:
  enabled: true
  size: 20Gi
  storageClass: gp3

serviceAccount:
  create: true

rbac:
  create: true

ingress:
  enabled: true
  hosts:
    - host: jenkins.fawkes.example.com
      paths: ["/"]
```

---

## See Also

- [Jenkins Official Documentation](https://www.jenkins.io/doc/)
- [Jenkins Helm Chart Repository](https://github.com/jenkinsci/helm-charts)
- [Jenkins Configuration as Code Plugin](https://plugins.jenkins.io/configuration-as-code/)
- [Golden Path Usage Guide](../../golden-path-usage.md)
