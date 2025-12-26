# Fawkes Dojo Module 10: Deployment Strategies

## 🎯 Module Overview

**Belt Level**: 🟢 Green Belt - GitOps & Deployment
**Module**: 2 of 4 (Green Belt)
**Duration**: 60 minutes
**Difficulty**: Intermediate
**Prerequisites**:

- Module 9: GitOps with ArgoCD complete
- Understanding of Kubernetes Deployments
- Familiarity with service routing
- Basic knowledge of load balancing

---

## 📚 Learning Objectives

By the end of this module, you will:

1. ✅ Understand different deployment strategies and when to use each
2. ✅ Implement blue-green deployments with Kubernetes
3. ✅ Configure canary deployments with traffic splitting
4. ✅ Execute rolling updates with zero downtime
5. ✅ Implement recreate deployments for stateful apps
6. ✅ Use feature flags for progressive rollouts
7. ✅ Choose the right strategy for different scenarios

**DORA Capabilities Addressed**:

- ✓ CD2: Automate deployment process (advanced)
- ✓ Work in Small Batches
- ✓ Team Experimentation

---

## 📖 Part 1: Deployment Strategy Overview

### The Problem: High-Risk Deployments

**Traditional "Big Bang" deployment**:

```
Old Version (100% traffic) → SWITCH → New Version (100% traffic)
                                ↓
                          If something breaks:
                          ALL users affected
                          Immediate rollback needed
                          High stress, high risk
```

**Result**: Fear of deploying, slow release cycles, weekend deployments

### The Solution: Progressive Deployment Strategies

Different strategies for different needs:

| Strategy           | Risk     | Downtime | Complexity | Best For                       |
| ------------------ | -------- | -------- | ---------- | ------------------------------ |
| **Recreate**       | High     | Yes      | Low        | Development, stateful apps     |
| **Rolling Update** | Medium   | No       | Low        | Most applications              |
| **Blue-Green**     | Low      | No       | Medium     | Production, quick rollback     |
| **Canary**         | Very Low | No       | High       | Critical apps, gradual rollout |
| **A/B Testing**    | Very Low | No       | High       | Feature testing, experiments   |

---

## 🔵🟢 Part 2: Blue-Green Deployment

### What is Blue-Green?

Run two identical production environments:

- **Blue**: Current production version
- **Green**: New version being deployed

Switch traffic from Blue → Green when ready.

```
┌─────────────┐
│   Users     │
└──────┬──────┘
       │
┌──────▼──────────────────────┐
│   Load Balancer/Router      │
│   (Initially → Blue)         │
└──────┬──────────────────────┘
       │
   ┌───┴────┐
   │        │
┌──▼──┐  ┌─▼───┐
│Blue │  │Green│
│v1.0 │  │v2.0 │
│100% │  │ 0%  │
└─────┘  └─────┘

[Deploy & Test Green]
        ↓
┌──────────────────────┐
│   Switch Traffic     │
│   Blue → Green       │
└──────────────────────┘
        ↓
┌─────┐  ┌─────┐
│Blue │  │Green│
│v1.0 │  │v2.0 │
│ 0%  │  │100% │
└─────┘  └─────┘
```

### Benefits

- ✅ Instant rollback (switch back to Blue)
- ✅ Zero downtime
- ✅ Test in production before switching
- ✅ Simple conceptually

### Drawbacks

- ❌ 2x infrastructure cost during deployment
- ❌ Database migrations tricky
- ❌ All-or-nothing switch

---

## 🛠️ Part 3: Hands-On Lab - Blue-Green Deployment

### Step 1: Deploy Blue Environment

Create `blue-deployment.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp-blue
  labels:
    app: myapp
    version: blue
spec:
  replicas: 3
  selector:
    matchLabels:
      app: myapp
      version: blue
  template:
    metadata:
      labels:
        app: myapp
        version: blue
    spec:
      containers:
        - name: myapp
          image: myapp:v1.0
          ports:
            - containerPort: 8080
          env:
            - name: VERSION
              value: "v1.0-blue"
          resources:
            requests:
              memory: "128Mi"
              cpu: "100m"
            limits:
              memory: "256Mi"
              cpu: "200m"
---
apiVersion: v1
kind: Service
metadata:
  name: myapp
spec:
  selector:
    app: myapp
    version: blue # Points to blue initially
  ports:
    - port: 80
      targetPort: 8080
  type: LoadBalancer
```

Deploy:

```bash
kubectl apply -f blue-deployment.yaml

# Verify
kubectl get pods -l version=blue
kubectl get svc myapp
```

### Step 2: Deploy Green Environment

Create `green-deployment.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp-green
  labels:
    app: myapp
    version: green
spec:
  replicas: 3
  selector:
    matchLabels:
      app: myapp
      version: green
  template:
    metadata:
      labels:
        app: myapp
        version: green
    spec:
      containers:
        - name: myapp
          image: myapp:v2.0 # New version
          ports:
            - containerPort: 8080
          env:
            - name: VERSION
              value: "v2.0-green"
          resources:
            requests:
              memory: "128Mi"
              cpu: "100m"
            limits:
              memory: "256Mi"
              cpu: "200m"
```

Deploy Green (without switching traffic):

```bash
kubectl apply -f green-deployment.yaml

# Verify both running
kubectl get pods -l app=myapp
```

### Step 3: Test Green Environment

Create a test service to access Green directly:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: myapp-green-test
spec:
  selector:
    app: myapp
    version: green
  ports:
    - port: 80
      targetPort: 8080
  type: LoadBalancer
```

Test Green:

```bash
kubectl apply -f green-test-service.yaml

# Get test service URL
TEST_URL=$(kubectl get svc myapp-green-test -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

# Run tests
curl http://$TEST_URL/health
curl http://$TEST_URL/version
# Should return: v2.0-green

# Run load test
ab -n 1000 -c 10 http://$TEST_URL/
```

### Step 4: Switch Traffic to Green

Update the main service selector:

```bash
# Patch service to point to green
kubectl patch service myapp -p '{"spec":{"selector":{"version":"green"}}}'

# Verify switch
kubectl get svc myapp -o yaml | grep version
# Should show: version: green

# Test from user perspective
PROD_URL=$(kubectl get svc myapp -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
curl http://$PROD_URL/version
# Should return: v2.0-green
```

### Step 5: Rollback if Needed

If issues found, instant rollback:

```bash
# Switch back to blue
kubectl patch service myapp -p '{"spec":{"selector":{"version":"blue"}}}'

# Verify
curl http://$PROD_URL/version
# Should return: v1.0-blue

# Total rollback time: ~5 seconds!
```

### Step 6: Clean Up Old Version

Once confident in Green:

```bash
# Scale down blue
kubectl scale deployment myapp-blue --replicas=0

# Or delete entirely
kubectl delete deployment myapp-blue
kubectl delete service myapp-green-test
```

---

## 🔄 Part 4: Rolling Update Deployment

### What is Rolling Update?

Gradually replace pods with new version, one (or few) at a time.

```
Initial State:
[v1] [v1] [v1] [v1] [v1]  (5 pods)

Step 1:
[v1] [v1] [v1] [v1] [v2]  (1 pod updated)
                    ↑
                 New pod

Step 2:
[v1] [v1] [v1] [v2] [v2]  (2 pods updated)

Step 3:
[v1] [v1] [v2] [v2] [v2]  (3 pods updated)

Step 4:
[v1] [v2] [v2] [v2] [v2]  (4 pods updated)

Step 5:
[v2] [v2] [v2] [v2] [v2]  (All pods updated)
```

### Benefits

- ✅ Zero downtime
- ✅ Gradual rollout (detect issues early)
- ✅ No extra infrastructure needed
- ✅ Built into Kubernetes

### Drawbacks

- ❌ Both versions run simultaneously
- ❌ Rollback slower than blue-green
- ❌ May cause issues if versions incompatible

### Implementing Rolling Update

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
spec:
  replicas: 5
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1 # Max 1 extra pod during update
      maxUnavailable: 1 # Max 1 pod can be unavailable
  selector:
    matchLabels:
      app: myapp
  template:
    metadata:
      labels:
        app: myapp
    spec:
      containers:
        - name: myapp
          image: myapp:v2.0
          ports:
            - containerPort: 8080
          livenessProbe:
            httpGet:
              path: /health
              port: 8080
            initialDelaySeconds: 10
            periodSeconds: 5
          readinessProbe:
            httpGet:
              path: /ready
              port: 8080
            initialDelaySeconds: 5
            periodSeconds: 3
```

### Controlling Rolling Update Speed

```yaml
strategy:
  type: RollingUpdate
  rollingUpdate:
    maxSurge: 2 # Update 2 pods at a time
    maxUnavailable: 0 # Keep all pods available

# This means:
# - Always maintain at least 5 pods available
# - Can temporarily have up to 7 pods (5 + 2 surge)
# - Faster rollout but more resources used
```

**Conservative rollout**:

```yaml
strategy:
  type: RollingUpdate
  rollingUpdate:
    maxSurge: 1
    maxUnavailable: 0
# This means:
# - Update only 1 pod at a time
# - Never reduce capacity
# - Slower but safer
```

### Performing Rolling Update

```bash
# Update image version
kubectl set image deployment/myapp myapp=myapp:v2.0

# Watch the rollout
kubectl rollout status deployment/myapp

# Expected output:
Waiting for deployment "myapp" rollout to finish: 1 out of 5 new replicas have been updated...
Waiting for deployment "myapp" rollout to finish: 2 out of 5 new replicas have been updated...
Waiting for deployment "myapp" rollout to finish: 3 out of 5 new replicas have been updated...
Waiting for deployment "myapp" rollout to finish: 4 out of 5 new replicas have been updated...
Waiting for deployment "myapp" rollout to finish: 4 of 5 updated replicas are available...
deployment "myapp" successfully rolled out

# Verify
kubectl get pods -l app=myapp
```

### Pausing and Resuming Rollout

```bash
# Start rollout
kubectl set image deployment/myapp myapp=myapp:v2.0

# Pause after first pod
kubectl rollout pause deployment/myapp

# Verify mixed versions
kubectl get pods -l app=myapp -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.containers[0].image}{"\n"}{end}'

# Run smoke tests on new version
# If good, resume
kubectl rollout resume deployment/myapp

# If bad, rollback
kubectl rollout undo deployment/myapp
```

---

## 🐦 Part 5: Canary Deployment

### What is Canary?

Release new version to small subset of users first, gradually increase if successful.

```
Phase 1: 5% canary
────────────────────
95% → [v1] [v1] [v1] ... (19 pods)
 5% → [v2]                (1 pod)

Phase 2: 25% canary (if healthy)
─────────────────────────────────
75% → [v1] [v1] [v1] ... (15 pods)
25% → [v2] [v2] [v2] ... (5 pods)

Phase 3: 50% canary
────────────────────
50% → [v1] [v1] ... (10 pods)
50% → [v2] [v2] ... (10 pods)

Phase 4: 100% canary
────────────────────
  0% → (Blue removed)
100% → [v2] [v2] ... (20 pods)
```

### Benefits

- ✅ Lowest risk (expose to small % first)
- ✅ Real user feedback before full rollout
- ✅ Can monitor metrics for issues
- ✅ Gradual, controlled rollout

### Drawbacks

- ❌ Complex to implement correctly
- ❌ Need sophisticated traffic routing
- ❌ Requires monitoring and analysis

### Canary with Native Kubernetes

Basic canary using ReplicaSet ratios:

```bash
# Deploy baseline (v1.0)
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp-baseline
spec:
  replicas: 19  # 95% of traffic
  selector:
    matchLabels:
      app: myapp
  template:
    metadata:
      labels:
        app: myapp
        version: v1.0
    spec:
      containers:
      - name: myapp
        image: myapp:v1.0
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp-canary
spec:
  replicas: 1  # 5% of traffic
  selector:
    matchLabels:
      app: myapp
  template:
    metadata:
      labels:
        app: myapp
        version: v2.0
        canary: "true"
    spec:
      containers:
      - name: myapp
        image: myapp:v2.0
---
apiVersion: v1
kind: Service
metadata:
  name: myapp
spec:
  selector:
    app: myapp  # Matches both versions
  ports:
  - port: 80
    targetPort: 8080
EOF
```

**Problem with this approach**: Traffic split not guaranteed (depends on load balancer).

### Canary with Istio (Advanced)

For precise traffic control:

```yaml
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: myapp
spec:
  hosts:
    - myapp
  http:
    - match:
        - headers:
            x-canary:
              exact: "true"
      route:
        - destination:
            host: myapp
            subset: canary
    - route:
        - destination:
            host: myapp
            subset: baseline
          weight: 95
        - destination:
            host: myapp
            subset: canary
          weight: 5
---
apiVersion: networking.istio.io/v1beta1
kind: DestinationRule
metadata:
  name: myapp
spec:
  host: myapp
  subsets:
    - name: baseline
      labels:
        version: v1.0
    - name: canary
      labels:
        version: v2.0
```

---

## 🔨 Part 6: Recreate Deployment

### What is Recreate?

Shut down all old pods, then start new ones.

```
Phase 1: Running
[v1] [v1] [v1] [v1] [v1]

Phase 2: Terminate all
[  ] [  ] [  ] [  ] [  ]  ← DOWNTIME

Phase 3: Start new
[v2] [v2] [v2] [v2] [v2]
```

### When to Use

- ✅ Development/test environments
- ✅ Stateful apps that can't run mixed versions
- ✅ Database migrations that break compatibility
- ✅ When downtime is acceptable

### Drawbacks

- ❌ Downtime (seconds to minutes)
- ❌ All-or-nothing deployment

### Implementation

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
spec:
  replicas: 3
  strategy:
    type: Recreate # Simple!
  selector:
    matchLabels:
      app: myapp
  template:
    metadata:
      labels:
        app: myapp
    spec:
      containers:
        - name: myapp
          image: myapp:v2.0
```

```bash
# Update deployment
kubectl apply -f deployment.yaml

# Observe behavior
kubectl get pods -w

# Output:
myapp-v1-abc  1/1  Running      0  5m
myapp-v1-def  1/1  Running      0  5m
myapp-v1-ghi  1/1  Running      0  5m
myapp-v1-abc  1/1  Terminating  0  5m
myapp-v1-def  1/1  Terminating  0  5m
myapp-v1-ghi  1/1  Terminating  0  5m
myapp-v1-abc  0/1  Terminating  0  5m
myapp-v1-def  0/1  Terminating  0  5m
myapp-v1-ghi  0/1  Terminating  0  5m
myapp-v2-jkl  0/1  Pending      0  0s
myapp-v2-mno  0/1  Pending      0  0s
myapp-v2-pqr  0/1  Pending      0  0s
myapp-v2-jkl  0/1  ContainerCreating  0  1s
myapp-v2-mno  0/1  ContainerCreating  0  1s
myapp-v2-pqr  0/1  ContainerCreating  0  1s
myapp-v2-jkl  1/1  Running      0  10s
myapp-v2-mno  1/1  Running      0  10s
myapp-v2-pqr  1/1  Running      0  10s
```

---

## 🎯 Part 7: Choosing the Right Strategy

### Decision Matrix

| Scenario                    | Recommended Strategy         | Reason                |
| --------------------------- | ---------------------------- | --------------------- |
| **Development environment** | Recreate or Rolling          | Fast, simple          |
| **Stateless web app**       | Rolling Update or Blue-Green | Zero downtime, safe   |
| **Critical production app** | Canary                       | Gradual, low risk     |
| **Microservice**            | Rolling Update               | Standard, works well  |
| **Database migration**      | Blue-Green or Recreate       | Handle schema changes |
| **Breaking API changes**    | Blue-Green with versioning   | Quick rollback        |
| **Feature testing**         | Canary or A/B                | Real user feedback    |
| **Overnight batch job**     | Recreate                     | Downtime acceptable   |

### Example Decision Tree

```
START
  │
  ▼
Can you accept downtime?
  │
  ├─ YES → Recreate ✅
  │
  └─ NO
      │
      ▼
  Is this super critical?
      │
      ├─ YES → Canary 🐦
      │
      └─ NO
          │
          ▼
      Need instant rollback?
          │
          ├─ YES → Blue-Green 🔵🟢
          │
          └─ NO → Rolling Update 🔄
```

---

## 💪 Part 8: Practical Exercise

### Exercise: Implement Multiple Deployment Strategies

**Objective**: Deploy same application using 3 different strategies

**Scenario**: You have a web application with:

- Frontend (stateless)
- API (stateless)
- Database (stateful)

**Requirements**:

1. Deploy frontend with **Blue-Green**
2. Deploy API with **Canary** (10% → 50% → 100%)
3. Deploy database with **Recreate** (maintenance window)
4. Document decision reasoning
5. Demonstrate rollback for each

**Starter Template**:

```yaml
# frontend-bluegreen.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend-blue
# TODO: Complete blue-green setup

---
# api-canary.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-baseline
# TODO: Complete canary setup

---
# database-recreate.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: database
spec:
  strategy:
    type: Recreate
# TODO: Complete recreate setup
```

**Validation Criteria**:

- [ ] Frontend: Blue and Green deployed, traffic switchable
- [ ] API: Canary at 10%, metrics monitored, promotable
- [ ] Database: Recreate strategy, downtime measured
- [ ] All: Rollback procedures documented and tested
- [ ] Decision matrix: Justify each strategy choice

---

## 🎓 Part 9: Knowledge Check

### Quiz Questions

1. **What is the main benefit of Blue-Green deployment?**

   - [ ] Lowest cost
   - [x] Instant rollback
   - [ ] No infrastructure changes
   - [ ] Automatic testing

2. **In a Rolling Update, what does maxSurge: 2 mean?**

   - [ ] Maximum 2 pods total
   - [ ] Update 2 pods per minute
   - [x] Can have 2 extra pods temporarily during update
   - [ ] Must have 2 pods available

3. **When should you use Recreate strategy?**

   - [ ] Production critical apps
   - [ ] Never, it's deprecated
   - [x] When downtime is acceptable or for incompatible versions
   - [ ] Only for initial deployment

4. **What's the primary advantage of Canary deployment?**

   - [ ] Fastest deployment
   - [ ] Simplest to implement
   - [x] Lowest risk with gradual rollout
   - [ ] Requires least infrastructure

5. **In Blue-Green, when do you delete the Blue environment?**

   - [ ] Immediately after switching
   - [ ] Never
   - [x] After Green is validated in production
   - [ ] Before deploying Green

6. **What's required for precise canary traffic control?**

   - [ ] Multiple data centers
   - [x] Advanced routing (like Istio or ingress controller)
   - [ ] Minimum 100 pods
   - [ ] Manual intervention

7. **Which strategy has the highest infrastructure cost during deployment?**

   - [x] Blue-Green
   - [ ] Rolling Update
   - [ ] Canary
   - [ ] Recreate

8. **What's the main drawback of Rolling Update?**
   - [ ] Requires downtime
   - [ ] Very complex
   - [x] Both versions run simultaneously
   - [ ] Can't rollback

**Answers**: 1-B, 2-C, 3-C, 4-C, 5-C, 6-B, 7-A, 8-C

---

## 🎯 Part 10: Module Summary & Next Steps

### What You Learned

✅ **Deployment Strategies**: Blue-Green, Rolling, Canary, Recreate
✅ **Blue-Green**: Instant rollback with parallel environments
✅ **Rolling Update**: Gradual replacement with zero downtime
✅ **Canary**: Progressive rollout with risk mitigation
✅ **Decision Making**: Choose right strategy for scenario
✅ **Implementation**: Hands-on with Kubernetes

### DORA Capabilities Achieved

- ✅ **CD2**: Automated deployment (advanced patterns)
- ✅ **Work in Small Batches**: Gradual rollouts
- ✅ **Team Experimentation**: Safe testing in production

### Key Takeaways

1. **No one-size-fits-all** - Different apps need different strategies
2. **Balance risk and complexity** - More safety = more complexity
3. **Zero downtime is achievable** - Most strategies support it
4. **Rollback is critical** - Always have an escape hatch
5. **Test in production** - Canary and Blue-Green enable this safely

### Real-World Impact

"After implementing deployment strategies:

- **Deployment confidence**: 60% → 95%
- **Production incidents from deploys**: 15 per month → 2 per month
- **Rollback time**: 30 minutes → 30 seconds (Blue-Green)
- **User impact from bad deploys**: 100% → 5% (Canary)

We now deploy during business hours with confidence."

- _Platform Team, Financial Services_

---

## 📚 Additional Resources

### Documentation

- [Kubernetes Deployment Strategies](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)
- [Istio Traffic Management](https://istio.io/latest/docs/concepts/traffic-management/)
- [Argo Rollouts](https://argoproj.github.io/argo-rollouts/)

### Tools

- [Flagger](https://flagger.app/) - Progressive delivery operator
- [Spinnaker](https://spinnaker.io/) - Multi-cloud CD platform
- [Argo Rollouts](https://github.com/argoproj/argo-rollouts) - Advanced K8s deployments

---

## 🏅 Module Completion

### Assessment Checklist

- [ ] **Conceptual Understanding**

  - [ ] Explain each deployment strategy
  - [ ] Choose appropriate strategy for scenarios
  - [ ] Understand trade-offs

- [ ] **Practical Skills**

  - [ ] Implement Blue-Green deployment
  - [ ] Configure Rolling Update parameters
  - [ ] Set up basic Canary deployment
  - [ ] Execute rollback procedures

- [ ] **Hands-On Lab**

  - [ ] Deploy using multiple strategies
  - [ ] Switch traffic between versions
  - [ ] Perform successful rollback

- [ ] **Quiz**
  - [ ] Score 80% or higher (6/8 questions)

### Certification Credit

Upon completion, you earn:

- **5 points** toward Green Belt certification (50% complete)
- **Badge**: "Deployment Strategist"
- **Skill Unlocked**: Advanced Deployment Patterns

---

## 🎖️ Green Belt Progress

```
Green Belt: GitOps & Deployment
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Module 9:  GitOps with ArgoCD     ████████░░░░ 25% ✓
Module 10: Deployment Strategies  ████████░░░░ 50% ✓
Module 11: Progressive Delivery   ░░░░░░░░░░░░  0%
Module 12: Rollback & Incident    ░░░░░░░░░░░░  0%
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**Halfway to Green Belt!** 🎉

**Next Module Preview**: Module 11 - Progressive Delivery (Automated canary analysis, metrics-driven rollout, Argo Rollouts)

---

**🎉 Congratulations!** You now know how to deploy applications safely using multiple strategies!

**Ready for Module 11?** Let's learn Progressive Delivery with automated analysis! 🚀

---

_Fawkes Dojo - Where Platform Engineers Are Forged_
_Version 1.0 | Last Updated: October 2025_
_License: MIT | https://github.com/paruff/fawkes_
