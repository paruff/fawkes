# Kubernetes Manifest Standards

**Version**: 1.0  
**Last Updated**: January 5, 2025  
**Status**: Standard  
**Applies To**: All Kubernetes manifests in the Fawkes platform

---

## Overview

This document defines the standard format, labels, annotations, security contexts, resource limits, and health checks for all Kubernetes manifests in the Fawkes repository. Adhering to these standards ensures consistency, improves observability, and maintains security compliance across all environments.

## Architectural Principles

All Kubernetes manifests must align with Fawkes' core architectural principles:

- **Observable by Default**: Every component exposes metrics, logs, and traces
- **Secure by Design**: Security contexts with least privilege, no root containers
- **Declarative & GitOps-Driven**: All configuration in version control
- **Resource-Aware**: Resource limits defined to prevent over-allocation (target <70% utilization)

## Standard Labels

All Kubernetes resources MUST include the following standard labels where applicable:

### Required Labels (Metadata)

```yaml
metadata:
  labels:
    app.kubernetes.io/name: <application-name>        # Name of the application (e.g., "backstage", "nps-service")
    app.kubernetes.io/part-of: fawkes                 # Platform name (always "fawkes")
    app.kubernetes.io/component: <component-type>     # Component role (e.g., "backend", "frontend", "database")
```

### Recommended Labels

```yaml
metadata:
  labels:
    app.kubernetes.io/version: <version>              # Application version (e.g., "v1.0.0", "0.1.0")
    app.kubernetes.io/managed-by: <tool>              # Tool managing the resource (e.g., "argocd", "backstage", "helm")
```

### Legacy Compatibility

For backward compatibility with existing selectors, also include:

```yaml
metadata:
  labels:
    app: <application-name>                           # Simple app label for selectors
```

### Label Value Guidelines

- Use lowercase letters, numbers, hyphens, and dots only
- Start and end with alphanumeric characters
- Maximum 63 characters per label value
- Be descriptive but concise

### Component Types

Common `app.kubernetes.io/component` values:

- `backend` - Backend services and APIs
- `frontend` - Web interfaces and UIs
- `database` - Database instances
- `cache` - Redis, Memcached, etc.
- `queue` - Message queues
- `observability` - Monitoring, logging, tracing
- `ai-platform` - AI/ML services
- `feedback` - Feedback collection services
- `platform` - Core platform services

## Standard Annotations

### Pod Annotations

For applications exposing Prometheus metrics:

```yaml
spec:
  template:
    metadata:
      annotations:
        prometheus.io/scrape: "true"                  # Enable Prometheus scraping
        prometheus.io/port: "<port>"                  # Port where metrics are exposed
        prometheus.io/path: "/metrics"                # Path to metrics endpoint
```

### Deployment Annotations

For documentation and change tracking:

```yaml
metadata:
  annotations:
    description: "<brief-description>"                # Brief description of the resource
    docs: "<link-to-documentation>"                   # Link to relevant documentation
```

## Security Context Standards

All deployments MUST implement security contexts at both pod and container levels.

### Pod-Level Security Context

```yaml
spec:
  template:
    spec:
      securityContext:
        runAsNonRoot: true                            # REQUIRED: Never run as root
        runAsUser: 65534                              # REQUIRED: Use nobody user (65534) by default
        runAsGroup: 65534                             # REQUIRED: Use nobody group
        fsGroup: 65534                                # REQUIRED: File system group ownership
```

**User ID Guidelines:**

- Default to `65534` (nobody user) for maximum security
- Use specific non-root UIDs (e.g., `1000`, `10001`) only if required by the application
- NEVER use UID `0` (root)

### Container-Level Security Context

```yaml
spec:
  template:
    spec:
      containers:
        - name: <container-name>
          securityContext:
            allowPrivilegeEscalation: false           # REQUIRED: Prevent privilege escalation
            readOnlyRootFilesystem: true              # REQUIRED: Make root filesystem read-only
            runAsNonRoot: true                        # REQUIRED: Ensure non-root execution
            runAsUser: 65534                          # REQUIRED: Match pod-level user
            capabilities:
              drop:
                - ALL                                 # REQUIRED: Drop all Linux capabilities
            seccompProfile:
              type: RuntimeDefault                    # REQUIRED: Use default seccomp profile
```

### Volume Mounts for Writable Directories

When using `readOnlyRootFilesystem: true`, provide writable temporary directories:

```yaml
spec:
  template:
    spec:
      containers:
        - name: <container-name>
          volumeMounts:
            - name: tmp
              mountPath: /tmp
      volumes:
        - name: tmp
          emptyDir: {}
```

## Resource Limits Standards

All containers MUST define resource requests and limits to prevent resource contention.

### Standard Resource Definitions

```yaml
spec:
  template:
    spec:
      containers:
        - name: <container-name>
          resources:
            requests:                                 # REQUIRED: Minimum guaranteed resources
              cpu: "<cpu-request>"                    # e.g., "100m", "200m"
              memory: "<memory-request>"              # e.g., "128Mi", "256Mi"
            limits:                                   # REQUIRED: Maximum allowed resources
              cpu: "<cpu-limit>"                      # e.g., "500m", "1000m"
              memory: "<memory-limit>"                # e.g., "512Mi", "1Gi"
```

### Resource Sizing Guidelines

Target cluster utilization: **<70%** to ensure headroom for spikes

#### Small Services (APIs, simple backends)

```yaml
resources:
  requests:
    cpu: 100m
    memory: 128Mi
  limits:
    cpu: 500m
    memory: 512Mi
```

#### Medium Services (Standard applications)

```yaml
resources:
  requests:
    cpu: 200m
    memory: 256Mi
  limits:
    cpu: 500m
    memory: 512Mi
```

#### Large Services (Data processing, ML services)

```yaml
resources:
  requests:
    cpu: 500m
    memory: 512Mi
  limits:
    cpu: 2000m
    memory: 2Gi
```

#### Java Applications

Java applications require more memory:

```yaml
resources:
  requests:
    cpu: 250m
    memory: 512Mi
  limits:
    cpu: 1000m
    memory: 1Gi
```

### Resource Limit Best Practices

- Always set both `requests` and `limits`
- Set `requests` to expected baseline usage
- Set `limits` 2-3x higher than `requests` for burst capacity
- Monitor actual usage and adjust over time
- Use `kubectl top pods` to validate resource usage

## Health Check Standards

All application containers MUST define both liveness and readiness probes.

### Liveness Probe

Determines if the container is alive and should be restarted:

```yaml
spec:
  template:
    spec:
      containers:
        - name: <container-name>
          livenessProbe:
            httpGet:
              path: /health                           # Or /healthz, /live
              port: http
            initialDelaySeconds: 30                   # Wait before first check
            periodSeconds: 10                         # Check every 10 seconds
            timeoutSeconds: 5                         # Timeout for each check
            failureThreshold: 3                       # Restart after 3 failures
```

### Readiness Probe

Determines if the container is ready to receive traffic:

```yaml
spec:
  template:
    spec:
      containers:
        - name: <container-name>
          readinessProbe:
            httpGet:
              path: /ready                            # Or /readyz, /health/ready
              port: http
            initialDelaySeconds: 10                   # Wait before first check
            periodSeconds: 5                          # Check every 5 seconds
            timeoutSeconds: 3                         # Timeout for each check
            failureThreshold: 3                       # Mark unready after 3 failures
```

### Health Check Guidelines

- Use HTTP probes when possible (preferred over TCP and exec)
- Liveness checks should be simple and fast
- Readiness checks can be more comprehensive (check dependencies)
- Set `initialDelaySeconds` based on application startup time
- Java apps: Use longer `initialDelaySeconds` (60s+)
- Python/Node apps: Use shorter `initialDelaySeconds` (10-30s)

### Common Health Check Paths

- **FastAPI/Python**: `/health`, `/ready`
- **Spring Boot/Java**: `/actuator/health/liveness`, `/actuator/health/readiness`
- **Node.js/Express**: `/health`, `/ready`
- **Go**: `/healthz`, `/readyz`

## Service Account Standards

Applications requiring Kubernetes API access MUST use a dedicated ServiceAccount:

```yaml
spec:
  template:
    spec:
      serviceAccountName: <app-name>                  # Use dedicated service account
```

For applications NOT requiring API access:

```yaml
spec:
  template:
    spec:
      automountServiceAccountToken: false             # Disable token mounting
```

## Image Standards

### Image References

```yaml
spec:
  template:
    spec:
      containers:
        - name: <container-name>
          image: <registry>/<org>/<name>:<tag-or-digest>
          imagePullPolicy: IfNotPresent               # Use cached images when possible
```

### Image Pull Policy Guidelines

- `IfNotPresent`: For tagged releases (recommended)
- `Always`: For `latest` tag or continuous development
- Never use `latest` tag in production

### Image Tag Best Practices

- Use semantic versioning: `v1.0.0`, `v1.2.3`
- Use SHA digests for immutable deployments: `@sha256:...`
- Avoid `latest` tag in production environments

## Complete Example: Standard Deployment

```yaml
# Copyright (c) 2025  Philip Ruff
# [License header...]

apiVersion: apps/v1
kind: Deployment
metadata:
  name: example-service
  namespace: fawkes
  labels:
    app: example-service
    app.kubernetes.io/name: example-service
    app.kubernetes.io/version: v1.0.0
    app.kubernetes.io/component: backend
    app.kubernetes.io/part-of: fawkes
    app.kubernetes.io/managed-by: argocd
  annotations:
    description: Example service demonstrating standard manifest format
    docs: https://github.com/paruff/fawkes/tree/main/services/example-service
spec:
  replicas: 2
  selector:
    matchLabels:
      app: example-service
  template:
    metadata:
      labels:
        app: example-service
        app.kubernetes.io/name: example-service
        app.kubernetes.io/version: v1.0.0
        app.kubernetes.io/component: backend
        app.kubernetes.io/part-of: fawkes
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "8000"
        prometheus.io/path: "/metrics"
    spec:
      serviceAccountName: example-service
      securityContext:
        runAsNonRoot: true
        runAsUser: 65534
        runAsGroup: 65534
        fsGroup: 65534

      containers:
        - name: example-service
          image: harbor.fawkes.local/platform/example-service:v1.0.0
          imagePullPolicy: IfNotPresent

          ports:
            - name: http
              containerPort: 8000
              protocol: TCP

          env:
            - name: ENVIRONMENT
              value: "production"
            - name: LOG_LEVEL
              value: "info"

          resources:
            requests:
              cpu: 200m
              memory: 256Mi
            limits:
              cpu: 500m
              memory: 512Mi

          livenessProbe:
            httpGet:
              path: /health
              port: http
            initialDelaySeconds: 30
            periodSeconds: 10
            timeoutSeconds: 5
            failureThreshold: 3

          readinessProbe:
            httpGet:
              path: /ready
              port: http
            initialDelaySeconds: 10
            periodSeconds: 5
            timeoutSeconds: 3
            failureThreshold: 3

          securityContext:
            allowPrivilegeEscalation: false
            readOnlyRootFilesystem: true
            runAsNonRoot: true
            runAsUser: 65534
            capabilities:
              drop:
                - ALL
            seccompProfile:
              type: RuntimeDefault

          volumeMounts:
            - name: tmp
              mountPath: /tmp

      volumes:
        - name: tmp
          emptyDir: {}
```

## Service Standards

```yaml
apiVersion: v1
kind: Service
metadata:
  name: example-service
  namespace: fawkes
  labels:
    app: example-service
    app.kubernetes.io/name: example-service
    app.kubernetes.io/component: backend
    app.kubernetes.io/part-of: fawkes
  annotations:
    prometheus.io/scrape: "true"
    prometheus.io/port: "8000"
    prometheus.io/path: "/metrics"
spec:
  type: ClusterIP
  ports:
    - name: http
      port: 8000
      targetPort: http
      protocol: TCP
  selector:
    app: example-service
```

## Ingress Standards

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: example-service
  namespace: fawkes
  labels:
    app: example-service
    app.kubernetes.io/name: example-service
    app.kubernetes.io/component: backend
    app.kubernetes.io/part-of: fawkes
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
    cert-manager.io/cluster-issuer: letsencrypt-prod
spec:
  ingressClassName: nginx
  rules:
    - host: example.fawkes.local
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: example-service
                port:
                  number: 8000
  tls:
    - hosts:
        - example.fawkes.local
      secretName: example-service-tls
```

## ConfigMap and Secret Standards

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: example-service-config
  namespace: fawkes
  labels:
    app: example-service
    app.kubernetes.io/name: example-service
    app.kubernetes.io/component: backend
    app.kubernetes.io/part-of: fawkes
data:
  key: value
---
apiVersion: v1
kind: Secret
metadata:
  name: example-service-secret
  namespace: fawkes
  labels:
    app: example-service
    app.kubernetes.io/name: example-service
    app.kubernetes.io/component: backend
    app.kubernetes.io/part-of: fawkes
type: Opaque
stringData:
  key: value
```

## CronJob Standards

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: example-job
  namespace: fawkes
  labels:
    app: example-job
    app.kubernetes.io/name: example-job
    app.kubernetes.io/component: batch
    app.kubernetes.io/part-of: fawkes
spec:
  schedule: "0 2 * * *"
  jobTemplate:
    spec:
      template:
        metadata:
          labels:
            app: example-job
            app.kubernetes.io/name: example-job
            app.kubernetes.io/component: batch
            app.kubernetes.io/part-of: fawkes
        spec:
          restartPolicy: OnFailure
          securityContext:
            runAsNonRoot: true
            runAsUser: 65534
            runAsGroup: 65534
            fsGroup: 65534
          containers:
            - name: job
              image: harbor.fawkes.local/platform/example-job:v1.0.0
              imagePullPolicy: IfNotPresent
              resources:
                requests:
                  cpu: 100m
                  memory: 128Mi
                limits:
                  cpu: 500m
                  memory: 512Mi
              securityContext:
                allowPrivilegeEscalation: false
                readOnlyRootFilesystem: true
                runAsNonRoot: true
                runAsUser: 65534
                capabilities:
                  drop:
                    - ALL
                seccompProfile:
                  type: RuntimeDefault
              volumeMounts:
                - name: tmp
                  mountPath: /tmp
          volumes:
            - name: tmp
              emptyDir: {}
```

## Validation

### Pre-deployment Validation

Before committing manifest changes:

```bash
# Validate YAML syntax
make lint

# Validate Kubernetes schemas
make k8s-validate

# Validate with policy engine
make validate
```

### Runtime Validation

After deployment:

```bash
# Check resource usage (target <70%)
make validate-resources

# Verify security contexts
kubectl get pods -n <namespace> -o jsonpath='{.items[*].spec.securityContext}'

# Check for running containers
kubectl get pods -n <namespace> --field-selector=status.phase=Running
```

## Migration Guide

### Updating Existing Manifests

1. **Add standard labels** to metadata
2. **Add security contexts** if missing or incomplete
3. **Add resource limits** if not defined
4. **Add health checks** if missing
5. **Add standard annotations** for monitoring
6. **Validate** changes before committing

### Checklist for Each Manifest

- [ ] Has `app.kubernetes.io/name` label
- [ ] Has `app.kubernetes.io/part-of: fawkes` label
- [ ] Has `app.kubernetes.io/component` label
- [ ] Has pod-level security context with `runAsNonRoot: true`
- [ ] Has container-level security context with `allowPrivilegeEscalation: false`
- [ ] Has `seccompProfile.type: RuntimeDefault`
- [ ] Has resource requests and limits
- [ ] Has liveness probe (for Deployments)
- [ ] Has readiness probe (for Deployments)
- [ ] Has Prometheus annotations (if applicable)
- [ ] Has writable volumes if using `readOnlyRootFilesystem: true`

## Non-Goals

The following are explicitly **out of scope** for this standardization:

- Converting manifests to Helm charts or other templating systems
- Cluster-specific testing or deployment
- Custom resource limits beyond generic defaults
- Application-specific health check endpoints

## References

- [Kubernetes Recommended Labels](https://kubernetes.io/docs/concepts/overview/working-with-objects/common-labels/)
- [Pod Security Standards](https://kubernetes.io/docs/concepts/security/pod-security-standards/)
- [Resource Management for Pods and Containers](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/)
- [Configure Liveness, Readiness and Startup Probes](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/)
- [Fawkes Architecture](../architecture.md)

## Change Log

| Date | Version | Changes |
|------|---------|---------|
| 2025-01-05 | 1.0 | Initial standard established for issue #121 |
