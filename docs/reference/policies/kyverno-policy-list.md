---
title: Kyverno Policy Reference
description: Complete list of active Kyverno policies and their enforcement modes
---

# Kyverno Policy Reference

## Overview

This document lists all active Kyverno policies deployed in the Fawkes platform. Policies enforce security standards, mutate resources for compliance, and generate default configurations.

**Policy Files Location:** `platform/policies/`

**Enforcement Modes:**

- **Enforce:** Blocks non-compliant resources from being created.
- **Audit:** Logs violations but allows resources to be created.
- **Mutate:** Automatically modifies resources to comply with standards.
- **Generate:** Creates new resources based on triggers.

---

## Security Policies (Enforce Mode)

These policies enforce Pod Security Standards and will **DENY** non-compliant resources.

**Source File:** `platform/policies/mandatory-security.yaml`

| Policy Name | Severity | Resource Type | Description | Enforcement Mode |
|-------------|----------|---------------|-------------|------------------|
| `require-run-as-non-root` | High | Pod | Containers must run as non-root user. Validates `securityContext.runAsNonRoot=true`. | **Enforce** |
| `disallow-privileged-containers` | Critical | Pod | Prohibits privileged containers with full host access. | **Enforce** |
| `restrict-host-namespaces` | High | Pod | Disallows `hostNetwork`, `hostPID`, `hostIPC` usage. | **Enforce** |
| `disallow-host-ports` | Medium | Pod | Prevents binding to host ports (`hostPort`). | **Enforce** |
| `disallow-capabilities` | High | Pod | Restricts Linux capabilities beyond defaults (e.g., `CAP_SYS_ADMIN`). | **Enforce** |
| `require-seccomp-profile` | Medium | Pod | Requires seccomp profile (RuntimeDefault or Localhost). | **Audit** |

### Excluded Namespaces

Security policies exclude the following system namespaces:

- `kube-system`
- `kube-public`
- `kube-node-lease`
- `kyverno`
- `vault`

---

## Resource Constraint Policies

Enforce resource management best practices.

**Source File:** `platform/policies/resource-constraints.yaml`

| Policy Name | Severity | Resource Type | Description | Enforcement Mode |
|-------------|----------|---------------|-------------|------------------|
| `require-resource-limits` | High | Pod | All containers must have CPU and memory limits. | **Enforce** |
| `require-resource-requests` | High | Pod | All containers must have CPU and memory requests. | **Enforce** |
| `limit-resource-maximums` | Medium | Pod | Enforces maximum CPU (8 cores) and memory (16Gi) limits. | **Audit** |
| `require-probes` | Medium | Deployment, StatefulSet | Requires `livenessProbe` and `readinessProbe` for workloads. | **Audit** |

### Default Resource Limits

When `add-default-resources` mutation is applied:

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | `100m` | `500m` |
| Memory | `128Mi` | `512Mi` |

---

## Mutation Policies (Automatic Modification)

These policies automatically modify resources to comply with platform standards.

**Source File:** `platform/policies/mutation-policies.yaml`

| Policy Name | Resource Type | Mutation Applied | Description |
|-------------|---------------|------------------|-------------|
| `add-platform-labels` | Pod, Deployment, StatefulSet, DaemonSet | Adds labels:<br>• `app.fawkes.idp/managed-by=fawkes-platform`<br>• `app.fawkes.idp/environment={{namespace}}` | Ensures consistent labeling for monitoring and cost allocation. |
| `add-vault-annotations` | Pod | Adds annotations:<br>• `vault.hashicorp.com/agent-inject=true`<br>• `vault.hashicorp.com/role={{namespace}}` | Enables Vault Agent sidecar for secret injection. |
| `set-ingress-class` | Ingress | Sets `ingressClassName=nginx` | Standardizes Ingress controller usage. |
| `set-default-security-context` | Pod | Sets:<br>• `runAsNonRoot=true`<br>• `allowPrivilegeEscalation=false`<br>• `seccompProfile.type=RuntimeDefault` | Applies secure defaults if not explicitly configured. |
| `add-default-resources` | Pod | Adds CPU/memory requests and limits if missing (see table above). | Prevents unbounded resource consumption. |

---

## Generation Policies (Resource Creation)

These policies automatically create resources when triggers occur (e.g., new namespace creation).

**Source File:** `platform/policies/generation-policies.yaml`

| Policy Name | Trigger | Generated Resource | Description |
|-------------|---------|-------------------|-------------|
| `generate-namespace-network-policy` | New Namespace | NetworkPolicy | Creates default deny-all ingress NetworkPolicy for network isolation. |
| `generate-namespace-resource-quota` | New Namespace | ResourceQuota | Creates quota limiting namespaces to 10 Pods, 20 CPU cores, 40Gi memory. |
| `generate-namespace-limit-range` | New Namespace | LimitRange | Sets default and maximum resource limits for containers. |
| `generate-namespace-service-account` | New Namespace | ServiceAccount | Creates `fawkes-workload` ServiceAccount with standard RBAC. |

### Generated ResourceQuota Limits

| Resource | Limit |
|----------|-------|
| Pods | 10 |
| CPU (total) | 20 cores |
| Memory (total) | 40Gi |
| Persistent Volume Claims | 5 |
| Services (LoadBalancer) | 2 |

---

## Policy Validation Workflow

```text
┌─────────────────────────────────────────────────────────────────┐
│                   Resource Creation Request                      │
└───────────────────────────┬─────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│  Step 1: Mutation Policies (add labels, security context, etc.) │
└───────────────────────────┬─────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│  Step 2: Validation Policies (security, resource constraints)   │
└───────────────────────────┬─────────────────────────────────────┘
                            │
                  ┌─────────┴──────────┐
                  │                    │
                  ▼ (Enforce)          ▼ (Audit)
            ┌──────────┐          ┌──────────┐
            │  DENY    │          │  ALLOW   │
            │ Resource │          │ Resource │
            └──────────┘          └────┬─────┘
                                       │
                                       ▼
                           ┌───────────────────────┐
                           │ Generate PolicyReport │
                           └───────────────────────┘
```

---

## Checking Policy Compliance

### View Policy Reports for a Namespace

```bash
kubectl get policyreport -n <namespace>
```

### View Cluster-Wide Policy Reports

```bash
kubectl get clusterpolicyreport
```

### Describe Policy Violations

```bash
kubectl describe policyreport -n <namespace>
```

### Dry-Run Validation

Test a manifest against policies before applying:

```bash
kubectl apply --dry-run=server -f deployment.yaml
```

---

## Policy Exceptions

If a workload requires a policy exception (e.g., a privileged container for a monitoring agent), create a `PolicyException`:

```yaml
apiVersion: kyverno.io/v2beta1
kind: PolicyException
metadata:
  name: allow-privileged-monitoring
  namespace: monitoring
spec:
  exceptions:
    - policyName: disallow-privileged-containers
      ruleNames:
        - disallow-privileged
  match:
    any:
      - resources:
          kinds:
            - Pod
          names:
            - node-exporter-*
```

---

## Monitoring Policies

Kyverno exposes Prometheus metrics:

| Metric | Description |
|--------|-------------|
| `kyverno_policy_results_total` | Total policy evaluations (by policy, result, and action). |
| `kyverno_admission_review_duration_seconds` | Latency of admission webhook processing. |
| `kyverno_policy_execution_duration_seconds` | Time taken to execute individual policies. |

**Grafana Dashboard:** `grafana.fawkes.idp/d/kyverno`

---

## See Also

- [Kyverno Official Documentation](https://kyverno.io/docs/)
- [Pod Security Standards](https://kubernetes.io/docs/concepts/security/pod-security-standards/)
- [Troubleshoot Kyverno Violations](../../how-to/policy/troubleshoot-kyverno-violation.md)
- [Policy as Code Tiers Explanation](../../explanation/governance/policy-as-code-tiers.md)
- [ADR-017: Kyverno Policy Engine](../../adr/ADR-017%20kyverno-policy-engine.md)
