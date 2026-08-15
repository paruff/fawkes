# Design — Spin `docs/dojo/` out into its own repo (`uFawkesDojo`)

**Date:** 2026-08-15
**Related:** ROADMAP.md Phase 2 ("Dojo Spin-out & Learning Platform")
**Status:** Approved

## Goal

Extract the belt-level Dojo curriculum from the Fawkes monorepo into a standalone,
public repo (`uFawkesDojo`) so it can be consumed by both `fawkes` and the wider
`uFawkes*` stack family, matching the pattern already used for `uFawkesPipe`,
`uFawkesObs`, `uFawkesSec`, `uFawkesDevX`, `uFawkesAI`, `uFawkesRes`, `ufawkesdora`.

## Scope

Everything under `docs/dojo/` moves:

- `Fawkes Dojo: Immersive Learning Architecture.md`
- `modules/{white,yellow,green,brown,black}-belt/*.md` (20 modules)
- `white-belt/module-01-what-is-idp/` (lab-01 instructions + solution manifests + validate.sh)
- `labs/` — `fawkes-cli.py`, `setup.py`, `lab automation.md`, `brown n black labs.md`
- `assessments/` — white/green/brown/black exam docs
- `index.html`, `onboarding.html`

**Verified standalone:** `labs/fawkes-cli.py` only depends on `click`, `yaml`,
`subprocess`/`kubectl`, and a local `lab_automation` module — no imports from
Fawkes' `services/`. It targets generic `fawkes.io/lab` k8s labels, not
Fawkes-specific APIs. No code-surgery needed before the move.

**Nothing else in the repo references dojo content programmatically** — only
doc links (`mkdocs.yml` nav, `README.md`, `catalog-info.yaml`, `ROADMAP.md`).
No `.github/workflows/*` target `docs/dojo/`.

## Extraction method

Preserve git history using `git filter-repo` against a fresh clone of `fawkes`:

```bash
git clone https://github.com/paruff/fawkes uFawkesDojo-extract
cd uFawkesDojo-extract
git filter-repo --path docs/dojo/ --path-rename docs/dojo/:
```

Push the filtered history as the initial history of the new `uFawkesDojo` repo
(created public, matching sibling `uFawkes*` repos).

## New repo (`uFawkesDojo`) bootstrap

- Own `mkdocs.yml` (or keep the two static HTML pages as-is — implementer's call)
  so the curriculum browses independently of Fawkes' docs site.
- Root `README.md` in the same style as `uFawkesPipe`/`uFawkesObs`, cross-linking
  back to `fawkes` and `uFawkes.dev`.
- `catalog-info.yaml` so it can still register as a Backstage component if
  Fawkes' Backstage instance wants to surface it.
- Minimal CI: markdown-lint job only. No mkdocs-deploy pipeline — that's a
  speculative feature until someone asks for the site to be published.

## Fawkes-side changes (small PRs)

1. **PR 1** — Delete `docs/dojo/` (except a new one-page
   `docs/dojo/README.md` pointer: "Dojo moved to
   github.com/paruff/uFawkesDojo"). Update `mkdocs.yml` nav (~5 lines) to
   point at the pointer page or straight to the external URL.
2. **PR 2** — Update `README.md`'s ~15 dojo references and the
   `catalog-info.yaml` description to point outward instead of to in-repo paths.
3. **PR 3** — Flip `ROADMAP.md` Phase 2 status/acceptance-criteria rows from
   "Not started" to reflect the completed spin-out (same convention as the
   already-done Phase 0 rows).

## Cross-repo follow-up (separate repo, not this PR series)

`uFawkes.dev` stack pages get a link to the new repo — already flagged as a
pending row in `ROADMAP.md` §10 ("Learn guides ... Coordinate Phase 2").

## Explicitly out of scope

- No git submodule mounting `uFawkesDojo` back into Fawkes' `docs/dojo/`.
- No CI sync job mirroring content between repos.

The "remove + link out" decision means Fawkes doesn't need dojo content
in-tree going forward — a submodule or sync job would be unrequested
complexity for a docs-only asset with no runtime dependents.

## Risks / open items

- Any external links pointing at `fawkes/docs/dojo/...` paths (blog posts,
  socials, uFawkes.dev) break unless redirected — worth a grep of
  `uFawkes.dev` and any published announcements before merging PR 1.
- `labs/fawkes-cli.py` docstring hardcodes
  `https://docs.fawkes.io/dojo/module-{module}` — update to the new repo's
  docs URL during the move.
