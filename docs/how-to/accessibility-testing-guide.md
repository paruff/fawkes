# Automated Accessibility Testing Guide

## Overview

This guide explains how to use the automated accessibility testing integrated into the Fawkes platform CI/CD pipeline. The system uses axe-core and Lighthouse CI to ensure WCAG 2.1 AA compliance for all components.

## Table of Contents

- [Quick Start](#quick-start)
- [Testing Tools](#testing-tools)
- [Running Tests Locally](#running-tests-locally)
- [CI/CD Integration](#cicd-integration)
- [Understanding Test Results](#understanding-test-results)
- [Fixing Violations](#fixing-violations)
- [Dashboard and Metrics](#dashboard-and-metrics)
- [Troubleshooting](#troubleshooting)

## Quick Start

### Run All Accessibility Tests

```bash
cd design-system
npm run accessibility:full
```

### Run Only Axe-Core Tests

```bash
cd design-system
npm run test:a11y
```

### Run Only Lighthouse CI

```bash
cd design-system
npm run build-storybook
npm run lighthouse:ci
```

## Testing Tools

### Axe-Core

[axe-core](https://github.com/dequelabs/axe-core) is a fast, lightweight accessibility testing engine that runs automated WCAG 2.0, 2.1, and Section 508 accessibility tests.

**What it tests:**
- Color contrast
- ARIA attributes
- Semantic HTML
- Keyboard navigation
- Form labels
- Image alt text
- And 90+ other rules

### Lighthouse CI

[Lighthouse CI](https://github.com/GoogleChrome/lighthouse-ci) provides automated auditing, performance metrics, and best practices for web pages.

**What it tests:**
- Accessibility score (0-100)
- WCAG compliance
- Best practices
- SEO fundamentals

## Running Tests Locally

### Prerequisites

```bash
cd design-system
npm install
```

### Run Axe-Core Tests

```bash
# Run all accessibility tests
npm run test:a11y

# Run in watch mode for development
npm run test:watch -- --testPathPattern=a11y

# Run with coverage report
npm run test:coverage
```

### Run Lighthouse CI

```bash
# Build Storybook first
npm run build-storybook

# Run Lighthouse CI
npm run lighthouse:ci

# Or run individual commands
npm run lighthouse:collect
npm run lighthouse:assert
```

### Writing Accessibility Tests

Create tests for your components using jest-axe:

```typescript
import { render } from '@testing-library/react';
import { axe, toHaveNoViolations } from 'jest-axe';
import { MyComponent } from './MyComponent';

expect.extend(toHaveNoViolations);

describe('MyComponent Accessibility', () => {
  it('should have no accessibility violations', async () => {
    const { container } = render(<MyComponent />);
    const results = await axe(container);
    expect(results).toHaveNoViolations();
  });

  it('should be keyboard accessible', async () => {
    const { container } = render(<MyComponent />);
    const results = await axe(container, {
      rules: {
        'keyboard-access': { enabled: true }
      }
    });
    expect(results).toHaveNoViolations();
  });
});
```

## CI/CD Integration

### GitHub Actions

Accessibility tests run automatically on:
- Every pull request
- Push to main branch
- Daily at 9 AM UTC (scheduled)
- Manual workflow dispatch

**Workflow:** `.github/workflows/accessibility-testing.yml`

### Jenkins Pipeline

For services using the Golden Path pipeline, add accessibility testing:

```groovy
@Library('fawkes-pipeline-library') _

goldenPathPipeline {
    appName = 'my-service'
    language = 'node'
    // ... other config
}

// Add accessibility stage after unit tests
stage('Accessibility Tests') {
    steps {
        accessibilityTest {
            runAxeCore = true
            runLighthouse = true
            wcagLevel = 'AA'
            failOnViolations = true
            lighthouseScoreThreshold = 90
        }
    }
}
```

### Quality Gates

The pipeline enforces these quality gates:

| Gate | Threshold | Action |
|------|-----------|--------|
| Axe-Core Tests | 0 violations | ❌ Fail build |
| Lighthouse Score | ≥ 90/100 | ❌ Fail build |
| WCAG 2.1 AA | Must comply | ❌ Fail build |
| Color Contrast | 4.5:1 text, 3:1 large | ❌ Fail build |

## Understanding Test Results

### Axe-Core Results

Violations are categorized by severity:

- **Critical**: Serious accessibility issues that must be fixed immediately
- **Serious**: Major accessibility problems that significantly impact users
- **Moderate**: Noticeable accessibility issues
- **Minor**: Small accessibility improvements

Example output:

```
❌ 2 violations found:

1. color-contrast (serious)
   - Element: <button class="btn-primary">Submit</button>
   - Description: Element's background color could not be determined due to a background image
   - Fix: Ensure sufficient color contrast (4.5:1 for normal text)
   - More info: https://dequeuniversity.com/rules/axe/4.8/color-contrast

2. label (critical)
   - Element: <input type="text" id="email">
   - Description: Form element does not have an associated label
   - Fix: Add a <label> element or aria-label attribute
   - More info: https://dequeuniversity.com/rules/axe/4.8/label
```

### Lighthouse Results

Lighthouse provides a score from 0-100:

- **90-100**: ✅ Good (meets WCAG 2.1 AA)
- **70-89**: ⚠️ Needs improvement
- **0-69**: ❌ Poor (does not meet requirements)

Reports include:
- Overall accessibility score
- Detailed audit results
- Opportunities for improvement
- Passed audits

## Fixing Violations

### Common Violations and Fixes

#### 1. Missing Alt Text

**Problem:**
```html
<img src="logo.png" />
```

**Fix:**
```html
<img src="logo.png" alt="Company logo" />
```

#### 2. Poor Color Contrast

**Problem:**
```css
.text {
  color: #999;
  background: #fff;
  /* Contrast ratio: 2.85:1 (fails) */
}
```

**Fix:**
```css
.text {
  color: #666;
  background: #fff;
  /* Contrast ratio: 5.74:1 (passes) */
}
```

#### 3. Missing Form Labels

**Problem:**
```html
<input type="email" id="email" />
```

**Fix:**
```html
<label htmlFor="email">Email Address</label>
<input type="email" id="email" />
```

Or use aria-label:
```html
<input type="email" aria-label="Email Address" />
```

#### 4. Invalid ARIA Attributes

**Problem:**
```html
<div role="button" aria-pressed="yes">Click me</div>
```

**Fix:**
```html
<button aria-pressed="true">Click me</button>
```

#### 5. Missing Keyboard Access

**Problem:**
```html
<div onClick={handleClick}>Clickable</div>
```

**Fix:**
```html
<button onClick={handleClick}>Clickable</button>
```

Or make div keyboard accessible:
```html
<div
  role="button"
  tabIndex={0}
  onClick={handleClick}
  onKeyPress={(e) => e.key === 'Enter' && handleClick()}
>
  Clickable
</div>
```

### Testing Your Fixes

1. Make the fix in your component
2. Run tests locally:
   ```bash
   npm run test:a11y
   ```
3. Verify the specific test passes
4. Commit and push
5. Check CI results

## Dashboard and Metrics

### Grafana Dashboard

Access the accessibility dashboard at:
```
https://grafana.fawkes.idp/d/accessibility
```

**Dashboard features:**
- Overall accessibility score trend
- Test pass/fail rate
- Violations by severity
- Violations by component
- WCAG 2.1 AA compliance status
- Historical metrics

### Prometheus Metrics

Query these metrics in Prometheus:

```promql
# Accessibility score
lighthouse_accessibility_score

# Test pass rate
sum(accessibility_tests_passed) / sum(accessibility_tests_total)

# Critical violations
sum(axe_critical_violations)

# Violations by component
sum by (component) (axe_component_violations)

# WCAG compliance status
wcag_aa_compliance_status
```

## Troubleshooting

### Tests Pass Locally But Fail in CI

**Cause**: Environment differences, missing dependencies, or timing issues.

**Solution**:
1. Check CI logs for specific errors
2. Ensure all dependencies are in `package.json`
3. Run tests with CI flag locally:
   ```bash
   npm run test:a11y:ci
   ```
4. Check for race conditions in async tests

### Lighthouse Score is Lower Than Expected

**Cause**: Storybook build issues, network problems, or threshold too high.

**Solution**:
1. Build Storybook locally and inspect:
   ```bash
   npm run build-storybook
   npx http-server storybook-static
   ```
2. Check Lighthouse report for specific issues
3. Review `lighthouserc.json` configuration
4. Temporarily lower threshold while fixing issues

### False Positives

**Cause**: Axe-core might flag valid patterns as violations.

**Solution**:
1. Review the violation carefully
2. Check if it's a legitimate issue
3. If it's a false positive, add to `.axerc.json`:
   ```json
   {
     "rules": {
       "rule-id": { "enabled": false }
     }
   }
   ```
4. Document why you disabled the rule

### GitHub Actions Workflow Failing

**Cause**: Workflow configuration issues or missing secrets.

**Solution**:
1. Check workflow logs in GitHub Actions
2. Verify all required secrets are set
3. Check file paths are correct
4. Ensure Node version is compatible
5. Re-run workflow after fixes

### Jenkins Pipeline Hanging

**Cause**: Lighthouse might be waiting for user input or timing out.

**Solution**:
1. Check Jenkins console output
2. Increase timeout in `lighthouserc.json`:
   ```json
   {
     "ci": {
       "collect": {
         "numberOfRuns": 1
       }
     }
   }
   ```
3. Use headless mode in Jenkins agent

## Resources

### WCAG Guidelines
- [WCAG 2.1 Quick Reference](https://www.w3.org/WAI/WCAG21/quickref/)
- [Understanding WCAG 2.1](https://www.w3.org/WAI/WCAG21/Understanding/)
- [How to Meet WCAG](https://www.w3.org/WAI/WCAG21/quickref/)

### Tools Documentation
- [axe-core Documentation](https://github.com/dequelabs/axe-core)
- [jest-axe Documentation](https://github.com/nickcolley/jest-axe)
- [Lighthouse CI Documentation](https://github.com/GoogleChrome/lighthouse-ci/blob/main/docs/getting-started.md)

### Learning Resources
- [WebAIM Articles](https://webaim.org/articles/)
- [A11y Project](https://www.a11yproject.com/)
- [MDN Accessibility](https://developer.mozilla.org/en-US/docs/Web/Accessibility)
- [Inclusive Components](https://inclusive-components.design/)

### Browser Extensions
- [axe DevTools](https://www.deque.com/axe/devtools/)
- [WAVE](https://wave.webaim.org/extension/)
- [Lighthouse](https://developers.google.com/web/tools/lighthouse)

## Getting Help

If you need help with accessibility testing:

1. Check this documentation
2. Review existing test examples in `design-system/src/`
3. Check the [A11y Project](https://www.a11yproject.com/)
4. Ask in `#accessibility` Slack channel
5. Create an issue with the `accessibility` label

## Contributing

To improve accessibility testing:

1. Add more comprehensive tests
2. Update test utilities
3. Improve documentation
4. Share learnings with the team
5. Propose new quality gates

---

**Last Updated**: 2025-12-24
**Maintained By**: Fawkes Platform Team
