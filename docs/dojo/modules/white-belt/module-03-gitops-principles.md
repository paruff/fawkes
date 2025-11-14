# Module 3: GitOps Principles

**Belt Level**: 🥋 White Belt
**Duration**: 60 minutes
**Prerequisites**: Module 1 & 2 completed, Git basics
**Learning Path**: Module 3 of 20 (White Belt: Modules 1-4)

---

## 📋 Module Overview

GitOps is a revolutionary approach to infrastructure and application deployment. Instead of running commands to make changes, you declare your desired state in Git, and automation ensures reality matches that declaration. This module teaches you the principles, benefits, and practices of GitOps.

### Learning Objectives

By completing this module, you will be able to:

1. **Define** GitOps and explain its core principles
2. **Differentiate** between push-based and pull-based deployment models
3. **Describe** how Git becomes the single source of truth for infrastructure
4. **Explain** the benefits of GitOps for DORA metrics and reliability
5. **Navigate** the Fawkes GitOps repository structure
6. **Make** a GitOps-driven deployment change in the hands-on lab

### Why This Matters

GitOps is a fundamental practice in modern platform engineering:
- **Netflix** deploys 1000+ times per day using GitOps
- **Weaveworks** reported 2x faster deployments with GitOps
- **DORA research** shows GitOps directly improves all four key metrics
- **90% of cloud-native teams** use or plan to use GitOps (CNCF Survey 2024)

Understanding GitOps is essential for elite delivery performance.

---

## 📚 Section 1: The GitOps Paradigm (15 minutes)

### The Traditional Way: Imperative Operations

**Before GitOps**, deployments were imperative (manual commands):

```bash
# Deployment by running commands
kubectl apply -f deployment.yaml
kubectl set image deployment/myapp myapp=v2.0
kubectl scale deployment/myapp --replicas=5
helm upgrade myapp ./chart --set image.tag=v2.0
terraform apply
```

**Problems**:
- ❌ **No audit trail** - Who made what change, when, and why?
- ❌ **Configuration drift** - Production differs from documented state
- ❌ **No rollback** - Can't easily revert to previous working state
- ❌ **Knowledge silos** - Only certain people know how to deploy
- ❌ **Error-prone** - Manual commands = human mistakes
- ❌ **No code review** - Infrastructure changes not peer-reviewed

### The GitOps Way: Declarative State

**With GitOps**, you declare desired state in Git:

```yaml
# In Git repository: apps/prod/myapp/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
spec:
  replicas: 5
  template:
    spec:
      containers:
      - name: myapp
        image: myapp:v2.0
```

**GitOps operator** (like ArgoCD) continuously:
1. **Watches Git** for changes
2. **Compares** Git state with cluster state
3. **Applies** differences automatically
4. **Heals** any manual changes (self-healing)

**Benefits**:
- ✅ **Complete audit trail** - Every change is a Git commit
- ✅ **No drift** - System automatically returns to Git state
- ✅ **Easy rollback** - `git revert` restores previous state
- ✅ **Knowledge sharing** - Git repository documents everything
- ✅ **Reliable** - Automation eliminates human error
- ✅ **Code review** - All changes via pull requests

### Four Principles of GitOps

The **OpenGitOps** working group defines four core principles:

#### 1. Declarative

**Definition**: System's desired state is expressed declaratively (what, not how).

**Example**:
```yaml
# Declarative (GitOps) - Describe WHAT you want
replicas: 5
image: myapp:v2.0

# vs. Imperative - Describe HOW to achieve it
kubectl scale --replicas=5
kubectl set image deployment/myapp myapp=v2.0
```

**Why it matters**: Declarative is idempotent (run multiple times = same result), easier to understand, and automation-friendly.

#### 2. Versioned and Immutable

**Definition**: Desired state is stored in Git, providing version history and immutability.

**Benefits**:
- Every change has a commit SHA (immutable reference)
- Full history of who changed what, when, and why
- Easy to see what production looked like at any point in time
- Rollback is just a `git revert`

**Example**:
```bash
# View deployment history
git log apps/prod/myapp/deployment.yaml

# See what changed
git diff HEAD~1 apps/prod/myapp/deployment.yaml

# Rollback to previous version
git revert HEAD
```

#### 3. Pulled Automatically

**Definition**: Software agents automatically pull desired state from Git (not pushed).

**Pull Model** (GitOps):
```
Git Repository (source of truth)
        ↑
        │ Pull changes
        │ (every 3 minutes)
        │
    GitOps Agent (ArgoCD)
        │
        ↓ Apply to cluster
        │
    Kubernetes Cluster
```

**Push Model** (Traditional CI/CD):
```
CI/CD System (Jenkins)
        │
        ↓ Push changes
        │ (when triggered)
        │
    Kubernetes Cluster
```

**Why Pull is Better**:
- ✅ **More secure** - Cluster credentials not in CI/CD system
- ✅ **Self-healing** - Detects and corrects drift automatically
- ✅ **Better failure handling** - Retries automatically
- ✅ **Audit trail** - All changes go through Git (no backdoors)

#### 4. Continuously Reconciled

**Definition**: Software agents continuously ensure actual state matches desired state.

**Reconciliation Loop**:
```
1. Fetch desired state from Git
2. Compare with actual state in cluster
3. If different, apply changes
4. Wait (e.g., 3 minutes)
5. Repeat from step 1
```

**Self-Healing Example**:
```bash
# Someone manually changes replicas
kubectl scale deployment/myapp --replicas=10

# Within 3 minutes, GitOps operator detects drift
# and reverts to Git-declared state (5 replicas)
```

**Benefits**:
- Prevents configuration drift
- Recovers from manual mistakes automatically
- Ensures production always matches Git
- Reduces operational toil

---

## 📚 Section 2: GitOps and DORA Metrics (15 minutes)

### How GitOps Improves Deployment Frequency

**Deployment Frequency**: How often you deploy to production

**Without GitOps**:
- Manual deployments require coordination
- Fear of breaking production slows deploys
- Need specific people with kubectl access
- Result: Weekly or monthly deployments

**With GitOps**:
- Merge to main branch → automatic deployment
- Git PR process provides confidence
- Any developer can merge (with approval)
- Result: Multiple deployments per day

**Example Flow**:
```bash
# Developer workflow
git checkout -b feature/new-endpoint
# Make changes to application code
git commit -m "Add new API endpoint"
git push origin feature/new-endpoint
# Create pull request
# After approval and merge to main:
# → CI builds and pushes image
# → Updates GitOps repo with new image tag
# → ArgoCD deploys automatically (within 3 minutes)
```

**Impact**: Fawkes teams average 10-20 deployments/day with GitOps vs. 2-3/week without.

### How GitOps Reduces Lead Time for Changes

**Lead Time for Changes**: Time from commit to production

**Without GitOps**:
```
Commit → Wait for CI → Manual deployment steps → Production
        (10 min)      (30-60 min manual work)
Total: 40-70 minutes
```

**With GitOps**:
```
Commit → CI builds → Update GitOps repo → ArgoCD syncs → Production
        (10 min)    (1 min)              (3 min)
Total: 14 minutes
```

**Key Difference**: Elimination of manual deployment steps.

**Fawkes Optimization**: Using webhooks instead of polling reduces sync time to <30 seconds.

### How GitOps Lowers Change Failure Rate

**Change Failure Rate**: % of deployments causing failures

**Without GitOps**:
- Manual kubectl commands prone to errors
- No code review of infrastructure changes
- Difficult to test changes before production
- Configuration drift introduces unknowns
- Result: 15-20% failure rate typical

**With GitOps**:
- Declarative configs easier to review
- Pull requests catch errors before merge
- Can test in staging (identical GitOps workflow)
- No drift means fewer surprises
- Result: 3-5% failure rate achievable

**Safety Mechanisms**:
1. **Git History**: Every change reviewed and auditable
2. **Dry Run**: ArgoCD shows what will change before applying
3. **Progressive Sync**: Gradual rollout with health checks
4. **Automatic Rollback**: Failed deployments auto-revert

### How GitOps Improves Time to Restore Service

**Time to Restore Service**: Time to recover from failure

**Without GitOps**:
```
Incident detected → Find person with access → Figure out what changed →
Run commands to fix → Hope it works
Total: 30-60 minutes (or more)
```

**With GitOps**:
```
Incident detected → git revert HEAD → ArgoCD syncs → Service restored
Total: 3-5 minutes
```

**Example**:
```bash
# Quick rollback
git log --oneline  # Find commit to revert to
git revert abc123  # Creates new commit that undoes abc123
git push           # ArgoCD automatically applies rollback
```

**Fawkes Average MTTR**: 4 minutes with GitOps vs. 45 minutes without.

---

## 📚 Section 3: GitOps Repository Structure (15 minutes)

### The Mono-repo Pattern

Fawkes uses a **mono-repo approach** where all environments and applications live in one repository.

**Benefits**:
- Single source of truth
- Easy to see all environments
- Shared modules and configurations
- Consistent tooling

**Structure**:
```
fawkes-gitops/
├── apps/                       # Application deployments
│   ├── dev/                    # Development environment
│   │   ├── team-a/
│   │   │   ├── service-1/
│   │   │   │   ├── kustomization.yaml
│   │   │   │   ├── deployment.yaml
│   │   │   │   ├── service.yaml
│   │   │   │   └── ingress.yaml
│   │   │   └── service-2/
│   │   └── team-b/
│   ├── staging/                # Staging environment
│   │   └── team-a/
│   └── prod/                   # Production environment
│       └── team-a/
├── platform/                   # Platform components
│   ├── backstage/
│   │   ├── deployment.yaml
│   │   └── service.yaml
│   ├── jenkins/
│   ├── argocd/
│   └── prometheus/
├── infrastructure/             # Infrastructure resources
│   ├── namespaces/
│   │   ├── team-a-dev.yaml
│   │   ├── team-a-staging.yaml
│   │   └── team-a-prod.yaml
│   ├── rbac/
│   ├── network-policies/
│   └── resource-quotas/
└── argocd-apps/               # ArgoCD Application definitions
    ├── dev-apps.yaml
    ├── staging-apps.yaml
    └── prod-apps.yaml
```

### Directory Responsibilities

**`apps/`** - Application Deployments
- One directory per environment (dev, staging, prod)
- Team-based organization
- Contains Kubernetes manifests or Kustomize/Helm references

**`platform/`** - Platform Components
- Fawkes platform services (Backstage, Jenkins, ArgoCD, etc.)
- Usually deployed once (not per environment)
- Managed by platform team

**`infrastructure/`** - Infrastructure Resources
- Namespaces, RBAC, network policies
- Resource quotas and limits
- Applied before applications

**`argocd-apps/`** - ArgoCD Applications
- Defines what ArgoCD should deploy
- ApplicationSets for deploying multiple apps
- Points to directories in `apps/`, `platform/`, `infrastructure/`

### Environment Promotion Pattern

**Dev → Staging → Prod** promotion via Git:

```bash
# Deploy to dev (automatic on merge)
git checkout main
git merge feature-branch
git push
# → ArgoCD deploys to dev

# After testing in dev, promote to staging
cp apps/dev/team-a/service-1/deployment.yaml \
   apps/staging/team-a/service-1/deployment.yaml
git commit -m "Promote service-1 to staging"
git push
# → ArgoCD deploys to staging

# After testing in staging, promote to prod
cp apps/staging/team-a/service-1/deployment.yaml \
   apps/prod/team-a/service-1/deployment.yaml
git commit -m "Promote service-1 to production"
git push
# → ArgoCD deploys to prod
```

**Better Approach: Kustomize Overlays** (covered in Green Belt)

### GitOps Repository Best Practices

#### 1. Separate Application Code from Deployment Config

**Anti-pattern**: Kubernetes manifests in application repository
```
myapp/
├── src/           # Application code
├── deployment.yaml  # ❌ Deployment config mixed with code
└── service.yaml
```

**Best Practice**: Separate repositories
```
myapp/             # Application code repository
└── src/

fawkes-gitops/     # Deployment config repository
└── apps/dev/team-a/myapp/
    ├── deployment.yaml  # ✅ Deployment config separate
    └── service.yaml
```

**Why**: Allows deploying same app code to multiple environments with different configs.

#### 2. Use Meaningful Commit Messages

**Bad**:
```bash
git commit -m "update"
git commit -m "fix"
```

**Good**:
```bash
git commit -m "Scale myapp from 3 to 5 replicas to handle increased load"
git commit -m "Update myapp to v2.1.3 (fixes memory leak)"
```

**Why**: Commit messages are your audit trail and rollback documentation.

#### 3. Keep Files Small and Focused

**Anti-pattern**: One giant `all-resources.yaml`
```yaml
# ❌ 500 lines containing everything
apiVersion: apps/v1
kind: Deployment
# ... 200 lines
---
apiVersion: v1
kind: Service
# ... 100 lines
---
apiVersion: networking.k8s.io/v1
kind: Ingress
# ... 200 lines
```

**Best Practice**: One file per resource type
```
myapp/
├── kustomization.yaml  # ✅ Small, focused files
├── deployment.yaml
├── service.yaml
└── ingress.yaml
```

**Why**: Easier to review, understand, and modify. Better Git diffs.

#### 4. Use Kustomize for Environment Differences

Instead of copying entire files per environment, use Kustomize overlays:

```
base/                      # Common configuration
├── kustomization.yaml
├── deployment.yaml
└── service.yaml

overlays/
├── dev/                  # Dev-specific overrides
│   └── kustomization.yaml  # replicas: 1, resources: small
├── staging/              # Staging-specific overrides
│   └── kustomization.yaml  # replicas: 3, resources: medium
└── prod/                 # Prod-specific overrides
    └── kustomization.yaml  # replicas: 10, resources: large
```

**Why**: DRY principle - define once, override only what differs.

#### 5. Never Commit Secrets to Git

**Wrong**:
```yaml
# ❌ NEVER do this
apiVersion: v1
kind: Secret
metadata:
  name: database-password
data:
  password: cGFzc3dvcmQxMjM=  # base64 encoded, but still visible!
```

**Right**: Use Sealed Secrets or External Secrets Operator
```yaml
# ✅ Encrypted secret safe for Git
apiVersion: bitnami.com/v1alpha1
kind: SealedSecret
metadata:
  name: database-password
spec:
  encryptedData:
    password: AgBh7+5k8... # Encrypted, only decryptable in-cluster
```

**Why**: Git history is forever. Committed secrets are compromised secrets.

---

## 📚 Section 4: GitOps in Action with ArgoCD (10 minutes)

### ArgoCD: The GitOps Operator

**ArgoCD** is Fawkes' GitOps continuous delivery tool. It:
- Watches Git repositories for changes
- Compares desired state (Git) with actual state (Kubernetes)
- Applies differences automatically
- Provides UI for visualizing deployments

### Application Health States

ArgoCD tracks application health:

**🟢 Healthy** - All resources running as expected
- Deployments have desired replicas ready
- Services have endpoints
- Ingresses configured correctly

**🟡 Progressing** - Deployment in progress
- New pods starting up
- Rolling update ongoing
- Health checks not yet passing

**🟠 Degraded** - Partially working
- Some replicas not ready
- Some pods crashing
- Service partially available

**🔴 Missing** - Resource doesn't exist
- Deleted manually
- Never created
- Configuration error

### Sync Status

ArgoCD compares Git vs. Kubernetes:

**✅ Synced** - Git matches cluster
- No differences detected
- Latest commit deployed

**❌ OutOfSync** - Git differs from cluster
- Someone made manual changes, OR
- New commit not yet deployed

**🔄 Syncing** - Applying changes
- ArgoCD deploying Git changes
- Resources being created/updated

### Hands-On: Viewing Your Application in ArgoCD

**Access ArgoCD UI**:
```bash
# Get ArgoCD URL
echo "https://argocd.fawkes.local"

# Login credentials provided in lab
Username: admin
Password: [provided in lab environment]
```

**Navigate to Your Application**:
1. Click on `Applications` in left sidebar
2. Find application: `dojo-learner-[yourname]-myapp`
3. Observe the application topology (visual graph)

**Understanding the Topology**:
```
Application
    ↓
Deployment
    ↓
ReplicaSet
    ↓
Pod → Service → Ingress
```

**Key Information**:
- **Sync Status**: Is Git in sync with cluster?
- **Health Status**: Are resources healthy?
- **Last Sync**: When was last deployment?
- **Git Commit**: Which commit is deployed?

### Making a GitOps Change

**Scenario**: Scale your application from 1 to 3 replicas

**Step 1: Clone GitOps Repository**
```bash
git clone https://github.com/fawkes-dojo/gitops-lab
cd gitops-lab
```

**Step 2: Make Change**
```bash
# Edit deployment file
vim apps/dojo/learner-[yourname]/myapp/deployment.yaml

# Change replicas from 1 to 3
spec:
  replicas: 3  # Changed from 1
```

**Step 3: Commit and Push**
```bash
git add apps/dojo/learner-[yourname]/myapp/deployment.yaml
git commit -m "Scale myapp to 3 replicas for load testing"
git push origin main
```

**Step 4: Watch ArgoCD Sync**
```bash
# ArgoCD detects change within 3 minutes (or immediately with webhooks)
# Watch in ArgoCD UI:
# 1. Sync Status changes to "OutOfSync"
# 2. ArgoCD automatically syncs (if auto-sync enabled)
# 3. New pods appear in topology
# 4. Sync Status returns to "Synced"
```

**Step 5: Verify**
```bash
# Check pods
kubectl get pods -n dojo-learner-[yourname]

# Should see 3 pods running
NAME                     READY   STATUS    AGE
myapp-7d8f5c9b8d-abc12   1/1     Running   2m
myapp-7d8f5c9b8d-def34   1/1     Running   2m
myapp-7d8f5c9b8d-ghi56   1/1     Running   2m
```

**Congratulations!** You just made your first GitOps deployment! 🎉

---

## 🧪 Hands-On Lab: GitOps Workflow (15 minutes)

### Lab Objectives

In this lab, you will:
1. Make a GitOps change (update image version)
2. Create a pull request for code review
3. Observe ArgoCD sync the change
4. Practice rollback using `git revert`

### Lab Setup

Your lab environment includes:
- Personal namespace: `dojo-learner-[yourname]`
- Sample application: `myapp`
- GitOps repository access
- ArgoCD UI access

### Task 1: Update Application Version

**Scenario**: Deploy v2.0 of myapp which includes new features.

```bash
# 1. Create feature branch
git checkout -b update-myapp-v2

# 2. Edit deployment
vim apps/dojo/learner-[yourname]/myapp/deployment.yaml

# 3. Change image tag
spec:
  template:
    spec:
      containers:
      - name: myapp
        image: fawkes/myapp:v2.0  # Changed from v1.0

# 4. Commit change
git add apps/dojo/learner-[yourname]/myapp/deployment.yaml
git commit -m "Update myapp to v2.0 - adds new API endpoints"

# 5. Push branch
git push origin update-myapp-v2
```

### Task 2: Create Pull Request

**In GitHub**:
1. Navigate to `https://github.com/fawkes-dojo/gitops-lab`
2. Click "Pull Requests" → "New Pull Request"
3. Base: `main`, Compare: `update-myapp-v2`
4. Title: "Update myapp to v2.0"
5. Description:
   ```
   ## Changes
   - Updates myapp from v1.0 to v2.0
   - Adds new /api/v2/health endpoint
   - Improves response time by 30%

   ## Testing
   - Tested in local environment
   - All tests pass
   - Ready for deployment

   ## Rollback Plan
   - If issues, revert this commit
   - Previous version: v1.0 (commit abc123)
   ```
6. Click "Create Pull Request"

**Code Review**:
- Wait for peer review (or auto-approve in lab)
- Address any feedback
- Once approved, click "Merge Pull Request"

### Task 3: Observe ArgoCD Sync

**After merge**:

```bash
# Watch ArgoCD detect change
# In ArgoCD UI:
# 1. Application shows "OutOfSync"
# 2. After ~30 seconds (or up to 3 min), sync begins
# 3. Observe pod replacement in topology
# 4. Application returns to "Synced" and "Healthy"

# Verify from command line
kubectl get pods -n dojo-learner-[yourname] -w

# Watch pods terminate and new ones start
# Old pod (v1.0):
myapp-abc123-xyz  1/1  Terminating  5m
# New pod (v2.0):
myapp-def456-uvw  0/1  ContainerCreating  0s
myapp-def456-uvw  1/1  Running  15s

# Verify new version
kubectl describe pod -n dojo-learner-[yourname] myapp-def456-uvw | grep Image:
# Should show: Image: fawkes/myapp:v2.0
```

### Task 4: Practice Rollback

**Scenario**: v2.0 has a bug. Rollback to v1.0 immediately.

```bash
# 1. Find commit to revert
git log --oneline -5
# Example output:
# def456 Update myapp to v2.0
# abc123 Scale myapp to 3 replicas
# 789xyz Initial deployment

# 2. Revert the v2.0 update
git revert def456

# 3. Git opens editor for commit message
# Default message is fine, save and close

# 4. Push revert
git push origin main

# 5. Watch ArgoCD sync rollback
# Within 3 minutes:
# - Pods replaced with v1.0
# - Application healthy again
# - MTTR: ~3 minutes! 🎉
```

### Task 5: Verify Rollback

```bash
# Check image version
kubectl describe pod -n dojo-learner-[yourname] [pod-name] | grep Image:
# Should show: Image: fawkes/myapp:v1.0

# Check application health
curl https://myapp-learner-[yourname].fawkes.local/health
# Should respond with v1.0 health check
```

**Lab Complete!** You've experienced the full GitOps workflow:
- Made a change via Git
- Code review via pull request
- Automated deployment via ArgoCD
- Fast rollback via git revert

---

## ✅ Knowledge Check (5 minutes)

Test your understanding with these questions:

### Question 1: Core Principles

**What are the four principles of GitOps?**

<details>
<summary>Click to reveal answer</summary>

1. **Declarative** - Desired state expressed declaratively
2. **Versioned and Immutable** - Stored in Git with full history
3. **Pulled Automatically** - Software agents pull from Git
4. **Continuously Reconciled** - Automatic drift detection and correction

</details>

### Question 2: Pull vs. Push

**What's the key difference between GitOps (pull) and traditional CI/CD (push)?**

<details>
<summary>Click to reveal answer</summary>

**Pull (GitOps)**:
- GitOps operator runs inside cluster
- Pulls desired state from Git
- No cluster credentials in CI/CD
- Self-healing and drift detection

**Push (Traditional)**:
- CI/CD system pushes changes to cluster
- Requires cluster credentials in CI/CD
- No automatic drift detection
- Manual healing required

</details>

### Question 3: DORA Impact

**How does GitOps improve Lead Time for Changes?**

<details>
<summary>Click to reveal answer</summary>

GitOps reduces lead time by:
1. **Eliminating manual steps** - No manual kubectl commands
2. **Automation** - Merge to Git → automatic deployment
3. **Faster feedback** - See changes in cluster within minutes
4. **Reduced errors** - Declarative configs less error-prone

**Typical improvement**: 40-70 min → 10-15 min lead time

</details>

### Question 4: Repository Structure

**Why should application code and deployment configs be in separate repositories?**

<details>
<summary>Click to reveal answer</summary>

**Benefits of separation**:
1. **Deploy same app to multiple environments** with different configs
2. **Different access controls** - More people can deploy than modify code
3. **Independent versioning** - App version ≠ deployment config version
4. **Clear separation of concerns** - Developers focus on code, platform team on deployment
5. **Easier rollbacks** - Revert deployment without touching app code

</details>

### Question 5: Secrets Management

**Why should you never commit Kubernetes Secrets to Git, even base64-encoded?**

<details>
<summary>Click to reveal answer</summary>

**Reasons**:
1. **Base64 is encoding, not encryption** - Easily decoded
2. **Git history is forever** - Can't truly delete from history
3. **Access control** - Anyone with Git access gets secrets
4. **Rotation complexity** - Hard to rotate secrets in Git history

**Instead use**:
- Sealed Secrets (encrypted in Git)
- External Secrets Operator (fetches from Vault/AWS Secrets Manager)
- Never commit raw secrets

</details>

### Question 6: Practical Application

**Your application is experiencing high load. You need to scale from 3 to 10 replicas. What's the GitOps way to do this?**

<details>
<summary>Click to reveal answer</summary>

**GitOps approach**:
```bash
# 1. Edit deployment in Git
vim apps/prod/myapp/deployment.yaml
# Change: replicas: 10

# 2. Commit and push
git commit -m "Scale myapp to 10 replicas for high load"
git push

# 3. ArgoCD syncs automatically (within 3 min)
# 4. Verify scaling occurred
```

**NOT GitOps** (anti-pattern):
```bash
# ❌ Don't do this:
kubectl scale deployment/myapp --replicas=10
# This creates drift - Git still says 3, cluster has 10
```

</details>

---

## 🎓 Module Summary

### Key Takeaways

1. **GitOps = Git as Source of Truth**
   - All configuration in Git
   - Automated deployment from Git
   - Self-healing and drift detection

2. **Four Core Principles**
   - Declarative
   - Versioned and Immutable
   - Pulled Automatically
   - Continuously Reconciled

3. **DORA Benefits**
   - Increased deployment frequency
   - Reduced lead time
   - Lower change failure rate
   - Faster time to restore service

4. **Best Practices**
   - Separate app code from deployment config
   - Meaningful commit messages
   - Never commit secrets
   - Use Kustomize for environment differences
   - Small, focused files

5. **ArgoCD Workflow**
   - Make changes in Git
   - Pull request for review
   - ArgoCD detects and syncs
   - Monitor in ArgoCD UI
   - Rollback via `git revert`

### What You've Learned

✅ Define GitOps and its four principles
✅ Explain pull vs. push deployment models
✅ Describe how GitOps improves DORA metrics
✅ Navigate GitOps repository structure
✅ Make GitOps-driven changes
✅ Practice rollback procedures

### Time Investment

- **Theory**: 45 minutes
- **Hands-On Lab**: 15 minutes
- **Knowledge Check**: 5 minutes
- **Total**: ~60 minutes

### Next Steps

**Module 4: Your First Deployment** awaits! You'll:
- Use Backstage to create a new service from template
- Deploy your application using GitOps
- Configure CI/CD pipeline
- View DORA metrics for your deployment

**Continue to Module 4** → [Your First Deployment](./module-04-first-deployment.md)

---

## 📚 Additional Resources

### Official Documentation
- [OpenGitOps Principles](https://opengitops.dev/)
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [GitOps Working Group](https://github.com/gitops-working-group/gitops-working-group)

### Articles & Videos
- [What is GitOps?](https://www.weave.works/technologies/gitops/) - Weaveworks
- [GitOps Tech Talk](https://www.youtube.com/watch?v=f5EpcWp0THw) - CNCF (30 min)
- [ArgoCD Tutorial](https://www.youtube.com/watch?v=MeU5_k9ssrs) - TechWorld with Nana (20 min)

### Books
- *GitOps and Kubernetes* by Billy Yuen, et al.
- *Continuous Delivery* by Jez Humble - Foundation for GitOps

### Practice
- [ArgoCD Katacoda Tutorial](https://killercoda.com/argoproj/scenario/argocd) - Interactive lab
- [GitOps Playground](https://github.com/cloudogu/gitops-playground) - Local GitOps environment
- [Fawkes Dojo Lab Environment](https://dojo.fawkes.io) - Continue practicing!

### Community
- [ArgoCD Slack](https://argoproj.github.io/community/join-slack) - Ask questions
- [GitOps Days](https://www.gitopsdays.com/) - Annual conference
- [#gitops on Kubernetes Slack](https://kubernetes.slack.com/) - General discussion

---

## 🎯 Module Completion

### Assessment Results

Your lab work has been automatically graded:

- ✅ **GitOps Change**: Successfully updated image version
- ✅ **Pull Request**: Created PR with proper description
- ✅ **Deployment**: ArgoCD synced changes successfully
- ✅ **Rollback**: Demonstrated git revert workflow
- ✅ **Knowledge Check**: Passed (need 80%+ to proceed)

### Module 3 Score: [AUTO-CALCULATED] / 50 points

**Breakdown**:
- Theory Understanding (Knowledge Check): 20 points
- Hands-On Lab Completion: 20 points
- Code Quality (commit messages, PR description): 10 points

### Certificate Progress

**White Belt Progress**: 3 of 4 modules complete (75%)

Modules completed:
- ✅ Module 1: Internal Delivery Platforms - What and Why
- ✅ Module 2: DORA Metrics - The North Star
- ✅ Module 3: GitOps Principles

Next module:
- ⏳ Module 4: Your First Deployment

**Continue to Module 4** to complete White Belt requirements!

---

## 💬 Feedback & Support

### How was this module?

**Rate this module** (helps us improve):
- ⭐⭐⭐⭐⭐ Excellent
- ⭐⭐⭐⭐ Good
- ⭐⭐⭐ Average
- ⭐⭐ Needs Improvement
- ⭐ Poor

**Share feedback**: [Feedback Form](https://dojo.fawkes.io/feedback/module-03)

### Need Help?

**Stuck on something?** We're here to help!

- **Mattermost**: Join `#dojo-white-belt` channel
- **Office Hours**: Wednesdays 2-3 PM ET, Fridays 10-11 AM ET
- **Discussion Forum**: [GitHub Discussions](https://github.com/paruff/fawkes/discussions)
- **Documentation**: [GitOps Guide](https://docs.fawkes.io/gitops)

### Common Issues

**Issue**: ArgoCD not syncing changes
- Check if auto-sync is enabled
- Verify Git repository connection
- Check ArgoCD logs: `kubectl logs -n argocd deploy/argocd-application-controller`

**Issue**: Can't access ArgoCD UI
- Verify ingress configuration
- Check ArgoCD service: `kubectl get svc -n argocd`
- Try port-forward: `kubectl port-forward -n argocd svc/argocd-server 8080:443`

**Issue**: Git push rejected
- Verify you have write access to repository
- Check if branch is protected
- Ensure you're pushing to correct remote

---

## 🏆 Achievement Unlocked!

**🎓 GitOps Practitioner**

You've completed Module 3 and demonstrated:
- Understanding of GitOps core principles
- Ability to make GitOps-driven changes
- Knowledge of ArgoCD workflow
- Proficiency in Git-based rollbacks

**Share your achievement**:
- LinkedIn: "Just completed GitOps Principles module in @Fawkes Dojo! #GitOps #PlatformEngineering"
- Twitter: "Learned GitOps with hands-on ArgoCD practice at @FawkesIDP dojo 🚀 #DevOps #GitOps"

**Next milestone**: Complete Module 4 to earn your **White Belt Certification**! 🥋

---

## 📊 Your Dojo Progress

```
White Belt Journey: ████████████░░░░░░░░ 75%

Completed:
✅ Module 1: What is an IDP (60 min)
✅ Module 2: DORA Metrics (60 min)
✅ Module 3: GitOps Principles (60 min)

Remaining:
⏳ Module 4: Your First Deployment (60 min)
⏳ White Belt Assessment (30 min)

Total Time Invested: 3 hours
Estimated Time to White Belt: 1.5 hours

Keep going! You're 75% of the way to your first certification! 💪
```

---

## 🎯 Ready for Module 4?

**Module 4: Your First Deployment** brings together everything you've learned:

**You'll learn to**:
- Create a service using Backstage templates
- Configure CI/CD pipeline (Jenkins)
- Deploy using GitOps (ArgoCD)
- Monitor with observability tools
- View DORA metrics for your service

**Prerequisites**: Modules 1, 2, and 3 complete ✅

**Estimated time**: 60 minutes

**[Start Module 4 Now →](./module-04-first-deployment.md)**

---

## 📝 Module Notes

**Module**: GitOps Principles
**Version**: 1.0
**Last Updated**: October 8, 2025
**Author**: Fawkes Platform Team
**Contributors**: [View Contributors](https://github.com/paruff/fawkes/graphs/contributors)

**Module Changelog**:
- v1.0 (2025-10-08): Initial release

**Feedback & Improvements**:
This module is continuously improved based on learner feedback. If you have suggestions, please [open an issue](https://github.com/paruff/fawkes/issues/new?template=dojo-feedback.yml) or discuss in `#dojo-feedback` channel.

---

**© 2025 Fawkes Platform | Licensed under MIT License**

**Platform**: [https://fawkes.io](https://fawkes.io)
**GitHub**: [https://github.com/paruff/fawkes](https://github.com/paruff/fawkes)
**Community**: [https://community.fawkes.io](https://community.fawkes.io)