# Fawkes Dojo Module 15: SLIs, SLOs, and Error Budgets

## 🎯 Module Overview

**Belt Level**: 🟤 Brown Belt - Observability & SRE
**Module**: 3 of 4 (Brown Belt)
**Duration**: 60 minutes
**Difficulty**: Advanced
**Prerequisites**:
- Module 13: Observability complete
- Module 14: DORA Metrics Deep Dive complete
- Understanding of Prometheus and monitoring
- Basic statistics knowledge (percentiles, averages)

---

## 📚 Learning Objectives

By the end of this module, you will:

1. ✅ Define Service Level Indicators (SLIs) for your services
2. ✅ Create meaningful Service Level Objectives (SLOs)
3. ✅ Calculate and track error budgets
4. ✅ Implement SLI/SLO monitoring in Prometheus
5. ✅ Balance innovation velocity with reliability
6. ✅ Make data-driven decisions about service reliability
7. ✅ Communicate service health to stakeholders

**DORA Capabilities Addressed**:
- ✓ Monitoring and Observability
- ✓ Service Reliability
- ✓ Data-Driven Decision Making
- ✓ Customer Focus

---

## 📖 Part 1: The Reliability Framework

### Why SLIs/SLOs Matter

**Without SLIs/SLOs**:
```
Team: "Our service is pretty reliable"
Customer: "It's been down twice this week!"
PM: "Can we deploy this risky feature?"
Ops: "I don't know, maybe?"

Result:
- No shared understanding of reliability
- Arbitrary decisions about risk
- Customer dissatisfaction
- Team stress and conflict
```

**With SLIs/SLOs**:
```
Team: "We have 99.9% availability (SLO) and we're at 99.95%"
Customer: "Within SLO, acceptable"
PM: "We have error budget remaining, let's deploy"
Ops: "Budget shows we can tolerate this risk"

Result:
- Shared language for reliability
- Data-driven risk decisions
- Customer expectations managed
- Team alignment
```

### The SRE Hierarchy

```
┌─────────────────────────────────────┐
│     User Happiness (Ultimate Goal)  │
└───────────────┬─────────────────────┘
                │
┌───────────────▼─────────────────────┐
│   Service Level Indicators (SLIs)   │
│   What we measure (metrics)         │
└───────────────┬─────────────────────┘
                │
┌───────────────▼─────────────────────┐
│  Service Level Objectives (SLOs)    │
│  Targets for SLIs (promises)        │
└───────────────┬─────────────────────┘
                │
┌───────────────▼─────────────────────┐
│       Error Budget                   │
│  Allowed unreliability (innovation)  │
└─────────────────────────────────────┘
```

---

## 🎯 Part 2: Service Level Indicators (SLIs)

### What is an SLI?

**SLI**: A carefully selected metric that represents user happiness

**Good SLI characteristics**:
- ✅ User-centric (measures what users care about)
- ✅ Measurable (can be quantified)
- ✅ Actionable (team can improve it)
- ✅ Aggregatable (can combine across services)

### Common SLI Types

#### 1. Availability (Uptime)

**Definition**: Proportion of time service is operational

```promql
# Availability SLI
sum(up{service="myapp"}) / count(up{service="myapp"}) * 100

# Example: 99.5% availability
```

**User impact**: "Can I access the service?"

#### 2. Latency (Speed)

**Definition**: Time to respond to requests

```promql
# Latency SLI (p95)
histogram_quantile(0.95,
  sum(rate(http_request_duration_seconds_bucket{service="myapp"}[5m])) by (le)
)

# Example: p95 < 200ms
```

**User impact**: "How fast does it respond?"

#### 3. Error Rate (Correctness)

**Definition**: Proportion of requests that fail

```promql
# Error rate SLI
sum(rate(http_requests_total{service="myapp",status=~"5.."}[5m]))
/
sum(rate(http_requests_total{service="myapp"}[5m]))
* 100

# Example: 0.1% error rate
```

**User impact**: "Does it work correctly?"

#### 4. Throughput (Capacity)

**Definition**: Requests handled per unit time

```promql
# Throughput SLI
sum(rate(http_requests_total{service="myapp"}[5m]))

# Example: 1000 req/s
```

**User impact**: "Can it handle my load?"

#### 5. Durability (Data Safety)

**Definition**: Proportion of data successfully stored/retrieved

```promql
# Durability SLI
sum(successful_writes) / sum(total_writes) * 100

# Example: 99.999% durability
```

**User impact**: "Is my data safe?"

### Selecting SLIs for Your Service

**Step 1: Identify User Journeys**

Example: E-commerce checkout

```
User Journey: Purchase Product
1. Browse catalog
2. Add to cart
3. Enter payment
4. Complete purchase
5. Receive confirmation
```

**Step 2: Map to SLIs**

| Journey Step | SLI | Target | Why It Matters |
|--------------|-----|--------|----------------|
| Browse catalog | Latency | p95 < 300ms | Slow browsing = abandoned |
| Add to cart | Availability | 99.9% | Can't shop if cart broken |
| Enter payment | Error rate | < 0.1% | Payment errors = lost sales |
| Complete purchase | Latency | p99 < 1s | Checkout must be fast |
| Receive confirmation | Availability | 99.99% | Legal requirement |

**Step 3: Prioritize**

Focus on 3-5 most critical SLIs:
1. **Checkout error rate** (revenue impact)
2. **Checkout latency** (abandonment risk)
3. **Catalog availability** (engagement)

---

## 📊 Part 3: Service Level Objectives (SLOs)

### What is an SLO?

**SLO**: A target value or range for an SLI over a time window

**Format**: `SLI ≥ Target over Time Window`

**Examples**:
- Availability ≥ 99.9% over 30 days
- p95 latency ≤ 200ms over 7 days
- Error rate < 0.5% over 30 days

### Setting Good SLOs

#### Rule 1: Align with User Expectations

**Bad**: "5 nines (99.999%) because we're perfectionists"
**Good**: "99.9% because user research shows this meets needs"

**User tolerance** varies by context:
- Search engine: p95 < 100ms (users expect instant)
- Banking transfer: p95 < 2s (users tolerate some delay)
- Batch report: p95 < 30s (users expect processing time)

#### Rule 2: Start Conservative, Tighten Over Time

**Initial SLO**: 99.5% availability
- Monitor for 3 months
- Actual: 99.7%
- **Tighten**: 99.6% (between actual and previous)

**Why**: Easier to exceed SLO and tighten than miss and relax

#### Rule 3: Fewer is Better

**Bad**: 15 SLOs for one service
**Good**: 3-5 SLOs that matter most

**Example**:
```
Service: Payment API
SLOs:
1. Availability ≥ 99.95% (30 days)
2. p95 latency ≤ 500ms (7 days)
3. Error rate < 0.1% (30 days)
```

#### Rule 4: Document Your SLOs

```yaml
# slo-definition.yaml
service: payment-api
slos:
  - name: availability
    description: "Proportion of successful requests"
    type: availability
    target: 99.95
    window: 30d
    sli: |
      sum(http_requests_total{status!~"5.."})
      / sum(http_requests_total) * 100

  - name: latency
    description: "95th percentile response time"
    type: latency
    target: 500ms
    window: 7d
    sli: |
      histogram_quantile(0.95,
        sum(rate(http_duration_bucket[5m])) by (le)
      )

  - name: error_rate
    description: "Proportion of failed requests"
    type: error_rate
    target: 0.1
    window: 30d
    sli: |
      sum(rate(http_requests_total{status=~"5.."}[5m]))
      / sum(rate(http_requests_total[5m])) * 100
```

### Multi-Window SLOs

Track SLOs over different time windows:

```
Service: API
SLO: 99.9% availability

Windows:
- 1 hour:  99.99% ✅ (shorter window, stricter)
- 1 day:   99.95% ✅
- 7 days:  99.92% ✅
- 30 days: 99.91% ✅ (meets SLO)
```

**Benefit**: Early warning system
- Hour/day violations = potential trend
- 30-day still met = no customer impact yet

---

## 💰 Part 4: Error Budgets

### What is an Error Budget?

**Error Budget**: Allowed unreliability based on SLO

**Formula**: `Error Budget = 100% - SLO`

**Example**:
```
SLO: 99.9% availability
Error Budget: 0.1% (100% - 99.9%)

In a 30-day month:
- Total time: 30 days = 43,200 minutes
- Error budget: 0.1% × 43,200 = 43.2 minutes
- Allowed downtime: ~43 minutes per month
```

### Error Budget as Currency

Think of error budget as **innovation currency**:

```
Monthly Error Budget: 43 minutes

Spent on:
- Planned maintenance: 10 minutes
- Feature deploy issues: 15 minutes
- Infrastructure failure: 8 minutes
- Security patching: 5 minutes
─────────────────────────────────────
Total spent: 38 minutes
Remaining: 5 minutes (healthy) ✅
```

### Burn Rate

**Burn Rate**: How fast you're consuming error budget

**Formula**: `Burn Rate = (Error Rate / Error Budget) × Time Window`

**Example**:
```
Current error rate: 0.5%
Error budget: 0.1%
Burn rate: 0.5% / 0.1% = 5x

At this rate:
- 30-day budget consumed in 6 days
- Action required! 🚨
```

### Error Budget Policies

Define policies for budget exhaustion:

```yaml
error_budget_policy:
  - condition: "50% remaining"
    action: "Continue normal operations"

  - condition: "25% remaining"
    action:
      - "Freeze non-critical feature deploys"
      - "Increase monitoring"
      - "Review recent changes"

  - condition: "10% remaining"
    action:
      - "Freeze ALL feature deploys"
      - "Focus on reliability improvements"
      - "Daily team review"
      - "Incident commander assigned"

  - condition: "0% remaining (exhausted)"
    action:
      - "Complete deploy freeze"
      - "Root cause analysis required"
      - "Reliability sprint"
      - "Executive notification"
```

---

## 🛠️ Part 5: Hands-On Lab - Implementing SLIs/SLOs

### Step 1: Define SLIs

Create `sli-definitions.yaml`:

```yaml
# Service: payment-api
slis:
  # Availability SLI
  - name: availability
    description: "Percentage of successful HTTP requests"
    query: |
      sum(rate(http_requests_total{service="payment-api",status!~"5.."}[5m]))
      /
      sum(rate(http_requests_total{service="payment-api"}[5m]))
      * 100
    unit: percent

  # Latency SLI (p95)
  - name: latency_p95
    description: "95th percentile HTTP request duration"
    query: |
      histogram_quantile(0.95,
        sum(rate(http_request_duration_seconds_bucket{service="payment-api"}[5m])) by (le)
      ) * 1000
    unit: milliseconds

  # Latency SLI (p99)
  - name: latency_p99
    description: "99th percentile HTTP request duration"
    query: |
      histogram_quantile(0.99,
        sum(rate(http_request_duration_seconds_bucket{service="payment-api"}[5m])) by (le)
      ) * 1000
    unit: milliseconds

  # Error Rate SLI
  - name: error_rate
    description: "Percentage of failed HTTP requests"
    query: |
      sum(rate(http_requests_total{service="payment-api",status=~"5.."}[5m]))
      /
      sum(rate(http_requests_total{service="payment-api"}[5m]))
      * 100
    unit: percent
```

### Step 2: Define SLOs

Create `slo-definitions.yaml`:

```yaml
# Service: payment-api
slos:
  # Availability SLO
  - name: availability_slo
    sli: availability
    objective: 99.9
    window: 30d
    description: "Service available 99.9% of the time over 30 days"
    alert_threshold: 99.8  # Alert when approaching SLO breach

  # Latency SLO (p95)
  - name: latency_p95_slo
    sli: latency_p95
    objective: 500  # milliseconds
    window: 7d
    description: "95% of requests complete within 500ms over 7 days"
    alert_threshold: 600

  # Error Rate SLO
  - name: error_rate_slo
    sli: error_rate
    objective: 0.1  # 0.1% error rate
    window: 30d
    description: "Error rate below 0.1% over 30 days"
    alert_threshold: 0.15
```

### Step 3: Calculate Error Budget

Create `error-budget-calculator.yaml`:

```yaml
# Prometheus recording rules for error budget
groups:
  - name: error_budget
    interval: 1m
    rules:
      # Availability error budget
      - record: error_budget:availability:remaining_percent
        expr: |
          (
            100 -
            (
              (100 - slo:availability:30d) -
              (100 - sli:availability:30d)
            ) / (100 - slo:availability:30d) * 100
          )

      # Availability error budget consumed
      - record: error_budget:availability:consumed_percent
        expr: |
          100 - error_budget:availability:remaining_percent

      # Availability burn rate (1 hour)
      - record: error_budget:availability:burn_rate_1h
        expr: |
          (100 - sli:availability:1h) / (100 - slo:availability:30d)

      # Availability burn rate (6 hours)
      - record: error_budget:availability:burn_rate_6h
        expr: |
          (100 - sli:availability:6h) / (100 - slo:availability:30d)

      # Error rate error budget
      - record: error_budget:error_rate:remaining_percent
        expr: |
          (
            1 - (sli:error_rate:30d / slo:error_rate:30d)
          ) * 100
```

### Step 4: Create Prometheus Recording Rules

Create `prometheus-rules.yaml`:

```yaml
groups:
  - name: sli_recording
    interval: 30s
    rules:
      # Availability SLI (real-time)
      - record: sli:availability:current
        expr: |
          sum(rate(http_requests_total{service="payment-api",status!~"5.."}[1m]))
          /
          sum(rate(http_requests_total{service="payment-api"}[1m]))
          * 100

      # Availability SLI (1 hour)
      - record: sli:availability:1h
        expr: |
          sum(rate(http_requests_total{service="payment-api",status!~"5.."}[1h]))
          /
          sum(rate(http_requests_total{service="payment-api"}[1h]))
          * 100

      # Availability SLI (30 days)
      - record: sli:availability:30d
        expr: |
          sum(rate(http_requests_total{service="payment-api",status!~"5.."}[30d]))
          /
          sum(rate(http_requests_total{service="payment-api"}[30d]))
          * 100

      # Error rate SLI (30 days)
      - record: sli:error_rate:30d
        expr: |
          sum(rate(http_requests_total{service="payment-api",status=~"5.."}[30d]))
          /
          sum(rate(http_requests_total{service="payment-api"}[30d]))
          * 100

      # Latency p95 SLI (7 days)
      - record: sli:latency_p95:7d
        expr: |
          histogram_quantile(0.95,
            sum(rate(http_request_duration_seconds_bucket{service="payment-api"}[7d])) by (le)
          ) * 1000
```

### Step 5: Implement SLO Alerts

Create `slo-alerts.yaml`:

```yaml
groups:
  - name: slo_alerts
    rules:
      # Fast burn alert (1 hour window)
      - alert: ErrorBudgetBurnRateCritical
        expr: |
          error_budget:availability:burn_rate_1h > 14.4
          and
          error_budget:availability:burn_rate_6h > 6
        for: 5m
        labels:
          severity: critical
          slo: availability
        annotations:
          summary: "Critical burn rate - will exhaust budget in 2 days"
          description: "Error budget burning at {{ $value }}x normal rate"

      # Medium burn alert (6 hour window)
      - alert: ErrorBudgetBurnRateHigh
        expr: |
          error_budget:availability:burn_rate_6h > 6
          and
          error_budget:availability:remaining_percent < 50
        for: 30m
        labels:
          severity: warning
          slo: availability
        annotations:
          summary: "High burn rate with low remaining budget"
          description: "{{ $value }}% budget remaining, burning fast"

      # Budget exhausted
      - alert: ErrorBudgetExhausted
        expr: |
          error_budget:availability:remaining_percent <= 0
        for: 5m
        labels:
          severity: critical
          slo: availability
        annotations:
          summary: "Error budget completely exhausted"
          description: "Deploy freeze in effect per error budget policy"

      # SLO approaching breach
      - alert: SLOApproachingBreach
        expr: |
          sli:availability:30d < 99.8  # 0.1% below SLO of 99.9%
        for: 1h
        labels:
          severity: warning
          slo: availability
        annotations:
          summary: "Availability SLO approaching breach"
          description: "Current: {{ $value }}%, SLO: 99.9%"
```

### Step 6: Create Grafana Dashboard

```json
{
  "dashboard": {
    "title": "SLO Dashboard - Payment API",
    "panels": [
      {
        "title": "Availability SLO Status",
        "type": "gauge",
        "targets": [{
          "expr": "sli:availability:30d"
        }],
        "fieldConfig": {
          "defaults": {
            "thresholds": {
              "steps": [
                {"value": 0, "color": "red"},
                {"value": 99.8, "color": "yellow"},
                {"value": 99.9, "color": "green"}
              ]
            },
            "min": 99,
            "max": 100,
            "unit": "percent"
          }
        }
      },
      {
        "title": "Error Budget Remaining",
        "type": "graph",
        "targets": [{
          "expr": "error_budget:availability:remaining_percent",
          "legendFormat": "Remaining"
        }, {
          "expr": "error_budget:availability:consumed_percent",
          "legendFormat": "Consumed"
        }]
      },
      {
        "title": "Burn Rate (Last Hour)",
        "type": "stat",
        "targets": [{
          "expr": "error_budget:availability:burn_rate_1h"
        }],
        "fieldConfig": {
          "defaults": {
            "thresholds": {
              "steps": [
                {"value": 0, "color": "green"},
                {"value": 5, "color": "yellow"},
                {"value": 10, "color": "red"}
              ]
            }
          }
        }
      },
      {
        "title": "SLI vs SLO (30 days)",
        "type": "timeseries",
        "targets": [{
          "expr": "sli:availability:30d",
          "legendFormat": "Actual"
        }, {
          "expr": "99.9",
          "legendFormat": "SLO (99.9%)"
        }]
      }
    ]
  }
}
```

---

## 📈 Part 6: Advanced Error Budget Management

### Multi-Service Error Budgets

Aggregate error budgets across microservices:

```promql
# Overall platform error budget
avg(error_budget:availability:remaining_percent{service=~".*-api"})

# Worst performing service
bottomk(1, error_budget:availability:remaining_percent)
```

### Error Budget Attribution

Track what consumed your budget:

```yaml
# Error budget breakdown
error_budget_consumption:
  total_consumed: 35%
  breakdown:
    - cause: "Database outage"
      percentage: 20%
      duration: "15 minutes"
      date: "2025-10-01"

    - cause: "Bad deployment (v2.1.0)"
      percentage: 10%
      duration: "8 minutes"
      date: "2025-10-08"

    - cause: "DDoS attack"
      percentage: 5%
      duration: "4 minutes"
      date: "2025-10-12"
```

### Error Budget Forecasting

Predict when budget will exhaust:

```python
# Simple linear forecast
def forecast_budget_exhaustion(current_burn_rate, remaining_budget):
    """
    Predict days until error budget exhausted

    Args:
        current_burn_rate: Current burn rate (multiplier)
        remaining_budget: Remaining budget (percentage)

    Returns:
        Days until exhaustion
    """
    if current_burn_rate <= 0:
        return float('inf')  # Never exhausts

    # Days in 30-day window
    days_in_window = 30

    # Expected daily budget consumption at 1x burn rate
    daily_budget = 100 / days_in_window

    # Actual daily consumption at current burn rate
    actual_daily = daily_budget * current_burn_rate

    # Days until exhaustion
    days_remaining = remaining_budget / actual_daily

    return days_remaining

# Example
burn_rate = 5  # 5x normal
remaining = 30  # 30% budget left

days = forecast_budget_exhaustion(burn_rate, remaining)
print(f"Budget exhausted in {days:.1f} days")
# Output: Budget exhausted in 1.8 days
```

---

## 💡 Part 7: SLO-Driven Decision Making

### Scenario 1: Should We Deploy This Feature?

```
Feature: New payment method integration
Risk: Medium (touches critical path)
Error Budget Remaining: 60%

Decision Framework:
1. Check error budget: 60% > 25% ✅
2. Review recent burn rate: 1.2x (normal) ✅
3. Check deployment time: Off-peak hours ✅
4. Rollback plan: Yes ✅

Decision: DEPLOY
Rationale: Sufficient budget, normal burn rate, low-risk timing
```

### Scenario 2: Should We Continue This Deployment?

```
Feature: UI redesign (v3.0)
Deployed: 30 minutes ago
Error Budget Remaining: 15% (was 40%)
Burn Rate: 25x (critical)

Decision Framework:
1. Budget consumption: 25% in 30 min 🚨
2. Projected exhaustion: <2 hours 🚨
3. User impact: High (errors visible) 🚨
4. Rollback available: Yes ✅

Decision: IMMEDIATE ROLLBACK
Rationale: Critical burn rate will exhaust budget
```

### Scenario 3: Should We Focus on Reliability?

```
Current State:
- Error Budget: 5% remaining
- Days left in window: 10 days
- Recent deploys: 8 feature releases
- Incidents: 3 in last week

Decision Framework:
1. Budget health: Critical (<10%) 🚨
2. Trend: Worsening (3 incidents/week) 🚨
3. Time remaining: 33% of window left
4. Feature pressure: High demand from PM

Decision: RELIABILITY SPRINT
Actions:
- Freeze feature deploys for 10 days
- Focus team on reliability improvements
- Daily review of metrics
- Root cause analysis for incidents
```

---

## 🎯 Part 8: Practical Exercise

### Exercise: Complete SLO Implementation

**Objective**: Implement full SLI/SLO/Error Budget system for a service

**Scenario**: You manage an API service that handles user authentication

**Requirements**:

1. **Define 3 SLIs**
   - Availability
   - Latency (p95 and p99)
   - Error rate

2. **Set SLOs**
   - Based on user requirements
   - Document reasoning
   - Include alert thresholds

3. **Calculate Error Budgets**
   - Convert SLOs to error budgets
   - Define burn rate alerts
   - Create exhaustion policies

4. **Implement Monitoring**
   - Prometheus recording rules
   - AlertManager rules
   - Grafana dashboard

5. **Document Decision Framework**
   - When to deploy
   - When to rollback
   - When to freeze deploys

**Starter Template**:

```yaml
# slo-config.yaml
service: auth-api
description: "User authentication service"

slis:
  - name: availability
    # TODO: Define SLI query

  - name: latency_p95
    # TODO: Define SLI query

  - name: error_rate
    # TODO: Define SLI query

slos:
  - name: availability_slo
    sli: availability
    objective: ???  # TODO: Set target
    window: 30d
    reasoning: "???"  # TODO: Document why

  # TODO: Add latency and error rate SLOs

error_budget_policy:
  # TODO: Define policies for budget consumption
```

**Validation Criteria**:
- [ ] 3 SLIs defined with Prometheus queries
- [ ] 3 SLOs set with clear reasoning
- [ ] Error budgets calculated correctly
- [ ] Recording rules implemented
- [ ] Alert rules configured
- [ ] Dashboard created and functional
- [ ] Decision framework documented
- [ ] Tested with simulated incidents

---

## 🎓 Part 9: Knowledge Check

### Quiz Questions

1. **What is an SLI?**
   - [ ] A promise to users about reliability
   - [x] A metric that indicates user happiness
   - [ ] The allowed unreliability
   - [ ] A dashboard panel

2. **What is an SLO?**
   - [x] A target value for an SLI over a time window
   - [ ] A metric collection system
   - [ ] An error budget calculation
   - [ ] A monitoring tool

3. **How is error budget calculated?**
   - [ ] 100% - SLI
   - [x] 100% - SLO
   - [ ] SLO - SLI
   - [ ] SLI - SLO

4. **What does a burn rate of 5x mean?**
   - [ ] Service is 5x faster
   - [ ] 5 errors per minute
   - [x] Consuming error budget 5x faster than normal
   - [ ] 5% error rate

5. **When should you freeze feature deploys?**
   - [ ] Never, always ship features
   - [ ] Only during incidents
   - [x] When error budget is critically low (<10%)
   - [ ] Every Friday

6. **What's a good starting point for SLOs?**
   - [ ] 100% (perfection)
   - [ ] 50% (average)
   - [x] Slightly below current performance
   - [ ] Industry average

7. **How many SLOs should a service have?**
   - [ ] Exactly 1
   - [ ] At least 10
   - [x] 3-5 most critical metrics
   - [ ] One per feature

8. **What's the purpose of multi-window SLOs?**
   - [ ] Confuse people with more metrics
   - [ ] Show off monitoring capabilities
   - [x] Provide early warning of SLO violations
   - [ ] Meet compliance requirements

**Answers**: 1-B, 2-A, 3-B, 4-C, 5-C, 6-C, 7-C, 8-C

---

## 🎯 Part 10: Module Summary & Next Steps

### What You Learned

✅ **SLIs**: User-centric metrics that indicate happiness
✅ **SLOs**: Targets for SLIs that balance reliability and innovation
✅ **Error Budgets**: Allowed unreliability enabling risk-taking
✅ **Burn Rates**: Speed of error budget consumption
✅ **SLO-Driven Decisions**: Data-driven deployment and reliability choices
✅ **Implementation**: Prometheus, recording rules, alerts, dashboards

### Key Takeaways

1. **SLOs create shared language** - Teams align on reliability
2. **Error budgets enable innovation** - Spend budget on features
3. **Measure what users care about** - SLIs should reflect user experience
4. **Start conservative** - Easier to tighten than loosen SLOs
5. **Fewer is better** - 3-5 well-chosen SLOs beat 20 mediocre ones
6. **Burn rate matters** - Track how fast you're consuming budget
7. **Use data to decide** - Deploy when budget allows, freeze when exhausted

### Real-World Impact

"After implementing SLIs/SLOs/Error Budgets:
- **Deployment confidence**: 70% → 95% (data-driven decisions)
- **Reliability**: 99.5% → 99.9% (clear targets)
- **Innovation velocity**: 30% increase (error budget enables risk)
- **Team alignment**: Dramatically improved (shared language)
- **Customer satisfaction**: NPS +20 points (met expectations)
- **Incident response**: Faster (clear SLO breach alerts)

We transformed from arguing about reliability to managing it scientifically."
- *Engineering Director, SaaS Platform*

---

## 📚 Additional Resources

### Books
- *Site Reliability Engineering* - Google (free online)
- *The Site Reliability Workbook* - Google
- *Implementing Service Level Objectives* - Alex Hidalgo

### Tools
- [Sloth](https://sloth.dev/) - SLO generator for Prometheus
- [Pyrra](https://github.com/pyrra-dev/pyrra) - SLO tracking
- [OpenSLO](https://openslo.com/) - SLO specification standard

### Learning Resources
- [Google SRE - SLO Chapter](https://sre.google/sre-book/service-level-objectives/)
- [Embracing Risk](https://sre.google/sre-book/embracing-risk/)
- [SLO Workshop](https://slo-workshop.stevesnet.com/)

---

## 🏅 Module Completion

### Assessment Checklist

- [ ] **Conceptual Understanding**
  - [ ] Explain SLIs, SLOs, error budgets
  - [ ] Calculate burn rates
  - [ ] Understand SLO-driven decisions

- [ ] **Practical Skills**
  - [ ] Define SLIs for services
  - [ ] Set appropriate SLOs
  - [ ] Implement monitoring
  - [ ] Create dashboards
  - [ ] Configure alerts

- [ ] **Hands-On Lab**
  - [ ] Complete SLO implementation
  - [ ] Recording rules working
  - [ ] Alerts configured
  - [ ] Dashboard functional

- [ ] **Quiz**
  - [ ] Score 80% or higher (6/8 questions)

### Certification Credit

Upon completion, you earn:
- **10 points** toward Brown Belt certification (75% complete)
- **Badge**: "SLO Architect"
- **Skill Unlocked**: Service Reliability Engineering

---

## 🎖️ Brown Belt Progress

```
Brown Belt: Observability & SRE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Module 13: Observability          ████████░░░░ 25% ✓
Module 14: DORA Metrics           ████████░░░░ 50% ✓
Module 15: SLIs/SLOs/Budgets      ████████░░░░ 75% ✓
Module 16: Incident Management    ░░░░░░░░░░░░  0%
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**Next Module Preview**: Module 16 - Advanced Incident Management (Postmortems, chaos engineering, MTTR optimization)

---

*Fawkes Dojo - Where Platform Engineers Are Forged*
*Version 1.0 | Last Updated: October 2025*
*License: MIT | https://github.com/paruff/fawkes*