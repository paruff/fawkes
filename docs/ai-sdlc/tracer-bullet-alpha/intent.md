# Intent: fawkes Tracer Bullet Alpha

**Traces to:** the suite release plan,
[Phase 6](https://github.com/paruff/uFawkes.dev/blob/main/docs/ai-sdlc/suite-release/plan.md#phase-6--fawkes-alpha--dojo-06-gate-ac-fawkes-0104),
and the epic paruff/fawkes#1804.

**Who:** a platform engineer who has run a uFawkes stack on Docker Compose and
wants to see the same ideas on Kubernetes.

**Job:** watch one service go from a commit to staging in a single clean run,
and read two DORA metrics for it.

**Why now:** fawkes is pre-alpha. Alpha is its first release, and the last of
the suite's six.

**Outcome:** the four criteria in [`spec.md`](spec.md) pass, each with a
linked run.

## Non-goals

Beta and Production, the Dojo curriculum, and a hosted CI service. What comes
after Alpha is [`../path-to-beta/plan.md`](../path-to-beta/plan.md).
