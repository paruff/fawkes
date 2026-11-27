# Plan: Beta for a first adopter, then scale

**Traces to:** [`intent.md`](intent.md) → [`spec.md`](spec.md) | **Epic:** #1805
| **Status:** the owner approved this plan's spec on 2026-11-27. Status lives
on [Project #7](https://github.com/users/paruff/projects/7), not here.

Beta is one outcome: AC-BETA-01 to AC-BETA-07 pass, with evidence, six weeks
after approval (by **2027-01-08**). The work is seven goals, each a `goal`
issue that holds its own steps, limits and exit criteria. Goal 2 (scale)
begins with its own spec once Beta closes.

## Goals

| # | Goal | Issue | Criteria | Route | Priority |
| --- | --- | --- | --- | --- | --- |
| 0 | Board reset: this plan merged, issue verdicts recorded, path-to-Beta re-scoped | #2298 | — | Claude Code, Opus | P0 |
| 1 | Alpha ships: #1797, one clean `python-fawkes-path` run (#1858) | #1804 | AC-BETA-06 | Claude Code, Sonnet | P0 |
| 2 | Every DORA panel shows a series Fawkes produces | #2314 | AC-BETA-05 | Claude Code, Sonnet; sub-issues to opencode | P1 |
| 3 | Python and the adopter's language pass `golden-path-verification` on AKS | #2352 | AC-BETA-02 | Claude Code, Sonnet | P0 |
| 4 | A cluster built from tagged releases through CI-gated apply | #2353 | AC-BETA-03 | Claude Code, Opus then Sonnet | P1 |
| 5 | Backstage live with the golden-path templates | #2354 | AC-BETA-01 (portal) | Claude Code, Sonnet | P1 |
| 6 | Single sign-on with GitHub identities and an approver role | #2190 | AC-BETA-04 | Claude Code, Opus (security) | P1 |
| 7 | A non-maintainer ships to production; docs describe Beta as built | #2355 | AC-BETA-01, AC-BETA-07 | Claude Code, Opus | P0 |
| — | Scale: write the Goal 2 spec and plan | #2356 | Goal 2 | Claude Code, Opus | P2 |

## Sequence

```text
week        1          2          3          4          5          6
G0 reset    ██
G1 Alpha    ██████████
G2 DORA     ████████████████████
G3 paths    ░░░░░░░░░░██████████████████████          (░ = no-cluster steps only)
G4 infra    ████████████████████████████████
G5 portal              ████████████████████
G6 SSO                 ██████████████████████
G7 adopter                                  ████████████████████
```

| Goal | Depends on | Why |
| --- | --- | --- |
| G1 | — | Alpha's open items are Beta's prerequisites (spec, Prerequisites) |
| G3 cluster steps | G1 | Don't change `python-fawkes-path`'s Application while #1858's evidence run is pending |
| G5 | #1797 in G1 | Backstage's secrets are placeholders until then |
| G6 | G5 | Backstage must run before anyone can sign in to it |
| G7 | G2–G6 | It is the end-to-end proof of all of them |
| #2356 | G7 | Goal 2 is specified from what Beta teaches |

**The adopter picks their language by the end of week 2.** If they haven't,
G3 uses Node.js/TypeScript (spec C10).

## Risks

| Risk | Mitigation |
| --- | --- |
| Weeks 4–5 fall over the December holidays | G7 can use a non-maintainer on the Fawkes cluster (AC-BETA-01). Any slip is reported on #2355, and the date is never quietly moved |
| The AKS cluster is destroyed nightly and rebuilt by hand | G4 step 4 replaces the hand rebuild with a CI-built verification cluster. Until then, live steps note the cluster's build time |
| Six goals in parallel for one maintainer's reviews | Small PRs (≤400 lines). Agents take only issues that have files, a reference and exit criteria (`AGENTS.md` §11) |
| A new language takes longer than its Python twin | Node.js and Java both start from existing templates. The third language is Goal 2 |
| Pressure to mark things done without live proof | Every exit criterion names a run or a paste (`AGENTS.md` §9) |

## Existing issues

Each open issue at `0904e2a9` has one verdict. G0 (#2298) posts each verdict
as a comment that links here. The owner approves every close before it
happens; #2004 was approved as decision C12.

| Verdict | Issues |
| --- | --- |
| **Close: accepted risk** (C12) | #2004 |
| **Close: superseded** (owner to approve) | #1153 (duplicate of #1569); #1680 (DevLake, replaced by ADR-038) |
| **Close when this plan merges** | #2191 (the path to Beta is now defined); #2298 once its comments are posted |
| **Resolved, not verified** | #2081 (built in PR #2144; its rules are missing from the live map, G2); #2079 (`dora:change_failure_rate:ratio30d` exists; verify in G2, then close); #1661 (verify with #1858's run, G1) |
| **Beta, G1** | #1804, #1808, #1797, #1858, #2188, #2325 (BDD tests read a deleted workflow) |
| **Beta, G2** | #2314, #2310, #2312, #2344, #2130, #1572, #1919, #1946, #1948 |
| **Beta, G3** | #2299 (guard only), #2300, #2302, #2120, #2323, #2322 (canary aborts healthy rollouts), #1856, #1909, #2032 (if Java is the adopter's language) |
| **Beta, G4** | #2126, #1938 |
| **Beta, G5** | #1950 |
| **Beta, G6** | #2190 |
| **Goal 2 (scale)** | #1806, #2124, #1857, #2189, #1942, #1943, #1569, #1578, #1592, #1156, #1735, #1737 |
| **Beside Beta, not gating it** | #2116, #2299 (monolith scaffolds), #2301, #2303, #2304, #2311, #2296, #2227, #2326, #1715, #1792, #1795, #1796, #1949, #1496 |
| **Host hardware, unrelated to the adopter** | #2351, #1922 |

## Harnesses and models

As in the spec's table. In practice:

- `goal` issues and anything touching security, RBAC, secrets or `infra/`:
  Claude Code. Opus plans and reviews, Sonnet implements.
- Sub-issues that a goal splits off with files, a reference and exit criteria:
  `opencode,model:nemotron-3-ultra` for multi-file work,
  `opencode,model:glm-5.3-flash` for single-file work.
- `good first issue` for outside contributors: `opencode,model:mimo-v2.6-flash`
  on the free tier.

## Exit criteria

- [ ] #2355 closed, with AC-BETA-01 to AC-BETA-07 each linking its evidence
- [ ] #1805 closed
- [ ] #2356 picked up with the adopter's transaction numbers
