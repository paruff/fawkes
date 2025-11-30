#!/usr/bin/env groovy
/**
 * Security Scan Step for Fawkes Platform
 *
 * Provides reusable security scanning functions including:
 * - Container image scanning with Trivy
 * - SonarQube static analysis
 * - OWASP dependency checks
 *
 * Usage:
 * @Library('fawkes-pipeline-library') _
 * securityScan {
 *     image = 'my-image:tag'
 *     sonarProject = 'my-project'
 *     language = 'java'
 * }
 *
 * @author Fawkes Platform Team
 */

def call(Map config = [:]) {
    def defaultConfig = [
        image: '',
        sonarProject: '',
        language: 'java',
        trivySeverity: 'HIGH,CRITICAL',
        trivyExitCode: '1',
        failOnVulnerabilities: true
    ]

    config = defaultConfig + config

    stage('Security Scan') {
        parallel(
            'Container Scan': {
                if (config.image) {
                    containerScan(config)
                }
            },
            'Static Analysis': {
                if (config.sonarProject) {
                    sonarAnalysis(config)
                }
            },
            'Dependency Check': {
                dependencyCheck(config)
            }
        )
    }
}

/**
 * Run Trivy container scan
 */
def containerScan(Map config) {
    container('trivy') {
        echo "Scanning container image: ${config.image}"
        
        def exitCode = config.failOnVulnerabilities ? config.trivyExitCode : '0'
        
        sh """
            trivy image \
                --severity ${config.trivySeverity} \
                --exit-code ${exitCode} \
                --format table \
                --output trivy-report.txt \
                ${config.image}
        """
        
        // Generate JSON report for archiving
        sh """
            trivy image \
                --severity ${config.trivySeverity} \
                --format json \
                --output trivy-report.json \
                ${config.image}
        """
        
        archiveArtifacts artifacts: 'trivy-report.*', allowEmptyArchive: true
    }
}

/**
 * Run SonarQube analysis
 */
def sonarAnalysis(Map config) {
    withSonarQubeEnv('SonarQube') {
        switch (config.language) {
            case 'java':
                sh "mvn sonar:sonar -Dsonar.projectKey=${config.sonarProject}"
                break
            case 'python':
                sh """
                    sonar-scanner \
                        -Dsonar.projectKey=${config.sonarProject} \
                        -Dsonar.sources=src \
                        -Dsonar.python.coverage.reportPaths=coverage.xml
                """
                break
            case 'node':
                sh """
                    npx sonar-scanner \
                        -Dsonar.projectKey=${config.sonarProject} \
                        -Dsonar.sources=src \
                        -Dsonar.javascript.lcov.reportPaths=coverage/lcov.info
                """
                break
            case 'go':
                sh """
                    sonar-scanner \
                        -Dsonar.projectKey=${config.sonarProject} \
                        -Dsonar.sources=. \
                        -Dsonar.go.coverage.reportPaths=coverage.out
                """
                break
        }
    }
    
    // Wait for quality gate
    timeout(time: 5, unit: 'MINUTES') {
        def qg = waitForQualityGate()
        if (qg.status != 'OK' && config.failOnVulnerabilities) {
            error "Quality Gate failed: ${qg.status}"
        }
    }
}

/**
 * Run dependency vulnerability check
 */
def dependencyCheck(Map config) {
    echo "Running dependency vulnerability check..."
    
    switch (config.language) {
        case 'java':
            sh 'mvn org.owasp:dependency-check-maven:check -DfailBuildOnCVSS=7 || true'
            archiveArtifacts artifacts: '**/dependency-check-report.*', allowEmptyArchive: true
            break
        case 'python':
            sh '''
                pip install safety pip-audit
                safety check --json > safety-report.json || true
                pip-audit --format json -o pip-audit.json || true
            '''
            archiveArtifacts artifacts: '*-report.json,pip-audit.json', allowEmptyArchive: true
            break
        case 'node':
            sh '''
                npm audit --json > npm-audit.json || true
            '''
            archiveArtifacts artifacts: 'npm-audit.json', allowEmptyArchive: true
            break
        case 'go':
            sh '''
                go install golang.org/x/vuln/cmd/govulncheck@latest
                govulncheck -json ./... > govulncheck.json || true
            '''
            archiveArtifacts artifacts: 'govulncheck.json', allowEmptyArchive: true
            break
    }
}

return this
