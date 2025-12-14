@jenkins @kubernetes @issue-14
Feature: Jenkins Deployment with Kubernetes Plugin
  As a platform engineer
  I want Jenkins deployed via ArgoCD with Kubernetes plugin
  So that CI/CD pipelines can use dynamic agent provisioning

  Background:
    Given the Fawkes platform namespace exists
    And ArgoCD is deployed and running

  @smoke @deployment
  Scenario: Jenkins is deployed via ArgoCD
    Given the Jenkins ArgoCD Application is created
    When I check the Jenkins deployment status
    Then Jenkins should be running in the fawkes namespace
    And the Jenkins pod should be in Ready state
    And the Jenkins service should be created

  @kubernetes-plugin @configuration
  Scenario: Kubernetes plugin is configured
    Given Jenkins is deployed and running
    When I check the Jenkins configuration
    Then the Kubernetes cloud should be configured
    And the Kubernetes cloud should target the fawkes namespace
    And the Jenkins URL should be "http://jenkins:8080"
    And the Jenkins tunnel should be "jenkins-agent:50000"

  @agent-templates @configuration
  Scenario: Agent templates are configured
    Given Jenkins is deployed with Kubernetes plugin
    When I check the configured agent templates
    Then the following agent templates should exist:
      | template      | label           | image                           |
      | jnlp-agent    | k8s-agent       | jenkins/inbound-agent:latest    |
      | maven-agent   | maven java      | maven:3.9-eclipse-temurin-17    |
      | python-agent  | python          | python:3.11-slim                |
      | node-agent    | node nodejs     | node:20-slim                    |
      | go-agent      | go golang       | golang:1.21                     |

  @dynamic-provisioning @functional
  Scenario: Dynamic agent provisioning works
    Given Jenkins is accessible
    And the Kubernetes plugin is configured
    When a pipeline job requests a "k8s-agent" label
    Then a Kubernetes pod should be created dynamically
    And the pod should run in the fawkes namespace
    And the pod should connect to Jenkins controller
    And the job should execute on the dynamic agent
    And the pod should be terminated after job completion

  @ingress @accessibility
  Scenario: Jenkins UI is accessible via Ingress
    Given Jenkins is deployed with Ingress enabled
    When I access the Jenkins URL "http://jenkins.127.0.0.1.nip.io"
    Then I should receive a successful HTTP response
    And the Jenkins login page should be displayed
    And the page should be served over the nginx ingress

  @security @authentication
  Scenario: Jenkins authentication is configured
    Given Jenkins is deployed
    When I attempt to access Jenkins without credentials
    Then I should be redirected to the login page
    And anonymous access should be denied
    When I login with valid admin credentials
    Then I should be authenticated successfully
    And I should have access to Jenkins dashboard

  @resource-limits @configuration
  Scenario: Agent resource limits are configured
    Given Jenkins has maven-agent template configured
    When I check the maven-agent resource configuration
    Then the CPU request should be "1"
    And the memory request should be "2Gi"
    And the CPU limit should be "2"
    And the memory limit should be "4Gi"

  @idle-termination @configuration
  Scenario: Agent idle termination is configured
    Given Jenkins agent templates are configured
    When I check the agent idle termination settings
    Then all agent templates should have idleTerminationMinutes set to 10
    And idle agents should be terminated after the configured time

  @capacity @configuration
  Scenario: Agent capacity limits are configured
    Given the Kubernetes cloud is configured
    When I check the capacity settings
    Then the container capacity should be "20"
    And each agent template should have appropriate instance capacity

  @jcasc @configuration
  Scenario: Jenkins Configuration as Code is working
    Given Jenkins is deployed with JCasC enabled
    When I check the Jenkins system message
    Then it should display "Fawkes CI/CD Platform - Golden Path Enabled"
    And the number of executors on controller should be 0
    And all configuration should be loaded from JCasC
