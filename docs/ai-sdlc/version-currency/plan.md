# Plan: version currency

Intent: #2366. Rule: [ADR-040](../../adr/ADR-040-version-currency.md).
Facts: [inventory](inventory.md), [automation](automation.md).

Status lives on the project board, not here.

## Order of upgrade work

1. Security advisories or retired upstream: #2371, #2372, #2373, #2374, #2375,
   #2376, #2377.
2. End-of-life, disagreeing or automation: #2378, #2379, #2380, #2381, #2382,
   #2383, #2384, #2385, #2386, #2394, #1735.
3. The rest: #2387, #2388, #2389, #2390, #2391, #2392, #2393.

Each upgrade is one component, verified on a live cluster (#2368), and removes its
guard exception and updates its inventory row.

## Verification Strategy

Every upgrade, before merge:

- `tests/unit/test_version_pins.py` passes with the component's exception removed.
- On a live cluster: install the old version, upgrade in place to the new one, and
  check that what depends on it still works. Also check a fresh install by any
  second install path. Record in the PR what was not covered.

For Argo CD (#2371) that means: Terraform apply old then new; Applications Synced
and tracked; metrics scraped from another namespace; the ApplicationSet
`applicationsSync` override honoured; the `dev-up.sh` Argo CD block on a clean
cluster; empty and range `chart_version` rejected.
