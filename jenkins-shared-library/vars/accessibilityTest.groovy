#!/usr/bin/env groovy
/**
 * Accessibility Testing Shared Library
 * 
 * Provides methods for running automated accessibility tests
 * using axe-core and Lighthouse CI in Jenkins pipelines.
 * 
 * Usage in Jenkinsfile:
 * @Library('fawkes-pipeline-library') _
 * 
 * stage('Accessibility Tests') {
 *   steps {
 *     accessibilityTest {
 *       runAxeCore = true
 *       runLighthouse = true
 *       wcagLevel = 'AA'
 *       failOnViolations = true
 *     }
 *   }
 * }
 * 
 * @author Fawkes Platform Team
 */

def call(Map config = [:]) {
    // Default configuration
    def defaultConfig = [
        runAxeCore: true,
        runLighthouse: true,
        wcagLevel: 'AA',  // 'A', 'AA', or 'AAA'
        failOnViolations: true,
        lighthouseScoreThreshold: 90,
        storybookUrl: '',
        publishResults: true
    ]
    
    // Merge user config with defaults
    config = defaultConfig + config
    
    def violations = []
    def axePassed = true
    def lighthousePassed = true
    
    echo """
    ============================================
    🔍 Starting Accessibility Testing
    ============================================
    WCAG Level: ${config.wcagLevel}
    Axe-Core: ${config.runAxeCore ? 'Enabled' : 'Disabled'}
    Lighthouse: ${config.runLighthouse ? 'Enabled' : 'Disabled'}
    Fail on Violations: ${config.failOnViolations}
    ============================================
    """
    
    // Run Axe-Core tests if enabled
    if (config.runAxeCore) {
        axePassed = runAxeCoreTests(config)
        if (!axePassed) {
            violations.add('Axe-Core tests detected violations')
        }
    }
    
    // Run Lighthouse tests if enabled
    if (config.runLighthouse) {
        lighthousePassed = runLighthouseTests(config)
        if (!lighthousePassed) {
            violations.add('Lighthouse CI score below threshold')
        }
    }
    
    // Publish results
    if (config.publishResults) {
        publishAccessibilityResults(axePassed, lighthousePassed, config)
    }
    
    // Generate summary
    generateAccessibilitySummary(axePassed, lighthousePassed, violations, config)
    
    // Fail build if configured and violations found
    if (config.failOnViolations && violations.size() > 0) {
        error """
        ❌ Accessibility Testing Failed
        
        Violations detected:
        ${violations.collect { "  - ${it}" }.join('\n')}
        
        Please review the accessibility test reports and fix the violations.
        """
    }
    
    return [
        passed: axePassed && lighthousePassed,
        axeCore: axePassed,
        lighthouse: lighthousePassed,
        violations: violations
    ]
}

/**
 * Run Axe-Core accessibility tests
 */
def runAxeCoreTests(Map config) {
    echo "Running Axe-Core accessibility tests..."
    
    try {
        sh """
            cd design-system
            npm run test:a11y:ci
        """
        
        echo "✅ Axe-Core tests passed"
        return true
    } catch (Exception e) {
        echo "❌ Axe-Core tests failed: ${e.message}"
        
        // Archive the test results
        archiveArtifacts artifacts: 'design-system/coverage/**/*', allowEmptyArchive: true
        
        return false
    }
}

/**
 * Run Lighthouse CI tests
 */
def runLighthouseTests(Map config) {
    echo "Running Lighthouse CI accessibility audit..."
    
    try {
        // Build Storybook first
        sh """
            cd design-system
            npm run build-storybook
        """
        
        // Run Lighthouse CI
        sh """
            cd design-system
            npm run lighthouse:ci
        """
        
        // Parse Lighthouse results
        def score = parseLighthouseScore()
        
        echo "📊 Lighthouse Accessibility Score: ${score}/100"
        
        if (score >= config.lighthouseScoreThreshold) {
            echo "✅ Lighthouse tests passed (Score: ${score} >= ${config.lighthouseScoreThreshold})"
            return true
        } else {
            echo "❌ Lighthouse tests failed (Score: ${score} < ${config.lighthouseScoreThreshold})"
            return false
        }
    } catch (Exception e) {
        echo "❌ Lighthouse tests failed: ${e.message}"
        
        // Archive the Lighthouse reports
        archiveArtifacts artifacts: 'design-system/.lighthouseci/**/*', allowEmptyArchive: true
        
        return false
    }
}

/**
 * Parse Lighthouse accessibility score from results
 */
def parseLighthouseScore() {
    try {
        def manifestFile = 'design-system/.lighthouseci/manifest.json'
        if (fileExists(manifestFile)) {
            def manifest = readJSON file: manifestFile
            if (manifest && manifest[0] && manifest[0].summary) {
                def score = manifest[0].summary.accessibility ?: 0
                return Math.round(score * 100)
            }
        }
    } catch (Exception e) {
        echo "Warning: Could not parse Lighthouse score: ${e.message}"
    }
    return 0
}

/**
 * Publish accessibility test results
 */
def publishAccessibilityResults(boolean axePassed, boolean lighthousePassed, Map config) {
    echo "Publishing accessibility test results..."
    
    // Publish JUnit test results if available
    junit allowEmptyResults: true, testResults: 'design-system/junit.xml'
    
    // Publish HTML reports
    publishHTML(target: [
        allowMissing: true,
        alwaysLinkToLastBuild: true,
        keepAll: true,
        reportDir: 'design-system/coverage/lcov-report',
        reportFiles: 'index.html',
        reportName: 'Axe-Core Coverage Report'
    ])
    
    publishHTML(target: [
        allowMissing: true,
        alwaysLinkToLastBuild: true,
        keepAll: true,
        reportDir: 'design-system/.lighthouseci',
        reportFiles: '*.html',
        reportName: 'Lighthouse Accessibility Report'
    ])
}

/**
 * Generate accessibility testing summary
 */
def generateAccessibilitySummary(boolean axePassed, boolean lighthousePassed, List violations, Map config) {
    def summary = """
    ============================================
    🔍 ACCESSIBILITY TESTING SUMMARY
    ============================================
    
    WCAG ${config.wcagLevel} Compliance Check
    
    Test Results:
    ${axePassed ? '  ✅ Axe-Core Tests: PASSED' : '  ❌ Axe-Core Tests: FAILED'}
    ${lighthousePassed ? '  ✅ Lighthouse CI: PASSED' : '  ❌ Lighthouse CI: FAILED'}
    
    Overall Status: ${axePassed && lighthousePassed ? '✅ PASSED' : '❌ FAILED'}
    """
    
    if (violations.size() > 0) {
        summary += """
    
    Violations Found:
    ${violations.collect { "  - ${it}" }.join('\n')}
    
    Action Required:
    1. Review the accessibility test reports
    2. Fix the violations according to WCAG ${config.wcagLevel} guidelines
    3. Run tests locally: npm run test:a11y
    4. Re-run the pipeline after fixes
    """
    }
    
    summary += """
    
    Resources:
    - Axe-Core Report: ${env.BUILD_URL}Axe-Core_Coverage_Report/
    - Lighthouse Report: ${env.BUILD_URL}Lighthouse_Accessibility_Report/
    - WCAG Guidelines: https://www.w3.org/WAI/WCAG21/quickref/?versions=${config.wcagLevel}
    
    ============================================
    """
    
    echo summary
    
    // Add to build description
    currentBuild.description = (currentBuild.description ?: '') + 
        "\n<br/>🔍 A11y: ${axePassed && lighthousePassed ? '✅ PASSED' : '❌ FAILED'}"
}

/**
 * Record accessibility metrics for DORA/DevLake
 */
def recordAccessibilityMetrics(Map results, Map config) {
    def devlakeApiUrl = env.DEVLAKE_API_URL ?: 'http://devlake.fawkes-devlake.svc:8080'
    
    try {
        httpRequest(
            url: "${devlakeApiUrl}/api/plugins/webhook/1/quality",
            httpMode: 'POST',
            contentType: 'APPLICATION_JSON',
            requestBody: """
            {
                "service": "${config.appName ?: env.JOB_BASE_NAME}",
                "commit_sha": "${env.GIT_COMMIT}",
                "branch": "${env.BRANCH_NAME}",
                "build_number": "${env.BUILD_NUMBER}",
                "metric_type": "accessibility",
                "axe_core_passed": ${results.axeCore},
                "lighthouse_passed": ${results.lighthouse},
                "timestamp": "${new Date().format("yyyy-MM-dd'T'HH:mm:ss'Z'", TimeZone.getTimeZone('UTC'))}",
                "url": "${env.BUILD_URL}"
            }
            """,
            validResponseCodes: '200:299'
        )
        echo "✅ Accessibility metrics recorded"
    } catch (Exception e) {
        echo "⚠️ Failed to record accessibility metrics: ${e.message}"
    }
}

return this
