# Plan: default primary moves from Indigo 500 to Indigo 600

**Traces to:** owner decision D10 | suite design reference
([`DESIGN.md`](https://github.com/paruff/uFawkes.dev/blob/main/DESIGN.md),
[`tokens.json`](https://ufawkes.dev/design/tokens.json))

## Changes

1. `design-system/src/tokens/colors.ts`: the "Main primary color" marker moves
   to `600`. Scale values are unchanged.
2. `Button.css`: primary hover goes 500 to 700 (500 is 4.47:1 with white
   text); focus ring goes 500 to 600. `global.css` gains `--fawkes-primary-700`.
3. README and MDX examples use `primary[600]`.

## Verification Strategy

| Criterion                        | Evidence                                              | How                                                                |
| -------------------------------- | ----------------------------------------------------- | ------------------------------------------------------------------ |
| Default is 600 and passes AA     | `primaryDefault.test.ts` fails before, passes after   | `cd design-system && npx jest src/tokens`                          |
| Nothing else regressed           | Existing Button and a11y tests pass; typecheck, lint  | `npx jest`, `npm run typecheck`, `npm run lint` in `design-system` |
| Scale still matches the suite    | Check prints "design system colours match tokens.json" | `python3 scripts/check-design-token-sync.py <path to tokens.json>` |
