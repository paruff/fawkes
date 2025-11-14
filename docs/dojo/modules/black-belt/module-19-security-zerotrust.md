# Module 19: Security & Zero Trust Architecture

**Belt Level**: ⚫ Black Belt
**Duration**: 60 minutes
**Prerequisites**: Modules 1-18, especially Module 7 (Security Scanning), Module 13 (Observability)
**Certification Track**: Fawkes Platform Architect

---

## 🎯 Learning Objectives

By the end of this module, you will be able to:

1. **Design and implement** a zero trust security architecture for internal developer platforms
2. **Apply** the principle of "never trust, always verify" to CI/CD pipelines and deployment workflows
3. **Implement** mutual TLS (mTLS), service mesh security, and workload identity
4. **Configure** policy-as-code enforcement using Open Policy Agent (OPA) and admission controllers
5. **Establish** supply chain security practices including SBOM generation, image signing, and provenance verification

---

## 📚 Theory: Zero Trust for Platform Engineering

### What is Zero Trust?

Zero trust is a security model based on the principle of **"never trust, always verify"**. Unlike traditional perimeter-based security (castle-and-moat), zero trust assumes:

- **No implicit trust**: Location (inside/outside network) doesn't grant access
- **Verify explicitly**: Always authenticate and authorize based on all available data points
- **Least privilege access**: Grant minimum permissions necessary for the task
- **Assume breach**: Design systems expecting compromise at any point

### Why Zero Trust Matters for IDPs

Internal Developer Platforms handle:

- **Credentials and secrets** for all production systems
- **CI/CD pipelines** that deploy code to production
- **Container registries** with potentially vulnerable images
- **Service-to-service communication** across microservices
- **Developer access** to sensitive production resources

A breach at any point could cascade across your entire platform. Zero trust minimizes blast radius.

### The Zero Trust Architecture Pillars

```
┌─────────────────────────────────────────────────────────────┐
│                    ZERO TRUST PRINCIPLES                    │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  1. IDENTITY                                                │
│     ├─ Workload Identity (not long-lived credentials)      │
│     ├─ Human Identity (SSO, MFA, short-lived tokens)       │
│     └─ Machine Identity (service accounts, mTLS)           │
│                                                             │
│  2. DEVICE                                                  │
│     ├─ Endpoint security posture                           │
│     ├─ Compliance validation                               │
│     └─ Device certificates                                 │
│                                                             │
│  3. NETWORK                                                 │
│     ├─ Encrypt all traffic (TLS everywhere)                │
│     ├─ Micro-segmentation                                  │
│     └─ Service mesh (Istio, Linkerd)                       │
│                                                             │
│  4. APPLICATION                                             │
│     ├─ Policy-as-code enforcement                          │
│     ├─ Runtime security (Falco, AppArmor)                  │
│     └─ Admission controllers                               │
│                                                             │
│  5. DATA                                                    │
│     ├─ Encryption at rest and in transit                   │
│     ├─ Data classification and DLP                         │
│     └─ Secret management (Vault, External Secrets)         │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Zero Trust in CI/CD Pipelines

Traditional CI/CD often uses:
- ❌ Long-lived credentials stored in CI system
- ❌ Broad permissions for deployment service accounts
- ❌ No verification of artifact provenance
- ❌ Implicit trust between pipeline stages

**Zero trust CI/CD**:
- ✅ Workload identity for pipeline authentication (OIDC)
- ✅ Least-privilege, ephemeral credentials
- ✅ Cryptographic verification of artifacts (Sigstore/Cosign)
- ✅ Policy enforcement at every stage

---

## 🔐 Core Concepts

### 1. Workload Identity

**Problem**: Traditional approaches use long-lived service account keys stored as secrets.

**Zero Trust Solution**: Workload identity allows pods/pipelines to authenticate using short-lived tokens.

**Example: GitHub Actions → AWS**
```yaml
# Traditional approach (NEVER DO THIS)
- name: Configure AWS Credentials
  env:
    AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY }}     # ❌ Long-lived
    AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_KEY }} # ❌ Rotated manually

# Zero trust approach with OIDC
- name: Configure AWS Credentials
  uses: aws-actions/configure-aws-credentials@v4
  with:
    role-to-assume: arn:aws:iam::123456789:role/GitHubActionsRole
    aws-region: us-east-1
    # ✅ No secrets stored in GitHub
    # ✅ Short-lived tokens (1 hour)
    # ✅ Scoped to specific repos/branches
```

**Example: Kubernetes Workload Identity**
```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: payment-service
  annotations:
    # AWS: Map to IAM role
    eks.amazonaws.com/role-arn: arn:aws:iam::123456789:role/payment-service

    # GCP: Map to GCP service account
    iam.gke.io/gcp-service-account: payment@project.iam.gserviceaccount.com
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: payment-service
spec:
  template:
    spec:
      serviceAccountName: payment-service  # ✅ Pod gets temporary credentials
      containers:
      - name: app
        image: payment-service:v1.2.3
        # No AWS_ACCESS_KEY_ID needed! SDK auto-discovers credentials
```

### 2. Mutual TLS (mTLS) and Service Mesh

**mTLS**: Both client and server authenticate using certificates, encrypting all traffic.

**Service Mesh** (Istio, Linkerd, Consul) provides:
- Automatic mTLS between all services
- Fine-grained authorization policies
- Traffic encryption without code changes

**Example: Istio Authorization Policy**
```yaml
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: payment-access-policy
  namespace: payments
spec:
  selector:
    matchLabels:
      app: payment-api
  action: ALLOW
  rules:
  - from:
    - source:
        principals:
        - "cluster.local/ns/checkout/sa/checkout-service"  # Only checkout can call
    to:
    - operation:
        methods: ["POST"]
        paths: ["/api/v1/charge"]
  - from:
    - source:
        principals:
        - "cluster.local/ns/admin/sa/admin-dashboard"
    to:
    - operation:
        methods: ["GET"]
        paths: ["/api/v1/transactions/*"]
```

**Result**: Even if an attacker compromises the `frontend` service, they cannot call the payment API.

### 3. Policy-as-Code with OPA

**Open Policy Agent (OPA)**: Express security policies as code, enforce them at runtime.

**Gatekeeper**: OPA integration for Kubernetes admission control.

**Example: Require Image Signatures**
```rego
package kubernetes.admission

import future.keywords.contains
import future.keywords.if

# Deny pods with unsigned images
deny[msg] {
    input.request.kind.kind == "Pod"
    image := input.request.object.spec.containers[_].image
    not image_is_signed(image)
    msg := sprintf("Image %v is not signed. All images must be signed with Cosign.", [image])
}

# Check if image has valid signature
image_is_signed(image) if {
    # Query external service or cache of verified images
    verified_images := data.verified_images
    image_ref := split(image, "@")[0]
    verified_images[image_ref]
}
```

**Example: Enforce Resource Limits**
```rego
package kubernetes.admission

deny[msg] {
    input.request.kind.kind == "Deployment"
    container := input.request.object.spec.template.spec.containers[_]
    not container.resources.limits.memory
    msg := sprintf("Container %v must specify memory limits", [container.name])
}

deny[msg] {
    input.request.kind.kind == "Deployment"
    container := input.request.object.spec.template.spec.containers[_]
    not container.resources.limits.cpu
    msg := sprintf("Container %v must specify CPU limits", [container.name])
}
```

### 4. Supply Chain Security (SLSA)

**Supply chain attacks**: Compromise the build or delivery process to inject malicious code.

**SLSA (Supply Chain Levels for Software Artifacts)**: Framework for supply chain integrity.

**Key Components**:

1. **SBOM (Software Bill of Materials)**: List all dependencies
2. **Provenance**: Cryptographically signed record of how artifact was built
3. **Image Signing**: Sign container images with Cosign/Sigstore
4. **Verification**: Verify signatures before deployment

**Example: Generate SBOM with Syft**
```bash
# Generate SBOM for container image
syft packages registry:ghcr.io/myorg/payment-service:v1.2.3 \
  -o spdx-json=sbom.json

# Generate SBOM during build
syft packages dir:. -o cyclonedx-json=sbom.json
```

**Example: Sign Image with Cosign**
```bash
# Sign image (uses keyless signing with Sigstore)
cosign sign ghcr.io/myorg/payment-service:v1.2.3

# Generate provenance attestation
cosign attest --predicate provenance.json \
  ghcr.io/myorg/payment-service:v1.2.3

# Verify signature before deployment
cosign verify ghcr.io/myorg/payment-service:v1.2.3 \
  --certificate-identity-regexp 'https://github.com/myorg/*' \
  --certificate-oidc-issuer 'https://token.actions.githubusercontent.com'
```

**Example: Policy to Require Signatures**
```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: verify-image-signatures
spec:
  validationFailureAction: enforce
  rules:
  - name: verify-signature
    match:
      any:
      - resources:
          kinds:
          - Pod
    verifyImages:
    - imageReferences:
      - "ghcr.io/myorg/*"
      attestors:
      - entries:
        - keyless:
            subject: "https://github.com/myorg/*"
            issuer: "https://token.actions.githubusercontent.com"
            rekor:
              url: https://rekor.sigstore.dev
```

### 5. Secret Management

**Never store secrets in**:
- ❌ Git repositories
- ❌ Environment variables in Dockerfiles
- ❌ ConfigMaps
- ❌ Hardcoded in source code

**Zero trust secret management**:

```yaml
# External Secrets Operator: Sync from Vault/AWS Secrets Manager
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: payment-api-secrets
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: aws-secretsmanager
    kind: SecretStore
  target:
    name: payment-api-secrets
    creationPolicy: Owner
  data:
  - secretKey: stripe-api-key
    remoteRef:
      key: prod/payment/stripe-api-key
  - secretKey: database-password
    remoteRef:
      key: prod/payment/db-password
```

**Vault Integration**:
```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: payment-service
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: payment-service
spec:
  template:
    metadata:
      annotations:
        vault.hashicorp.com/agent-inject: "true"
        vault.hashicorp.com/role: "payment-service"
        vault.hashicorp.com/agent-inject-secret-stripe: "secret/data/payment/stripe"
    spec:
      serviceAccountName: payment-service
      containers:
      - name: app
        image: payment-service:v1.2.3
        # Vault agent sidecar injects secrets at /vault/secrets/stripe
```

---

## 🏗️ Zero Trust Architecture for Fawkes

### Reference Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         DEVELOPER                               │
│                              │                                  │
│                    ┌─────────▼──────────┐                       │
│                    │   SSO + MFA        │                       │
│                    │   (Okta, Keycloak) │                       │
│                    └─────────┬──────────┘                       │
│                              │                                  │
│                              │ OIDC Token                       │
│                              │                                  │
├──────────────────────────────┼──────────────────────────────────┤
│                              ▼                                  │
│                    ┌──────────────────┐                         │
│                    │  API Gateway     │                         │
│                    │  + Policy Engine │                         │
│                    │  (OPA, Kyverno)  │                         │
│                    └────────┬─────────┘                         │
│                             │                                   │
│          ┌──────────────────┼──────────────────┐                │
│          │                  │                  │                │
│    ┌─────▼──────┐    ┌──────▼──────┐   ┌──────▼───────┐        │
│    │  Backstage │    │   ArgoCD    │   │  CI System   │        │
│    │  (mTLS)    │    │   (mTLS)    │   │  (Tekton)    │        │
│    └─────┬──────┘    └──────┬──────┘   └──────┬───────┘        │
│          │                  │                  │                │
│          │ Workload Identity│ Workload Identity│                │
│          │                  │                  │                │
├──────────┼──────────────────┼──────────────────┼────────────────┤
│          │                  │                  │                │
│          │          ┌───────▼──────────┐       │                │
│          │          │  Service Mesh    │       │                │
│          │          │  (Istio/Linkerd) │       │                │
│          │          │   - mTLS         │       │                │
│          │          │   - AuthZ Policy │       │                │
│          │          └───────┬──────────┘       │                │
│          │                  │                  │                │
│    ┌─────▼──────────────────▼──────────────────▼───────┐        │
│    │           Application Workloads                   │        │
│    │  ┌──────────┐  ┌──────────┐  ┌──────────┐       │        │
│    │  │ Frontend │  │  Backend │  │ Database │       │        │
│    │  │  (mTLS)  │  │  (mTLS)  │  │  (mTLS)  │       │        │
│    │  └──────────┘  └──────────┘  └──────────┘       │        │
│    │                                                   │        │
│    │  🔐 All traffic encrypted                        │        │
│    │  🔐 Every request authenticated                  │        │
│    │  🔐 Authorization at every hop                   │        │
│    └───────────────────────────────────────────────────┘        │
│                                                                 │
│  Secrets: Vault / External Secrets Operator                    │
│  Logging: All authN/authZ decisions → SIEM                     │
│  Policy: OPA Gatekeeper + Kyverno admission controllers        │
└─────────────────────────────────────────────────────────────────┘
```

### Zero Trust CI/CD Pipeline

```
┌──────────────────────────────────────────────────────────────┐
│  1. CODE COMMIT                                              │
│     └─ Developer pushes to GitHub                           │
│        └─ Signed commit (GPG signature required)            │
└────────────────────┬─────────────────────────────────────────┘
                     │
                     ▼
┌──────────────────────────────────────────────────────────────┐
│  2. CI PIPELINE TRIGGERED (Tekton/GitHub Actions)            │
│     ├─ Authenticate with OIDC (no long-lived credentials)   │
│     ├─ Scan code (SAST: Semgrep, CodeQL)                    │
│     ├─ Dependency check (Dependabot, Snyk)                  │
│     ├─ Build image in ephemeral runner                      │
│     ├─ Scan image (Trivy, Grype)                            │
│     ├─ Generate SBOM (Syft)                                 │
│     ├─ Sign image (Cosign/Sigstore)                         │
│     ├─ Generate provenance attestation                      │
│     └─ Push to registry with signature                      │
└────────────────────┬─────────────────────────────────────────┘
                     │
                     ▼
┌──────────────────────────────────────────────────────────────┐
│  3. ADMISSION CONTROL (Kubernetes)                           │
│     ├─ Gatekeeper/Kyverno verify signature                  │
│     ├─ Check SBOM for known vulnerabilities                 │
│     ├─ Enforce resource limits                              │
│     ├─ Validate security context (no root, read-only FS)    │
│     └─ Only allow if ALL policies pass                      │
└────────────────────┬─────────────────────────────────────────┘
                     │
                     ▼
┌──────────────────────────────────────────────────────────────┐
│  4. DEPLOYMENT (ArgoCD)                                      │
│     ├─ ArgoCD authenticates with workload identity          │
│     ├─ Applies manifests to cluster                         │
│     ├─ Service mesh injects mTLS sidecar                    │
│     └─ Pod authenticates to Vault for secrets               │
└────────────────────┬─────────────────────────────────────────┘
                     │
                     ▼
┌──────────────────────────────────────────────────────────────┐
│  5. RUNTIME SECURITY                                         │
│     ├─ Falco monitors for suspicious syscalls               │
│     ├─ Service mesh enforces authorization policies         │
│     ├─ All traffic encrypted with mTLS                      │
│     └─ Logs sent to SIEM for audit                          │
└──────────────────────────────────────────────────────────────┘
```

---

## 🛠️ Hands-On Lab: Implementing Zero Trust for Fawkes

### Lab Overview

You will implement key zero trust components:
1. Configure workload identity for CI/CD
2. Deploy a service mesh with mTLS
3. Implement policy-as-code with OPA Gatekeeper
4. Sign and verify container images with Cosign
5. Configure External Secrets Operator

**Duration**: 25 minutes
**Tools**: `kubectl`, `cosign`, `helm`, `fawkes` CLI

---

### Lab Setup

```bash
# Ensure you're in the Fawkes lab environment
fawkes lab start --module 19

# Verify cluster access
kubectl get nodes

# You should see a 3-node cluster with Istio pre-installed
```

---

### Exercise 1: Deploy Istio Service Mesh (5 minutes)

**Objective**: Enable mTLS for all services in the `payments` namespace.

```bash
# Istio is already installed in the lab. Enable strict mTLS for payments namespace.
kubectl create namespace payments

kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: default
  namespace: payments
spec:
  mtls:
    mode: STRICT  # Require mTLS for all traffic
EOF

# Verify
kubectl get peerauthentication -n payments
```

**Deploy a test service**:

```bash
kubectl apply -f - <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: payment-api
  namespace: payments
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: payment-api
  namespace: payments
spec:
  replicas: 2
  selector:
    matchLabels:
      app: payment-api
  template:
    metadata:
      labels:
        app: payment-api
    spec:
      serviceAccountName: payment-api
      containers:
      - name: app
        image: ghcr.io/fawkes-demo/payment-api:v1.0.0
        ports:
        - containerPort: 8080
---
apiVersion: v1
kind: Service
metadata:
  name: payment-api
  namespace: payments
spec:
  selector:
    app: payment-api
  ports:
  - port: 80
    targetPort: 8080
EOF
```

**Apply authorization policy**:

```bash
kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: payment-api-authz
  namespace: payments
spec:
  selector:
    matchLabels:
      app: payment-api
  action: ALLOW
  rules:
  - from:
    - source:
        principals:
        - "cluster.local/ns/checkout/sa/checkout-service"
    to:
    - operation:
        methods: ["POST"]
        paths: ["/api/v1/charge"]
EOF
```

**Test the policy**:

```bash
# This should FAIL (no valid service account)
kubectl run -it --rm curl-test --image=curlimages/curl --restart=Never -- \
  curl -v http://payment-api.payments.svc.cluster.local/api/v1/charge

# You should see "RBAC: access denied"
```

---

### Exercise 2: Install OPA Gatekeeper and Policies (5 minutes)

**Objective**: Enforce that all pods must have resource limits.

```bash
# Install Gatekeeper
kubectl apply -f https://raw.githubusercontent.com/open-policy-agent/gatekeeper/master/deploy/gatekeeper.yaml

# Wait for Gatekeeper to be ready
kubectl wait --for=condition=ready pod -l control-plane=controller-manager -n gatekeeper-system --timeout=120s
```

**Create a constraint template**:

```bash
kubectl apply -f - <<EOF
apiVersion: templates.gatekeeper.sh/v1
kind: ConstraintTemplate
metadata:
  name: k8srequiredresources
spec:
  crd:
    spec:
      names:
        kind: K8sRequiredResources
  targets:
    - target: admission.k8s.gatekeeper.sh
      rego: |
        package k8srequiredresources

        violation[{"msg": msg}] {
          container := input.review.object.spec.containers[_]
          not container.resources.limits.memory
          msg := sprintf("Container <%v> must specify memory limits", [container.name])
        }

        violation[{"msg": msg}] {
          container := input.review.object.spec.containers[_]
          not container.resources.limits.cpu
          msg := sprintf("Container <%v> must specify CPU limits", [container.name])
        }
EOF
```

**Create the constraint**:

```bash
kubectl apply -f - <<EOF
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: K8sRequiredResources
metadata:
  name: must-have-resource-limits
spec:
  match:
    kinds:
      - apiGroups: ["apps"]
        kinds: ["Deployment"]
    namespaces:
      - "payments"
EOF
```

**Test the policy**:

```bash
# This should FAIL (no resource limits)
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: bad-deployment
  namespace: payments
spec:
  replicas: 1
  selector:
    matchLabels:
      app: bad-app
  template:
    metadata:
      labels:
        app: bad-app
    spec:
      containers:
      - name: nginx
        image: nginx:latest
        # ❌ No resource limits!
EOF

# You should see: "Container <nginx> must specify memory limits"
```

---

### Exercise 3: Sign and Verify Container Images (8 minutes)

**Objective**: Sign an image with Cosign and configure policy to require signatures.

```bash
# Install Cosign
curl -sLO https://github.com/sigstore/cosign/releases/latest/download/cosign-linux-amd64
chmod +x cosign-linux-amd64
sudo mv cosign-linux-amd64 /usr/local/bin/cosign

# Generate a key pair (in production, use keyless signing)
cosign generate-key-pair

# Sign the payment-api image
cosign sign --key cosign.key ghcr.io/fawkes-demo/payment-api:v1.0.0

# Enter password when prompted
```

**Verify the signature**:

```bash
cosign verify --key cosign.pub ghcr.io/fawkes-demo/payment-api:v1.0.0

# You should see "Verification for ghcr.io/fawkes-demo/payment-api:v1.0.0 -- The following checks were performed..."
```

**Install Kyverno for signature verification**:

```bash
helm repo add kyverno https://kyverno.github.io/kyverno/
helm repo update
helm install kyverno kyverno/kyverno -n kyverno --create-namespace
```

**Create a policy to verify signatures**:

```bash
kubectl apply -f - <<EOF
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: verify-image-signature
spec:
  validationFailureAction: enforce
  webhookTimeoutSeconds: 30
  rules:
  - name: verify-signature
    match:
      any:
      - resources:
          kinds:
          - Pod
          namespaces:
          - payments
    verifyImages:
    - imageReferences:
      - "ghcr.io/fawkes-demo/*"
      attestors:
      - count: 1
        entries:
        - keys:
            publicKeys: |-
$(cat cosign.pub | sed 's/^/              /')
EOF
```

**Test the policy**:

```bash
# This should SUCCEED (signed image)
kubectl run signed-pod --image=ghcr.io/fawkes-demo/payment-api:v1.0.0 -n payments

# This should FAIL (unsigned image)
kubectl run unsigned-pod --image=nginx:latest -n payments

# You should see: "resource validation error: image signature verification failed"
```

---

### Exercise 4: Configure External Secrets Operator (7 minutes)

**Objective**: Store secrets in AWS Secrets Manager and sync them to Kubernetes.

```bash
# Install External Secrets Operator
helm repo add external-secrets https://charts.external-secrets.io
helm install external-secrets external-secrets/external-secrets -n external-secrets-system --create-namespace

# For the lab, we'll use a fake backend. In production, configure AWS/GCP/Vault.
```

**Create a SecretStore** (using Kubernetes secrets as backend for demo):

```bash
# Create a secret to act as our "vault"
kubectl create secret generic payment-secrets -n payments \
  --from-literal=stripe-api-key=sk_test_abc123 \
  --from-literal=db-password=super-secret-password

kubectl apply -f - <<EOF
apiVersion: external-secrets.io/v1beta1
kind: SecretStore
metadata:
  name: kubernetes-backend
  namespace: payments
spec:
  provider:
    kubernetes:
      remoteNamespace: payments
      auth:
        serviceAccount:
          name: external-secrets
      server:
        caProvider:
          type: ConfigMap
          name: kube-root-ca.crt
          key: ca.crt
EOF
```

**Create an ExternalSecret**:

```bash
kubectl apply -f - <<EOF
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: payment-api-external-secret
  namespace: payments
spec:
  refreshInterval: 1m
  secretStoreRef:
    name: kubernetes-backend
    kind: SecretStore
  target:
    name: payment-api-secrets
    creationPolicy: Owner
  data:
  - secretKey: STRIPE_API_KEY
    remoteRef:
      key: payment-secrets
      property: stripe-api-key
  - secretKey: DB_PASSWORD
    remoteRef:
      key: payment-secrets
      property: db-password
EOF
```

**Verify the secret was synced**:

```bash
kubectl get externalsecret -n payments
kubectl get secret payment-api-secrets -n payments -o yaml

# You should see STRIPE_API_KEY and DB_PASSWORD
```

**Update deployment to use the external secret**:

```bash
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: payment-api
  namespace: payments
spec:
  replicas: 2
  selector:
    matchLabels:
      app: payment-api
  template:
    metadata:
      labels:
        app: payment-api
    spec:
      serviceAccountName: payment-api
      containers:
      - name: app
        image: ghcr.io/fawkes-demo/payment-api:v1.0.0
        envFrom:
        - secretRef:
            name: payment-api-secrets  # ✅ Synced from external source
        resources:
          limits:
            memory: "256Mi"
            cpu: "500m"
          requests:
            memory: "128Mi"
            cpu: "250m"
EOF
```

---

### Lab Validation

```bash
# Run the validation script
fawkes lab validate --module 19

# You should see:
# ✅ Istio mTLS enabled in payments namespace
# ✅ Authorization policies configured
# ✅ OPA Gatekeeper installed with resource limit policy
# ✅ Image signature verification with Cosign
# ✅ Kyverno policy enforcing signatures
# ✅ External Secrets Operator syncing secrets
```

**Cleanup**:

```bash
fawkes lab stop --module 19
```

---

## ✅ Knowledge Check

Test your understanding with these questions:

### Question 1: Zero Trust Principles

Which of the following is NOT a core principle of zero trust?

A) Never trust, always verify
B) Assume breach
C) Trust based on network location
D) Least privilege access

<details>
<summary>Show Answer</summary>

**Answer: C**

Zero trust explicitly rejects the idea that network location (inside/outside perimeter) should grant trust. All access must be verified regardless of location.

</details>

---

### Question 2: Workload Identity

What is the main advantage of workload identity over long-lived service account keys?

A) Easier to configure
B) Works with more cloud providers
C) Credentials are short-lived and automatically rotated
D) Requires less compute resources

<details>
<summary>Show Answer</summary>

**Answer: C**

Workload identity provides short-lived tokens (typically 1 hour) that are automatically rotated, eliminating the risk of leaked credentials and manual rotation processes.

</details>

---

### Question 3: Service Mesh Security

What does mTLS (mutual TLS) provide that regular TLS does not?

A) Faster encryption
B) Both client and server authenticate each other
C) Compression of network traffic
D) Load balancing capabilities

<details>
<summary>Show Answer</summary>

**Answer: B**

In regular TLS, only the server authenticates to the client. With mTLS, both parties authenticate using certificates, ensuring both ends of the connection are trusted.

</details>

---

### Question 4: Supply Chain Security

Which tool is used to cryptographically sign container images?

A) Trivy
B) Cosign
C) Falco
D) OPA

<details>
<summary>Show Answer</summary>

**Answer: B**

Cosign (part of Sigstore project) is used to sign and verify container images. Trivy is for scanning, Falco for runtime security, and OPA for policy enforcement.

</details>

---

### Question 5: Policy-as-Code

What happens when a Kubernetes admission controller policy is violated?

A) The resource is created with a warning
B) The resource creation is rejected
C) The policy is automatically updated
D) An email is sent to administrators

<details>
<summary>Show Answer</summary>

**Answer: B**

Admission controllers (like Gatekeeper and Kyverno) run before resources are persisted to etcd. If a policy is violated, the API request is rejected and the resource is not created.

</details>

---

### Question 6: Secret Management

Why should secrets never be stored in Git repositories?

A) Git is too slow for secret retrieval
B) Git history is immutable - secrets remain even if deleted
C) Git doesn't support encryption
D) Secrets take up too much storage

<details>
<summary>Show Answer</summary>

**Answer: B**

Git history is permanent. Even if you delete a file containing secrets, they remain in the repository's history and can be retrieved by anyone with access to the repo.

</details>

---

### Question 7: SBOM (Software Bill of Materials)

What is the primary purpose of an SBOM?

A) To compress container images
B) To list all software components and dependencies in an artifact
C) To encrypt network traffic
D) To monitor application performance

<details>
<summary>Show Answer</summary>

**Answer: B**

An SBOM provides a complete inventory of all software components, libraries, and dependencies in an artifact, enabling vulnerability tracking and license compliance.

</details>

---

### Question 8: Zero Trust CI/CD

Which authentication method is recommended for CI/CD pipelines in a zero trust architecture?

A) Storing AWS access keys in GitHub Secrets
B) Using long-lived service account tokens
C) OIDC-based workload identity
D) Username and password authentication

<details>
<summary>Show Answer</summary>

**Answer: C**

OIDC-based workload identity (like GitHub Actions OIDC to AWS) provides short-lived credentials without storing long-lived secrets, aligning with zero trust principles.

</details>

---

## 🌍 Real-World Examples

### Example 1: Netflix's Zero Trust Journey

**Challenge**: Netflix runs on AWS with thousands of microservices. Traditional perimeter security was insufficient.

**Solution**:
- **No VPN**: All services authenticate individually, no network-based trust
- **mTLS everywhere**: Every service-to-service call uses mutual TLS
- **Dynamic authorization**: Zuul gateway enforces fine-grained policies based on user/service identity
- **Credential rotation**: All credentials rotate automatically every few hours

**Result**:
- Eliminated network perimeter as security boundary
- Reduced blast radius of security incidents
- Enabled faster deployment (no VPN bottlenecks)

**Learn more**: [Netflix Security Blog](https://netflixtechblog.com/tagged/security)

---

### Example 2: Google's BeyondCorp

**Challenge**: Employees working remotely needed access to internal applications without VPN.

**Solution** (BeyondCorp):
- **Device trust**: Verify device posture before granting access
- **User identity**: Strong authentication (2FA/U2F keys)
- **Context-aware access**: Consider user, device, location, and resource sensitivity
- **Zero trust proxy**: All access flows through proxy that enforces policy

**Key insight**: "Location is not a proxy for trust"

**Result**:
- Employees work securely from anywhere without VPN
- Reduced attack surface (no broad network access)
- Better visibility into access patterns

**Learn more**: [BeyondCorp Research Papers](https://cloud.google.com/beyondcorp)

---

### Example 3: Capital One Breach (What Went Wrong)

**Incident** (2019): Attacker compromised a web application firewall (WAF), accessed IAM credentials, and exfiltrated data on 100 million customers.

**Root Causes**:
- ❌ **Overly permissive IAM role**: WAF had broad access to S3
- ❌ **No network segmentation**: Compromised WAF could reach production data
- ❌ **Missing detection**: Exfiltration not detected in real-time

**Zero Trust Would Have Prevented This**:
- ✅ **Least privilege**: WAF should not have S3 access
- ✅ **Workload identity**: Short-lived credentials, not long-lived IAM keys
- ✅ **Micro-segmentation**: WAF isolated from data storage layer
- ✅ **Continuous monitoring**: Alert on unusual S3 access patterns

**Lesson**: Assume breach. Design systems so a single compromise doesn't cascade.

---

### Example 4: Shopify's Vault-Backed Secrets

**Challenge**: Thousands of microservices needed secure access to secrets (API keys, database passwords).

**Old approach**:
- Secrets stored in environment variables
- Rotated manually (infrequently)
- Broad access (many services could read all secrets)

**Zero trust approach**:
- **HashiCorp Vault**: Central secret management
- **Dynamic secrets**: Database credentials generated on-demand, expire after use
- **Fine-grained ACLs**: Each service can only access its required secrets
- **Audit logging**: Every secret access logged

**Result**:
- Secrets rotated automatically
- Reduced blast radius (leaked credential only works for one service)
- Complete audit trail for compliance

---

## 📊 DORA Capabilities Mapping

This module directly supports these **DORA capabilities**:

| Capability | How This Module Helps | Impact on Metrics |
|------------|----------------------|-------------------|
| **Shift Left on Security** | Integrate security scanning and policy enforcement early in CI/CD | Reduces change failure rate by catching vulnerabilities before production |
| **Continuous Delivery** | Zero trust enables secure automation without manual approval gates | Improves deployment frequency and lead time |
| **Loosely Coupled Architecture** | Service mesh and mTLS allow secure communication without tight coupling | Enables independent deployment of services |
| **Monitoring & Observability** | Audit all authentication/authorization decisions for compliance | Faster MTTR with clear audit trails |

---

## 🔧 Troubleshooting Common Issues

### Issue 1: Pods Fail to Start After Enabling Strict mTLS

**Symptom**:
```
Error from server: error when creating "deployment.yaml":
admission webhook "validation.gatekeeper.sh" denied the request
```

**Cause**: Pods without Istio sidecar injection cannot communicate when strict mTLS is enabled.

**Solution**:
```bash
# Ensure namespace has Istio injection enabled
kubectl label namespace payments istio-injection=enabled

# Restart pods to inject sidecar
kubectl rollout restart deployment -n payments
```

---

### Issue 2: Image Signature Verification Fails

**Symptom**:
```
Error: image signature verification failed: no matching signatures
```

**Cause**: Image was not signed, or signature verification policy references wrong public key.

**Solution**:
```bash
# Verify the image is signed
cosign verify --key cosign.pub ghcr.io/myorg/app:v1.0.0

# If not signed, sign it
cosign sign --key cosign.key ghcr.io/myorg/app:v1.0.0

# Ensure Kyverno policy references correct public key
kubectl edit clusterpolicy verify-image-signature
```

---

### Issue 3: External Secrets Not Syncing

**Symptom**:
```bash
kubectl get externalsecret
NAME            STORE    REFRESH INTERVAL   STATUS         READY
my-ext-secret   vault    1m                 SecretSyncedError   False
```

**Cause**: External Secrets Operator cannot authenticate to secret backend (Vault/AWS).

**Solution**:
```bash
# Check ExternalSecret status
kubectl describe externalsecret my-ext-secret -n payments

# Verify SecretStore configuration
kubectl describe secretstore -n payments

# For AWS: Ensure service account has correct IAM role annotation
kubectl get sa external-secrets -n payments -o yaml

# For Vault: Verify Kubernetes auth is configured
vault auth list
vault read auth/kubernetes/config
```

---

### Issue 4: OPA Gatekeeper Policies Not Enforcing

**Symptom**: Resources are created despite violating policies.

**Cause**: Constraint may not be applied, or validation failure action is "dryrun".

**Solution**:
```bash
# Check if constraint is created
kubectl get constraints

# Verify constraint status
kubectl describe k8srequiredresources must-have-resource-limits

# Ensure enforcement (not dryrun)
kubectl get k8srequiredresources must-have-resource-limits -o yaml | grep validationFailureAction

# Should show: validationFailureAction: enforce
```

---

### Issue 5: Workload Identity Not Working

**Symptom**: Pods cannot authenticate to cloud provider (AWS/GCP/Azure).

**Cause**: Service account not properly annotated, or OIDC provider not configured.

**Solution for AWS (EKS)**:
```bash
# Verify OIDC provider exists
aws eks describe-cluster --name my-cluster --query "cluster.identity.oidc.issuer"

# Verify service account annotation
kubectl get sa payment-service -n payments -o yaml | grep eks.amazonaws.com/role-arn

# Should show: eks.amazonaws.com/role-arn: arn:aws:iam::123456789:role/payment-service

# Verify IAM role trust policy allows the service account
aws iam get-role --role-name payment-service --query 'Role.AssumeRolePolicyDocument'
```

---

## 📚 Additional Resources

### Official Documentation
- [NIST Zero Trust Architecture](https://www.nist.gov/publications/zero-trust-architecture) - Comprehensive guide to zero trust principles
- [CISA Zero Trust Maturity Model](https://www.cisa.gov/zero-trust-maturity-model) - Framework for assessing zero trust adoption
- [Sigstore Documentation](https://docs.sigstore.dev/) - Software signing and verification
- [SLSA Framework](https://slsa.dev/) - Supply chain security levels

### Tools & Projects
- [Istio Security](https://istio.io/latest/docs/concepts/security/) - Service mesh security
- [OPA Gatekeeper](https://open-policy-agent.github.io/gatekeeper/) - Kubernetes policy enforcement
- [Kyverno](https://kyverno.io/) - Kubernetes-native policy management
- [External Secrets Operator](https://external-secrets.io/) - Sync secrets from external sources
- [Falco](https://falco.org/) - Runtime security monitoring
- [Cosign](https://github.com/sigstore/cosign) - Container image signing

### Books & Papers
- **"Zero Trust Networks"** by Evan Gilman & Doug Barth (O'Reilly)
- **"Kubernetes Security and Observability"** by Brendan Creane & Amit Gupta (O'Reilly)
- **Google's BeyondCorp Papers** - Research on zero trust implementation

### Video Tutorials
- [Securing the Software Supply Chain](https://www.youtube.com/watch?v=VYgN5kGo02w) - KubeCon talk on Sigstore
- [Zero Trust Security in Kubernetes](https://www.youtube.com/watch?v=OP_JBQ1E5qg) - Practical implementation guide

---

## 🎯 Key Takeaways

By completing this module, you've learned:

1. ✅ **Zero trust principles** - Never trust, always verify; assume breach; least privilege
2. ✅ **Workload identity** - Short-lived credentials via OIDC instead of long-lived keys
3. ✅ **Service mesh security** - mTLS and fine-grained authorization with Istio
4. ✅ **Policy-as-code** - Enforce security policies with OPA Gatekeeper and Kyverno
5. ✅ **Supply chain security** - Sign images, generate SBOMs, verify provenance
6. ✅ **Secret management** - External Secrets Operator for centralized secret handling

**Zero trust is not a product, it's an architecture philosophy.** Every component in your platform should:
- Authenticate explicitly (no implicit trust)
- Authorize with least privilege (only what's needed)
- Encrypt all traffic (TLS everywhere)
- Audit all access (comprehensive logging)

---

## 🚀 Next Steps

### In Module 20: Multi-Cloud Strategies

You'll learn how to:
- Design platform architectures that span multiple cloud providers
- Abstract cloud-specific APIs with unified interfaces
- Implement disaster recovery and failover across clouds
- Manage cost optimization in multi-cloud environments
- Navigate the tradeoffs of multi-cloud vs. cloud-agnostic approaches

**Prepare by**:
- Reviewing your organization's cloud provider usage
- Identifying which services are cloud-specific vs. portable
- Considering disaster recovery requirements (RTO/RPO)

---

## 🏆 Black Belt Progress

**Module 19 Complete!** ✅

```
Black Belt Progress:
[████████████████████░░] 75% (3/4 modules)

✅ Module 17: Platform as a Product
✅ Module 18: Multi-Tenancy & Resource Management
✅ Module 19: Security & Zero Trust
⬜ Module 20: Multi-Cloud Strategies

Next: Complete Module 20 to finish Black Belt curriculum!
```

---

## 🎓 Certification Path

After completing all Black Belt modules (17-20), you will:

1. **Complete the Black Belt Assessment** (4 hours):
   - Design a complete platform architecture
   - Present to peer review panel
   - Implement multi-tenant design with zero trust
   - Contribute to Fawkes codebase
   - Mentor 2 White Belt learners

2. **Earn the "Fawkes Platform Architect" Certification**:
   - Demonstrates mastery of platform engineering principles
   - Validates ability to design production-grade platforms
   - Recognized credential in the platform engineering community

**Keep going!** You're one module away from Black Belt! 🥋

---

**Module 19: Security & Zero Trust** | Fawkes Dojo | Black Belt
*"Never trust, always verify"* | Version 1.0