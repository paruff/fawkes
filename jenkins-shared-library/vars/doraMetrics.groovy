#!/usr/bin/env groovy
/**
 * DORA Metrics Helper for Fawkes Platform
 *
 * This shared library provides functions for emitting CI/build metrics events
 * to DevLake for tracking rework, build success rates, and quality metrics.
 *
 * IMPORTANT: In Fawkes GitOps architecture:
 * - ArgoCD is the PRIMARY source for deployment frequency metrics
 * - Jenkins provides CI metrics: build success, rework, quality gates
 * - This library focuses on CI-related metrics, not deployments
 *
 * Usage in Jenkinsfile:
 * @Library('fawkes-pipeline-library') _
 *
 * doraMetrics.recordBuild(
 *     service: 'my-service',
 *     status: 'success',
 *     stage: 'build'
 * )
 *
 * doraMetrics.recordQualityGate(
 *     service: 'my-service',
 *     passed: true,
 *     coveragePercent: 85
 * )
 *
 * @author Fawkes Platform Team
 */

/**
 * Record a CI build event for rework and build success tracking
 *
 * @param config Map containing:
 *   - service: Name of the service being built
 *   - status: Build status (success, failure, unstable)
 *   - stage: Build stage (build, test, scan, package)
 *   - isRetry: Whether this is a retry of a previous build
 */
def recordBuild(Map config = [:]) {
    def defaults = [
        service: env.JOB_BASE_NAME ?: 'unknown-service',
        status: 'success',
        stage: 'build',
        isRetry: isRetryBuild(),
        commitSha: env.GIT_COMMIT ?: '',
        duration: currentBuild.duration ?: 0,
        buildNumber: env.BUILD_NUMBER ?: '0',
        buildUrl: env.BUILD_URL ?: '',
        timestamp: new Date().format("yyyy-MM-dd'T'HH:mm:ss'Z'", TimeZone.getTimeZone('UTC'))
    ]

    config = defaults + config

    def devlakeApiUrl = env.DEVLAKE_API_URL ?: 'http://devlake.fawkes-devlake.svc:8080'

    def payload = """
    {
        "service": "${config.service}",
        "commit_sha": "${config.commitSha}",
        "branch": "${env.BRANCH_NAME ?: 'main'}",
        "build_number": "${config.buildNumber}",
        "status": "${config.status}",
        "duration_ms": ${config.duration},
        "stage": "${config.stage}",
        "is_retry": ${config.isRetry},
        "timestamp": "${config.timestamp}",
        "url": "${config.buildUrl}",
        "type": "ci_build"
    }
    """

    try {
        httpRequest(
            url: "${devlakeApiUrl}/api/plugins/webhook/1/cicd",
            httpMode: 'POST',
            contentType: 'APPLICATION_JSON',
            requestBody: payload,
            validResponseCodes: '200:299'
        )
        echo "✅ DORA: Build event recorded for ${config.service} (${config.stage})"
    } catch (Exception e) {
        echo "⚠️ DORA: Failed to record build event: ${e.message}"
    }
}

/**
 * Record a quality gate result (SonarQube)
 *
 * @param config Map containing:
 *   - service: Name of the service
 *   - passed: Whether quality gate passed
 *   - coveragePercent: Code coverage percentage
 *   - bugs: Number of bugs found
 *   - vulnerabilities: Number of vulnerabilities found
 */
def recordQualityGate(Map config = [:]) {
    def defaults = [
        service: env.JOB_BASE_NAME ?: 'unknown-service',
        passed: true,
        coveragePercent: 0,
        bugs: 0,
        vulnerabilities: 0,
        codeSmells: 0,
        duplicatedLines: 0,
        commitSha: env.GIT_COMMIT ?: '',
        buildNumber: env.BUILD_NUMBER ?: '0',
        timestamp: new Date().format("yyyy-MM-dd'T'HH:mm:ss'Z'", TimeZone.getTimeZone('UTC'))
    ]

    config = defaults + config

    def devlakeApiUrl = env.DEVLAKE_API_URL ?: 'http://devlake.fawkes-devlake.svc:8080'

    def payload = """
    {
        "service": "${config.service}",
        "commit_sha": "${config.commitSha}",
        "build_number": "${config.buildNumber}",
        "quality_gate_passed": ${config.passed},
        "coverage_percent": ${config.coveragePercent},
        "bugs": ${config.bugs},
        "vulnerabilities": ${config.vulnerabilities},
        "code_smells": ${config.codeSmells},
        "duplicated_lines_percent": ${config.duplicatedLines},
        "timestamp": "${config.timestamp}",
        "type": "quality_gate"
    }
    """

    try {
        httpRequest(
            url: "${devlakeApiUrl}/api/plugins/webhook/1/cicd",
            httpMode: 'POST',
            contentType: 'APPLICATION_JSON',
            requestBody: payload,
            validResponseCodes: '200:299'
        )
        echo "✅ DORA: Quality gate result recorded for ${config.service} (${config.passed ? 'PASSED' : 'FAILED'})"
    } catch (Exception e) {
        echo "⚠️ DORA: Failed to record quality gate result: ${e.message}"
    }
}

/**
 * Record test results for flakiness tracking
 *
 * @param config Map containing:
 *   - service: Name of the service
 *   - totalTests: Total number of tests
 *   - passedTests: Number of passed tests
 *   - failedTests: Number of failed tests
 *   - skippedTests: Number of skipped tests
 *   - flakyTests: Number of flaky tests (passed on retry)
 */
def recordTestResults(Map config = [:]) {
    def defaults = [
        service: env.JOB_BASE_NAME ?: 'unknown-service',
        totalTests: 0,
        passedTests: 0,
        failedTests: 0,
        skippedTests: 0,
        flakyTests: 0,
        duration: 0,
        commitSha: env.GIT_COMMIT ?: '',
        buildNumber: env.BUILD_NUMBER ?: '0',
        timestamp: new Date().format("yyyy-MM-dd'T'HH:mm:ss'Z'", TimeZone.getTimeZone('UTC'))
    ]

    config = defaults + config

    def devlakeApiUrl = env.DEVLAKE_API_URL ?: 'http://devlake.fawkes-devlake.svc:8080'

    def payload = """
    {
        "service": "${config.service}",
        "commit_sha": "${config.commitSha}",
        "build_number": "${config.buildNumber}",
        "total_tests": ${config.totalTests},
        "passed_tests": ${config.passedTests},
        "failed_tests": ${config.failedTests},
        "skipped_tests": ${config.skippedTests},
        "flaky_tests": ${config.flakyTests},
        "duration_ms": ${config.duration},
        "timestamp": "${config.timestamp}",
        "type": "test_results"
    }
    """

    try {
        httpRequest(
            url: "${devlakeApiUrl}/api/plugins/webhook/1/cicd",
            httpMode: 'POST',
            contentType: 'APPLICATION_JSON',
            requestBody: payload,
            validResponseCodes: '200:299'
        )
        echo "✅ DORA: Test results recorded for ${config.service} (${config.passedTests}/${config.totalTests} passed)"
    } catch (Exception e) {
        echo "⚠️ DORA: Failed to record test results: ${e.message}"
    }
}

/**
 * Record an incident event for MTTR tracking
 * NOTE: Incidents are typically created by observability platform
 * This is for manual incident recording from pipeline failures
 *
 * @param config Map containing:
 *   - service: Name of the affected service
 *   - severity: Incident severity (high, medium, low)
 *   - status: Incident status (open, resolved)
 *   - title: Incident title/description
 */
def recordIncident(Map config = [:]) {
    def defaults = [
        service: env.JOB_BASE_NAME ?: 'unknown-service',
        severity: 'medium',
        status: 'open',
        title: 'CI/CD failure',
        createdAt: new Date().format("yyyy-MM-dd'T'HH:mm:ss'Z'", TimeZone.getTimeZone('UTC')),
        resolvedAt: null,
        buildNumber: env.BUILD_NUMBER ?: '0',
        environment: 'ci'
    ]

    config = defaults + config

    def devlakeWebhookUrl = env.DEVLAKE_WEBHOOK_URL ?: 'http://devlake.fawkes-devlake.svc:8080'

    // Build JSON payload with proper handling of optional resolvedAt field
    def resolvedDateField = config.resolvedAt ? ",\n        \"resolvedDate\": \"${config.resolvedAt}\"" : ''

    def payload = """
    {
        "id": "${config.service}-incident-${config.buildNumber}",
        "title": "${config.title}",
        "status": "${config.status}",
        "severity": "${config.severity}",
        "createdDate": "${config.createdAt}"${resolvedDateField},
        "service": "${config.service}",
        "environment": "${config.environment}",
        "url": "${env.BUILD_URL ?: ''}"
    }
    """

    try {
        httpRequest(
            url: "${devlakeWebhookUrl}/api/plugins/webhook/1/incidents",
            httpMode: 'POST',
            contentType: 'APPLICATION_JSON',
            requestBody: payload,
            validResponseCodes: '200:299'
        )
        echo "✅ DORA: Incident event recorded for ${config.service} (${config.status})"
    } catch (Exception e) {
        echo "⚠️ DORA: Failed to record incident event: ${e.message}"
    }
}

/**
 * Record complete CI pipeline metrics
 * Call this at the end of the pipeline to record all CI metrics
 *
 * @param config Map containing:
 *   - service: Name of the service
 */
def recordPipelineComplete(Map config = [:]) {
    def defaults = [
        service: env.JOB_BASE_NAME ?: 'unknown-service',
        pipelineResult: currentBuild.currentResult ?: 'UNKNOWN'
    ]

    config = defaults + config

    // Record final build status
    recordBuild(
        service: config.service,
        status: config.pipelineResult == 'SUCCESS' ? 'success' : 'failure',
        stage: 'pipeline-complete'
    )

    // Log summary
    echo """
    ============================================
    📊 CI Metrics Summary for ${config.service}
    ============================================
    Build Result: ${config.pipelineResult}
    Duration: ${currentBuild.durationString}
    Commit: ${env.GIT_COMMIT?.take(7) ?: 'unknown'}
    Branch: ${env.BRANCH_NAME ?: 'unknown'}

    NOTE: Deployment metrics are tracked via ArgoCD.
    View DORA dashboard: http://devlake-grafana.127.0.0.1.nip.io
    ============================================
    """
}

/**
 * Check if this is a retry build (same commit as previous build)
 */
def isRetryBuild() {
    try {
        def previousBuild = currentBuild.previousBuild
        if (previousBuild) {
            def previousCommit = previousBuild.changeSets?.find { it }?.items?.find { it }?.commitId
            def currentCommit = env.GIT_COMMIT
            return previousCommit == currentCommit
        }
    } catch (Exception e) {
        echo "⚠️ Could not determine if this is a retry build: ${e.message}"
    }
    return false
}

/**
 * Get rework metrics summary for a service
 *
 * @param service Name of the service
 * @return Map containing rework metrics or null if unavailable
 */
def getReworkMetrics(String service) {
    def devlakeApiUrl = env.DEVLAKE_API_URL ?: 'http://devlake.fawkes-devlake.svc:8080'

    try {
        def response = httpRequest(
            url: "${devlakeApiUrl}/api/dora/rework?project=${service}",
            httpMode: 'GET',
            contentType: 'APPLICATION_JSON',
            validResponseCodes: '200:299'
        )

        def metrics = readJSON text: response.content

        echo """
        ============================================
        📊 Rework Metrics for ${service}
        ============================================
        Build Success Rate: ${metrics.buildSuccessRate?.value ?: 'N/A'}%
        Rework Rate: ${metrics.reworkRate?.value ?: 'N/A'}%
        Quality Gate Pass Rate: ${metrics.qualityGatePassRate?.value ?: 'N/A'}%
        Test Flakiness: ${metrics.testFlakiness?.value ?: 'N/A'}%
        Avg Build Duration: ${metrics.avgBuildDuration?.value ?: 'N/A'} min
        ============================================
        """

        return metrics
    } catch (Exception e) {
        echo "⚠️ DORA: Unable to fetch rework metrics: ${e.message}"
        return null
    }
}

/**
 * Get DORA metrics summary for a service
 * NOTE: Deployment metrics come from ArgoCD, not Jenkins
 *
 * @param service Name of the service
 * @return Map containing DORA metrics or null if unavailable
 */
def getMetricsSummary(String service) {
    def devlakeApiUrl = env.DEVLAKE_API_URL ?: 'http://devlake.fawkes-devlake.svc:8080'

    try {
        def response = httpRequest(
            url: "${devlakeApiUrl}/api/dora/metrics?project=${service}",
            httpMode: 'GET',
            contentType: 'APPLICATION_JSON',
            validResponseCodes: '200:299'
        )

        def metrics = readJSON text: response.content

        echo """
        ============================================
        📊 DORA Metrics for ${service}
        ============================================
        Deployment Frequency: ${metrics.deploymentFrequency?.value ?: 'N/A'} ${metrics.deploymentFrequency?.unit ?: ''} (via ArgoCD)
        Lead Time for Changes: ${metrics.leadTimeForChanges?.value ?: 'N/A'} ${metrics.leadTimeForChanges?.unit ?: ''}
        Change Failure Rate: ${metrics.changeFailureRate?.value ?: 'N/A'}%
        Mean Time to Restore: ${metrics.meanTimeToRestore?.value ?: 'N/A'} ${metrics.meanTimeToRestore?.unit ?: ''}
        Operational Performance: ${metrics.operationalPerformance?.value ?: 'N/A'}%
        ============================================

        CI/Rework Metrics (Jenkins):
        Build Success Rate: ${metrics.buildSuccessRate?.value ?: 'N/A'}%
        Rework Rate: ${metrics.reworkRate?.value ?: 'N/A'}%
        ============================================
        """

        return metrics
    } catch (Exception e) {
        echo "⚠️ DORA: Unable to fetch metrics summary: ${e.message}"
        return null
    }
}

return this
