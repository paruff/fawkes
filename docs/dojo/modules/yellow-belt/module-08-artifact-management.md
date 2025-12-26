# Fawkes Dojo Module 8: Artifact Management

## 🎯 Module Overview

**Belt Level**: 🟡 Yellow Belt - CI/CD Mastery
**Module**: 4 of 4 (Yellow Belt - **FINAL MODULE**)
**Duration**: 60 minutes
**Difficulty**: Intermediate
**Prerequisites**:

- Modules 5, 6, 7 complete
- Understanding of Docker and containers
- Familiarity with versioning concepts
- CI/CD pipeline experience

---

## 📚 Learning Objectives

By the end of this module, you will:

1. ✅ Understand the role of artifact registries in CI/CD
2. ✅ Configure Harbor container registry in Fawkes
3. ✅ Implement semantic versioning strategies
4. ✅ Manage artifact lifecycle and retention policies
5. ✅ Implement artifact promotion across environments
6. ✅ Secure artifacts with signing and scanning
7. ✅ Optimize storage costs and performance

**DORA Capabilities Addressed**:

- ✓ CD1: Version control for production artifacts
- ✓ CD2: Automate deployment process
- ✓ Artifact Traceability

---

## 📖 Part 1: Why Artifact Management Matters

### The Problem: Ad-Hoc Artifact Storage

**Without proper artifact management**:

```
Team A: Stores Docker images on local machines
Team B: Uses random Docker Hub accounts
Team C: Rebuilds from source every time
Team D: No idea which version is in production

Result:
❌ Can't reproduce builds
❌ Can't rollback reliably
❌ No audit trail
❌ Security vulnerabilities untracked
❌ Storage costs out of control
```

### The Solution: Centralized Artifact Registry

```
                   ┌─────────────────────┐
                   │   Harbor Registry   │
                   │  (Fawkes Platform)  │
                   └──────────┬──────────┘
                              │
        ┌─────────────────────┼─────────────────────┐
        │                     │                     │
   ┌────▼────┐          ┌────▼────┐          ┌────▼────┐
   │   Dev   │          │ Staging │          │  Prod   │
   │ myapp:  │          │ myapp:  │          │ myapp:  │
   │  dev-123│          │  stg-123│          │  v1.2.3 │
   └─────────┘          └─────────┘          └─────────┘
```

**Benefits**:

- ✅ Single source of truth
- ✅ Immutable artifacts
- ✅ Complete audit trail
- ✅ Security scanning integrated
- ✅ Efficient storage with deduplication
- ✅ Role-based access control
- ✅ Replication for DR

---

## 🏗️ Part 2: Harbor Container Registry

### What is Harbor?

Harbor is an open-source container registry that secures artifacts with policies and role-based access control.

**Key Features**:

- 🐳 Docker/OCI image storage
- 🔒 Integrated security scanning (Trivy)
- 📊 Vulnerability management
- 🏷️ Image signing (Cosign/Notary)
- 📦 Helm chart repository
- 🔐 RBAC and quota management
- 📈 Audit logging
- 🌍 Replication across registries

### Harbor Architecture in Fawkes

```
┌──────────────────────────────────────────────────────┐
│                   Harbor Registry                     │
├──────────────────────────────────────────────────────┤
│                                                      │
│  ┌────────────┐  ┌────────────┐  ┌──────────────┐  │
│  │   Core     │  │  Registry  │  │   Trivy      │  │
│  │  Service   │  │  (Storage) │  │   Scanner    │  │
│  └──────┬─────┘  └──────┬─────┘  └──────┬───────┘  │
│         │                │                │          │
│  ┌──────▼────────────────▼────────────────▼───────┐ │
│  │           PostgreSQL Database                  │ │
│  │  • Image metadata  • Scan results  • Audit    │ │
│  └────────────────────────────────────────────────┘ │
│                                                      │
│  ┌──────────────────────────────────────────────┐  │
│  │        Object Storage (S3/MinIO)             │  │
│  │     • Image layers  • Helm charts            │  │
│  └──────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────┘
```

---

## 🛠️ Part 3: Hands-On Lab - Publishing Artifacts

### Step 1: Configure Harbor in Pipeline

```groovy
// vars/goldenPathJava.groovy (enhanced)
def call(Map config = [:]) {
    def defaults = [
        harborRegistry: 'harbor.fawkes.internal',
        harborProject: 'library',
        harborCredentials: 'harbor-robot-account',
        imagePrefix: '',
        pushToHarbor: true
    ]

    config = defaults + config

    pipeline {
        // ... agent configuration ...

        environment {
            HARBOR_REGISTRY = "${config.harborRegistry}"
            HARBOR_PROJECT = "${config.harborProject}"
            IMAGE_NAME = "${config.imagePrefix}${env.JOB_NAME}".replaceAll('/', '-')
        }

        stages {
            // ... build stages ...

            stage('Build Docker Image') {
                steps {
                    container('docker') {
                        script {
                            // Generate version tags
                            def shortCommit = env.GIT_COMMIT.take(7)
                            def buildTag = "${env.BUILD_NUMBER}-${shortCommit}"
                            def latestTag = env.BRANCH_NAME == 'main' ? 'latest' : env.BRANCH_NAME

                            env.IMAGE_TAG = buildTag
                            env.IMAGE_FULL = "${HARBOR_REGISTRY}/${HARBOR_PROJECT}/${IMAGE_NAME}:${buildTag}"

                            echo "🐳 Building: ${env.IMAGE_FULL}"
                            sh """
                                docker build \
                                    --label "version=${buildTag}" \
                                    --label "git-commit=${env.GIT_COMMIT}" \
                                    --label "build-url=${env.BUILD_URL}" \
                                    --label "built-by=fawkes-ci" \
                                    -t ${env.IMAGE_FULL} \
                                    -t ${HARBOR_REGISTRY}/${HARBOR_PROJECT}/${IMAGE_NAME}:${latestTag} \
                                    .
                            """
                        }
                    }
                }
            }

            stage('Push to Harbor') {
                when {
                    expression { config.pushToHarbor }
                }
                steps {
                    container('docker') {
                        script {
                            withCredentials([
                                usernamePassword(
                                    credentialsId: config.harborCredentials,
                                    usernameVariable: 'HARBOR_USER',
                                    passwordVariable: 'HARBOR_PASS'
                                )
                            ]) {
                                echo "📤 Pushing to Harbor..."
                                sh """
                                    echo \$HARBOR_PASS | docker login ${HARBOR_REGISTRY} -u \$HARBOR_USER --password-stdin
                                    docker push ${env.IMAGE_FULL}

                                    # Push additional tags
                                    docker push ${HARBOR_REGISTRY}/${HARBOR_PROJECT}/${IMAGE_NAME}:${env.BRANCH_NAME}
                                """
                            }
                        }
                    }
                }
            }

            stage('Harbor Scan & Sign') {
                steps {
                    script {
                        // Trigger Harbor vulnerability scan
                        sh """
                            curl -X POST \
                                -u \$HARBOR_USER:\$HARBOR_PASS \
                                "${HARBOR_REGISTRY}/api/v2.0/projects/${HARBOR_PROJECT}/repositories/${IMAGE_NAME}/artifacts/${env.IMAGE_TAG}/scan"
                        """

                        // Wait for scan completion
                        timeout(time: 5, unit: 'MINUTES') {
                            waitUntil {
                                def status = sh(
                                    script: """
                                        curl -s -u \$HARBOR_USER:\$HARBOR_PASS \
                                            "${HARBOR_REGISTRY}/api/v2.0/projects/${HARBOR_PROJECT}/repositories/${IMAGE_NAME}/artifacts/${env.IMAGE_TAG}" \
                                            | jq -r '.scan_overview."application/vnd.scanner.adapter.vuln.report.harbor+json; version=1.0".scan_status'
                                    """,
                                    returnStdout: true
                                ).trim()
                                return status == 'Success'
                            }
                        }

                        echo "✅ Harbor scan complete"
                    }
                }
            }
        }

        post {
            success {
                script {
                    echo """
                    ✅ Artifact published successfully!
                    📦 Image: ${env.IMAGE_FULL}
                    🔗 Harbor: ${HARBOR_REGISTRY}/harbor/projects/${HARBOR_PROJECT}/repositories/${IMAGE_NAME}
                    """
                }
            }
        }
    }
}
```

### Step 2: Verify in Harbor UI

Access Harbor: `https://harbor.fawkes.internal`

**Navigate to your image**:

1. Projects → Your Project
2. Repositories → Your Image
3. Click on tag (e.g., `123-abc1234`)

**View Details**:

- 📋 Vulnerabilities scan results
- 🏷️ Labels and metadata
- 📊 Layer information
- 🔒 Signature status
- 📈 Pull statistics

---

## 📊 Part 4: Versioning Strategies

### Semantic Versioning (SemVer)

**Format**: `MAJOR.MINOR.PATCH`

```
v1.2.3
│ │ │
│ │ └─ Patch: Bug fixes (backward compatible)
│ └─── Minor: New features (backward compatible)
└───── Major: Breaking changes
```

**Examples**:

- `v1.0.0` → Initial release
- `v1.0.1` → Bug fix
- `v1.1.0` → New feature added
- `v2.0.0` → Breaking API change

### Tagging Strategy

**Multiple tags per image**:

```bash
# Build number + commit (immutable reference)
myapp:142-abc1234

# Semantic version (for releases)
myapp:v1.2.3

# Environment-specific
myapp:dev
myapp:staging
myapp:production

# Branch-based
myapp:main
myapp:feature-auth

# Latest (moving target)
myapp:latest
```

### Implementing Versioning in Pipeline

```groovy
def generateImageTags() {
    def tags = []

    // Always add build number + commit
    def shortCommit = env.GIT_COMMIT.take(7)
    tags.add("${env.BUILD_NUMBER}-${shortCommit}")

    // Add semantic version if tagged
    if (env.TAG_NAME) {
        tags.add(env.TAG_NAME)

        // Also add major.minor
        def semver = env.TAG_NAME =~ /v?(\d+)\.(\d+)\.(\d+)/
        if (semver) {
            tags.add("v${semver[0][1]}.${semver[0][2]}")
            tags.add("v${semver[0][1]}")
        }
    }

    // Add branch name
    tags.add(env.BRANCH_NAME.replaceAll('/', '-'))

    // Add 'latest' for main branch
    if (env.BRANCH_NAME == 'main') {
        tags.add('latest')
    }

    return tags
}

stage('Build & Tag') {
    steps {
        script {
            def tags = generateImageTags()
            def imageBase = "${HARBOR_REGISTRY}/${HARBOR_PROJECT}/${IMAGE_NAME}"

            // Build with first tag
            sh "docker build -t ${imageBase}:${tags[0]} ."

            // Add additional tags
            tags.drop(1).each { tag ->
                sh "docker tag ${imageBase}:${tags[0]} ${imageBase}:${tag}"
            }

            // Push all tags
            tags.each { tag ->
                sh "docker push ${imageBase}:${tag}"
            }
        }
    }
}
```

---

## 🔄 Part 5: Artifact Promotion

### Environment Promotion Pattern

**Concept**: Same artifact progresses through environments

```
Build → Dev → Test → Staging → Production
 │       │      │       │          │
 v142    v142   v142    v142      v142
         ↓                         ↓
      promote               final promote
```

**Never rebuild** - same artifact, different tags/environment

### Implementing Promotion

```groovy
def promoteArtifact(Map config) {
    def sourceTag = config.sourceTag
    def targetTag = config.targetTag
    def imageBase = "${HARBOR_REGISTRY}/${HARBOR_PROJECT}/${IMAGE_NAME}"

    echo "🔄 Promoting ${imageBase}:${sourceTag} → ${targetTag}"

    // Pull source image
    sh "docker pull ${imageBase}:${sourceTag}"

    // Re-tag for target environment
    sh "docker tag ${imageBase}:${sourceTag} ${imageBase}:${targetTag}"

    // Push to Harbor
    sh "docker push ${imageBase}:${targetTag}"

    // Update GitOps manifest
    sh """
        git clone https://github.com/org/gitops-manifests.git
        cd gitops-manifests

        # Update image tag in manifest
        yq eval -i '.spec.template.spec.containers[0].image = "${imageBase}:${targetTag}"' \
            environments/${targetTag}/deployment.yaml

        git add .
        git commit -m "Promote ${IMAGE_NAME} to ${targetTag} (build ${sourceTag})"
        git push
    """

    echo "✅ Promotion complete"
}

// Usage
stage('Promote to Staging') {
    when {
        branch 'main'
    }
    steps {
        script {
            promoteArtifact(
                sourceTag: "${env.BUILD_NUMBER}-${env.GIT_COMMIT.take(7)}",
                targetTag: 'staging'
            )
        }
    }
}

stage('Promote to Production') {
    when {
        tag pattern: "v\\d+\\.\\d+\\.\\d+", comparator: "REGEXP"
    }
    steps {
        script {
            promoteArtifact(
                sourceTag: 'staging',
                targetTag: 'production'
            )
        }
    }
}
```

### Approval Gates

Add manual approval for production:

```groovy
stage('Approve Production Deploy') {
    when {
        tag pattern: "v\\d+\\.\\d+\\.\\d+", comparator: "REGEXP"
    }
    steps {
        script {
            def approved = input(
                message: 'Deploy to Production?',
                parameters: [
                    booleanParam(
                        name: 'DEPLOY',
                        defaultValue: false,
                        description: 'Check to approve production deployment'
                    ),
                    text(
                        name: 'NOTES',
                        defaultValue: '',
                        description: 'Deployment notes (optional)'
                    )
                ]
            )

            if (!approved.DEPLOY) {
                error("Production deployment not approved")
            }

            echo "Deployment approved by: ${env.BUILD_USER}"
            echo "Notes: ${approved.NOTES}"
        }
    }
}
```

---

## 🗄️ Part 6: Retention Policies

### Why Retention Policies Matter

**Without retention**:

```
Day 1:   10 images  → 1 GB
Day 30:  300 images → 30 GB
Day 90:  900 images → 90 GB
Day 365: 3650 images → 365 GB 💸💸💸
```

**With retention**:

```
Day 1:   10 images → 1 GB
Day 365: 100 images → 10 GB ✅
```

### Harbor Retention Rules

Configure in Harbor UI or via API:

**Example Policy**:

```yaml
retention_policy:
  - scope: "**" # All repositories
    rules:
      # Keep production images indefinitely
      - tag: "production"
        retain: -1 # Forever

      # Keep staging images for 30 days
      - tag: "staging"
        retain: 30

      # Keep latest 10 dev images
      - tag: "dev-*"
        retain_count: 10

      # Keep semantic versions for 1 year
      - tag: "v*.*.*"
        retain: 365

      # Delete untagged images after 7 days
      - tag: ""
        retain: 7
```

### Implementing Retention via API

```groovy
stage('Configure Retention') {
    steps {
        script {
            def retentionPolicy = '''
            {
                "rules": [
                    {
                        "disabled": false,
                        "action": "retain",
                        "tag_selectors": [{
                            "kind": "doublestar",
                            "decoration": "matches",
                            "pattern": "production"
                        }],
                        "scope_selectors": {
                            "repository": [{
                                "kind": "doublestar",
                                "decoration": "matches",
                                "pattern": "**"
                            }]
                        }
                    },
                    {
                        "disabled": false,
                        "action": "retain",
                        "tag_selectors": [{
                            "kind": "doublestar",
                            "decoration": "matches",
                            "pattern": "v*.*.*"
                        }],
                        "scope_selectors": {
                            "repository": [{
                                "kind": "doublestar",
                                "decoration": "matches",
                                "pattern": "**"
                            }]
                        },
                        "template": "retain_n",
                        "params": {"n": 10}
                    }
                ]
            }
            '''

            sh """
                curl -X POST \
                    -H "Content-Type: application/json" \
                    -u \$HARBOR_USER:\$HARBOR_PASS \
                    -d '${retentionPolicy}' \
                    "${HARBOR_REGISTRY}/api/v2.0/projects/${HARBOR_PROJECT}/retention"
            """
        }
    }
}
```

---

## 🔒 Part 7: Artifact Signing & Verification

### Why Sign Artifacts?

**Without signing**:

```
❌ Can't verify artifact authenticity
❌ Don't know who published it
❌ Can't detect tampering
❌ Supply chain vulnerable
```

**With signing**:

```
✅ Cryptographically verify origin
✅ Detect any modifications
✅ Enforce only signed images run
✅ Complete audit trail
```

### Signing with Cosign

**Install Cosign**:

```bash
# In pipeline
curl -sSL https://github.com/sigstore/cosign/releases/download/v2.0.0/cosign-linux-amd64 \
    -o /usr/local/bin/cosign
chmod +x /usr/local/bin/cosign
```

**Generate Key Pair** (one-time setup):

```bash
cosign generate-key-pair
# Creates: cosign.key (private) and cosign.pub (public)
# Store private key in Jenkins credentials
```

**Sign Image in Pipeline**:

```groovy
stage('Sign Image') {
    steps {
        container('cosign') {
            withCredentials([
                file(credentialsId: 'cosign-private-key', variable: 'COSIGN_KEY'),
                string(credentialsId: 'cosign-password', variable: 'COSIGN_PASSWORD')
            ]) {
                sh """
                    cosign sign \
                        --key \${COSIGN_KEY} \
                        --yes \
                        ${env.IMAGE_FULL}
                """
            }
        }
    }
}
```

**Verify Signature**:

```bash
# In deployment pipeline
cosign verify \
    --key cosign.pub \
    harbor.fawkes.internal/library/myapp:v1.2.3
```

### Kubernetes Admission Control

Enforce only signed images:

```yaml
# Kyverno policy
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: verify-signed-images
spec:
  validationFailureAction: enforce
  rules:
    - name: verify-signature
      match:
        resources:
          kinds:
            - Pod
      verifyImages:
        - imageReferences:
            - "harbor.fawkes.internal/*"
          attestors:
            - entries:
                - keys:
                    publicKeys: |-
                      -----BEGIN PUBLIC KEY-----
                      [Your Cosign Public Key]
                      -----END PUBLIC KEY-----
```

---

## 📈 Part 8: Monitoring & Metrics

### Key Artifact Metrics

```promql
# Artifact publish rate
rate(artifacts_published_total[5m])

# Artifact size over time
avg(artifact_size_bytes) by (repository)

# Pull count by artifact
sum(artifact_pulls_total) by (repository, tag)

# Storage usage by project
sum(storage_used_bytes) by (project)

# Vulnerability count by severity
sum(vulnerabilities_total) by (severity, repository)

# Artifact age
time() - artifact_push_timestamp_seconds
```

### Grafana Dashboard

```json
{
  "dashboard": {
    "title": "Artifact Registry Metrics",
    "panels": [
      {
        "title": "Daily Artifact Publishes",
        "targets": [
          {
            "expr": "sum(rate(artifacts_published_total[1d]))"
          }
        ],
        "type": "graph"
      },
      {
        "title": "Storage Usage by Project",
        "targets": [
          {
            "expr": "sum(storage_used_bytes) by (project) / 1024/1024/1024"
          }
        ],
        "type": "piechart",
        "unit": "GB"
      },
      {
        "title": "Most Pulled Images",
        "targets": [
          {
            "expr": "topk(10, sum(rate(artifact_pulls_total[7d])) by (repository))"
          }
        ],
        "type": "table"
      },
      {
        "title": "Vulnerabilities by Severity",
        "targets": [
          {
            "expr": "sum(vulnerabilities_total) by (severity)"
          }
        ],
        "type": "bargauge"
      }
    ]
  }
}
```

### Alerting Rules

```yaml
groups:
  - name: artifact_alerts
    rules:
      - alert: HighVulnerabilityCount
        expr: sum(vulnerabilities_total{severity="critical"}) > 10
        for: 1h
        annotations:
          summary: "High number of critical vulnerabilities"
          description: "{{ $value }} critical vulnerabilities detected"

      - alert: StorageQuotaExceeded
        expr: storage_used_bytes / storage_quota_bytes > 0.9
        for: 15m
        annotations:
          summary: "Storage quota 90% full"
          description: "Project {{ $labels.project }} is at {{ $value }}% capacity"

      - alert: ArtifactNotPulled
        expr: |
          time() - artifact_last_pull_timestamp_seconds{tag="production"} > 86400*30
        for: 1h
        annotations:
          summary: "Production artifact not pulled in 30 days"
          description: "{{ $labels.repository }}:{{ $labels.tag }} may be orphaned"
```

---

## 💪 Part 9: Practical Exercise

### Exercise: Complete Artifact Lifecycle

**Objective**: Implement full artifact management lifecycle

**Requirements**:

1. Build and tag Docker image with multiple tags
2. Push to Harbor with metadata labels
3. Trigger and verify Harbor security scan
4. Sign image with Cosign
5. Implement artifact promotion (dev → staging → prod)
6. Configure retention policy
7. Set up monitoring for artifact metrics

**Starter Template**:

```groovy
@Library('fawkes-pipelines') _

pipeline {
    agent {
        kubernetes {
            yaml '''
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: docker
    image: docker:24-dind
    securityContext:
      privileged: true
  - name: cosign
    image: gcr.io/projectsigstore/cosign:latest
'''
        }
    }

    environment {
        HARBOR_REGISTRY = 'harbor.fawkes.internal'
        HARBOR_PROJECT = 'library'
        IMAGE_NAME = 'myapp'
    }

    stages {
        stage('Checkout') {
            steps {
                git 'https://github.com/myorg/myapp.git'
            }
        }

        stage('Build & Tag') {
            steps {
                // TODO: Build with multiple tags
            }
        }

        stage('Push to Harbor') {
            steps {
                // TODO: Push all tags
            }
        }

        stage('Scan & Sign') {
            steps {
                // TODO: Trigger Harbor scan and sign with Cosign
            }
        }

        stage('Promote to Staging') {
            when {
                branch 'main'
            }
            steps {
                // TODO: Promote artifact
            }
        }
    }
}
```

**Validation Criteria**:

- [ ] Image built and tagged correctly
- [ ] All tags pushed to Harbor
- [ ] Harbor scan completed successfully
- [ ] Image signed with Cosign
- [ ] Signature verifiable
- [ ] Artifact promoted correctly
- [ ] Retention policy configured
- [ ] Metrics visible in Grafana

---

## 🎓 Part 10: Knowledge Check

### Quiz Questions

1. **What is the purpose of an artifact registry?**

   - [ ] Store source code
   - [x] Store and manage build artifacts (images, packages)
   - [ ] Run containers
   - [ ] Deploy applications

2. **What is semantic versioning format?**

   - [ ] BUILD.DATE.TIME
   - [x] MAJOR.MINOR.PATCH
   - [ ] YEAR.MONTH.DAY
   - [ ] VERSION.RELEASE.BUILD

3. **Why should you use the same artifact across environments?**

   - [ ] Save disk space
   - [ ] Faster builds
   - [x] Ensure consistency and avoid "works on my machine"
   - [ ] Easier to debug

4. **What does artifact signing provide?**

   - [ ] Faster downloads
   - [ ] Smaller file size
   - [x] Verification of authenticity and integrity
   - [ ] Automatic deployment

5. **Why implement retention policies?**

   - [x] Control storage costs and remove unused artifacts
   - [ ] Make builds faster
   - [ ] Improve security
   - [ ] All of the above

6. **What is artifact promotion?**

   - [ ] Marketing the artifact
   - [x] Moving same artifact through environments without rebuilding
   - [ ] Upgrading to newer version
   - [ ] Deleting old versions

7. **What tool does Fawkes use for container registry?**

   - [ ] Docker Hub
   - [ ] Artifactory
   - [x] Harbor
   - [ ] Nexus

8. **What is the benefit of tagging with build number + commit SHA?**
   - [ ] Looks professional
   - [ ] Required by Docker
   - [x] Provides immutable, traceable reference
   - [ ] Makes images smaller

**Answers**: 1-B, 2-B, 3-C, 4-C, 5-A, 6-B, 7-C, 8-C

---

## 🎯 Part 11: Module Summary & Next Steps

### What You Learned

✅ **Artifact Registries**: Centralized, secure storage for build artifacts
✅ **Harbor**: Configuration and usage in Fawkes platform
✅ **Versioning**: Semantic versioning and tagging strategies
✅ **Promotion**: Moving artifacts through environments
✅ **Retention**: Lifecycle management and cost optimization
✅ **Signing**: Cryptographic verification with Cosign
✅ **Monitoring**: Tracking artifact metrics and health

### DORA Capabilities Achieved

- ✅ **CD1**: Version control for production artifacts (complete)
- ✅ **CD2**: Automated deployment with immutable artifacts
- ✅ **Traceability**: Complete audit trail from build to production

### Key Takeaways

1. **Artifacts are immutable** - Never rebuild, always promote
2. **Tag everything** - Multiple tags for different purposes
3. **Sign your artifacts** - Prevent supply chain attacks
4. **Lifecycle management** - Retention policies save money
5. **Monitor your registry** - Track usage, vulnerabilities, costs

### Real-World Impact

"After implementing proper artifact management:

- **Build reproducibility**: 60% → 100%
- **Deployment confidence**: 70% → 95%
- **Storage costs**: $5,000/month → $800/month
- **Time to rollback**: 30 min → 2 min
- **Supply chain security**: Significantly improved with signing

We can now trace every production artifact back to exact source code commit."

- _DevOps Team, E-Commerce Platform_

---

## 🎉 Yellow Belt Complete

### 🏆 Congratulations

You've completed all four Yellow Belt modules:

- ✅ Module 5: CI Fundamentals
- ✅ Module 6: Golden Path Pipelines
- ✅ Module 7: Security Scanning & Quality Gates
- ✅ Module 8: Artifact Management

### 🎖️ Yellow Belt Progress

```
Yellow Belt: CI/CD Mastery
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Module 5: CI Fundamentals        ████████░░░░ 25% ✓
Module 6: Golden Path Pipelines  ████████░░░░ 50% ✓
Module 7: Security & Quality     ████████░░░░ 75% ✓
Module 8: Artifact Management    ████████████ 100% ✓
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### 📜 Yellow Belt Certification

**You're now ready for the Yellow Belt Certification Exam!**

**Exam Format**:

- 40 multiple choice questions
- 3 hands-on challenges
- 85% passing score required
- 2-hour time limit

**Exam Challenges**:

1. Build a production-ready CI/CD pipeline from scratch
2. Optimize existing pipeline to <5 minute build time
3. Implement complete security scanning and artifact management

**Schedule Your Exam**:

- Visit Fawkes Dojo Portal
- Navigate to Certifications → Yellow Belt
- Click "Schedule Exam"

### 🎓 What You've Achieved

**Skills Mastered**:

- ✅ Jenkins pipeline development
- ✅ Shared library creation
- ✅ Security scanning integration
- ✅ Artifact management
- ✅ Pipeline optimization
- ✅ CI/CD best practices

**DORA Impact**:

- **Deployment Frequency**: Can deploy multiple times per day
- **Lead Time**: Reduced to minutes with optimized pipelines
- **Change Failure Rate**: Security gates prevent bad code
- **MTTR**: Artifact management enables fast rollbacks

### 🚀 What's Next?

**Option 1: Take Yellow Belt Certification Exam**

- Validate your learning
- Earn "Fawkes CI/CD Specialist" badge
- Get LinkedIn-verified credential

**Option 2: Continue to Green Belt**

- Module 9: GitOps with ArgoCD
- Module 10: Deployment Strategies
- Module 11: Progressive Delivery
- Module 12: Rollback & Incident Response

**Option 3: Practice & Contribute**

- Apply learnings to your team's pipelines
- Share your shared library with community
- Write blog post about your journey
- Help others in #yellow-belt channel

---

## 📚 Additional Resources

### Tools & Documentation

- [Harbor Documentation](https://goharbor.io/docs/)
- [Cosign Documentation](https://docs.sigstore.dev/cosign/overview/)
- [Semantic Versioning](https://semver.org/)
- [OCI Image Spec](https://github.com/opencontainers/image-spec)

### Learning Resources

- [Artifact Management Best Practices](https://www.jfrog.com/confluence/display/JFROG/Best+Practices)
- [Supply Chain Security](https://slsa.dev/)
- [Container Signing Tutorial](https://www.sigstore.dev/get-started)

### Community

- [Fawkes Mattermost](https://mattermost.fawkes.internal) - #yellow-belt
- Share your certification achievement!
- Help newcomers in #white-belt

---

## 📖 Appendix: Artifact Management Cheat Sheet

### Quick Reference Commands

**Harbor CLI (via API)**:

```bash
# List repositories
curl -u user:pass https://harbor.fawkes.internal/api/v2.0/projects/library/repositories

# Get artifact details
curl -u user:pass https://harbor.fawkes.internal/api/v2.0/projects/library/repositories/myapp/artifacts/v1.2.3

# Trigger scan
curl -X POST -u user:pass https://harbor.fawkes.internal/api/v2.0/projects/library/repositories/myapp/artifacts/v1.2.3/scan

# Delete artifact
curl -X DELETE -u user:pass https://harbor.fawkes.internal/api/v2.0/projects/library/repositories/myapp/artifacts/v1.2.3
```

**Cosign Commands**:

```bash
# Sign image
cosign sign --key cosign.key myapp:v1.2.3

# Verify signature
cosign verify --key cosign.pub myapp:v1.2.3

# Attach SBOM
cosign attach sbom --sbom sbom.json myapp:v1.2.3

# Download SBOM
cosign download sbom myapp:v1.2.3
```

**Docker Tag Management**:

```bash
# Create multiple tags
docker tag myapp:123 myapp:v1.2.3
docker tag myapp:123 myapp:latest
docker tag myapp:123 myapp:production

# Push all tags
docker push --all-tags myapp
```

---

## 🎊 Final Thoughts

You've completed an intensive journey through CI/CD mastery. You now have the skills to:

- Build production-ready pipelines
- Implement security at every stage
- Manage artifacts professionally
- Optimize for speed and reliability
- Lead CI/CD initiatives in your organization

**Your impact on DORA metrics will be significant!**

---

**Ready to continue?** 🟢

Next up: **Green Belt - GitOps & Deployment**

Module 9: Introduction to GitOps with ArgoCD awaits! You'll learn declarative deployments, automated sync, and progressive delivery strategies.

---

_Fawkes Dojo - Where Platform Engineers Are Forged_
_Version 1.0 | Last Updated: October 2025_
_License: MIT | https://github.com/paruff/fawkes_

**🎉 Yellow Belt Complete - Congratulations, CI/CD Specialist! 🎉**
