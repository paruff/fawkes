# Platform Status

> **Machine-generated. Do not hand-edit.** Produced by `scripts/generate-platform-status.sh`
> from the latest `scripts/validate-golden-path-*.sh` reports. Regenerated nightly and
> on-demand by `.github/workflows/golden-path-verification.yml`.
>
> Last run: 2026-10-10T03:06:13Z — [workflow run](https://github.com/paruff/fawkes/actions/runs/38019349498)

| Plane | Status | Passed / Total | Last Checked |
|---|---|---|---|
| devex | 🔴 all failed | 0/2 | 2026-10-10T03:06:03Z |
| dora | 🔴 all failed | 0/1 | 2026-10-10T03:06:03Z |
| gitops | 🔴 all failed | 0/1 | 2026-10-10T03:06:03Z |
| observability | ⚪ no data | — | never |
| pipeline | 🔴 all failed | 0/1 | 2026-10-10T03:06:12Z |
| progressive-delivery | ⚪ no checks defined | 0/0 | 2026-10-10T03:06:12Z |
| resources | 🔴 all failed | 0/1 | 2026-10-10T03:06:13Z |
| security | 🔴 all failed | 0/1 | 2026-10-10T03:06:13Z |

## What this replaces

Prior to this, `docs/BACKLOG.md`'s per-phase status tables were hand-typed and
drifted from reality in both directions (see the Phase 2 audit this file's
generation was born from). This page is the single source of truth for
"is it actually working right now" - `BACKLOG.md` should link here, not
duplicate a status claim.
