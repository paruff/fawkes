# Security PR Audit — 2026-09

> Quality audit of the last 20 merged `fix(security)`/`fix(terraform)` PRs.
> Not a merge gate (all already merged) — assessing whether shipped fixes
> actually close what they claim to.

## Summary

| PR | Title | Verdict | Why |
|---|---|---|---|
| #1720 | friction-bot signature verification | Solid | TDD, 9 tests, verified this session |
| #1718 | bump postcss 8.5.28 | Solid | Trivial version bump, 3 CVEs, no logic change |
| #1714 | design-system npm overrides | Not deep-reviewed | Superseded by later work this session; low risk |
| #1712 | AKS API server IP ranges | Solid | Rejects `0.0.0.0/0`, forces caller decision, docs regenerated; verified no other caller broken |
| #1710 | SNS topic encryption default | Solid | Verified no orphaned var/output references from the file consolidation |
| #1708 | Unleash read-only rootfs | Solid | Correct `emptyDir` `/tmp` mount added alongside the flip |
| #1707 | Plausible read-only rootfs | Solid | Most thorough of the three — covers init containers and a dedicated ClickHouse log dir too |
| #1703 | vsm-service read-only rootfs | Solid | Correct `emptyDir` `/tmp` mount |
| #1701 | Postgres firewall rules require public access | Solid | Closes the specific gap: scoped rules silently ignored when `public_network_access_enabled=false` |
| #1688 | Stop leaking exception text (5 services) | Solid | Real regression tests per service using a canary string; server-side logging preserved |
| #1686 | Harden securityContext, extensions workloads | Solid | Final state (checked directly) is coherent across the 4-PR series |
| #1685 | mcp-k8s-server / Dockerfile.secure non-root | Solid | `USER 1000` confirmed in current file |
| #1683 | Scope Spring Boot actuator exposure | Solid | Current state confirmed: `health,info,prometheus` only, `show-details=when-authorized` |
| #1681 | Default VPC/DB to private | Solid | Part of same coherent series as #1683/#1685/#1686 |
| **#1665** | **Penpot securityContext** | **Incomplete — likely broke the app** | See Findings below |
| #1664 | Sealed Secrets rollout (22 secrets) | Solid | Real `kubeseal`-encrypted payloads (not a facade), careful script, justified CodeQL suppressions |
| #1663 | Revert design-system Dependabot fix | Exemplary | Data-driven: verified via live `dependabot/alerts` that the "fix" net-added 27 alerts incl. 1 critical |
| #1653 | sealed-secrets ArgoCD app OCI source | Not deep-reviewed | 2-line change, low risk |
| #1649 | Escape reflected survey token (XSS) | Solid | Correctly distinguishes JS-string vs HTML-body escaping context; tested with real payloads |
| **#1625** | **4 Terraform security fixes (AWS/Azure/GCP)** | **Partially incomplete** | See Findings below |

**19 of 20 solid or low-risk. 2 findings requiring follow-up**, one likely already causing a real outage.

## Findings requiring follow-up

### #1665 — Penpot: `readOnlyRootFilesystem: true` without writable `/tmp` (likely broke the app)

`platform/apps/penpot/deployment.yaml` sets `readOnlyRootFilesystem: true` on all 4
Penpot containers (`penpot-backend`, `penpot-frontend`, `penpot-exporter`,
`penpot-redis`) but — unlike the sibling PRs #1708 (Unleash), #1707 (Plausible),
and #1703 (vsm-service), which each correctly added an `emptyDir` volume
mounted at `/tmp` alongside the same flip — this PR adds **no writable `/tmp`
at all** for `penpot-backend`, `penpot-frontend`, or `penpot-exporter`.
Confirmed by reading the current file: the only volume mounts anywhere in it
are `penpot-data` → `/opt/data` (backend only) and `redis-data` → `/data`
(redis only). `penpot-frontend` and `penpot-exporter` have zero volume
mounts.

Penpot's backend is a Clojure/JVM service — JVM apps routinely need `/tmp`
scratch space (temp files, in some configurations `java.io.tmpdir`). With no
writable filesystem anywhere, any such write will fail. This should be
verified against the actual running pods (`kubectl get pods -n fawkes -l
app=penpot -o wide` — look for `CrashLoopBackOff` or repeated restarts,
or exec in and try writing to `/tmp`).

**Fix**: add the same pattern used in #1708/#1707/#1703 — an `emptyDir: {}`
volume named `tmp`, mounted at `/tmp`, on `penpot-backend`, `penpot-frontend`,
and `penpot-exporter`.

### #1625 — AWS EKS secrets encryption defaults to *disabled*, unlike its Azure/GCP siblings in the same PR

This PR bundles 4 fixes across 3 cloud providers. The Azure fix
(`network_policy`, defaults to `"azure"`, always applied) and the GCP fix
(`disable-legacy-endpoints` forced `true` unconditionally via `merge()`, plus
`0.0.0.0/0` rejected in `master_authorized_networks`) are both enforced
unconditionally — the caller can't opt out. The AWS EKS fix
(`infra/terraform/modules/aws/eks/variables.tf`) adds `kms_key_arn` with
`default = null`, and `main.tf`'s `dynamic "encryption_config"` block only
activates `if kms_key_arn != null` — so EKS secrets encryption stays fully
**opt-in**, and every existing/new caller that doesn't explicitly set it gets
no encryption at rest, same as before this PR.

This is inconsistent with how #1712 (a later PR, same class of problem —
AKS API server IP ranges) handled the equivalent situation: it *removed* the
insecure default entirely, forcing every caller to make an explicit choice
via `terraform plan` failing until they do. The EKS fix could follow the
same pattern (no `default`, or require a real ARN when a flag like
`enable_secrets_encryption` is true).

**Fix**: either drop `default = null` (matching #1712's pattern — forces
callers to decide, `terraform plan` fails until they do) or, at minimum,
open a tracked issue so this doesn't read as closed when it's actually
opt-in.

### Follow-up grep: same pattern found in `dora-metrics` too

Checked every `platform/apps/*/deployment.yaml` for
`readOnlyRootFilesystem: true` without a matching `/tmp` mount, per the
suggestion above. Two clean misses:

- **`platform/apps/penpot/deployment.yaml`** — as above.
- **`platform/apps/dora-metrics/deployment.yaml`** — 1 container sets
  `readOnlyRootFilesystem: true`, 0 `/tmp` mounts anywhere in the file. This
  wasn't part of the 20-PR sample (predates it or was never in a "security
  fix" PR by title), but is the identical bug — worth the same fix.

Two more are worth a second look but weren't deep-dived here (partial
mismatch, may be fine if it's an init container that doesn't need `/tmp` —
didn't verify): `platform/apps/unleash/deployment.yaml` (2
`readOnlyRootFilesystem`, 1 `/tmp` mount) and
`platform/apps/focalboard/deployment.yaml` (2 `readOnlyRootFilesystem`, 1
`/tmp` mount).

## Overall assessment

Security fixes in this repo are **generally trustworthy** — the sample shows
real regression tests (#1649, #1688, #1720), a genuinely exemplary
data-verified revert (#1663) rather than a rubber-stamp, and correct handling
of the `readOnlyRootFilesystem` + `/tmp` gotcha in 3 of 4 cases. The one
miss (#1665) is a copy-paste-adjacent PR that dropped the one detail that
makes the pattern safe, in a PR merged the same day as its three correct
siblings — worth a quick grep across `platform/apps/*/deployment.yaml` for
any other `readOnlyRootFilesystem: true` without a matching `/tmp` mount,
since this is exactly the kind of thing that's easy to miss once and easy to
copy wrong a second time.
