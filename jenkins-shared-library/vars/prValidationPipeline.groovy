#!/usr/bin/env groovy
/**
 * Lightweight PR Pipeline for Fawkes Platform
 *
 * This pipeline runs only unit and BDD tests for pull requests,
 * providing fast feedback without producing artifacts.
 *
 * Usage in Jenkinsfile:
 * @Library('fawkes-pipeline-library') _
 * prValidationPipeline {
 *     appName = 'my-service'
 *     language = 'java'
 * }
 *
 * @author Fawkes Platform Team
 */

def call(Map config = [:]) {
    def defaultConfig = [
        appName: env.JOB_BASE_NAME ?: 'unknown-app',
        language: 'java',
        testCommand: '',
        bddTestCommand: '',
        notifyChannel: 'ci-builds',
        timeoutMinutes: 15
    ]

    config = defaultConfig + config
    setLanguageDefaults(config)

    pipeline {
        agent {
            kubernetes {
                yaml getPodTemplate(config.language)
            }
        }

        options {
            timeout(time: config.timeoutMinutes, unit: 'MINUTES')
            timestamps()
            buildDiscarder(logRotator(numToKeepStr: '5'))
        }

        stages {
            stage('Checkout') {
                steps {
                    checkout scm
                    script {
                        echo "PR Validation for ${config.appName}"
                        echo "PR: #${env.CHANGE_ID}"
                        echo "Source: ${env.CHANGE_BRANCH} -> ${env.CHANGE_TARGET}"
                    }
                }
            }

            stage('Unit Test') {
                steps {
                    container(getContainerName(config.language)) {
                        script {
                            echo "Running unit tests..."
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
                    expression { config.bddTestCommand }
                }
                steps {
                    container(getContainerName(config.language)) {
                        script {
                            echo "Running BDD tests..."
                            sh config.bddTestCommand
                        }
                    }
                }
            }

            stage('Code Style Check') {
                steps {
                    container(getContainerName(config.language)) {
                        script {
                            runLinting(config)
                        }
                    }
                }
            }
        }

        post {
            success {
                script {
                    setPRStatus('success', 'All tests passed', config)
                }
            }
            failure {
                script {
                    setPRStatus('failure', 'Tests failed', config)
                }
            }
            always {
                cleanWs()
            }
        }
    }
}

/**
 * Set language-specific defaults
 */
def setLanguageDefaults(Map config) {
    switch (config.language) {
        case 'java':
            if (!config.testCommand) config.testCommand = 'mvn test'
            if (!config.bddTestCommand) config.bddTestCommand = 'mvn verify -Pcucumber'
            break
        case 'python':
            if (!config.testCommand) config.testCommand = 'pytest tests/unit --junitxml=test-results.xml'
            if (!config.bddTestCommand) config.bddTestCommand = 'behave --junit'
            break
        case 'node':
            if (!config.testCommand) config.testCommand = 'npm test -- --ci'
            if (!config.bddTestCommand) config.bddTestCommand = 'npm run test:bdd'
            break
        case 'go':
            if (!config.testCommand) config.testCommand = 'go test -v ./...'
            if (!config.bddTestCommand) config.bddTestCommand = 'go test -v ./features/...'
            break
    }
}

/**
 * Get container name for language
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
 * Get pod template
 */
def getPodTemplate(String language) {
    def containers = [
        java: """
  - name: maven
    image: maven:3.9-eclipse-temurin-17
    command: ['cat']
    tty: true
    resources:
      requests:
        cpu: '500m'
        memory: '1Gi'
      limits:
        cpu: '1'
        memory: '2Gi'
""",
        python: """
  - name: python
    image: python:3.11-slim
    command: ['cat']
    tty: true
    resources:
      requests:
        cpu: '250m'
        memory: '512Mi'
      limits:
        cpu: '500m'
        memory: '1Gi'
""",
        node: """
  - name: node
    image: node:20-slim
    command: ['cat']
    tty: true
    resources:
      requests:
        cpu: '250m'
        memory: '512Mi'
      limits:
        cpu: '500m'
        memory: '1Gi'
""",
        go: """
  - name: golang
    image: golang:1.21
    command: ['cat']
    tty: true
    resources:
      requests:
        cpu: '250m'
        memory: '512Mi'
      limits:
        cpu: '500m'
        memory: '1Gi'
"""
    ]

    return """
apiVersion: v1
kind: Pod
metadata:
  labels:
    jenkins: agent
    pipeline: pr-validation
spec:
  containers:
${containers[language] ?: containers['java']}
"""
}

/**
 * Publish test results
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
    }
}

/**
 * Run linting based on language
 */
def runLinting(Map config) {
    switch (config.language) {
        case 'java':
            sh 'mvn checkstyle:check || true'
            break
        case 'python':
            sh 'pip install flake8 && flake8 src/ --exit-zero'
            break
        case 'node':
            sh 'npm run lint || true'
            break
        case 'go':
            // Using staticcheck instead of deprecated golint
            sh 'go install honnef.co/go/tools/cmd/staticcheck@latest && staticcheck ./... || true'
            break
    }
}

/**
 * Set GitHub PR status
 */
def setPRStatus(String state, String description, Map config) {
    try {
        // Use GitHub status API
        def context = "jenkins/${config.appName}"
        githubNotify status: state, description: description, context: context
    } catch (Exception e) {
        echo "Warning: Failed to set PR status: ${e.message}"
    }
}

return this
