# Kyverno Policy Engine for Fawkes IDP

## Overview

Kyverno is a Kubernetes-native policy engine that enables policy-as-code for the
Fawkes Internal Delivery Platform. It provides validation, mutation, and
generation capabilities to enforce security, standardization, and governance
policies across all application deployments.

## Features

- **Validation Policies**: Enforce security standards (Pod Security Standards,
  resource limits)
- **Mutation Policies**: Automatically add platform labels, Vault integration
- **Generation Policies**: Create standard resources for new namespaces
- **Policy Reports**: Audit and compliance reporting via PolicyReport CRDs

## Deployment

Kyverno is deployed via ArgoCD using the official Helm chart:

```bash
# Deployed automatically via ArgoCD Application
kubectl get application kyverno -n fawkes
```

## Architecture

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│                          Kyverno Policy Engine                               │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────────────────┐  │
│  │   Admission      │  │   Background     │  │   Reports Controller     │  │
│  │   Controller     │  │   Controller     │  │                          │  │
│  │   (3 replicas)   │  │   (2 replicas)   │  │   • PolicyReport         │  │
│  │                  │  │                  │  │   • ClusterPolicyReport  │  │
│  │   • Validate     │  │   • Generate     │  │                          │  │
│  │   • Mutate       │  │   • Background   │  │                          │  │
│  └──────────────────┘  └──────────────────┘  └──────────────────────────┘  │
│                                                                              │
│  ┌──────────────────────────────────────────────────────────────────────┐   │
│  │                         Policy Types                                  │   │
│  │                                                                        │   │
│  │  ClusterPolicy (cluster-wide)  │  Policy (namespace-scoped)          │   │
│  │  • Security enforcement        │  • Team-specific rules              │   │
│  │  • Platform standards          │  • Application policies             │   │
│  └──────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Policies

### Security Policies (Enforce Mode)

Located in `platform/policies/mandatory-security.yaml`:

| Policy                           | Description                            | Action |
| -------------------------------- | -------------------------------------- | ------ |
| `require-run-as-non-root`        | Pods must run as non-root user         | Deny   |
| `disallow-privileged-containers` | Privileged containers not allowed      | Deny   |
| `require-resource-limits`        | Pods must have CPU/memory limits       | Deny   |
| `restrict-host-namespaces`       | Disallow hostNetwork, hostPID, hostIPC | Deny   |

### Mutation Policies (Mutate Mode)

Located in `platform/policies/mutation-policies.yaml`:

| Policy                         | Description                    | Mutation               |
| ------------------------------ | ------------------------------ | ---------------------- |
| `add-platform-labels`          | Add Fawkes platform labels     | Add labels             |
| `add-vault-annotations`        | Add Vault Agent sidecar config | Add annotations        |
| `set-default-security-context` | Set secure defaults            | Modify securityContext |

### Generation Policies (Generate Mode)

Located in `platform/policies/generation-policies.yaml`:

| Policy                        | Description                           | Generated Resources          |
| ----------------------------- | ------------------------------------- | ---------------------------- |
| `generate-namespace-defaults` | Standard resources for new namespaces | NetworkPolicy, ResourceQuota |

## Usage

### For Developers

Your deployments will be automatically validated and mutated by Kyverno. To
check policy compliance:

```bash
# View policy reports for your namespace
kubectl get policyreport -n <namespace>

# View cluster-wide policy reports
kubectl get clusterpolicyreport
```

### Testing Policy Compliance

Test a manifest against policies before deployment:

```bash
# Dry-run validation
kubectl apply --dry-run=server -f deployment.yaml
```

### Viewing Policy Violations

```bash
# Get detailed policy violations
kubectl describe policyreport -n <namespace>

# List all violations across cluster
kubectl get clusterpolicyreport -o yaml
```

## Monitoring

Kyverno exposes Prometheus metrics:

- **Policy admission latency**: `kyverno_admission_review_duration_seconds`
- **Policy violations**: `kyverno_policy_results_total`
- **Controller health**: `kyverno_controller_reconcile_total`

Access Grafana dashboard at: `grafana.fawkes.idp/d/kyverno`

## Troubleshooting

### Common Issues

**Policy blocks my deployment:**

1. Check the error message for which policy is failing
2. View the policy details: `kubectl get clusterpolicy <name> -o yaml`
3. Fix the manifest to comply or request policy exception

**Mutation not applied:**

1. Verify the resource matches policy selector
2. Check Kyverno admission controller logs:
   ```bash
   kubectl logs -n kyverno -l app.kubernetes.io/component=admission-controller
   ```

**Policy reports missing:**

1. Ensure reports controller is running:
   ```bash
   kubectl get pods -n kyverno -l app.kubernetes.io/component=reports-controller
   ```

## References

- [Kyverno Documentation](https://kyverno.io/docs/)
- [Policy Examples](https://kyverno.io/policies/)
- [Fawkes Security Architecture](../../docs/architecture.md#security-architecture)
- [ADR-017: Kyverno Policy Engine](../../docs/adr/ADR-017%20kyverno-policy-engine.md)
