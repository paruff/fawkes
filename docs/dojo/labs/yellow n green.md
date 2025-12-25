# =============================================================================

# YELLOW BELT LAB FILES - CI/CD Mastery (Modules 5-8)

# =============================================================================

# =============================================================================

# MODULE 5 - LAB 1: Production CI Pipeline

# Directory: labs/module-05/

# =============================================================================

---

# labs/module-05/github-actions-template.yaml

# .github/workflows/ci.yml template for students

name: CI Pipeline

on:
push:
branches: [ main, develop ]
pull_request:
branches: [ main ]

jobs:
test:
runs-on: ubuntu-latest
steps: - uses: actions/checkout@v3

      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Run tests
        run: npm test -- --coverage

      - name: Check coverage
        run: |
          COVERAGE=$(node -e "console.log(require('./coverage/coverage-summary.json').total.lines.pct)")
          if [ $(echo "$COVERAGE < 80" | bc) -eq 1 ]; then
            echo "Coverage $COVERAGE% is below 80%"
            exit 1
          fi

security-scan:
runs-on: ubuntu-latest
steps: - uses: actions/checkout@v3

      - name: Run Semgrep
        uses: returntocorp/semgrep-action@v1
        with:
          config: auto

      - name: Run npm audit
        run: npm audit --audit-level=high

build:
needs: [test, security-scan]
runs-on: ubuntu-latest
steps: - uses: actions/checkout@v3

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v2

      - name: Build image
        uses: docker/build-push-action@v4
        with:
          context: .
          push: false
          tags: my-app:${{ github.sha }}
          cache-from: type=gha
          cache-to: type=gha,mode=max

      - name: Scan image
        uses: aquasecurity/trivy-action@master
        with:
          image-ref: my-app:${{ github.sha }}
          exit-code: '1'
          severity: 'CRITICAL,HIGH'

---

# labs/module-05/tekton-pipeline.yaml

# Tekton pipeline alternative

apiVersion: tekton.dev/v1beta1
kind: Pipeline
metadata:
name: ci-pipeline
namespace: tekton-pipelines
spec:
params: - name: git-url
type: string - name: git-revision
type: string
default: main
workspaces: - name: shared-data
tasks: - name: fetch-source
taskRef:
name: git-clone
workspaces: - name: output
workspace: shared-data
params: - name: url
value: $(params.git-url) - name: revision
value: $(params.git-revision)

    - name: run-tests
      runAfter: [fetch-source]
      taskRef:
        name: npm-test
      workspaces:
        - name: source
          workspace: shared-data

    - name: security-scan
      runAfter: [fetch-source]
      taskRef:
        name: semgrep-scan
      workspaces:
        - name: source
          workspace: shared-data

    - name: build-image
      runAfter: [run-tests, security-scan]
      taskRef:
        name: kaniko
      workspaces:
        - name: source
          workspace: shared-data
      params:
        - name: IMAGE
          value: "registry.fawkes.io/my-app:$(params.git-revision)"

---

# labs/module-05/quality-gates.yaml

# Quality gates configuration

apiVersion: v1
kind: ConfigMap
metadata:
name: quality-gates
namespace: lab-module-5
data:
gates.yaml: |
gates:
test_coverage:
threshold: 80
action: block

      security_vulnerabilities:
        critical: 0
        high: 0
        medium: 5
        action: block

      code_quality:
        min_maintainability: B
        max_complexity: 15
        action: warn

      build_time:
        max_duration_seconds: 300
        action: warn

---

# =============================================================================

# MODULE 6 - LAB 2: Golden Path Pipelines

# Directory: labs/module-06/

# =============================================================================

---

# labs/module-06/golden-path-template.yaml

# Reusable workflow template

apiVersion: v1
kind: ConfigMap
metadata:
name: golden-path-template
namespace: lab-module-6
data:
node-service.yaml: | # Golden Path for Node.js Services
name: Node.js Service Pipeline

    on:
      push:
        branches: [main, develop]

    jobs:
      golden-path:
        uses: fawkes/workflows/.github/workflows/golden-path-node.yml@v1
        with:
          node-version: '18'
          test-coverage-threshold: 80
          security-scan: true
          deploy-dev: true
        secrets:
          REGISTRY_TOKEN: ${{ secrets.REGISTRY_TOKEN }}

python-service.yaml: | # Golden Path for Python Services
name: Python Service Pipeline

    on:
      push:
        branches: [main]

    jobs:
      golden-path:
        uses: fawkes/workflows/.github/workflows/golden-path-python.yml@v1
        with:
          python-version: '3.11'
          test-framework: pytest
          security-scan: true
        secrets:
          REGISTRY_TOKEN: ${{ secrets.REGISTRY_TOKEN }}

---

# =============================================================================

# MODULE 7 - LAB 3: Security Scanning & Quality Gates

# Directory: labs/module-07/

# =============================================================================

---

# labs/module-07/semgrep-config.yaml

# Semgrep security scanning configuration

apiVersion: v1
kind: ConfigMap
metadata:
name: semgrep-config
namespace: lab-module-7
data:
.semgrep.yml: |
rules: - id: hardcoded-secret
patterns: - pattern: password = "..." - pattern: api_key = "..."
message: Hardcoded secret detected
severity: ERROR

      - id: sql-injection
        patterns:
          - pattern: execute($SQL + $INPUT)
        message: Possible SQL injection
        severity: ERROR

      - id: xss-vulnerability
        patterns:
          - pattern: innerHTML = $INPUT
        message: Possible XSS vulnerability
        severity: WARNING

---

# labs/module-07/trivy-config.yaml

# Trivy image scanning configuration

apiVersion: v1
kind: ConfigMap
metadata:
name: trivy-config
namespace: lab-module-7
data:
trivy.yaml: |
severity: - CRITICAL - HIGH - MEDIUM

    vulnerability:
      type:
        - os
        - library

    ignore-unfixed: true

    exit-code: 1  # Fail on findings

    cache:
      ttl: 24h

---

# labs/module-07/sonarqube-properties.yaml

apiVersion: v1
kind: ConfigMap
metadata:
name: sonarqube-config
namespace: lab-module-7
data:
sonar-project.properties: |
sonar.projectKey=my-first-app
sonar.projectName=My First App
sonar.sources=src
sonar.tests=test
sonar.javascript.lcov.reportPaths=coverage/lcov.info

    # Quality Gates
    sonar.qualitygate.wait=true
    sonar.coverage.minimum=80
    sonar.bugs.blocker.max=0
    sonar.vulnerabilities.critical.max=0

---

# =============================================================================

# MODULE 8 - LAB: Artifact Management

# Directory: labs/module-08/

# =============================================================================

---

# labs/module-08/container-registry.yaml

# Harbor container registry setup

apiVersion: v1
kind: Secret
metadata:
name: registry-credentials
namespace: lab-module-8
type: kubernetes.io/dockerconfigjson
data:
.dockerconfigjson: BASE64_ENCODED_CONFIG

---

# labs/module-08/image-signing-setup.yaml

# Cosign image signing configuration

apiVersion: v1
kind: ConfigMap
metadata:
name: cosign-config
namespace: lab-module-8
data:
sign-image.sh: |
#!/bin/bash
set -e

    IMAGE=$1

    echo "Signing image: $IMAGE"

    # Generate key pair (in real scenario, use existing keys)
    cosign generate-key-pair

    # Sign the image
    cosign sign --key cosign.key $IMAGE

    # Generate SBOM
    syft packages $IMAGE -o spdx-json=sbom.json

    # Attach SBOM to image
    cosign attach sbom --sbom sbom.json $IMAGE

    echo "Image signed successfully"
    echo "Verify with: cosign verify --key cosign.pub $IMAGE"

---

# =============================================================================

# GREEN BELT LAB FILES - GitOps & Deployment (Modules 9-12)

# =============================================================================

# =============================================================================

# MODULE 9 - LAB 1: GitOps with ArgoCD

# Directory: labs/module-09/

# =============================================================================

---

# labs/module-09/namespace.yaml

apiVersion: v1
kind: Namespace
metadata:
name: lab-module-9
labels:
fawkes.io/module: "9"
fawkes.io/belt: "green"

---

# labs/module-09/argocd-application.yaml

apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
name: my-app-gitops
namespace: argocd
finalizers: - resources-finalizer.argocd.argoproj.io
spec:
project: default

source:
repoURL: https://github.com/student/my-app
targetRevision: HEAD
path: k8s/base

destination:
server: https://kubernetes.default.svc
namespace: lab-module-9

syncPolicy:
automated:
prune: true
selfHeal: true
allowEmpty: false
syncOptions: - CreateNamespace=true - PrunePropagationPolicy=foreground - PruneLast=true
retry:
limit: 5
backoff:
duration: 5s
factor: 2
maxDuration: 3m

---

# labs/module-09/sync-waves-example.yaml

# Demonstrates ArgoCD sync waves

apiVersion: v1
kind: ConfigMap
metadata:
name: database-config
namespace: lab-module-9
annotations:
argocd.argoproj.io/sync-wave: "1" # Deploy first
data:
database: "postgres"

---

apiVersion: apps/v1
kind: Deployment
metadata:
name: backend
namespace: lab-module-9
annotations:
argocd.argoproj.io/sync-wave: "2" # Deploy after config
spec:
replicas: 2
selector:
matchLabels:
app: backend
template:
metadata:
labels:
app: backend
spec:
containers: - name: app
image: backend:v1.0.0
envFrom: - configMapRef:
name: database-config

---

# =============================================================================

# MODULE 10 - LAB 2: Deployment Strategies

# Directory: labs/module-10/

# =============================================================================

---

# labs/module-10/blue-green-deployment.yaml

# Blue-Green deployment example

apiVersion: v1
kind: Service
metadata:
name: my-app
namespace: lab-module-10
spec:
selector:
app: my-app
version: blue # Switch to 'green' for blue-green switch
ports:

- port: 80
  targetPort: 8080

---

apiVersion: apps/v1
kind: Deployment
metadata:
name: my-app-blue
namespace: lab-module-10
labels:
app: my-app
version: blue
spec:
replicas: 3
selector:
matchLabels:
app: my-app
version: blue
template:
metadata:
labels:
app: my-app
version: blue
spec:
containers: - name: app
image: my-app:v1.0.0
ports: - containerPort: 8080

---

apiVersion: apps/v1
kind: Deployment
metadata:
name: my-app-green
namespace: lab-module-10
labels:
app: my-app
version: green
spec:
replicas: 3
selector:
matchLabels:
app: my-app
version: green
template:
metadata:
labels:
app: my-app
version: green
spec:
containers: - name: app
image: my-app:v2.0.0 # New version
ports: - containerPort: 8080

---

# labs/module-10/canary-deployment.yaml

# Manual canary deployment (before Flagger)

apiVersion: apps/v1
kind: Deployment
metadata:
name: my-app-stable
namespace: lab-module-10
spec:
replicas: 9 # 90% of traffic
selector:
matchLabels:
app: my-app
track: stable
template:
metadata:
labels:
app: my-app
track: stable
spec:
containers: - name: app
image: my-app:v1.0.0

---

apiVersion: apps/v1
kind: Deployment
metadata:
name: my-app-canary
namespace: lab-module-10
spec:
replicas: 1 # 10% of traffic
selector:
matchLabels:
app: my-app
track: canary
template:
metadata:
labels:
app: my-app
track: canary
spec:
containers: - name: app
image: my-app:v2.0.0

---

apiVersion: v1
kind: Service
metadata:
name: my-app
namespace: lab-module-10
spec:
selector:
app: my-app # Routes to both stable and canary
ports:

- port: 80
  targetPort: 8080

---

# labs/module-10/rolling-update.yaml

# Rolling update strategy

apiVersion: apps/v1
kind: Deployment
metadata:
name: my-app-rolling
namespace: lab-module-10
spec:
replicas: 5
strategy:
type: RollingUpdate
rollingUpdate:
maxSurge: 1 # 1 extra pod during update
maxUnavailable: 1 # 1 pod can be unavailable
selector:
matchLabels:
app: my-app
template:
metadata:
labels:
app: my-app
spec:
containers: - name: app
image: my-app:v2.0.0
readinessProbe:
httpGet:
path: /health
port: 8080
initialDelaySeconds: 5
periodSeconds: 5

---

# =============================================================================

# MODULE 11 - LAB 3: Progressive Delivery with Flagger

# Directory: labs/module-11/

# =============================================================================

---

# labs/module-11/flagger-canary.yaml

apiVersion: flagger.app/v1beta1
kind: Canary
metadata:
name: my-app
namespace: lab-module-11
spec:

# deployment reference

targetRef:
apiVersion: apps/v1
kind: Deployment
name: my-app

# HPA reference (optional)

autoscalerRef:
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
name: my-app

# service port

service:
port: 80
targetPort: 8080

# canary analysis

analysis: # schedule interval
interval: 1m

    # max number of failed metric checks before rollback
    threshold: 5

    # max traffic percentage routed to canary
    maxWeight: 50

    # canary increment step
    stepWeight: 10

    # metrics
    metrics:
    - name: request-success-rate
      thresholdRange:
        min: 99
      interval: 1m

    - name: request-duration
      thresholdRange:
        max: 500
      interval: 30s

    # webhooks
    webhooks:
    - name: load-test
      url: http://flagger-loadtester/
      timeout: 5s
      metadata:
        type: cmd
        cmd: "hey -z 1m -q 10 -c 2 http://my-app-canary.lab-module-11/"

---

# labs/module-11/flagger-loadtester.yaml

# Load testing service for Flagger

apiVersion: apps/v1
kind: Deployment
metadata:
name: flagger-loadtester
namespace: lab-module-11
spec:
replicas: 1
selector:
matchLabels:
app: flagger-loadtester
template:
metadata:
labels:
app: flagger-loadtester
spec:
containers: - name: loadtester
image: ghcr.io/fluxcd/flagger-loadtester:0.29.0
ports: - name: http
containerPort: 8080
command: - ./loadtester - -port=8080 - -log-level=info - -timeout=1h

---

apiVersion: v1
kind: Service
metadata:
name: flagger-loadtester
namespace: lab-module-11
spec:
type: ClusterIP
selector:
app: flagger-loadtester
ports:

- name: http
  port: 80
  targetPort: http

---

# labs/module-11/prometheus-metrics.yaml

# ServiceMonitor for Prometheus metrics

apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
name: my-app
namespace: lab-module-11
spec:
selector:
matchLabels:
app: my-app
endpoints:

- port: http-metrics
  interval: 15s

---

# =============================================================================

# MODULE 12 - LAB 4: Rollback & Incident Response

# Directory: labs/module-12/

# =============================================================================

---

# labs/module-12/incident-simulation.yaml

# Deployment that will fail (for practice)

apiVersion: apps/v1
kind: Deployment
metadata:
name: broken-app
namespace: lab-module-12
labels:
app: broken-app
spec:
replicas: 3
selector:
matchLabels:
app: broken-app
template:
metadata:
labels:
app: broken-app
spec:
containers: - name: app
image: nginx:latest
ports: - containerPort: 80
env: - name: CRASH_ON_START
value: "true" # This will cause the app to crash
livenessProbe:
httpGet:
path: /health
port: 8080
initialDelaySeconds: 5
periodSeconds: 5
failureThreshold: 3

---

# labs/module-12/rollback-script.yaml

apiVersion: v1
kind: ConfigMap
metadata:
name: rollback-scripts
namespace: lab-module-12
data:
rollback-deployment.sh: |
#!/bin/bash
set -e

    DEPLOYMENT_NAME=$1
    NAMESPACE=${2:-default}

    echo "Rolling back deployment: $DEPLOYMENT_NAME in namespace: $NAMESPACE"

    # Get current revision
    CURRENT=$(kubectl rollout history deployment/$DEPLOYMENT_NAME -n $NAMESPACE | tail -1 | awk '{print $1}')
    echo "Current revision: $CURRENT"

    # Rollback to previous revision
    kubectl rollout undo deployment/$DEPLOYMENT_NAME -n $NAMESPACE

    # Wait for rollback to complete
    kubectl rollout status deployment/$DEPLOYMENT_NAME -n $NAMESPACE --timeout=5m

    echo "Rollback completed successfully"

    # Verify pods are running
    kubectl get pods -n $NAMESPACE -l app=$DEPLOYMENT_NAME

rollback-argocd.sh: |
#!/bin/bash
set -e

    APP_NAME=$1

    echo "Rolling back ArgoCD application: $APP_NAME"

    # Get current revision
    CURRENT=$(argocd app get $APP_NAME -o json | jq -r '.status.sync.revision')
    echo "Current revision: $CURRENT"

    # Get history
    argocd app history $APP_NAME

    # Rollback to previous revision
    PREVIOUS=$(argocd app history $APP_NAME -o json | jq -r '.[-2].id')
    argocd app rollback $APP_NAME $PREVIOUS

    # Wait for sync
    argocd app wait $APP_NAME --timeout 300

    echo "ArgoCD rollback completed"

---

# labs/module-12/incident-playbook.yaml

apiVersion: v1
kind: ConfigMap
metadata:
name: incident-playbook
namespace: lab-module-12
data:
playbook.md: | # Incident Response Playbook

    ## Phase 1: Detection (0-2 minutes)
    - [ ] Alert received
    - [ ] Acknowledge incident
    - [ ] Create incident channel (#incident-YYYYMMDD-NNN)
    - [ ] Page on-call engineer

    ## Phase 2: Triage (2-5 minutes)
    - [ ] Check recent deployments
    - [ ] Review error logs
    - [ ] Check monitoring dashboards
    - [ ] Determine severity (P0/P1/P2)

    ## Phase 3: Mitigation (5-10 minutes)
    - [ ] Decision: Rollback or fix-forward?
    - [ ] If rollback: `kubectl rollout undo deployment/NAME`
    - [ ] If fix-forward: Deploy hotfix
    - [ ] Verify mitigation: Check metrics

    ## Phase 4: Recovery (10-15 minutes)
    - [ ] Confirm all services healthy
    - [ ] Notify stakeholders
    - [ ] Update status page
    - [ ] Document timeline

    ## Phase 5: Postmortem (Within 48 hours)
    - [ ] Schedule postmortem meeting
    - [ ] Document root cause
    - [ ] Create action items
    - [ ] Update runbooks

---

# labs/module-12/monitoring-alerts.yaml

# PrometheusRule for incident detection

apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
name: app-alerts
namespace: lab-module-12
spec:
groups:

- name: app-health
  interval: 30s
  rules:

  - alert: HighErrorRate
    expr: |
    (
    rate(http_requests_total{status=~"5.."}[5m])
    /
    rate(http_requests_total[5m])
    ) > 0.05
    for: 2m
    labels:
    severity: critical
    annotations:
    summary: "High error rate detected"
    description: "Error rate is {{ $value | humanizePercentage }}"

  - alert: PodCrashLooping
    expr: |
    rate(kube_pod_container_status_restarts_total[15m]) > 0
    for: 5m
    labels:
    severity: warning
    annotations:
    summary: "Pod is crash looping"
    description: "Pod {{ $labels.pod }} is restarting frequently"

  - alert: DeploymentReplicasMismatch
    expr: |
    kube_deployment_spec_replicas != kube_deployment_status_replicas_available
    for: 10m
    labels:
    severity: warning
    annotations:
    summary: "Deployment replicas mismatch"
    description: "Deployment {{ $labels.deployment }} has mismatched replicas"

---

# =============================================================================

# SHARED GREEN BELT RESOURCES

# Directory: labs/green-belt-shared/

# =============================================================================

---

# labs/green-belt-shared/flagger-install.yaml

# Install Flagger for all green belt labs

apiVersion: v1
kind: Namespace
metadata:
name: flagger-system

---

apiVersion: apps/v1
kind: Deployment
metadata:
name: flagger
namespace: flagger-system
spec:
replicas: 1
selector:
matchLabels:
app: flagger
template:
metadata:
labels:
app: flagger
spec:
serviceAccountName: flagger
containers: - name: flagger
image: ghcr.io/fluxcd/flagger:1.32.0
ports: - name: http
containerPort: 8080
command: - ./flagger - -mesh-provider=kubernetes - -metrics-server=http://prometheus.monitoring:9090

---

# labs/green-belt-shared/argocd-config.yaml

# ArgoCD configuration for labs

apiVersion: v1
kind: ConfigMap
metadata:
name: argocd-cm
namespace: argocd
data:

# Enable anonymous access for lab environment

users.anonymous.enabled: "true"

# Increase timeout for sync operations

timeout.reconciliation: "300s"

# Resource customizations

resource.customizations: |
apps/Deployment:
health.lua: |
hs = {}
if obj.status ~= nil then
if obj.status.updatedReplicas == obj.spec.replicas then
hs.status = "Healthy"
hs.message = "Deployment is healthy"
return hs
end
end
hs.status = "Progressing"
hs.message = "Waiting for deployment"
return hs

---

# labs/green-belt-shared/lab-app-base.yaml

# Base application used across multiple labs

apiVersion: v1
kind: ConfigMap
metadata:
name: app-config
data:
config.json: |
{
"environment": "lab",
"logging": {
"level": "info",
"format": "json"
},
"metrics": {
"enabled": true,
"port": 8080
},
"health": {
"endpoint": "/health",
"liveness": "/health/live",
"readiness": "/health/ready"
}
}

---

apiVersion: apps/v1
kind: Deployment
metadata:
name: sample-app
spec:
replicas: 2
selector:
matchLabels:
app: sample-app
template:
metadata:
labels:
app: sample-app
annotations:
prometheus.io/scrape: "true"
prometheus.io/port: "8080"
prometheus.io/path: "/metrics"
spec:
containers: - name: app
image: ghcr.io/fawkes/sample-app:v1.0.0
ports: - name: http
containerPort: 8080 - name: metrics
containerPort: 9090
env: - name: CONFIG_PATH
value: /config/config.json
volumeMounts: - name: config
mountPath: /config
livenessProbe:
httpGet:
path: /health/live
port: 8080
initialDelaySeconds: 10
periodSeconds: 10
readinessProbe:
httpGet:
path: /health/ready
port: 8080
initialDelaySeconds: 5
periodSeconds: 5
resources:
requests:
memory: "128Mi"
cpu: "100m"
limits:
memory: "256Mi"
cpu: "500m"
volumes: - name: config
configMap:
name: app-config

---

apiVersion: v1
kind: Service
metadata:
name: sample-app
spec:
type: ClusterIP
selector:
app: sample-app
ports:

- name: http
  port: 80
  targetPort: http
- name: metrics
  port: 9090
  targetPort: metrics

---

# =============================================================================

# LAB SETUP AUTOMATION

# =============================================================================

---

# labs/scripts/setup-lab.sh

apiVersion: v1
kind: ConfigMap
metadata:
name: lab-setup-scripts
namespace: fawkes-system
data:
setup-module.sh: |
#!/bin/bash # Automated lab setup script
set -e

    MODULE=$1
    STUDENT_EMAIL=$2

    if [ -z "$MODULE" ] || [ -z "$STUDENT_EMAIL" ]; then
      echo "Usage: $0 <module-number> <student-email>"
      exit 1
    fi

    NAMESPACE="lab-module-${MODULE}-$(echo $STUDENT_EMAIL | cut -d@ -f1)"

    echo "Setting up lab for Module $MODULE"
    echo "Student: $STUDENT_EMAIL"
    echo "Namespace: $NAMESPACE"

    # Create namespace
    kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

    # Label namespace
    kubectl label namespace $NAMESPACE \
      fawkes.io/module="$MODULE" \
      fawkes.io/student="$STUDENT_EMAIL" \
      --overwrite

    # Apply resource quota
    kubectl apply -f /labs/shared/resource-quota.yaml -n $NAMESPACE

    # Apply network policy
    kubectl apply -f /labs/shared/network-policy.yaml -n $NAMESPACE

    # Apply lab-specific resources
    if [ -d "/labs/module-$(printf %02d $MODULE)" ]; then
      kubectl apply -f /labs/module-$(printf %02d $MODULE)/ -n $NAMESPACE
    fi

    echo "Lab setup complete!"
    echo "Access with: kubectl config set-context --current --namespace=$NAMESPACE"

cleanup-lab.sh: |
#!/bin/bash # Cleanup lab environment
set -e

    MODULE=$1
    STUDENT_EMAIL=$2

    NAMESPACE="lab-module-${MODULE}-$(echo $STUDENT_EMAIL | cut -d@ -f1)"

    echo "Cleaning up lab: $NAMESPACE"

    # Delete namespace (cascades all resources)
    kubectl delete namespace $NAMESPACE --wait=true --timeout=120s

    echo "Lab cleanup complete!"
