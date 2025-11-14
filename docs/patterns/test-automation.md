---
title: Test Automation Pattern
description: Implementation patterns for test automation based on DORA research and elite performance practices
---

# Test Automation Pattern

![Test Pyramid](../assets/images/patterns/test-pyramid.png){ width="600" }

Test automation is a critical capability identified in DORA research that enables organizations to achieve elite performance through rapid, reliable feedback cycles. According to the research, elite performers automate 95% of their tests.

## Core Principles

| Principle | Description | Implementation |
|-----------|-------------|----------------|
| ![](../assets/images/icons/pyramid.png){ width="24" } **Test Pyramid** | Balance test types for optimal coverage | Unit (70%), Integration (20%), E2E (10%) |
| ![](../assets/images/icons/shift-left.png){ width="24" } **Shift Left** | Test early in development cycle | CI pipeline integration |
| ![](../assets/images/icons/reliable.png){ width="24" } **Reliability** | Tests should be deterministic | Avoid flaky tests |
| ![](../assets/images/icons/fast.png){ width="24" } **Speed** | Quick feedback loops | Parallel test execution |
| ![](../assets/images/icons/trunk.png){ width="24" } **Trunk-Based** | Support frequent integration | Pre-merge testing |

## Implementation Guide

### 1. Unit Testing

```java
@Test
void deploymentFrequencyCalculation() {
    // Arrange
    DeploymentMetrics metrics = new DeploymentMetrics();
    List<Deployment> deployments = Arrays.asList(
        new Deployment("2023-01-01"),
        new Deployment("2023-01-02")
    );

    // Act
    double frequency = metrics.calculateFrequency(deployments);

    // Assert
    assertEquals(2.0, frequency, "Should calculate correct deployment frequency");
}

@Test
void shouldHandleNoDeployments() {
    // Arrange
    DeploymentMetrics metrics = new DeploymentMetrics();
    List<Deployment> deployments = Collections.emptyList();

    // Act & Assert
    assertDoesNotThrow(() -> metrics.calculateFrequency(deployments));
    assertEquals(0.0, metrics.calculateFrequency(deployments));
}
```

### 2. Integration Testing with TestContainers

```java
@TestContainer
class DeploymentRepositoryTest {
    @Container
    static PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("postgres:14")
        .withDatabaseName("testdb")
        .withUsername("test")
        .withPassword("test");

    @Test
    void shouldPersistDeployment() {
        // Arrange
        DeploymentRepository repository = new DeploymentRepository(postgres.getJdbcUrl());
        Deployment deployment = new Deployment("2023-01-01");

        // Act
        repository.save(deployment);

        // Assert
        Optional<Deployment> found = repository.findById(deployment.getId());
        assertTrue(found.isPresent());
        assertEquals("2023-01-01", found.get().getDate());
    }
}
```

### 3. End-to-End Testing with Cypress

```javascript
describe('Deployment Pipeline', () => {
  beforeEach(() => {
    cy.intercept('GET', '/api/deployments').as('getDeployments');
    cy.login(); // Custom command for authentication
  });

  it('shows deployment metrics dashboard', () => {
    // Arrange
    cy.visit('/dashboard');

    // Act
    cy.wait('@getDeployments');

    // Assert
    cy.get('[data-testid="deployment-frequency"]').should('be.visible');
    cy.get('[data-testid="lead-time"]').should('be.visible');
    cy.get('[data-testid="change-failure-rate"]').should('be.visible');
    cy.get('[data-testid="mttr"]').should('be.visible');
  });

  it('creates new deployment', () => {
    // Arrange
    cy.visit('/deployments/new');

    // Act
    cy.get('[data-testid="service-name"]').type('fawkes-web');
    cy.get('[data-testid="version"]').type('1.0.0');
    cy.get('[data-testid="submit"]').click();

    // Assert
    cy.get('[data-testid="success-message"]')
      .should('be.visible')
      .and('contain', 'Deployment created successfully');
  });
});
```

## Continuous Integration Pipeline

```yaml
# GitHub Actions workflow for test automation
name: Test Automation
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Set up JDK
        uses: actions/setup-java@v3
        with:
          java-version: '17'
          distribution: 'temurin'

      - name: Unit Tests
        run: ./gradlew test

      - name: Integration Tests
        run: ./gradlew integrationTest

      - name: E2E Tests
        uses: cypress-io/github-action@v6
        with:
          browser: chrome
          config-file: cypress.config.js

      - name: Upload Test Reports
        if: always()
        uses: actions/upload-artifact@v3
        with:
          name: test-reports
          path: build/reports/tests/
```

## Test Coverage Goals

| Test Type | Coverage Target | Run Frequency | Max Duration |
|-----------|----------------|---------------|--------------|
| Unit | 80% | Every commit | 3 minutes |
| Integration | 60% | Every PR | 10 minutes |
| E2E | 40% | Daily | 30 minutes |

## Performance Metrics

According to DORA research, elite performers achieve:

- **Test Runtime**: < 10 minutes for the full suite
- **Test Reliability**: > 95% pass rate
- **Coverage**: > 80% of critical paths
- **Automation**: > 95% of all tests

[View Example Project :octicons-code-16:](../examples/test-automation){ .md-button .md-button--primary }
[Testing Guide :octicons-book-16:](../guides/testing){ .md-button }