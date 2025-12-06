---
title: Measure DORA Metrics
description: Analyze your service's performance using DORA metrics in Apache DevLake
---

# Measure DORA Metrics

**Time to Complete**: 25-30 minutes  
**Goal**: Understand how your service contributes to team DORA metrics and use data to drive improvements.

## What You'll Learn

By the end of this tutorial, you will have:

1. ✅ Understood the four key DORA metrics
2. ✅ Configured your service for DORA metric collection
3. ✅ Viewed your service's metrics in Apache DevLake dashboards
4. ✅ Analyzed trends and identified improvement opportunities
5. ✅ Understood how Fawkes automates DORA data collection

## Prerequisites

Before you begin, ensure you have:

- [ ] Completed [Tutorial 1: Deploy Your First Service](1-deploy-first-service.md)
- [ ] Your `hello-fawkes` service deployed and operational
- [ ] Access to Grafana (typically at `https://grafana.127.0.0.1.nip.io`)
- [ ] Access to DevLake (typically at `https://devlake.127.0.0.1.nip.io`)
- [ ] At least a few deployments of your service (from previous tutorials)

!!! info "What are DORA Metrics?"
    DORA (DevOps Research and Assessment) identified four key metrics that predict software delivery performance:
    1. **Deployment Frequency** - How often you deploy to production
    2. **Lead Time for Changes** - Time from commit to production
    3. **Change Failure Rate** - % of deployments causing failures
    4. **Time to Restore Service** - Time to recover from failures
    
    [Learn more about DORA capabilities](../capabilities.md).

## Step 1: Understand DORA Metrics

Let's review what each metric measures and why it matters.

### Deployment Frequency

**Definition**: How often an organization successfully releases to production.

**Elite Performance**: Multiple deploys per day  
**Industry Average**: Between once per week and once per month

**Why it matters**: 
- High frequency = smaller changes
- Smaller changes = lower risk
- Lower risk = faster feedback

### Lead Time for Changes

**Definition**: Time from code committed to code successfully running in production.

**Elite Performance**: Less than one hour  
**Industry Average**: Between one week and one month

**Why it matters**:
- Short lead time = fast feedback
- Fast feedback = rapid iteration
- Rapid iteration = better products

### Change Failure Rate

**Definition**: Percentage of changes that result in a failure in production.

**Elite Performance**: 0-15%  
**Industry Average**: 31-45%

**Why it matters**:
- Low failure rate = stable releases
- Stable releases = customer trust
- Customer trust = business success

### Time to Restore Service

**Definition**: Time it takes to recover from a failure in production.

**Elite Performance**: Less than one hour  
**Industry Average**: Less than one day

**Why it matters**:
- Fast recovery = minimized impact
- Minimized impact = satisfied customers
- Satisfied customers = retained revenue

!!! success "Checkpoint"
    You understand what DORA metrics are and why they matter.

## Step 2: Access DevLake Dashboard

Apache DevLake is Fawkes' data platform for DORA metrics.

1. Navigate to DevLake in your browser:
   ```
   https://devlake.127.0.0.1.nip.io
   ```

2. Log in with your credentials (ask your platform team if you don't have them).

3. You should see the main dashboard with:
   - Projects list
   - DORA metrics overview
   - Trend graphs

4. Navigate to **Dashboards** → **DORA Dashboard**.

5. Use the filters to select your service:
   - Project: `my-first-app`
   - Repository: `hello-fawkes`
   - Time Range: Last 30 days

!!! tip "No Data Yet?"
    If this is your first deployment, you may not see much data yet. That's okay! We'll generate more data in this tutorial.

!!! success "Checkpoint"
    You can access the DevLake DORA dashboard and filter by your service.

## Step 3: Configure Data Collection

Fawkes automatically collects most DORA data, but let's verify the configuration.

1. Check that your ArgoCD application has DORA annotations.

   View `argocd-app.yaml`:
   ```yaml
   apiVersion: argoproj.io/v1alpha1
   kind: Application
   metadata:
     name: hello-fawkes
     namespace: argocd
     annotations:
       # DORA metric annotations
       dora/team: "platform-team"
       dora/service: "hello-fawkes"
       notifications.argoproj.io/subscribe.on-deployed.devlake: "webhook"
   spec:
     # ... rest of spec
   ```

2. If annotations are missing, add them:
   ```bash
   kubectl annotate application hello-fawkes -n argocd \
     dora/team=platform-team \
     dora/service=hello-fawkes \
     notifications.argoproj.io/subscribe.on-deployed.devlake=webhook
   ```

3. Verify ArgoCD notifications are configured:
   ```bash
   kubectl get configmap argocd-notifications-cm -n argocd -o yaml
   ```
   
   Should include a DevLake webhook trigger.

4. Check that your GitHub repository is connected:
   - In DevLake UI, go to **Data Connections**
   - Verify `hello-fawkes` repository is listed
   - If not, add it following the platform team's instructions

!!! success "Checkpoint"
    Your service is configured for automatic DORA data collection.

## Step 4: Generate Deployment Data

Let's create some deployments to populate the metrics.

1. Make a small code change to `server.js`:
   ```javascript
   app.get('/', (req, res) => {
     res.json({
       message: 'Hello from Fawkes!',
       timestamp: new Date().toISOString(),
       version: '4.0.0',  // Bump version
       tracing: 'enabled',
       secrets: 'managed by Vault',
       dora: 'tracking enabled'  // New field
     });
   });
   ```

2. Commit and push:
   ```bash
   git add server.js
   git commit -m "Add DORA tracking indicator"
   git push
   ```

3. This triggers:
   - Git webhook to DevLake (Lead Time starts)
   - ArgoCD sync (Deployment happens)
   - Deployment notification to DevLake (Deployment Frequency recorded)

4. Wait for ArgoCD to sync (check in ArgoCD UI or CLI):
   ```bash
   kubectl get application hello-fawkes -n argocd -w
   ```

5. Make a few more changes to generate more data points:
   ```bash
   # Change 2
   git commit --allow-empty -m "Trigger deployment 2"
   git push
   
   # Wait 5 minutes
   
   # Change 3
   git commit --allow-empty -m "Trigger deployment 3"
   git push
   ```

!!! info "Why Multiple Deployments?"
    DORA metrics are trends, not single data points. The more deployments you have, the more meaningful the metrics become.

!!! success "Checkpoint"
    You've generated deployment data for DORA analysis.

## Step 5: View Deployment Frequency

Let's analyze how often you're deploying.

1. In DevLake, navigate to **DORA Dashboard** → **Deployment Frequency**.

2. You should see:
   - A timeline graph showing deployments over time
   - Total deployments in the selected period
   - Average deployments per day/week
   - Trend: Increasing, Stable, or Decreasing

3. Filter by your service (`hello-fawkes`).

4. Compare to team average and industry benchmarks.

5. Example insights:
   - "We deployed 3 times this week"
   - "Our average is 0.6 deployments per day"
   - "We're at 'Medium' performance tier (weekly deploys)"
   - "Goal: Reach 'High' tier (daily deploys)"

!!! tip "Interpreting the Data"
    - **Elite**: On-demand (multiple per day)
    - **High**: Between once per day and once per week
    - **Medium**: Between once per week and once per month
    - **Low**: Less than once per month

!!! success "Checkpoint"
    You can view and interpret your deployment frequency metrics.

## Step 6: Analyze Lead Time for Changes

Now let's see how long it takes from commit to production.

1. In DevLake, navigate to **DORA Dashboard** → **Lead Time for Changes**.

2. The dashboard shows:
   - Median lead time (p50)
   - 95th percentile lead time (p95)
   - Breakdown by stage:
     - Code commit to PR creation
     - PR creation to approval
     - PR approval to merge
     - Merge to deployment

3. Click on a specific deployment to see its journey:
   ```
   Commit: 2025-12-06 10:00:00
   ├─ PR Created: +5 minutes
   ├─ PR Approved: +10 minutes
   ├─ PR Merged: +2 minutes
   └─ Deployed: +3 minutes
   
   Total Lead Time: 20 minutes ✅ Elite
   ```

4. Identify bottlenecks:
   - If "PR approval" takes hours → Need faster reviews
   - If "Merge to deploy" is slow → Optimize CI/CD pipeline
   - If "Commit to PR" is long → Smaller changesets

!!! info "Lead Time Stages"
    Fawkes tracks each stage separately so you can identify exactly where delays occur.

!!! success "Checkpoint"
    You understand your lead time and where time is spent.

## Step 7: Monitor Change Failure Rate

Let's see how often deployments cause problems.

1. In DevLake, navigate to **DORA Dashboard** → **Change Failure Rate**.

2. The dashboard shows:
   - Percentage of failed deployments
   - Failed vs. successful deployments over time
   - Correlation with deployment frequency

3. What counts as a "failure"?
   - Deployment rollback
   - Hotfix deployed within 24 hours
   - Production incident tagged to a deployment
   - Pod crash loops after deployment

4. Example analysis:
   - "3 deployments, 0 failures = 0% failure rate ✅ Elite"
   - Or: "10 deployments, 3 failures = 30% failure rate ⚠️ Medium"

5. If you have failures, click to see details:
   - Which commit caused the failure?
   - What was the error?
   - How long until it was fixed?

!!! tip "Improving Change Failure Rate"
    - Increase test coverage
    - Add canary deployments
    - Implement feature flags
    - Improve staging environment parity

!!! success "Checkpoint"
    You can track how often your deployments fail.

## Step 8: Measure Time to Restore Service

Finally, let's look at recovery time when failures do occur.

1. In DevLake, navigate to **DORA Dashboard** → **Mean Time to Restore**.

2. The dashboard shows:
   - Average time from incident detection to resolution
   - Trend over time
   - Incidents by severity

3. What counts as an "incident"?
   - Service downtime (health check failures)
   - Error rate spike
   - Performance degradation
   - Manual incident creation in PagerDuty/Mattermost

4. Example incident timeline:
   ```
   Incident Detected: 2025-12-06 14:00:00 (Automated alert)
   ├─ Team Notified: +1 minute (Mattermost alert)
   ├─ Diagnosis Started: +5 minutes (Engineer joined)
   ├─ Fix Identified: +10 minutes (Found bad config)
   ├─ Rollback Initiated: +2 minutes (ArgoCD rollback)
   └─ Service Restored: +3 minutes (Health checks pass)
   
   Total MTTR: 21 minutes ✅ Elite
   ```

5. If you don't have incidents yet (great!), you can simulate one:
   ```bash
   # Break the service temporarily
   kubectl scale deployment hello-fawkes -n my-first-app --replicas=0
   
   # Wait 2 minutes for alert
   
   # Restore service
   kubectl scale deployment hello-fawkes -n my-first-app --replicas=2
   ```

!!! warning "Simulated Incidents"
    Only simulate incidents in development/staging. Never in production!

!!! success "Checkpoint"
    You can measure how quickly your team recovers from incidents.

## Step 9: Create a DORA Improvement Plan

Based on your metrics, create an action plan.

1. In DevLake or Grafana, export your current DORA metrics:
   - Deployment Frequency: X per week
   - Lead Time: X minutes
   - Change Failure Rate: X%
   - MTTR: X minutes

2. Identify your current performance tier:
   - Elite, High, Medium, or Low for each metric

3. Choose one metric to improve first:
   - Pick the one farthest from Elite
   - Or the one with the biggest business impact

4. Set a SMART goal:
   - **Specific**: Increase deployment frequency
   - **Measurable**: From 3/week to 1/day
   - **Achievable**: By automating tests
   - **Relevant**: Faster feedback to customers
   - **Time-bound**: Within 30 days

5. Track progress:
   - Review DORA dashboard weekly
   - Adjust tactics based on data
   - Celebrate improvements!

!!! success "Checkpoint"
    You have a data-driven plan to improve your DORA metrics.

## What You've Accomplished

Congratulations! You've successfully:

- ✅ Understood the four key DORA metrics
- ✅ Configured your service for metric collection
- ✅ Viewed metrics in DevLake dashboards
- ✅ Analyzed deployment frequency, lead time, failure rate, and MTTR
- ✅ Created an improvement plan based on data

## Key Insights

Through this tutorial, you've learned:

1. **DORA metrics are objective** - No more arguing about "good" or "bad" deployment practices
2. **Fawkes automates collection** - No manual tracking or surveys needed
3. **Trends matter more than absolutes** - Focus on improving, not perfection
4. **All four metrics work together** - Optimizing one at the expense of others doesn't work
5. **Elite performance is achievable** - With the right platform and practices

## What's Next?

Continue your Fawkes journey:

1. **Review all tutorials** - Ensure you've completed 1-6
2. **Join the Dojo** - Progress through belt levels for deeper learning
3. **Share your metrics** - Discuss with your team and set collective goals
4. **Contribute back** - Share your DORA improvement story with the community

## Troubleshooting

### No Data in DevLake

```bash
# Check DevLake is running
kubectl get pods -n fawkes-platform -l app=devlake

# Verify GitHub connection
# In DevLake UI: Data Connections → GitHub

# Check ArgoCD notifications
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-notifications-controller
```

### Metrics Seem Wrong

- Verify time zone settings in DevLake
- Check that repository is correctly tagged
- Ensure ArgoCD sync policies are correct
- Review incident tagging criteria

### Can't See My Service

- Confirm ArgoCD application has DORA annotations
- Verify repository is connected in DevLake
- Check that commits are being detected
- Wait 5-10 minutes for data pipeline to process

## Learn More

- **[DORA Capabilities](../capabilities.md)** - All 24 capabilities that drive DORA metrics
- **[How to View DORA Metrics](../how-to/observability/view-dora-metrics-devlake.md)** - Advanced DevLake usage
- **[Accelerate Book](https://itrevolution.com/product/accelerate/)** - The research behind DORA metrics
- **[State of DevOps Report](https://cloud.google.com/devops/state-of-devops)** - Annual DORA research

## Feedback

What did you learn from your DORA metrics? What surprised you? Share your insights in the [Fawkes Community Mattermost](https://fawkes-community.mattermost.com)!

---

## 🎉 You've Completed All Six Tutorials!

Congratulations on completing the entire Fawkes tutorial series! You now have:

- ✅ Deployed a service to Fawkes
- ✅ Added distributed tracing
- ✅ Implemented Vault secret management
- ✅ Migrated to Cloud Native Buildpacks
- ✅ Created a Golden Path template
- ✅ Measured and analyzed DORA metrics

### Next Steps

1. **[Join the Dojo](../dojo/modules/white-belt/module-01-what-is-idp.md)** - Start your White Belt journey
2. **[Explore How-To Guides](../how-to/index.md)** - Solve specific problems
3. **[Read Explanations](../explanation/index.md)** - Deepen your understanding
4. **[Contribute](../contributing.md)** - Help improve Fawkes

### Share Your Success

- Post your achievement in Mattermost
- Write a blog post about your experience
- Help others complete the tutorials
- Contribute improvements to the docs

**Thank you for learning with Fawkes!** 🚀
