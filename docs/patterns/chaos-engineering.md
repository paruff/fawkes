# Chaos Engineering Pattern

Chaos engineering is the practice of intentionally injecting failures into a system
to verify that it handles them gracefully. The goal is to discover weaknesses before
they cause user-impacting incidents, building confidence in the system's resilience.

## The Chaos Engineering Principle

As Netflix's Chaos Monkey demonstrated: **if you don't regularly kill things in your
system, you don't know how it will behave when they die on their own**. Systems that
are never stress-tested accumulate hidden assumptions about availability.

## Key Concepts

**Steady-state hypothesis** — Before running an experiment, define what "normal"
looks like: error rate < 0.1%, P95 latency < 200ms, all health checks green. The
experiment tests whether this steady state holds when a failure is injected.

**Blast radius** — Start small. Begin with non-production environments and single
instances. Progressively expand to production only after consistent steady-state
validation.

**Observability first** — You cannot run chaos experiments without good observability.
If you cannot measure steady state, you cannot validate hypotheses.

## Chaos Mesh in Fawkes

Fawkes uses [Chaos Mesh](https://chaos-mesh.org/) to run controlled experiments on
Kubernetes workloads.

```yaml
# Kill one pod from the backstage deployment
apiVersion: chaos-mesh.org/v1alpha1
kind: PodChaos
metadata:
  name: backstage-pod-kill
spec:
  action: pod-kill
  mode: one
  selector:
    namespaces: [backstage]
    labelSelectors:
      app: backstage
  duration: "30s"
```

## Experiment Types

| Type | What It Tests |
|------|--------------|
| **Pod kill** | Service handles pod restarts gracefully |
| **Network delay** | Timeouts and retries work correctly |
| **Network partition** | Split-brain scenarios are handled |
| **CPU stress** | Resource limits prevent cascade failures |
| **Memory pressure** | OOM events are handled gracefully |

## Gameday Process

1. Define hypothesis and blast radius
2. Set up monitoring dashboards and alerting
3. Run experiment in non-production first
4. Observe and record results
5. Fix any discovered weaknesses
6. Re-run in production during low-traffic window with approval

## See Also

- [Incident Response Pattern](incident-response.md)
- [Monitoring and Observability Pattern](monitoring-and-observability.md)
- [Architecture Overview](../architecture.md)
