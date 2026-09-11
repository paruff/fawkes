# Set Up RBAC for a Service

> **Goal**: least-privilege Kubernetes RBAC for a service namespace (ServiceAccount + Role + RoleBinding).

## Prerequisites

- A live cluster (`kubectl cluster-info`) and a service namespace (e.g. `fawkes`)

## Steps

1. **Create a dedicated ServiceAccount** (services must not use `default`):

   ```bash
   kubectl create serviceaccount my-service -n fawkes
   ```

2. **Grant only what it needs** with a namespaced `Role` (example: read pods, no secrets):

   ```yaml
   apiVersion: rbac.authorization.k8s.io/v1
   kind: Role
   metadata:
     name: my-service-reader
     namespace: fawkes
   rules:
     - apiGroups: [""]
       resources: ["pods"]
       verbs: ["get", "list"]
   ```

3. **Bind the role** to the ServiceAccount and reference it from the Deployment (`spec.serviceAccountName`).

4. **Verify** the grant is minimal:

   ```bash
   kubectl auth can-i --as=system:serviceaccount:fawkes:my-service get pods -n fawkes
   # want: yes
   kubectl auth can-i --as=system:serviceaccount:fawkes:my-service get secrets -n fawkes
   # want: no
   ```

## Verify success

- `kubectl describe rolebinding -n fawkes` shows only the intended binding.
- Platform Kyverno policies (`platform/policies/`) report no violation for the namespace.

## Background

See [zero-trust model](../../explanation/security/zero-trust-model.md) for the platform's RBAC posture.
