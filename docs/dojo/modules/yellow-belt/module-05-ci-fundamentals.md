# Fawkes Dojo Module 5: Continuous Integration Fundamentals

## 🎯 Module Overview

**Belt Level**: 🟡 Yellow Belt - CI/CD Mastery  
**Module**: 1 of 4 (Yellow Belt)  
**Duration**: 60 minutes  
**Difficulty**: Intermediate  
**Prerequisites**: 
- White Belt certification complete
- Basic understanding of Git workflows
- Familiarity with build tools (Maven, npm, etc.)
- Command line comfort

---

## 📚 Learning Objectives

By the end of this module, you will:

1. ✅ Explain the principles and benefits of Continuous Integration
2. ✅ Understand Jenkins architecture and core concepts
3. ✅ Create your first Jenkinsfile (Pipeline as Code)
4. ✅ Configure build stages: checkout, build, test, package
5. ✅ Implement basic error handling and notifications
6. ✅ Understand how CI improves DORA metrics
7. ✅ Troubleshoot common CI pipeline failures

**DORA Capabilities Addressed**:
- ✓ CD3: Implement continuous integration
- ✓ CD1: Use version control for all production artifacts
- ✓ CD5: Trunk-based development methods

---

## 📖 Part 1: What is Continuous Integration?

### The Problem: Integration Hell

**Traditional development workflow**:
```
Developer A writes code for 2 weeks → Commits
Developer B writes code for 2 weeks → Commits
Developer C writes code for 2 weeks → Commits
                ↓
        Integration Day (Friday)
                ↓
      Merge conflicts, broken tests
      Incompatible changes, missing dependencies
                ↓
        Weekend fixing integration issues
```

**Result**: 
- Integration becomes painful and risky
- Feedback delayed by weeks
- Bugs found late, expensive to fix
- Releases delayed, stress increases

### Continuous Integration Solution

> **"Integrate early, integrate often"**

```
Developer A: Commits multiple times per day
         ↓
    Automated Build + Test
         ↓
    Immediate Feedback (5-10 min)
         ↓
    Fix issues immediately
         ↓
    Always in releasable state
```

### Core CI Principles

1. **Maintain a Single Source Repository**
   - All code in version control
   - One repo truth source
   - Branches short-lived (<1 day)

2. **Automate the Build**
   - One command builds everything
   - No manual steps
   - Repeatable and reliable

3. **Make Your Build Self-Testing**
   - Automated unit tests
   - Integration tests
   - Build fails if tests fail

4. **Everyone Commits to Mainline Every Day**
   - Small, frequent commits
   - Merge conflicts minimized
   - Continuous integration (the name!)

5. **Every Commit Should Build on Integration Machine**
   - Not "works on my machine"
   - Clean environment every time
   - Same as production

6. **Keep the Build Fast**
   - Target: <10 minutes
   - Developers wait for feedback
   - Slow builds = ignored builds

7. **Test in Clone of Production Environment**
   - Same OS, same dependencies
   - Containers/VMs for consistency
   - "Shift left" on environment issues

8. **Make it Easy to Get Latest Deliverables**
   - Artifacts automatically published
   - Always available for testing
   - Clear versioning

9. **Everyone Can See What's Happening**
   - Build status visible to all
   - Radiator dashboards
   - Notifications on failures

10. **Automate Deployment**
    - One-click deployment
    - Continuous Delivery (next step)
    - Reduces human error

### CI Impact on DORA Metrics

| DORA Metric | CI Impact | Data |
|-------------|-----------|------|
| **Deployment Frequency** | Enables multiple deploys/day with confidence | Elite: Multiple per day |
| **Lead Time for Changes** | Reduces commit-to-deploy from days to minutes | Elite: <1 hour |
| **Change Failure Rate** | Catches bugs before production | Elite: 0-15% |
| **MTTR** | Small changes = easier rollback | Elite: <1 hour |

**Research shows**: Teams with CI are 2x more likely to be high performers on DORA metrics.

---

## 🏗️ Part 2: Jenkins Architecture

### What is Jenkins?

Jenkins is an open-source automation server that enables CI/CD pipelines.

**Key Features**:
- Pipeline as Code (Jenkinsfile)
- 1,800+ plugins for integration
- Distributed builds (controller + agents)
- Kubernetes-native (Fawkes uses Kubernetes Plugin)
- Web UI for monitoring and management

### Jenkins Architecture in Fawkes

```
┌─────────────────────────────────────────────────────┐
│           Fawkes Platform (Kubernetes)              │
├─────────────────────────────────────────────────────┤
│                                                     │
│  ┌──────────────────────────────────────────────┐  │
│  │      Jenkins Controller (Master)             │  │
│  │  • Manages pipelines                         │  │
│  │  • Schedules builds                          │  │
│  │  • Stores configuration                      │  │
│  │  • Serves Web UI                             │  │
│  │  • Kubernetes Plugin installed               │  │
│  └───────────────┬──────────────────────────────┘  │
│                  │                                  │
│                  │ (Schedules agents)               │
│                  ▼                                  │
│  ┌──────────────────────────────────────────────┐  │
│  │  Dynamic Build Agents (Pods)                 │  │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐   │  │
│  │  │ Java     │  │ Node.js  │  │ Python   │   │  │
│  │  │ Agent    │  │ Agent    │  │ Agent    │   │  │
│  │  └──────────┘  └──────────┘  └──────────┘   │  │
│  │  • Created on-demand                         │  │
│  │  • Isolated namespaces                       │  │
│  │  • Auto-deleted after build                  │  │
│  │  • Resource limits enforced                  │  │
│  └──────────────────────────────────────────────┘  │
│                                                     │
│  ┌──────────────────────────────────────────────┐  │
│  │      Supporting Services                     │  │
│  │  • Git Repository (Source)                   │  │
│  │  • Harbor (Artifact Registry)                │  │
│  │  • SonarQube (Code Quality)                  │  │
│  │  • Trivy (Security Scanning)                 │  │
│  └──────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────┘
```

### Jenkins Controller vs. Agents

**Controller (Master)**:
- Orchestrates builds
- Manages plugins and configuration
- Serves Web UI
- Should NOT run builds (security + resource management)

**Agents (Slaves/Pods)**:
- Execute actual build work
- Ephemeral in Kubernetes
- Isolated from each other
- Deleted after build completes

**Fawkes Advantage**: Using Kubernetes Plugin, agents are dynamic pods. No pre-provisioned VMs needed!

### Pipeline as Code: Jenkinsfile

Modern Jenkins uses **declarative pipelines** defined in `Jenkinsfile`:

**Benefits**:
- ✅ Version controlled with code
- ✅ Code review for pipeline changes
- ✅ Consistent across projects
- ✅ Auditable (Git history)
- ✅ Portable across Jenkins instances

---

## 🛠️ Part 3: Hands-On Lab - Your First Pipeline

### Lab Scenario

You'll create a CI pipeline for a sample Java Spring Boot application that:
1. Checks out code from Git
2. Compiles the application
3. Runs unit tests
4. Packages as Docker image
5. Pushes to Harbor registry

### Step 1: Access Your Lab Environment

```bash
# Access Jenkins in Fawkes platform
kubectl port-forward -n jenkins svc/jenkins 8080:8080

# Get Jenkins admin password
kubectl get secret -n jenkins jenkins-admin -o jsonpath="{.data.password}" | base64 -d

# Open Jenkins UI
# URL: http://localhost:8080
# Username: admin
# Password: (from above command)
```

### Step 2: Create Your First Pipeline Job

**In Jenkins UI**:

1. Click "New Item"
2. Name: `my-first-pipeline`
3. Type: "Pipeline"
4. Click "OK"

**Pipeline Configuration**:
- Scroll to "Pipeline" section
- Definition: "Pipeline script"
- Paste the following script:

```groovy
pipeline {
    agent {
        kubernetes {
            yaml '''
apiVersion: v1
kind: Pod
metadata:
  labels:
    jenkins: agent
spec:
  containers:
  - name: maven
    image: maven:3.8-openjdk-17
    command:
    - sleep
    args:
    - infinity
  - name: docker
    image: docker:24-dind
    securityContext:
      privileged: true
'''
        }
    }
    
    stages {
        stage('Checkout') {
            steps {
                echo 'Checking out source code...'
                git branch: 'main',
                    url: 'https://github.com/fawkes-platform/sample-spring-boot.git'
            }
        }
        
        stage('Build') {
            steps {
                container('maven') {
                    echo 'Building application...'
                    sh 'mvn clean compile'
                }
            }
        }
        
        stage('Test') {
            steps {
                container('maven') {
                    echo 'Running tests...'
                    sh 'mvn test'
                }
            }
        }
        
        stage('Package') {
            steps {
                container('maven') {
                    echo 'Packaging application...'
                    sh 'mvn package -DskipTests'
                }
            }
        }
    }
    
    post {
        success {
            echo '✅ Pipeline succeeded!'
        }
        failure {
            echo '❌ Pipeline failed!'
        }
        always {
            echo '🏁 Pipeline completed'
        }
    }
}
```

4. Click "Save"
5. Click "Build Now"

### Step 3: Watch Your Pipeline Execute

**In the Jenkins UI**:
- Click on the build number (e.g., #1)
- Click "Console Output" to see logs in real-time
- Watch as stages progress: Checkout → Build → Test → Package

**Expected Output**:
```
Started by user admin
Running in Durability level: MAX_SURVIVABILITY
[Pipeline] Start of Pipeline
[Pipeline] podTemplate
[Pipeline] {
[Pipeline] node
Created Pod: jenkins-agent-xxxxx
Agent maven-xxxxx is provisioned from template maven
[Pipeline] {
[Pipeline] stage (Checkout)
[Pipeline] { (Checkout)
[Pipeline] echo
Checking out source code...
[Pipeline] git
Cloning repository https://github.com/fawkes-platform/sample-spring-boot.git
...
[Pipeline] stage (Build)
[Pipeline] { (Build)
[Pipeline] container
[Pipeline] {
[Pipeline] echo
Building application...
[Pipeline] sh
+ mvn clean compile
[INFO] Scanning for projects...
[INFO] Building sample-app 1.0.0
...
[INFO] BUILD SUCCESS
...
```

### Step 4: Understanding the Jenkinsfile

Let's break down each section:

#### Agent Definition
```groovy
agent {
    kubernetes {
        yaml '''
        ...
        '''
    }
}
```
- Tells Jenkins to run this pipeline on a Kubernetes pod
- Defines container images needed (Maven, Docker)
- Containers are ephemeral - created for this build, deleted after

#### Stages
```groovy
stages {
    stage('Checkout') { ... }
    stage('Build') { ... }
    stage('Test') { ... }
    stage('Package') { ... }
}
```
- Sequential steps in your pipeline
- Each stage appears as a column in Jenkins UI
- Stages fail fast - if one fails, subsequent stages don't run

#### Steps
```groovy
steps {
    container('maven') {
        sh 'mvn clean compile'
    }
}
```
- Actual commands executed
- `container('maven')` - runs inside Maven container
- `sh` - executes shell command
- Can use `echo`, `git`, custom plugins

#### Post Actions
```groovy
post {
    success { ... }
    failure { ... }
    always { ... }
}
```
- Runs after all stages complete
- `success` - only if pipeline succeeded
- `failure` - only if pipeline failed
- `always` - regardless of outcome
- Perfect for notifications, cleanup

---

## 📊 Part 4: Understanding Build Stages

### Standard CI Pipeline Stages

```
┌──────────┐   ┌───────┐   ┌──────┐   ┌─────────┐   ┌────────┐
│ Checkout │ → │ Build │ → │ Test │ → │ Package │ → │ Publish│
└──────────┘   └───────┘   └──────┘   └─────────┘   └────────┘
     2s           3m          2m          1m            30s
```

### Stage 1: Checkout

**Purpose**: Get source code from version control

```groovy
stage('Checkout') {
    steps {
        git branch: 'main',
            url: 'https://github.com/org/repo.git',
            credentialsId: 'github-credentials'
    }
}
```

**Best Practices**:
- Always specify branch explicitly
- Use shallow clone for speed: `git clone --depth 1`
- Store credentials in Jenkins Credentials Store (never in Jenkinsfile!)

### Stage 2: Build/Compile

**Purpose**: Compile source code, resolve dependencies

```groovy
stage('Build') {
    steps {
        container('maven') {
            sh '''
                mvn clean compile \
                    -DskipTests \
                    -B \
                    --batch-mode
            '''
        }
    }
}
```

**Key Flags**:
- `-DskipTests` - Skip tests during compile (run separately)
- `-B` / `--batch-mode` - Non-interactive, better for CI logs
- `clean` - Remove previous build artifacts

**Build Duration Targets**:
- Small projects: <2 minutes
- Medium projects: 2-5 minutes
- Large projects: 5-10 minutes
- If >10 minutes, optimize (covered in Module 6)

### Stage 3: Test

**Purpose**: Run automated tests, verify functionality

```groovy
stage('Test') {
    steps {
        container('maven') {
            sh 'mvn test'
        }
    }
    post {
        always {
            junit 'target/surefire-reports/**/*.xml'
        }
    }
}
```

**Test Types in CI**:
- **Unit Tests**: Fast (<1s each), no external dependencies
- **Integration Tests**: Slower (1-10s), may use database/APIs
- **Contract Tests**: Verify API contracts between services

**Best Practices**:
- Run unit tests in every build (fast feedback)
- Run integration tests in parallel or on schedule
- Fail build if tests fail (quality gate)
- Publish test reports with `junit` step

### Stage 4: Package

**Purpose**: Create deployable artifact (JAR, Docker image, etc.)

```groovy
stage('Package') {
    steps {
        container('maven') {
            sh 'mvn package -DskipTests'
        }
        container('docker') {
            sh '''
                docker build -t myapp:${BUILD_NUMBER} .
                docker tag myapp:${BUILD_NUMBER} myapp:latest
            '''
        }
    }
}
```

**Artifact Versioning**:
- Use `${BUILD_NUMBER}` - Jenkins build number (e.g., `myapp:142`)
- Use `${GIT_COMMIT}` - Git commit SHA (e.g., `myapp:abc1234`)
- Use semantic versioning for releases (e.g., `myapp:1.2.3`)

### Stage 5: Publish (Optional for Module 5)

**Purpose**: Push artifacts to registry

```groovy
stage('Publish') {
    steps {
        container('docker') {
            sh '''
                docker login harbor.fawkes.internal -u ${HARBOR_USER} -p ${HARBOR_PASS}
                docker push harbor.fawkes.internal/myapp:${BUILD_NUMBER}
            '''
        }
    }
}
```

*We'll cover this in detail in Module 8: Artifact Management*

---

## 🔍 Part 5: Error Handling & Debugging

### Common Pipeline Failures

#### Issue 1: Checkout Fails

**Error**:
```
ERROR: Error cloning remote repo 'origin'
hudson.plugins.git.GitException: Command "git fetch" returned status code 128
```

**Causes**:
- Repository URL incorrect
- No access credentials configured
- Network issues

**Solutions**:
```groovy
// Option 1: Use credentials
git branch: 'main',
    url: 'https://github.com/org/private-repo.git',
    credentialsId: 'github-pat'

// Option 2: Use SSH
git branch: 'main',
    url: 'git@github.com:org/private-repo.git',
    credentialsId: 'github-ssh-key'

// Option 3: Check connectivity
sh 'git ls-remote https://github.com/org/repo.git HEAD'
```

#### Issue 2: Build Fails

**Error**:
```
[ERROR] Failed to execute goal org.apache.maven.plugins:maven-compiler-plugin:3.8.1:compile
[ERROR] Compilation failure: Compilation failure:
[ERROR] /src/main/java/App.java:[10,8] cannot find symbol
```

**Causes**:
- Compilation errors in code
- Missing dependencies
- Wrong Java version

**Solutions**:
```groovy
// Specify Java version
stage('Build') {
    steps {
        container('maven') {
            sh '''
                java -version
                mvn -version
                mvn clean compile
            '''
        }
    }
}

// Use specific Maven image
agent {
    kubernetes {
        yaml '''
        containers:
        - name: maven
          image: maven:3.8-openjdk-17  # Specific version
        '''
    }
}
```

#### Issue 3: Tests Fail

**Error**:
```
[ERROR] Tests run: 10, Failures: 2, Errors: 0, Skipped: 0
[INFO] BUILD FAILURE
```

**Causes**:
- Actual bugs in code (good thing CI caught it!)
- Test environment not set up correctly
- Flaky tests (tests that randomly fail)

**Solutions**:
```groovy
stage('Test') {
    steps {
        container('maven') {
            // Run with detailed output
            sh 'mvn test -X'  // Debug mode
            
            // Or continue on failure to see all test results
            sh 'mvn test || true'
        }
    }
    post {
        always {
            // Always publish test results
            junit 'target/surefire-reports/**/*.xml'
            
            // Archive failed test logs
            archiveArtifacts artifacts: 'target/surefire-reports/**',
                             allowEmptyArchive: true
        }
    }
}
```

#### Issue 4: Resource Limits

**Error**:
```
java.lang.OutOfMemoryError: Java heap space
```

**Causes**:
- Build requires more memory than allocated
- Memory leak in build process

**Solutions**:
```groovy
agent {
    kubernetes {
        yaml '''
        containers:
        - name: maven
          image: maven:3.8-openjdk-17
          resources:
            requests:
              memory: "2Gi"
              cpu: "1000m"
            limits:
              memory: "4Gi"
              cpu: "2000m"
          env:
          - name: MAVEN_OPTS
            value: "-Xmx3g"  # Increase heap size
        '''
    }
}
```

### Debugging Techniques

**1. Add Verbose Logging**
```groovy
stage('Debug') {
    steps {
        sh '''
            echo "Current directory: $(pwd)"
            echo "Files present:"
            ls -la
            echo "Java version:"
            java -version
            echo "Maven version:"
            mvn -version
            echo "Environment variables:"
            env | sort
        '''
    }
}
```

**2. Use Try-Catch**
```groovy
stage('Build with Error Handling') {
    steps {
        script {
            try {
                sh 'mvn clean compile'
            } catch (Exception e) {
                echo "Build failed with error: ${e.message}"
                // Send notification, mark unstable, etc.
                currentBuild.result = 'UNSTABLE'
            }
        }
    }
}
```

**3. Access Agent Shell**
```groovy
// Add this stage temporarily for debugging
stage('Debug Shell') {
    steps {
        container('maven') {
            sh 'sleep 3600'  // Keeps container alive for 1 hour
        }
    }
}

// Then connect to pod:
// kubectl exec -it <pod-name> -c maven -- /bin/bash
```

---

## 🎯 Part 6: CI Best Practices

### 1. Keep Builds Fast

**Target**: <10 minutes total

**Techniques**:
- Run only essential tests in CI (unit tests)
- Parallelize independent stages
- Cache dependencies
- Use incremental compilation

```groovy
pipeline {
    options {
        timestamps()
        timeout(time: 10, unit: 'MINUTES')  // Fail if >10 min
    }
    
    stages {
        stage('Parallel Tests') {
            parallel {
                stage('Unit Tests') {
                    steps {
                        sh 'mvn test'
                    }
                }
                stage('Linting') {
                    steps {
                        sh 'mvn checkstyle:check'
                    }
                }
            }
        }
    }
}
```

### 2. Fail Fast

Stop pipeline as soon as a critical issue is found.

```groovy
pipeline {
    options {
        skipDefaultCheckout()  // Don't checkout until needed
    }
    
    stages {
        stage('Pre-Flight Checks') {
            steps {
                // Check if branch name follows convention
                script {
                    if (!env.BRANCH_NAME.matches(/(main|develop|feature\/.+)/)) {
                        error("Invalid branch name: ${env.BRANCH_NAME}")
                    }
                }
            }
        }
        
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        
        // ... rest of pipeline
    }
}
```

### 3. Notifications

Keep team informed of build status.

```groovy
post {
    success {
        slackSend(
            color: 'good',
            message: "✅ Build #${BUILD_NUMBER} succeeded\nBranch: ${env.BRANCH_NAME}"
        )
    }
    
    failure {
        slackSend(
            color: 'danger',
            message: "❌ Build #${BUILD_NUMBER} failed\nBranch: ${env.BRANCH_NAME}\nSee: ${BUILD_URL}"
        )
        
        // Email on failure
        emailext(
            subject: "Build Failed: ${env.JOB_NAME} #${BUILD_NUMBER}",
            body: "Check console output at ${BUILD_URL}",
            to: "${env.CHANGE_AUTHOR_EMAIL}"
        )
    }
}
```

### 4. Environment Variables

Use environment variables for configuration.

```groovy
pipeline {
    environment {
        APP_NAME = 'my-spring-boot-app'
        HARBOR_REGISTRY = 'harbor.fawkes.internal'
        JAVA_VERSION = '17'
        MAVEN_OPTS = '-Xmx2g -XX:+UseG1GC'
    }
    
    stages {
        stage('Build') {
            steps {
                sh """
                    echo "Building ${APP_NAME} with Java ${JAVA_VERSION}"
                    mvn clean package
                """
            }
        }
    }
}
```

### 5. Shared Libraries (Preview)

Reuse pipeline code across projects.

```groovy
// In Jenkinsfile
@Library('fawkes-pipeline-library') _

fawkesJavaPipeline {
    gitRepo = 'https://github.com/org/repo.git'
    javaVersion = '17'
    runTests = true
    publishArtifacts = true
}
```

*We'll cover this in Module 6: Golden Path Pipelines*

---

## 📈 Part 7: CI Impact on DORA Metrics

### How CI Improves Each Metric

**1. Deployment Frequency**
```
Without CI:
- Manual testing before each deploy
- Fear of breaking production
- Result: Deploy 1x per month

With CI:
- Automated testing on every commit
- Confidence in code quality
- Result: Deploy 10x per day
```

**2. Lead Time for Changes**
```
Without CI:
Commit → Manual build (30 min) → Manual test (2 hours) → Package (30 min)
= 3+ hours before deploy-ready

With CI:
Commit → Auto build (3 min) → Auto test (2 min) → Auto package (1 min)
= 6 minutes before deploy-ready
```

**3. Change Failure Rate**
```
Without CI:
- No automated testing
- Bugs reach production
- Result: 30% of deploys fail

With CI:
- Automated tests catch 80% of bugs
- Code review before merge
- Result: 5% of deploys fail
```

**4. MTTR (Mean Time to Restore)**
```
Without CI:
- Large commits, hard to isolate issue
- Manual rollback process
- Result: 2+ hours to restore

With CI:
- Small commits, easy to identify culprit
- Automated rollback
- Result: 10 minutes to restore
```

### Measuring CI Effectiveness

Track these metrics in your Jenkins/Fawkes dashboard:

```groovy
// Add to pipeline for metrics collection
post {
    always {
        script {
            def buildDuration = currentBuild.duration / 1000  // seconds
            def buildResult = currentBuild.result ?: 'SUCCESS'
            
            // Send to Prometheus
            sh """mayhem
                curl -X POST http://prometheus-pushgateway:9091/metrics/job/jenkins \
                    --data-binary @- <<EOF
# TYPE jenkins_build_duration_seconds gauge
jenkins_build_duration_seconds{job="${env.JOB_NAME}",result="${buildResult}"} ${buildDuration}

# TYPE jenkins_build_result counter
jenkins_build_result{job="${env.JOB_NAME}",result="${buildResult}"} 1
EOF
            """
        }
    }
}
```

---

## 💪 Part 8: Practical Exercise

### Exercise: Build Your First Real Pipeline

**Objective**: Create a CI pipeline for a sample application

**Scenario**: You have a Java Spring Boot REST API that needs CI.

**Requirements**:
1. Checkout code from Git
2. Compile with Maven
3. Run unit tests
4. Package as JAR
5. Build Docker image
6. Send Slack notification on failure

**Starter Code**:

```groovy
pipeline {
    agent {
        kubernetes {
            yaml '''
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: maven
    image: maven:3.8-openjdk-17
    command: ['sleep']
    args: ['infinity']
  - name: docker
    image: docker:24-dind
    securityContext:
      privileged: true
    command: ['sleep']
    args: ['infinity']
'''
        }
    }
    
    stages {
        // TODO: Add your stages here
        // 1. Checkout
        // 2. Build
        // 3. Test
        // 4. Package
        // 5. Docker Build
    }
    
    post {
        // TODO: Add notifications
    }
}
```

**Validation Criteria**:
- [ ] Pipeline runs successfully
- [ ] All stages complete in <8 minutes
- [ ] Test results published to Jenkins
- [ ] Docker image created
- [ ] Notification sent (Slack or email)

**Submission**:
1. Save your Jenkinsfile to Git repository
2. Run pipeline successfully (screenshot)
3. Show console output
4. Submit repository link

---

## 🎓 Part 9: Knowledge Check

### Quiz Questions

1. **What is the primary goal of Continuous Integration?**
   - [ ] Deploy to production automatically
   - [x] Integrate code changes frequently and catch issues early
   - [ ] Write better documentation
   - [ ] Reduce server costs

2. **How often should developers commit to mainline in CI?**
   - [ ] Once per week
   - [ ] Once per sprint
   - [x] At least once per day
   - [ ] Only when feature is complete

3. **What is the recommended maximum build time?**
   - [ ] 30 minutes
   - [x] 10 minutes
   - [ ] 1 hour
   - [ ] As long as it takes

4. **In Jenkins Kubernetes Plugin, what happens to build agents after build?**
   - [ ] They remain running for next build
   - [x] They are automatically deleted
   - [ ] They are paused
   - [ ] They are archived

5. **Which stage should run first in a CI pipeline?**
   - [ ] Test
   - [ ] Package
   - [x] Checkout
   - [ ] Deploy

6. **What does "fail fast" mean in CI?**
   - [ ] Make builds run faster
   - [x] Stop pipeline immediately when critical issue found
   - [ ] Skip tests to save time
   - [ ] Deploy even if tests fail

7. **What file defines Jenkins Pipeline as Code?**
   - [ ] pipeline.yaml
   - [x] Jenkinsfile
   - [ ] build.xml
   - [ ] ci-config.json

8. **Which DORA metric is most directly improved by CI?**
   - [ ] Deployment Frequency
   - [x] Lead Time for Changes
   - [ ] MTTR
   - [ ] All of the above

**Answers**: 1-B, 2-C, 3-B, 4-B, 5-C, 6-B, 7-B, 8-D

---

## 🎯 Part 10: Module Summary & Next Steps

### What You Learned

✅ **CI Principles**: Early integration, automated builds, fast feedback  
✅ **Jenkins Architecture**: Controller, agents, Kubernetes plugin  
✅ **Pipeline as Code**: Jenkinsfile structure and syntax  
✅ **Build Stages**: Checkout, build, test, package workflow  
✅ **Troubleshooting**: Common failures and debugging techniques  
✅ **Best Practices**: Fast builds, fail fast, notifications  
✅ **DORA Impact**: How CI improves all four key metrics

### DORA Capabilities Achieved

- ✅ **CD3**: Continuous Integration implemented
- ✅ **CD1**: Version control for production artifacts
- ✅ **CD5**: Trunk-based development support

### Key Takeaways

1. **CI is about feedback speed** - The faster you know about problems, the cheaper they are to fix
2. **Automate everything** - If it can be automated, it should be automated
3. **Keep builds fast** - Developers won't wait for slow builds
4. **Fail fast** - Don't waste time on builds that will fail anyway
5. **Make failures visible** - Everyone should see broken builds immediately

### Real-World Impact

"Before CI, our integration process took 2-3 days and often failed. After implementing CI with Jenkins:
- **Build time**: 3 hours → 8 minutes
- **Integration time**: 3 days → Continuous
- **Bug detection**: Post-production → Pre-commit
- **Deploy confidence**: Low → High

We went from monthly releases to daily deploys." 
- *Engineering Team, SaaS Company*

---

## 📚 Additional Resources

### Official Documentation
- [Jenkins Documentation](https://www.jenkins.io/doc/)
- [Pipeline Syntax](https://www.jenkins.io/doc/book/pipeline/syntax/)
- [Kubernetes Plugin](https://plugins.jenkins.io/kubernetes/)

### Learning Resources
- [Martin Fowler: Continuous Integration](https://martinfowler.com/articles/continuousIntegration.html)
- [Continuous Delivery Book](https://continuousdelivery.com/) by Jez Humble
- [Jenkins Pipeline Tutorial](https://www.jenkins.io/doc/pipeline/tour/hello-world/)

### Community
- [Jenkins Community](https://www.jenkins.io/participate/)
- [Jenkins Slack](https://www.jenkins.io/chat/)
- [Fawkes Mattermost](https://mattermost.fawkes.internal) - #yellow-belt channel

---

## 🏅 Module Completion

### Assessment Checklist

To complete this module, you must:

- [ ] **Conceptual Understanding**
  - [ ] Explain the 10 principles of CI
  - [ ] Describe Jenkins controller vs. agent architecture
  - [ ] Explain how CI improves DORA metrics

- [ ] **Practical Skills**
  - [ ] Create a Jenkinsfile from scratch
  - [ ] Configure Kubernetes agent pod template
  - [ ] Implement checkout, build, test, package stages
  - [ ] Add error handling and notifications
  - [ ] Debug a failed pipeline

- [ ] **Hands-On Lab**
  - [ ] Complete the first pipeline lab
  - [ ] Pipeline runs successfully (<10 min)
  - [ ] All tests pass
  - [ ] Docker image created

- [ ] **Quiz**
  - [ ] Score 80% or higher (6/8 questions)

### Certification Credit

Upon completion, you earn:
- **5 points** toward Yellow Belt certification (25% complete)
- **Badge**: "CI Practitioner"
- **Skill Unlocked**: Jenkins Pipeline Creation

---

## 🎖️ Yellow Belt Progress

```
Yellow Belt: CI/CD Mastery
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Module 5: CI Fundamentals        ████████░░░░ 25% ✓
Module 6: Golden Path Pipelines  ░░░░░░░░░░░░  0%
Module 7: Security & Quality     ░░░░░░░░░░░░  0%
Module 8: Artifact Management    ░░░░░░░░░░░░  0%
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**Next Module Preview**: Module 6 - Building Golden Path Pipelines (Shared libraries, pipeline templates, optimization)

---

**🎉 Congratulations!** You've completed Module 5 and learned the fundamentals of Continuous Integration with Jenkins.

You're now ready to build production-ready CI pipelines. Continue to Module 6 to learn how to create reusable, optimized pipeline templates!

---

*Fawkes Dojo - Where Platform Engineers Are Forged*  
*Version 1.0 | Last Updated: October 2025*  
*License: MIT | https://github.com/paruff/fawkes*