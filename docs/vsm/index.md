# Value Stream Mapping (VSM)

This section covers value stream mapping documentation, metrics, and optimization for the Fawkes platform.

## Overview

Value Stream Mapping helps visualize and optimize the flow of work from idea to production, identifying bottlenecks and waste in the delivery process. A VSM exercise reveals where work waits, where handoffs lose context, and where automation can eliminate toil.

In the Fawkes platform, VSM data is collected automatically from Git, CI, and incident systems, enabling continuous measurement without manual facilitation sessions.

## Documentation

- [Value Stream Mapping](value-stream-mapping.md) - VSM methodology and practices

## Implementation

- [VSM Implementation Complete](../implementation-notes/VSM_IMPLEMENTATION_COMPLETE.md) - Completed VSM implementation
- [VSM Implementation Summary](../implementation-notes/VSM_IMPLEMENTATION_SUMMARY.md) - Technical implementation details

## Related Concepts

### DORA Metrics

VSM directly supports DORA metrics measurement:

- **Deployment Frequency** - How often work flows to production
- **Lead Time for Changes** - Time through the value stream
- **Change Failure Rate** - Quality indicators in the stream
- **Time to Restore Service** - Recovery time measurement

See also:

- [DORA Metrics Tutorial](../tutorials/6-measure-dora-metrics.md) - Getting started with DORA metrics
- [DORA Metrics Playbook](../playbooks/dora-metrics-implementation.md) - Implementation guide
- [View DORA Metrics](../how-to/observability/view-dora-metrics-devlake.md) - Access dashboards

## Related Documentation

- [Observability](../observability/index.md) - Monitoring and metrics
- [Patterns](../patterns/index.md) - Value stream patterns
- [Playbooks](../playbooks/index.md) - Implementation playbooks
