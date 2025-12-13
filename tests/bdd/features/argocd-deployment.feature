@argocd @gitops @deployment
Feature: Deploy ArgoCD via Helm
  As a platform engineer
  I want to deploy ArgoCD for GitOps continuous delivery management
  So that the platform can manage applications declaratively from Git

  Background:
    Given I have kubectl configured for the cluster
    And the ingress-nginx controller is deployed and running

  @namespace
  Scenario: ArgoCD deployed in argocd namespace
    When I check for the argocd namespace
    Then the namespace "argocd" should exist
    And the namespace "argocd" should be Active

  @pods @health
  Scenario: ArgoCD pods are running
    Given ArgoCD is deployed in namespace "argocd"
    When I check the ArgoCD pods
    Then the following pods should be running in namespace "argocd":
      | component               |
      | argocd-server          |
      | argocd-application-controller |
      | argocd-repo-server     |
      | argocd-redis           |
    And all ArgoCD pods should be in Ready state within 300 seconds

  @ui @ingress @accessibility
  Scenario: ArgoCD UI accessible via ingress
    Given ArgoCD is deployed with ingress enabled
    When I check the ingress configuration in namespace "argocd"
    Then an ingress should exist for "argocd-server"
    And the ingress should have host "argocd.127.0.0.1.nip.io"
    And the ingress should use ingressClassName "nginx"
    And the ArgoCD UI should be accessible at "http://argocd.127.0.0.1.nip.io"

  @cli @credentials
  Scenario: ArgoCD CLI configured and working
    Given ArgoCD is deployed in namespace "argocd"
    When I retrieve the initial admin password
    Then the secret "argocd-initial-admin-secret" should exist in namespace "argocd"
    And the secret should contain a "password" key
    And I should be able to login using argocd CLI

  @security @credentials
  Scenario: Initial admin credentials secured
    Given ArgoCD is deployed in namespace "argocd"
    When I check the admin credentials storage
    Then the credentials should be stored in a Kubernetes secret
    And the secret should be named "argocd-initial-admin-secret"
    And the secret should be in namespace "argocd"
    And the password should be base64 encoded

  @api @health
  Scenario: ArgoCD API server is healthy
    Given ArgoCD server is running in namespace "argocd"
    When I check the ArgoCD server health endpoint
    Then the health endpoint should return status "Healthy"
    And the API server should be responsive

  @resources @stability
  Scenario: ArgoCD components have resource limits
    Given ArgoCD is deployed in namespace "argocd"
    When I check the resource specifications for ArgoCD deployments
    Then all deployments should have CPU requests defined
    And all deployments should have memory requests defined
    And all deployments should have CPU limits defined
    And all deployments should have memory limits defined

  @crds @prerequisites
  Scenario: ArgoCD CRDs are installed
    Given ArgoCD is deployed
    When I check for ArgoCD Custom Resource Definitions
    Then the following CRDs should exist:
      | crd                                      |
      | applications.argoproj.io                |
      | applicationsets.argoproj.io             |
      | appprojects.argoproj.io                 |
    And all CRDs should be established

  @service @networking
  Scenario: ArgoCD services are configured correctly
    Given ArgoCD is deployed in namespace "argocd"
    When I check the ArgoCD services
    Then a service "argocd-server" should exist
    And the service "argocd-server" should be type "ClusterIP"
    And the service should expose port 80 for HTTP
    And the service should expose port 443 for HTTPS
