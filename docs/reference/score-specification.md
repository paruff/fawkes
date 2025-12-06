# SCORE Specification Reference for Fawkes

This document describes the SCORE workload specification fields supported by the Fawkes platform.

## Overview

SCORE (Specification for Container Orchestration and Runtime Execution) is an open-source, platform-agnostic workload specification. Fawkes uses SCORE to provide a simplified, portable way to define application workloads.

**SCORE Homepage**: https://score.dev

**Fawkes Implementation**: The Fawkes platform translates SCORE workload specifications into Kubernetes manifests using the SCORE transformer component.

## Document Structure

```yaml
apiVersion: score.dev/v1b1
metadata: {...}
containers: {...}
service: {...}
resources: {...}
route: {...}
extensions: {...}
```

---

## Core Fields (SCORE Standard)

### apiVersion

**Type**: `string`
**Required**: Yes
**Supported Values**: `score.dev/v1b1`

Specifies the SCORE API version.

**Example**:
```yaml
apiVersion: score.dev/v1b1
```

---

### metadata

**Type**: `object`
**Required**: Yes

Metadata about the workload.

#### metadata.name

**Type**: `string`
**Required**: Yes
**Constraints**: 
- Must be a valid Kubernetes resource name
- Lowercase alphanumeric characters, `-` only
- Max 63 characters

The name of the workload. This becomes the base name for all generated Kubernetes resources.

**Example**:
```yaml
metadata:
  name: my-service
```

---

### containers

**Type**: `object`
**Required**: Yes

Map of container definitions. Each key is the container name.

#### containers.<name>.image

**Type**: `string`
**Required**: Yes

Container image reference.

**Example**:
```yaml
containers:
  web:
    image: "harbor.fawkes.local/my-team/my-app:v1.0.0"
```

#### containers.<name>.command

**Type**: `array of strings`
**Required**: No

Override the container's entrypoint.

**Example**:
```yaml
containers:
  web:
    command: ["/app/server"]
```

#### containers.<name>.args

**Type**: `array of strings`
**Required**: No

Override the container's arguments.

**Example**:
```yaml
containers:
  web:
    args: ["--port", "8080", "--workers", "4"]
```

#### containers.<name>.resources

**Type**: `object`
**Required**: Recommended

Resource requests and limits.

**Sub-fields**:
- `requests.cpu`: CPU request (e.g., `"100m"`, `"0.5"`)
- `requests.memory`: Memory request (e.g., `"128Mi"`, `"1Gi"`)
- `limits.cpu`: CPU limit
- `limits.memory`: Memory limit

**Example**:
```yaml
containers:
  web:
    resources:
      requests:
        cpu: "250m"
        memory: "256Mi"
      limits:
        cpu: "500m"
        memory: "512Mi"
```

**Best Practices**:
- Always set both requests and limits
- Memory limits should be 1.5-2x requests
- CPU limits can be higher for burstable workloads

#### containers.<name>.variables

**Type**: `object`
**Required**: No

Environment variables for the container. Values can reference resources using `${resources.<name>.<field>}`.

**Example**:
```yaml
containers:
  web:
    variables:
      LOG_LEVEL: "info"
      DATABASE_URL: "${resources.db.connection_string}"
      REDIS_URL: "${resources.cache.connection_string}"
      ENVIRONMENT: "${ENVIRONMENT}"
```

**Variable Interpolation**:
- `${ENVIRONMENT}`: Replaced with target environment (dev, staging, prod)
- `${resources.<resource-name>.<field>}`: Replaced with resource field values

#### containers.<name>.livenessProbe

**Type**: `object`
**Required**: Recommended

Liveness probe configuration.

**Supported Types**: `httpGet` only (in current implementation)

**Example**:
```yaml
containers:
  web:
    livenessProbe:
      httpGet:
        path: /health
        port: 8080
      initialDelaySeconds: 30
      periodSeconds: 10
      timeoutSeconds: 5
      failureThreshold: 3
```

#### containers.<name>.readinessProbe

**Type**: `object`
**Required**: Recommended

Readiness probe configuration.

**Example**:
```yaml
containers:
  web:
    readinessProbe:
      httpGet:
        path: /ready
        port: 8080
      initialDelaySeconds: 10
      periodSeconds: 5
```

---

### service

**Type**: `object`
**Required**: No (required if exposing ports)

Service configuration for the workload.

#### service.ports

**Type**: `object`
**Required**: Yes (if `service` is defined)

Map of port definitions. Each key is the port name.

**Sub-fields**:
- `port`: External port (on the Service)
- `targetPort`: Container port
- `protocol`: Protocol (`tcp`, `udp`)

**Example**:
```yaml
service:
  ports:
    http:
      port: 80
      targetPort: 8080
      protocol: tcp
    grpc:
      port: 9090
      targetPort: 9090
      protocol: tcp
```

---

### resources

**Type**: `object`
**Required**: No

Map of infrastructure resources required by the workload.

#### Resource Type: postgres

PostgreSQL database provisioned via CloudNativePG.

**Example**:
```yaml
resources:
  db:
    type: postgres
    metadata:
      annotations:
        fawkes.dev/storage-size: "10Gi"
        fawkes.dev/version: "15"
    properties:
      database: "myapp"
```

**Generated Resources**:
- CloudNativePG Cluster (managed externally)
- ExternalSecret with connection credentials
- Environment variable: `${resources.db.connection_string}`

**Fawkes Annotations**:
- `fawkes.dev/storage-size`: Persistent volume size (default: `10Gi`)
- `fawkes.dev/version`: PostgreSQL version (default: `15`)

#### Resource Type: redis

Redis cache provisioned via Redis Helm Chart.

**Example**:
```yaml
resources:
  cache:
    type: redis
    metadata:
      annotations:
        fawkes.dev/storage-size: "2Gi"
    properties:
      maxmemory-policy: "allkeys-lru"
```

**Generated Resources**:
- Redis StatefulSet (managed externally)
- ExternalSecret with connection credentials
- Environment variable: `${resources.cache.connection_string}`

#### Resource Type: secret

Secrets from HashiCorp Vault provisioned via External Secrets Operator.

**Example**:
```yaml
resources:
  api-keys:
    type: secret
    metadata:
      annotations:
        fawkes.dev/vault-path: "secret/my-team/my-app/keys"
    properties:
      keys:
        - API_KEY
        - JWT_SECRET
```

**Generated Resources**:
- ExternalSecret referencing Vault
- Kubernetes Secret with specified keys
- Environment variables: `${resources.api-keys.API_KEY}`, etc.

**Fawkes Annotations**:
- `fawkes.dev/vault-path`: Path in Vault (required)

#### Resource Type: volume

Persistent volume provisioned via PersistentVolumeClaim.

**Example**:
```yaml
resources:
  uploads:
    type: volume
    metadata:
      annotations:
        fawkes.dev/storage-class: "standard"
        fawkes.dev/access-mode: "ReadWriteOnce"
    properties:
      size: "5Gi"
      mountPath: "/app/uploads"
```

**Generated Resources**:
- PersistentVolumeClaim
- Volume mount in container

**Fawkes Annotations**:
- `fawkes.dev/storage-class`: StorageClass (default: `standard`)
- `fawkes.dev/access-mode`: Access mode (default: `ReadWriteOnce`)

**Properties**:
- `size`: Storage size (required)
- `mountPath`: Path in container (required)

---

### route

**Type**: `object`
**Required**: No (required for external access)

Ingress/route configuration for external access.

#### route.host

**Type**: `string`
**Required**: Yes (if `route` is defined)

Hostname for the Ingress. Use `${ENVIRONMENT}` for environment interpolation.

**Example**:
```yaml
route:
  host: "my-service.${ENVIRONMENT}.fawkes.idp"
```

**Dev**: `my-service.dev.fawkes.idp`
**Prod**: `my-service.prod.fawkes.idp`

#### route.path

**Type**: `string`
**Required**: No
**Default**: `"/"`

Path prefix for routing.

**Example**:
```yaml
route:
  path: "/api"
```

#### route.tls

**Type**: `object`
**Required**: No

TLS/HTTPS configuration.

**Sub-fields**:
- `enabled`: Boolean (default: `true`)

**Example**:
```yaml
route:
  tls:
    enabled: true
```

**Generated Resources**:
- Ingress with TLS configuration
- Certificate automatically provisioned via cert-manager

---

## Fawkes Extensions

The `extensions.fawkes` section provides Fawkes-specific features beyond the SCORE standard.

### extensions.fawkes.team

**Type**: `string`
**Required**: Recommended

Team name for RBAC and billing.

**Example**:
```yaml
extensions:
  fawkes:
    team: my-team
```

---

### extensions.fawkes.deployment

**Type**: `object`
**Required**: No

Deployment-specific configuration.

#### deployment.strategy

**Type**: `string`
**Default**: `"RollingUpdate"`
**Options**: `RollingUpdate`, `Recreate`

Kubernetes deployment strategy.

#### deployment.replicas

**Type**: `integer`
**Default**: `2`

Number of replicas.

#### deployment.autoscaling

**Type**: `object`
**Required**: No

Horizontal Pod Autoscaler configuration.

**Sub-fields**:
- `enabled`: Boolean (default: `false`)
- `minReplicas`: Minimum replicas (default: `2`)
- `maxReplicas`: Maximum replicas (default: `10`)
- `targetCPUUtilizationPercentage`: CPU target (default: `70`)
- `targetMemoryUtilizationPercentage`: Memory target (default: `80`)

**Example**:
```yaml
extensions:
  fawkes:
    deployment:
      autoscaling:
        enabled: true
        minReplicas: 3
        maxReplicas: 20
        targetCPUUtilizationPercentage: 70
        targetMemoryUtilizationPercentage: 80
```

---

### extensions.fawkes.observability

**Type**: `object`
**Required**: No

Observability configuration.

#### observability.metrics

**Type**: `object`

Prometheus metrics scraping configuration.

**Sub-fields**:
- `enabled`: Boolean (default: `false`)
- `port`: Metrics port (default: `9090`)
- `path`: Metrics path (default: `"/metrics"`)

**Example**:
```yaml
extensions:
  fawkes:
    observability:
      metrics:
        enabled: true
        port: 9090
        path: "/metrics"
```

**Generated Annotations**:
```yaml
annotations:
  prometheus.io/scrape: "true"
  prometheus.io/port: "9090"
  prometheus.io/path: "/metrics"
```

#### observability.tracing

**Type**: `object`

OpenTelemetry distributed tracing configuration.

**Sub-fields**:
- `enabled`: Boolean (default: `false`)
- `samplingRate`: Sampling rate (0.0-1.0, default: `0.1`)

**Example**:
```yaml
extensions:
  fawkes:
    observability:
      tracing:
        enabled: true
        samplingRate: 0.1
```

#### observability.logging

**Type**: `object`

Logging configuration.

**Sub-fields**:
- `enabled`: Boolean (default: `true`)
- `format`: Log format (`json`, `text`, default: `json`)
- `level`: Log level (`debug`, `info`, `warn`, `error`, default: `info`)

---

### extensions.fawkes.security

**Type**: `object`
**Required**: No

Security configuration.

#### security.podSecurityStandard

**Type**: `string`
**Default**: `"restricted"`
**Options**: `privileged`, `baseline`, `restricted`

Pod Security Standard level.

#### security.runAsNonRoot

**Type**: `boolean`
**Default**: `true`

Run containers as non-root user.

#### security.runAsUser

**Type**: `integer`
**Default**: `65534`

User ID to run containers as.

#### security.networkPolicy

**Type**: `object`

NetworkPolicy configuration.

**Sub-fields**:
- `enabled`: Boolean (default: `false`)
- `allowedNamespaces`: Array of allowed namespaces

**Example**:
```yaml
extensions:
  fawkes:
    security:
      runAsNonRoot: true
      runAsUser: 65534
      networkPolicy:
        enabled: true
        allowedNamespaces:
          - "my-team"
          - "fawkes"
```

---

### extensions.fawkes.dora

**Type**: `object`
**Required**: No

DORA metrics tracking configuration.

**Sub-fields**:
- `enabled`: Boolean (default: `true`)

**Example**:
```yaml
extensions:
  fawkes:
    dora:
      enabled: true
```

---

## Complete Example

```yaml
apiVersion: score.dev/v1b1

metadata:
  name: fullstack-app

containers:
  web:
    image: "harbor.fawkes.local/team-a/app:v2.1.0"
    resources:
      requests: {cpu: "500m", memory: "512Mi"}
      limits: {cpu: "1000m", memory: "1Gi"}
    variables:
      LOG_LEVEL: "info"
      DATABASE_URL: "${resources.db.connection_string}"
      REDIS_URL: "${resources.cache.connection_string}"
      API_KEY: "${resources.secrets.API_KEY}"
    livenessProbe:
      httpGet: {path: /health, port: 8080}
      initialDelaySeconds: 30
    readinessProbe:
      httpGet: {path: /ready, port: 8080}
      initialDelaySeconds: 10

service:
  ports:
    http: {port: 80, targetPort: 8080, protocol: tcp}

resources:
  db:
    type: postgres
    properties: {database: "appdb"}
  cache:
    type: redis
  secrets:
    type: secret
    metadata:
      annotations:
        fawkes.dev/vault-path: "secret/team-a/app"
    properties:
      keys: [API_KEY, JWT_SECRET]
  uploads:
    type: volume
    properties: {size: "10Gi", mountPath: "/app/uploads"}

route:
  host: "app.${ENVIRONMENT}.fawkes.idp"
  path: "/"
  tls: {enabled: true}

extensions:
  fawkes:
    team: team-a
    deployment:
      autoscaling:
        enabled: true
        minReplicas: 3
        maxReplicas: 20
    observability:
      metrics: {enabled: true, port: 9090}
      tracing: {enabled: true, samplingRate: 0.1}
    security:
      runAsNonRoot: true
      networkPolicy:
        enabled: true
        allowedNamespaces: ["team-a", "fawkes"]
```

---

## Migration from Kubernetes Manifests

### Step 1: Identify Core Components

Map your existing K8s resources to SCORE fields:

| Kubernetes Resource | SCORE Field |
|-------------------|-------------|
| Deployment.spec.template.spec.containers | `containers` |
| Deployment.spec.replicas | `extensions.fawkes.deployment.replicas` |
| Service.spec.ports | `service.ports` |
| Ingress.spec.rules | `route` |
| ConfigMap/Secret | `resources` (type: secret) |
| PersistentVolumeClaim | `resources` (type: volume) |

### Step 2: Create score.yaml

Start with a minimal `score.yaml`:

```yaml
apiVersion: score.dev/v1b1
metadata:
  name: my-service
containers:
  web:
    image: <from Deployment>
    resources: <from Deployment>
service:
  ports: <from Service>
```

### Step 3: Add Resources

For each external dependency (DB, cache, etc.), add a resource:

```yaml
resources:
  db:
    type: postgres
```

### Step 4: Validate

Generate manifests and compare:

```bash
python3 charts/score-transformer/generator.py \
  --score score.yaml \
  --environment dev \
  --output /tmp/generated

diff /tmp/generated/deployment.yaml old-deployment.yaml
```

---

## Troubleshooting

### Common Issues

#### Invalid SCORE File

**Error**: `ValueError: score.yaml must have 'apiVersion' field`

**Solution**: Ensure your file starts with:
```yaml
apiVersion: score.dev/v1b1
```

#### Environment Variable Not Interpolated

**Problem**: `${ENVIRONMENT}` appears literally in generated manifests

**Solution**: The transformer replaces this automatically. Check you're using the correct syntax:
```yaml
route:
  host: "app.${ENVIRONMENT}.fawkes.idp"
```

#### Resource Not Provisioned

**Problem**: Database/cache not created

**Solution**: Resource provisioning happens externally to the SCORE transformer. The transformer only generates ExternalSecret references. Ensure:
1. CloudNativePG operator is installed (for postgres)
2. Redis is deployed (for redis)
3. External Secrets Operator is configured (for secrets)

---

## Further Reading

- [SCORE Official Documentation](https://score.dev)
- [ADR-030: SCORE Integration](../adr/ADR-030%20SCORE%20Workload%20Specification%20Integration.md)
- [Golden Path Usage Guide](../golden-path-usage.md)
- [SCORE Transformer README](../../charts/score-transformer/README.md)
- [Golden Path Service Template](../../templates/golden-path-service/README.md)
