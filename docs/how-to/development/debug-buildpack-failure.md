---
title: Debug Buildpack Failure
description: Troubleshoot and resolve Cloud Native Buildpack build failures
---

# Debug Buildpack Failure

## Goal

Identify and resolve failures when building container images using Cloud Native Buildpacks, enabling successful application deployment.

## Prerequisites

Before you begin, ensure you have:

- [ ] Access to the CI/CD system (Jenkins) where the build failed
- [ ] Build logs from the failed buildpack execution
- [ ] Source code repository access
- [ ] `pack` CLI installed locally (optional, for local testing)
- [ ] Docker installed locally (for local debugging)

## Steps

### 1. Locate the Build Failure

#### Access Jenkins Build Logs

```bash
# Get Jenkins URL
echo "https://jenkins.127.0.0.1.nip.io"

# Navigate to the failed build
# Jobs → Your Pipeline → Build #XX → Console Output
```

Or using Jenkins CLI:

```bash
# Download Jenkins CLI
wget http://jenkins.127.0.0.1.nip.io/jnlpJars/jenkins-cli.jar

# Get build log
java -jar jenkins-cli.jar -s http://jenkins.127.0.0.1.nip.io \
  -auth admin:password \
  console my-pipeline 123  # build number
```

#### Identify the Failure Point

Look for error indicators in logs:

```text
[detector] ======== Results ========
[detector] fail: paketo-buildpacks/node-engine@1.0.0
[detector] ERROR: No buildpack groups passed detection.
[detector] ERROR: Please check that you are running against the correct path.
ERROR: failed to build: exit status 1
```

Common failure patterns:

- `No buildpack groups passed detection` - Buildpack couldn't detect project type
- `Unable to satisfy X dependency` - Missing dependency or version conflict
- `Error during build` - Build command failed
- `COPY failed` - File not found during build

### 2. Analyze the Error Message

#### Understand the Failure Type

| Error Pattern                          | Cause                                         | Section to Check                                       |
| -------------------------------------- | --------------------------------------------- | ------------------------------------------------------ |
| `No buildpack groups passed detection` | Wrong project structure or missing files      | [3. Detection Failures](#3-detection-failures)         |
| `Unable to satisfy dependency`         | Version constraints or unavailable dependency | [4. Dependency Issues](#4-dependency-issues)           |
| `Error: npm install failed`            | Node.js build error                           | [5. Build Command Failures](#5-build-command-failures) |
| `Permission denied`                    | File permission issues                        | [6. Permission Issues](#6-permission-issues)           |
| `Layer restoration failed`             | Cache corruption                              | [7. Cache Issues](#7-cache-issues)                     |

### 3. Detection Failures

If buildpack can't detect your project type:

#### Verify Required Files Exist

Different buildpacks require different files:

**Node.js (Paketo):**

```bash
# Required: package.json in repository root
ls -la package.json

# Verify package.json is valid JSON
cat package.json | jq .
```

**Java (Paketo):**

```bash
# Required: pom.xml (Maven) or build.gradle (Gradle)
ls -la pom.xml build.gradle

# For multi-module projects, ensure parent POM exists
```

**Python (Paketo):**

```bash
# Required: requirements.txt, Pipfile, or setup.py
ls -la requirements.txt Pipfile setup.py
```

**Go (Paketo):**

```bash
# Required: go.mod
ls -la go.mod
```

#### Fix: Add Missing Files

Create the required file for your project:

```bash
# Node.js example
cat > package.json <<EOF
{
  "name": "my-app",
  "version": "1.0.0",
  "main": "index.js",
  "scripts": {
    "start": "node index.js"
  },
  "dependencies": {
    "express": "^4.18.0"
  }
}
EOF

# Python example
cat > requirements.txt <<EOF
flask==2.3.0
gunicorn==21.2.0
EOF
```

### 4. Dependency Issues

If dependencies can't be resolved:

#### Check Version Constraints

```bash
# Node.js: View dependency versions
cat package.json | jq '.dependencies, .devDependencies'

# Python: Check requirements
cat requirements.txt

# Java: Check Maven dependencies
cat pom.xml | grep -A 5 "<dependencies>"
```

#### Fix: Update Dependency Versions

```bash
# Node.js: Use compatible versions
npm install express@4.18.0

# Python: Pin versions
echo "flask==2.3.0" >> requirements.txt

# Java: Update in pom.xml
<dependency>
  <groupId>org.springframework.boot</groupId>
  <artifactId>spring-boot-starter-web</artifactId>
  <version>3.1.0</version>
</dependency>
```

#### Verify Dependency Availability

```bash
# Node.js: Check if package exists in npm registry
npm view express versions --json

# Python: Check PyPI
pip index versions flask

# Java: Check Maven Central
curl https://search.maven.org/solrsearch/select?q=g:org.springframework.boot+AND+a:spring-boot-starter-web
```

### 5. Build Command Failures

If the build command itself fails:

#### Reproduce Locally

```bash
# Test build locally with pack CLI
pack build my-app:local \
  --builder paketobuildpacks/builder:base \
  --path .

# Or use docker
docker build -t my-app:local .
```

#### Check Build Logs for Specific Errors

Common build errors:

**Node.js:**

```text
ERROR: npm install failed
ENOENT: no such file or directory
```

**Fix:**

```bash
# Ensure all files are committed
git status

# Check .gitignore doesn't exclude required files
cat .gitignore

# Add missing files
git add src/config.js
git commit -m "fix: add missing config file"
```

**Python:**

```text
ERROR: Could not find a version that satisfies the requirement
```

**Fix:**

```bash
# Use compatible Python version
echo "python_version = \"3.11\"" > runtime.txt

# Or specify in buildpack config
cat > project.toml <<EOF
[[build.env]]
name = "BP_PYTHON_VERSION"
value = "3.11.*"
EOF
```

**Java:**

```text
ERROR: Compilation error
[ERROR] cannot find symbol
```

**Fix:**

```bash
# Build locally to identify error
mvn clean install

# Fix compilation errors in code
# Then commit and rebuild
```

### 6. Permission Issues

If build fails due to permissions:

```text
ERROR: Permission denied
COPY failed: stat /tmp/src/app: permission denied
```

#### Fix: Correct File Permissions

```bash
# Make files readable
chmod -R 644 .

# Make directories executable
find . -type d -exec chmod 755 {} \;

# Make scripts executable
chmod +x scripts/*.sh

# Commit permission changes
git add --chmod=+x scripts/entrypoint.sh
git commit -m "fix: make entrypoint executable"
```

### 7. Cache Issues

If layer restoration fails:

```text
ERROR: failed to restore cached layer
ERROR: layer restoration failed
```

#### Fix: Clear Build Cache

In Jenkins pipeline:

```groovy
stage('Build with Buildpack') {
    steps {
        sh '''
            # Clear buildpack cache
            pack build my-app:latest \
              --builder paketobuildpacks/builder:base \
              --clear-cache \
              --path .
        '''
    }
}
```

Or delete cache manually:

```bash
# In CI/CD environment
rm -rf /var/cache/buildpacks/*

# Rebuild without cache
```

### 8. Configure Buildpack Behavior

#### Create `project.toml`

Customize buildpack behavior with a configuration file:

```toml
# project.toml - place in repository root
[_]
schema-version = "0.2"

[[build.env]]
name = "BP_NODE_VERSION"
value = "20.*"

[[build.env]]
name = "BP_NPM_INSTALL_ARGS"
value = "--production"

[[build.buildpacks]]
uri = "docker://gcr.io/paketo-buildpacks/nodejs:latest"

[[build.buildpacks]]
uri = "docker://gcr.io/paketo-buildpacks/npm-install:latest"
```

Common configuration options:

**Node.js:**

```toml
[[build.env]]
name = "BP_NODE_VERSION"
value = "20.*"

[[build.env]]
name = "BP_NPM_INSTALL_ARGS"
value = "--production"
```

**Python:**

```toml
[[build.env]]
name = "BP_PYTHON_VERSION"
value = "3.11.*"

[[build.env]]
name = "BP_PIP_ARGS"
value = "--no-cache-dir"
```

**Java:**

```toml
[[build.env]]
name = "BP_JVM_VERSION"
value = "17.*"

[[build.env]]
name = "BP_MAVEN_BUILD_ARGUMENTS"
value = "clean install -DskipTests"
```

### 9. Test Locally Before Pushing

Always test buildpack builds locally:

```bash
# Install pack CLI
brew install buildpacks/tap/pack  # macOS
# or download from https://buildpacks.io/docs/tools/pack/

# Build locally
pack build my-app:test \
  --builder paketobuildpacks/builder:base \
  --path .

# Run container to verify
docker run -p 8080:8080 my-app:test

# Test endpoint
curl http://localhost:8080/health
```

## Verification

### 1. Verify Build Succeeds

```bash
# Re-run Jenkins build
# Or build locally
pack build my-app:verified \
  --builder paketobuildpacks/builder:base \
  --path .

# Should complete without errors
# Look for: Successfully built image my-app:verified
```

### 2. Verify Image Runs

```bash
# Run the built image
docker run -d -p 8080:8080 --name test-app my-app:verified

# Check container is running
docker ps | grep test-app

# Check logs for errors
docker logs test-app

# Test application endpoints
curl http://localhost:8080
curl http://localhost:8080/health

# Clean up
docker rm -f test-app
```

### 3. Verify Buildpack Metadata

```bash
# Inspect image for buildpack metadata
pack inspect my-app:verified

# Should show:
# - Buildpacks used
# - Runtime version
# - Build processes
# - Launch processes
```

### 4. Verify in CI/CD Pipeline

```bash
# Trigger Jenkins build
# Navigate to Console Output

# Verify all stages pass:
# [detector] ✓ paketo-buildpacks/node-engine
# [analyzer] ✓ Layer restoration successful
# [builder] ✓ Build completed successfully
# [exporter] ✓ Image exported
```

## Common Buildpack Issues and Solutions

### Issue: "No buildpack groups passed detection"

**Solution:**

```bash
# Ensure correct file structure
ls -la package.json  # Node.js
ls -la pom.xml       # Java
ls -la requirements.txt  # Python

# Specify builder explicitly
pack build my-app --builder paketobuildpacks/builder:full
```

### Issue: "Unable to satisfy node version"

**Solution:**

```toml
# Add to project.toml
[[build.env]]
name = "BP_NODE_VERSION"
value = "20.*"  # Use wildcard for flexibility
```

### Issue: "npm install fails with network error"

**Solution:**

```bash
# Configure npm registry
[[build.env]]
name = "NPM_CONFIG_REGISTRY"
value = "https://registry.npmjs.org"

# Or use .npmrc
echo "registry=https://registry.npmjs.org" > .npmrc
```

### Issue: "Out of memory during build"

**Solution:**

```groovy
// Increase memory in Jenkins pipeline
stage('Build') {
    environment {
        PACK_MEMORY_LIMIT = '4G'
    }
    steps {
        sh 'pack build my-app --memory 4G'
    }
}
```

## Troubleshooting Checklist

- [ ] Required manifest file exists (package.json, pom.xml, etc.)
- [ ] Manifest file is valid (JSON/XML syntax)
- [ ] Dependencies are available and versions are compatible
- [ ] Build commands succeed locally
- [ ] File permissions are correct
- [ ] No sensitive files in repository (check .gitignore)
- [ ] Buildpack version is up to date
- [ ] Correct builder is specified
- [ ] Cache is not corrupted

## Next Steps

After resolving buildpack issues:

- [Onboard Service to ArgoCD](../gitops/onboard-service-argocd.md) - Deploy your application
- [Configure Ingress TLS](../networking/configure-ingress-tls.md) - Expose your service
- [View DORA Metrics](../observability/view-dora-metrics-devlake.md) - Track deployment performance
- [Troubleshooting Guide](../../troubleshooting.md) - Additional debugging help

## Related Documentation

- [Continuous Delivery Pattern](../../patterns/continuous-delivery.md) - Build and deployment best practices
- [Jenkins Configuration](../../tools/jenkins.md) - CI/CD setup
- [Paketo Buildpacks Documentation](https://paketo.io/docs/) - Official buildpack docs
- [Cloud Native Buildpacks](https://buildpacks.io/) - CNB specification
