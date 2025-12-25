# ============================================================
# Jenkins Webhook Configuration for DORA Metrics
# ============================================================
# This document provides instructions for using the Jenkins
# shared library to send CI/CD events to DevLake
#
# Events captured:
# - Build completion → Build success rate
# - Test results → Test flakiness
# - Quality gates → Code quality metrics
# - Pipeline retries → Rework rate
# ============================================================

## Overview

Jenkins integration for DORA metrics is implemented via the **doraMetrics.groovy** shared library. This library sends webhook events to DevLake during pipeline execution to track CI/CD metrics.

**Key Point**: In Fawkes GitOps architecture:
- **ArgoCD** tracks deployment metrics (deployment frequency, lead time)
- **Jenkins** tracks CI metrics (build success, rework, quality gates)

## Webhook Endpoint

**DevLake Webhook URL**: `http://devlake.fawkes-devlake.svc:8080/api/plugins/webhook/1/cicd`

This endpoint is accessible from within the Kubernetes cluster.

## Shared Library Usage

The `doraMetrics.groovy` library is already available in all Jenkins pipelines via the `fawkes-pipeline-library`.

### Available Functions

#### 1. recordBuild - Track Build Events

Records a build event for build success rate and duration tracking.

```groovy
doraMetrics.recordBuild(
    service: 'my-service',
    status: 'success',  // 'success', 'failure', 'unstable'
    stage: 'build'      // 'build', 'test', 'scan', 'package'
)
```

**When to use**: After each major build stage completes.

#### 2. recordQualityGate - Track Quality Gate Results

Records SonarQube quality gate results.

```groovy
doraMetrics.recordQualityGate(
    service: 'my-service',
    passed: true,
    coveragePercent: 85,
    bugs: 2,
    vulnerabilities: 0
)
```

**When to use**: After SonarQube analysis completes.

#### 3. recordTestResults - Track Test Execution

Records test execution results for flakiness tracking.

```groovy
doraMetrics.recordTestResults(
    service: 'my-service',
    totalTests: 150,
    passedTests: 148,
    failedTests: 2,
    flakyTests: 1  // Tests that passed on retry
)
```

**When to use**: After test execution completes.

#### 4. recordIncident - Track CI/CD Incidents

Records incidents for MTTR tracking (typically for severe failures).

```groovy
doraMetrics.recordIncident(
    service: 'my-service',
    severity: 'high',      // 'high', 'medium', 'low'
    status: 'open',        // 'open', 'resolved'
    title: 'Build failure: out of memory'
)
```

**When to use**: For severe build failures that require investigation.

#### 5. recordPipelineComplete - Summary Tracking

Records complete pipeline execution summary.

```groovy
doraMetrics.recordPipelineComplete(
    service: 'my-service'
)
```

**When to use**: At the end of the pipeline in a `post` block.

## Example Jenkinsfile Integration

### Minimal Integration

```groovy
@Library('fawkes-pipeline-library') _

pipeline {
    agent { label 'k8s-agent' }

    stages {
        stage('Build') {
            steps {
                sh 'mvn clean package'
            }
            post {
                success {
                    doraMetrics.recordBuild(
                        service: env.JOB_BASE_NAME,
                        status: 'success',
                        stage: 'build'
                    )
                }
                failure {
                    doraMetrics.recordBuild(
                        service: env.JOB_BASE_NAME,
                        status: 'failure',
                        stage: 'build'
                    )
                }
            }
        }

        stage('Test') {
            steps {
                sh 'mvn test'
            }
        }
    }

    post {
        always {
            doraMetrics.recordPipelineComplete(
                service: env.JOB_BASE_NAME
            )
        }
    }
}
```

### Full Integration with All Metrics

```groovy
@Library('fawkes-pipeline-library') _

pipeline {
    agent { label 'maven' }

    environment {
        SERVICE_NAME = 'payment-service'
    }

    stages {
        stage('Build') {
            steps {
                script {
                    sh 'mvn clean package'
                }
            }
            post {
                success {
                    doraMetrics.recordBuild(
                        service: env.SERVICE_NAME,
                        status: 'success',
                        stage: 'build'
                    )
                }
                failure {
                    doraMetrics.recordBuild(
                        service: env.SERVICE_NAME,
                        status: 'failure',
                        stage: 'build'
                    )
                    doraMetrics.recordIncident(
                        service: env.SERVICE_NAME,
                        severity: 'high',
                        status: 'open',
                        title: 'Build failed'
                    )
                }
            }
        }

        stage('Test') {
            steps {
                script {
                    sh 'mvn test'

                    // Parse test results
                    def testResults = junit 'target/surefire-reports/*.xml'

                    doraMetrics.recordTestResults(
                        service: env.SERVICE_NAME,
                        totalTests: testResults.totalCount,
                        passedTests: testResults.passCount,
                        failedTests: testResults.failCount,
                        skippedTests: testResults.skipCount,
                        flakyTests: 0  // Implement flaky test detection
                    )
                }
            }
        }

        stage('SonarQube Analysis') {
            steps {
                script {
                    withSonarQubeEnv('SonarQube') {
                        sh 'mvn sonar:sonar'
                    }

                    // Wait for quality gate
                    timeout(time: 5, unit: 'MINUTES') {
                        def qg = waitForQualityGate()

                        doraMetrics.recordQualityGate(
                            service: env.SERVICE_NAME,
                            passed: qg.status == 'OK',
                            coveragePercent: 85,  // Parse from SonarQube API
                            bugs: 2,
                            vulnerabilities: 0
                        )

                        if (qg.status != 'OK') {
                            error "Quality gate failed: ${qg.status}"
                        }
                    }
                }
            }
        }

        stage('Security Scan') {
            steps {
                script {
                    sh 'trivy image --exit-code 1 my-service:${env.BUILD_NUMBER}'
                }
            }
            post {
                success {
                    doraMetrics.recordBuild(
                        service: env.SERVICE_NAME,
                        status: 'success',
                        stage: 'scan'
                    )
                }
                failure {
                    doraMetrics.recordBuild(
                        service: env.SERVICE_NAME,
                        status: 'failure',
                        stage: 'scan'
                    )
                }
            }
        }

        stage('Package') {
            steps {
                script {
                    sh 'docker build -t my-service:${env.BUILD_NUMBER} .'
                    sh 'docker push my-service:${env.BUILD_NUMBER}'
                }
            }
            post {
                success {
                    doraMetrics.recordBuild(
                        service: env.SERVICE_NAME,
                        status: 'success',
                        stage: 'package'
                    )
                }
            }
        }
    }

    post {
        always {
            doraMetrics.recordPipelineComplete(
                service: env.SERVICE_NAME
            )
        }
        failure {
            doraMetrics.recordIncident(
                service: env.SERVICE_NAME,
                severity: 'medium',
                status: 'open',
                title: "Pipeline failed at stage ${env.STAGE_NAME}"
            )
        }
    }
}
```

### Using Golden Path Pipeline

The Golden Path pipeline automatically integrates DORA metrics:

```groovy
@Library('fawkes-pipeline-library') _

goldenPathPipeline {
    appName = 'payment-service'
    language = 'java'
    enableDoraMetrics = true  // Default: true
}
```

The Golden Path pipeline automatically calls:
- `recordBuild()` after each stage
- `recordTestResults()` after tests
- `recordQualityGate()` after SonarQube
- `recordPipelineComplete()` at the end

## Configuration

### Environment Variables

Set these in Jenkins global configuration or pipeline:

```groovy
environment {
    DEVLAKE_API_URL = 'http://devlake.fawkes-devlake.svc:8080'
    DEVLAKE_WEBHOOK_URL = 'http://devlake.fawkes-devlake.svc:8080'
}
```

**Default values** (used if not set):
- `DEVLAKE_API_URL`: `http://devlake.fawkes-devlake.svc:8080`
- `DEVLAKE_WEBHOOK_URL`: `http://devlake.fawkes-devlake.svc:8080`

### Network Access

Jenkins pods must have network access to DevLake service:

```yaml
# Already configured in platform/apps/devlake/config/webhooks.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: devlake-webhook-ingress
  namespace: fawkes-devlake
spec:
  podSelector:
    matchLabels:
      app.kubernetes.io/name: devlake
  ingress:
    - from:
        - namespaceSelector:
            matchLabels:
              name: fawkes
          podSelector:
            matchLabels:
              app.kubernetes.io/name: jenkins
      ports:
        - protocol: TCP
          port: 8080
```

## Webhook Payload Examples

### Build Event

```json
{
  "service": "payment-service",
  "commit_sha": "abc123def456",
  "branch": "main",
  "build_number": "42",
  "status": "success",
  "duration_ms": 120000,
  "stage": "build",
  "is_retry": false,
  "timestamp": "2024-12-15T10:30:00Z",
  "url": "http://jenkins.127.0.0.1.nip.io/job/payment-service/42/",
  "type": "ci_build"
}
```

### Quality Gate Event

```json
{
  "service": "payment-service",
  "commit_sha": "abc123def456",
  "build_number": "42",
  "quality_gate_passed": true,
  "coverage_percent": 85.5,
  "bugs": 2,
  "vulnerabilities": 0,
  "code_smells": 15,
  "duplicated_lines_percent": 3.2,
  "timestamp": "2024-12-15T10:35:00Z",
  "type": "quality_gate"
}
```

### Test Results Event

```json
{
  "service": "payment-service",
  "commit_sha": "abc123def456",
  "build_number": "42",
  "total_tests": 150,
  "passed_tests": 148,
  "failed_tests": 2,
  "skipped_tests": 0,
  "flaky_tests": 1,
  "duration_ms": 45000,
  "timestamp": "2024-12-15T10:32:00Z",
  "type": "test_results"
}
```

## Troubleshooting

### Webhook Events Not Being Sent

1. **Check plugin is installed**:
   ```bash
   kubectl exec -n fawkes jenkins-0 -- jenkins-plugin-cli --list | grep http_request
   ```
   The `http_request` plugin is required for webhook calls.

2. **Check network connectivity**:
   ```groovy
   // Add to pipeline for testing
   sh 'curl -v http://devlake.fawkes-devlake.svc:8080/api/ping'
   ```

3. **Check Jenkins logs**:
   ```bash
   kubectl logs -n fawkes jenkins-0 | grep "DORA"
   ```

### Webhook Failures in Logs

```
⚠️ DORA: Failed to record build event: Connection refused
```

**Solutions**:
- Verify DevLake is running: `kubectl get pods -n fawkes-devlake`
- Check network policy allows Jenkins → DevLake
- Verify service name: `kubectl get svc -n fawkes-devlake devlake`

### Missing DORA Metrics Calls

If using a custom Jenkinsfile, ensure you're calling the doraMetrics functions.

**Quick check**: Search pipeline code for `doraMetrics.record`

### Metrics Not Appearing in DevLake

1. **Verify webhook received**:
   ```bash
   kubectl logs -n fawkes-devlake -l app.kubernetes.io/component=lake | grep "cicd.*webhook"
   ```

2. **Check database**:
   ```sql
   SELECT * FROM cicd_deployments ORDER BY created_at DESC LIMIT 10;
   ```

3. **Query via API**:
   ```bash
   curl "http://devlake.127.0.0.1.nip.io/api/dora/rework?project=payment-service"
   ```

## Monitoring

### Jenkins Webhook Metrics

View in DevLake Grafana dashboard:
- **Dashboard**: DevLake Webhooks
- **Panel**: Jenkins CI Events

**Metrics**:
- Build events per hour
- Quality gate pass rate
- Test flakiness rate
- Average build duration

## Advanced Configuration

### Custom Webhook Headers

Add authentication or custom headers:

```groovy
// In doraMetrics.groovy (for customization)
httpRequest(
    url: "${devlakeApiUrl}/api/plugins/webhook/1/cicd",
    httpMode: 'POST',
    contentType: 'APPLICATION_JSON',
    customHeaders: [
        [name: 'X-API-Key', value: env.DEVLAKE_API_KEY],
        [name: 'X-Jenkins-Job', value: env.JOB_NAME]
    ],
    requestBody: payload
)
```

### Webhook Retry Logic

The doraMetrics library includes error handling:
- Catches exceptions
- Logs warnings (doesn't fail pipeline)
- No automatic retry (by design - metrics are best-effort)

To add retry logic:

```groovy
def recordWithRetry(Closure webhookCall) {
    int retries = 3
    for (int i = 0; i < retries; i++) {
        try {
            webhookCall()
            return
        } catch (Exception e) {
            if (i == retries - 1) {
                echo "⚠️ DORA: Failed after ${retries} retries: ${e.message}"
            } else {
                echo "⚠️ DORA: Retry ${i+1}/${retries} after error: ${e.message}"
                sleep(5)
            }
        }
    }
}

// Usage
recordWithRetry {
    doraMetrics.recordBuild(service: 'my-service', status: 'success')
}
```

## Validation

### Test Jenkins Integration

1. **Trigger a pipeline build**:
   ```bash
   # Via Jenkins UI or CLI
   jenkins-cli -s http://jenkins.127.0.0.1.nip.io build payment-service
   ```

2. **Check console output** for DORA messages:
   ```
   ✅ DORA: Build event recorded for payment-service (build)
   ✅ DORA: Test results recorded for payment-service (148/150 passed)
   ✅ DORA: Quality gate result recorded for payment-service (PASSED)
   ```

3. **Verify in DevLake**:
   ```bash
   curl "http://devlake.127.0.0.1.nip.io/api/dora/rework?project=payment-service"
   ```

4. **Check database**:
   ```sql
   SELECT service, status, stage, created_at
   FROM cicd_deployments
   WHERE service = 'payment-service'
   ORDER BY created_at DESC
   LIMIT 5;
   ```

## Related Documentation

- [doraMetrics.groovy Source Code](../../../../jenkins-shared-library/vars/doraMetrics.groovy)
- [Golden Path Pipeline](../../../../jenkins-shared-library/vars/goldenPathPipeline.groovy)
- [DevLake Webhooks Configuration](webhooks.yaml)
- [DORA Metrics API Reference](../../../docs/reference/dora-metrics-api.md)
- [Jenkins HTTP Request Plugin](https://plugins.jenkins.io/http_request/)
