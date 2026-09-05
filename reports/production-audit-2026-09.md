# Production Audit — 2026-09-04

> Generated via the `production-audit` skill. Tracks findings from the initial
> pass and follow-up work. Cross-references `docs/KNOWN_LIMITATIONS.md` and
> `docs/BACKLOG.md` where a finding already has an owner/issue instead of
> duplicating it.

## Summary

Initial score: **60/100, risky**. Capped by two independent gaps: no rollback
path for app deployments, and no state locking for Terraform. One blocker
(unauthenticated friction-bot endpoints) is fixed as of this pass.

**Updated 2026-09-05: 52/100, risky.** Live-tested the pipeline and
observability planes against the local Docker Desktop Kubernetes cluster (see
"Live Cluster Verification" below) instead of relying on static review alone.
Found a new, wide-blast-radius blocker (CNPG `initdb` segfaults for every
Postgres-backed service on this host/image combination) plus evidence that
last week's Jenkins/CNPG fix (`ce89f166`) doesn't yet hold up when a pod's
container-runtime sandbox is recreated (e.g. after a host restart) — both
lower the score versus the previous pass despite CI staying green throughout.

## Task List

| ID | Finding | Severity | Status | Evidence / next step |
|----|---------|----------|--------|----------------------|
| AUD-1 | `friction-bot`'s `/slack/slash/friction` and `/mattermost/slash/friction` had no real signature/token verification (Slack used a deprecated, non-constant-time "verification token" that fails open when unset; friction-bot is externally exposed via `platform/apps/friction-bot/ingress.yaml`) | Blocker | **Done** (this session) | Added `verify_slack_signature()` (Slack HMAC-SHA256 v0 scheme + 5-min replay window), hardened Mattermost token check to `hmac.compare_digest`, wired `SLACK_SIGNING_SECRET` through `secret.yaml`/`deployment.yaml`, added 9 unit tests (`services/friction-bot/tests/unit/test_main.py`) — all pass, ruff+black clean. **Operator action still needed:** set the real `slack-signing-secret` value in the cluster secret (currently an empty placeholder, same as `bot-token`) |
| AUD-2 | `smart-alerting`'s alert-ingestion (`/api/v1/alerts/*`) and acknowledge/resolve endpoints have no auth check at all; external exposure unconfirmed (no dedicated ingress manifest found under `platform/apps/smart-alerting/`) | Blocker (pending exposure confirmation) | Open | Confirm exposure first (check the ArgoCD-rendered Service/Ingress once deployed to a test cluster — see Evidence Collection below); if exposed, apply the same signature/token pattern as AUD-1, otherwise restrict via NetworkPolicy and document why no app-level auth is needed |
| AUD-3 | Terraform state has no remote backend or locking (`docs/KNOWN_LIMITATIONS.md` KL-01) — concurrent `apply` corrupts state, no DR path | Blocker | Open — **already tracked**, GAP-7 / issue #1153 in `docs/BACKLOG.md` | Not duplicating; infra change requires a second human reviewer per `AGENTS.md` §9 |
| AUD-4 | No progressive delivery, canary, or automated rollback — deployments are all-or-nothing on `main` push (`docs/DEPLOYMENT_STRATEGY.md`, only Phase 1 of 4 built) | Blocker | Open | See CI Recommendations below — `idp-e2e-tests.yml`'s kind-cluster pattern is the natural base for Phase 3 (canary) smoke tests |
| AUD-5 | 14+ of 18 services under `services/` have **zero CI** — no lint, test, build, or scan job references them. Only `tracer-bullet` and `dora-metrics` have dedicated workflows; `code-quality.yml`'s Python job only runs `pytest`/`mypy`/`pylint` against repo-root `tests/unit/`, not `services/*/tests/` | High | Open | `ai-code-review` already has a real pytest suite that has likely never run in CI; `friction-bot` now does too (this session). See CI Recommendations |
| AUD-6 | 45 Gherkin BDD feature files have no step definitions (`docs/KNOWN_LIMITATIONS.md` KL-05) — false coverage signal | Medium | Open — already tracked | No dedicated issue per KNOWN_LIMITATIONS; a local kind cluster (see below) can start closing this by giving the missing steps something real to exercise |
| AUD-7 | Two existing per-service pipelines (`tracer-bullet-ci.yml`, `dora-metrics-ci.yml`) hand-roll their own inline Trivy scan instead of the repo's existing `reusable-security-scanning.yml`, and neither wires up the existing `reusable-sbom-generation.yml` / `reusable-image-signing.yml` for their built images | Medium | Open | Consolidate onto the reusable workflows for consistency once the AUD-5 matrix job exists (same underlying pattern) |
| AUD-8 | Original audit didn't verify: UX/E2E coverage of launch-critical paths, `smart-alerting`'s real network exposure, whether the other 13 services share AUD-1/AUD-2's auth gap | — | Evidence missing | See Evidence Collection below |
| AUD-9 | **CNPG `initdb` segfaults live.** `db-sonarqube-dev`'s `initdb` container (`ghcr.io/cloudnative-pg/postgresql:16.4`, the exact image pinned in the committed `db-sonarqube-cluster.yaml`) crashes with `signal: segmentation fault` running `initdb --encoding=UTF8 --lc-collate=C --lc-ctype=C` on this host (amd64, no memory/disk pressure on the node). CNPG retries every ~90s and fails identically every time, including retries launched *after* `ce89f166` merged (06:45 UTC vs. merge at 06:39 UTC). Blocks all 8 CNPG-backed services (`db-harbor`, `db-sonarqube`, `db-backstage`, `db-datahub`, `db-focalboard`, `db-plausible`, `db-unleash`, `db-vsm`) identically, since they share this bootstrap path. | **Blocker** | Open, new | `kubectl logs db-sonarqube-dev-1-initdb-<pod> -n fawkes -c initdb` on the live cluster; cluster stuck in `status.conditions[0].reason=ClusterIsNotReady` since 2026-09-04T21:56:29Z |
| AUD-10 | **Jenkins controller still crash-loops live, contradicting `ce89f166`'s "verified live... zero errors" claim.** `jenkins-0`'s `init` container is in a restart back-off (7 restarts as of this audit) after the pod's container-runtime sandbox was recreated (a `SandboxChanged` event, consistent with the host's Docker Desktop having restarted since the fix was verified). The init container's plugin-copy step emits `cp: overwrite '<plugin>.jpi'?` prompts for every one of ~100 plugin files with no TTY attached to answer them. The original fix (dropping pinned plugin versions) was verified once against a **fresh** emptyDir; it was never exercised against a pod whose plugin cache already has files on disk from a prior run, which is exactly what a sandbox recreation produces. | **Blocker** | Open, new | `kubectl describe pod jenkins-0 -n fawkes` (Back-off restarting failed container init); `kubectl logs jenkins-0 -n fawkes -c init` |
| AUD-11 | **ArgoCD is not running in this cluster at all** (intentionally removed in a prior session per `cfb400be`'s own commit message, to free memory). The `prometheus-stack` and `ingress-nginx` `Application` CRs still exist in etcd and still report `Synced`/`Healthy` from their last reconcile at `2026-09-04T19:41:20Z` — but every actual Deployment/StatefulSet/DaemonSet/Pod the `prometheus-stack` app tree lists as `Healthy` has since been deleted from the `monitoring` namespace (`kubectl get pods -n monitoring` → zero results). An operator trusting `argocd app get` / the cached Application status on this cluster right now would see a fully healthy observability plane that does not exist. Not a code bug — a consequence of removing ArgoCD without also clearing its stale Application objects — but worth a documented gotcha given AGENTS.md's "GitOps is the source of truth" framing assumes a live reconciler. | Low (local-dev-only artifact) | Open, informational | `kubectl get ns argocd` (not found); `kubectl get application prometheus-stack -n fawkes -o jsonpath='{.status.reconciledAt}'` vs `kubectl get pods -n monitoring` |
| AUD-12 | `db-harbor-dev`'s live `Cluster.spec.imageName` (`ghcr.io/cloudnative-pg/postgresql:16.10`) doesn't match what's committed in `db-harbor-cluster.yaml` (`16.4`) — the object was likely hand-patched during a prior debugging session and never reconciled back to git (no ArgoCD running to catch the drift, per AUD-11). Its `initdb` pod has been wedged in `PodInitializing` for 9h with a stale "Pulling image" event, even though a manual `crictl pull` of the same tag on the node completes in seconds — a kubelet/CRI-level stuck state, not a registry problem. Recommend deleting the Cluster and letting it recreate from the current committed manifest for a clean read (not done in this pass to avoid piling more live changes into an audit). | Medium | Open, new | `kubectl get cluster db-harbor-dev -n fawkes -o jsonpath='{.spec.imageName}'`; `docker exec desktop-control-plane crictl pull ghcr.io/cloudnative-pg/postgresql:16.10` (completes immediately) |

## Evidence Collection Plan

You offered to stand up a local Kubernetes cluster on Docker (kind/k3d) — this
is the highest-leverage next step and unlocks several items above that can't
be verified from static code alone:

1. **Confirm real exposure (AUD-2, AUD-8).** Deploy `platform/apps/` manifests
   (or at least `smart-alerting`, `friction-bot`) to the local cluster and
   inspect the rendered `Service`/`Ingress` objects — this settles whether
   `smart-alerting` is actually reachable from outside the cluster.
2. **Audit the other services for AUD-1's pattern.** With a cluster available,
   grep + spot-check each service in `services/` with a `POST` webhook/slash-
   command-style endpoint for the same missing-verification pattern found in
   friction-bot, prioritizing anything with an `ingress.yaml`.
3. **Exercise the rollback protocol (AUD-4).** `docs/DEPLOYMENT_STRATEGY.md`
   documents a rollback protocol that has apparently never been run — deploy a
   known-good version, deploy a broken one, and manually walk the documented
   rollback steps to confirm they work as written (or find where they don't).
4. **Start closing BDD gaps (AUD-6).** Pick a handful of the 45 orphaned
   Gherkin scenarios that map to services reachable in the local cluster and
   implement real step definitions against it, rather than mocks.
5. **Terraform state locking (AUD-3) is NOT addressed by a local k8s cluster**
   — that's a `infra/` cloud-backend change (S3+DynamoDB, Azure Blob, etc.),
   already tracked as issue #1153.

## CI Recommendations

The repo already has solid reusable building blocks
(`reusable-tests.yml`, `reusable-lint.yml`, `reusable-security-scanning.yml`,
`reusable-sbom-generation.yml`, `reusable-image-signing.yml`,
`reusable-dependency-review.yml`, Dependabot, CodeQL, a full Terraform
validate/plan/cost/e2e pipeline in `terraform-tests.yml`) — the gap is
**adoption**, not missing capability:

1. **Highest priority: a per-service Python CI job (AUD-5).** Add a matrix job
   (or a new reusable workflow) that runs ruff/black/pytest for any directory
   under `services/*/` with a `requirements.txt`, triggered on
   `services/<name>/**` changes — mirroring what `tracer-bullet-ci.yml` and
   `dora-metrics-ci.yml` already do for their two services, but generalized.
   This is what would have caught friction-bot shipping with no test coverage
   in the first place, and it's what will actually run the tests just added.
2. **Consolidate the two existing per-service pipelines (AUD-7)** onto the
   shared `reusable-security-scanning.yml` / `reusable-sbom-generation.yml` /
   `reusable-image-signing.yml` instead of their current hand-rolled inline
   Trivy scans — removes duplication and gets SBOM+signing coverage on
   deployed images for free.
3. **Extend `idp-e2e-tests.yml`'s kind-cluster pattern** beyond
   `mcp-k8s-server` to smoke-test `/health` on each deployed service after a
   merge to `main` — this is a concrete, incremental step toward
   `DEPLOYMENT_STRATEGY.md`'s Phase 3/4 post-deployment verification, and can
   be prototyped locally first using the cluster from the Evidence Collection
   plan above.
4. **No new Terraform CI needed** — `terraform-tests.yml` already covers
   validate/plan/cost-estimation/integration/e2e; the KL-01/AUD-3 gap is the
   state *backend*, not CI validation.

Implementing any of #1-#3 means editing `.github/workflows/` — per `AGENTS.md`
§6 ("Must Ask Before... Modifying `.github/workflows/`"), that needs your
go-ahead before I touch it.
