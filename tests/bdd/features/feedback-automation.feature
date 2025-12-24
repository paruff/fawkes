@feedback-automation @feedback
Feature: Feedback-to-Issue Automation
  As a platform team
  I want automated conversion of validated feedback into GitHub issues
  So that user feedback is promptly addressed with appropriate prioritization

  Background:
    Given the feedback service is running
    And the GitHub integration is configured
    And AI triage is enabled

  Scenario: AI triage calculates correct priority for critical bug
    Given a feedback submission with type "bug_report"
    And the feedback has rating 1
    And the feedback comment contains "critical security vulnerability"
    And the feedback has negative sentiment
    When AI triage is performed
    Then the priority should be "P0"
    And the suggested labels should include "bug", "security", and "P0"
    And the suggested milestone should be "Hotfix"

  Scenario: AI triage calculates correct priority for feature request
    Given a feedback submission with type "feature_request"
    And the feedback has rating 4
    And the feedback comment contains "nice to have enhancement"
    And the feedback has positive sentiment
    When AI triage is performed
    Then the priority should be "P2" or "P3"
    And the suggested labels should include "enhancement"
    And the suggested milestone should be "Backlog" or "Future"

  Scenario: Duplicate detection prevents duplicate issue creation
    Given an existing GitHub issue with title "Login page not working"
    And a feedback submission with comment "The login page is not working properly"
    When AI triage is performed with duplicate detection
    Then potential duplicates should be found
    And the should_create_issue flag should be false
    And duplicate notification should be sent

  Scenario: Auto-labeling based on feedback content
    Given a feedback submission about "performance issues with slow loading"
    When AI triage is performed
    Then the suggested labels should include "performance"
    And the suggested labels should include "category:performance"

  Scenario: High-priority feedback triggers immediate notification
    Given a feedback submission with type "bug_report"
    And the feedback has rating 1
    And the feedback comment contains "urgent blocker"
    When the feedback is submitted
    Then a high-priority notification should be sent
    And the notification should include priority "P0"

  Scenario: Automated processing creates GitHub issues for validated feedback
    Given 3 validated feedback submissions without GitHub issues
    And the feedback items have status "open"
    When the automation pipeline processes validated feedback
    Then GitHub issues should be created for non-duplicate feedback
    And the feedback status should be updated to "in_progress"
    And the GitHub issue URL should be linked to feedback
    And notifications should be sent for each issue created

  Scenario: Automation pipeline skips duplicate feedback
    Given 2 validated feedback submissions
    And one feedback is a duplicate of an existing issue
    When the automation pipeline processes validated feedback
    Then only 1 GitHub issue should be created
    And the duplicate feedback should be skipped
    And a duplicate notification should be sent

  Scenario: Automation summary notification is sent
    Given multiple feedback items are processed by automation
    When the automation pipeline completes
    Then an automation summary notification should be sent
    And the summary should include processed count
    And the summary should include issues created count
    And the summary should include duplicates skipped count

  Scenario: Triage endpoint returns complete analysis
    Given a feedback submission exists in the database
    When an admin requests AI triage via API
    Then the response should include priority and score
    And the response should include suggested labels
    And the response should include potential duplicates
    And the response should include suggested milestone
    And the response should include should_create_issue flag

  Scenario: Manual feedback submission with auto-issue creation
    Given a user submits feedback with create_github_issue flag set
    And the feedback is critical priority
    When the feedback is processed
    Then a GitHub issue should be created automatically
    And the issue should have appropriate labels
    And the issue URL should be linked to the feedback
    And a notification should be sent

  Scenario: Automation respects GitHub integration status
    Given the GitHub token is not configured
    When the automation pipeline is triggered
    Then an error should be returned
    And no GitHub issues should be created
    And the error message should mention GitHub integration

  Scenario: Keyword-based priority scoring works correctly
    Given a feedback submission contains keywords "critical", "blocker", "outage"
    When AI triage calculates priority
    Then the keyword score should be high
    And the matched keywords should be recorded
    And the overall priority should be elevated

  Scenario: Sentiment analysis influences priority
    Given a feedback submission with rating 2
    And the feedback has very negative sentiment (compound < -0.5)
    When AI triage calculates priority
    Then the sentiment score should contribute to priority
    And the priority should be elevated due to negative sentiment

  Scenario: Category influences priority scoring
    Given a feedback submission in "Security" category
    When AI triage calculates priority
    Then the category score should be applied
    And the overall priority should be elevated

  Scenario: Notification system can be disabled
    Given notifications are disabled via configuration
    When an issue is created from feedback
    Then no notifications should be sent
    And the issue creation should still succeed

  Scenario: Batch automation respects limit parameter
    Given 20 validated feedback submissions exist
    When automation is triggered with limit of 5
    Then only 5 feedback items should be processed
    And 5 or fewer issues should be created

  Scenario: Automation handles errors gracefully
    Given a feedback submission with invalid data
    When the automation pipeline processes it
    Then the error should be logged
    And other feedback items should still be processed
    And the error should be included in the result

  Scenario: Priority labels are correctly mapped
    Given feedback submissions with different priorities
    | priority | expected_milestone |
    | P0       | Hotfix            |
    | P1       | Next Sprint       |
    | P2       | Backlog           |
    | P3       | Future            |
    When AI triage determines milestones
    Then the correct milestone should be suggested for each priority

  Scenario: Similar feedback is detected with high accuracy
    Given a feedback comment "The application is very slow"
    And an existing issue with body "The app is extremely slow"
    When duplicate detection is performed
    Then the similarity score should be above 0.5
    And the issue should be flagged as potential duplicate
