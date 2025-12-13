# tests/bdd/features/azure_ingress_loadbalancer.feature

@smoke @azure @white-belt
Feature: Azure Load Balancer and Ingress Configuration (AT-E1-002)
  As a platform engineer
  I want to configure Azure Load Balancer and deploy nginx-ingress controller
  So that services can be accessed externally with TLS termination

  Background:
    Given I have an AKS cluster running on Azure
    And I have kubectl configured for the cluster
    And I have ArgoCD installed

  @dora-deployment-frequency @AT-E1-002
  Scenario: Deploy nginx-ingress controller with Azure Load Balancer
    Given I am in the repository root directory
    When I apply the ingress-nginx ArgoCD Application for Azure
    Then the ArgoCD Application "ingress-nginx" should be created
    And the ingress-nginx namespace should exist
    And the ingress-nginx-controller deployment should be running
    And the deployment should have 2 replicas
    And all pods should be in Running state

  @AT-E1-002 @networking
  Scenario: Verify Azure Load Balancer is created
    Given nginx-ingress is deployed on AKS
    When I check the ingress-nginx-controller service
    Then the service type should be LoadBalancer
    And the service should have an external IP assigned
    And the Azure Load Balancer health probe should be configured
    And the external traffic policy should be Local

  @AT-E1-002 @networking
  Scenario: Verify Azure Load Balancer health probes
    Given nginx-ingress is deployed with Azure Load Balancer
    When I check the service annotations
    Then the annotation "service.beta.kubernetes.io/azure-load-balancer-health-probe-request-path" should be set to "/healthz"
    And the health probe endpoint should be accessible

  @AT-E1-002 @security
  Scenario: Verify TLS configuration
    Given nginx-ingress is deployed on AKS
    When I check the ingress controller configuration
    Then SSL redirect should be enabled
    And HSTS should be enabled
    And server tokens should be hidden
    And proxy protocol should be configured appropriately

  @AT-E1-002 @observability
  Scenario: Verify Prometheus metrics are enabled
    Given nginx-ingress is deployed on AKS
    When I check the metrics configuration
    Then Prometheus metrics should be enabled
    And ServiceMonitor should be created
    And PrometheusRules should be configured
    And metrics endpoint should be accessible on port 9402

  @AT-E1-002 @high-availability
  Scenario: Verify high availability configuration
    Given nginx-ingress is deployed on AKS
    When I check the deployment configuration
    Then the deployment should have at least 2 replicas
    And pod anti-affinity should be configured
    And HorizontalPodAutoscaler should be enabled
    And minAvailable should be set in PodDisruptionBudget

  @AT-E1-002 @networking
  Scenario: Test ingress route with echo server
    Given nginx-ingress is deployed on AKS
    And I have deployed a test echo server
    When I create an ingress resource for the echo server
    And I curl the ingress URL
    Then the request should succeed with 200 status
    And the response should contain echo server content

  @AT-E1-002 @dns @optional
  Scenario: Configure Azure DNS zone
    Given I have a custom domain for the platform
    And I have configured dns_zone_name variable in Terraform
    When I run "terraform apply" in infra/azure
    Then an Azure DNS zone should be created
    And the DNS zone should contain nameservers
    And the nameservers should be output for delegation

  @AT-E1-002 @dns @optional
  Scenario: Create DNS records for ingress
    Given I have an Azure DNS zone configured
    And ingress-nginx has a public IP assigned
    And I have set create_dns_records to true
    When I run "terraform apply" in infra/azure
    Then an A record should be created for the root domain
    And a wildcard A record should be created for "*.fawkes.domain"
    And the A records should point to the ingress public IP

  @AT-E1-002 @security @certificates
  Scenario: Deploy cert-manager
    Given I am in the repository root directory
    When I apply the cert-manager ArgoCD Application
    Then the ArgoCD Application "cert-manager" should be created
    And the cert-manager namespace should exist
    And all cert-manager deployments should be running
    And cert-manager CRDs should be installed

  @AT-E1-002 @security @certificates
  Scenario: Configure Let's Encrypt ClusterIssuers
    Given cert-manager is deployed
    When I apply the ClusterIssuer configurations
    Then the "letsencrypt-staging" ClusterIssuer should be created
    And the "letsencrypt-prod" ClusterIssuer should be created
    And both ClusterIssuers should be in Ready state

  @AT-E1-002 @security @certificates
  Scenario: Request certificate with HTTP-01 challenge
    Given cert-manager is deployed with ClusterIssuers
    And nginx-ingress is deployed
    When I create a Certificate resource with letsencrypt-staging issuer
    Then a CertificateRequest should be created
    And an Order should be created
    And HTTP-01 challenges should be created
    And the certificate should be issued successfully
    And a TLS secret should be created

  @AT-E1-002 @security @certificates @optional
  Scenario: Configure Azure DNS challenge for wildcard certificates
    Given cert-manager is deployed
    And Azure DNS zone is configured
    And Azure Workload Identity is configured
    When I apply the Azure DNS ClusterIssuer
    Then the "letsencrypt-dns-azure" ClusterIssuer should be created
    And the ClusterIssuer should be in Ready state

  @AT-E1-002 @security @certificates @optional
  Scenario: Request wildcard certificate with DNS-01 challenge
    Given cert-manager with Azure DNS issuer is configured
    When I create a Certificate resource for "*.fawkes.domain"
    Then a CertificateRequest should be created
    And DNS-01 challenges should be created
    And DNS TXT records should be created in Azure DNS
    And the wildcard certificate should be issued successfully

  @AT-E1-002 @integration
  Scenario: Deploy service with automatic TLS certificate
    Given nginx-ingress is deployed
    And cert-manager with ClusterIssuers is configured
    When I create an Ingress with cert-manager annotation
    Then cert-manager should automatically create a Certificate
    And the certificate should be issued
    And the Ingress should use the TLS secret
    And HTTPS access should work

  @AT-E1-002 @monitoring
  Scenario: Monitor certificate expiration
    Given cert-manager is deployed with certificates
    When I query Prometheus metrics
    Then certificate expiration metrics should be available
    And certificate ready status should be available
    And alerts should be configured for expiring certificates

  @AT-E1-002 @validation
  Scenario: Run validation scripts
    Given nginx-ingress is deployed on AKS
    When I run the ingress-nginx validation script
    Then the validation should pass all checks
    When I run the cert-manager validation script
    Then the validation should pass all checks

  @AT-E1-002 @cost-optimization
  Scenario: Verify resource limits are appropriate
    Given nginx-ingress is deployed on AKS
    When I check the resource requests and limits
    Then CPU requests should be set appropriately for Azure
    And memory requests should be set appropriately for Azure
    And the configuration should support auto-scaling

  @AT-E1-002 @disaster-recovery
  Scenario: Verify certificate backup and recovery
    Given cert-manager is deployed with certificates
    When I check the certificate secrets
    Then all TLS secrets should be stored in Kubernetes
    And ACME account keys should be stored securely
    And certificates should auto-renew before expiration
