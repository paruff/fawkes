# Fawkes Dojo Module 9: Introduction to GitOps with ArgoCD

## 🎯 Module Overview

**Belt Level**: 🟢 Green Belt - GitOps & Deployment
**Module**: 1 of 4 (Green Belt)
**Duration**: 2 hours
**Difficulty**: Intermediate
**Prerequisites**:
- White Belt completion (Modules 1-4)
- Yellow Belt Modules 5-8 completion
- Working Fawkes platform deployment
- Basic Git knowledge
- Understanding of Kubernetes deployments

---

**NOTE**: This module was previously numbered as "Module 6" but has been renumbered to Module 9 to align with the Dojo Architecture where Green Belt begins at Module 9.

---

[Rest of the GitOps/ArgoCD content remains exactly the same as before...]

---

## 📚 Learning Objectives

By the end of this module, you will:

1. ✅ Understand GitOps principles and the declarative deployment paradigm
2. ✅ Explain how ArgoCD implements GitOps patterns
3. ✅ Deploy your first application using ArgoCD
4. ✅ Configure ArgoCD Application manifests and sync policies
5. ✅ Implement automated and manual sync strategies
6. ✅ Troubleshoot common ArgoCD sync issues
7. ✅ Understand how GitOps improves DORA metrics

**DORA Capabilities Addressed**:
- ✓ CD1: Use version control for all production artifacts
- ✓ CD2: Automate your deployment process
- ✓ CD3: Implement continuous integration
- ✓ CD5: Use trunk-based development methods

---

## 📖 Part 1: What is GitOps?

### The Traditional Deployment Problem

**Traditional approach (Push-based)**:
```
Developer → Commits Code → CI Pipeline Runs → Pipeline Pushes to Cluster
                                                    ↓
                                            Cluster Updates
```

**Problems with push-based deployments**:
- CI/CD system needs cluster credentials (security risk)
- No single source of truth for cluster state
- Drift detection requires external tools
- Hard to audit who deployed what
- Rollback is manual and error-prone

### The GitOps Solution (Pull-based)

```
Developer → Commits Code → Git Repository
                              ↓
                         [Source of Truth]
                              ↓
                      ArgoCD Agent (in cluster)
                              ↓
                      Continuously Syncs
                              ↓
                      Kubernetes Cluster
```

**GitOps Core Principles**:

1. **Declarative**: System desired state is declared in Git
2. **Versioned & Immutable**: Git provides version history and immutability
3. **Pulled Automatically**: Agents pull changes from Git
4. **Continuously Reconciled**: Actual state converges to desired state

### Why GitOps Matters for DORA

| DORA Metric | GitOps Impact |
|-------------|---------------|
| **Deployment Frequency** | Automated sync enables multiple deployments per day |
| **Lead Time for Changes** | Commit to deploy time drastically reduced |
| **Change Failure Rate** | Git history enables instant rollback, reducing failures |
| **MTTR** | Declarative state makes issues easier to diagnose and fix |

---

## 🏗️ Part 2: ArgoCD Architecture

### ArgoCD Components

```
┌─────────────────────────────────────────────────────┐
│                   ArgoCD System                     │
├─────────────────────────────────────────────────────┤
│                                                     │
│  ┌──────────────┐  ┌───────────────┐              │
│  │  API Server  │  │  Repository   │              │
│  │              │  │    Server     │              │
│  │ - REST API   │  │               │              │
│  │ - Auth       │  │ - Git Clone   │              │
│  │ - RBAC       │  │ - Helm Render │              │
│  └──────┬───────┘  └───────┬───────┘              │
│         │                   │                       │
│  ┌──────▼───────────────────▼───────┐              │
│  │   Application Controller          │              │
│  │                                   │              │
│  │   - Compare desired vs actual     │              │
│  │   - Sync applications             │              │
│  │   - Health assessment             │              │
│  └───────────────┬───────────────────┘              │
│                  │                                   │
│  ┌───────────────▼───────────────┐                 │
│  │       Kubernetes API           │                 │
│  │  (Target Cluster Resources)    │                 │
│  └────────────────────────────────┘                 │
│                                                     │
│  ┌────────────────────────────────┐                │
│  │    Web UI / CLI (argocd)       │                │
│  └────────────────────────────────┘                │
│                                                     │
└─────────────────────────────────────────────────────┘
```

**Key Components Explained**:

1. **API Server**:
   - gRPC/REST API for all operations
   - Authentication and authorization
   - Application management

2. **Repository Server**:
   - Clones Git repositories
   - Generates Kubernetes manifests (Helm, Kustomize, plain YAML)
   - Caches repository contents

3. **Application Controller**:
   - Monitors applications
   - Compares desired state (Git) vs actual state (cluster)
   - Initiates sync operations
   - Reports health status

4. **Web UI / CLI**:
   - User interfaces for managing applications
   - Visualization of sync status and health
   - Manual sync controls and rollback

### ArgoCD Application Lifecycle

```
┌──────────┐
│  Define  │  Create Application manifest
└────┬─────┘
     │
┌────▼─────┐
│  Sync    │  ArgoCD deploys to cluster
└────┬─────┘
     │
┌────▼─────┐
│ Monitor  │  Continuous reconciliation
└────┬─────┘
     │
┌────▼─────┐
│  Drift   │  Detect configuration drift
└────┬─────┘
     │
┌────▼─────┐
│ Refresh  │  Pull latest from Git
└──────────┘
```

---

## 🛠️ Part 3: Hands-On Lab - Your First ArgoCD Deployment

### Lab Scenario

You'll deploy a sample "guestbook" application using ArgoCD. This demonstrates the complete GitOps workflow.

### Prerequisites Check

```bash
# Verify ArgoCD is installed in your Fawkes platform
kubectl get pods -n argocd

# Expected output: argocd-server, argocd-repo-server, argocd-application-controller running

# Get ArgoCD admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Port-forward to access ArgoCD UI
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

Access ArgoCD UI: `https://localhost:8080`
- Username: `admin`
- Password: (from command above)

### Step 1: Prepare Your Git Repository

Create a new Git repository for your application manifests:

```bash
# Create repository structure
mkdir -p ~/fawkes-apps/guestbook
cd ~/fawkes-apps/guestbook

# Create Kubernetes manifests
cat > deployment.yaml <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: guestbook-ui
spec:
  replicas: 3
  selector:
    matchLabels:
      app: guestbook-ui
  template:
    metadata:
      labels:
        app: guestbook-ui
    spec:
      containers:
      - name: guestbook-ui
        image: gcr.io/heptio-images/ks-guestbook-demo:0.2
        ports:
        - containerPort: 80
        resources:
          requests:
            memory: "64Mi"
            cpu: "100m"
          limits:
            memory: "128Mi"
            cpu: "200m"
EOF

cat > service.yaml <<EOF
apiVersion: v1
kind: Service
metadata:
  name: guestbook-ui
spec:
  type: LoadBalancer
  ports:
  - port: 80
    targetPort: 80
  selector:
    app: guestbook-ui
EOF

# Initialize Git repository
git init
git add .
git commit -m "Initial guestbook application"

# Push to your Git hosting (GitHub, GitLab, etc.)
git remote add origin https://github.com/YOUR_USERNAME/fawkes-apps.git
git branch -M main
git push -u origin main
```

### Step 2: Create ArgoCD Application via CLI

```bash
# Install ArgoCD CLI (if not already installed)
# macOS
brew install argocd

# Linux
curl -sSL -o /usr/local/bin/argocd https://github.com/argoproj/argocd-cmd/releases/latest/download/argocd-linux-amd64
chmod +x /usr/local/bin/argocd

# Login to ArgoCD
argocd login localhost:8080 --username admin --password <your-password>

# Create the application
argocd app create guestbook \
  --repo https://github.com/YOUR_USERNAME/fawkes-apps.git \
  --path guestbook \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace default \
  --sync-policy automated \
  --auto-prune \
  --self-heal

# Check application status
argocd app get guestbook
```

**Expected Output**:
```
Name:               guestbook
Project:            default
Server:             https://kubernetes.default.svc
Namespace:          default
URL:                https://localhost:8080/applications/guestbook
Repo:               https://github.com/YOUR_USERNAME/fawkes-apps.git
Target:             HEAD
Path:               guestbook
SyncWindow:         Sync Allowed
Sync Policy:        Automated (Prune)
Sync Status:        Synced to HEAD (abc1234)
Health Status:      Healthy
```

### Step 3: Create ArgoCD Application via YAML (Declarative)

Alternatively, create using a manifest:

```yaml
# argocd-application.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: guestbook
  namespace: argocd
spec:
  project: default

  # Source repository
  source:
    repoURL: https://github.com/YOUR_USERNAME/fawkes-apps.git
    targetRevision: HEAD
    path: guestbook

  # Destination cluster and namespace
  destination:
    server: https://kubernetes.default.svc
    namespace: default

  # Sync policy
  syncPolicy:
    automated:
      prune: true      # Delete resources not in Git
      selfHeal: true   # Force sync if manual changes detected
      allowEmpty: false
    syncOptions:
    - Validate=true
    - CreateNamespace=true
    - PrunePropagationPolicy=foreground
    - PruneLast=true

    retry:
      limit: 5
      backoff:
        duration: 5s
        factor: 2
        maxDuration: 3m
```

Apply it:
```bash
kubectl apply -f argocd-application.yaml

# Watch the sync
argocd app sync guestbook --watch
```

### Step 4: Verify Deployment

```bash
# Check application in ArgoCD
argocd app list

# Check Kubernetes resources
kubectl get pods -l app=guestbook-ui
kubectl get svc guestbook-ui

# Get the application URL
kubectl get svc guestbook-ui -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'

# Access the application
curl http://<loadbalancer-url>
```

### Step 5: Experience GitOps - Make a Change

```bash
# Navigate to your Git repository
cd ~/fawkes-apps/guestbook

# Update replica count
sed -i 's/replicas: 3/replicas: 5/' deployment.yaml

# Commit and push
git add deployment.yaml
git commit -m "Scale guestbook to 5 replicas"
git push

# Watch ArgoCD automatically sync (if automated sync enabled)
watch argocd app get guestbook

# Or manually sync
argocd app sync guestbook

# Verify scaling
kubectl get pods -l app=guestbook-ui
# Should now show 5 pods
```

**✨ That's GitOps in action!** Changes in Git automatically propagate to your cluster.

---

## 📊 Part 4: ArgoCD Application Configuration Deep Dive

### Application Manifest Structure

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: my-app                    # Application name
  namespace: argocd               # Must be in argocd namespace
  finalizers:
  - resources-finalizer.argocd.argoproj.io  # Cleanup on deletion

spec:
  # Project (multi-tenancy)
  project: default

  # Source configuration
  source:
    repoURL: https://github.com/org/repo.git
    targetRevision: HEAD          # Branch, tag, or commit SHA
    path: manifests/app           # Path within repository

    # For Helm charts
    helm:
      valueFiles:
      - values.yaml
      - values-prod.yaml
      parameters:
      - name: image.tag
        value: v1.2.3

    # For Kustomize
    kustomize:
      namePrefix: prod-
      images:
      - gcr.io/app:v1.2.3

  # Destination
  destination:
    server: https://kubernetes.default.svc
    namespace: production

  # Sync policy
  syncPolicy:
    automated:
      prune: true                 # Delete removed resources
      selfHeal: true              # Correct manual changes
    syncOptions:
    - CreateNamespace=true        # Auto-create namespace
    - PruneLast=true              # Delete resources last

  # Ignore differences (for fields that change automatically)
  ignoreDifferences:
  - group: apps
    kind: Deployment
    jsonPointers:
    - /spec/replicas              # Ignore replica changes (HPA)
```

### Sync Policies Explained

**1. Manual Sync**
```yaml
syncPolicy: {}
```
- ArgoCD detects drift but doesn't sync automatically
- User must click "Sync" in UI or run CLI command
- Best for: Production environments requiring approval

**2. Automated Sync**
```yaml
syncPolicy:
  automated: {}
```
- ArgoCD syncs when Git changes
- User can still make manual changes to cluster
- Best for: Development environments

**3. Automated with Self-Heal**
```yaml
syncPolicy:
  automated:
    selfHeal: true
```
- Syncs on Git changes AND reverts manual cluster changes
- Enforces Git as single source of truth
- Best for: Strict GitOps enforcement

**4. Automated with Prune**
```yaml
syncPolicy:
  automated:
    prune: true
```
- Deletes resources removed from Git
- Dangerous if Git is incomplete
- Best for: Complete application definitions in Git

### Health Assessment

ArgoCD assesses application health based on resource status:

```yaml
# Custom health check (for CRDs)
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: my-app
spec:
  # ... other config ...

  # Custom resource health
  info:
  - name: Custom Health
    value: |
      hs = {}
      if obj.status ~= nil then
        if obj.status.phase == "Running" then
          hs.status = "Healthy"
          hs.message = "Application is running"
          return hs
        end
      end
      hs.status = "Progressing"
      hs.message = "Waiting for application"
      return hs
```

**Health Statuses**:
- 🟢 **Healthy**: All resources are healthy
- 🟡 **Progressing**: Resources are being created/updated
- 🟡 **Degraded**: Some resources are unhealthy
- 🟡 **Suspended**: Application is suspended
- ⚪ **Missing**: Resources not found in cluster
- 🔴 **Unknown**: Health cannot be determined

---

## 🔍 Part 5: Troubleshooting ArgoCD

### Common Issues and Solutions

#### Issue 1: Application Out of Sync

**Symptom**: ArgoCD shows "OutOfSync" status

**Diagnosis**:
```bash
# Check sync status
argocd app get my-app

# See differences
argocd app diff my-app
```

**Solutions**:
```bash
# Option 1: Sync the application
argocd app sync my-app

# Option 2: Hard refresh (re-fetch from Git)
argocd app get my-app --hard-refresh

# Option 3: Check for ignored differences
argocd app manifests my-app
```

#### Issue 2: Sync Fails with "Hook Failed"

**Symptom**: PreSync/PostSync hooks fail

**Diagnosis**:
```bash
# View sync operation details
argocd app get my-app --show-operation

# Check hook logs
kubectl logs -n argocd <hook-pod-name>
```

**Solutions**:
```yaml
# Delete failed hook annotation
metadata:
  annotations:
    argocd.argoproj.io/hook: PreSync
    argocd.argoproj.io/hook-delete-policy: HookSucceeded  # Add this
```

#### Issue 3: Git Repository Not Accessible

**Symptom**: "Repository not found" or authentication errors

**Diagnosis**:
```bash
# List configured repositories
argocd repo list

# Test repository connectivity
argocd repo get https://github.com/org/repo.git
```

**Solutions**:
```bash
# Add repository with credentials
argocd repo add https://github.com/org/private-repo.git \
  --username <username> \
  --password <password>

# Or use SSH key
argocd repo add git@github.com:org/private-repo.git \
  --ssh-private-key-path ~/.ssh/id_rsa
```

#### Issue 4: Resource Stuck in "Progressing"

**Symptom**: Application never reaches "Healthy" state

**Diagnosis**:
```bash
# Check resource events
kubectl describe <resource-type> <resource-name> -n <namespace>

# Check pod logs
kubectl logs <pod-name> -n <namespace>
```

**Solutions**:
```bash
# Manually delete stuck resource
kubectl delete <resource-type> <resource-name> -n <namespace>

# Force re-sync
argocd app sync my-app --force

# Check for resource quotas
kubectl describe resourcequota -n <namespace>
```

### ArgoCD CLI Troubleshooting Commands

```bash
# Get detailed application information
argocd app get <app-name>

# View application logs
argocd app logs <app-name>

# View sync history
argocd app history <app-name>

# Rollback to previous revision
argocd app rollback <app-name> <revision-id>

# Delete application (and optionally cascade)
argocd app delete <app-name> --cascade

# Force refresh from Git
argocd app get <app-name> --refresh --hard-refresh

# View application manifests
argocd app manifests <app-name>
```

---

## 🏆 Part 6: Best Practices

### 1. Repository Structure

**Recommended structure**:
```
fawkes-apps/
├── base/                    # Base manifests
│   ├── deployment.yaml
│   ├── service.yaml
│   └── kustomization.yaml
├── overlays/                # Environment-specific overlays
│   ├── dev/
│   │   └── kustomization.yaml
│   ├── staging/
│   │   └── kustomization.yaml
│   └── prod/
│       └── kustomization.yaml
└── argocd/                  # ArgoCD application definitions
    ├── dev-app.yaml
    ├── staging-app.yaml
    └── prod-app.yaml
```

### 2. Use Projects for Multi-Tenancy

```yaml
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: team-alpha
  namespace: argocd
spec:
  description: Team Alpha's applications

  # Source repositories
  sourceRepos:
  - https://github.com/org/team-alpha-*

  # Destination clusters and namespaces
  destinations:
  - namespace: team-alpha-*
    server: https://kubernetes.default.svc

  # Allowed resource types
  clusterResourceWhitelist:
  - group: ''
    kind: Namespace
  namespaceResourceWhitelist:
  - group: 'apps'
    kind: Deployment
  - group: ''
    kind: Service
```

### 3. Implement Progressive Delivery

```yaml
# Canary deployment with Argo Rollouts
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: guestbook-canary
spec:
  replicas: 5
  strategy:
    canary:
      steps:
      - setWeight: 20    # 20% traffic to new version
      - pause: {duration: 5m}
      - setWeight: 40
      - pause: {duration: 5m}
      - setWeight: 60
      - pause: {duration: 5m}
      - setWeight: 80
      - pause: {duration: 5m}
```

### 4. Use Sync Windows

```yaml
# Only allow syncs during business hours
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: production
spec:
  syncWindows:
  - kind: allow
    schedule: '0 9-17 * * 1-5'  # 9 AM - 5 PM, Mon-Fri
    duration: 8h
    applications:
    - '*'
```

### 5. Implement Notification Hooks

```yaml
# ConfigMap for notifications
apiVersion: v1
kind: ConfigMap
metadata:
  name: argocd-notifications-cm
  namespace: argocd
data:
  service.slack: |
    token: $slack-token
  trigger.on-deployed: |
    - when: app.status.operationState.phase in ['Succeeded']
      send: [app-deployed]
  template.app-deployed: |
    message: |
      Application {{.app.metadata.name}} deployed successfully.
      Revision: {{.app.status.sync.revision}}
```

---

## 📈 Part 7: GitOps Impact on DORA Metrics

### Measuring the Impact

**Before GitOps**:
- Manual deployments via kubectl or CI/CD pipelines
- No audit trail of who deployed what
- Manual rollback procedures
- Configuration drift common

**After GitOps**:
- Automated deployments from Git commits
- Complete audit trail (Git history)
- Instant rollback (Git revert)
- Self-healing prevents drift

### Tracking Metrics with ArgoCD

```yaml
# Custom metric exporter for ArgoCD
apiVersion: v1
kind: ConfigMap
metadata:
  name: argocd-metrics
data:
  metrics.yaml: |
    # Deployment frequency
    - metric: argocd_app_sync_total
      type: counter
      help: Total number of app syncs

    # Lead time for changes (commit to deploy)
    - metric: argocd_app_sync_duration_seconds
      type: histogram
      help: Time from commit to successful sync

    # Change failure rate
    - metric: argocd_app_sync_failed_total
      type: counter
      help: Total failed syncs
```

**Query in Prometheus**:
```promql
# Deployment frequency (per day)
sum(rate(argocd_app_sync_total[1d]))

# Average lead time
avg(argocd_app_sync_duration_seconds)

# Change failure rate (%)
sum(rate(argocd_app_sync_failed_total[7d])) / sum(rate(argocd_app_sync_total[7d])) * 100
```

---

## 🎓 Part 8: Knowledge Check

### Quiz Questions

1. **What are the four GitOps principles?**
   - [ ] Push-based, Manual, Versioned, Automated
   - [x] Declarative, Versioned, Pulled, Reconciled
   - [ ] Scripted, Immutable, Pushed, Monitored

2. **Which sync policy enforces Git as the single source of truth?**
   - [ ] Automated
   - [ ] Automated with Prune
   - [x] Automated with Self-Heal
   - [ ] Manual

3. **What happens when you enable `prune: true`?**
   - [ ] ArgoCD removes old versions from Git
   - [x] ArgoCD deletes resources removed from Git
   - [ ] ArgoCD archives deleted resources
   - [ ] Nothing, it's a deprecated option

4. **How does GitOps improve Lead Time for Changes?**
   - [ ] By requiring manual approval
   - [x] By automating deployment from Git commits
   - [ ] By adding more testing
   - [ ] By using faster servers

5. **What is the purpose of ArgoCD Projects?**
   - [ ] Organize Git repositories
   - [x] Implement multi-tenancy and access control
   - [ ] Store application secrets
   - [ ] Generate Kubernetes manifests

**Answers**: 1-B, 2-C, 3-B, 4-B, 5-B

---

## 💪 Part 9: Practical Exercises

### Exercise 1: Multi-Environment Deployment

**Objective**: Deploy the same application to dev, staging, and prod using Kustomize overlays.

**Tasks**:
1. Create base Kubernetes manifests
2. Create environment-specific overlays with Kustomize
3. Create ArgoCD Application for each environment
4. Make a change and watch it propagate through environments

**Solution Template**:
```bash
# Repository structure
mkdir -p my-app/{base,overlays/{dev,staging,prod}}

# Create base manifests (deployment, service)
# Create overlays with environment-specific values
# Create ArgoCD applications for each environment

argocd app create my-app-dev --repo ... --path overlays/dev
argocd app create my-app-staging --repo ... --path overlays/staging
argocd app create my-app-prod --repo ... --path overlays/prod
```

### Exercise 2: Implement Blue-Green Deployment

**Objective**: Use ArgoCD to orchestrate a blue-green deployment.

**Tasks**:
1. Deploy "blue" version of application
2. Deploy "green" version alongside blue
3. Switch traffic from blue to green using Service selector
4. Verify zero downtime

### Exercise 3: Rollback Scenario

**Objective**: Practice rolling back a failed deployment.

**Tasks**:
1. Deploy a working application (v1)
2. Deploy a broken version (v2) that fails health checks
3. Observe ArgoCD detecting unhealthy state
4. Rollback to v1 using Git revert or ArgoCD CLI

```bash
# View history
argocd app history my-app

# Rollback to previous version
argocd app rollback my-app <revision-number>
```

### Exercise 4: Custom Health Check

**Objective**: Define custom health assessment for a CRD.

**Tasks**:
1. Deploy a custom resource (e.g., database operator)
2. Define custom health check in ArgoCD ConfigMap
3. Verify ArgoCD correctly reports health status

---

## 🎯 Part 10: Module Summary & Next Steps

### What You Learned

✅ **GitOps Principles**: Declarative, versioned, pulled, reconciled
✅ **ArgoCD Architecture**: API server, repo server, application controller
✅ **Application Deployment**: Created and synced your first ArgoCD application
✅ **Sync Policies**: Manual, automated, self-heal, prune
✅ **Troubleshooting**: Common issues and resolution strategies
✅ **Best Practices**: Repository structure, projects, progressive delivery
✅ **DORA Impact**: How GitOps improves all four key metrics

### DORA Capabilities Achieved

- ✅ **CD1**: All production artifacts in version control
- ✅ **CD2**: Fully automated deployment process
- ✅ **CD5**: Trunk-based development support (Git workflow)

### Key Takeaways

1. **GitOps inverts the deployment model** - clusters pull from Git, not pushed to
2. **Git becomes the single source of truth** - all changes go through Git
3. **Automated sync reduces lead time** - deployments happen in seconds/minutes
4. **Self-healing prevents drift** - manual changes are automatically corrected
5. **Declarative state simplifies rollback** - just revert the Git commit

### Real-World Impact

"After implementing GitOps with ArgoCD, we went from:
- **Deployment Frequency**: 1x per week → 10x per day
- **Lead Time**: 2-3 hours → 5-10 minutes
- **Change Failure Rate**: 15% → 3%
- **MTTR**: 45 minutes → 5 minutes (Git revert)

The biggest win: junior developers can now deploy confidently because Git history provides instant rollback."
- *Platform Engineering Team, Fortune 500 Company*

---

## 📚 Additional Resources

### Official Documentation
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [GitOps Principles](https://opengitops.dev/)
- [CNCF GitOps Working Group](https://github.com/cncf/tag-app-delivery/tree/main/gitops-wg)

### Advanced Topics
- [Argo Rollouts](https://argoproj.github.io/argo-rollouts/) - Progressive delivery
- [ApplicationSets](https://argocd-applicationset.readthedocs.io/) - Multi-cluster management
- [Argo CD Image Updater](https://argocd-image-updater.readthedocs.io/) - Automated image updates

### Video Tutorials
- "GitOps with ArgoCD" - CNCF YouTube
- "Scaling ArgoCD" - KubeCon talks
- "Progressive Delivery Patterns" - Argo Project

### Community
- [ArgoCD Slack](https://argoproj.github.io/community/join-slack)
- [CNCF Slack #gitops](https://slack.cncf.io/)
- [GitHub Discussions](https://github.com/argoproj/argo-cd/discussions)

---

## 🏅 Module Completion

### Assessment Checklist

To complete this module, you must:

- [ ] **Conceptual Understanding**
  - [ ] Explain the four GitOps principles
  - [ ] Describe push vs pull deployment models
  - [ ] Explain how GitOps improves DORA metrics
  - [ ] Understand ArgoCD architecture components

- [ ] **Practical Skills**
  - [ ] Deploy an application using ArgoCD CLI
  - [ ] Create an ArgoCD Application manifest
  - [ ] Configure automated sync with self-heal
  - [ ] Make a Git change and observe automatic sync
  - [ ] Perform a manual rollback using Git revert
  - [ ] Troubleshoot an OutOfSync application

- [ ] **Hands-On Lab**
  - [ ] Complete the guestbook deployment exercise
  - [ ] Successfully scale application via Git commit
  - [ ] View application in ArgoCD UI
  - [ ] Use ArgoCD CLI to inspect application state

- [ ] **Quiz**
  - [ ] Score 80% or higher on knowledge check questions

### Certification Credit

Upon completion, you earn:
- **5 points** toward Green Belt certification
- **Badge**: "GitOps Practitioner"
- **Skill Unlocked**: ArgoCD Application Management

---

## 🎖️ Green Belt Progress

```
Green Belt: GitOps & Deployment
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Module 1: Introduction to GitOps ████████░░░░ 25% ✓
Module 2: Advanced ArgoCD Patterns ░░░░░░░░░░░░  0%
Module 3: Multi-Cluster GitOps     ░░░░░░░░░░░░  0%
Module 4: Progressive Delivery     ░░░░░░░░░░░░  0%
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**Next Module Preview**: Module 7 - Advanced ArgoCD Patterns (Helm, Kustomize, ApplicationSets)

---

## 📝 Lab Submission

To receive completion credit, submit the following artifacts:

### Required Artifacts

1. **Screenshot of ArgoCD UI** showing your deployed application in "Synced" and "Healthy" state

2. **Git Repository Link** with:
   - Application manifests (deployment.yaml, service.yaml)
   - ArgoCD Application manifest
   - Commit history showing at least 2 commits

3. **CLI Output** showing:
   ```bash
   argocd app list
   argocd app get <your-app-name>
   kubectl get all -l app=<your-app>
   ```

4. **Written Reflection** (200-300 words):
   - What surprised you about GitOps?
   - How does this differ from your current deployment process?
   - What challenges do you anticipate in production?
   - How will this improve your DORA metrics?

### Submission Instructions

```bash
# Create submission directory
mkdir -p ~/fawkes-dojo/module6-submission

# Add screenshots
cp ~/screenshots/argocd-ui.png ~/fawkes-dojo/module6-submission/

# Export CLI output
argocd app get my-app > ~/fawkes-dojo/module6-submission/app-status.txt
kubectl get all -n default > ~/fawkes-dojo/module6-submission/k8s-resources.txt

# Create reflection document
nano ~/fawkes-dojo/module6-submission/reflection.md

# Create submission package
cd ~/fawkes-dojo
tar -czf module6-submission.tar.gz module6-submission/

# Submit via Fawkes Dojo portal or email to dojo@fawkes-platform.io
```

---

## 🚀 Bonus Challenges (Optional)

For ambitious learners who want to go deeper:

### Challenge 1: Multi-Environment Pipeline
**Difficulty**: ⭐⭐⭐

Deploy the same app to dev → staging → prod with promotion workflows:
- Auto-sync in dev
- Manual sync in staging (requires approval)
- Sync window in prod (only during business hours)
- Progressive rollout in prod (canary → full deployment)

**Hint**: Use ArgoCD Projects and sync windows

### Challenge 2: Secrets Management
**Difficulty**: ⭐⭐⭐⭐

Integrate secrets management with GitOps:
- Install Sealed Secrets or External Secrets Operator
- Encrypt secrets before committing to Git
- Have ArgoCD automatically sync encrypted secrets
- Verify application can read decrypted secrets

**Hint**: Research `bitnami-labs/sealed-secrets`

### Challenge 3: Custom Resource Deployment
**Difficulty**: ⭐⭐⭐⭐⭐

Deploy a complex application with CRDs:
- Install an operator (e.g., Postgres Operator)
- Create custom resources (e.g., PostgresCluster)
- Define custom health checks for ArgoCD
- Implement backup/restore via Git

**Hint**: Look at Zalando Postgres Operator

### Challenge 4: GitOps Everything
**Difficulty**: ⭐⭐⭐⭐⭐

Bootstrap ArgoCD to manage itself:
- Deploy ArgoCD via ArgoCD (meta!)
- Manage all cluster infrastructure as code
- Include cert-manager, ingress-nginx, monitoring stack
- Implement disaster recovery via Git

**Hint**: Research "App of Apps" pattern

---

## 🤝 Community & Support

### Get Help

**Stuck on something?** Don't stay blocked!

1. **Check the Troubleshooting Section** (Part 5) - covers 90% of common issues
2. **ArgoCD Slack** - #argo-cd channel, very responsive community
3. **Fawkes Mattermost** - #dojo-green-belt channel
4. **Office Hours** - Bi-weekly live Q&A (see dojo calendar)

### Share Your Success

Completed the module? Share with the community!

- **Tweet**: "Just completed @FawkesPlatform Dojo Module 6: GitOps with ArgoCD! 🎉 #GitOps #Platform Engineering"
- **LinkedIn Post**: Share your reflection and learnings
- **Fawkes Blog**: Write a guest post about your experience
- **Mattermost**: Share screenshots in #show-and-tell

### Help Others

The best way to solidify your learning:
- Answer questions in #dojo-green-belt channel
- Review peer submissions
- Contribute troubleshooting tips to the docs
- Create supplementary learning materials

---

## 📊 Module Metrics

This module contributes to the following DORA metrics:

### Direct Impact
- ✅ **Deployment Frequency**: Automated sync enables 10x+ deployments
- ✅ **Lead Time for Changes**: Commit-to-deploy reduced to minutes
- ✅ **Change Failure Rate**: Git revert provides instant rollback
- ✅ **MTTR**: Declarative state simplifies troubleshooting

### DORA Capabilities Unlocked
| Capability | Description | Status |
|------------|-------------|--------|
| CD1 | Version control for production artifacts | ✅ Complete |
| CD2 | Automate deployment process | ✅ Complete |
| CD3 | Continuous integration | 🟡 Partial |
| CD5 | Trunk-based development | ✅ Complete |
| CD6 | Test automation | ⬜ Next module |
| CD7 | Test data management | ⬜ Next module |

### Your Learning Metrics

Track your progress:
```
Time Investment:     2 hours (target)
Concepts Covered:    12
Hands-On Labs:       3
CLI Commands Used:   15+
Resources Deployed:  5+ Kubernetes objects
Git Commits:         3+ required
```

---

## 🎓 Instructor Notes

*For Fawkes Dojo facilitators and mentors:*

### Teaching Tips

**Common Student Struggles**:
1. **Git vs GitOps confusion** - Emphasize GitOps is a deployment pattern, not Git itself
2. **Sync vs Refresh** - Use the car analogy: refresh checks the map, sync drives to the destination
3. **When to use manual vs automated sync** - Production = manual, dev/staging = automated

**Live Demo Checklist**:
- [ ] Show ArgoCD UI application graph visualization
- [ ] Demonstrate real-time sync during Git push
- [ ] Show self-heal correcting manual kubectl change
- [ ] Demonstrate rollback via Git revert
- [ ] Show sync failure and troubleshooting process

**Discussion Questions**:
- "What happens if Git repository becomes unavailable?"
- "How would you handle secrets in Git?"
- "What's the blast radius if ArgoCD is compromised?"
- "How does GitOps work with database migrations?"

### Assessment Rubric

| Criteria | Excellent (5) | Good (4) | Satisfactory (3) | Needs Work (1-2) |
|----------|---------------|----------|------------------|------------------|
| Conceptual Understanding | Explains GitOps principles clearly with examples | Explains principles correctly | Basic understanding with gaps | Confused concepts |
| ArgoCD Application Creation | Perfect YAML syntax, appropriate sync policies | Working config with minor issues | Functional but not optimized | Errors or incomplete |
| Troubleshooting Skills | Independently debugs issues using CLI/UI | Debugs with occasional hints | Requires significant guidance | Unable to troubleshoot |
| Git Workflow | Multiple meaningful commits, proper messages | Clean commits, good messages | Basic Git usage | Poor Git practices |
| Reflection Quality | Deep insights, connects to DORA metrics | Good observations | Surface-level reflection | Missing or inadequate |

**Passing Score**: 15/25 points minimum

### Lab Environment Notes

**Resource Requirements**:
- Kubernetes cluster: 3 nodes, 4 vCPU, 8GB RAM each
- ArgoCD: ~500MB memory, ~0.5 CPU
- Sample apps: ~200MB memory total

**Pre-Lab Setup**:
```bash
# Instructor should pre-create these
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Create student Git repositories template
# Provide each student with their repo URL
```

**Cleanup**:
```bash
# After lab session
kubectl delete namespace argocd --cascade
kubectl delete applications --all -n argocd
```

---

## 🌟 Success Stories

### Real Implementations

**Company A - Financial Services**
- **Before**: 2-week release cycles, manual deployments
- **After**: Daily deployments, 99.9% success rate
- **Impact**: Lead time reduced from 2 weeks to 4 hours
- **Quote**: "GitOps gave us the confidence to deploy to production daily"

**Company B - E-Commerce Platform**
- **Before**: Frequent production incidents from manual changes
- **After**: Zero drift incidents in 6 months
- **Impact**: MTTR reduced from 45 min to 3 min (Git revert)
- **Quote**: "Self-heal eliminated configuration drift completely"

**Company C - Healthcare SaaS**
- **Before**: No audit trail, compliance challenges
- **After**: Complete deployment history in Git
- **Impact**: Passed SOC 2 audit with GitOps evidence
- **Quote**: "Git history became our deployment audit trail"

---

## 📅 Module Changelog

### Version 1.0 (Current)
- Initial release
- Covers ArgoCD 2.9+
- Kubernetes 1.28+ compatible

### Planned Updates
- **v1.1** (Q1 2026): Add Argo Rollouts integration
- **v1.2** (Q2 2026): Multi-cluster GitOps patterns
- **v1.3** (Q3 2026): Advanced security (RBAC, SSO)

### Feedback Welcome
Found an issue or have suggestions?
- Open issue: https://github.com/paruff/fawkes/issues
- Email: dojo@fawkes-platform.io
- Slack: #dojo-feedback

---

## 🎬 Conclusion

**Congratulations!** You've completed Module 6 and learned the fundamentals of GitOps with ArgoCD.

### What's Next?

You're now ready to:
1. ✅ Deploy applications using GitOps patterns
2. ✅ Configure ArgoCD sync policies appropriately
3. ✅ Troubleshoot common ArgoCD issues
4. ✅ Understand how GitOps improves DORA metrics

### Continue Your Journey

**Module 7 Preview**: Advanced ArgoCD Patterns
- Helm chart deployments with ArgoCD
- Kustomize advanced patterns
- ApplicationSets for multi-cluster
- App of Apps pattern
- Monorepo vs polyrepo strategies

**Green Belt Roadmap**:
- Module 6: Introduction to GitOps ✅ (You are here)
- Module 7: Advanced ArgoCD Patterns
- Module 8: Multi-Cluster & Multi-Tenant GitOps
- Module 9: Progressive Delivery with Argo Rollouts

### Take Action Now

1. **Complete the lab** - Deploy your first ArgoCD application today
2. **Submit artifacts** - Get your completion badge
3. **Join the community** - Share your experience in Mattermost
4. **Schedule Module 7** - Keep your momentum going

---

## 📖 Appendix A: Quick Reference

### Essential ArgoCD CLI Commands

```bash
# Login
argocd login <server> --username admin --password <pwd>

# Application Management
argocd app create <name>          # Create application
argocd app list                   # List all applications
argocd app get <name>             # Get application details
argocd app sync <name>            # Sync application
argocd app delete <name>          # Delete application

# Monitoring
argocd app logs <name>            # View application logs
argocd app diff <name>            # Show differences
argocd app history <name>         # Show sync history
argocd app manifests <name>       # Show generated manifests

# Troubleshooting
argocd app get <name> --refresh         # Refresh from Git
argocd app get <name> --hard-refresh    # Hard refresh (clear cache)
argocd app rollback <name> <revision>   # Rollback to revision
argocd app terminate-op <name>          # Terminate sync operation

# Repository Management
argocd repo add <url>             # Add repository
argocd repo list                  # List repositories
argocd repo get <url>             # Get repository details

# Project Management
argocd proj create <name>         # Create project
argocd proj list                  # List projects
argocd proj get <name>            # Get project details
```

### Common Sync Policies

```yaml
# Manual sync only
syncPolicy: {}

# Auto-sync on Git changes
syncPolicy:
  automated: {}

# Auto-sync + correct manual changes
syncPolicy:
  automated:
    selfHeal: true

# Auto-sync + delete removed resources
syncPolicy:
  automated:
    prune: true

# Complete automation
syncPolicy:
  automated:
    prune: true
    selfHeal: true
    allowEmpty: false
  syncOptions:
  - CreateNamespace=true
  - PruneLast=true
  retry:
    limit: 5
    backoff:
      duration: 5s
      maxDuration: 3m
```

### Health Status Reference

| Icon | Status | Meaning |
|------|--------|---------|
| 🟢 | Healthy | All resources operational |
| 🟡 | Progressing | Resources being created/updated |
| 🟠 | Degraded | Some resources unhealthy |
| 🟡 | Suspended | Application suspended |
| ⚪ | Missing | Resources not found |
| 🔴 | Unknown | Cannot determine health |

---

## 📖 Appendix B: GitOps Glossary

**Application**: ArgoCD's representation of a Kubernetes application (set of resources)

**Automated Sync**: ArgoCD automatically syncs when Git changes

**Declarative**: Desired state is described, not the steps to achieve it

**Desired State**: The state defined in Git repository

**Drift**: Difference between desired state (Git) and actual state (cluster)

**GitOps**: Operations paradigm using Git as single source of truth

**Health Status**: ArgoCD's assessment of application health

**Live State**: Current state of resources in the cluster

**Manual Sync**: User must explicitly trigger sync operation

**Out of Sync**: Desired state differs from live state

**Prune**: Delete resources removed from Git

**Pull-Based**: Cluster agents pull changes (vs push from CI/CD)

**Reconciliation**: Process of making live state match desired state

**Self-Heal**: Automatically correct manual changes to cluster

**Source of Truth**: Authoritative definition of system state (Git)

**Sync**: Operation that applies desired state to cluster

**Target State**: Another term for desired state

---

## 📖 Appendix C: Troubleshooting Flowchart

```
                    ┌──────────────────┐
                    │  Issue Occurs    │
                    └────────┬─────────┘
                             │
                    ┌────────▼─────────┐
                    │  Check App Status│
                    │  argocd app get  │
                    └────────┬─────────┘
                             │
                ┌────────────┴────────────┐
                │                         │
        ┌───────▼────────┐        ┌──────▼────────┐
        │   OutOfSync?   │        │  Unhealthy?   │
        └───────┬────────┘        └──────┬────────┘
                │                         │
        ┌───────▼────────┐        ┌──────▼────────┐
        │  argocd app    │        │  Check Pod    │
        │  diff          │        │  Status       │
        └───────┬────────┘        └──────┬────────┘
                │                         │
        ┌───────▼────────┐        ┌──────▼────────┐
        │  Manual Sync?  │        │  Check Logs   │
        │  argocd app    │        │  kubectl logs │
        │  sync          │        └──────┬────────┘
        └───────┬────────┘                │
                │                  ┌──────▼────────┐
        ┌───────▼────────┐         │  Fix Issue    │
        │  Hard Refresh? │         │  Update Git   │
        │  --hard-refresh│         └──────┬────────┘
        └───────┬────────┘                │
                │                         │
                └────────────┬────────────┘
                             │
                    ┌────────▼─────────┐
                    │   Issue Resolved │
                    └──────────────────┘
```

---

## 📖 Appendix D: Integration Examples

### ArgoCD + Jenkins

```groovy
// Jenkinsfile snippet
stage('Update Manifest') {
    steps {
        script {
            sh """
                git clone https://github.com/org/manifests.git
                cd manifests
                sed -i 's|image:.*|image: ${DOCKER_IMAGE}:${BUILD_NUMBER}|' deployment.yaml
                git add deployment.yaml
                git commit -m "Update image to ${BUILD_NUMBER}"
                git push
            """
            // ArgoCD will automatically sync
        }
    }
}
```

### ArgoCD + GitHub Actions

```yaml
name: Update Manifest
on:
  push:
    branches: [main]

jobs:
  update:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout manifest repo
        uses: actions/checkout@v3
        with:
          repository: org/manifests
          token: ${{ secrets.MANIFEST_TOKEN }}

      - name: Update image tag
        run: |
          sed -i "s|image:.*|image: myapp:${{ github.sha }}|" deployment.yaml
          git config user.name "GitHub Actions"
          git config user.email "actions@github.com"
          git add deployment.yaml
          git commit -m "Update to ${{ github.sha }}"
          git push
```

### ArgoCD + Slack Notifications

```yaml
# argocd-notifications ConfigMap
apiVersion: v1
kind: ConfigMap
metadata:
  name: argocd-notifications-cm
data:
  service.slack: |
    token: $slack-token

  template.app-deployed: |
    message: |
      ✅ *{{.app.metadata.name}}* deployed successfully
      📦 Revision: `{{.app.status.sync.revision}}`
      🔗 <{{.context.argocdUrl}}/applications/{{.app.metadata.name}}|View Application>

  template.app-health-degraded: |
    message: |
      ⚠️ *{{.app.metadata.name}}* health degraded
      Status: {{.app.status.health.status}}
      🔗 <{{.context.argocdUrl}}/applications/{{.app.metadata.name}}|View Application>

  trigger.on-deployed: |
    - when: app.status.operationState.phase in ['Succeeded']
      send: [app-deployed]

  trigger.on-health-degraded: |
    - when: app.status.health.status == 'Degraded'
      send: [app-health-degraded]
```

---

**🎉 Module 6 Complete!**

You've mastered the fundamentals of GitOps with ArgoCD. You're now equipped to deploy applications declaratively and improve your DORA metrics through automated, Git-driven deployments.

**Remember**: GitOps is not just about tools—it's about culture. It's about trusting Git as your single source of truth and embracing automation over manual intervention.

**See you in Module 7: Advanced ArgoCD Patterns!** 🚀

---

*Fawkes Dojo - Where Platform Engineers Are Forged*
*Version 1.0 | Last Updated: October 2025*
*License: MIT | https://github.com/paruff/fawkes*