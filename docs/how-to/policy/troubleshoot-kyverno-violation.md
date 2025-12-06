---
title: Troubleshoot Kyverno Policy Violations
description: Identify and resolve Kyverno policy violations blocking deployments
---

# Troubleshoot Kyverno Policy Violations

## Goal

Identify, understand, and resolve Kyverno policy violations that are blocking resource creation or modification in Kubernetes.

## Prerequisites

Before you begin, ensure you have:

- [ ] Kyverno installed in the cluster
- [ ] `kubectl` configured with cluster access
- [ ] Knowledge of which resource is being blocked
- [ ] Access to view PolicyReports (RBAC permissions)

## Steps

### 1. Identify the Policy Violation

#### Check Resource Status

When a resource fails to deploy due to policy:

```bash
# Try to create/update resource
kubectl apply -f my-deployment.yaml

# Error message will reference the policy:
# Error from server: admission webhook "validate.kyverno.svc" denied the request:
# 
# policy Deployment/my-app-deployment for resource violation:
# 
# require-non-root:
#   runAsNonRoot: 'must set runAsNonRoot to true'
```

#### View PolicyReports

```bash
# List all PolicyReports in namespace
kubectl get policyreport -n my-namespace

# Get detailed report
kubectl get policyreport -n my-namespace polr-ns-my-namespace -o yaml

# Filter for failures only
kubectl get policyreport -n my-namespace -o json | \
  jq '.items[].results[] | select(.result == "fail")'
```

#### Check ClusterPolicyReports

For cluster-wide resources:

```bash
# List ClusterPolicyReports
kubectl get clusterpolicyreport

# View specific report
kubectl describe clusterpolicyreport clusterpolicyreport
```

### 2. Understand the Policy

#### View Policy Definition

```bash
# List all policies
kubectl get clusterpolicy

# Get specific policy
kubectl get clusterpolicy require-non-root -o yaml

# View policy in readable format
kubectl get clusterpolicy require-non-root -o jsonpath='{.spec.rules[*].validate.message}'
```

#### Understand Policy Rules

Common Kyverno policies in Fawkes:

| Policy | Purpose | Validation Rule |
|--------|---------|----------------|
| `require-non-root` | Security: Prevent root containers | `securityContext.runAsNonRoot == true` |
| `require-resource-limits` | Resource management | `resources.limits` must be set |
| `require-labels` | Organization | Required labels: `app`, `team`, `env` |
| `disallow-latest-tag` | Stability | Image tag cannot be `latest` |
| `require-probes` | Reliability | `livenessProbe` and `readinessProbe` required |
| `restrict-ingress-classes` | Security | Only approved Ingress classes allowed |

### 3. Fix Common Policy Violations

#### Violation: "runAsNonRoot must be true"

**Policy:** `require-non-root`

**Problem:** Container running as root user (UID 0).

**Fix:**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
spec:
  template:
    spec:
      # Add security context
      securityContext:
        runAsNonRoot: true
        runAsUser: 1000      # Non-root user ID
        fsGroup: 1000        # File system group
      
      containers:
      - name: my-app
        image: my-app:v1.0.0
        # Container-level security context (optional)
        securityContext:
          runAsNonRoot: true
          runAsUser: 1000
          allowPrivilegeEscalation: false
          capabilities:
            drop:
              - ALL
```

#### Violation: "resource limits must be set"

**Policy:** `require-resource-limits`

**Problem:** Missing resource requests and limits.

**Fix:**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
spec:
  template:
    spec:
      containers:
      - name: my-app
        image: my-app:v1.0.0
        # Add resource limits
        resources:
          requests:
            cpu: "100m"
            memory: "128Mi"
          limits:
            cpu: "500m"
            memory: "512Mi"
```

#### Violation: "required labels missing"

**Policy:** `require-labels`

**Problem:** Missing mandatory labels.

**Fix:**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
  # Add required labels
  labels:
    app: my-app
    team: platform-squad
    env: production
    version: v1.0.0
    component: backend
spec:
  selector:
    matchLabels:
      app: my-app
  template:
    metadata:
      # Also add to pod template
      labels:
        app: my-app
        team: platform-squad
        env: production
        version: v1.0.0
```

#### Violation: "image tag 'latest' not allowed"

**Policy:** `disallow-latest-tag`

**Problem:** Using `latest` tag (not deterministic).

**Fix:**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
spec:
  template:
    spec:
      containers:
      - name: my-app
        # Use specific version tag, SHA, or semantic version
        image: my-app:v1.2.3
        # Or use SHA
        # image: my-app@sha256:abc123...
```

#### Violation: "probes required"

**Policy:** `require-probes`

**Problem:** Missing liveness or readiness probes.

**Fix:**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
spec:
  template:
    spec:
      containers:
      - name: my-app
        image: my-app:v1.0.0
        
        # Add liveness probe
        livenessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 10
          timeoutSeconds: 5
          failureThreshold: 3
        
        # Add readiness probe
        readinessProbe:
          httpGet:
            path: /ready
            port: 8080
          initialDelaySeconds: 10
          periodSeconds: 5
          timeoutSeconds: 3
          failureThreshold: 3
```

### 4. Request Policy Exception

If a policy violation is legitimate but unavoidable:

#### Create PolicyException

```yaml
apiVersion: kyverno.io/v2beta1
kind: PolicyException
metadata:
  name: allow-root-for-legacy-app
  namespace: my-namespace
spec:
  # Which resources to exclude
  match:
    any:
    - resources:
        kinds:
          - Deployment
        namespaces:
          - my-namespace
        names:
          - legacy-app*  # Wildcard supported
  
  # Which policies to exclude from
  exceptions:
  - policyName: require-non-root
    ruleNames:
    - validate-runAsNonRoot
  
  # Justification (good practice)
  background: "Legacy database container requires root for initialization scripts"
```

Apply the exception:

```bash
# Create exception
kubectl apply -f policy-exception.yaml

# Verify exception created
kubectl get policyexception -n my-namespace

# Now resource can be created despite policy
kubectl apply -f legacy-app-deployment.yaml
```

### 5. Test Policy Compliance

#### Dry-Run Validation

```bash
# Test resource against policies without creating it
kubectl apply -f my-deployment.yaml --dry-run=server

# If policies pass, no error message
# If policies fail, error shows which policy blocked it
```

#### Use kubectl-kyverno Plugin

```bash
# Install kubectl-kyverno plugin
kubectl krew install kyverno

# Test resource against policies
kubectl kyverno apply \
  --cluster \
  --resource my-deployment.yaml

# Output shows which policies pass/fail
```

#### Validate Locally Before Push

Create a test script:

```bash
#!/bin/bash
# validate-manifests.sh

for manifest in manifests/*.yaml; do
  echo "Validating $manifest..."
  kubectl apply -f "$manifest" --dry-run=server || exit 1
done

echo "All manifests passed policy validation!"
```

### 6. Monitor Policy Reports

#### Create Alert on Policy Violations

```bash
# View recent violations
kubectl get policyreport -A -o json | \
  jq '.items[].results[] | select(.result == "fail") | {policy: .policy, resource: .resources[0].name, message: .message}'

# Set up Prometheus alert (if metrics enabled)
```

#### Export Policy Report

```bash
# Export violations to file
kubectl get policyreport -A -o json > policy-violations.json

# Generate HTML report (using kubectl-kyverno)
kubectl kyverno report --output html > policy-report.html
```

## Verification

### 1. Verify Resource Passes Policies

```bash
# Apply with dry-run
kubectl apply -f my-deployment.yaml --dry-run=server

# Expected: No error (policies pass)
# Actually apply
kubectl apply -f my-deployment.yaml

# Verify resource created
kubectl get deployment my-app -n my-namespace
```

### 2. Verify PolicyReport Shows Pass

```bash
# Check PolicyReport for resource
kubectl get policyreport -n my-namespace -o json | \
  jq '.items[].results[] | select(.resources[0].name == "my-app")'

# Should show: "result": "pass"
```

### 3. Verify No Violations in Audit Mode

```bash
# Check for any fail results
kubectl get policyreport -A -o json | \
  jq '.items[].results[] | select(.result == "fail") | length'

# Expected: 0 (no failures)
```

## Understanding Kyverno Policy Modes

### Audit Mode

Policy violations are logged but not blocked:

```yaml
spec:
  validationFailureAction: Audit  # Log violations, don't block
```

Resources are created, but violations appear in PolicyReports.

### Enforce Mode

Policy violations block resource creation:

```yaml
spec:
  validationFailureAction: Enforce  # Block non-compliant resources
```

Resources fail to create if they violate the policy.

### Check Policy Mode

```bash
# View policy mode
kubectl get clusterpolicy require-non-root -o jsonpath='{.spec.validationFailureAction}'

# Output: Audit or Enforce
```

## Common Policy Patterns

### Allow Specific Namespaces

```yaml
spec:
  # Exclude certain namespaces from policy
  exclude:
    resources:
      namespaces:
        - kube-system
        - monitoring
        - cert-manager
```

### Require Specific Annotations

```yaml
spec:
  rules:
  - name: require-deployment-annotations
    match:
      resources:
        kinds:
        - Deployment
    validate:
      message: "Deployments must have 'owner' and 'cost-center' annotations"
      pattern:
        metadata:
          annotations:
            owner: "?*"
            cost-center: "?*"
```

### Mutate Resources (Auto-Fix)

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: add-default-resources
spec:
  rules:
  - name: add-resource-limits
    match:
      resources:
        kinds:
        - Deployment
    mutate:
      patchStrategicMerge:
        spec:
          template:
            spec:
              containers:
              - (name): "*"
                resources:
                  limits:
                    +(memory): "512Mi"
                    +(cpu): "500m"
```

## Troubleshooting

### Policy Not Being Enforced

**Cause:** Policy mode is `Audit` or policy doesn't match resources.

**Solution:**

```bash
# Check policy mode
kubectl get clusterpolicy <policy-name> -o jsonpath='{.spec.validationFailureAction}'

# Check if policy matches resource
kubectl describe clusterpolicy <policy-name>

# Look at match/exclude rules
```

### PolicyReport Not Showing Results

**Cause:** Background scanning disabled or reports not generated yet.

**Solution:**

```bash
# Check if background scanning is enabled
kubectl get clusterpolicy <policy-name> -o jsonpath='{.spec.background}'

# Trigger manual scan
kubectl annotate deployment my-app -n my-namespace \
  policies.kyverno.io/last-applied-patches=""

# Wait 1-2 minutes for report to update
```

### Cannot Create Exception

**Cause:** PolicyException CRD not installed or insufficient permissions.

**Solution:**

```bash
# Check if PolicyException CRD exists
kubectl get crd policyexceptions.kyverno.io

# If missing, upgrade Kyverno
helm upgrade kyverno kyverno/kyverno -n kyverno --set features.policyExceptions.enabled=true

# Check RBAC permissions
kubectl auth can-i create policyexceptions --namespace my-namespace
```

### Resource Passes Dry-Run but Fails on Apply

**Cause:** Webhook timeout or Kyverno unavailable.

**Solution:**

```bash
# Check Kyverno pods
kubectl get pods -n kyverno

# Check webhook configuration
kubectl get validatingwebhookconfiguration kyverno-resource-validating-webhook-cfg

# Check webhook logs
kubectl logs -n kyverno -l app.kubernetes.io/component=admission-controller --tail=100
```

## Next Steps

After resolving policy violations:

- [Onboard Service to ArgoCD](../gitops/onboard-service-argocd.md) - Deploy compliant resources
- [Rotate Vault Secrets](../security/rotate-vault-secrets.md) - Manage secrets per policy
- [Configure Ingress TLS](../networking/configure-ingress-tls.md) - Secure networking
- [Security Documentation](../../security.md) - Platform security best practices

## Related Documentation

- [Kyverno Configuration](../../platform/apps/kyverno/README.md) - Policy setup
- [Security Best Practices](../../security.md) - Platform security
- [Kyverno Documentation](https://kyverno.io/docs/) - Official Kyverno docs
- [Policy Catalog](https://kyverno.io/policies/) - Pre-built policies
