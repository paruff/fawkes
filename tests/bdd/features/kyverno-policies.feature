# tests/bdd/features/kyverno-policies.feature

@kyverno @policy-engine @security @governance
Feature: Kyverno Policy Enforcement Engine
  As a platform engineer
  I want to deploy and configure Kyverno as the native Kubernetes policy engine
  So that Fawkes IDP can enforce critical security, standardization, and governance policies

  Background:
    Given I have kubectl configured for the cluster
    And Kyverno is deployed and running in the cluster

  @validation @security @runAsNonRoot
  Scenario: Validation - Security Gate (runAsNonRoot enforcement)
    Given a Kyverno validation policy is active that enforces runAsNonRoot security context
    When a developer attempts to deploy a Pod with securityContext.runAsNonRoot set to false
    Then the admission request is denied
    And the user receives a descriptive error message explaining the policy violation

  @mutation @vault-integration
  Scenario: Mutation - Vault Integration
    Given a mutation policy is active that ensures Pods use the Vault Agent Sidecar
    And the Pod has the label vault.fawkes.idp/inject set to true
    When a developer creates a Deployment without the required Vault annotations
    Then Kyverno automatically mutates the Deployment resource
    And the necessary Vault Agent Sidecar annotations are added

  @generation @namespace-standards
  Scenario: Generation - Namespace Standardization
    Given a generation policy is active for new Namespaces
    When a developer creates a new Namespace resource
    Then Kyverno automatically generates a default NetworkPolicy
    And Kyverno automatically generates a default ResourceQuota
    And Kyverno automatically generates a default LimitRange

  @reporting @auditability
  Scenario: Reporting and Auditability
    Given Kyverno is deployed with policy reporting enabled
    When a valid or invalid resource is submitted to the cluster API
    Then the action is recorded in a PolicyReport custom resource
    And policy violations are visible via kubectl get policyreport

  @validation @resource-limits @failure
  Scenario: Resource Constraints Validation (Failure)
    Given a validation policy enforces mandatory resource limits
    When a developer attempts to deploy a Pod without specifying memory limits
    Then the admission request is denied
    And the error message details the missing required field

  @validation @resource-limits @success
  Scenario: Resource Constraints Validation (Success)
    Given a validation policy enforces mandatory resource limits
    When a developer deploys a Pod with properly specified resource limits
    Then the admission request is accepted
    And the Pod is created successfully

  @mutation @platform-labels
  Scenario: Mutation - Platform Labels
    Given a mutation policy is active that adds platform standard labels
    When a developer creates a Deployment without Fawkes platform labels
    Then Kyverno automatically adds the app.fawkes.idp/managed-by label
    And Kyverno automatically adds the app.fawkes.idp/environment label

  @validation @privileged-containers
  Scenario: Validation - Disallow Privileged Containers
    Given a validation policy disallows privileged containers
    When a developer attempts to deploy a Pod with privileged set to true
    Then the admission request is denied
    And the error message explains that privileged containers are not allowed

  @validation @host-namespaces
  Scenario: Validation - Restrict Host Namespaces
    Given a validation policy restricts host namespace access
    When a developer attempts to deploy a Pod with hostNetwork set to true
    Then the admission request is denied
    And the error message explains that host namespaces are not allowed

  @mutation @ingress-class
  Scenario: Mutation - Set Default Ingress Class
    Given a mutation policy sets the default Ingress class
    When a developer creates an Ingress without specifying ingressClassName
    Then Kyverno automatically sets the ingressClassName to nginx
