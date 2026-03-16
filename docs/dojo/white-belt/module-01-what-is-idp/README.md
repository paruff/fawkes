# Module 1: What is an Internal Delivery Platform?

**Belt Level**: 🥋 White Belt
**Estimated Time**: 60 minutes (15 min theory + 45 min hands-on lab)
**Prerequisites**: Basic command line, Git, and Kubernetes knowledge
**DORA Capability**: Continuous Delivery (introduction)

---

## Learning Objectives

By the end of this module, you will be able to:

- ✅ Define what an Internal Delivery Platform (IDP) is and explain its core components
- ✅ Articulate why organisations need IDPs using concrete DORA metrics
- ✅ Explain the "Platform as a Product" mindset and its benefits
- ✅ Navigate the Fawkes platform (Backstage portal, ArgoCD, Grafana)
- ✅ Deploy a sample service using the Fawkes golden path template
- ✅ Verify end-to-end delivery: code → ArgoCD → Kubernetes → observability

---

## Module Structure

| Section | Time | Description |
|---------|------|-------------|
| Theory | 15 min | What is an IDP, DORA metrics, Platform as a Product |
| Lab 01 | 45 min | Deploy `hello-fawkes` via golden path template |

---

## Theory Summary (15 minutes)

### What is an Internal Delivery Platform?

An **Internal Delivery Platform (IDP)** is a curated set of tools, services, and
self-service capabilities that application teams use to deliver and manage their
software with minimal friction.

Think of it as **"paved roads for software delivery"** — just as cities build roads
so citizens do not have to navigate rough terrain, platforms build golden paths so
developers do not have to navigate infrastructure complexity.

#### The Three Characteristics of an IDP

1. **Self-Service** — developers provision resources and deploy without waiting for tickets
2. **Curated & Opinionated** — the platform team makes thoughtful tool and pattern decisions
3. **Built on Standards** — uses industry-standard tools to avoid vendor lock-in

### Why DORA Metrics Matter

According to the 2024 State of DevOps Report, elite performers compared to low performers:

- Deploy **973 times more frequently**
- Have a **6,570 times faster** lead time for changes
- Have a **3 times lower** change failure rate

An IDP is the mechanism that moves teams from low to elite performance by removing
toil, enforcing quality gates, and providing golden paths.

### The Fawkes Platform Components

| Component | Purpose |
|-----------|---------|
| **Backstage** | Developer portal — service catalog, TechDocs, golden path templates |
| **ArgoCD** | GitOps — syncs Git state to Kubernetes automatically |
| **Prometheus + Grafana** | Observability — metrics, dashboards, alerting |
| **Vault** | Secrets management |
| **k3d** | Local Kubernetes cluster for development |

---

## Lab

➡️ **[Lab 01: Deploy a Service via Golden Path Template](lab-01/instructions.md)**

This lab walks you through deploying a sample service (`hello-fawkes`) using the
Fawkes platform. You will apply Kubernetes manifests, register the service in
Backstage, and verify the full delivery pipeline end-to-end.

**Validation**: `make dojo-validate BELT=white MODULE=01 LAB=01`

---

## Success Criteria

You have mastered this module when you can:

- Explain to a colleague why your organisation needs a platform (in business terms)
- Navigate the Fawkes Backstage portal and find a service's TechDocs
- Deploy a new service using the golden path template and confirm it is healthy
- Describe how ArgoCD keeps Git and cluster state in sync

---

## Next Steps

After completing this module, proceed to:

➡️ **Module 02: DORA Metrics — Measuring Delivery Performance**
