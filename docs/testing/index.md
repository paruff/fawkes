# Testing Documentation

This section covers testing strategies, implementations, and best practices for the Fawkes platform.

## Testing Strategy

Fawkes implements comprehensive testing at all levels to ensure platform reliability and quality.

- [Test Automation Pattern](../patterns/test-automation.md) - Testing best practices and patterns

## Testing Types

### Unit Testing

- Run unit tests with: `make test-unit` or `pytest tests/unit -v`

### Integration Testing

- Run integration tests with: `make test-integration` or `pytest tests/integration -v`

### End-to-End Testing

- [E2E Testing Summary](../implementation-summaries/E2E_TESTING_SUMMARY.md) - E2E test implementation
- [Validation Tests E2 Summary](../implementation-summaries/VALIDATION_TESTS_E2_SUMMARY.md) - Epic 2 validation tests
- Run E2E tests with: `make test-e2e-all`

### BDD/Acceptance Testing

- Run BDD tests with: `make test-bdd` or `behave tests/bdd/features --tags=@local`

## User Experience Testing

### Accessibility Testing

- [Accessibility Testing Implementation](../implementation-summaries/ACCESSIBILITY_TESTING_IMPLEMENTATION.md) - A11y testing approach
- [Accessibility Testing Guide](../how-to/accessibility-testing-guide.md) - How to test for accessibility

### Usability Testing

- [Usability Testing Implementation](../implementation-summaries/USABILITY_TESTING_IMPLEMENTATION.md) - Usability testing framework
- [Usability Testing Guide](../how-to/usability-testing-guide.md) - Conducting usability tests

## Infrastructure Testing

- [Terratest Implementation](../implementation-summaries/TERRATEST_IMPLEMENTATION_SUMMARY.md) - Infrastructure testing with Terratest
- [Great Expectations Implementation](../implementation-summaries/GREAT_EXPECTATIONS_IMPLEMENTATION.md) - Data quality testing

## Validation & Acceptance

### Epic Validation

- [Epic 3 Final Validation](../implementation-summaries/EPIC_3_FINAL_VALIDATION_SUMMARY.md) - Epic 3 acceptance testing
- [AT-E1-006 Validation Coverage](../AT-E1-006-VALIDATION-COVERAGE.md) - Acceptance test coverage

### Component Validation

- [OpenTelemetry Validation](../validation/OPENTELEMETRY_VALIDATION.md) - Telemetry validation
- [Azure AKS Validation Checklist](../runbooks/azure-aks-validation-checklist.md) - AKS validation
- [Azure Ingress Validation Checklist](../azure-ingress-validation-checklist.md) - Ingress validation

## Testing Commands

```bash
# Run all tests
make test-all

# Run specific test types
make test-unit          # Unit tests
make test-integration   # Integration tests
make test-bdd          # BDD/acceptance tests
make test-e2e-all      # All E2E tests

# Run specific validation tests
make validate-at-e1-001  # AKS cluster
make validate-at-e1-002  # GitOps/ArgoCD
make validate-at-e1-003  # Backstage
```

## Related Documentation

- [Development Guide](../development.md) - Development and testing setup
- [How-To Guides](../how-to/index.md) - Step-by-step testing guides
- [Troubleshooting](../troubleshooting.md) - Common testing issues
- [Runbooks](../runbooks/) - Operational testing procedures
