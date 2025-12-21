# VSM Configuration

This directory contains configuration files for the VSM (Value Stream Mapping) service.

## Files

### stages.yaml
Defines the 8 value stream stages that work items flow through:

1. **Backlog** (wait) - Work items waiting to be analyzed
2. **Design** (active) - Active design and analysis phase
3. **Development** (active) - Active implementation phase
4. **Code Review** (wait) - Waiting for peer review
5. **Testing** (active) - Active testing and QA phase
6. **Deployment Approval** (wait) - Waiting for deployment approval
7. **Deploy** (active) - Active deployment to production
8. **Production** (done) - Successfully deployed and running

Each stage includes:
- **name**: Stage name
- **type**: Category (wait/active/done) for flow metrics
- **order**: Sequence in the value stream
- **wip_limit**: Work in progress limit (null = no limit)
- **description**: Detailed explanation of the stage

### transitions.yaml
Defines the rules for moving work items between stages:

- **Allowed transitions**: Valid stage-to-stage movements
- **Required fields**: Data needed for each transition
- **Automated transitions**: Transitions triggered by external events
- **Validation rules**: Checks to enforce before transitioning
- **Notifications**: Alerts sent when items transition
- **Backward transitions**: Rules for moving items back (rework)
- **Flow metrics**: Configuration for cycle time and lead time calculation

## Loading Stages

To load or update stages from the configuration:

```bash
# Load stages (skip existing)
python scripts/load-stages.py

# Update existing stages
python scripts/load-stages.py --update

# Dry run to see what would change
python scripts/load-stages.py --dry-run

# Use custom config file
python scripts/load-stages.py --config /path/to/stages.yaml
```

## Modifying Stages

To modify stages:

1. Edit `stages.yaml` with your changes
2. Run the load script with `--update` flag
3. Verify changes with the API: `GET /api/v1/stages`

**Note**: Changing stage names or order may affect existing work items. Consider the impact before making changes to production.

## WIP Limits

Work in Progress (WIP) limits prevent overloading and improve flow:

- **Backlog**: No limit (entry point)
- **Design**: 5 items
- **Development**: 10 items
- **Code Review**: 8 items
- **Testing**: 8 items
- **Deployment Approval**: 5 items
- **Deploy**: 3 items (small to control deployment risk)
- **Production**: No limit (completed items)

Adjust these limits based on your team size and capacity.

## Stage Types

### Wait Stages
Items are idle, waiting for action:
- Backlog
- Code Review
- Deployment Approval

**Impact**: Increases lead time but not cycle time (active work time).

### Active Stages
Items are being actively worked on:
- Design
- Development
- Testing
- Deploy

**Impact**: Consumes team capacity, counted in cycle time.

### Done Stage
Items are complete:
- Production

**Impact**: Marks completion for throughput metrics.

## Documentation

See [docs/vsm/value-stream-mapping.md](../../docs/vsm/value-stream-mapping.md) for complete documentation on:
- How to use VSM
- Understanding flow metrics
- Identifying bottlenecks
- Continuous improvement process
