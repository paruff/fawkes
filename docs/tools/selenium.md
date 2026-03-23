# Selenium

[Selenium](https://www.selenium.dev/) is an open-source browser automation framework used
for end-to-end (E2E) UI testing. It supports multiple browsers (Chrome, Firefox, Edge)
and languages (Java, Python, JavaScript).

## How Fawkes Uses Selenium

Fawkes uses Selenium for browser-based E2E tests of the platform's web interfaces,
including the Backstage developer portal and any custom web UIs. E2E tests live in
`tests/e2e/` and run as part of the CI pipeline after deployment to a test environment.

```bash
# Run E2E tests locally
make test-e2e-all

# Run a specific suite
make test-e2e-argocd
```

## Test Structure

Selenium tests in Fawkes follow the Page Object Model (POM) pattern:

```python
# tests/e2e/pages/backstage_page.py
class BackstagePage:
    def __init__(self, driver):
        self.driver = driver

    def navigate_to_catalog(self):
        self.driver.get("/catalog")
        return self
```

This separates test logic from page interaction code, making tests easier to maintain
when the UI changes.

## Running in CI

Jenkins executes E2E tests inside a Docker container with Chrome headless. The Selenium
Grid or a local ChromeDriver handles browser automation without a visible display.

## Best Practices

- **Use explicit waits** (`WebDriverWait`) rather than `time.sleep()` to avoid flaky tests.
- **Clean up test data** after each test to maintain a consistent test environment.
- **Limit E2E tests** to critical user journeys — they are slow and brittle compared to
  unit or integration tests. Prefer lower-level tests for business logic.
- **Tag tests** with `@smoke`, `@critical`, or `@regression` so CI can run subsets.

## See Also

- [Test Automation Pattern](../patterns/test-automation.md)
- [E2E Tests Directory](../testing/index.md)
- [GitHub Actions Workflows](../how-to/development/github-actions-workflows.md)
