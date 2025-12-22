Feature: AI Code Review Service
  As a software engineer
  I want automated AI-powered code reviews on my pull requests
  So that I can catch issues early and improve code quality

  Background:
    Given the AI code review service is running
    And GitHub webhook integration is configured
    And the RAG service is available for context

  Scenario: AI code review service is deployed
    Given I check the Kubernetes cluster
    When I look for the ai-code-review deployment
    Then the deployment should exist in the fawkes namespace
    And the deployment should have 2 ready replicas
    And the service should be accessible on port 8000

  Scenario: GitHub webhook endpoint is configured
    Given the AI code review service is running
    When I check the webhook endpoint "/webhook/github"
    Then the endpoint should accept POST requests
    And the endpoint should verify GitHub signatures
    And the endpoint should return 200 for valid requests

  Scenario: Security review category works
    Given a pull request with potential security issues
    When the AI code review bot analyzes the PR
    Then it should identify SQL injection vulnerabilities
    And it should identify hardcoded secrets
    And it should identify authentication bypass risks
    And it should post security-related comments to the PR

  Scenario: Performance review category works
    Given a pull request with performance issues
    When the AI code review bot analyzes the PR
    Then it should identify N+1 query problems
    And it should identify inefficient algorithms
    And it should identify memory leaks
    And it should post performance-related comments to the PR

  Scenario: Best practices review category works
    Given a pull request with code quality issues
    When the AI code review bot analyzes the PR
    Then it should identify SOLID principle violations
    And it should identify DRY violations
    And it should identify poor error handling
    And it should post best practice comments to the PR

  Scenario: Test coverage review category works
    Given a pull request with inadequate test coverage
    When the AI code review bot analyzes the PR
    Then it should identify missing unit tests
    And it should identify missing edge case tests
    And it should identify untested error conditions
    And it should post test coverage comments to the PR

  Scenario: Documentation review category works
    Given a pull request with missing documentation
    When the AI code review bot analyzes the PR
    Then it should identify missing docstrings
    And it should identify missing API documentation
    And it should identify unclear code sections
    And it should post documentation comments to the PR

  Scenario: SonarQube integration works
    Given SonarQube has analyzed a pull request
    And the AI code review bot has also analyzed the PR
    When the findings are combined
    Then duplicate findings should be removed
    And unique findings from both sources should be preserved
    And findings should be prioritized by severity

  Scenario: False positive rate is acceptable
    Given the AI code review bot has analyzed 100 pull requests
    When I check the false positive metrics
    Then the false positive rate should be below 20%
    And high-confidence findings should be prioritized
    And low-confidence findings should be filtered out

  Scenario: RAG integration provides context
    Given a pull request modifies authentication code
    When the AI code review bot analyzes the PR
    Then it should query the RAG service for authentication documentation
    And it should use the retrieved context in the review
    And it should reference relevant internal standards

  Scenario: Review comments are posted to GitHub
    Given a pull request has been analyzed
    And the AI has identified 5 issues
    When the review is complete
    Then 5 review comments should be posted to the GitHub PR
    And each comment should include the issue category
    And each comment should include severity level
    And each comment should include actionable recommendations

  Scenario: Webhook signature verification prevents tampering
    Given an unauthorized webhook request is sent
    When the request has an invalid signature
    Then the webhook should reject the request with 401
    And no review should be triggered
    And an error should be logged

  Scenario: Service handles large pull requests gracefully
    Given a pull request with 50 changed files
    When the AI code review bot analyzes the PR
    Then it should review only the first 20 files
    And it should prioritize critical files
    And it should complete within 60 seconds
    And it should not exceed the comment limit

  Scenario: Metrics are exposed for monitoring
    Given the AI code review service is running
    When I check the metrics endpoint "/metrics"
    Then I should see "ai_review_webhooks_total" metric
    And I should see "ai_review_reviews_total" metric
    And I should see "ai_review_duration_seconds" metric
    And I should see "ai_review_comments_total" metric
    And I should see "ai_review_false_positive_rate" metric

  Scenario: Service configuration is documented
    Given I check the service documentation
    Then I should find configuration for GITHUB_TOKEN
    And I should find configuration for GITHUB_WEBHOOK_SECRET
    And I should find configuration for LLM_API_KEY
    And I should find configuration for SONARQUBE_URL
    And I should find configuration for RAG_SERVICE_URL

  Scenario: Service has proper error handling
    Given the GitHub API is unavailable
    When a webhook is received
    Then the service should retry with exponential backoff
    And it should log the error
    And it should return a 500 status code
    And it should not crash

  Scenario: Review engine respects rate limits
    Given the service is processing multiple PRs
    When GitHub API rate limits are approaching
    Then the service should slow down requests
    And it should prioritize critical reviews
    And it should log rate limit warnings

  Scenario: Service uses caching to improve performance
    Given a PR has been reviewed before
    When a new commit is pushed to the same PR
    Then the service should use cached analysis for unchanged files
    And it should only review the new/modified files
    And the review should complete faster

  @acceptance @at-e2-007
  Scenario: AT-E2-007 - AI Code Review validates all requirements
    Given the Fawkes platform is running
    And the AI code review service is operational
    When I verify the AI code review functionality
    Then the service should meet all requirements:
      | Requirement                          | Status   |
      | AI review bot deployed               | ✓        |
      | GitHub webhook integration           | ✓        |
      | Review categories implemented        | ✓        |
      | Security analysis working            | ✓        |
      | Performance analysis working         | ✓        |
      | Best practices analysis working      | ✓        |
      | Test coverage analysis working       | ✓        |
      | Documentation analysis working       | ✓        |
      | SonarQube integration working        | ✓        |
      | False positive rate < 20%            | ✓        |
      | RAG integration working              | ✓        |
      | Reviews posted automatically         | ✓        |
      | Metrics instrumented                 | ✓        |
      | Configuration documented             | ✓        |
    And all acceptance criteria should be met
