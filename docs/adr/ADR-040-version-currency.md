# ADR-040: Version Currency for Stack Components

> **Status:** Proposed
> **Date:** 2026-11-27
> **Extends:** [ADR-034](ADR-034-tiered-dependency-pinning.md)
> **DORA Capability:** Cap 2 — Healthy Data Ecosystem

## Context

ADR-034 pins code libraries. It says nothing about the tools and applications the
platform installs. Their versions are set in manifests, shell scripts, Terraform,
workflows and Dockerfiles, and they disagree: on 2026-11-27 a laptop cluster and a
Terraform-built cluster could differ by three major Argo CD chart versions
([inventory](../ai-sdlc/version-currency/inventory.md), #2366). The difference
changed behaviour (#2323).

## Decision

**Latest stable** is the newest generally available release from the maintained
upstream source. Release candidates, betas and other pre-releases do not count.
A deprecated chart or an archived project is never current, whatever its number.

**When to take it:**

| Change | Wait after publication | How |
|---|---|---|
| Security fix | none | Next PR |
| Patch or minor | 7 days (the cooldown Dependabot already uses) | One PR per component |
| Major | 30 days | Its own issue: read upgrade notes, go one major at a time where upstream requires it, migrate CRDs and data first |

Where a project has long-term support lines (Node.js, Java, SonarQube), the newest
patch of a supported LTS line counts as current.

**One place per version:**

| Component | The place |
|---|---|
| Anything Argo CD installs | `targetRevision` in its one `Application` manifest |
| Argo CD itself | the `chart_version` default in `infra/terraform/argocd/variables.tf` |
| Container base images | the `FROM` line; all files using one image and variant use one version |
| Kubernetes | the cluster module's `kubernetes_version` variable |
| Vendored release YAML (Tekton) | the versioned file under `upstream/` |
| A chart's images | the chart's own default; an override needs a written reason |
| CI tools | the workflow or pre-commit hook; all copies agree |
| Terraform providers | `required_providers` plus the committed lock file |

A script or document that must repeat a version repeats it exactly. New code
should read it from the place above instead of copying it.

**Pinning:** every version is exact. No `latest`, no empty value that means
"whatever is newest today". One carve-out: CI setup
tools may name a language minor (`python-version: "3.13"`), which takes that
line's newest patch.

**Exceptions:** a component may stay behind with a written reason. A violation the
guard can see is listed in `tests/unit/version_pin_exceptions.yaml` with an issue
or reason; others are recorded in the inventory. An exception is removed in the PR
that fixes it.

**Done:** an upgrade is not done until it has been verified on a real cluster
(#2368). Passing file checks is not enough.

## Guard

`tests/unit/test_version_pins.py` runs with the unit tests in CI. It fails when a
version it can see is floating, when two files disagree, or when an exception no
longer matches.

It covers: Argo CD `Application` chart versions, `*_CHART_VERSION` in shell
scripts, the Argo CD Terraform `chart_version`, Dockerfile `FROM` and manifest
`image:` tags, `tag: latest`, setup versions in `.github/`, golangci-lint and
gitleaks, Trivy, shell `helm install` without `--version`, and install URLs on a
moving branch.

It does **not** cover: Kubernetes versions, Terraform provider constraints,
vendored Tekton files, other download URLs, language libraries, or
`platform/apps-deferred/`. It does not know what upstream has released; that is
the automation's job. It compares the set of versions, so a new file that copies
an already-excepted old version passes.

## Consequences

- A version change that updates only one of two copies now fails CI.
- Today's disagreements are visible as a list that can only shrink.
- Someone has to act on update PRs. Currency is only as good as the automation
  described in [automation.md](../ai-sdlc/version-currency/automation.md), which
  is not yet enabled (#2386).

## Alternatives Considered

| Option | Why rejected |
|---|---|
| One central `versions.yaml` that renders every file | Argo CD manifests are read as they are in Git; this adds a generation step to every change |
| Track `latest` | Not reproducible, and forbidden by `AGENTS.md` §6 |
| Manual quarterly review | This is what produced the current state |
