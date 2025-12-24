Feature: Automated Accessibility Testing
  As a Platform Engineer
  I want automated accessibility testing integrated into CI/CD
  So that we ensure WCAG 2.1 AA compliance for all components

  Background:
    Given the Fawkes platform is deployed
    And the design system components are available
    And accessibility testing tools are configured

  @accessibility @wcag @critical
  Scenario: Axe-core integration in CI/CD pipeline
    Given I have a component in the design system
    When the CI/CD pipeline runs
    Then axe-core accessibility tests should execute
    And the tests should check for WCAG 2.1 AA violations
    And test results should be published to the build artifacts
    And the pipeline should fail if critical violations are found

  @accessibility @lighthouse @critical
  Scenario: Lighthouse CI configured for accessibility audits
    Given the design system Storybook is built
    When Lighthouse CI runs accessibility audits
    Then the accessibility score should be calculated
    And the score should meet the minimum threshold of 90
    And detailed reports should be generated
    And reports should be uploaded as artifacts

  @accessibility @quality-gate @critical
  Scenario: WCAG 2.1 AA compliance gates enforced
    Given accessibility tests are running in the pipeline
    When any WCAG 2.1 AA violation is detected
    Then the build should fail with a clear error message
    And the violation details should be logged
    And a link to the full report should be provided
    And remediation guidance should be included

  @accessibility @dashboard @important
  Scenario: Accessibility metrics displayed in dashboard
    Given Grafana is configured with accessibility metrics
    When I navigate to the accessibility dashboard
    Then I should see the overall accessibility score
    And I should see the test pass rate trend
    And I should see violations grouped by severity
    And I should see violations grouped by component
    And I should see WCAG 2.1 AA compliance status

  @accessibility @automation @important
  Scenario: Auto-creation of GitHub issues for violations
    Given accessibility tests detect violations
    And the tests run on the main branch or on schedule
    When critical violations are found
    Then a GitHub issue should be created automatically
    And the issue should have the "accessibility" label
    And the issue should have the "automated" label
    And the issue should include violation details
    And the issue should link to test reports
    And duplicate issues should not be created within 7 days

  @accessibility @components @important
  Scenario: All design system components pass accessibility tests
    Given the design system has multiple components
    When axe-core tests run against each component
    Then Button component should have no violations
    And Alert component should have no violations
    And Card component should have no violations
    And Checkbox component should have no violations
    And all interactive elements should be keyboard accessible
    And all elements should have proper ARIA attributes

  @accessibility @color-contrast @important
  Scenario: Color contrast meets WCAG AA requirements
    Given design system components use various color schemes
    When color contrast is tested
    Then all text should meet minimum contrast ratio of 4.5:1
    And large text should meet minimum contrast ratio of 3:1
    And interactive elements should have sufficient contrast
    And color should not be the only means of conveying information

  @accessibility @keyboard @important
  Scenario: Keyboard navigation works for all interactive elements
    Given design system components include interactive elements
    When keyboard navigation is tested
    Then all buttons should be keyboard accessible
    And all form controls should be keyboard accessible
    And focus indicators should be visible
    And tab order should be logical
    And keyboard traps should not exist

  @accessibility @screen-reader @important
  Scenario: Screen reader compatibility verified
    Given design system components use ARIA attributes
    When screen reader compatibility is tested
    Then all images should have alt text
    And all buttons should have accessible names
    And all form inputs should have labels
    And ARIA roles should be valid
    And ARIA attributes should be properly used
    And semantic HTML should be used where appropriate

  @accessibility @documentation @normal
  Scenario: Accessibility testing documentation is available
    Given the Fawkes documentation repository
    When I navigate to the accessibility testing guide
    Then I should find instructions for running tests locally
    And I should find information about WCAG 2.1 AA requirements
    And I should find troubleshooting guidance
    And I should find examples of common violations and fixes
    And I should find links to accessibility resources

  @accessibility @jenkins @important
  Scenario: Jenkins pipeline includes accessibility testing stage
    Given a service uses the Golden Path pipeline
    When the Jenkins pipeline executes
    Then there should be an accessibility testing stage
    And the stage should run after unit tests
    And the stage should run before deployment
    And axe-core tests should execute in the stage
    And Lighthouse CI should execute in the stage
    And results should be published to Jenkins

  @accessibility @metrics @normal
  Scenario: Accessibility metrics are tracked over time
    Given accessibility tests run regularly
    When I query the metrics system
    Then I should see accessibility score trends
    And I should see violation counts by severity
    And I should see test pass/fail rates
    And I should see metrics per component
    And metrics should be available in Prometheus
    And metrics should be visualized in Grafana

  @accessibility @alerts @normal  
  Scenario: Alerts are triggered for accessibility failures
    Given accessibility monitoring is configured
    When accessibility tests fail on main branch
    Then an alert should be sent to the team
    And the alert should include failure details
    And the alert should link to the build
    And the alert should link to the dashboard
    And the alert should be sent via configured channels

  @accessibility @local-dev @normal
  Scenario: Developers can run accessibility tests locally
    Given I am a developer working on a component
    When I run "npm run test:a11y" in design-system
    Then axe-core tests should execute locally
    And I should see test results in the console
    And I should see violation details if any exist
    And the command should exit with appropriate code
    And I can run tests in watch mode for development

  @accessibility @pr-checks @critical
  Scenario: Pull requests include accessibility test results
    Given a pull request modifies design system components
    When the CI workflow runs on the pull request
    Then accessibility tests should execute
    And test results should be commented on the PR
    And Lighthouse scores should be displayed
    And the PR check should pass/fail based on results
    And developers should receive immediate feedback
