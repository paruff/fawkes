# Loosely Coupled Architecture Pattern

Loosely coupled architecture enables teams to deploy, test, and scale their services
independently. DORA research found that teams with loosely coupled architectures
achieve 56% reductions in lead time and deploy significantly more frequently than
teams with tightly coupled monolithic systems.

## What Loose Coupling Means

A loosely coupled system is one where:

- **Services communicate via stable APIs** — not direct database access or shared libraries
- **Failures are isolated** — a bug in Service A does not cascade to Service B
- **Teams are autonomous** — each team can deploy their service without coordinating with others
- **Data is owned** — each service owns its own data store and exposes it only through its API

## How Fawkes Enables Loose Coupling

**Kubernetes namespaces** create network and resource boundaries between services.
NetworkPolicy resources restrict which services can talk to which, preventing
unintended dependencies from forming.

**Service catalog (Backstage)** makes every service's API contract, ownership, and
dependencies explicit. Teams can see what they depend on and who depends on them.

**Async messaging** decouples producers from consumers in time. Services emit events
rather than calling each other directly for non-critical flows.

**API versioning** allows services to evolve independently. Consumers are not broken
by internal refactoring as long as the public API contract is maintained.

## Anti-Patterns to Avoid

- **Shared databases** — Two services writing to the same schema create tight coupling
  at the data layer and make independent deployment impossible.
- **Chatty synchronous chains** — A request that fans out to five downstream synchronous
  calls multiplies latency and failure probability.
- **Shared mutable configuration** — Services that read the same config file or
  environment variable at runtime cannot be deployed independently.

## Bounded Contexts

Use Domain-Driven Design bounded contexts to identify service boundaries. Each bounded
context owns its data model and evolves independently.

## See Also

- [Architecture Overview](../architecture.md)
- [GitOps Strategy](../explanation/architecture/gitops-strategy.md)
- [Kubernetes](../tools/kubernetes.md)
