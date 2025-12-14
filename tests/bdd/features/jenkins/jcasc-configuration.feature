@jenkins @jcasc @issue-15
Feature: Jenkins Configuration as Code (JCasC)
  As a platform engineer
  I want Jenkins configured via JCasC
  So that configuration is reproducible and version-controlled

  Background:
    Given the Fawkes platform namespace exists
    And Jenkins is deployed via ArgoCD
    And Jenkins pod is running and ready

  @configuration @smoke
  Scenario: JCasC plugin is installed and enabled
    Given Jenkins is accessible
    When I check the installed plugins
    Then the "configuration-as-code" plugin should be installed
    And the plugin version should be "latest" or a specific version

  @configuration @core
  Scenario: Core Jenkins configuration is applied via JCasC
    Given Jenkins is configured with JCasC
    When I check the Jenkins system configuration
    Then the system message should be "Fawkes CI/CD Platform - Golden Path Enabled"
    And the number of executors on controller should be 0
    And Jenkins mode should be "NORMAL"

  @configuration @kubernetes
  Scenario: Kubernetes cloud is configured via JCasC
    Given Jenkins has JCasC configuration loaded
    When I check the cloud configuration
    Then a Kubernetes cloud named "kubernetes" should exist
    And the Kubernetes cloud namespace should be "fawkes"
    And the Jenkins URL should be "http://jenkins:8080"
    And the Jenkins tunnel should be "jenkins-agent:50000"
    And the container capacity should be 20

  @configuration @agents
  Scenario: Agent templates are configured via JCasC
    Given Jenkins Kubernetes cloud is configured
    When I list all agent templates
    Then the following agent templates should exist:
      | template_name   | labels          |
      | jnlp-agent      | k8s-agent       |
      | maven-agent     | maven java      |
      | python-agent    | python          |
      | node-agent      | node nodejs     |
      | go-agent        | go golang       |

  @configuration @credentials
  Scenario: Credentials are configured via JCasC
    Given Jenkins is running with JCasC
    When I check the global credentials
    Then the following credential IDs should exist:
      | credential_id    | type              |
      | github-token     | Secret text       |
      | sonarqube-token  | Secret text       |
      | docker-registry  | Username/Password |
    And credentials should be sourced from environment variables
    And no credentials should be hardcoded in configuration

  @configuration @libraries
  Scenario: Global shared libraries are configured via JCasC
    Given Jenkins has JCasC enabled
    When I check the global library configuration
    Then a library named "fawkes-pipeline-library" should be configured
    And the library default version should be "main"
    And the library should be marked as implicit
    And the library should allow version override
    And the library should use GitHub repository "https://github.com/paruff/fawkes"
    And the library path should be "jenkins-shared-library"

  @configuration @security
  Scenario: Security realm is configured via JCasC
    Given Jenkins is deployed with JCasC
    When I check the security realm configuration
    Then local security realm should be enabled
    And user signup should be disabled
    And an admin user should be configured
    And admin password should be sourced from ADMIN_PASSWORD environment variable

  @configuration @authorization
  Scenario: Authorization strategy is configured via JCasC
    Given Jenkins security is configured via JCasC
    When I check the authorization strategy
    Then "loggedInUsersCanDoAnything" strategy should be enabled
    And anonymous read access should be disabled
    And authenticated users should have full access

  @configuration @tools
  Scenario: Tool installations are configured via JCasC
    Given Jenkins has tool configuration via JCasC
    When I check the configured tools
    Then Git should be configured with name "Default"
    And Maven should be configured with name "Maven 3.9"
    And Maven installer should use version "3.9.6"

  @configuration @integrations
  Scenario: SonarQube integration is configured via JCasC
    Given Jenkins is configured with JCasC
    When I check the SonarQube configuration
    Then a SonarQube installation named "SonarQube" should exist
    And the SonarQube server URL should be "http://sonarqube.fawkes.svc:9000"
    And the SonarQube credentials ID should be "sonarqube-token"
    And build wrapper should be enabled

  @configuration @notifications
  Scenario: Mattermost notification is configured via JCasC
    Given Jenkins has notification configuration
    When I check the Mattermost notifier settings
    Then Mattermost endpoint should be "http://mattermost.fawkes.svc:8065/hooks/jenkins"
    And the notification room should be "ci-builds"
    And the icon should be ":jenkins:"
    And build server URL should be "http://jenkins.127.0.0.1.nip.io"

  @configuration @reload
  Scenario: JCasC configuration can be reloaded without restart
    Given Jenkins is running with JCasC
    When I trigger a JCasC configuration reload
    Then the configuration should reload successfully
    And no errors should be present in the reload log
    And Jenkins should remain responsive

  @configuration @validation
  Scenario: JCasC configuration is valid YAML
    Given the JCasC configuration file exists
    When I validate the YAML syntax
    Then the YAML should be well-formed
    And there should be no syntax errors
    And all required sections should be present

  @configuration @secrets
  Scenario: Secrets are properly injected from Kubernetes
    Given Jenkins pod has environment variables configured
    When I check the environment variables
    Then ADMIN_PASSWORD should be set from jenkins-admin secret
    And GITHUB_TOKEN should be available if jenkins-credentials secret exists
    And SONARQUBE_TOKEN should be available if jenkins-credentials secret exists
    And secret values should not be visible in configuration exports

  @configuration @plugins
  Scenario: Required plugins for JCasC are installed
    Given Jenkins is deployed
    When I check the installed plugins
    Then the following plugins should be installed:
      | plugin_name                | purpose                    |
      | configuration-as-code      | JCasC core                 |
      | kubernetes                 | Kubernetes cloud           |
      | workflow-aggregator        | Pipeline support           |
      | credentials                | Credentials management     |
      | git                        | Git integration            |
      | github                     | GitHub integration         |
      | sonar                      | SonarQube integration      |
      | mattermost                 | Mattermost notifications   |

  @configuration @reproducibility
  Scenario: Jenkins configuration is reproducible
    Given Jenkins is configured via JCasC
    When I delete the Jenkins pod
    And wait for Jenkins to restart
    Then all configuration should be restored automatically
    And the system message should match the JCasC configuration
    And all agent templates should be recreated
    And all credentials should be available
    And all integrations should work

  @configuration @version-control
  Scenario: JCasC configuration is version controlled
    Given the Fawkes Git repository
    When I check the platform/apps/jenkins directory
    Then jcasc.yaml file should exist
    And the file should be tracked in Git
    And the file should have a Git history
    And changes should be documented in commit messages

  @configuration @documentation
  Scenario: JCasC configuration is documented
    Given the Jenkins configuration files
    When I review the jcasc.yaml file
    Then the file should have header comments explaining its purpose
    And each major section should have explanatory comments
    And required environment variables should be documented
    And plugin requirements should be documented

  @security @best-practices
  Scenario: JCasC follows security best practices
    Given Jenkins is configured with JCasC
    When I audit the security configuration
    Then no credentials should be hardcoded in jcasc.yaml
    And all sensitive values should use environment variable substitution
    And secrets should be stored in Kubernetes Secrets
    And script approval should be configured
    And anonymous access should be disabled

  @deployment @argocd
  Scenario: JCasC configuration is deployed via ArgoCD
    Given ArgoCD application for Jenkins exists
    When I check the ArgoCD sync status
    Then the jenkins application should be healthy
    And the sync status should be "Synced"
    And JCasC ConfigMap should be deployed
    And Jenkins pod should mount the JCasC configuration

  @monitoring @observability
  Scenario: JCasC configuration changes are observable
    Given Jenkins is running with JCasC
    When I change the jcasc.yaml configuration
    And sync the ArgoCD application
    Then I should be able to see the configuration change in Jenkins logs
    And JCasC should log successful configuration load
    And any configuration errors should be visible in logs
    And Prometheus metrics should reflect configuration status
