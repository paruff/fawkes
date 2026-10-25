# REVIEW.md

Apply the suite rules in [uFawkesAI REVIEW.md](https://github.com/paruff/uFawkesAI/blob/main/REVIEW.md):
severity, what to flag (verification, validation, security), what to skip, the
output and the board move. This file adds only what is specific to this repo.

## Checks the PR must paste

- `make validate`
- `make lint`
- `make test-unit`
- `npx @google/design.md@0.4.0 lint DESIGN.md` when `DESIGN.md` changes: 0 errors, 0 warnings

## UI

The design system and docs site follow [`DESIGN.md`](DESIGN.md).

## Repo rules

Path-specific review rules: [`.github/instructions/code-review.instructions.md`](.github/instructions/code-review.instructions.md).
