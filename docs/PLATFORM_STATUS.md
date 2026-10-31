# Platform Status

> **Machine-generated. Do not hand-edit.** Produced by `scripts/generate-platform-status.sh`
> from the latest `scripts/validate-golden-path-*.sh` reports. Regenerated nightly and
> on-demand by `.github/workflows/golden-path-verification.yml`.
>
> Last run: 2026-10-31T03:01:38Z — [workflow run](https://github.com/paruff/fawkes/actions/runs/41162528698)

| Plane | Status | Passed / Total | Last Checked |
|---|---|---|---|
| devex | 🔴 all failed | 0/2 | 2026-10-31T03:01:29Z |
| dora | 🔴 all failed | 0/1 | 2026-10-31T03:01:29Z |
| gitops | 🔴 all failed | 0/1 | 2026-10-31T03:01:29Z |
| observability | ⚪ no data | — | never |
| pipeline | 🔴 all failed | 0/1 | 2026-10-31T03:01:38Z |
| progressive-delivery | ⚪ no checks defined | 0/0 | 2026-10-31T03:01:38Z |
| resources | 🔴 all failed | 0/1 | 2026-10-31T03:01:38Z |
| security | 🔴 all failed | 0/1 | 2026-10-31T03:01:38Z |

## What this replaces

Prior to this, `docs/BACKLOG.md`'s per-phase status tables were hand-typed and
drifted from reality in both directions (see the Phase 2 audit this file's
generation was born from). This page is the single source of truth for
"is it actually working right now" - `BACKLOG.md` should link here, not
duplicate a status claim.
