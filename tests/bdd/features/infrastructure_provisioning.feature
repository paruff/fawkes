# tests/e2e/features/infrastructure_provisioning.feature

@smoke @white-belt
Feature: Infrastructure Provisioning
  As a platform engineer
  I want to provision AWS infrastructure with one command
  So that I can quickly set up the Fawkes platform

  @dora-deployment-frequency
  Scenario: Provision AWS EKS cluster
    Given I have AWS credentials configured
    And I have Terraform installed
    When I run "./scripts/ignite.sh --provider aws dev"
    Then the script completes successfully within 30 minutes
    And an EKS cluster named "fawkes-dev" is created
    And the cluster has 3 worker nodes
    And kubectl can connect to the cluster