# Module 4: Your First Deployment

**Belt Level**: 🥋 White Belt
**Duration**: 60 minutes
**Prerequisites**: Modules 1, 2, and 3 completed
**DORA Capabilities**: Continuous Delivery, Deployment Automation

---

## 1. Learning Objectives (3 minutes)

### What You'll Learn

By the end of this module, you will be able to:

- ✅ Deploy an application using Fawkes golden path templates
- ✅ Navigate the deployment pipeline from code to production
- ✅ Monitor deployment progress through Backstage, Jenkins, and ArgoCD
- ✅ Verify application health and accessibility
- ✅ Understand how DORA metrics are automatically captured
- ✅ Troubleshoot common deployment issues

### Why It Matters

**The Milestone**: This is the moment you've been building toward—your first end-to-end deployment on the Fawkes platform.

**Real-World Impact**: According to DORA research, organizations that master deployment automation:
- Deploy **417 times more frequently** than low performers
- Have **5,788 times lower** change failure rates
- Reduce lead time from **months to minutes**

**Your Journey**: In the next hour, you'll experience what elite performers do dozens of times per day—safely deploying code to production with full observability.

### Success Criteria

You've mastered this module when you can:

- Deploy an application end-to-end without assistance
- Explain each stage of the deployment pipeline
- Find and interpret deployment logs across tools
- Identify when a deployment succeeded or failed
- Access your deployed application

---

## 2. Theory & Concepts (15 minutes)

### 📺 Video: The Fawkes Deployment Pipeline (7 minutes)

> **[VIDEO PLACEHOLDER]**
> **Script Summary**:
> - Opening: Show the full deployment pipeline diagram
> - Code commit → Jenkins build → Harbor registry → ArgoCD sync
> - Each stage explained with real-time visualization
> - Observability: Where to find logs and metrics at each stage
> - DORA metrics: How they're automatically captured
> - Closing: "From commit to production in minutes, not months"

### The Fawkes Deployment Pipeline

When you deploy on Fawkes, your code flows through a carefully orchestrated pipeline:

```
Developer → Git → Jenkins → Harbor → ArgoCD → Kubernetes → 🎉
   You     SCM    CI/CD    Registry  GitOps   Cluster    Live!
```

Let's break down each stage:

#### Stage 1: Code Commit (Git)

**What Happens**: You push code to a Git repository (GitHub, GitLab, etc.)

**Behind the Scenes**:
- Git webhook triggers Jenkins
- Commit SHA becomes the version identifier
- Timestamp recorded (start of lead time measurement)

**Your Role**: `git push origin main`

**Time**: < 1 second

---

#### Stage 2: Build & Test (Jenkins)

**What Happens**: Jenkins automatically builds and tests your code

**Behind the Scenes**:
1. **Checkout**: Jenkins clones your repository
2. **Build**: Compiles code, runs tests
3. **Security Scan**: Checks for vulnerabilities (Trivy)
4. **Quality Check**: SonarQube analysis (if configured)
5. **Package**: Creates container image
6. **Push**: Uploads image to Harbor registry

**Your Role**: None! It's automated by the golden path pipeline.

**Time**: 3-8 minutes (depending on project size)

**Success Indicators**:
- ✅ All tests pass
- ✅ No critical security vulnerabilities
- ✅ Code quality meets threshold
- ✅ Container image tagged with commit SHA

---

#### Stage 3: Registry Storage (Harbor)

**What Happens**: Your container image is stored in Harbor registry

**Behind the Scenes**:
- Image tagged: `harbor.fawkes.local/myapp:abc123`
- Vulnerability scan runs automatically
- Image signed (cryptographic verification)
- Available for deployment

**Your Role**: None! Fully automated.

**Time**: < 30 seconds

**Important**: The image is immutable—same image moves through all environments (dev → staging → prod). This ensures consistency.

---

#### Stage 4: GitOps Deployment (ArgoCD)

**What Happens**: ArgoCD detects the new image and deploys to Kubernetes

**Behind the Scenes**:
1. **Detection**: ArgoCD polls Git repository every 3 minutes (or webhook triggers immediately)
2. **Sync**: Compares desired state (Git) with actual state (Kubernetes)
3. **Apply**: Creates/updates Kubernetes resources
4. **Health Check**: Monitors pod startup and readiness
5. **Metrics**: Records deployment event for DORA metrics

**Your Role**: Review sync status in ArgoCD UI

**Time**: 1-5 minutes (depending on pod startup time)

**Success Indicators**:
- ✅ Sync status: "Synced"
- ✅ Health status: "Healthy"
- ✅ Pods running: All replicas ready

---

#### Stage 5: Running Application (Kubernetes)

**What Happens**: Your application runs in Kubernetes, accessible via ingress

**Behind the Scenes**:
- Pods scheduled across nodes for HA
- Service provides stable network endpoint
- Ingress routes traffic from external load balancer
- Probes monitor health (liveness, readiness)
- Metrics collected by Prometheus
- Logs shipped to OpenSearch
- Traces sent to Grafana Tempo

**Your Role**: Access application, verify functionality

**Time**: Immediate once pods are ready

**Success Indicators**:
- ✅ Application responds to requests
- ✅ Health check endpoints return 200 OK
- ✅ No errors in logs

---

### Golden Path Templates

Fawkes provides **golden path templates**—pre-configured application scaffolds that include everything you need:

**What's Included**:
- ✅ Application code structure
- ✅ Dockerfile (container image build)
- ✅ Jenkinsfile (CI/CD pipeline)
- ✅ Kubernetes manifests (deployment, service, ingress)
- ✅ Helm chart (configuration management)
- ✅ README with instructions
- ✅ Automated testing setup
- ✅ Monitoring and observability configuration

**Why Golden Paths?**
- **Consistency**: Every app follows the same patterns
- **Best Practices**: Security, testing, monitoring built-in
- **Speed**: Start from working example, customize as needed
- **Learning**: See how the pieces fit together

**Available Templates** (in Fawkes MVP):
- `spring-boot-api`: Java REST API with Spring Boot
- `python-flask-api`: Python REST API with Flask
- `nodejs-express-api`: Node.js REST API with Express
- `static-website`: Static HTML/CSS/JS site

---

### DORA Metrics: Automatic Capture

Every deployment automatically updates your DORA metrics:

**Deployment Frequency**:
- Incremented when ArgoCD successfully syncs to production
- Visible in real-time on DORA dashboard

**Lead Time for Changes**:
- Start: Git commit timestamp
- End: ArgoCD sync completion timestamp
- Calculated automatically, no manual tracking

**Change Failure Rate**:
- If deployment rolls back within 24 hours → counted as failure
- If incident created within 24 hours of deploy → counted as failure
- Visible as percentage on dashboard

**Mean Time to Restore (MTTR)**:
- Start: Incident created timestamp
- End: Incident resolved timestamp (successful deploy or rollback)
- Only measured if incident occurs

**No Manual Work Required**: The platform captures everything automatically.

---

### Common Deployment Patterns

#### Pattern 1: Direct to Production (MVP)
```
Git → Jenkins → Harbor → ArgoCD → Production
```
**When to Use**: MVP, small teams, low-risk changes
**Risk Level**: Medium (no staging environment)

#### Pattern 2: Dev → Production (Recommended)
```
Git → Jenkins → Harbor → ArgoCD → Dev → Production
```
**When to Use**: Small teams, moderate risk
**Risk Level**: Low (dev environment for testing)

#### Pattern 3: Full Pipeline (Enterprise)
```
Git → Jenkins → Harbor → ArgoCD → Dev → Staging → Production
```
**When to Use**: Large teams, high-risk changes, compliance requirements
**Risk Level**: Very Low (multiple validation stages)

**Fawkes MVP**: Uses Pattern 1 or 2 by default. Pattern 3 configured in production.

---

### Troubleshooting: Where to Look

**Build Failed**:
- **Where**: Jenkins build logs
- **How**: Click on build number in Jenkins UI
- **Common Issues**: Test failures, dependency errors, Docker build errors

**Image Scan Failed**:
- **Where**: Harbor UI → Images → Scan Results
- **How**: Click on image tag, view vulnerabilities
- **Common Issues**: Critical CVEs in base image or dependencies

**Deployment Failed**:
- **Where**: ArgoCD UI → Application → Events
- **How**: Check sync status and pod events
- **Common Issues**: Image pull errors, insufficient resources, configuration errors

**Application Not Responding**:
- **Where**: Kubernetes pod logs, Grafana dashboards
- **How**: `kubectl logs <pod-name>` or Backstage component view
- **Common Issues**: Application crashes, database connection failures, port misconfigurations

---

## 3. Demonstration (10 minutes)

### 📺 Video: Deploying the Sample Application (10 minutes)

> **[VIDEO PLACEHOLDER]**
> **Script**: Instructor performs a complete deployment showing:
>
> **Part 1: Create from Template (2 min)**
> - Open Backstage
> - Click "Create" → "Choose a template"
> - Select "Spring Boot API" template
> - Fill in details: name, description, repository
> - Click "Create"
> - Show generated repository in GitHub
>
> **Part 2: Trigger Build (2 min)**
> - Show Jenkins detecting the new repository
> - Build starts automatically
> - Walk through build stages in Jenkins UI
> - Show build logs for each stage
> - Highlight test results and security scan
>
> **Part 3: Image Registry (1 min)**
> - Switch to Harbor UI
> - Show new image with commit SHA tag
> - Open vulnerability scan results
> - Explain image signing
>
> **Part 4: ArgoCD Deployment (3 min)**
> - Open ArgoCD UI
> - Show application appearing in list
> - Watch sync in real-time
> - Explain "Out of Sync" → "Syncing" → "Synced" → "Healthy"
> - Show Kubernetes resources created
>
> **Part 5: Access Application (1 min)**
> - Get application URL from Backstage
> - Open in browser, show it works
> - Make a test API call
>
> **Part 6: Observe Metrics (1 min)**
> - Open DORA dashboard
> - Show deployment frequency incremented
> - Show lead time calculated
> - Point out where to find logs, traces, metrics

### Key Takeaways from Demo

1. **It's Fast**: From template creation to live app in ~10 minutes
2. **It's Automated**: You push code, platform handles the rest
3. **It's Observable**: Every stage visible in appropriate tool
4. **It's Safe**: Multiple quality gates (tests, scans, health checks)
5. **It's Measurable**: DORA metrics update automatically

---

## 4. Hands-On Lab (25 minutes)

### Lab Overview

You'll deploy your first application on Fawkes using a golden path template, monitor its progress through the pipeline, and verify it's running successfully.

**Time Estimate**: 20-25 minutes
**Difficulty**: Beginner
**Auto-Graded**: Yes
**Points**: 100

### Lab Environment

When you click "Start Lab", we'll provision:
- ✅ Access to Backstage (create templates)
- ✅ Git repository for your application
- ✅ Jenkins pipeline (automatic)
- ✅ ArgoCD application (automatic)
- ✅ Kubernetes namespace: `dojo-learner-{username}`
- ✅ Application URL (via ingress)

**Environment will be available for 24 hours from start time.**

### Lab Instructions

#### Part 1: Create Application from Template (5 minutes)

**Step 1**: Access Backstage

```bash
# Your lab credentials will be displayed here after clicking "Start Lab"
# Navigate to: https://backstage.fawkes-dojo.internal
```

**Step 2**: Create New Component

1. Click **"Create"** in the left sidebar
2. Click **"Choose a template"**
3. Select **"Spring Boot REST API"** template
4. Click **"Choose"**

**Step 3**: Fill in Application Details

- **Name**: `my-first-app` (use your username if `my-first-app` is taken)
- **Description**: `My first deployment on Fawkes`
- **Owner**: Select your username from dropdown
- **Repository**: `github.com/fawkes-dojo/{your-username}/my-first-app`

Click **"Next"**

**Step 4**: Review and Create

- Review the repository location
- Click **"Create"**
- Wait for template to be generated (~30 seconds)
- Click **"Open in catalog"** when complete

✅ **Validation**: We'll check that you created a component in Backstage

📝 **Submit**: Component name and URL

---

#### Part 2: Monitor the Build (8 minutes)

**Step 5**: Find Your Jenkins Build

1. In Backstage, on your component page, click the **"CI/CD"** tab
2. You should see a Jenkins build triggered automatically
3. Click on the build number (e.g., "#1")
4. This opens Jenkins UI

**Step 6**: Watch Build Progress

Observe the build stages:
1. **Checkout**: Jenkins clones your repository
2. **Build**: Compiles code, runs tests
3. **Test**: Executes unit tests
4. **Security Scan**: Trivy scans for vulnerabilities
5. **Docker Build**: Creates container image
6. **Push to Harbor**: Uploads image

**Wait for build to complete** (~5-8 minutes). You can move to the next part while waiting.

**Step 7**: Review Build Results

Once complete, note:
- Build status (hopefully "Success" ✅)
- Build duration
- Test results (how many tests ran, passed/failed)
- Security scan results (vulnerabilities found)

✅ **Validation**: We'll check that your build completed successfully

📝 **Submit**: Build number and status

---

#### Part 3: Verify Image in Harbor (3 minutes)

**Step 8**: Access Harbor Registry

1. Navigate to: `https://harbor.fawkes-dojo.internal`
2. Log in with your dojo credentials
3. Click on **"Projects"** → **"dojo-apps"**
4. Find your application: `my-first-app`

**Step 9**: Inspect Image

1. Click on your app name
2. You should see one image tagged with commit SHA (e.g., `abc123`)
3. Click on the tag
4. Review vulnerability scan results
5. Note the image size and creation time

✅ **Validation**: We'll check that your image exists in Harbor

📝 **Submit**: Image tag (commit SHA)

---

#### Part 4: Monitor ArgoCD Deployment (5 minutes)

**Step 10**: Access ArgoCD

1. Return to Backstage, click **"Deployment"** tab
2. Click **"Open in ArgoCD"** link
3. Or navigate directly to: `https://argocd.fawkes-dojo.internal`

**Step 11**: Watch Deployment Sync

1. Find your application: `my-first-app`
2. Observe sync status:
   - **Out of Sync**: ArgoCD detected new image
   - **Syncing**: Applying changes to Kubernetes
   - **Synced**: Desired state matches actual state
3. Observe health status:
   - **Progressing**: Pods starting
   - **Healthy**: All pods ready
4. Click on your app to see detailed view

**Step 12**: Inspect Kubernetes Resources

In ArgoCD detailed view, you should see:
- **Deployment**: Your application deployment
- **Service**: Network endpoint for your app
- **Ingress**: External URL routing
- **Pods**: Individual application instances (should be 2 replicas)

Wait for all resources to show **"Healthy"** status.

✅ **Validation**: We'll check that your app is synced and healthy in ArgoCD

📝 **Submit**: ArgoCD sync status and health status

---

#### Part 5: Access Your Application (4 minutes)

**Step 13**: Get Application URL

1. In Backstage, on your component page, find the **"Links"** section
2. Click on **"Application URL"**
3. Or construct manually: `https://my-first-app.dojo-learner-{username}.fawkes-dojo.internal`

**Step 14**: Test Application

Your Spring Boot app exposes these endpoints:

```bash
# Health check
curl https://my-first-app.dojo-learner-{username}.fawkes-dojo.internal/actuator/health

# Should return:
# {"status":"UP"}

# Sample API endpoint
curl https://my-first-app.dojo-learner-{username}.fawkes-dojo.internal/api/hello

# Should return:
# {"message":"Hello from Fawkes!","timestamp":"2025-10-08T..."}
```

**Step 15**: Verify in Browser

1. Open application URL in browser
2. You should see a welcome page
3. Navigate to `/swagger-ui.html` to see API documentation

✅ **Validation**: We'll check that your application responds with HTTP 200

📝 **Submit**: Screenshot of application running in browser OR response from `/actuator/health`

---

#### Part 6: Review DORA Metrics (3 minutes)

**Step 16**: Check Your Metrics

1. In Backstage, click **"DORA Metrics"** in left sidebar
2. Filter by your component: `my-first-app`
3. Observe:
   - **Deployment Frequency**: Should show 1 deployment
   - **Lead Time**: Time from commit to deployment (likely 10-15 minutes)
   - **Change Failure Rate**: Should be 0% (successful deployment)
   - **MTTR**: N/A (no incidents)

**Step 17**: Explore Observability

1. Click **"Logs"** tab → Opens OpenSearch Dashboards
   - Search for: `kubernetes.namespace_name:"dojo-learner-{username}"`
   - You should see application startup logs
2. Click **"Metrics"** tab → Opens Grafana
   - View pod CPU, memory, network metrics
3. Click **"Traces"** tab → Opens Grafana Tempo
   - View distributed traces (if application makes external calls)

✅ **Validation**: We'll check that metrics were recorded

📝 **Submit**: Your lead time for changes (in minutes)

---

### Lab Submission

Once you've completed all parts:

1. Ensure all answers are recorded in your lab notebook
2. Double-check that your application is still running
3. Click **"Submit Lab"** button in Backstage

**Grading**:
- Part 1 (Component created): 15 points
- Part 2 (Build completed): 20 points
- Part 3 (Image in Harbor): 15 points
- Part 4 (ArgoCD synced): 20 points
- Part 5 (App responding): 20 points
- Part 6 (Metrics recorded): 10 points

**Passing score**: 80/100 (80%)

**Auto-grading runs within 2 minutes.** You'll see:
- ✅ Checks that passed (green)
- ❌ Checks that failed (red) with hints
- Final score
- Option to retry if score < 80

---

### Troubleshooting Hints

**Build Failed in Jenkins?**
- Click on build number → "Console Output"
- Look for red error messages
- Common fix: Tests might fail on first run; click "Rebuild"

**Image Not in Harbor?**
- Check Jenkins logs for "Push to Harbor" stage
- Verify Jenkins completed successfully
- Wait 1-2 minutes after build completes

**ArgoCD Stuck "Out of Sync"?**
- Click "Refresh" in ArgoCD
- If still stuck, click "Sync" → "Synchronize"
- ArgoCD polls every 3 minutes; you can force manual sync

**Pods Not Starting?**
- In ArgoCD, click on pod → "Logs"
- Look for error messages (image pull errors, crashes)
- Common issue: Image tag mismatch (check Harbor vs. deployment manifest)

**Application Not Responding?**
- Verify pods are "Running" in ArgoCD
- Check pod logs for errors
- Verify ingress configuration (ArgoCD → Ingress resource)

**Can't Access Application URL?**
- Verify ingress is "Healthy" in ArgoCD
- Check ingress annotations
- Try health check endpoint first: `/actuator/health`

---

## 5. Knowledge Check (5 minutes)

### Quiz: First Deployment Mastery

**Instructions**: Answer all 10 questions. You need 8/10 (80%) to pass. Unlimited attempts allowed.

#### Question 1
**What triggers a Jenkins build in the Fawkes platform?**

- [ ] A) Manual button click in Backstage
- [x] B) Git webhook when code is pushed
- [ ] C) Scheduled cron job every hour
- [ ] D) ArgoCD detecting a configuration change

**Explanation**: When you push code to Git, a **webhook automatically triggers Jenkins** to start the CI/CD pipeline. This ensures every code change is built and tested.

---

#### Question 2
**In which component is your container image stored after the build?**

- [ ] A) Jenkins
- [x] B) Harbor
- [ ] C) ArgoCD
- [ ] D) Kubernetes

**Explanation**: **Harbor** is the container registry where Docker images are stored after Jenkins builds them. Harbor also scans images for vulnerabilities.

---

#### Question 3
**What does ArgoCD do in the deployment pipeline?**

- [ ] A) Builds the container image
- [ ] B) Runs unit tests
- [x] C) Deploys applications to Kubernetes using GitOps
- [ ] D) Scans code for security vulnerabilities

**Explanation**: **ArgoCD implements GitOps**—it continuously monitors Git repositories and ensures Kubernetes cluster state matches the desired state defined in Git.

---

#### Question 4
**What is a "golden path template" in Fawkes?**

- [ ] A) The fastest route to production
- [x] B) A pre-configured application scaffold with best practices built-in
- [ ] C) A deployment checklist
- [ ] D) A security policy document

**Explanation**: **Golden path templates** are pre-built application templates that include everything needed for CI/CD, monitoring, and deployment—so you can start from a working example.

---

#### Question 5
**When is the "lead time for changes" measurement started?**

- [x] A) When code is committed to Git
- [ ] B) When Jenkins build starts
- [ ] C) When ArgoCD begins syncing
- [ ] D) When pods become ready

**Explanation**: Lead time starts at the **Git commit timestamp** and ends when the deployment completes. This measures how long code waits in your process.

---

#### Question 6
**What does it mean when ArgoCD shows "Out of Sync"?**

- [ ] A) The application is broken
- [ ] B) Jenkins build failed
- [x] C) Desired state (Git) differs from actual state (Kubernetes)
- [ ] D) The database is down

**Explanation**: "Out of Sync" means **Git has changes that aren't yet applied to Kubernetes**. ArgoCD will automatically sync, or you can trigger it manually.

---

#### Question 7
**How can you verify your application is healthy after deployment?**

- [ ] A) Check if ArgoCD shows "Synced"
- [ ] B) Call the application's health endpoint
- [ ] C) Look at pod status in ArgoCD
- [x] D) All of the above

**Explanation**: You should verify **all three**: ArgoCD sync status, pod health, and application response. A healthy deployment shows green across all checks.

---

#### Question 8
**Where do you find logs if your application crashes after deployment?**

- [ ] A) Jenkins build logs
- [ ] B) Harbor scan results
- [x] C) Kubernetes pod logs (via ArgoCD or kubectl)
- [ ] D) Git commit history

**Explanation**: **Pod logs** show application runtime errors. Access them via ArgoCD UI → click pod → "Logs", or use `kubectl logs <pod-name>`.

---

#### Question 9
**What does Jenkins do during the "Security Scan" stage?**

- [ ] A) Tests application functionality
- [x] B) Scans container image for known vulnerabilities
- [ ] C) Checks code style
- [ ] D) Deploys to production

**Explanation**: Jenkins uses **Trivy to scan container images** for CVEs (Common Vulnerabilities and Exposures) in base images and dependencies.

---

#### Question 10
**Why does the same container image move through all environments (dev → staging → prod)?**

- [ ] A) To save disk space
- [ ] B) To make builds faster
- [x] C) To ensure consistency—what you test is what you deploy
- [ ] D) It's a Fawkes requirement, not a best practice

**Explanation**: **Immutable deployments** mean the exact same artifact (container image) progresses through environments. You never rebuild for production—you promote the tested image.

---

### Quiz Results

**Score: X / 10**

- ✅ **Passed** (8+): Excellent! You understand the deployment pipeline.
- ❌ **Not Yet** (<8): Review the theory section and try again.

**Incorrect answers?** Each question links back to the relevant section for review.

---

## 6. Reflection & Next Steps (5 minutes)

### What You Learned

Congratulations! 🎉 You've completed your first deployment on Fawkes. Let's recap:

✅ **You now know**:
- The complete deployment pipeline from code to production
- How Jenkins, Harbor, ArgoCD, and Kubernetes work together
- Where to find logs, metrics, and traces at each stage
- How DORA metrics are automatically captured
- What golden path templates provide
- How to troubleshoot common deployment issues

✅ **You can now**:
- Deploy applications end-to-end without assistance
- Monitor deployment progress across multiple tools
- Verify application health and functionality
- Interpret success/failure at each pipeline stage

### How This Connects to Your Work

**For Developers**:
- You can now deploy code multiple times per day
- No more waiting for ops team to deploy for you
- Immediate feedback on every change
- Full visibility into deployment status

**For Platform Engineers**:
- You understand how the golden path works
- You can help teams troubleshoot deployment issues
- You see how observability is built into the pipeline

**For Leaders**:
- You've seen how automation enables high deployment frequency
- You understand how DORA metrics are captured automatically
- You can articulate the business value of the platform

### Real-World Application Exercise

**This Week, Try This**:

1. **Deploy a Real Feature**
   - Pick a small feature or bug fix from your backlog
   - Deploy it using the Fawkes platform
   - Measure your lead time (commit to production)

2. **Compare Before and After**
   - How long did deployments take before Fawkes?
   - How long now?
   - Calculate time saved

3. **Share Your Experience**
   - Demo your deployed app to your team (5 min standup)
   - Show the DORA metrics dashboard
   - Discuss: "What would we need to deploy 10x per day?"

### Reflection Questions

Take 2 minutes to think about:

1. **What surprised you most?**
   - Was the deployment faster or slower than expected?
   - Which part was easiest? Hardest?

2. **What would you change?**
   - If you could modify the golden path template, what would you add?
   - What additional automation would be helpful?

3. **What's your next deployment?**
   - What will you deploy next on Fawkes?
   - Can you deploy to production confidently now?

4. **How does this compare to your current process?**
   - What manual steps does Fawkes eliminate?
   - What new capabilities does it provide?

### Additional Resources

**📚 Further Reading**:
- [Deployment Strategies](https://docs.fawkes.io/deployment-strategies) - Blue-green, canary, rolling
- [Golden Path Templates](https://docs.fawkes.io/templates) - Creating custom templates
- [Troubleshooting Guide](https://docs.fawkes.io/troubleshooting) - Common issues and fixes
- [GitOps Best Practices](https://www.weave.works/technologies/gitops/) - ArgoCD patterns

**🎥 Videos to Watch**:
- "Advanced Deployment Patterns" (15 min)
- "Customizing Golden Path Templates" (20 min)
- "Zero-Downtime Deployments" (10 min)

**🛠️ Hands-On Practice**:
- Deploy the Python Flask template
- Deploy the Node.js Express template
- Customize a template (add database, change ports)
- Practice rolling back a deployment

**💬 Community**:
- Share your first deployment in `#dojo-achievements`
- Help others in `#dojo-white-belt`
- Ask questions in daily office hours

### Preview: White Belt Assessment

**You've Completed All 4 White Belt Modules!**

Next up is the **White Belt Assessment** (2 hours):
- Deploy 2 additional applications (different languages)
- Written exam (30 questions covering modules 1-4)
- Practical troubleshooting scenario
- Passing score: 80%

**What You'll Need to Do**:
1. Deploy a Python application
2. Deploy a Node.js application
3. Troubleshoot a broken deployment
4. Answer questions on platform concepts
5. Demonstrate DORA metrics knowledge

**Get Ready**:
- Review all 4 modules
- Practice deploying different templates
- Make sure you understand the full pipeline
- Be comfortable with troubleshooting

**When You're Ready**: Click "Start White Belt Assessment" in your Dojo dashboard.

---

## Module Completion

### ✅ You've Completed Module 4!

**Next Steps**:
1. ✅ Mark this module complete in your Backstage profile
2. 📊 View your progress on the Dojo dashboard
3. 💬 Share your first deployment in `#dojo-achievements`!
4. ➡️ **Prepare for White Belt Assessment** when ready

**Time Investment**: 60 minutes
**Skills Gained**: End-to-end deployment, pipeline understanding, troubleshooting
**Progress**: 4 of 4 modules complete (100% - Ready for White Belt Assessment!)

**Deployment Count**: 1 🚀
**Lead Time**: ~15 minutes (from commit to production)
**DORA Metrics**: Automatically captured ✅

---

**Questions or Issues?**
- 💬 Ask in `#dojo-white-belt` on Mattermost
- 📧 Email: dojo@fawkes.io
- 🐛 Report bugs: [GitHub Issues](https://github.com/paruff/fawkes/issues)

**Feedback?**
- Rate this module (takes 30 seconds)
- What worked well? What could be better?
- Help us improve the learning experience!

---

**Module Author**: Fawkes Learning Team
**Last Updated**: October 2025
**Version**: 1.0

**🎉 Congratulations on your first deployment! You're well on your way to becoming a platform engineering expert.**