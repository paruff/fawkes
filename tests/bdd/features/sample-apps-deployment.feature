@sample-apps @deployment @dora-metrics
Feature: Sample Applications Deployment
  As a platform engineer
  I want to deploy sample Java, Python, and Node.js applications
  So that I can test the platform's capabilities and collect DORA metrics

  Background:
    Given the Fawkes platform is running
    And ArgoCD is deployed and healthy
    And the fawkes-samples namespace is configured

  Scenario: Deploy sample Java Spring Boot application
    Given the sample Java application source code exists
    When I apply the ArgoCD application manifest for sample-java-app
    Then the ArgoCD application "sample-java-app" should be created
    And the ArgoCD application "sample-java-app" should sync successfully
    And the deployment "sample-java-app" should exist in namespace "fawkes-samples"
    And the deployment "sample-java-app" should have 2 ready replicas
    And the service "sample-java-app" should exist in namespace "fawkes-samples"
    And the ingress "sample-java-app" should exist in namespace "fawkes-samples"
    And the ingress should have TLS configured for "sample-java-app.fawkes.idp"

  Scenario: Deploy sample Python FastAPI application
    Given the sample Python application source code exists
    When I apply the ArgoCD application manifest for sample-python-app
    Then the ArgoCD application "sample-python-app" should be created
    And the ArgoCD application "sample-python-app" should sync successfully
    And the deployment "sample-python-app" should exist in namespace "fawkes-samples"
    And the deployment "sample-python-app" should have 2 ready replicas
    And the service "sample-python-app" should exist in namespace "fawkes-samples"
    And the ingress "sample-python-app" should exist in namespace "fawkes-samples"
    And the ingress should have TLS configured for "sample-python-app.fawkes.idp"

  Scenario: Deploy sample Node.js Express application
    Given the sample Node.js application source code exists
    When I apply the ArgoCD application manifest for sample-nodejs-app
    Then the ArgoCD application "sample-nodejs-app" should be created
    And the ArgoCD application "sample-nodejs-app" should sync successfully
    And the deployment "sample-nodejs-app" should exist in namespace "fawkes-samples"
    And the deployment "sample-nodejs-app" should have 2 ready replicas
    And the service "sample-nodejs-app" should exist in namespace "fawkes-samples"
    And the ingress "sample-nodejs-app" should exist in namespace "fawkes-samples"
    And the ingress should have TLS configured for "sample-nodejs-app.fawkes.idp"

  Scenario: All sample applications are accessible via ingress
    Given all sample applications are deployed
    When I access "https://sample-java-app.fawkes.idp/actuator/health"
    Then I should receive a 200 OK response
    And the response should contain health status "UP"
    When I access "https://sample-python-app.fawkes.idp/health"
    Then I should receive a 200 OK response
    And the response should contain health status "healthy"
    When I access "https://sample-nodejs-app.fawkes.idp/health"
    Then I should receive a 200 OK response
    And the response should contain health status "healthy"

  Scenario: Prometheus metrics are exposed by all sample applications
    Given all sample applications are deployed
    When I access "https://sample-java-app.fawkes.idp/actuator/prometheus"
    Then I should receive a 200 OK response
    And the response should contain Prometheus metrics
    When I access "https://sample-python-app.fawkes.idp/metrics"
    Then I should receive a 200 OK response
    And the response should contain Prometheus metrics
    When I access "https://sample-nodejs-app.fawkes.idp/metrics"
    Then I should receive a 200 OK response
    And the response should contain Prometheus metrics

  Scenario: DORA metrics collection is enabled for all sample applications
    Given all sample applications are deployed
    When I check the ArgoCD application "sample-java-app" annotations
    Then the annotation "dora.fawkes.io/collect-metrics" should be "true"
    And the annotation "dora.fawkes.io/environment" should be "dev"
    When I check the ArgoCD application "sample-python-app" annotations
    Then the annotation "dora.fawkes.io/collect-metrics" should be "true"
    And the annotation "dora.fawkes.io/environment" should be "dev"
    When I check the ArgoCD application "sample-nodejs-app" annotations
    Then the annotation "dora.fawkes.io/collect-metrics" should be "true"
    And the annotation "dora.fawkes.io/environment" should be "dev"

  Scenario: Sample applications are registered in Backstage catalog
    Given Backstage is deployed and healthy
    And all sample applications are deployed
    When I query the Backstage API for components
    Then the component "sample-java-app" should be registered
    And the component "sample-java-app" should have language tag "java"
    And the component "sample-python-app" should be registered
    And the component "sample-python-app" should have language tag "python"
    And the component "sample-nodejs-app" should be registered
    And the component "sample-nodejs-app" should have language tag "nodejs"

  Scenario: Sample applications have proper security context
    Given all sample applications are deployed
    When I check the deployment "sample-java-app" security context
    Then the pod should run as non-root
    And the pod should have read-only root filesystem
    And the pod should drop all capabilities
    When I check the deployment "sample-python-app" security context
    Then the pod should run as non-root
    And the pod should have read-only root filesystem
    And the pod should drop all capabilities
    When I check the deployment "sample-nodejs-app" security context
    Then the pod should run as non-root
    And the pod should have read-only root filesystem
    And the pod should drop all capabilities

  Scenario: Sample applications have resource limits configured
    Given all sample applications are deployed
    When I check the deployment "sample-java-app" resource configuration
    Then the deployment should have CPU requests defined
    And the deployment should have memory requests defined
    And the deployment should have CPU limits defined
    And the deployment should have memory limits defined
    When I check the deployment "sample-python-app" resource configuration
    Then the deployment should have CPU requests defined
    And the deployment should have memory requests defined
    And the deployment should have CPU limits defined
    And the deployment should have memory limits defined
    When I check the deployment "sample-nodejs-app" resource configuration
    Then the deployment should have CPU requests defined
    And the deployment should have memory requests defined
    And the deployment should have CPU limits defined
    And the deployment should have memory limits defined

  Scenario: Sample applications deployment triggers DORA metrics
    Given DevLake is configured to collect DORA metrics
    And all sample applications are deployed
    When I trigger a new deployment for "sample-java-app"
    Then DevLake should record a deployment event
    And the deployment frequency metric should be updated
    And the lead time for changes should be calculated
    When I check the DORA metrics in DevLake
    Then I should see deployment data for "sample-java-app"
    And I should see deployment data for "sample-python-app"
    And I should see deployment data for "sample-nodejs-app"
