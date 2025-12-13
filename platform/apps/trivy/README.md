# Trivy - Container Security Scanner

## Purpose

Trivy provides comprehensive vulnerability scanning for container images, filesystems, and Git repositories. It's integrated into the CI/CD pipeline to ensure all deployed containers meet security standards.

## Key Features

- **Vulnerability Detection**: Scan for CVEs in OS packages and application dependencies
- **Misconfiguration Detection**: Detect IaC misconfigurations (Kubernetes, Terraform, Docker)
- **Secret Detection**: Find hardcoded secrets and credentials
- **SBOM Generation**: Software Bill of Materials in SPDX/CycloneDX
- **Multiple Targets**: Images, filesystems, repositories, Kubernetes clusters
- **Fast Scanning**: Cached DB for quick scans

## Quick Start

### Scan Container Image

```bash
# Scan image from registry
trivy image myapp:latest

# Scan with severity filter
trivy image --severity HIGH,CRITICAL myapp:latest

# Generate JSON report
trivy image -f json -o report.json myapp:latest
```

### Scan Kubernetes Cluster

```bash
# Scan all workloads in namespace
trivy k8s --namespace fawkes

# Generate report
trivy k8s --report summary --namespace fawkes
```

### Scan IaC Files

```bash
# Scan Terraform
trivy config infra/terraform/

# Scan Kubernetes manifests
trivy config platform/apps/
```

## Integration with Jenkins

Trivy is integrated into the Golden Path CI/CD pipeline:

```groovy
stage('Security Scan') {
    steps {
        script {
            // Build image
            def image = docker.build("myapp:${BUILD_NUMBER}")
            
            // Scan with Trivy
            sh """
                trivy image \
                  --exit-code 1 \
                  --severity HIGH,CRITICAL \
                  --format json \
                  --output trivy-report.json \
                  myapp:${BUILD_NUMBER}
            """
            
            // Archive report
            archiveArtifacts artifacts: 'trivy-report.json'
        }
    }
}
```

### Quality Gates

The pipeline fails if:
- **CRITICAL** vulnerabilities found: Immediate failure
- **HIGH** vulnerabilities > 5: Failure
- **MEDIUM** vulnerabilities > 20: Warning

## Integration with Harbor

Harbor uses Trivy as the default scanner:

```yaml
# Harbor scanner configuration
scanner:
  trivy:
    enabled: true
    image:
      repository: aquasec/trivy
      tag: latest
    scanOnPush: true
```

All images pushed to Harbor are automatically scanned.

## SBOM Generation

Generate Software Bill of Materials for compliance:

```bash
# Generate SBOM in SPDX format
trivy image --format spdx-json -o sbom.spdx.json myapp:latest

# Generate SBOM in CycloneDX format
trivy image --format cyclonedx -o sbom.cyclonedx.json myapp:latest
```

## Vulnerability Database

Trivy downloads and caches the vulnerability database:

```bash
# Update database
trivy image --download-db-only

# Check database version
trivy version --format json | jq .VulnerabilityDB
```

## Scanning Strategies

### Pre-Commit Scanning

Scan before committing code:

```yaml
# .pre-commit-config.yaml
repos:
  - repo: local
    hooks:
      - id: trivy
        name: Trivy filesystem scan
        entry: trivy fs --exit-code 1 .
        language: system
        pass_filenames: false
```

### Scheduled Scanning

Regular scans of running containers:

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: trivy-scan
spec:
  schedule: "0 2 * * *"  # Daily at 2 AM
  jobTemplate:
    spec:
      template:
        spec:
          containers:
            - name: trivy
              image: aquasec/trivy:latest
              command:
                - trivy
                - k8s
                - --namespace
                - fawkes
```

## Reporting

Generate various report formats:

```bash
# Table format (default)
trivy image myapp:latest

# JSON format
trivy image -f json myapp:latest

# SARIF format (for GitHub Security)
trivy image -f sarif myapp:latest

# Template format
trivy image -f template --template "@contrib/gitlab.tpl" myapp:latest
```

## Ignoring Vulnerabilities

Create `.trivyignore` file to suppress false positives:

```text
# Ignore specific CVE
CVE-2021-12345

# Ignore with expiration
CVE-2021-67890 exp:2024-12-31

# Ignore with reason
CVE-2021-11111 # Fixed in next release
```

## Troubleshooting

### Database Update Failures

```bash
# Check database path
trivy image --cache-dir /path/to/cache myapp:latest

# Clear cache and re-download
rm -rf ~/.cache/trivy
trivy image --download-db-only
```

### High Memory Usage

Trivy can use significant memory for large images:

```bash
# Limit memory usage
trivy image --timeout 10m --slow myapp:latest
```

### Offline Scanning

For air-gapped environments:

```bash
# Download database
trivy image --download-db-only

# Copy database to air-gapped system
cp -r ~/.cache/trivy /path/to/airgap/

# Use offline database
trivy image --cache-dir /path/to/airgap/trivy myapp:latest
```

## Metrics and Monitoring

Trivy exports metrics for monitoring:

```yaml
# ServiceMonitor
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: trivy
spec:
  selector:
    matchLabels:
      app: trivy
  endpoints:
    - port: metrics
      interval: 30s
```

## Related Documentation

- [Trivy Documentation](https://aquasecurity.github.io/trivy/)
- [Trivy GitHub](https://github.com/aquasecurity/trivy)
- [ADR-005: Container Security Scanning](../../../docs/adr/005-container-security.md)
