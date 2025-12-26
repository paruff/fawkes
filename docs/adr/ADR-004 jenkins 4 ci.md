# ADR-004: Jenkins for CI/CD

## Status

**Accepted** - October 8, 2025

## Context

Fawkes requires a Continuous Integration and Continuous Delivery (CI/CD) platform to automate building, testing, securing, and packaging applications. CI/CD is foundational to achieving elite DORA performance, particularly for deployment frequency and lead time for changes.

### The Need for CI/CD Automation

**Current Challenges Without CI/CD**:

- **Manual Builds**: Error-prone, time-consuming, not repeatable
- **Inconsistent Testing**: Tests run locally (or not at all), vary by developer
- **Security Gaps**: No automated security scanning, vulnerabilities reach production
- **Slow Feedback**: Developers wait hours/days to know if changes work
- **Deployment Bottlenecks**: Manual packaging and deployment slow delivery
- **No Audit Trail**: Can't trace which code produced which artifact

**What CI/CD Provides**:

1. **Automated Builds**: Code commit triggers automatic build and test
2. **Quality Gates**: Automated testing, linting, security scanning block bad code
3. **Fast Feedback**: Developers know within minutes if changes work
4. **Consistent Process**: Same build/test process every time, regardless of developer
5. **Security Integration**: Automated SAST, dependency scanning, container scanning
6. **Artifact Management**: Versioned, immutable build artifacts
7. **Deployment Trigger**: Successful builds trigger GitOps deployment
8. **Audit Trail**: Complete record of what was built, when, and by whom

### Requirements for CI/CD Platform

**Core Requirements**:

- **Pipeline as Code**: Jenkinsfiles in Git, version controlled
- **Kubernetes Native**: Dynamic agents in Kubernetes pods
- **Golden Paths**: Reusable pipeline templates for common scenarios
- **Security Scanning**: Integration with SonarQube, Trivy, dependency checkers
- **Multi-Language**: Support Java, Python, Node.js, Go, and more
- **Extensible**: Plugin ecosystem for integrations
- **GitOps Integration**: Trigger ArgoCD deployments
- **DORA Metrics**: Report build/deployment events

**DORA Alignment**:

- **Deployment Frequency**: Automated pipelines enable frequent deployments
- **Lead Time**: Fast builds reduce time from commit to production
- **Change Failure Rate**: Quality gates catch issues before deployment
- **Time to Restore**: Fast pipelines enable quick hotfix deployment

**Integration Requirements**:

- **GitHub**: Webhook triggers, status checks
- **ArgoCD**: Trigger GitOps sync after successful build
- **SonarQube**: Code quality and security analysis
- **Trivy**: Container image scanning
- **Harbor/ECR**: Push container images
- **Mattermost**: Build notifications
- **Backstage**: Show pipeline status in developer portal
- **DORA Metrics Service**: Report build events

### Forces at Play

**Technical Forces**:

- Need pipeline-as-code for version control and review
- Kubernetes-native approach reduces infrastructure overhead
- Security scanning must be automated and enforced
- Multi-language support critical for polyglot teams

**Developer Experience Forces**:

- Fast feedback loops improve developer productivity
- Clear error messages reduce debugging time
- Consistent builds reduce "works on my machine" issues
- Self-service pipelines reduce dependency on platform team

**Operational Forces**:

- Platform team can't manually build everything
- Need scalability (100+ concurrent builds)
- Resource efficiency matters (cost optimization)
- Maintenance burden should be minimized

**Enterprise Forces**:

- Many enterprises already use Jenkins
- Familiarity reduces adoption friction
- Extensive plugin ecosystem meets diverse needs
- Proven at massive scale

## Decision

**We will use Jenkins with Kubernetes plugin as the CI/CD platform for Fawkes.**

Specifically:

- **Jenkins LTS** (Long-Term Support, latest stable)
- **Kubernetes Plugin** for dynamic agent provisioning
- **Configuration as Code (JCasC)** for declarative Jenkins setup
- **Shared Pipeline Libraries** for golden path reusability
- **Pipeline-as-Code** (Jenkinsfile in every repository)
- **Security Scanning Integration** (SonarQube, Trivy, OWASP Dependency-Check)
- **GitOps Integration** (trigger ArgoCD after successful builds)

### Rationale

1. **Industry Standard**: Jenkins is the most widely adopted CI/CD tool, with 20+ years of development, used by 70%+ of enterprises

2. **Kubernetes Native**: Jenkins Kubernetes plugin provides:

   - Dynamic agent provisioning (pods created on-demand)
   - Isolated build environments (each build in separate pod)
   - Resource efficiency (agents destroyed after build)
   - Scalability (limited only by cluster capacity)
   - Cost optimization (only pay for active builds)

3. **Pipeline as Code**: Jenkinsfile DSL enables:

   - Version-controlled pipelines
   - Code review of pipeline changes
   - Reusable shared libraries
   - Declarative and scripted syntax options
   - Mature, battle-tested

4. **Massive Plugin Ecosystem**: 1,800+ plugins covering:

   - SCM: GitHub, GitLab, Bitbucket
   - Build tools: Maven, Gradle, npm, pip
   - Quality: SonarQube, Checkstyle, PMD
   - Security: Trivy, OWASP, git-secrets
   - Deployment: Kubernetes, ArgoCD, Spinnaker
   - Notifications: Mattermost, email, Slack

5. **Configuration as Code (JCasC)**:

   - Declarative YAML configuration
   - Version controlled in Git
   - Reproducible Jenkins setup
   - No manual UI configuration
   - Easy disaster recovery

6. **Proven at Scale**: Used by massive organizations:

   - Netflix (2,000+ builds/day)
   - CloudBees customers (enterprise scale)
   - Thousands of open source projects
   - Can handle 100+ concurrent builds easily

7. **Shared Libraries**: Reusable pipeline code:

   - DRY principle for pipelines
   - Golden path templates
   - Consistent build patterns
   - Centralized updates (change once, apply everywhere)

8. **Enterprise Features Available**:

   - RBAC and folder-based security
   - Audit logging
   - Blue Ocean UI (modern interface)
   - Pipeline visualization
   - Extensive reporting

9. **Strong Community**:

   - Active development (monthly releases)
   - Large user community
   - Extensive documentation
   - Many tutorials and examples
   - Commercial support available (CloudBees)

10. **Backstage Integration**: Official Jenkins plugin shows:

    - Build status and history
    - Console logs
    - Test results
    - Direct links to Jenkins

11. **Familiarity**: Most developers have used Jenkins:

    - Reduces learning curve
    - Easier contributor onboarding
    - Extensive knowledge base (Stack Overflow, blogs)

12. **Cost Effective**:
    - Open source (free)
    - Only infrastructure costs
    - Commercial support optional (CloudBees)

## Consequences

### Positive

✅ **Automated Quality Gates**: Every commit tested, scanned, and validated before deployment

✅ **Fast Feedback**: Developers get results in 5-10 minutes, not hours

✅ **Golden Paths**: Shared libraries provide consistent, best-practice pipelines

✅ **Security Integration**: SAST, dependency scanning, container scanning automated

✅ **Resource Efficiency**: Dynamic Kubernetes agents scale up/down based on load

✅ **Pipeline as Code**: Jenkinsfiles version-controlled, reviewed, and testable

✅ **Extensive Integrations**: 1,800+ plugins cover virtually any tool

✅ **Proven Reliability**: Battle-tested at enterprise scale for 15+ years

✅ **Developer Self-Service**: Teams create/modify pipelines without platform team

✅ **DORA Metrics**: Build events feed into deployment frequency and lead time calculations

✅ **Familiarity**: Developers already know Jenkins, reducing onboarding time

✅ **Cost Effective**: Open source with no licensing fees

### Negative

⚠️ **UI Complexity**: Traditional Jenkins UI dated, can be overwhelming (Blue Ocean helps)

⚠️ **Plugin Management**: Keeping plugins updated requires ongoing effort

⚠️ **Groovy DSL**: Jenkinsfile syntax (Groovy) has learning curve

⚠️ **Resource Usage**: Jenkins controller requires ~2GB RAM minimum

⚠️ **Security Concerns**: Jenkins has had security vulnerabilities (requires updates)

⚠️ **Configuration Complexity**: Advanced pipelines can become complex

⚠️ **Legacy Baggage**: 15+ years of features means some cruft

⚠️ **Agent Configuration**: Setting up Kubernetes plugin requires careful configuration

⚠️ **Maintenance**: Jenkins and plugins need regular updates

### Neutral

◽ **Alternative Modern Tools Exist**: GitHub Actions, GitLab CI, Tekton are simpler but less feature-rich

◽ **Blue Ocean**: Modern UI available but not default

◽ **CloudBees**: Commercial support available if needed

### Mitigation Strategies

1. **UI Complexity**:

   - Use Blue Ocean for modern UI
   - Standardize on pipeline-as-code (minimize UI usage)
   - Create clear documentation and screenshots
   - Consider Backstage as primary interface (show status there)

2. **Plugin Management**:

   - Use dependabot or similar for plugin updates
   - Test updates in staging before production
   - Limit plugin count to essential ones
   - Document which plugins are used and why

3. **Groovy DSL Learning Curve**:

   - Provide Jenkinsfile templates for common scenarios
   - Create shared library with high-level abstractions
   - Include examples and comments in templates
   - Run workshops for developers

4. **Security**:

   - Subscribe to Jenkins security advisories
   - Automate Jenkins updates (test first)
   - Use RBAC to limit permissions
   - Regular security audits
   - Keep plugins updated

5. **Configuration**:

   - Use JCasC for all configuration
   - Store configuration in Git
   - Use Infrastructure as Code for Jenkins deployment
   - Document configuration decisions

6. **Kubernetes Plugin**:
   - Start with simple pod templates
   - Create library of pod templates for common scenarios
   - Document resource limits and requests
   - Monitor agent performance

## Alternatives Considered

### Alternative 1: GitHub Actions

**Pros**:

- Native GitHub integration (no webhooks)
- YAML-based, simple syntax
- Matrix builds for testing multiple versions
- Large marketplace of actions
- Free for public repos, generous limits
- Modern, fast, cloud-native

**Cons**:

- **GitHub Lock-In**: Only works with GitHub
- **Limited Self-Hosting**: Self-hosted runners less mature than Jenkins
- **Cost**: Expensive for private repos at scale ($0.008/minute, adds up)
- **Less Flexible**: More opinionated than Jenkins
- **Smaller Plugin Ecosystem**: Fewer actions than Jenkins plugins
- **No Shared Libraries**: Harder to share pipeline code across repos
- **Limited RBAC**: Access control less granular

**Reason for Rejection**: While excellent for GitHub-centric projects, GitHub Actions creates vendor lock-in. Cost at scale significant (100 builds/day × 10 min × $0.008 = $240/month, $2,880/year just for CI). Self-hosted runners less mature than Jenkins Kubernetes agents. May use for Fawkes repo itself but not as platform-wide CI solution.

### Alternative 2: GitLab CI

**Pros**:

- Native GitLab integration
- YAML-based pipelines
- Built-in container registry
- Auto DevOps features
- Good UI and UX
- Free tier generous

**Cons**:

- **GitLab Required**: We use GitHub, not GitLab
- **Migration Overhead**: Would need to migrate or mirror repos
- **Less Flexible**: More opinionated than Jenkins
- **Smaller Ecosystem**: Fewer integrations than Jenkins
- **Learning Curve**: Teams would need to learn new tool

**Reason for Rejection**: GitLab CI excellent if using GitLab, but we use GitHub. Migrating repos or maintaining mirrors adds complexity without clear benefit. Jenkins works with any Git provider.

### Alternative 3: Tekton Pipelines

**Pros**:

- Kubernetes-native (CRDs)
- Cloud-native, modern architecture
- Pipeline-as-code (YAML)
- CNCF project (good governance)
- Growing adoption
- True cloud-native approach

**Cons**:

- **Immature**: Newer project, less proven at scale
- **Steeper Learning Curve**: CRDs and Tasks/Pipelines concepts unfamiliar
- **No UI**: Requires separate UI (Tekton Dashboard basic)
- **Smaller Ecosystem**: Fewer pre-built Tasks than Jenkins plugins
- **Limited Shared Libraries**: Harder to share pipeline code
- **Complex Setup**: More moving parts than Jenkins
- **Debugging Harder**: Kubernetes-native means more abstraction

**Reason for Rejection**: Tekton philosophically appealing (cloud-native) but less mature and harder to use. Jenkins provides 80% of benefits with 20% of complexity. May revisit Tekton in 2-3 years when more mature and ecosystem richer.

### Alternative 4: CircleCI (SaaS)

**Pros**:

- Fast builds (optimized infrastructure)
- Good UI and developer experience
- Docker-first approach
- Orbs (reusable config)
- Free tier available
- Popular with startups

**Cons**:

- **SaaS Only**: No self-hosted option (CircleCI Server discontinued)
- **Cost**: $15-60/user/month depending on tier (expensive at scale)
- **Vendor Lock-In**: Proprietary platform
- **Limited Control**: Can't customize deeply
- **Data on CircleCI Servers**: Security/compliance concerns

**Reason for Rejection**: SaaS-only and proprietary conflicts with self-hosted open source values. Cost at 100 developers: $18,000-$72,000/year. Cannot customize to our exact needs.

### Alternative 5: Drone CI

**Pros**:

- Open source and self-hosted
- Container-native (Docker)
- YAML-based pipelines
- Lightweight
- Easy to set up
- Good GitHub integration

**Cons**:

- **Smaller Community**: Much smaller than Jenkins
- **Limited Plugins**: Fewer integrations than Jenkins
- **Less Mature**: Newer, less battle-tested
- **Uncertain Future**: Development pace variable
- **Limited Enterprise Features**: RBAC, audit logging less robust
- **Smaller Ecosystem**: Fewer shared pipelines

**Reason for Rejection**: While simpler than Jenkins, Drone's smaller community and ecosystem are concerns. Jenkins' maturity and plugin ecosystem provide more value. Drone good for simple use cases but Fawkes needs comprehensive CI solution.

### Alternative 6: Concourse CI

**Pros**:

- Pipeline-as-code (YAML)
- Resource-based model (interesting approach)
- Reproducible builds
- Open source
- Kubernetes support

**Cons**:

- **Steep Learning Curve**: Resource model unintuitive
- **Small Community**: Very small compared to Jenkins
- **Limited Plugins**: Minimal ecosystem
- **Complex Setup**: Many components to deploy
- **No UI for Configuration**: All YAML, no web UI
- **Limited Adoption**: Few large organizations use it

**Reason for Rejection**: Concourse's resource-based model interesting but unintuitive. Very small community and ecosystem. Learning curve not justified by benefits over Jenkins.

### Alternative 7: Spinnaker

**Pros**:

- Continuous delivery focus
- Multi-cloud native
- Advanced deployment strategies
- Netflix-proven

**Cons**:

- **Not CI Tool**: Continuous delivery only, not continuous integration
- **Very Complex**: Difficult to set up and maintain
- **Resource Heavy**: 10+ microservices, high overhead
- **Overkill**: More than we need

**Reason for Rejection**: Spinnaker is CD tool, not CI. We need CI/CD together. Spinnaker's complexity unjustified. Using Jenkins (CI) + ArgoCD (CD) cleaner separation of concerns.

## Related Decisions

- **ADR-001**: Kubernetes (Jenkins uses Kubernetes plugin for agents)
- **ADR-002**: Backstage (Jenkins plugin shows build status)
- **ADR-003**: ArgoCD (Jenkins triggers ArgoCD deployments)
- **ADR-007**: Mattermost (Jenkins sends build notifications)
- **Future ADR**: Shared Pipeline Library Structure
- **Future ADR**: Build Caching Strategy

## Implementation Notes

### Deployment Architecture

```yaml
# Jenkins Deployment
jenkins:
  namespace: fawkes-ci

  components:
    - jenkins-controller:
        image: jenkins/jenkins:lts
        replicas: 1 (stateful, uses persistent volume)
        resources:
          cpu: 2 cores
          memory: 4Gi
        storage: 50Gi (PVC for Jenkins home)

    - jenkins-agents:
        dynamic: true (Kubernetes plugin creates on-demand)
        pod-templates:
          - maven-agent:
              resources:
                cpu: 1 core
                memory: 2Gi
          - node-agent:
              resources:
                cpu: 1 core
                memory: 1Gi
          - python-agent:
              resources:
                cpu: 1 core
                memory: 1Gi
          - docker-agent:
              resources:
                cpu: 2 cores
                memory: 4Gi

  integrations:
    - github (webhooks, status checks)
    - sonarqube (code quality scanning)
    - trivy (container scanning)
    - argocd (deployment triggering)
    - mattermost (notifications)
    - backstage (build status plugin)
    - harbor (container registry)
    - dora-metrics-service (build events)
```

### Configuration as Code (JCasC)

```yaml
# jenkins-casc.yaml
jenkins:
  systemMessage: "Fawkes Platform CI/CD"
  numExecutors: 0 # Use Kubernetes agents only

  securityRealm:
    github:
      githubWebUri: "https://github.com"
      clientID: "${GITHUB_CLIENT_ID}"
      clientSecret: "${GITHUB_CLIENT_SECRET}"

  authorizationStrategy:
    globalMatrix:
      permissions:
        - "Overall/Administer:admin"
        - "Overall/Read:authenticated"
        - "Job/Build:authenticated"
        - "Job/Cancel:authenticated"

  clouds:
    - kubernetes:
        name: "kubernetes"
        serverUrl: "https://kubernetes.default"
        namespace: "fawkes-ci"
        jenkinsUrl: "http://jenkins:8080"
        jenkinsTunnel: "jenkins-agent:50000"
        templates:
          - name: "maven"
            label: "maven"
            containers:
              - name: "maven"
                image: "maven:3.8-openjdk-17"
                command: "/bin/sh -c"
                args: "cat"
                ttyEnabled: true
                resourceRequestCpu: "1"
                resourceRequestMemory: "2Gi"
                resourceLimitCpu: "2"
                resourceLimitMemory: "4Gi"

unclassified:
  globalLibraries:
    libraries:
      - name: "fawkes-pipeline-library"
        retriever:
          modernSCM:
            scm:
              git:
                remote: "https://github.com/paruff/fawkes-pipeline-library"
                credentialsId: "github-token"
```

### Shared Pipeline Library Structure

```
fawkes-pipeline-library/
├── vars/
│   ├── mavenPipeline.groovy
│   ├── nodePipeline.groovy
│   ├── pythonPipeline.groovy
│   ├── dockerBuild.groovy
│   ├── securityScan.groovy
│   └── deployToArgoCD.groovy
├── src/
│   └── com/
│       └── fawkes/
│           ├── Build.groovy
│           ├── Test.groovy
│           ├── Security.groovy
│           └── Deploy.groovy
└── resources/
    └── pod-templates/
        ├── maven.yaml
        ├── node.yaml
        └── python.yaml
```

### Golden Path Jenkinsfile Examples

**Java Spring Boot**:

```groovy
@Library('fawkes-pipeline-library') _

mavenPipeline {
    sonarQubeProject = 'my-service'
    dockerImage = 'my-service'
    argocdApp = 'my-service-dev'
    notifyChannel = 'team-builds'
}
```

**Python FastAPI**:

```groovy
@Library('fawkes-pipeline-library') _

pythonPipeline {
    pythonVersion = '3.11'
    testCommand = 'pytest --cov=src tests/'
    dockerImage = 'my-python-service'
    argocdApp = 'my-python-service-dev'
}
```

**Node.js Express**:

```groovy
@Library('fawkes-pipeline-library') _

nodePipeline {
    nodeVersion = '18'
    buildCommand = 'npm run build'
    testCommand = 'npm test'
    dockerImage = 'my-node-service'
    argocdApp = 'my-node-service-dev'
}
```

### Complete Pipeline Example (Without Library)

```groovy
pipeline {
    agent {
        kubernetes {
            yaml """
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: maven
    image: maven:3.8-openjdk-17
    command: ['cat']
    tty: true
  - name: docker
    image: docker:latest
    command: ['cat']
    tty: true
    volumeMounts:
    - name: docker-sock
      mountPath: /var/run/docker.sock
  - name: trivy
    image: aquasec/trivy:latest
    command: ['cat']
    tty: true
  volumes:
  - name: docker-sock
    hostPath:
      path: /var/run/docker.sock
"""
        }
    }

    environment {
        DOCKER_REGISTRY = 'harbor.fawkes.io'
        IMAGE_NAME = "${DOCKER_REGISTRY}/myapp/myservice"
        IMAGE_TAG = "${env.GIT_COMMIT.take(7)}"
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build') {
            steps {
                container('maven') {
                    sh 'mvn clean package -DskipTests'
                }
            }
        }

        stage('Test') {
            steps {
                container('maven') {
                    sh 'mvn test'
                }
            }
            post {
                always {
                    junit 'target/surefire-reports/*.xml'
                }
            }
        }

        stage('SonarQube Analysis') {
            steps {
                container('maven') {
                    withSonarQubeEnv('SonarQube') {
                        sh 'mvn sonar:sonar'
                    }
                }
            }
        }

        stage('Quality Gate') {
            steps {
                timeout(time: 5, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                container('docker') {
                    sh """
                        docker build -t ${IMAGE_NAME}:${IMAGE_TAG} .
                        docker tag ${IMAGE_NAME}:${IMAGE_TAG} ${IMAGE_NAME}:latest
                    """
                }
            }
        }

        stage('Security Scan') {
            steps {
                container('trivy') {
                    sh """
                        trivy image --severity HIGH,CRITICAL --exit-code 1 ${IMAGE_NAME}:${IMAGE_TAG}
                    """
                }
            }
        }

        stage('Push Image') {
            steps {
                container('docker') {
                    withCredentials([usernamePassword(credentialsId: 'harbor-credentials',
                                                     usernameVariable: 'USER',
                                                     passwordVariable: 'PASS')]) {
                        sh """
                            echo \$PASS | docker login ${DOCKER_REGISTRY} -u \$USER --password-stdin
                            docker push ${IMAGE_NAME}:${IMAGE_TAG}
                            docker push ${IMAGE_NAME}:latest
                        """
                    }
                }
            }
        }

        stage('Update GitOps') {
            steps {
                script {
                    // Update image tag in GitOps repository
                    sh """
                        git clone https://github.com/paruff/fawkes-gitops.git
                        cd fawkes-gitops
                        sed -i 's|image: .*|image: ${IMAGE_NAME}:${IMAGE_TAG}|' apps/dev/myservice/deployment.yaml
                        git add apps/dev/myservice/deployment.yaml
                        git commit -m "Update myservice to ${IMAGE_TAG}"
                        git push
                    """
                }
            }
        }

        stage('Notify DORA Service') {
            steps {
                script {
                    sh """
                        curl -X POST https://dora-metrics.fawkes.io/webhook/build \\
                          -H 'Content-Type: application/json' \\
                          -d '{
                            "service": "myservice",
                            "commit": "${env.GIT_COMMIT}",
                            "buildNumber": "${env.BUILD_NUMBER}",
                            "status": "SUCCESS",
                            "duration": "${currentBuild.duration}",
                            "timestamp": "${new Date().format('yyyy-MM-dd HH:mm:ss')}"
                          }'
                    """
                }
            }
        }
    }

    post {
        success {
            mattermostSend(
                channel: 'team-builds',
                color: 'good',
                message: "✅ Build #${env.BUILD_NUMBER} succeeded for ${env.JOB_NAME}\nCommit: ${env.GIT_COMMIT.take(7)}\nDuration: ${currentBuild.durationString}"
            )
        }
        failure {
            mattermostSend(
                channel: 'team-builds',
                color: 'danger',
                message: "❌ Build #${env.BUILD_NUMBER} failed for ${env.JOB_NAME}\nCommit: ${env.GIT_COMMIT.take(7)}"
            )
        }
    }
}
```

### Plugin List (Essential)

**Core Plugins**:

- Kubernetes Plugin (dynamic agents)
- Pipeline Plugin (Jenkinsfile support)
- Git Plugin (Git integration)
- GitHub Plugin (GitHub webhooks)
- Credentials Plugin (secret management)
- Configuration as Code Plugin (JCasC)

**Quality & Security**:

- SonarQube Scanner Plugin
- Warnings Next Generation Plugin
- JUnit Plugin
- Code Coverage Plugin

**Build Tools**:

- Maven Integration Plugin
- NodeJS Plugin
- Python Plugin
- Docker Plugin

**Deployment**:

- Kubernetes CLI Plugin
- HTTP Request Plugin (ArgoCD API)

**Notifications**:

- Mattermost Plugin
- Email Extension Plugin

**UI**:

- Blue Ocean Plugin (modern UI)
- Dashboard View Plugin

### Monitoring & Observability

**Prometheus Metrics** (via Jenkins Prometheus plugin):

- jenkins_builds_total
- jenkins_builds_duration_seconds
- jenkins_queue_size
- jenkins_node_online_total
- jenkins_job_success_rate

**Grafana Dashboard**:

- Build success/failure rates
- Build duration trends (P50, P95, P99)
- Queue size over time
- Agent utilization
- Plugin health

**Alerts**:

- Build queue >10 for >15 minutes
- Build failure rate >20% (rolling 24h)
- Jenkins controller down >5 minutes
- Disk space <20%

### Backup & Disaster Recovery

**Backup Strategy**:

- Jenkins configuration in Git (JCasC)
- Persistent volume snapshots (daily)
- Plugin list documented
- Job configurations in Git (Jenkinsfile per repo)

**Recovery**:

1. Redeploy Jenkins from Helm + JCasC
2. Restore persistent volume from snapshot (job history)
3. Plugins auto-installed via JCasC
4. Jobs auto-discovered from GitHub organizations

**RTO**: <4 hours
**RPO**: <24 hours

### Performance Optimization

**Build Caching**:

- Maven local repository cache (PV)
- npm cache (PV)
- Docker layer caching
- Workspace caching for reuse

**Agent Optimization**:

- Right-size agent resources
- Use pod templates with pre-pulled images
- Implement build timeouts
- Limit concurrent builds per agent

**Controller Optimization**:

- Increase heap size for large installations
- Use separate build agents (don't build on controller)
- Regular cleanup of old builds
- Archive artifacts externally (S3/MinIO)

## Monitoring This Decision

We will revisit this ADR if:

- Jenkins development significantly slows or stops
- A cloud-native alternative (Tekton, Dagger) becomes significantly more mature
- Operational burden (updates, plugins) exceeds benefits
- GitHub Actions or GitLab CI costs become competitive with self-hosted
- Team strongly prefers different CI tool
- Security concerns cannot be adequately addressed

**Next Review Date**: April 8, 2026 (6 months)

## References

- [Jenkins Official Documentation](https://www.jenkins.io/doc/)
- [Jenkins Kubernetes Plugin](https://plugins.jenkins.io/kubernetes/)
- [Configuration as Code Plugin](https://github.com/jenkinsci/configuration-as-code-plugin)
- [Jenkins Pipeline Documentation](https://www.jenkins.io/doc/book/pipeline/)
- [Shared Libraries Documentation](https://www.jenkins.io/doc/book/pipeline/shared-libraries/)
- [Jenkins Helm Chart](https://github.com/jenkinsci/helm-charts)

## Notes

### Why Not GitHub Actions?

Most common question: "Why not just use GitHub Actions?"

**GitHub Actions excellent for**:

- GitHub-hosted open source projects
- Simple CI workflows
- GitHub-centric organizations

**Jenkins better for Fawkes because**:

- **Vendor neutral**: Works with any Git provider
- **Self-hosted first**: True control, no SaaS lock-in
- **More flexible**: Less opinionated, more customizable
- **Shared libraries**: Better code reuse across pipelines
- **Enterprise features**: RBAC, audit logging more mature
- **Cost at scale**: Free except infrastructure vs. GitHub's per-minute pricing

Can use both: GitHub Actions for Fawkes repo itself, Jenkins for platform users.

### Jenkins Security Best Practices

1. **Keep Updated**: Subscribe to security advisories, apply patches promptly
2. **Minimize Plugins**: Only install necessary plugins
3. **Use RBAC**: Least privilege access model
4. **Secrets Management**: Use Credentials Plugin, not hardcoded secrets
5. **Network Segmentation**: Restrict Jenkins network access
6. **Audit Logging**: Enable and monitor audit logs
7. **CSRF Protection**: Enable CSRF tokens
8. **Content Security Policy**: Configure CSP headers

### Kubernetes Plugin Configuration Tips

1. **Resource Limits**: Always set limits and requests
2. **Service Account**: Use dedicated service account with minimal permissions
3. **Network Policies**: Restrict agent network access
4. **Image Pull Policy**: Use IfNotPresent to reduce registry load
5. **Pod Templates**: Create library of reusable templates
6. **Timeouts**: Set appropriate pod and container timeouts
7. **Cleanup**: Configure automatic pod deletion after build

---

**Decision Made By**: Platform Architecture Team
**Approved By**: Project Lead
**Date**: October 8, 2025
**Author**: [Platform Architect Name]
**Last Updated**: October 8, 2025
