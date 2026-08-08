# Build Report — Issue #1541: bump same-major npm overrides in design-system

**Status:** COMPLETE

---

## Tasks Completed

| Task | Title | Status |
| ---- | ----- | ------ |
| Overrides | Raise 6 floors + add 4 new entries in `design-system/package.json` | DONE |
| Lockfile | Regenerate `package-lock.json`; all 13 targets above vulnerable floors | DONE |
| Audit | `npm audit`: 0 findings for all 13 target packages | DONE |
| Tests | jest 17 passed, a11y 10 passed, eslint 0 errors, tsc clean, storybook build | DONE |
| Deliver | PR #1553 merged, then refined via PR #1554 (merged); issue #1541 closed | DONE |

## Artifacts

- PR #1553 — first pass (merged `60e0c2d1`): overrides + lockfile, 13/13 fixed
- PR #1554 — refinement (merged `0e08b74f`): dropped unnecessary `@babel/core` cascade, pinned minimal rollup `^4.59.0` / postcss `^8.5.23` floors, lockfile diff 583 → 85 lines

## Fixes (13 Dependabot alerts)

basic-ftp (#145,#151), lodash (#141), lodash-es (#138), rollup (#22), flatted (#100), form-data (#245), @babel/plugin-transform-modules-systemjs (#185), ws (#239), svgo (#272), tmp (#195), fast-uri (#183,#184,#271), postcss (#281), defu (#142)

## Validation Results

| Check | Status |
| ----- | ------ |
| npm audit (13 targets) | PASS — 0 remaining |
| jest + a11y | PASS — 17 + 10 passed |
| eslint / tsc | PASS — 0 errors / clean |
| storybook build | PASS |
| CI (PR #1554) | PASS — all 6 workflows incl. PR Size Gate |

## Notes

- Remaining 36 audit findings require major-version bumps (storybook 10, vite 8) — out of scope per issue ("same-major").
- `docs/dora-research-alignment` branch (unrelated, parallel session) was observed mid-flight; verified unharmed (equals origin/main).
