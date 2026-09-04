# Accessibility Testing

Fawkes runs automated accessibility testing in CI/CD against the [design system](../../design/design-system.md) using **axe-core** and **Lighthouse CI**, targeting **WCAG 2.1 AA** compliance. This page is the accessibility dashboard: it describes the test program, how to run it, and where results are surfaced.

## Overview

Accessibility is enforced at two complementary layers:

| Layer | Tool | What it checks | When it runs |
|-------|------|----------------|--------------|
| Component tests | axe-core (via `jest-axe`) | WCAG 2.1 A/AA rule violations in rendered components (ARIA, labels, keyboard access, landmarks, alt text) | Every PR touching `design-system/**` + daily schedule |
| Browser audit | Lighthouse CI | Full-page accessibility score (incl. color contrast, which jsdom cannot measure) against the built Storybook | Every PR touching `design-system/**` + daily schedule |

Both layers gate CI: a violation fails the build.

## Quick Start

```bash
cd design-system

# Run the axe-core component accessibility suite locally
npm run test:a11y

# Run the full accessibility pipeline locally (axe-core + build Storybook + Lighthouse CI)
npm run accessibility:full
```

## Compliance Gates (WCAG 2.1 AA)

Lighthouse CI (`design-system/lighthouserc.json`) fails on:

- **Accessibility category score < 0.90** (`categories:accessibility` is asserted as `error` with `minScore: 0.9`)
- Individual WCAG rules asserted as `error`: `color-contrast`, `image-alt`, `label`, `link-name`, `button-name`, `aria-allowed-attr`, `aria-required-attr`, `aria-required-children`, `aria-required-parent`, `aria-roles`, `aria-valid-attr`, `aria-valid-attr-value`, `duplicate-id-aria`, `tabindex`, `td-headers-attr`, `th-has-data-cells`, `valid-lang`, `listitem`, `list`, `definition-list`, `dlitem`, `accesskeys`, `frame-title`, `meta-refresh`, `object-alt`
- `heading-order` and `video-caption` are `warn` (reported, non-blocking)

The axe-core suite (`design-system/src/a11y.test.tsx`) enables the WCAG 2.1 A/AA rule set in the rendered-component environment. `color-contrast` is disabled there (jsdom cannot render canvas); it is enforced by the Lighthouse browser audit instead.

## Where Results Surface (the dashboard)

Results are visible in four places:

1. **Grafana accessibility dashboard** — provisioned from `platform/apps/prometheus/accessibility-dashboard.yaml` (ConfigMap labeled `grafana_dashboard: "1"`). Panels track the overall Lighthouse accessibility score, test pass rate, critical axe violations, WCAG 2.1 AA compliance, violations by severity/component/rule, and test-execution history. Panels populate once the CI pipeline pushes `lighthouse_accessibility_score`, `axe_*_violations`, and `accessibility_test_*` to Prometheus (same pending-metrics convention as the DORA metrics dashboard).
2. **GitHub Actions run summary** — the `accessibility-report` job posts a compliance summary table (Axe-Core / Lighthouse pass-fail, WCAG 2.1 AA verdict) to the run's `$GITHUB_STEP_SUMMARY`.
3. **PR comment** — on pull requests, the `lighthouse-ci` job comments the accessibility score (≥90 = PASSED) with a link to the run artifacts.
4. **Artifacts** — every run uploads:
   - `axe-core-test-results` (coverage + `junit.xml`)
   - `lighthouse-reports` (`design-system/.lighthouseci/`, including the HTML report)

## Auto-Issue Creation for Violations

When either gate fails on a **scheduled run or a push to `main`**, the `create-accessibility-issues` job opens a GitHub issue labeled `accessibility`, `automated`, `bug`, `P1` (skipped on PR builds; deduplicated — only one issue per rolling 7-day window). The issue links the failing workflow run and the fix steps.

## CI Workflows

- `.github/workflows/accessibility-testing.yml` — the primary workflow (axe-core, Lighthouse CI, auto-issue creation, report summary). Triggers on PRs and pushes touching `design-system/**` or `platform/apps/backstage/**`, plus a daily 09:00 UTC schedule.
- `.github/workflows/reusable-accessibility.yml` — reusable workflow (`workflow_call`) so other components can opt in with `test-type`, `wcag-level`, `target-url`, `working-directory`, and `create-issues` inputs.

Both workflows log DORA `job-start`/`job-finish` timestamps with workflow, job, and commit SHA for traceability.

## Best Practices

- **Fix violations in the component, not the test** — prefer semantic HTML and ARIA fixes over axe suppressions.
- **Keep `color-contrast` disabled only in jsdom** — it must stay enabled in Lighthouse CI.
- **Extend `a11y.test.tsx`** when adding new components so axe-core covers them.
- **Do not lower the 0.90 gate** without a documented product decision.

## Getting Help

- [WCAG 2.1 Quick Reference](https://www.w3.org/WAI/WCAG21/quickref/)
- [axe-core documentation](https://github.com/dequelabs/axe-core)
- [Lighthouse accessibility scoring](https://developer.chrome.com/docs/lighthouse/accessibility/scoring/)
- Design system component docs: `docs/design/design-system.md`

---

**Maintained by**: Fawkes Platform Team
**Related Issues**: #396 (Implement Automated Accessibility Testing)
