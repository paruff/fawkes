Feature: Security Plane - Image Signing
  As a security engineer
  I want to cryptographically sign all container images
  So that we can verify image authenticity and integrity

  Background:
    Given the Fawkes Security Plane is configured
    And Cosign is installed
    And keyless signing with OIDC is enabled

  @security @signing @local
  Scenario: Sign container image with Cosign
    Given a container image "test-app:v1.0.0"
    When the image signing workflow is triggered
    Then the image should be signed with Cosign
    And the signature should use keyless OIDC authentication
    And the signature should be stored in the registry

  @security @signing @local
  Scenario: Verify signed image
    Given a container image has been signed
    When I verify the signature with Cosign
    Then the signature verification should succeed
    And the OIDC identity should be validated
    And the certificate chain should be verified

  @security @signing
  Scenario: Sign SBOM attestation
    Given a container image with an SBOM
    When the image signing workflow is triggered with SBOM attestation
    Then the image should be signed
    And an SBOM attestation should be created
    And the attestation should be signed
    And both signatures should be verifiable

  @security @signing
  Scenario: Fail on unsigned images in production
    Given enforcement mode is "strict"
    And an unsigned container image
    When a deployment to production is attempted
    Then the deployment should be blocked
    And an error message should indicate missing signature

  @security @signing @integration
  Scenario: Sign multiple images in workflow
    Given multiple container images: "app:v1", "worker:v1", "cron:v1"
    When the batch signing workflow is triggered
    Then all images should be signed
    And all signatures should be verifiable
    And a signing summary should be generated
