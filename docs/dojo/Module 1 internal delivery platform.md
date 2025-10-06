# Module 1: Internal Delivery Platforms - What and Why

**Belt Level**: 🥋 White Belt  
**Duration**: 60 minutes  
**Prerequisites**: Basic command line, Git, Docker knowledge  
**DORA Capabilities**: Continuous Delivery (introduction)

---

## 1. Learning Objectives (3 minutes)

### What You'll Learn

By the end of this module, you will be able to:

- ✅ Define what an Internal Delivery Platform (IDP) is and explain its core components
- ✅ Articulate why organizations need IDPs using concrete business metrics
- ✅ Explain the "Platform as a Product" mindset and its benefits
- ✅ Identify the key stakeholders and their needs in platform engineering
- ✅ Navigate the Fawkes platform and understand its architecture
- ✅ Recognize how Team Topologies concepts apply to platform teams

### Why It Matters

**The Problem**: Modern software delivery involves dozens of tools, complex configurations, and countless decisions that slow teams down. According to the 2023 State of DevOps Report:

- Elite performers deploy **417 times more frequently** than low performers
- They have a **5,788 times lower** change failure rate
- Their lead time for changes is **6,570 times faster**

**The Solution**: Internal Delivery Platforms abstract away complexity and provide "golden paths" that enable teams to move fast while maintaining quality and security.

**Your Role**: Understanding IDPs is the foundation for everything else in this dojo. You can't improve what you don't understand.

### Success Criteria

You've mastered this module when you can:

- Explain to a colleague why your organization needs a platform (in business terms)
- Navigate the Fawkes Backstage portal confidently
- Identify which Fawkes components serve which developer needs
- Articulate the difference between "platform" and "just some scripts"

---

## 2. Theory & Concepts (15 minutes)

### 📺 Video: What is an Internal Delivery Platform? (7 minutes)

> **[VIDEO PLACEHOLDER]**  
> **Script Summary**:
> - Opening: Show developer frustration with 12-step deployment process
> - Definition: IDP as "self-service platform that provides golden paths"
> - Key components: Portal, CI/CD, Observability, Infrastructure
> - Platform as Product: treating developers as customers
> - Fawkes tour: Show actual platform in action
> - Closing: "A platform that makes the right thing the easy thing"

### What is an Internal Delivery Platform?

An **Internal Delivery Platform (IDP)** is a curated set of tools, services, and self-service capabilities that application teams use to deliver and manage their software with minimal friction.

Think of it as **"paved roads for software delivery"**—just as cities build roads so citizens don't have to navigate rough terrain, platforms build golden paths so developers don't have to navigate infrastructure complexity.

#### The Three Characteristics of an IDP

1. **Self-Service**: Developers can provision resources, deploy applications, and access tools without waiting for tickets or manual intervention

2. **Curated & Opinionated**: The platform team makes thoughtful decisions about tools, patterns, and workflows, reducing cognitive load for app teams

3. **Built on Standards**: Uses industry-standard tools and practices, avoiding vendor lock-in and enabling portability

#### What an IDP is NOT

❌ **Not a PaaS**: Unlike Heroku or Cloud Foundry, IDPs give developers more control and flexibility  
❌ **Not just CI/CD**: CI/CD is one component, but IDPs include much more (observability, security, governance)  
❌ **Not "throw tools over the wall"**: True platforms treat developers as customers and measure satisfaction  
❌ **Not one-size-fits-all**: Platforms provide flexibility for different application types and team maturity levels

### The Platform as a Product Mindset

Traditional IT: *"Here are some tools. Figure it out yourself."*  
Platform Engineering: *"What do you need to be productive? Let me build that for you."*

#### Key Principles

**1. Developers are Your Customers**
- Understand their pain points through interviews and surveys
- Measure satisfaction with NPS (Net Promoter Score)
- Iterate based on feedback, not assumptions

**2. Build for the 80% Use Case**
- Provide golden paths for common scenarios
- Allow escape hatches for advanced users
- Don't try to solve every edge case immediately

**3. Measure Platform Value**
- Track adoption rates (% of teams using the platform)
- Monitor time saved (before vs. after metrics)
- Calculate cost efficiency (infrastructure + personnel)

**4. Treat It Like a Product**
- Maintain a roadmap based on customer needs
- Version releases and communicate changes
- Provide documentation and support

### Team Topologies & Enabling Teams

The book *Team Topologies* by Matthew Skelton and Manuel Pais introduces four fundamental team types. Platform teams are **Enabling Teams**.

#### The Four Team Types

1. **Stream-Aligned Teams**: Product/feature teams that deliver value to customers
2. **Enabling Teams**: Help stream-aligned teams overcome obstacles (platform teams!)
3. **Complicated Subsystem Teams**: Specialists for complex subsystems
4. **Platform Teams**: Provide internal services to reduce cognitive load

#### Platform Team Responsibilities

As a platform engineer, your job is to:

- **Reduce cognitive load**: Abstract away infrastructure complexity
- **Enable autonomy**: Give teams self-service capabilities
- **Accelerate delivery**: Remove blockers and reduce lead time
- **Ensure quality**: Build in security, testing, and observability
- **Continuously improve**: Treat the platform as a product that evolves

### Why Organizations Need IDPs

#### The Developer Productivity Crisis

Modern developers spend **70-80% of their time** on non-value-added activities:

- Waiting for environments to be provisioned
- Debugging CI/CD failures
- Figuring out deployment procedures
- Managing infrastructure configurations
- Coordinating with 5+ teams for a single deployment

#### The Business Impact

Without a platform:
- **Slower time to market**: Weeks or months to deploy new services
- **Higher operational costs**: Manual work doesn't scale
- **Increased risk**: No standardization leads to security vulnerabilities
- **Developer attrition**: Frustrated developers leave for better experiences

With a platform:
- **Faster deployments**: From weeks to minutes
- **Lower costs**: Automation reduces manual work by 60-80%
- **Better security**: Security built into golden paths
- **Happier developers**: NPS increases by 30-50 points

#### Real-World Example: Spotify

Spotify's Backstage (which Fawkes uses!) reduced their time to:
- **Provision a new service**: From 4 weeks → 5 minutes
- **Deploy to production**: From 2 hours → 10 minutes
- **Onboard a new developer**: From 2 weeks → 1 day

### Fawkes Platform Architecture

Fawkes provides a complete IDP built on industry-standard open-source tools:

```
┌─────────────────────────────────────────────────────────┐
│              Developer Experience Layer                  │
│  ┌────────────────────────────────────────────────────┐ │
│  │  Backstage Portal (Developer Portal)               │ │
│  │  • Service Catalog  • TechDocs  • Scaffolder     │ │
│  └────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────┘
                          │
┌─────────────────────────▼─────────────────────────────────┐
│                  Core Platform Services                   │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐   │
│  │   CI/CD      │  │ GitOps       │  │ Observability│   │
│  │  (Jenkins)   │  │ (ArgoCD)     │  │ (Prometheus) │   │
│  └──────────────┘  └──────────────┘  └──────────────┘   │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐   │
│  │  Artifacts   │  │  Security    │  │ Collaboration│   │
│  │  (Harbor)    │  │  (Trivy)     │  │ (Mattermost) │   │
│  └──────────────┘  └──────────────┘  └──────────────┘   │
└───────────────────────────────────────────────────────────┘
                          │
┌─────────────────────────▼─────────────────────────────────┐
│            Infrastructure & Orchestration                 │
│  ┌────────────────────────────────────────────────────┐  │
│  │  Kubernetes Clusters (AWS EKS)                     │  │
│  │  • Multi-environment (dev, staging, prod)         │  │
│  │  • Multi-tenant namespaces                        │  │
│  │  • Infrastructure as Code (Terraform)             │  │
│  └────────────────────────────────────────────────────┘  │
└───────────────────────────────────────────────────────────┘
```

#### Key Fawkes Components

| Component | Purpose | Technology |
|-----------|---------|------------|
| **Backstage** | Developer portal, service catalog | Backstage by Spotify |
| **Jenkins** | CI/CD pipelines | Jenkins with K8s agents |
| **ArgoCD** | GitOps continuous deployment | ArgoCD |
| **Harbor** | Container registry | Harbor registry |
| **Prometheus/Grafana** | Metrics & monitoring | Prometheus stack |
| **OpenSearch** | Log aggregation & search | OpenSearch |
| **Jaeger** | Distributed tracing | Jaeger |
| **Mattermost** | Team collaboration | Mattermost |
| **Focalboard** | Project tracking | Focalboard |

### Common Pitfalls & How to Avoid Them

#### ❌ Pitfall 1: Building in Isolation
**Problem**: Platform team builds what they *think* developers need without asking them.  
**Solution**: Conduct regular developer interviews, track NPS, dogfood your own platform.

#### ❌ Pitfall 2: Too Much Control
**Problem**: Platform so restrictive that developers route around it.  
**Solution**: Provide golden paths for 80% of cases, escape hatches for edge cases.

#### ❌ Pitfall 3: No Documentation
**Problem**: Great platform, but no one knows how to use it.  
**Solution**: Documentation is a first-class feature. Use TechDocs, record videos, provide examples.

#### ❌ Pitfall 4: Ignoring Feedback
**Problem**: Developers complain but nothing changes.  
**Solution**: Public roadmap, regular releases, visible responsiveness to feedback.

#### ❌ Pitfall 5: No Metrics
**Problem**: Can't prove platform value to leadership.  
**Solution**: Track DORA metrics, adoption rates, time saved, cost efficiency.

---

## 3. Demonstration (10 minutes)

### 📺 Video: Fawkes Platform Tour (10 minutes)

> **[VIDEO PLACEHOLDER]**  
> **Script**: Instructor walks through Fawkes platform showing:
> 
> 1. **Backstage Home** (1 min)
>    - Overview page, quick links
>    - Component search
> 
> 2. **Service Catalog** (2 min)
>    - Browse services
>    - View service details (APIs, docs, owner)
>    - Dependencies visualization
> 
> 3. **TechDocs** (1 min)
>    - Navigate documentation
>    - Search functionality
> 
> 4. **Create New Service** (2 min)
>    - Click "Create" → choose template
>    - Fill in service details
>    - Show generated repository
> 
> 5. **DORA Dashboard** (2 min)
>    - View deployment frequency
>    - Lead time for changes
>    - Show live metrics
> 
> 6. **CI/CD View** (2 min)
>    - Jenkins integration
>    - Pipeline status
>    - Build logs
> 
> **Key Message**: "Notice how everything you need is in one place. No jumping between 12 different tools."

### Key Takeaways from Demo

1. **Single Pane of Glass**: All your tools accessible from Backstage
2. **Self-Service**: Create new services in minutes, not weeks
3. **Discoverability**: Find services, docs, and owners easily
4. **Visibility**: See deployments, metrics, and health in real-time
5. **Standardization**: Every service follows the same patterns

---

## 4. Hands-On Lab (20 minutes)

### Lab Overview

You'll explore the Fawkes Backstage portal, navigate the service catalog, and understand the platform architecture by completing a scavenger hunt.

**Time Estimate**: 15-20 minutes  
**Difficulty**: Beginner  
**Auto-Graded**: Yes  
**Points**: 50

### Lab Environment

When you click "Start Lab", we'll provision:
- ✅ Access to Fawkes demo environment
- ✅ Read-only access to sample services
- ✅ Your personal lab notebook (Markdown file)
- ✅ Credentials in your Backstage profile

**Environment will be available for 24 hours from start time.**

### Lab Instructions

#### Part 1: Navigate Backstage (15 points)

1. **Access Backstage** (3 points)
   - Click "Start Lab" button below
   - Log in with your dojo credentials
   - Find the "Home" page
   
   ✅ **Validation**: We'll check that you logged in successfully

2. **Explore the Catalog** (6 points)
   - Click "Catalog" in the left sidebar
   - Find a service called `sample-spring-boot-app`
   - Open its details page
   - Find and click "View Source" to see its GitHub repo
   
   ✅ **Validation**: We'll check that you visited the service page

3. **View Documentation** (6 points)
   - While on the `sample-spring-boot-app` page, click "Docs" tab
   - Read the "Getting Started" documentation
   - Notice the "Edit on GitHub" link
   
   ✅ **Validation**: We'll check that you accessed TechDocs

#### Part 2: Understand Service Details (20 points)

4. **Identify Service Owner** (5 points)
   - On the `sample-spring-boot-app` page, find the "About" section
   - Note the owner (person or team)
   - Find the Mattermost channel for support
   
   📝 **Submit**: Who owns this service? (Type answer in lab notebook)

5. **Explore Dependencies** (5 points)
   - Click the "Dependencies" tab
   - Identify what APIs this service depends on
   
   📝 **Submit**: How many dependencies does this service have?

6. **Check CI/CD Status** (5 points)
   - Click the "CI/CD" tab
   - View the latest Jenkins pipeline run
   - Note whether the build passed or failed
   
   📝 **Submit**: What was the status of the last build?

7. **Review DORA Metrics** (5 points)
   - Navigate to "DORA Metrics" from the left sidebar
   - Find the deployment frequency for the last 7 days
   - Note the lead time for changes
   
   📝 **Submit**: What is the deployment frequency? (e.g., "5 per week")

#### Part 3: Platform Architecture Understanding (15 points)

8. **Identify Platform Components** (10 points)
   - Navigate to "Platform Services" from the left sidebar
   - You should see tiles for Jenkins, ArgoCD, Harbor, Grafana, etc.
   - Click on each one to see its status
   
   📝 **Submit**: List the 5 platform services you found (comma-separated)

9. **Explore a Deployment** (5 points)
   - Click on "ArgoCD" tile to open ArgoCD
   - Browse the applications
   - Find the `sample-spring-boot-app` in the list
   
   📝 **Submit**: What is the sync status of the sample app in ArgoCD?

### Lab Submission

Once you've completed all tasks:

1. Open your lab notebook (automatically created in your namespace)
2. Ensure all answers are recorded
3. Click "Submit Lab" button in Backstage

**Auto-grading will run within 1 minute.** You'll see:
- ✅ Checks that passed (green)
- ❌ Checks that failed (red) with hints
- Final score out of 50 points
- Option to retry if score < 40

### Troubleshooting Hints

**Can't log in to Backstage?**
- Verify you're using your dojo username (not email)
- Try incognito/private browsing mode
- Check #dojo-support in Mattermost

**Can't find a service?**
- Use the search bar (top right)
- Check that catalog loaded (refresh if empty)
- Try filtering by "Kind: Component"

**ArgoCD or other tools not opening?**
- Some links open in new tabs (check pop-up blocker)
- You may need to accept security warnings (self-signed certs in demo environment)

**Lab not grading?**
- Ensure you clicked "Submit Lab" button
- Wait up to 60 seconds for auto-grading
- Check that all required answers are in your lab notebook

---

## 5. Knowledge Check (5 minutes)

### Quiz: Internal Delivery Platforms Fundamentals

**Instructions**: Answer all 10 questions. You need 8/10 (80%) to pass. Unlimited attempts allowed.

#### Question 1
**What is the primary purpose of an Internal Delivery Platform?**

- [ ] A) Replace all existing tools with a single monolithic system
- [x] B) Provide self-service golden paths that reduce cognitive load for developers
- [ ] C) Control everything developers do to enforce policies
- [ ] D) Eliminate the need for DevOps or platform engineers

**Explanation**: IDPs are about **enabling developers** through self-service and curated tools, not controlling or replacing everything.

---

#### Question 2
**According to Team Topologies, what type of team is a platform team?**

- [ ] A) Stream-aligned team
- [x] B) Enabling team
- [ ] C) Complicated subsystem team
- [ ] D) Infrastructure team

**Explanation**: Platform teams are **enabling teams** that help stream-aligned teams overcome obstacles and reduce cognitive load.

---

#### Question 3
**What does "Platform as a Product" mean?**

- [ ] A) Selling your platform to external customers
- [x] B) Treating internal developers as customers and measuring their satisfaction
- [ ] C) Using product management tools to track platform development
- [ ] D) Making the platform a commercial product

**Explanation**: It means treating **developers as customers**, understanding their needs, and measuring satisfaction—just like a real product.

---

#### Question 4
**Which of these is NOT a characteristic of a well-designed IDP?**

- [ ] A) Self-service capabilities
- [ ] B) Opinionated but flexible
- [x] C) Forces all teams to use exactly the same tools with no exceptions
- [ ] D) Built on industry standards

**Explanation**: Good platforms are **opinionated but provide escape hatches**. Forcing everyone into identical workflows leads to teams routing around the platform.

---

#### Question 5
**What is Backstage in the Fawkes platform?**

- [ ] A) The CI/CD pipeline tool
- [x] B) The developer portal that provides a single pane of glass
- [ ] C) The Kubernetes orchestration system
- [ ] D) The monitoring and observability tool

**Explanation**: **Backstage is the developer portal**—the single interface where developers access all platform services.

---

#### Question 6
**Why do organizations invest in Internal Delivery Platforms?**

- [ ] A) Because it's a trendy thing to do
- [ ] B) To give platform teams more control
- [x] C) To accelerate delivery, reduce costs, and improve developer experience
- [ ] D) To replace cloud providers

**Explanation**: IDPs deliver **business value** through faster delivery, lower costs, better security, and improved developer satisfaction.

---

#### Question 7
**What does "golden path" mean in platform engineering?**

- [x] A) The recommended, easy-to-follow path for common use cases
- [ ] B) The most expensive way to deploy applications
- [ ] C) A strict requirement that all teams must follow
- [ ] D) The path used only by senior engineers

**Explanation**: A **golden path** is the easy, paved road for the 80% use case—making the right thing the easy thing.

---

#### Question 8
**Which metric is NOT typically used to measure platform success?**

- [ ] A) Developer Net Promoter Score (NPS)
- [ ] B) Platform adoption rate
- [ ] C) Time saved per deployment
- [x] D) Number of tickets closed by the platform team

**Explanation**: Platform success is about **developer outcomes** (NPS, adoption, time saved), not just operational metrics like ticket volume.

---

#### Question 9
**In Fawkes, which tool is responsible for GitOps-based deployments?**

- [ ] A) Jenkins
- [x] B) ArgoCD
- [ ] C) Harbor
- [ ] D) Backstage

**Explanation**: **ArgoCD** manages GitOps-style continuous deployment, syncing Git repos to Kubernetes clusters.

---

#### Question 10
**What is a common pitfall when building an IDP?**

- [x] A) Building in isolation without talking to developers
- [ ] B) Using industry-standard open-source tools
- [ ] C) Providing documentation and examples
- [ ] D) Measuring platform adoption and satisfaction

**Explanation**: Building **without developer input** is the #1 pitfall—you end up solving the wrong problems.

---

### Quiz Results

**Score: X / 10**

- ✅ **Passed** (8+): Great job! You're ready to move to the next section.
- ❌ **Not Yet** (<8): Review the content and try again. Focus on areas you missed.

**Incorrect answers?** Each question links back to the relevant section for review.

---

## 6. Reflection & Next Steps (5 minutes)

### What You Learned

Congratulations! 🎉 You've completed Module 1. Let's recap:

✅ **You now understand**:
- What an Internal Delivery Platform is and why it matters
- The "Platform as a Product" mindset
- How Team Topologies applies to platform teams
- The Fawkes platform architecture and components
- How to navigate Backstage and find information

✅ **You can now**:
- Explain the business value of IDPs to colleagues
- Navigate the Fawkes Backstage portal confidently
- Identify the core components of the platform
- Find service owners, documentation, and dependencies

### How This Connects to Your Work

**For Developers**:
- You now understand why your company invested in a platform
- You know where to find docs, who to ask for help, and how to deploy apps
- You can take advantage of golden paths instead of reinventing the wheel

**For Platform Engineers**:
- You understand your role as an "enabling team"
- You know how to treat developers as customers
- You can articulate the value of the platform to stakeholders

**For Leaders**:
- You can explain how platforms accelerate delivery and reduce costs
- You understand the metrics that matter (DORA, NPS, adoption)
- You can make the case for platform investments

### Reflection Questions

Take 2 minutes to think about:

1. **What surprised you most about IDPs?**
   - Was there a concept that changed your perspective?

2. **How does your current workflow compare?**
   - Are you using a platform? Doing things manually? Somewhere in between?

3. **What would improve your developer experience?**
   - If you could wave a magic wand, what would you change?

4. **Who could benefit from this knowledge?**
   - Think of 2-3 colleagues who should go through this module

### Additional Resources

**📚 Further Reading**:
- [Team Topologies Book](https://teamtopologies.com) - Foundation for platform thinking
- [Backstage Documentation](https://backstage.io/docs/overview/what-is-backstage) - Learn more about Backstage
- [Platform Engineering Community](https://platformengineering.org) - Join the community
- [DORA Research](https://dora.dev) - Dive into the research behind DORA metrics

**🎥 Videos to Watch**:
- "What is Platform Engineering?" by Luca Galante (10 min)
- "Spotify's Backstage Journey" (15 min)
- "Building a Platform as a Product" by Camille Fournier (30 min)

**💬 Community**:
- Join `#dojo-white-belt` in Mattermost
- Share your "aha!" moments
- Help others who are just starting

### Preview: Module 2

**Next Up: DORA Metrics - The North Star**

In Module 2, you'll learn:
- The Four Key Metrics (Deployment Frequency, Lead Time, MTTR, Change Failure Rate)
- Why these metrics matter to your business
- How Fawkes automatically tracks DORA metrics
- How to interpret your team's metrics and drive improvement

**Time**: 60 minutes  
**Hands-On**: Build your first DORA dashboard

**Get Ready**: Think about your team's current deployment process. How long does it take? How often do you deploy? How often do deployments fail?

---

## Module Completion

### ✅ You've Completed Module 1!

**Next Steps**:
1. ✅ Mark this module complete in your Backstage profile
2. 📊 View your progress on the Dojo dashboard
3. 💬 Share your completion in `#dojo-achievements` (optional but encouraged!)
4. ➡️ **Continue to Module 2** when ready

**Time Investment**: 60 minutes  
**Skills Gained**: Platform fundamentals, Backstage navigation  
**Progress**: 1 of 4 modules toward White Belt (25% complete)

---

**Questions or Issues?**
- 💬 Ask in `#dojo-white-belt` on Mattermost
- 📧 Email: dojo@fawkes.io
- 🐛 Report bugs: [GitHub Issues](https://github.com/paruff/fawkes/issues)

**Feedback?**
- Rate this module (takes 30 seconds)
- Suggest improvements
- Help us make the dojo better!

---

**Module Author**: Fawkes Learning Team  
**Last Updated**: October 2025  
**Version**: 1.0