#!/usr/bin/env groovy
/**
 * Golden Path Pipeline for Fawkes Platform
 *
 * This shared library provides a standardized CI/CD pipeline that enforces
 * trunk-based development principles with mandatory security and quality gates.
 *
 * Usage in Jenkinsfile:
 * @Library('fawkes-pipeline-library') _
 * goldenPathPipeline {
 *     appName = 'my-service'
 *     language = 'java' // java, python, node, go
 *     dockerImage = 'my-org/my-service'
 *     notifyChannel = 'team-builds'
 * }
 *
 * @author Fawkes Platform Team
 */

def call(Map config = [:]) {
    // Default configuration with overrides
    def defaultConfig = [
        appName: env.JOB_BASE_NAME ?: 'unknown-app',
        language: 'java',
        dockerImage: '',
        dockerRegistry: env.DOCKER_REGISTRY ?: 'harbor.fawkes.local',
        notifyChannel: 'ci-builds',
        testCommand: '',
        bddTestCommand: '',
        buildCommand: '',
        sonarProject: '',
        trivySeverity: 'HIGH,CRITICAL',
        trivyExitCode: '1',
        deployToArgoCD: true,
        argocdApp: '',
        runBddTests: true,
        runSecurityScan: true,
        timeoutMinutes: 30
    ]

    // Merge user config with defaults
    config = defaultConfig + config

    // Set docker image if not provided
    if (!config.dockerImage) {
        config.dockerImage = "${config.dockerRegistry}/${config.appName}"
    }

    // Set ArgoCD app if not provided
    if (!config.argocdApp) {
        config.argocdApp = "${config.appName}-dev"
    }

    // Set SonarQube project if not provided
    if (!config.sonarProject) {
        config.sonarProject = config.appName
    }

    // Set language-specific defaults
    setLanguageDefaults(config)

    // Determine if this is a PR build or main branch build
    def isPR = env.CHANGE_ID != null
    def isMainBranch = env.BRANCH_NAME in ['main', 'master', 'trunk']

    pipeline {
        agent {
            kubernetes {
                yaml getPodTemplate(config.language)
            }
        }

        environment {
            IMAGE_TAG = "${env.GIT_COMMIT?.take(7) ?: 'latest'}"
            FULL_IMAGE = "${config.dockerImage}:${IMAGE_TAG}"
            DORA_METRICS_URL = "${env.DORA_METRICS_URL ?: 'http://dora-metrics.fawkes.svc:8080'}"
        }

        options {
            timeout(time: config.timeoutMinutes, unit: 'MINUTES')
            timestamps()
            buildDiscarder(logRotator(numToKeepStr: '10'))
            disableConcurrentBuilds()
        }

        stages {
            stage('Checkout') {
                steps {
                    checkout scm
                    script {
                        echo "Building ${config.appName} (${config.language})"
                        echo "Branch: ${env.BRANCH_NAME}, PR: ${env.CHANGE_ID ?: 'N/A'}"
                        echo "Commit: ${env.GIT_COMMIT}"
                    }
                }
            }

            stage('Build') {
                steps {
                    container(getContainerName(config.language)) {
                        script {
                            echo "Executing build stage..."
                            sh config.buildCommand
                        }
                    }
                }
            }

            stage('Unit Test') {
                steps {
                    container(getContainerName(config.language)) {
                        script {
                            echo "Executing unit tests..."
                            sh config.testCommand
                        }
                    }
                }
                post {
                    always {
                        publishTestResults(config.language)
                    }
                }
            }

            stage('BDD/Gherkin Test') {
                when {
                    expression { config.runBddTests && config.bddTestCommand }
                }
                steps {
                    container(getContainerName(config.language)) {
                        script {
                            echo "Executing BDD/Gherkin tests..."
                            sh config.bddTestCommand
                        }
                    }
                }
                post {
                    always {
                        publishBddResults(config.language)
                    }
                }
            }

            stage('Security Scan') {
                when {
                    expression { config.runSecurityScan }
                }
                stages {
                    stage('SonarQube Analysis') {
                        steps {
                            container(getContainerName(config.language)) {
                                script {
                                    withSonarQubeEnv('SonarQube') {
                                        runSonarScan(config)
                                    }
                                }
                            }
                        }
                    }

                    stage('Quality Gate') {
                        steps {
                            script {
                                // Wait for Quality Gate with detailed feedback
                                timeout(time: 5, unit: 'MINUTES') {
                                    def qg = waitForQualityGate()
                                    def sonarUrl = env.SONARQUBE_URL ?: 'http://sonarqube.fawkes.svc:9000'
                                    def projectKey = config.sonarProject ?: config.appName ?: 'unknown-project'
                                    def branchName = env.BRANCH_NAME ?: 'main'
                                    def reportUrl = "${sonarUrl}/dashboard?id=${projectKey}&branch=${branchName}"
                                    
                                    echo "=============================================="
                                    echo "SonarQube Quality Gate: ${qg.status}"
                                    echo "=============================================="
                                    echo "📊 View detailed analysis report:"
                                    echo "   ${reportUrl}"
                                    echo "=============================================="
                                    
                                    // Add link to build description for easy access
                                    currentBuild.description = (currentBuild.description ?: '') + 
                                        "\n<a href='${reportUrl}'>📊 SonarQube Report</a>"
                                    
                                    if (qg.status != 'OK') {
                                        def failureReason = """
❌ QUALITY GATE FAILED: ${qg.status}

The code changes did not meet the quality criteria.
Please review the SonarQube analysis for details:
${reportUrl}

Common failure reasons:
- New bugs or vulnerabilities introduced
- Code coverage dropped below threshold
- Duplicate code exceeded limit
- Security hotspots require review
"""
                                        echo failureReason
                                        error "Quality Gate failed: ${qg.status}. See: ${reportUrl}"
                                    }
                                    
                                    echo "✅ Quality Gate passed successfully!"
                                }
                            }
                        }
                    }

                    stage('Dependency Check') {
                        steps {
                            container(getContainerName(config.language)) {
                                script {
                                    runDependencyCheck(config)
                                }
                            }
                        }
                    }
                }
            }

            stage('Build Docker Image') {
                when {
                    expression { isMainBranch && !isPR }
                }
                steps {
                    container('docker') {
                        script {
                            echo "Building Docker image: ${FULL_IMAGE}"
                            sh """
                                docker build -t ${FULL_IMAGE} .
                                docker tag ${FULL_IMAGE} ${config.dockerImage}:latest
                            """
                        }
                    }
                }
            }

            stage('Container Security Scan') {
                when {
                    expression { isMainBranch && !isPR && config.runSecurityScan }
                }
                steps {
                    container('trivy') {
                        script {
                            echo "Scanning container image with Trivy..."
                            sh """
                                trivy image \
                                    --severity ${config.trivySeverity} \
                                    --exit-code ${config.trivyExitCode} \
                                    --format table \
                                    ${FULL_IMAGE}
                            """
                        }
                    }
                }
            }

            stage('Push Artifact') {
                when {
                    expression { isMainBranch && !isPR }
                }
                steps {
                    container('docker') {
                        script {
                            echo "Pushing image to registry: ${config.dockerRegistry}"
                            withCredentials([usernamePassword(
                                credentialsId: 'docker-registry-credentials',
                                usernameVariable: 'REGISTRY_USER',
                                passwordVariable: 'REGISTRY_PASS'
                            )]) {
                                sh """
                                    echo \$REGISTRY_PASS | docker login ${config.dockerRegistry} -u \$REGISTRY_USER --password-stdin
                                    docker push ${FULL_IMAGE}
                                    docker push ${config.dockerImage}:latest
                                """
                            }
                        }
                    }
                }
            }

            stage('Update GitOps') {
                when {
                    expression { isMainBranch && !isPR && config.deployToArgoCD }
                }
                steps {
                    script {
                        echo "Updating GitOps manifests for ArgoCD..."
                        updateGitOpsManifest(config)
                    }
                }
            }

            stage('Record DORA Metrics') {
                steps {
                    script {
                        recordDoraMetrics(config, currentBuild)
                    }
                }
            }
        }

        post {
            success {
                script {
                    notifyBuild('SUCCESS', config)
                }
            }
            failure {
                script {
                    notifyBuild('FAILURE', config)
                }
            }
            always {
                cleanWs()
            }
        }
    }
}

/**
 * Set language-specific default commands
 */
def setLanguageDefaults(Map config) {
    switch (config.language) {
        case 'java':
            if (!config.buildCommand) config.buildCommand = 'mvn clean package -DskipTests'
            if (!config.testCommand) config.testCommand = 'mvn test'
            if (!config.bddTestCommand) config.bddTestCommand = 'mvn verify -Pcucumber'
            break
        case 'python':
            if (!config.buildCommand) config.buildCommand = 'pip install -r requirements.txt && pip install -e .'
            if (!config.testCommand) config.testCommand = 'pytest tests/unit --junitxml=test-results.xml --cov=src --cov-report=xml'
            if (!config.bddTestCommand) config.bddTestCommand = 'behave --junit --junit-directory=bdd-results'
            break
        case 'node':
            if (!config.buildCommand) config.buildCommand = 'npm ci && npm run build'
            if (!config.testCommand) config.testCommand = 'npm test -- --ci --reporters=jest-junit'
            if (!config.bddTestCommand) config.bddTestCommand = 'npm run test:bdd'
            break
        case 'go':
            if (!config.buildCommand) config.buildCommand = 'go build -v ./...'
            if (!config.testCommand) config.testCommand = 'go test -v -coverprofile=coverage.out ./...'
            if (!config.bddTestCommand) config.bddTestCommand = 'go test -v ./features/...'
            break
        default:
            error "Unsupported language: ${config.language}. Supported: java, python, node, go"
    }
}

/**
 * Get the container name for the language
 */
def getContainerName(String language) {
    switch (language) {
        case 'java': return 'maven'
        case 'python': return 'python'
        case 'node': return 'node'
        case 'go': return 'golang'
        default: return 'jnlp'
    }
}

/**
 * Get pod template YAML for the specified language
 */
def getPodTemplate(String language) {
    def baseTemplate = """
apiVersion: v1
kind: Pod
metadata:
  labels:
    jenkins: agent
    language: ${language}
spec:
  containers:
"""

    def languageContainer = getLanguageContainer(language)
    def commonContainers = """
  - name: docker
    image: docker:24-dind
    command: ['cat']
    tty: true
    securityContext:
      privileged: true
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

    return baseTemplate + languageContainer + commonContainers
}

/**
 * Get language-specific container definition
 */
def getLanguageContainer(String language) {
    switch (language) {
        case 'java':
            return """
  - name: maven
    image: maven:3.9-eclipse-temurin-17
    command: ['cat']
    tty: true
    resources:
      requests:
        cpu: '1'
        memory: '2Gi'
      limits:
        cpu: '2'
        memory: '4Gi'
"""
        case 'python':
            return """
  - name: python
    image: python:3.11-slim
    command: ['cat']
    tty: true
    resources:
      requests:
        cpu: '500m'
        memory: '1Gi'
      limits:
        cpu: '1'
        memory: '2Gi'
"""
        case 'node':
            return """
  - name: node
    image: node:20-slim
    command: ['cat']
    tty: true
    resources:
      requests:
        cpu: '500m'
        memory: '1Gi'
      limits:
        cpu: '1'
        memory: '2Gi'
"""
        case 'go':
            return """
  - name: golang
    image: golang:1.21
    command: ['cat']
    tty: true
    resources:
      requests:
        cpu: '500m'
        memory: '1Gi'
      limits:
        cpu: '1'
        memory: '2Gi'
"""
        default:
            return """
  - name: jnlp
    image: jenkins/inbound-agent:latest
    command: ['cat']
    tty: true
"""
    }
}

/**
 * Publish test results based on language
 */
def publishTestResults(String language) {
    switch (language) {
        case 'java':
            junit allowEmptyResults: true, testResults: '**/target/surefire-reports/*.xml'
            break
        case 'python':
            junit allowEmptyResults: true, testResults: '**/test-results.xml'
            break
        case 'node':
            junit allowEmptyResults: true, testResults: '**/junit.xml'
            break
        case 'go':
            // Go test results parsing
            break
    }
}

/**
 * Publish BDD test results
 */
def publishBddResults(String language) {
    // Publish Cucumber/BDD results if available
    publishHTML(target: [
        allowMissing: true,
        alwaysLinkToLastBuild: true,
        keepAll: true,
        reportDir: 'bdd-results',
        reportFiles: 'index.html',
        reportName: 'BDD Test Report'
    ])
}

/**
 * Run SonarQube analysis based on language
 *
 * Executes language-specific SonarQube scanner with branch information
 * for accurate tracking in the SonarQube dashboard. Links analysis to
 * the Git repository and branch names for proper reporting.
 */
def runSonarScan(Map config) {
    def branch = env.BRANCH_NAME ?: 'main'
    def commitSha = env.GIT_COMMIT ?: ''
    
    echo "Running SonarQube analysis for ${config.sonarProject} on branch ${branch}"
    
    switch (config.language) {
        case 'java':
            sh """
                mvn sonar:sonar \
                    -Dsonar.projectKey=${config.sonarProject} \
                    -Dsonar.projectName='${config.sonarProject}' \
                    -Dsonar.branch.name=${branch} \
                    -Dsonar.scm.revision=${commitSha}
            """
            break
        case 'python':
            sh """
                sonar-scanner \
                    -Dsonar.projectKey=${config.sonarProject} \
                    -Dsonar.projectName='${config.sonarProject}' \
                    -Dsonar.sources=src \
                    -Dsonar.python.coverage.reportPaths=coverage.xml \
                    -Dsonar.branch.name=${branch} \
                    -Dsonar.scm.revision=${commitSha}
            """
            break
        case 'node':
            sh """
                npx sonar-scanner \
                    -Dsonar.projectKey=${config.sonarProject} \
                    -Dsonar.projectName='${config.sonarProject}' \
                    -Dsonar.sources=src \
                    -Dsonar.javascript.lcov.reportPaths=coverage/lcov.info \
                    -Dsonar.branch.name=${branch} \
                    -Dsonar.scm.revision=${commitSha}
            """
            break
        case 'go':
            sh """
                sonar-scanner \
                    -Dsonar.projectKey=${config.sonarProject} \
                    -Dsonar.projectName='${config.sonarProject}' \
                    -Dsonar.sources=. \
                    -Dsonar.go.coverage.reportPaths=coverage.out \
                    -Dsonar.branch.name=${branch} \
                    -Dsonar.scm.revision=${commitSha}
            """
            break
    }
}

/**
 * Run dependency security check
 */
def runDependencyCheck(Map config) {
    switch (config.language) {
        case 'java':
            sh 'mvn org.owasp:dependency-check-maven:check'
            break
        case 'python':
            sh 'pip install safety && safety check --json > safety-report.json || true'
            break
        case 'node':
            sh 'npm audit --json > npm-audit.json || true'
            break
        case 'go':
            sh 'go install golang.org/x/vuln/cmd/govulncheck@latest && govulncheck ./...'
            break
    }
}

/**
 * Update GitOps manifest in separate repository
 */
def updateGitOpsManifest(Map config) {
    withCredentials([usernamePassword(
        credentialsId: 'github-credentials',
        usernameVariable: 'GIT_USER',
        passwordVariable: 'GIT_TOKEN'
    )]) {
        // Clone without credentials in URL to avoid exposure in logs
        sh """
            # Configure git credential helper to avoid credentials in clone URL
            git config --global credential.helper 'store --file=/tmp/.git-credentials'
            echo "https://\${GIT_USER}:\${GIT_TOKEN}@github.com" > /tmp/.git-credentials
            
            git clone https://github.com/paruff/fawkes-gitops.git gitops-repo
            cd gitops-repo
            
            # Update image tag in deployment manifest
            if [ -f "apps/dev/${config.appName}/deployment.yaml" ]; then
                sed -i 's|image: ${config.dockerImage}:.*|image: ${FULL_IMAGE}|g' apps/dev/${config.appName}/deployment.yaml
                
                git config user.name "Jenkins CI"
                git config user.email "jenkins@fawkes.local"
                git add apps/dev/${config.appName}/deployment.yaml
                git commit -m "Update ${config.appName} to ${IMAGE_TAG}" || echo "No changes to commit"
                git push origin main
            else
                echo "Warning: Deployment manifest not found for ${config.appName}"
            fi
            
            # Clean up credentials
            rm -f /tmp/.git-credentials
        """
    }
}

/**
 * Record DORA metrics
 */
def recordDoraMetrics(Map config, def build) {
    def status = build.currentResult ?: 'UNKNOWN'
    def duration = build.duration ?: 0

    try {
        httpRequest(
            url: "${DORA_METRICS_URL}/api/v1/builds",
            httpMode: 'POST',
            contentType: 'APPLICATION_JSON',
            requestBody: """
            {
                "service": "${config.appName}",
                "commit_sha": "${env.GIT_COMMIT}",
                "branch": "${env.BRANCH_NAME}",
                "build_number": "${env.BUILD_NUMBER}",
                "status": "${status}",
                "duration_ms": ${duration},
                "timestamp": "${new Date().format("yyyy-MM-dd'T'HH:mm:ss'Z'", TimeZone.getTimeZone('UTC'))}"
            }
            """,
            validResponseCodes: '200:299'
        )
    } catch (Exception e) {
        echo "Warning: Failed to record DORA metrics: ${e.message}"
    }
}

/**
 * Send build notification to Mattermost
 */
def notifyBuild(String status, Map config) {
    def color = status == 'SUCCESS' ? 'good' : 'danger'
    def emoji = status == 'SUCCESS' ? '✅' : '❌'
    def message = "${emoji} Build #${env.BUILD_NUMBER} ${status} for ${config.appName}"
    message += "\nBranch: ${env.BRANCH_NAME}"
    message += "\nCommit: ${env.GIT_COMMIT?.take(7)}"
    message += "\nDuration: ${currentBuild.durationString}"
    message += "\n<${env.BUILD_URL}|View Build>"

    try {
        mattermostSend(
            channel: config.notifyChannel,
            color: color,
            message: message
        )
    } catch (Exception e) {
        echo "Warning: Failed to send Mattermost notification: ${e.message}"
    }
}

return this
