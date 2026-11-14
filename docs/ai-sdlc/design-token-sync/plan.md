# Plan: apply the suite design tokens to the Fawkes docs

**Traces to:** the suite design reference
([`DESIGN.md`](https://github.com/paruff/uFawkes.dev/blob/main/DESIGN.md),
[`tokens.json`](https://ufawkes.dev/design/tokens.json)) | fawkes#2192

## Changes

1. `docs/stylesheets/ufawkes-brand.css`, registered under `extra_css`, sets
   Material's colour variables from the tokens. `mkdocs.yml` switches the
   palette `primary` and `accent` to `custom` so the stylesheet applies, and
   sets the favicon and logo to the interim flame mark.
2. `scripts/check-design-token-sync.py` fails when the indigo or gray scale in
   `design-system/src/tokens/colors.ts` differs from `tokens.json`.
3. `design-system/README.md` explains how to run the check.

## Verification Strategy

| Criterion                         | Evidence                                                    | How                                                                  |
| --------------------------------- | ----------------------------------------------------------- | -------------------------------------------------------------------- |
| The docs site builds              | `mkdocs build` succeeds with the new stylesheet and mark    | `mkdocs build`; the `Validate MkDocs configuration` pre-commit hook  |
| Light and dark use the tokens     | Computed header, link and background colours match the tokens | Chromium on the built home page, both schemes                      |
| The design system matches tokens  | The check prints "design system colours match tokens.json"  | `python3 scripts/check-design-token-sync.py <path to tokens.json>`   |
| Drift is caught                   | A changed hex in `colors.ts` makes the check exit non-zero  | Checked by hand once (exit 1); no automated test or CI job yet      |

## Follow-up

Wire the sync check into CI once the published `tokens.json` is reachable from
runners, and decide whether the design system's default primary moves from 500
to 600 (500 is 4.47:1 on white).

State on 2026-11-13 (paruff/fawkes#2311): the primary moved to 600
([`design-primary-600`](../design-primary-600/plan.md)). The check still runs
in no hook, workflow or Make target, and it compares only the indigo and gray
scales. A pre-commit hook against a vendored `tokens.json` needs no network,
so it doesn't have to wait for runners to reach the published file.

| Criterion                                   | Evidence                                                        | How                                            |
| ------------------------------------------- | --------------------------------------------------------------- | ---------------------------------------------- |
| The check runs on every commit              | A `design-token-sync` hook in `.pre-commit-config.yaml`         | `make lint`                                    |
| Values outside the two scales are accounted for | Each one matches the tokens or is listed in `DESIGN.md` as a departure | Review of `DESIGN.md`'s "Today" table against the code |
