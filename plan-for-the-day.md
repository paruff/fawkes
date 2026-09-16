# Fawkes — Plan for the Day

> **Horizon:** Today (2026-09-16) | **Owner:** @paruff | **Review cadence:** Rewritten at the start of every work session

## Primary Goal

Finish the Azure AKS cutover to a working baseline: `terraform apply` the cluster, independently verify `kubectl` context (not trusting `ignite.sh`'s own check — see PR #2123), bootstrap ArgoCD, and get to a point where tomorrow's session (possibly a different agent — see note below) can pick up #2117's DORA-metrics work on a stable cluster instead of continuing to fight `mini-gamer`.

**Note for whoever picks this up next** (2026-09-16 note: today's session may be followed by an opencode/mimo session rather than the same agent/tool): this file and `EXECUTION_QUEUE.md` are written to be self-contained — read both before doing anything, don't assume conversational context carries over. The gotchas section below is the load-bearing part.

## What actually happened today (this replaces a normal "target issues" list — today was investigation-and-incident-response, not planned feature work)

1. Reviewed P0/P1 status in `EXECUTION_QUEUE.md`, found significant drift between claimed-done and actually-done (see PRs #2118, #2121)
2. Live-verified DevLake/DORA status on `mac-mini-k3s`: found KL-15's "DevLake deprecated, native PromQL replaces it" claim was aspirational, never executed — fixed the docs, wired `dora.yml` for real (PR #2118), filed #2117 for the actual remaining metrics-instrumentation work
3. Found and fixed a live incident: `mini-gamer` node down ~24h → ArgoCD reconciliation stuck → `tracer-bullet`/`python-fawkes-path` Application pruned because `path-based-applications`' generator pointed at a dead file path since #2054 (predates today). Re-applied `platform/bootstrap/`, which also deployed previously-inert Tekton/Argo Rollouts/Chaos Mesh Applications
4. Scoped a redesign of the golden-path ApplicationSet pattern (#2120) — today's incident is exactly the failure mode it fixes
5. Found the `argocd` Helm release on `mac-mini-k3s` has been `failed` since 2026-09-13 (three days, not caused today) — root cause (`argocd-redis-secret-init` hook failure) undiagnosed; `argocd-server`/`argocd-repo-server` still `CrashLoopBackOff` as of end of session
6. **Decision: move to Azure AKS** rather than keep fighting `mini-gamer` specifically (not k3s as a technology — `lima-k3s-worker`, the other node, was reliable throughout)
7. Found and fixed a real bug in `scripts/ignite.sh`'s Azure path (#1972) before using it for the cutover — it could silently bootstrap onto the wrong cluster with no error (PR #2123, merged)
8. Scoped SRE practices (#2124: detection/alerting before error budgets) and a CI-gated terraform-apply pipeline (#2126 — today's manual applies are a symptom of this gap, not the right pattern going forward)
9. Azure cutover in progress: state backend + RBAC done, `terraform apply` for the AKS cluster itself is the next concrete step

## Gotchas found today (read before touching any of this again)

- **`mac-mini-k3s`'s ArgoCD is currently broken** (`argocd-server`/`argocd-repo-server` `CrashLoopBackOff`, Helm release `failed`). Deprioritized given the Azure decision, not fixed. If anyone goes back to this cluster: the `argocd-redis-secret-init` pre-upgrade hook is the actual blocker, root cause not yet found (its pod is garbage-collected before logs can be read; would need to catch it live via `crictl -r unix:///run/k3s/containerd/containerd.sock logs <id>` during a fresh apply attempt).
- **`kubectl logs`/`kubectl exec` don't work against pods on `mini-gamer`** — a pre-existing, unresolved `502 Bad Gateway` proxying to its kubelet on port 10250. Confirmed general (fails even for long-stable pods), not workload-specific. Use `crictl` directly on that node instead of `kubectl logs`.
- **Tekton is `CrashLoopBackOff` on `mac-mini-k3s`**, cause undiagnosed (same log-proxy issue blocks remote diagnosis). Not worth chasing further given the Azure move — will be reinstalled fresh on AKS.
- **`scripts/ignite.sh --provider azure` was unsafe until PR #2123 merged** (today) — always confirm you're running the post-fix version before trusting its cluster-context detection.
- **Don't trust `platform/bootstrap/`'s live state without checking it against git** — it's a manual-apply layer, not self-reconciling; it silently drifted for days after #2054 and nobody noticed.
- **`infra/aws/` and `infra/gcp/` haven't been checked for the same `kubeconfig`-writing gap** PR #2123 fixed for Azure — flagged as a follow-up in that PR, not yet done.

## TDD Execution Protocol (per `AGENTS.md` §2)

For the Azure cutover's remaining steps:

1. **State the goal as a verifiable check** — `terraform apply` completing with the AKS cluster `Ready`, then `kubectl config current-context` printing `fawkes-dev-aks` (not `mac-mini-k3s`) as independent proof, not just `ignite.sh`'s own report
2. **Run it and confirm the right starting state** — currently: state backend exists, RBAC granted, `terraform init` should now succeed (last checked: blocked on RBAC propagation)
3. **Minimum change to pass** — don't scope-creep into re-deploying every golden path in one sitting; AKS `Ready` + ArgoCD bootstrapped is the actual done-line for today
4. **Re-run and link evidence** — `kubectl get nodes`/`kubectl get applications -n argocd` output, not "should be up"

## Retrospective

**What actually got done:**
- P0/P1 audit and correction (PRs #2118, #2121) — merged
- `mac-mini-k3s` ArgoCD reconciliation restored (temporarily — see gotchas, it's since broken again for a different reason)
- `scripts/ignite.sh` Azure kubeconfig bug found and fixed (PR #2123) — merged
- 4 new tracking issues scoped: #2117 (DORA metrics prerequisite), #2120 (ApplicationSet redesign), #2124 (SRE practices), #2126 (CI-gated apply)
- Azure cutover started: state backend + RBAC done

**What surprised us (feeds `EXECUTION_QUEUE.md`'s bottom-up feedback):**
- The scale of silent drift: an ApplicationSet generator broken since #2054, a Helm release failed since 2026-09-13, a kubeconfig bug that's existed since `ignite.sh`'s Azure path was written — none of it detected until this session went looking. This is the actual argument for #2124, not a hypothetical one.
- "P0 done" claims in this queue have been wrong often enough this week that live verification (not doc/PR-body trust) should probably be the default posture going forward, not an occasional audit.

**Backlog deltas:**
- New P0: Azure AKS cutover (supersedes continued `mac-mini-k3s` debugging)
- #2117 moved from "OPEN, not started" to "OPEN, blocked on AKS cutover" — target infrastructure changed mid-flight
- #1919/#2079/#1946/#2081 (P2) rescoped away from DevLake, now depend on #2117

**Carry over to tomorrow:**
- Finish `terraform apply` for AKS (blocked on RBAC propagation as of end of session)
- Verify `kubectl` context independently before any further action on the new cluster
- Bootstrap ArgoCD on AKS, redeploy #2117/#2120's target state there
- `mac-mini-k3s`'s broken ArgoCD Helm release and crash-looping Tekton are left as-is (deprioritized, not abandoned — revisit if the LAN cluster is ever needed again)
- #2126 (CI-gated apply pipeline) not started — today's Azure applies were still run by hand, by necessity (no pipeline exists yet)

## How This Connects

| Tier | File | What it answers |
|---|---|---|
| ↑ Weeks | [EXECUTION_QUEUE.md](EXECUTION_QUEUE.md) | Why these issues, and what's next after today? |
