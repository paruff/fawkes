# Intent: Beta for a first adopter, then scale

**Traces to:** [`../path-to-beta/plan.md`](../path-to-beta/plan.md), which
this redefines (decided by the owner 2026-11-27), and the Beta epic
paruff/fawkes#1805. | **Spec:** [`spec.md`](spec.md)

**Who:** a distributed team, working in GitHub, building a startup's product
on cloud infrastructure it owns. They have not chosen the product's stack
yet. They expect to grow to millions of transactions within six to twelve
months, and they want serverless as the end state. They start on Kubernetes
on Azure (AKS) and move to AWS (EKS) once they have AWS access.

**Job:** specify, build, test and deploy their services through Fawkes
without help from a Fawkes maintainer, then run and observe those services
at scale.

**Why now:** this is Fawkes's first real adopter. Beta already meant "usable
by developers other than the maintainer"; a real team on its own cloud
account is a stronger test of that than Fawkes's own services.

**Fawkes stays open source.** Nothing that names or configures the adopter
lands in this repo. Every change is a golden path, template, module or doc
that any team could use.

## Outcomes, in order

1. **Goal 1, Beta (six weeks):** the delivery pipeline. A developer on the
   adopter's team scaffolds a service from a Fawkes template, pushes to
   `main`, and it reaches staging on their AKS cluster and production through
   a reviewed promotion, with its DORA metrics on the dashboard and no
   maintainer involved.
2. **Goal 2, scale (after Goal 1):** monitoring and managing that
   infrastructure for millions of transactions, moving the workloads to
   serverless on Kubernetes, and proving the move from AKS to EKS.

Goal 2 starts when Goal 1's acceptance criteria pass. Its spec is
written then, from what Goal 1 teaches.

## Non-goals

- Running the adopter's infrastructure for them. They own the cloud
  subscription and the cluster. Fawkes is the delivery system they install
  into it, from versioned releases.
- Real customer traffic during Beta. The adopter has no customers before
  Goal 2.
- Merging Fawkes's own 17 services into two monoliths (#2116). It continues
  beside Beta, as path-to-Beta decision D2 already said, but no longer gates it.
- The cloud's own function services (Lambda, Azure Functions). Serverless
  means scale-to-zero on Kubernetes, so it moves between clouds unchanged.
- The Dojo curriculum.

## Anti-goals

These would make the work a failure even if every check passed:

- The adopter's team needs a maintainer to ship a change.
- A DORA panel shows a number that nothing measured.
- The pipeline works on Azure in a way that makes the move to AWS a rewrite.
- Adopter-specific code or values in this public repo.
