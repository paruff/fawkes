# SCORE Transformer for Fawkes

This component translates `score.yaml` workload specifications into Kubernetes manifests for deployment via ArgoCD.

## Architecture

The SCORE transformer is implemented as a **Kustomize generator plugin** that:

1. Reads `score.yaml` from the application repository
2. Reads environment configuration (dev/staging/prod)
3. Generates K8s manifests (Deployment, Service, Ingress, etc.)
4. Outputs manifests for Kustomize to apply overlays

## Implementation Options

### Option 1: Use Official score-k8s CLI (Recommended)

[score-k8s](https://github.com/score-spec/score-k8s) is the official Kubernetes implementation of the SCORE specification.

**Pros**:

- Official implementation, maintained by SCORE community
- Supports full SCORE spec
- Regular updates and bug fixes
- Good documentation

**Cons**:

- May require customization for Fawkes-specific extensions
- Additional binary dependency in CI/CD pipeline

**Usage**:

```bash
# Install score-k8s
curl -Lo score-k8s https://github.com/score-spec/score-k8s/releases/download/v0.1.0/score-k8s_0.1.0_linux_amd64
chmod +x score-k8s

# Generate manifests
score-k8s generate score.yaml \
  --environment dev \
  --output manifests/
```

### Option 2: Custom Kustomize Generator

A lightweight Python script that runs as a Kustomize exec plugin.

**Pros**:

- Full control over transformation logic
- Easy to add Fawkes-specific features
- No external binary dependencies (Python already in pipeline)

**Cons**:

- Maintenance burden on platform team
- Need to keep up with SCORE spec changes

**Implementation**: See `generator.py` in this directory.

### Decision: Hybrid Approach

We will use **score-k8s** for baseline SCORE support with a **custom post-processor** for Fawkes extensions.

```
score.yaml
    │
    ├─> score-k8s generate (baseline manifests)
    │
    ├─> fawkes-post-processor.py (add extensions)
    │   - Observability annotations
    │   - Security policies
    │   - Resource provisioning
    │
    └─> K8s manifests (Deployment, Service, Ingress, etc.)
```

## Directory Structure

```
charts/score-transformer/
├── README.md                      # This file
├── generator.py                   # Main transformer script
├── post-processor.py              # Fawkes-specific enhancements
├── templates/                     # Jinja2 templates for K8s resources
│   ├── deployment.yaml.j2
│   ├── service.yaml.j2
│   ├── ingress.yaml.j2
│   ├── pvc.yaml.j2
│   └── externalsecret.yaml.j2
├── tests/                         # Unit tests
│   ├── test_generator.py
│   ├── test_post_processor.py
│   └── fixtures/
│       └── sample-score.yaml
└── kustomize/
    └── generator.yaml             # Kustomize generator config

```

## Usage in GitOps Pipeline

### 1. Application Repository Structure

```
my-service/
├── score.yaml                     # Workload definition (SCORE spec)
├── kustomization.yaml             # Kustomize config
└── overlays/
    ├── dev/
    │   └── kustomization.yaml     # Dev-specific overrides
    ├── staging/
    │   └── kustomization.yaml
    └── prod/
        └── kustomization.yaml
```

### 2. Base kustomization.yaml

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

generators:
  # SCORE transformer
  - |-
    apiVersion: fawkes.dev/v1
    kind: ScoreTransformer
    metadata:
      name: score-generator
    spec:
      scoreFile: score.yaml
      environment: ${ENVIRONMENT}
```

### 3. ArgoCD Sync

When ArgoCD syncs, it runs:

```bash
kustomize build overlays/dev | kubectl apply -f -
```

Which executes:

1. Kustomize reads `generators` block
2. Runs `score-transformer` on `score.yaml`
3. Generates base K8s manifests
4. Applies dev overlay customizations
5. Outputs final manifests

## Environment Configuration

Environment-specific values are injected via Kustomize overlays:

**overlays/dev/kustomization.yaml**:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

bases:
  - ../../base

# Environment-specific values
configMapGenerator:
  - name: env-config
    literals:
      - ENVIRONMENT=dev
      - VAULT_ADDR=https://vault.dev.fawkes.local
      - LOG_LEVEL=debug

# Namespace
namespace: my-team-dev

# Replicas override
replicas:
  - name: my-service
    count: 1
```

**overlays/prod/kustomization.yaml**:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

bases:
  - ../../base

configMapGenerator:
  - name: env-config
    literals:
      - ENVIRONMENT=prod
      - VAULT_ADDR=https://vault.prod.fawkes.local
      - LOG_LEVEL=info

namespace: my-team-prod

replicas:
  - name: my-service
    count: 3

# Prod-specific patches
patchesStrategicMerge:
  - increase-resources.yaml
```

## Supported SCORE Resources

### Core Resources (v1)

| SCORE Type | Fawkes Implementation     | K8s Resource                 |
| ---------- | ------------------------- | ---------------------------- |
| `postgres` | CloudNativePG Cluster     | ExternalSecret (credentials) |
| `redis`    | Redis Helm Chart          | ExternalSecret (credentials) |
| `secret`   | External Secrets Operator | ExternalSecret → Secret      |
| `volume`   | PersistentVolumeClaim     | PVC                          |

### Extended Resources (Future)

| SCORE Type | Fawkes Implementation           |
| ---------- | ------------------------------- |
| `mysql`    | CloudNativePG (MySQL)           |
| `s3`       | Terraform-provisioned S3 bucket |
| `rabbitmq` | RabbitMQ Operator               |
| `kafka`    | Strimzi Kafka Operator          |

## Fawkes Extensions

Beyond standard SCORE, we support Fawkes-specific extensions under `extensions.fawkes`:

```yaml
extensions:
  fawkes:
    team: my-team # For RBAC and billing
    deployment:
      autoscaling: { ... } # HPA configuration
    observability:
      metrics: { ... } # Prometheus scraping
      tracing: { ... } # OpenTelemetry config
    security:
      networkPolicy: { ... } # Network policies
```

These are transformed into:

- ServiceAccount with team RBAC
- HorizontalPodAutoscaler
- PodMonitor (Prometheus)
- OpenTelemetry annotations
- NetworkPolicy

## Development

### Running Tests

```bash
cd charts/score-transformer
pytest tests/ -v
```

### Testing Locally

```bash
# Generate manifests from sample score.yaml
python generator.py \
  --score tests/fixtures/sample-score.yaml \
  --environment dev \
  --output /tmp/manifests

# Validate generated manifests
kubectl apply --dry-run=client -f /tmp/manifests
```

### Adding a New Resource Type

1. Add template in `templates/<resource-type>.yaml.j2`
2. Add translation logic in `generator.py`
3. Add test case in `tests/test_generator.py`
4. Update documentation

## Troubleshooting

### Issue: Generated manifests missing expected resources

**Solution**: Check score.yaml syntax with official validator:

```bash
score-k8s validate score.yaml
```

### Issue: Environment variables not interpolated

**Solution**: Ensure environment config is in Kustomize overlay:

```yaml
configMapGenerator:
  - name: env-config
    literals:
      - ENVIRONMENT=dev
```

### Issue: Custom Fawkes extensions not applied

**Solution**: Verify `post-processor.py` is being executed. Check ArgoCD logs:

```bash
kubectl logs -n argocd <argocd-pod> | grep score-transformer
```

## References

- [SCORE Specification](https://score.dev)
- [score-k8s GitHub](https://github.com/score-spec/score-k8s)
- [Kustomize Generators](https://kubectl.docs.kubernetes.io/references/kustomize/kustomization/generators/)
- [ADR-030: SCORE Integration](../../docs/adr/ADR-030%20SCORE%20Workload%20Specification%20Integration.md)
