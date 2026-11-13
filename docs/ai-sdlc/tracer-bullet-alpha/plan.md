# Plan: fawkes Tracer Bullet Alpha

**Traces to:** [`spec.md`](spec.md) → [`intent.md`](intent.md)

This plan lists no tasks. The sequence is
[Phase 6 of the suite plan](https://github.com/paruff/uFawkes.dev/blob/main/docs/ai-sdlc/suite-release/plan.md#phase-6--fawkes-alpha--dojo-06-gate-ac-fawkes-0104),
and the tasks are the Alpha epic's children (paruff/fawkes#1804) on
[Project #7](https://github.com/users/paruff/projects/7).

## Verification Strategy

| Criterion | Evidence |
| --- | --- |
| AC-FAWKES-01 | One CI run plus the ArgoCD sync history, linked (paruff/fawkes#1858) |
| AC-FAWKES-02 | A screenshot plus the PromQL behind each panel |
| AC-FAWKES-03 | paruff/fawkes#2004 and paruff/fawkes#1797 closed, with linked PRs |
| AC-FAWKES-04 | The suite's AC-SUITE-01 check, plus a README review |

### Make commands

Per [the suite's rule for `make` commands](https://github.com/paruff/uFawkes.dev/blob/main/docs/ai-sdlc/suite-release/spec.md#make-verification-commands). `make validate` here checks manifests in a running cluster (paruff/fawkes#2306); the hook gate is
`make lint`.

| Command | Proves | Needs |
| --- | --- | --- |
| `make lint` | Every pre-commit hook passes on every file | Nothing |
| `make format-check` | No file needs formatting | Nothing |
| `make test-unit`, `make test-bats` | Unit tests and the shell scripts' BATS tests pass | Nothing |
| `make terraform-validate` | The Terraform configurations are valid | Terraform |
| `make k8s-validate` | The Kubernetes manifests are valid | kubeval, kustomize, kubectl |
| `make dev-up`, then `make validate` | The local platform starts on k3d, and its manifests pass the policy checks | Docker, k3d, kubectl, helm |
| `make test-all` | Unit, BATS, BDD and integration tests pass | `make dev-up` first |
| `make doctor` | This clone's hooks are installed and its tools are present | Nothing |
