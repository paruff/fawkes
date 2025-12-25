# Value Stream Mapping in Fawkes

## What is Value Stream Mapping?

Value Stream Mapping (VSM) is a lean management method for analyzing and improving the flow of work items from idea to delivery. In software development, it helps teams:

- **Visualize the entire workflow** from concept to production deployment
- **Identify bottlenecks** where work items get stuck or delayed
- **Measure flow metrics** like cycle time, lead time, and work in progress (WIP)
- **Optimize delivery** by reducing waste and improving flow efficiency
- **Make data-driven decisions** about process improvements

VSM provides visibility into your delivery pipeline, helping you understand where value is created and where delays occur.

## Fawkes Value Stream Stages

Fawkes implements an 8-stage value stream that tracks work items through their complete lifecycle:

### 1. Backlog (Wait Stage)

**Type**: Wait
**WIP Limit**: None
**Description**: Work items waiting to be analyzed and prioritized. This is the entry point to the value stream where new ideas, features, bugs, and tasks are collected before being pulled into active work.

**Key Activities**:

- Capture new work items
- Initial prioritization
- Refinement backlog grooming

**Typical Duration**: Variable (days to weeks)

---

### 2. Design (Active Stage)

**Type**: Active
**WIP Limit**: 5
**Description**: Active design and analysis phase where requirements are refined, architecture is designed, and implementation approach is planned.

**Key Activities**:

- Requirements analysis
- Architecture design
- Create design documents
- Define acceptance criteria
- Technical spike investigations
- User story refinement

**Typical Duration**: 1-3 days

**Exit Criteria**:

- Design document completed
- Acceptance criteria defined
- Technical approach agreed upon

---

### 3. Development (Active Stage)

**Type**: Active
**WIP Limit**: 10
**Description**: Active implementation phase where code is written, unit tests are created, and features are implemented according to design specifications.

**Key Activities**:

- Write code
- Create unit tests
- Local testing
- Self-review
- Create pull request

**Typical Duration**: 2-5 days

**Exit Criteria**:

- Implementation complete
- Unit tests passing
- Pull request created
- Self-review completed

---

### 4. Code Review (Wait Stage)

**Type**: Wait
**WIP Limit**: 8
**Description**: Work items waiting for peer review. Code changes are reviewed for quality, security, maintainability, and adherence to coding standards.

**Key Activities**:

- Peer code review
- Security review
- Architecture review
- Provide feedback
- Request changes if needed

**Typical Duration**: 0.5-2 days

**Exit Criteria**:

- Minimum 2 approvals received
- All comments addressed
- CI checks passing
- No blocking issues

---

### 5. Testing (Active Stage)

**Type**: Active
**WIP Limit**: 8
**Description**: Active testing phase including integration testing, acceptance testing, and quality assurance. QA validates functionality against requirements.

**Key Activities**:

- Integration testing
- Acceptance testing
- Performance testing
- Security scanning
- Bug verification
- Test automation

**Typical Duration**: 1-3 days

**Exit Criteria**:

- All acceptance tests passing
- Test coverage ≥ 80%
- No critical or high-severity bugs
- Test results documented

---

### 6. Deployment Approval (Wait Stage)

**Type**: Wait
**WIP Limit**: 5
**Description**: Work items waiting for deployment approval from stakeholders or release managers. This gate ensures proper change management and coordination before production deployment.

**Key Activities**:

- Review deployment plan
- Risk assessment
- Stakeholder approval
- Schedule deployment window
- Coordinate with operations

**Typical Duration**: 0.5-1 day

**Exit Criteria**:

- Deployment approved by release manager
- Deployment plan reviewed
- Deployment window scheduled
- Rollback plan prepared

---

### 7. Deploy (Active Stage)

**Type**: Active
**WIP Limit**: 3
**Description**: Active deployment phase where changes are rolled out to production. Includes deployment execution, smoke testing, and initial monitoring to ensure successful release.

**Key Activities**:

- Execute deployment
- Smoke testing
- Monitor metrics
- Verify deployment success
- Rollback if needed

**Typical Duration**: 0.5-2 hours

**Exit Criteria**:

- Deployment completed successfully
- Smoke tests passing
- Monitoring alerts clear
- No errors in logs

---

### 8. Production (Done Stage)

**Type**: Done
**WIP Limit**: None
**Description**: Work items successfully deployed and running in production. This is the final stage indicating value delivery to end users.

**Outcomes**:

- Value delivered to users
- Feature available in production
- Metrics being collected
- Monitoring active

**What Happens Next**:

- Items remain in Production indefinitely
- Can spawn new work items for enhancements
- Contribute to throughput metrics
- Used for cycle time calculations

---

## Stage Types Explained

### Wait Stages

Stages where work items are idle, waiting for someone else to act:

- **Backlog**: Waiting for prioritization and team capacity
- **Code Review**: Waiting for reviewer attention
- **Deployment Approval**: Waiting for stakeholder decision

**Impact on Metrics**:

- Increases lead time
- Reduces flow efficiency
- Does not consume team capacity

### Active Stages

Stages where work is being actively performed:

- **Design**: Active analysis and planning
- **Development**: Active coding
- **Testing**: Active quality assurance
- **Deploy**: Active deployment execution

**Impact on Metrics**:

- Increases cycle time
- Improves flow efficiency
- Consumes team capacity

### Done Stage

The final stage indicating completion:

- **Production**: Work delivered and running

**Impact on Metrics**:

- Marks completion for throughput
- Ends cycle time measurement
- Exits WIP count

---

## How to Track Work Items

### Creating a Work Item

```bash
curl -X POST http://vsm-service/api/v1/work-items \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Add user authentication",
    "type": "feature"
  }'
```

**Work Item Types**:

- `feature`: New functionality
- `bug`: Defect fix
- `task`: Operational work
- `epic`: Large initiative (tracked at high level)

### Transitioning Between Stages

```bash
curl -X PUT http://vsm-service/api/v1/work-items/123/transition \
  -H "Content-Type: application/json" \
  -d '{
    "to_stage": "Development"
  }'
```

### Viewing Work Item History

```bash
curl http://vsm-service/api/v1/work-items/123/history
```

This returns complete stage transition history with timestamps, allowing you to see exactly how long the item spent in each stage.

---

## Understanding Flow Metrics

### Throughput

**Definition**: Number of work items completed in a time period
**Calculation**: Count of items reaching Production stage
**Target**: Increasing trend over time
**Use**: Measure team delivery rate

```bash
curl http://vsm-service/api/v1/metrics?days=7
```

### Work In Progress (WIP)

**Definition**: Number of work items currently in flight
**Calculation**: Items with transitions but not yet in Production
**Target**: Keep within WIP limits
**Use**: Prevent overloading and multitasking

**WIP Limits by Stage**:

- Design: 5 items
- Development: 10 items
- Code Review: 8 items
- Testing: 8 items
- Deployment Approval: 5 items
- Deploy: 3 items

**Why WIP Limits Matter**:

- Forces completion before starting new work
- Identifies bottlenecks quickly
- Reduces context switching
- Improves flow and quality

### Cycle Time

**Definition**: Time from starting work to completing it
**Calculation**: Time from Backlog → Production
**Target**: Consistent and decreasing
**Use**: Measure speed of delivery

**Percentiles**:

- **P50 (Median)**: 50% of items complete faster
- **P85**: 85% of items complete faster (good target)
- **P95**: 95% of items complete faster (handle outliers)

### Lead Time

**Definition**: Total time from idea to production
**Calculation**: Time from creation → Production
**Use**: Customer perspective on delivery speed

### Flow Efficiency

**Definition**: Ratio of active time to total time
**Calculation**: (Active stage time) / (Total cycle time)
**Target**: > 40% (industry average is 15%)
**Use**: Identify waste and wait time

**Formula**:

```
Flow Efficiency = Active Time / (Active Time + Wait Time)
Active Time = Design + Development + Testing + Deploy
Wait Time = Backlog + Code Review + Deployment Approval
```

---

## Identifying Bottlenecks

Bottlenecks are stages where work items accumulate and slow down flow. Use these indicators:

### 1. High WIP in a Stage

**Symptom**: Stage consistently at or above WIP limit
**Example**: 8+ items in Code Review stage

**Investigation**:

```bash
# Check current WIP by stage
curl http://vsm-service/api/v1/metrics | jq '.wip'

# View Prometheus metrics
curl http://vsm-service/metrics | grep vsm_work_in_progress
```

**Root Causes**:

- Insufficient capacity (not enough reviewers)
- Quality issues (many rounds of feedback)
- Unclear requirements (confusion about what to build)

**Solutions**:

- Add more reviewers or pair review
- Improve design phase to catch issues earlier
- Set stricter WIP limits to force focus
- Implement automated checks (linting, security scans)

### 2. Long Cycle Time

**Symptom**: Items taking much longer than expected
**Example**: P85 cycle time > 7 days for features

**Investigation**:

```bash
# Get cycle time metrics
curl http://vsm-service/api/v1/metrics?days=30

# Check specific work item history
curl http://vsm-service/api/v1/work-items/123/history
```

**Root Causes**:

- Blocked on dependencies
- Scope creep during development
- Inadequate testing environment
- Deployment delays

**Solutions**:

- Break down large items earlier
- Improve dependency management
- Invest in CI/CD and test automation
- Reduce deployment approval overhead

### 3. Low Flow Efficiency

**Symptom**: Most time spent in wait stages
**Example**: Flow efficiency < 30%

**Investigation**:

- Calculate time in wait vs active stages
- Identify which wait stages have longest delays

**Root Causes**:

- Batch processing (waiting for reviews to accumulate)
- Long approval processes
- Limited deployment windows

**Solutions**:

- Review code more frequently (daily)
- Automate approval for low-risk changes
- Implement continuous deployment
- Reduce batch sizes

### 4. Low Throughput

**Symptom**: Fewer items completed than expected
**Example**: Only 5 features completed per month

**Investigation**:

```bash
# Check throughput trend over time
curl http://vsm-service/api/v1/metrics?days=90
```

**Root Causes**:

- Too much WIP (multitasking)
- Large batch sizes (big features)
- Bottlenecks in flow
- Quality issues causing rework

**Solutions**:

- Reduce WIP limits
- Break work into smaller pieces
- Address bottlenecks systematically
- Invest in quality earlier in flow

---

## Continuous Improvement Process

Use VSM data to drive continuous improvement through regular cadence:

### 1. Daily Flow Review (5 minutes)

**Participants**: Development team
**Focus**: Current state

**Questions**:

- Are any stages at WIP limit?
- Are any items blocked?
- What's the oldest item in each stage?
- Are there any impediments?

**Actions**:

- Unblock items
- Swarm on bottlenecks
- Pair to finish in-progress work

### 2. Weekly Metrics Review (30 minutes)

**Participants**: Team + stakeholders
**Focus**: Trends and patterns

**Metrics to Review**:

- Throughput (completed items)
- WIP by stage
- Cycle time percentiles (P50, P85, P95)
- Flow efficiency

**Questions**:

- Is throughput increasing or stable?
- Where is WIP accumulating?
- Is cycle time predictable?
- Which stages have longest wait times?

**Outputs**:

- Identify top bottleneck
- Propose improvement experiment
- Assign action items

### 3. Monthly Retrospective (1-2 hours)

**Participants**: Entire team
**Focus**: Deep analysis and improvement

**Activities**:

1. Review month's metrics
2. Analyze specific work item journeys
3. Identify systemic issues
4. Celebrate improvements
5. Plan experiments for next month

**Experiments to Try**:

- Adjust WIP limits (increase or decrease)
- Change review processes
- Automate manual steps
- Restructure stages
- Add/remove stage transitions

### 4. Quarterly Planning

**Participants**: Leadership + teams
**Focus**: Strategic improvements

**Questions**:

- Are we delivering value faster?
- What systemic impediments remain?
- Do our stages reflect actual work?
- Are WIP limits appropriate?

**Actions**:

- Update value stream design
- Invest in tooling/automation
- Adjust team structure if needed
- Set improvement goals for next quarter

---

## Best Practices

### Do's ✅

- **Pull work** rather than push (respect WIP limits)
- **Finish work** before starting new items
- **Make flow visible** to entire team
- **Address bottlenecks** systematically
- **Measure everything** to enable data-driven decisions
- **Keep stages simple** and reflect actual work
- **Review metrics regularly** as a team
- **Celebrate improvements** in flow metrics
- **Experiment** with process changes
- **Focus on flow** not individual utilization

### Don'ts ❌

- **Don't exceed WIP limits** without good reason
- **Don't start new work** when items are blocked
- **Don't ignore wait times** (they matter!)
- **Don't optimize individual stages** at expense of overall flow
- **Don't blame individuals** for bottlenecks (it's a system issue)
- **Don't make stages too granular** (keep it manageable)
- **Don't ignore data** in favor of opinions
- **Don't change too many things** at once (experiment scientifically)
- **Don't measure success** by individual velocity
- **Don't forget the customer** (focus on value delivery)

---

## Integration with Other Systems

### Backstage Integration

VSM service integrates with Backstage to show flow metrics on component pages:

```yaml
# In catalog-info.yaml
metadata:
  annotations:
    fawkes.io/vsm-enabled: "true"
```

### Jenkins Integration

Jenkins pipelines automatically update VSM on key events:

```groovy
// In Jenkinsfile
post {
    success {
        updateVSMStage(workItemId: env.WORK_ITEM_ID, stage: 'Deploy')
    }
}
```

### Prometheus/Grafana

VSM exports metrics to Prometheus for dashboarding:

```promql
# Throughput rate (items/day)
rate(vsm_stage_transitions_total{to_stage="Production"}[7d]) * 86400

# Average WIP
avg(vsm_work_in_progress)

# Cycle time P85
histogram_quantile(0.85, vsm_cycle_time_hours_bucket)
```

---

## API Reference

### List Stages

```bash
GET /api/v1/stages
```

Returns all configured stages with their properties:

```json
[
  {
    "id": 1,
    "name": "Backlog",
    "order": 1,
    "type": "backlog"
  },
  ...
]
```

### Create Work Item

```bash
POST /api/v1/work-items
Content-Type: application/json

{
  "title": "Implement feature X",
  "type": "feature"
}
```

### Transition Work Item

```bash
PUT /api/v1/work-items/{id}/transition
Content-Type: application/json

{
  "to_stage": "Development"
}
```

### Get Work Item History

```bash
GET /api/v1/work-items/{id}/history
```

### Get Flow Metrics

```bash
GET /api/v1/metrics?days=7
```

---

## Troubleshooting

### Work item stuck in stage

**Check**:

1. Is there a blocker? (add comment/label)
2. Is stage at WIP limit?
3. Are required fields missing for transition?
4. Are there dependencies not yet complete?

**Resolution**:

- Address blocker or mark as blocked
- Finish other work to free up capacity
- Gather required information
- Coordinate with dependent teams

### Metrics not updating

**Check**:

1. Is VSM service running? `kubectl get pods -n fawkes`
2. Are transitions being recorded? Check logs
3. Is database connection healthy? `/api/v1/health`

**Resolution**:

- Restart VSM service pod
- Check database connectivity
- Verify transition API calls succeed

### WIP limit violations

**Check**:

1. Why was limit exceeded? (urgent issue?)
2. Is limit too low for team size?
3. Are items being finished?

**Resolution**:

- Enforce limit strictly going forward
- Swarm to finish existing items
- Review if limit needs adjustment
- Identify why items not completing

---

## Additional Resources

- [VSM Service README](../../services/vsm/README.md)
- [Stage Configuration](../../services/vsm/config/stages.yaml)
- [Transition Rules](../../services/vsm/config/transitions.yaml)
- [Flow Metrics Dashboard](http://grafana.fawkes.local/d/vsm-flow-metrics)
- [Prometheus Metrics](http://prometheus.fawkes.local/graph?g0.expr=vsm_*)

---

## Summary

Value Stream Mapping in Fawkes provides visibility into your delivery pipeline through:

1. **8 well-defined stages** tracking work from idea to production
2. **Clear stage types** (wait/active/done) to understand flow
3. **WIP limits** to prevent overload and identify bottlenecks
4. **Flow metrics** to measure throughput, cycle time, and efficiency
5. **Continuous improvement process** driven by data
6. **API and integrations** for automation and visibility

By using VSM effectively, teams can:

- Deliver value faster and more predictably
- Identify and remove bottlenecks
- Make data-driven process improvements
- Increase customer satisfaction through faster delivery

Start by visualizing your current flow, then use the metrics to guide incremental improvements over time.
