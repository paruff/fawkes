# Fawkes Dojo Module 16: Incident Management (Advanced)

## 🎯 Module Overview

**Belt Level**: 🟤 Brown Belt - Observability & SRE (**FINAL MODULE**)  
**Module**: 4 of 4 (Brown Belt)  
**Duration**: 60 minutes  
**Difficulty**: Advanced  
**Prerequisites**: 
- Module 12: Rollback & Incident Response complete
- Module 13: Observability complete
- Module 14: DORA Metrics Deep Dive complete
- Module 15: SLIs, SLOs, and Error Budgets complete

---

## 📚 Learning Objectives

By the end of this module, you will:

1. ✅ Implement advanced incident response frameworks
2. ✅ Conduct effective incident command and communication
3. ✅ Perform root cause analysis (RCA) with structured methods
4. ✅ Design and facilitate blameless postmortems
5. ✅ Build incident response automation
6. ✅ Create chaos engineering experiments
7. ✅ Measure and improve incident management effectiveness

**DORA Capabilities Addressed**:
- ✓ Mean Time to Restore (MTTR) - Elite level
- ✓ Incident Management Process
- ✓ Postmortem Culture
- ✓ Learning Organization

---

## 📖 Part 1: Advanced Incident Response Framework

### The Incident Lifecycle

```
┌─────────────────────────────────────────────────────┐
│           Advanced Incident Lifecycle                │
└─────────────────────────────────────────────────────┘

1. DETECTION (< 5 min)
   ├─ Automated monitoring alerts
   ├─ User reports
   └─ Synthetic monitoring

2. TRIAGE (< 2 min)
   ├─ Assess severity
   ├─ Assign incident commander
   └─ Form response team

3. INVESTIGATION (parallel)
   ├─ Gather data (logs, metrics, traces)
   ├─ Form hypotheses
   └─ Test theories

4. MITIGATION (< 15 min for SEV1)
   ├─ Quick fix (rollback, scale, disable)
   ├─ Workaround
   └─ Emergency patch

5. RESOLUTION
   ├─ Root cause fix
   ├─ Verification
   └─ Monitoring

6. RECOVERY
   ├─ Service restoration
   ├─ Data recovery
   └─ Communication

7. POSTMORTEM (within 24-48h)
   ├─ Timeline reconstruction
   ├─ Root cause analysis
   └─ Action items

8. FOLLOW-UP
   ├─ Action item tracking
   ├─ Pattern analysis
   └─ Process improvement
```

### Incident Severity Matrix

| Severity | Impact | MTTR Target | Response | Example |
|----------|--------|-------------|----------|---------|
| **SEV0** | Critical outage, data loss | < 15 min | All hands, exec notification | Database corruption |
| **SEV1** | Full service down | < 30 min | Full team, page oncall | API completely down |
| **SEV2** | Major feature broken | < 2 hours | Team leads, business hours | Payment processing failing |
| **SEV3** | Minor degradation | < 8 hours | Oncall engineer | Slow response times |
| **SEV4** | Cosmetic/low impact | < 1 day | Regular sprint work | UI bug in admin panel |

### Incident Roles

#### Incident Commander (IC)

**Responsibilities**:
- Overall incident coordination
- Communication hub
- Decision authority
- Delegate tasks
- Declare incident resolved

**Skills needed**:
- Calm under pressure
- Clear communication
- Technical understanding
- Decision-making

**IC Checklist**:
```markdown
[ ] Acknowledge incident
[ ] Assess severity
[ ] Assemble response team
[ ] Establish communication channels
[ ] Delegate investigation tasks
[ ] Make mitigation decisions
[ ] Coordinate with stakeholders
[ ] Declare resolution
[ ] Schedule postmortem
```

#### Technical Lead (TL)

**Responsibilities**:
- Technical investigation
- Hypothesis testing
- Implementation of fixes
- Technical decisions

#### Communications Lead (Comms)

**Responsibilities**:
- Status page updates
- Stakeholder notifications
- Customer communication
- Timeline documentation

#### Scribe

**Responsibilities**:
- Document timeline
- Capture decisions
- Record hypotheses
- Log actions taken

---

## 🚨 Part 2: Incident Command System

### The ICS Framework

Adapted from emergency response, ICS provides structure for incident response.

```
┌─────────────────────────────────────────┐
│      Incident Command System (ICS)      │
└─────────────────────────────────────────┘

                Incident Commander
                        │
        ┌───────────────┼───────────────┐
        │               │               │
   Operations      Communications   Planning
        │               │               │
    ┌───┴───┐      ┌───┴───┐      ┌───┴───┐
    │       │      │       │      │       │
Technical Customer Internal Timeline Resource
 Team    Comms    Comms   Keeping Management
```

### Communication Channels

**During Incident**:

```yaml
primary_channel: "#incident-war-room"
  purpose: "Real-time coordination"
  participants: "Response team only"
  format: "Slack/Mattermost"

status_channel: "#incidents-status"
  purpose: "Broadcast updates"
  participants: "Entire company"
  format: "Read-only, IC posts only"

customer_channel: "status.company.com"
  purpose: "External communication"
  participants: "Customers"
  format: "Status page updates"

executive_channel: "#exec-incidents"
  purpose: "Leadership updates"
  participants: "Executives"
  format: "SEV0/SEV1 only"
```

### Communication Templates

#### Initial Notification

```markdown
🚨 INCIDENT DECLARED - SEV1

**Service**: Payment API
**Impact**: Customers cannot complete purchases
**Detection**: Automated alert + customer reports
**Incident Commander**: @alice
**Started**: 2025-10-12 14:23 UTC
**War Room**: #incident-2025-10-12-payment
**Status Page**: https://status.company.com/incidents/12345

Current Status: INVESTIGATING
```

#### Status Update (Every 15-30 min)

```markdown
📊 INCIDENT UPDATE - 14:45 UTC

**Status**: MITIGATING
**Impact**: Still affecting 100% of payment attempts
**Progress**: 
- Root cause identified: Database connection pool exhausted
- Mitigation in progress: Scaling connection pool
- ETA for resolution: 15 minutes

Next update: 15:00 UTC or when status changes
```

#### Resolution Notification

```markdown
✅ INCIDENT RESOLVED - 15:10 UTC

**Service**: Payment API
**Duration**: 47 minutes (14:23 - 15:10 UTC)
**Resolution**: Connection pool scaled from 100 to 500
**Impact**: ~500 failed payment attempts during incident
**Root Cause**: Traffic spike exceeded connection pool capacity

**Next Steps**:
- Postmortem scheduled: 2025-10-13 10:00 UTC
- Monitoring enhanced connection pool metrics
- Reviewing auto-scaling policies

War room will remain open for 1 hour for follow-up.
```

---

## 🔍 Part 3: Root Cause Analysis (RCA)

### The 5 Whys Technique

**Method**: Ask "why" five times to find root cause

**Example: Website Down**

```
Problem: Website is down

Why #1: Why is the website down?
→ Because the web servers are not responding

Why #2: Why are the web servers not responding?
→ Because they ran out of memory

Why #3: Why did they run out of memory?
→ Because there was a memory leak in the new deployment

Why #4: Why was there a memory leak in the new deployment?
→ Because the code review didn't catch the leak

Why #5: Why didn't the code review catch the leak?
→ Because we don't have memory profiling in our review process

ROOT CAUSE: Lack of memory profiling in deployment process
```

### Fishbone Diagram (Ishikawa)

Categorize potential causes:

```
                    ┌─────────────────────┐
                    │  Website Down       │
                    └─────────────────────┘
                             │
        ┌────────────────────┼────────────────────┐
        │                    │                    │
    PEOPLE              PROCESS              TECHNOLOGY
        │                    │                    │
  ┌─────┴─────┐        ┌────┴────┐         ┌─────┴─────┐
  │           │        │         │         │           │
Oncall   Training   No load   Manual   Memory    No
tired     lacking   testing   deploy   leak    monitoring
  │                    │                    │
  └────────────────────┼────────────────────┘
                       │
              Contributing Factors
```

### Fault Tree Analysis

Work backwards from failure:

```
          Website Down
                │
        ┌───────┴───────┐
        │               │
   Server         Database
   Failed         Failed
        │               │
    ┌───┴───┐       ┌───┴───┐
    │       │       │       │
  Memory  CPU     Disk   Connection
  Leak   Spike    Full     Pool
                           │
                    ┌──────┴──────┐
                    │             │
                Traffic      Config
                Spike        Error
```

### Timeline Analysis

Reconstruct exact sequence:

```markdown
## Incident Timeline

**14:20 UTC** - Traffic begins increasing (normal pattern)
**14:22 UTC** - Connection pool usage hits 80%
**14:23 UTC** - First timeout errors occur
**14:23 UTC** - Alerts fire: "High Error Rate"
**14:24 UTC** - Oncall engineer paged
**14:25 UTC** - Engineer acknowledges page
**14:27 UTC** - Engineer joins war room
**14:28 UTC** - Incident declared SEV1
**14:30 UTC** - IC assigned (@alice)
**14:32 UTC** - Investigation begins
**14:35 UTC** - Root cause hypothesis: connection pool
**14:37 UTC** - Hypothesis confirmed via metrics
**14:40 UTC** - Decision: Scale connection pool
**14:42 UTC** - Configuration change deployed
**14:45 UTC** - Error rate begins decreasing
**14:50 UTC** - Error rate back to normal
**15:00 UTC** - Monitoring continues
**15:10 UTC** - Incident resolved

**Total Duration**: 47 minutes
**Detection to Mitigation**: 17 minutes
**Mitigation to Resolution**: 28 minutes
```

---

## 📝 Part 4: Blameless Postmortems

### What Makes a Postmortem "Blameless"?

**Blameless Principles**:

1. **Focus on Systems, Not People**
   - ❌ "Bob deployed bad code"
   - ✅ "Deployment lacked sufficient testing"

2. **Assume Good Intentions**
   - Everyone did their best with available information
   - No one comes to work to break things

3. **Psychological Safety**
   - People feel safe admitting mistakes
   - Honesty leads to better learning

4. **Learning Over Blame**
   - Goal is prevention, not punishment
   - Celebrate transparency

### Postmortem Template

```markdown
# Postmortem: Payment API Outage - 2025-10-12

## Executive Summary

**Date**: October 12, 2025, 14:23 - 15:10 UTC
**Duration**: 47 minutes
**Severity**: SEV1
**Impact**: 
- ~500 failed payment attempts
- $12,000 estimated revenue impact
- No data loss

**Root Cause**: Database connection pool exhausted under traffic spike

**Resolution**: Increased connection pool size and implemented auto-scaling

---

## Timeline

See [detailed timeline](#timeline-analysis) above

---

## Impact Analysis

### User Impact
- **Affected Users**: 100% of users attempting checkout
- **Failed Transactions**: ~500
- **Duration**: 47 minutes

### Business Impact
- **Revenue Loss**: ~$12,000 (estimated)
- **Reputation**: Minimal (quick resolution, good communication)
- **SLO Impact**: 
  - Availability: 99.89% (SLO: 99.9%) ⚠️ Close to breach
  - Error Budget: 15% consumed in single incident

### Technical Impact
- **Systems Affected**: Payment API, database, checkout flow
- **Data Loss**: None
- **Security Impact**: None

---

## Root Cause Analysis

### Primary Cause
Database connection pool configuration (100 connections) insufficient for traffic spike (150 requests/sec).

### Contributing Factors

1. **Lack of Load Testing**
   - New traffic patterns not tested
   - Connection pool limits not validated

2. **No Auto-Scaling**
   - Manual configuration required
   - Cannot adapt to traffic changes

3. **Insufficient Monitoring**
   - No alerting on connection pool utilization
   - Detected via error rate, not proactive metric

4. **Timing**
   - Occurred during major promotional campaign
   - Higher than normal traffic expected but not planned for

---

## What Went Well ✅

1. **Detection**: Automated alerts fired immediately (< 1 min)
2. **Communication**: Clear, frequent updates to stakeholders
3. **Collaboration**: Team worked effectively under pressure
4. **Documentation**: Excellent timeline kept by scribe
5. **Resolution Speed**: 47 minutes well within SEV1 target (< 2 hours)

---

## What Went Wrong ❌

1. **Prevention**: Inadequate load testing missed this scenario
2. **Monitoring**: No proactive alert on connection pool usage
3. **Capacity Planning**: Traffic spike predictable but not prepared for
4. **Automation**: Manual scaling required human intervention
5. **Documentation**: Connection pool limits not documented

---

## Action Items

### Immediate (< 1 week)

| Action | Owner | Deadline | Status |
|--------|-------|----------|--------|
| Implement connection pool monitoring | @bob | Oct 15 | ✅ Done |
| Alert on 80% pool utilization | @carol | Oct 15 | ✅ Done |
| Document all database limits | @dave | Oct 16 | 🔄 In Progress |

### Short-term (< 1 month)

| Action | Owner | Deadline | Status |
|--------|-------|----------|--------|
| Implement auto-scaling for connection pool | @eve | Nov 1 | 📋 Planned |
| Load test with 2x expected traffic | @frank | Nov 5 | 📋 Planned |
| Create runbook for connection pool issues | @grace | Oct 25 | 🔄 In Progress |

### Long-term (< 3 months)

| Action | Owner | Deadline | Status |
|--------|-------|----------|--------|
| Implement chaos engineering for database | @henry | Dec 15 | 📋 Planned |
| Review all system capacity limits | @iris | Nov 30 | 📋 Planned |
| Enhance pre-launch checklist | @jack | Nov 15 | 📋 Planned |

---

## Lessons Learned

1. **Load test everything**: Especially before major campaigns
2. **Monitor resources, not just symptoms**: Alert before error rates spike
3. **Plan for 3x capacity**: If expecting 2x traffic, plan for 3x
4. **Automate recovery**: Manual scaling too slow for rapid incidents
5. **Document limits**: Every system has limits - know and document them

---

## Supporting Data

### Metrics
- [Grafana Dashboard](https://grafana.company.com/incident-2025-10-12)
- [Connection Pool Graph](https://grafana.company.com/connection-pool)
- [Error Rate Spike](https://grafana.company.com/error-rate)

### Logs
- [Relevant Log Entries](https://opensearch.company.com/incident-logs)

### Communication
- [Slack War Room Archive](https://mattermost.company.com/incident-war-room)
- [Status Page Timeline](https://status.company.com/incidents/12345)

---

## Attendees

- Alice (Incident Commander)
- Bob (Technical Lead)
- Carol (SRE)
- Dave (Database Admin)
- Eve (Engineering Manager)
- Frank (QA Lead)
- Grace (Technical Writer)

**Meeting Date**: October 13, 2025, 10:00 UTC
**Duration**: 90 minutes

---

## Approval

- [ ] Engineering Manager: _________________
- [ ] SRE Lead: _________________
- [ ] CTO: _________________

**Approved**: October 14, 2025
```

---

## 🤖 Part 5: Incident Automation

### Automated Detection

```yaml
# prometheus-alerts.yaml
groups:
  - name: automated_incident_detection
    rules:
      # SEV1: Service completely down
      - alert: ServiceCompletelyDown
        expr: |
          sum(up{service="payment-api"}) == 0
        for: 1m
        labels:
          severity: sev1
          auto_incident: "true"
        annotations:
          summary: "Payment API completely down"
          description: "All instances unreachable for 1 minute"
          runbook: "https://runbooks.company.com/service-down"
          action: "Page oncall immediately, create incident"
      
      # SEV1: High error rate
      - alert: CriticalErrorRate
        expr: |
          sum(rate(http_requests_total{status=~"5.."}[5m]))
          /
          sum(rate(http_requests_total[5m]))
          > 0.10
        for: 5m
        labels:
          severity: sev1
          auto_incident: "true"
        annotations:
          summary: "Error rate above 10%"
          description: "{{ $value | humanizePercentage }} error rate"
      
      # SEV2: Approaching error budget exhaustion
      - alert: ErrorBudgetCritical
        expr: |
          error_budget:availability:remaining_percent < 10
          and
          error_budget:availability:burn_rate_1h > 5
        for: 10m
        labels:
          severity: sev2
          auto_incident: "true"
        annotations:
          summary: "Error budget critically low"
          description: "{{ $value }}% remaining, burning fast"
```

### Automated Incident Creation

```python
# incident_automation.py
from prometheus_client import CollectorRegistry, Gauge, push_to_gateway
import requests
import json

class IncidentAutomation:
    def __init__(self, mattermost_webhook, pagerduty_key):
        self.mattermost_webhook = mattermost_webhook
        self.pagerduty_key = pagerduty_key
    
    def create_incident(self, alert):
        """Automatically create incident from alert"""
        
        # Extract details
        severity = alert['labels']['severity']
        service = alert['labels']['service']
        summary = alert['annotations']['summary']
        description = alert['annotations']['description']
        runbook = alert['annotations'].get('runbook', '')
        
        # Generate incident ID
        incident_id = self.generate_incident_id()
        
        # Create war room channel
        war_room = self.create_war_room(incident_id, service)
        
        # Page oncall
        self.page_oncall(severity, summary, war_room)
        
        # Post initial notification
        self.post_notification(war_room, {
            'incident_id': incident_id,
            'severity': severity,
            'service': service,
            'summary': summary,
            'description': description,
            'runbook': runbook,
            'status': 'INVESTIGATING'
        })
        
        # Create incident ticket
        ticket = self.create_ticket(incident_id, severity, summary)
        
        # Update status page
        self.update_status_page(service, summary)
        
        return incident_id
    
    def create_war_room(self, incident_id, service):
        """Create Mattermost war room channel"""
        channel_name = f"incident-{incident_id}-{service}"
        
        # Create channel via API
        response = requests.post(
            f"{self.mattermost_url}/api/v4/channels",
            headers={"Authorization": f"Bearer {self.mattermost_token}"},
            json={
                "team_id": self.team_id,
                "name": channel_name,
                "display_name": f"🚨 Incident {incident_id} - {service}",
                "type": "O",  # Public
                "header": f"Incident response for {service}"
            }
        )
        
        return channel_name
    
    def page_oncall(self, severity, summary, war_room):
        """Page oncall via PagerDuty"""
        
        # SEV0 and SEV1 = page immediately
        if severity in ['sev0', 'sev1']:
            urgency = 'high'
        else:
            urgency = 'low'
        
        incident = {
            "incident": {
                "type": "incident",
                "title": summary,
                "urgency": urgency,
                "body": {
                    "type": "incident_body",
                    "details": f"War room: #{war_room}"
                }
            }
        }
        
        response = requests.post(
            "https://api.pagerduty.com/incidents",
            headers={
                "Authorization": f"Token token={self.pagerduty_key}",
                "Content-Type": "application/json"
            },
            json=incident
        )
        
        return response.json()
    
    def post_notification(self, channel, incident_data):
        """Post incident notification to Mattermost"""
        
        message = f"""
🚨 **INCIDENT DECLARED - {incident_data['severity'].upper()}**

**Service**: {incident_data['service']}
**Summary**: {incident_data['summary']}
**Description**: {incident_data['description']}
**Incident ID**: {incident_data['incident_id']}
**Status**: {incident_data['status']}
**Runbook**: {incident_data.get('runbook', 'N/A')}

**Next Steps**:
1. Acknowledge you're responding
2. Review runbook
3. Begin investigation
4. Update this channel every 15 minutes

War room: #{channel}
        """
        
        requests.post(
            self.mattermost_webhook,
            json={"text": message}
        )

# Usage
automation = IncidentAutomation(
    mattermost_webhook="https://mattermost.company.com/hooks/xxx",
    pagerduty_key="xxx"
)

# Triggered by AlertManager webhook
@app.route('/webhook/alerts', methods=['POST'])
def handle_alert():
    alerts = request.json['alerts']
    
    for alert in alerts:
        if alert['labels'].get('auto_incident') == 'true':
            incident_id = automation.create_incident(alert)
            print(f"Created incident: {incident_id}")
    
    return '', 200
```

### Automated Remediation

```python
# auto_remediation.py
class AutoRemediation:
    def __init__(self):
        self.remediation_actions = {
            'high_cpu': self.scale_horizontally,
            'out_of_memory': self.restart_pods,
            'disk_full': self.cleanup_logs,
            'connection_pool_exhausted': self.increase_pool,
            'circuit_breaker_open': self.reset_circuit_breaker
        }
    
    def handle_incident(self, incident_type, service):
        """Execute automated remediation"""
        
        if incident_type not in self.remediation_actions:
            print(f"No automated remediation for {incident_type}")
            return False
        
        # Execute remediation
        action = self.remediation_actions[incident_type]
        success = action(service)
        
        # Log action
        self.log_remediation(incident_type, service, success)
        
        return success
    
    def scale_horizontally(self, service):
        """Scale service horizontally"""
        current_replicas = self.get_replica_count(service)
        new_replicas = current_replicas * 2
        
        print(f"Scaling {service} from {current_replicas} to {new_replicas}")
        
        # Scale via kubectl
        subprocess.run([
            'kubectl', 'scale',
            f'deployment/{service}',
            f'--replicas={new_replicas}'
        ])
        
        return True
    
    def restart_pods(self, service):
        """Rolling restart of pods"""
        print(f"Restarting pods for {service}")
        
        subprocess.run([
            'kubectl', 'rollout', 'restart',
            f'deployment/{service}'
        ])
        
        return True
    
    def increase_pool(self, service):
        """Increase connection pool size"""
        current_pool = self.get_pool_size(service)
        new_pool = current_pool * 2
        
        print(f"Increasing pool from {current_pool} to {new_pool}")
        
        # Update ConfigMap
        self.update_config(service, 'pool_size', new_pool)
        
        # Restart to apply
        self.restart_pods(service)
        
        return True
```

---

## 💥 Part 6: Chaos Engineering

### What is Chaos Engineering?

> "Chaos Engineering is the discipline of experimenting on a system in order to build confidence in the system's capability to withstand turbulent conditions in production."

### Principles of Chaos

1. **Build a hypothesis** - Define steady state and expected behavior
2. **Vary real-world events** - Inject realistic failures
3. **Run experiments in production** - Where it matters most
4. **Automate experiments** - Run continuously
5. **Minimize blast radius** - Start small, scale up

### Example Chaos Experiments

#### Experiment 1: Pod Failure

```yaml
# chaos-pod-failure.yaml
apiVersion: chaos-mesh.org/v1alpha1
kind: PodChaos
metadata:
  name: pod-failure-payment-api
spec:
  action: pod-failure
  mode: one
  selector:
    namespaces:
      - production
    labelSelectors:
      app: payment-api
  duration: "30s"
  scheduler:
    cron: "@every 2h"  # Run every 2 hours
```

**Hypothesis**: "Payment API can tolerate single pod failure without user impact"

**Expected Outcome**: 
- Service remains available (other pods handle traffic)
- No increase in error rate
- Automatic pod recovery within 1 minute

**Success Criteria**:
- ✅ Availability > 99.9%
- ✅ Error rate < 0.5%
- ✅ P95 latency < 500ms
- ✅ Pod recovers automatically

#### Experiment 2: Network Latency

```yaml
# chaos-network-latency.yaml
apiVersion: chaos-mesh.org/v1alpha1
kind: NetworkChaos
metadata:
  name: network-latency-database
spec:
  action: delay
  mode: all
  selector:
    namespaces:
      - production
    labelSelectors:
      app: postgres
  delay:
    latency: "100ms"
    correlation: "100"
    jitter: "0ms"
  duration: "5m"
```

**Hypothesis**: "Application can handle 100ms database latency without errors"

**Expected Outcome**:
- Increased response times but no errors
- Circuit breaker prevents cascading failures
- Timeouts configured appropriately

#### Experiment 3: CPU Stress

```yaml
# chaos-cpu-stress.yaml
apiVersion: chaos-mesh.org/v1alpha1
kind: StressChaos
metadata:
  name: cpu-stress-payment-api
spec:
  mode: one
  selector:
    namespaces:
      - production
    labelSelectors:
      app: payment-api
  stressors:
    cpu:
      workers: 2
      load: 80
  duration: "3m"
```

**Hypothesis**: "Auto-scaling triggers before service degrades under CPU stress"

**Expected Outcome**:
- HPA scales up within 1 minute
- No user-visible impact
- Automatic recovery after experiment

### GameDay: Planned Chaos

Conduct regular "GameDay" exercises:

```markdown
# GameDay Planning Template

## Objective
Test incident response for complete database failure

## Date & Time
2025-10-20, 10:00-12:00 UTC (off-peak)

## Scope
- Service: Payment API (production)
- Failure: Database primary failure
- Duration: 15 minutes

## Participants
- Incident Commander: @alice
- On-call Engineer: @bob
- Database Team: @carol
- Observers: @dave, @eve

## Scenario
1. At T+0: Simulate primary database failure
2. Team responds as if real incident
3. Test failover to replica
4. Measure MTTR and effectiveness

## Success Criteria
- [ ] Automatic failover within 2 minutes
- [ ] Service restored within 5 minutes
- [ ] No data loss
- [ ] All runbooks followed correctly

## Safety Measures
- [ ] Backup verified before test
- [ ] Rollback plan documented
- [ ] Exec team notified
- [ ] Customer communication ready

## Debrief
- What went well
- What needs improvement
- Action items

## Results
[To be filled after GameDay]
```

---

## 📊 Part 7: Measuring Incident Management Effectiveness

### Key Metrics

#### 1. MTTR (Mean Time to Restore)

```promql
# Average MTTR by severity
avg(incident_duration_seconds) by (severity) / 60
```

**Targets**:
- SEV0: < 15 min
- SEV1: < 30 min
- SEV2: < 2 hours
- SEV3: < 8 hours

#### 2. MTTD (Mean Time to Detect)

```promql
# Time from incident start to detection
avg(incident_detected_seconds - incident_started_seconds)
```

**Target**: < 5 minutes (automated monitoring)

#### 3. MTTI (Mean Time to Investigate)

```promql
# Time from detection to root cause identified
avg(incident_root_cause_found_seconds - incident_detected_seconds) / 60
```

**Target**: < 10 minutes for SEV1

#### 4. Incident Frequency

```promql
# Incidents per week
sum(increase(incidents_total[7d]))
```

**Target**: Trending downward over time

#### 5. Repeat Incidents

```promql
# Percentage of repeat incidents
sum(incidents_repeat) / sum(incidents_total) * 100
```

**Target**: < 10% (learning from incidents)

#### 6. Action Item Completion

```promql
# Percentage of postmortem actions completed on time
sum(action_items_completed_on_time) / sum(action_items_total) * 100
```

**Target**: > 80%

### Incident Management Dashboard

```json
{
  "dashboard": {
    "title": "Incident Management Metrics",
    "panels": [
      {
        "title": "MTTR by Severity",
        "type": "graph",
        "targets": [{
          "expr": "avg(incident_duration_seconds) by (severity) / 60",
          "legendFormat": "{{severity}}"
        }],
        "yAxes": [{
          "label": "Minutes",
          "format": "short"
        }]
      },
      {
        "title": "Incidents This Month",
        "type": "stat",
        "targets": [{
          "expr": "sum(increase(incidents_total[30d]))"
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
        "title": "Detection Time Trend",
        "type": "graph",
        "targets": [{
          "expr": "avg_over_time((incident_detected_seconds - incident_started_seconds)[30d:1d])",
          "legendFormat": "Detection Time"
        }]
      },
      {
        "title": "Action Item Completion Rate",
        "type": "gauge",
        "targets": [{
          "expr": "sum(action_items_completed_on_time) / sum(action_items_total) * 100"
        }],
        "fieldConfig": {
          "defaults": {
            "thresholds": {
              "steps": [
                {"value": 0, "color": "red"},
                {"value": 60, "color": "yellow"},
                {"value": 80, "color": "green"}
              ]
            },
            "max": 100,
            "unit": "percent"
          }
        }
      },
      {
        "title": "Repeat Incidents",
        "type": "piechart",
        "targets": [{
          "expr": "sum(incidents_repeat)",
          "legendFormat": "Repeat"
        }, {
          "expr": "sum(incidents_total) - sum(incidents_repeat)",
          "legendFormat": "New"
        }]
      },
      {
        "title": "Incidents by Service",
        "type": "table",
        "targets": [{
          "expr": "sum(incidents_total) by (service)",
          "format": "table"
        }]
      }
    ]
  }
}
```

---

## 🎯 Part 8: Hands-On Lab - Full Incident Simulation

### Lab Overview

Conduct a complete incident response simulation from detection through postmortem.

**Scenario**: E-commerce checkout service experiencing high error rates

**Duration**: 60 minutes

**Roles**:
- Incident Commander
- Technical Lead
- Communications Lead
- Scribe

### Step 1: Detection (5 minutes)

**Trigger**: Alert fires

```yaml
Alert: HighErrorRate
Severity: SEV1
Service: checkout-api
Message: Error rate 25% (threshold: 5%)
Time: 14:23 UTC
```

**Tasks**:
- [ ] Acknowledge alert
- [ ] Initial assessment
- [ ] Declare incident
- [ ] Assign IC

### Step 2: Initial Response (10 minutes)

**IC Actions**:
```markdown
1. Create war room: #incident-2025-10-12-checkout
2. Assemble team:
   - Technical Lead: @bob
   - Comms Lead: @carol
   - Scribe: @dave
3. Post initial notification
4. Begin investigation
```

**Initial Notification**:
```markdown
🚨 INCIDENT DECLARED - SEV1

Service: Checkout API
Impact: 25% error rate on checkout
Detection: Automated monitoring
IC: @alice
Started: 14:23 UTC
War Room: #incident-2025-10-12-checkout

Status: INVESTIGATING
```

### Step 3: Investigation (15 minutes)

**Technical Lead investigates**:

```bash
# Check recent deployments
kubectl rollout history deployment/checkout-api

# Check error logs
kubectl logs -l app=checkout-api --tail=100 | grep ERROR

# Check metrics
# - CPU: Normal
# - Memory: Normal
# - Latency: Elevated (p95: 3s, normally 200ms)
# - Error types: "Payment service timeout"

# Check dependencies
curl https://payment-api.internal/health
# Returns: 503 Service Unavailable
```

**Hypothesis**: Payment service is down/degraded

**Verification**:
```bash
# Check payment service metrics
# - All pods healthy
# - High response time (5s average)
# - Database connections maxed out

# Root cause identified:
# Payment service database connection pool exhausted
```

### Step 4: Mitigation (10 minutes)

**Decision (IC)**: Scale database connection pool

```bash
# Update ConfigMap
kubectl edit configmap payment-api-config

# Change:
# pool_size: 100
# To:
# pool_size: 500

# Rolling restart to apply
kubectl rollout restart deployment/payment-api

# Monitor recovery
watch kubectl get pods -l app=payment-api
```

**Status Update**:
```markdown
📊 UPDATE - 14:45 UTC

Status: MITIGATING
Root Cause: Payment service DB connection pool exhausted
Action: Scaling pool from 100 to 500 connections
ETA: 5 minutes

Impact: Still affecting 25% of checkout attempts
Next update: 14:50 UTC
```

### Step 5: Resolution (10 minutes)

**Verify Fix**:
```bash
# Check error rate
# - Decreased from 25% to 5%
# - Decreasing to 1%
# - Now at 0.3% (normal)

# Check latency
# - p95: 250ms (acceptable)

# Check connection pool
# - Usage: 60% (healthy headroom)
```

**Resolution Notice**:
```markdown
✅ INCIDENT RESOLVED - 15:10 UTC

Duration: 47 minutes
Root Cause: DB connection pool exhaustion
Resolution: Scaled pool 100 → 500
Impact: ~800 failed checkout attempts

Postmortem: Tomorrow 10:00 UTC
War room remains open for 1 hour
```

### Step 6: Postmortem (10 minutes - simulation)

**Key Elements**:

```markdown
## Timeline
[See above]

## Root Cause
Payment service database connection pool (100 connections) 
insufficient for traffic spike (200 req/s)

## What Went Well
- Fast detection (< 1 minute)
- Clear communication
- Effective collaboration
- Quick mitigation (22 minutes)

## What Went Wrong
- No proactive monitoring of pool usage
- Inadequate load testing
- Manual scaling required

## Action Items
1. [ ] Add pool usage monitoring (@bob, Oct 15)
2. [ ] Implement auto-scaling (@carol, Nov 1)
3. [ ] Load test 3x expected traffic (@dave, Oct 20)
4. [ ] Document all capacity limits (@eve, Oct 18)
```

### Lab Validation

**Success Criteria**:
- [ ] Incident detected within 1 minute
- [ ] War room created within 2 minutes
- [ ] Root cause identified within 15 minutes
- [ ] Mitigation executed within 25 minutes
- [ ] Total MTTR < 50 minutes
- [ ] Clear communication throughout
- [ ] Timeline documented completely
- [ ] Postmortem scheduled

---

## 💪 Part 9: Practical Exercise

### Exercise: Build Complete Incident Response System

**Objective**: Implement end-to-end incident management for Fawkes platform

**Requirements**:

#### 1. Automated Detection
```yaml
# Task: Create alerts for common failure scenarios
- [ ] Service completely down
- [ ] High error rate (> 10%)
- [ ] High latency (p95 > 1s)
- [ ] Error budget exhaustion
- [ ] Database issues
```

#### 2. Incident Automation
```python
# Task: Build incident automation
- [ ] Auto-create war room channel
- [ ] Page oncall via PagerDuty
- [ ] Post initial notification
- [ ] Create incident ticket
- [ ] Update status page
```

#### 3. Runbooks
```markdown
# Task: Create runbooks for top 5 incidents
- [ ] Service down
- [ ] High error rate
- [ ] Database connection issues
- [ ] Memory leak
- [ ] Traffic spike
```

#### 4. Postmortem Template
```markdown
# Task: Customize postmortem template
- [ ] Executive summary
- [ ] Timeline
- [ ] Root cause analysis
- [ ] Impact assessment
- [ ] Action items tracking
```

#### 5. Chaos Experiments
```yaml
# Task: Design 3 chaos experiments
- [ ] Pod failure
- [ ] Network latency
- [ ] Resource exhaustion
```

#### 6. Metrics Dashboard
```json
# Task: Build incident metrics dashboard
- [ ] MTTR by severity
- [ ] Incident frequency
- [ ] Detection time
- [ ] Action item completion
```

**Validation Criteria**:
- [ ] All alerts configured and tested
- [ ] Automation creates incidents successfully
- [ ] Runbooks comprehensive and tested
- [ ] Postmortem template adopted by team
- [ ] Chaos experiments executed safely
- [ ] Dashboard provides actionable insights

---

## 🎓 Part 10: Knowledge Check

### Quiz Questions

1. **What is the primary goal of incident response?**
   - [ ] Find who caused the problem
   - [x] Restore service as quickly as possible
   - [ ] Write detailed reports
   - [ ] Prevent all future incidents

2. **What makes a postmortem "blameless"?**
   - [ ] Not mentioning anyone's name
   - [ ] Focusing only on technology
   - [x] Assuming good intentions and learning from systems
   - [ ] Avoiding technical details

3. **What is the target MTTR for SEV1 incidents?**
   - [ ] < 5 minutes
   - [ ] < 15 minutes
   - [x] < 30 minutes
   - [ ] < 2 hours

4. **What is the role of an Incident Commander?**
   - [ ] Fix the technical problem
   - [x] Coordinate response and make decisions
   - [ ] Write the postmortem
   - [ ] Page the oncall engineer

5. **What is Chaos Engineering?**
   - [ ] Creating random problems in production
   - [ ] Testing in chaotic environments
   - [x] Experimenting to build confidence in system resilience
   - [ ] Stress testing before launch

6. **How often should postmortem action items be reviewed?**
   - [ ] Never, they're just documentation
   - [ ] Only when incidents recur
   - [x] Regularly (weekly/bi-weekly) until complete
   - [ ] Once at the postmortem meeting

7. **What is MTTD?**
   - [ ] Mean Time To Deploy
   - [x] Mean Time To Detect
   - [ ] Mean Time To Document
   - [ ] Mean Time To Decide

8. **When should you conduct chaos experiments?**
   - [ ] Only in development
   - [ ] Only during incidents
   - [x] Regularly in production with safety measures
   - [ ] Never, too risky

**Answers**: 1-B, 2-C, 3-C, 4-B, 5-C, 6-C, 7-B, 8-C

---

## 🎯 Part 11: Module Summary & Next Steps

### What You Learned

✅ **Advanced Incident Response**: ICS framework, roles, communication  
✅ **Root Cause Analysis**: 5 Whys, Fishbone, Fault Tree  
✅ **Blameless Postmortems**: Learning culture, templates, follow-through  
✅ **Automation**: Detection, creation, remediation  
✅ **Chaos Engineering**: Building confidence through controlled failure  
✅ **Metrics**: MTTR, MTTD, effectiveness measurement

### DORA Capabilities Achieved

- ✅ **MTTR**: Elite level (< 1 hour) achievable with these practices
- ✅ **Incident Management**: Structured, repeatable process
- ✅ **Postmortem Culture**: Learning organization principles
- ✅ **Proactive Reliability**: Chaos engineering prevents incidents

### Key Takeaways

1. **Prepare before incidents happen** - Runbooks, automation, practice
2. **Blameless culture enables learning** - Focus on systems, not people
3. **Measure to improve** - Track MTTR, detection time, repeat incidents
4. **Chaos engineering builds confidence** - Break things intentionally to learn
5. **Follow through on action items** - Learning without action is wasted
6. **Communication is critical** - Keep stakeholders informed
7. **Every incident is an opportunity** - To learn and improve

### Real-World Impact

"After implementing advanced incident management practices:
- **MTTR**: 45 minutes → 12 minutes (73% improvement)
- **Repeat incidents**: 30% → 5%
- **Detection time**: 15 minutes → 2 minutes
- **Action item completion**: 40% → 85%
- **Team confidence**: Significantly improved
- **Customer satisfaction**: NPS +15 points

We transformed from reactive firefighting to proactive reliability engineering."
- *SRE Team, SaaS Platform*

---

## 🎉 Brown Belt Complete!

### 🏆 Congratulations!

You've completed all four Brown Belt modules:
- ✅ Module 13: Observability Fundamentals
- ✅ Module 14: DORA Metrics Deep Dive
- ✅ Module 15: SLIs, SLOs, and Error Budgets
- ✅ Module 16: Incident Management (Advanced)

### 🎖️ Brown Belt Progress

```
Brown Belt: Observability & SRE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Module 13: Observability          ████████░░░░ 25% ✓
Module 14: DORA Metrics           ████████░░░░ 50% ✓
Module 15: SLIs/SLOs/Budgets      ████████░░░░ 75% ✓
Module 16: Incident Management    ████████████ 100% ✓
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### 📜 Brown Belt Certification

**You're now ready for the Brown Belt Certification Exam!**

**Exam Format**:
- 50 multiple choice questions
- 4 hands-on challenges:
  1. Build complete observability stack
  2. Implement DORA metrics collection
  3. Define SLIs/SLOs and error budgets
  4. Conduct incident response simulation
- 85% passing score required
- 3-hour time limit

**Schedule Your Exam**:
- Visit Fawkes Dojo Portal
- Navigate to Certifications → Brown Belt
- Click "Schedule Exam"

### 🎓 What You've Achieved

**Skills Mastered**:
- ✅ Comprehensive observability (metrics, logs, traces)
- ✅ DORA metrics automation and analysis
- ✅ SLI/SLO definition and error budget management
- ✅ Advanced incident response and management
- ✅ Blameless postmortem facilitation
- ✅ Chaos engineering experiments
- ✅ SRE best practices

**DORA Impact**:
- **Deployment Frequency**: Confidence to deploy with observability
- **Lead Time**: Fast feedback from comprehensive monitoring
- **Change Failure Rate**: Detect issues immediately
- **MTTR**: Elite performance (< 1 hour, often < 15 min)

### 🚀 What's Next?

**Option 1: Take Brown Belt Certification Exam**
- Validate your observability and SRE mastery
- Earn "Fawkes SRE Practitioner" badge
- Get LinkedIn-verified credential

**Option 2: Continue to Black Belt**
- Module 17: Platform Architecture & Design
- Module 18: Multi-Tenancy & RBAC
- Module 19: Cost Optimization
- Module 20: Platform Team Leadership

**Option 3: Apply to Production**
- Implement full observability stack
- Define SLIs/SLOs for your services
- Create incident response automation
- Conduct chaos engineering experiments
- Share learnings with community

---

## 📚 Additional Resources

### Books
- *Site Reliability Engineering* - Google (free online)
- *The Site Reliability Workbook* - Google
- *Observability Engineering* - Charity Majors et al.
- *Chaos Engineering* - Casey Rosenthal

### Tools & Platforms
- [Chaos Mesh](https://chaos-mesh.org/) - Kubernetes chaos engineering
- [Gremlin](https://www.gremlin.com/) - Chaos engineering platform
- [PagerDuty](https://www.pagerduty.com/) - Incident management
- [Blameless](https://www.blameless.com/) - SRE platform

### Learning Resources
- [Google SRE Books](https://sre.google/books/)
- [Chaos Engineering Principles](https://principlesofchaos.org/)
- [Postmortem Culture](https://sre.google/sre-book/postmortem-culture/)
- [VOID Report](https://void.report/) - Postmortem database

### Community
- [SRE Weekly Newsletter](https://sreweekly.com/)
- [Chaos Engineering Slack](https://chaos-community.slack.com/)
- [Fawkes Mattermost](https://mattermost.fawkes.internal) - #brown-belt
- Share your certification achievement!

---

## 🏅 Module Completion

### Assessment Checklist

To complete this module, you must:

- [ ] **Conceptual Understanding**
  - [ ] Explain incident response framework
  - [ ] Understand root cause analysis techniques
  - [ ] Know blameless postmortem principles
  - [ ] Understand chaos engineering

- [ ] **Practical Skills**
  - [ ] Execute incident response simulation
  - [ ] Write comprehensive postmortem
  - [ ] Create incident automation
  - [ ] Design chaos experiments
  - [ ] Build incident metrics dashboard

- [ ] **Hands-On Lab**
  - [ ] Complete incident simulation
  - [ ] MTTR < 50 minutes achieved
  - [ ] Postmortem documented
  - [ ] Automation implemented

- [ ] **Quiz**
  - [ ] Score 80% or higher (6/8 questions)

### Certification Credit

Upon completion, you earn:
- **10 points** toward Brown Belt certification (100% complete!)
- **Badge**: "Incident Response Expert"
- **Skill Unlocked**: Advanced SRE Practices

---

## 📊 Overall Dojo Progress

```
Overall Progress: ███████░░░ 70% (14/20 modules)

By Belt:
White  ░░░░░░░░░░   0% (needs migration from old docs)
Yellow ██████████ 100% ✅ COMPLETE
Green  ██████████ 100% ✅ COMPLETE
Brown  ██████████ 100% ✅ COMPLETE
Black  ░░░░░░░░░░   0% (Platform Architecture next)
```

**🎉 Major Milestone: Brown Belt Complete!**

You've mastered observability, SRE practices, and incident management. You're now equipped to run highly reliable services at scale.

---

## 📖 Appendix A: Incident Response Cheat Sheet

### Quick Reference

**Severity Assessment** (< 1 min):
```
SEV0: Complete outage + data loss
SEV1: Complete outage OR revenue impact
SEV2: Major feature broken
SEV3: Minor degradation
SEV4: Cosmetic issue
```

**Initial Response** (< 5 min):
```
1. Acknowledge alert
2. Assess severity
3. Create war room
4. Assemble team
5. Post initial notification
6. Begin investigation
```

**Communication Cadence**:
```
SEV0/1: Every 15 minutes
SEV2:   Every 30 minutes
SEV3:   Every hour
```

**Key Commands**:
```bash
# Check recent deployments
kubectl rollout history deployment/SERVICE

# View logs
kubectl logs -l app=SERVICE --tail=100

# Rollback
kubectl rollout undo deployment/SERVICE

# Scale
kubectl scale deployment/SERVICE --replicas=10

# Check metrics
curl prometheus:9090/api/v1/query?query=...
```

---

## 📖 Appendix B: Postmortem Template (Condensed)

```markdown
# Postmortem: [TITLE]

**Date**: YYYY-MM-DD
**Duration**: X minutes
**Severity**: SEVX
**Impact**: [User/Business impact]

## Timeline
[Key events with timestamps]

## Root Cause
[Primary cause + contributing factors]

## What Went Well ✅
[Positive aspects]

## What Went Wrong ❌
[Areas for improvement]

## Action Items

| Action | Owner | Deadline | Status |
|--------|-------|----------|--------|
| ...    | ...   | ...      | ...    |

## Lessons Learned
[Key takeaways]
```

---

## 📖 Appendix C: Chaos Engineering Safety Checklist

Before conducting chaos experiments:

```markdown
## Pre-Flight Checklist

- [ ] Hypothesis clearly defined
- [ ] Expected outcome documented
- [ ] Success criteria established
- [ ] Blast radius minimized (% of traffic/instances)
- [ ] Monitoring in place to observe impact
- [ ] Rollback plan ready
- [ ] Team notified and ready to respond
- [ ] Off-peak hours selected (if applicable)
- [ ] Executive approval (for production experiments)
- [ ] Customer communication plan (if needed)

## During Experiment

- [ ] Monitor metrics in real-time
- [ ] Team ready to abort if needed
- [ ] Document observations
- [ ] Communicate status

## Post-Experiment

- [ ] Validate hypothesis (confirmed/rejected)
- [ ] Document findings
- [ ] Identify improvements
- [ ] Share learnings with team
```

---

**🎉 Congratulations on completing Brown Belt!**

You've achieved mastery in observability, SRE practices, and incident management. You can now:
- Build comprehensive monitoring systems
- Track and improve DORA metrics
- Manage services with SLIs/SLOs
- Respond to incidents like a pro
- Facilitate blameless postmortems
- Conduct chaos engineering safely

**Ready for Black Belt?** Module 17: Platform Architecture & Design awaits! 🚀

---

*Fawkes Dojo - Where Platform Engineers Are Forged*  
*Version 1.0 | Last Updated: October 2025*  
*License: MIT | https://github.com/paruff/fawkes*

**🎉 Brown Belt Complete - Congratulations, SRE Practitioner! 🎉**