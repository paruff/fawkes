#!/usr/bin/env groovy
/**
 * Security Scan Step for Fawkes Platform
 *
 * Provides reusable security scanning functions including:
 * - Container image scanning with Trivy
 * - SonarQube static analysis with Quality Gate enforcement
 * - OWASP dependency checks
 *
 * Usage:
 * @Library('fawkes-pipeline-library') _
 * securityScan {
 *     image = 'my-image:tag'
 *     sonarProject = 'my-project'
 *     language = 'java'
 *     failOnQualityGate = true
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
        failOnVulnerabilities: true,
        failOnQualityGate: true,
        sonarQubeTimeout: 5,
        sonarHostUrl: env.SONARQUBE_URL ?: 'http://sonarqube.fawkes.svc:9000',
        sonarBranch: env.BRANCH_NAME ?: 'main'
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
 * Run SonarQube analysis with Quality Gate enforcement
 *
 * This function executes SonarQube analysis and waits for the Quality Gate result.
 * If the Quality Gate fails and failOnQualityGate is true, the pipeline will fail.
 * A direct link to the SonarQube analysis report is provided in the build logs.
 */
def sonarAnalysis(Map config) {
    def sonarReportUrl = ''
    
    withSonarQubeEnv('SonarQube') {
        switch (config.language) {
            case 'java':
                sh """
                    mvn sonar:sonar \
                        -Dsonar.projectKey=${config.sonarProject} \
                        -Dsonar.projectName='${config.sonarProject}' \
                        -Dsonar.branch.name=${config.sonarBranch}
                """
                break
            case 'python':
                sh """
                    sonar-scanner \
                        -Dsonar.projectKey=${config.sonarProject} \
                        -Dsonar.projectName='${config.sonarProject}' \
                        -Dsonar.sources=src \
                        -Dsonar.python.coverage.reportPaths=coverage.xml \
                        -Dsonar.branch.name=${config.sonarBranch}
                """
                break
            case 'node':
                sh """
                    npx sonar-scanner \
                        -Dsonar.projectKey=${config.sonarProject} \
                        -Dsonar.projectName='${config.sonarProject}' \
                        -Dsonar.sources=src \
                        -Dsonar.javascript.lcov.reportPaths=coverage/lcov.info \
                        -Dsonar.branch.name=${config.sonarBranch}
                """
                break
            case 'go':
                sh """
                    sonar-scanner \
                        -Dsonar.projectKey=${config.sonarProject} \
                        -Dsonar.projectName='${config.sonarProject}' \
                        -Dsonar.sources=. \
                        -Dsonar.go.coverage.reportPaths=coverage.out \
                        -Dsonar.branch.name=${config.sonarBranch}
                """
                break
        }
        
        // Construct SonarQube report URL for developer access
        sonarReportUrl = "${config.sonarHostUrl}/dashboard?id=${config.sonarProject}&branch=${config.sonarBranch}"
    }
    
    // Wait for quality gate with detailed logging
    echo "=============================================="
    echo "Waiting for SonarQube Quality Gate result..."
    echo "=============================================="
    
    timeout(time: config.sonarQubeTimeout, unit: 'MINUTES') {
        def qg = waitForQualityGate()
        
        // Log Quality Gate result with link to dashboard
        echo "=============================================="
        echo "SonarQube Quality Gate: ${qg.status}"
        echo "=============================================="
        echo "📊 View detailed analysis report:"
        echo "   ${sonarReportUrl}"
        echo "=============================================="
        
        // Add summary to build description for easy access
        currentBuild.description = (currentBuild.description ?: '') + 
            "\n<a href='${sonarReportUrl}'>SonarQube Report</a>"
        
        if (qg.status != 'OK') {
            def failureMessage = """
============================================
❌ QUALITY GATE FAILED: ${qg.status}
============================================
The code changes did not meet the quality criteria.
Please review the SonarQube analysis for details:

${sonarReportUrl}

Common failure reasons:
- New bugs or vulnerabilities introduced
- Code coverage dropped below threshold
- Duplicate code exceeded limit
- Security hotspots require review
============================================
"""
            echo failureMessage
            
            if (config.failOnQualityGate) {
                error "Quality Gate failed: ${qg.status}. See SonarQube report: ${sonarReportUrl}"
            } else {
                unstable "Quality Gate failed but pipeline continues: ${qg.status}"
            }
        } else {
            echo "✅ Quality Gate passed successfully!"
        }
    }
    
    return sonarReportUrl
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

/**
 * Get the SonarQube dashboard URL for a project
 *
 * @param projectKey The SonarQube project key
 * @param branch Optional branch name
 * @return The URL to the SonarQube dashboard
 */
def getSonarQubeUrl(String projectKey, String branch = 'main') {
    def baseUrl = env.SONARQUBE_URL ?: 'http://sonarqube.fawkes.svc:9000'
    return "${baseUrl}/dashboard?id=${projectKey}&branch=${branch}"
}

return this
