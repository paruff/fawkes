# Golden Path Service Template

This directory contains the standardized template for creating new services using the Fawkes Golden Path.

## Overview

The Golden Path Service Template provides a complete, production-ready foundation for building and deploying microservices on the Fawkes platform. It includes:

- **SCORE Workload Specification** (`score.yaml`) - Platform-agnostic service definition
- **Kubernetes Manifests** (`k8s-manifests/`) - Generated from SCORE (reference examples)
- **CI/CD Integration** - Ready for Jenkins Golden Path pipeline
- **Security Best Practices** - Non-root containers, security contexts, network policies
- **Observability** - Prometheus metrics, health checks, distributed tracing
- **Resource Management** - Databases, caches, secrets, persistent storage

## Quick Start

### 1. Copy the Template

When creating a new service via Backstage, this template is automatically scaffolded. For manual creation:

```bash
cp -r templates/golden-path-service my-new-service
cd my-new-service
```

### 2. Customize score.yaml

Edit `score.yaml` to define your application:

```yaml
apiVersion: score.dev/v1b1
metadata:
  name: my-new-service # Change this

containers:
  web:
    image: "harbor.fawkes.local/my-team/my-new-service:latest" # Change this
    resources:
      limits: { memory: "512Mi", cpu: "500m" }
    variables:
      LOG_LEVEL: "info"
      DATABASE_URL: "${resources.db.connection_string}"

resources:
  db:
    type: postgres
    properties:
      database: "myapp"

service:
  ports:
    web: { port: 80, targetPort: 8080 }

route:
  host: "my-new-service.${ENVIRONMENT}.fawkes.idp"
  tls: { enabled: true }
```

### 3. Deploy

The `score.yaml` file is automatically translated to Kubernetes manifests by the SCORE transformer during the CI/CD pipeline.

```bash
# Commit and push
git add score.yaml
git commit -m "feat: Add SCORE workload definition"
git push origin main

# CI/CD pipeline will:
# 1. Build Docker image
# 2. Run tests
# 3. Translate score.yaml to K8s manifests
# 4. Deploy via ArgoCD
```

## File Structure

```
golden-path-service/
├── README.md                    # This file
├── score.yaml                   # SCORE workload specification (PRIMARY)
└── k8s-manifests/              # Generated K8s manifests (REFERENCE)
    ├── deployment.yaml          # Generated from score.yaml
    ├── service.yaml             # Generated from score.yaml
    └── ingress.yaml             # Generated from score.yaml
```

**Important**: The `k8s-manifests/` directory contains **reference examples** showing what gets generated from `score.yaml`. In practice, you only maintain `score.yaml` - the manifests are auto-generated.

## SCORE Workload Specification

### Why SCORE?

SCORE is an open-source, platform-agnostic workload specification that allows you to:

✅ Define your application **once**, deploy **anywhere** (dev, staging, prod)
✅ Focus on **what you need** (database, cache), not **how to configure** K8s
✅ Achieve **true portability** across environments and platforms
✅ Simplify **configuration management** with environment interpolation

### Core Concepts

#### 1. Containers

Define your application containers:

```yaml
containers:
  web:
    image: "my-app:v1.0.0"
    resources:
      limits: { memory: "512Mi", cpu: "500m" }
      requests: { memory: "256Mi", cpu: "250m" }
    variables:
      LOG_LEVEL: "info"
```

#### 2. Resources

Declare infrastructure resources your app needs:

```yaml
resources:
  db:
    type: postgres # Platform provisions CloudNativePG
  cache:
    type: redis # Platform provisions Redis
  api-secret:
    type: secret # Platform provisions from Vault
  uploads:
    type: volume # Platform provisions PVC
```

The platform automatically:

- Provisions the resource (database, cache, etc.)
- Creates credentials and connection strings
- Injects them into your container as environment variables

#### 3. Service & Routes

Expose your application:

```yaml
service:
  ports:
    http: { port: 80, targetPort: 8080 }

route:
  host: "my-service.${ENVIRONMENT}.fawkes.idp"
  path: "/"
  tls: { enabled: true }
```

### Environment Portability

The same `score.yaml` works across all environments. Environment-specific values are injected automatically:

**score.yaml** (same everywhere):

```yaml
route:
  host: "my-service.${ENVIRONMENT}.fawkes.idp"
```

**Dev deployment**:

- Hostname: `my-service.dev.fawkes.idp`
- Replicas: 1
- Resources: Small

**Prod deployment**:

- Hostname: `my-service.prod.fawkes.idp`
- Replicas: 3 (with autoscaling)
- Resources: Large

## Fawkes Extensions

Beyond standard SCORE, Fawkes supports platform-specific features via `extensions.fawkes`:

### Autoscaling

```yaml
extensions:
  fawkes:
    deployment:
      autoscaling:
        enabled: true
        minReplicas: 2
        maxReplicas: 10
        targetCPUUtilizationPercentage: 70
```

### Observability

```yaml
extensions:
  fawkes:
    observability:
      metrics:
        enabled: true
        port: 9090
        path: "/metrics"
      tracing:
        enabled: true
        samplingRate: 0.1
```

### Security

```yaml
extensions:
  fawkes:
    security:
      runAsNonRoot: true
      runAsUser: 65534
      networkPolicy:
        enabled: true
        allowedNamespaces: ["my-team", "fawkes"]
```

## Common Patterns

### Pattern 1: Simple Web App (No Database)

```yaml
apiVersion: score.dev/v1b1
metadata:
  name: simple-web

containers:
  web:
    image: "nginx:latest"
    resources:
      limits: { memory: "128Mi", cpu: "100m" }

service:
  ports:
    http: { port: 80, targetPort: 80 }

route:
  host: "simple-web.${ENVIRONMENT}.fawkes.idp"
```

### Pattern 2: API with Database

```yaml
apiVersion: score.dev/v1b1
metadata:
  name: api-service

containers:
  api:
    image: "my-api:v1.0.0"
    variables:
      DATABASE_URL: "${resources.db.connection_string}"
      LOG_LEVEL: "info"

resources:
  db:
    type: postgres
    properties:
      database: "apidb"

service:
  ports:
    api: { port: 8080, targetPort: 8080 }
```

### Pattern 3: Background Worker (No Ingress)

```yaml
apiVersion: score.dev/v1b1
metadata:
  name: worker

containers:
  worker:
    image: "my-worker:v1.0.0"
    variables:
      QUEUE_URL: "${resources.queue.connection_string}"

resources:
  queue:
    type: redis
# No service.ports or route - internal workload
```

### Pattern 4: Full-Stack App

```yaml
apiVersion: score.dev/v1b1
metadata:
  name: fullstack-app

containers:
  web:
    image: "fullstack-app:v1.0.0"
    resources:
      limits: { memory: "1Gi", cpu: "1000m" }
    variables:
      DATABASE_URL: "${resources.db.connection_string}"
      REDIS_URL: "${resources.cache.connection_string}"
      API_KEY: "${resources.secrets.API_KEY}"

resources:
  db:
    type: postgres
  cache:
    type: redis
  secrets:
    type: secret
    metadata:
      annotations:
        fawkes.dev/vault-path: "secret/my-team/app/keys"
  uploads:
    type: volume
    properties:
      size: "10Gi"

service:
  ports:
    http: { port: 80, targetPort: 8080 }

route:
  host: "app.${ENVIRONMENT}.fawkes.idp"
  tls: { enabled: true }

extensions:
  fawkes:
    deployment:
      autoscaling:
        enabled: true
        minReplicas: 3
        maxReplicas: 20
```

## Validation

Validate your `score.yaml` before committing:

```bash
# Using Python YAML validator
python3 -c "import yaml; yaml.safe_load(open('score.yaml'))"

# Using SCORE transformer (dry-run)
python3 charts/score-transformer/generator.py \
  --score score.yaml \
  --environment dev \
  --output /tmp/manifests

# Inspect generated manifests
ls -la /tmp/manifests/
```

## Troubleshooting

### Issue: "Invalid SCORE apiVersion"

**Solution**: Ensure `score.yaml` starts with:

```yaml
apiVersion: score.dev/v1b1
```

### Issue: Environment variables not interpolated

**Solution**: Use the `${ENVIRONMENT}` placeholder:

```yaml
route:
  host: "my-service.${ENVIRONMENT}.fawkes.idp"
```

### Issue: Resource not provisioned

**Solution**: Check supported resource types:

- `postgres`, `redis`, `secret`, `volume`

For other types, use Terraform to provision infrastructure separately.

### Issue: Generated manifests don't match my needs

**Solution**: Use Kustomize patches to override specific fields:

```yaml
# overlays/prod/kustomization.yaml
patchesStrategicMerge:
  - custom-resources.yaml
```

## Documentation

- **SCORE Specification**: https://score.dev
- **ADR-030**: [SCORE Integration Decision](../../docs/adr/ADR-030%20SCORE%20Workload%20Specification%20Integration.md)
- **Golden Path Guide**: [docs/golden-path-usage.md](../../docs/golden-path-usage.md)
- **Transformer Details**: [charts/score-transformer/README.md](../../charts/score-transformer/README.md)

## Support

- **Mattermost**: `#platform-support` channel
- **GitHub Issues**: https://github.com/paruff/fawkes/issues
- **Office Hours**: Platform team availability posted in Mattermost

## Contributing

Found a bug or want to improve the template? Please open an issue or submit a PR!
