# Epic 1: Platform Operations Runbook

**Version**: 1.0
**Last Updated**: December 2024
**Status**: Production Ready
**Target Audience**: Platform Engineers, SREs, DevOps Engineers

---

## Table of Contents

1. [Overview](#overview)
2. [Component Status Checks](#component-status-checks)
3. [Common Operations](#common-operations)
4. [Troubleshooting](#troubleshooting)
5. [Maintenance Procedures](#maintenance-procedures)
6. [Emergency Response](#emergency-response)
7. [Health Checks](#health-checks)

---

## Overview

This runbook provides operational procedures for the Epic 1 platform components, including:

- **Infrastructure**: 4-node Kubernetes cluster
- **GitOps**: ArgoCD
- **Developer Portal**: Backstage
- **CI/CD**: Jenkins
- **Security**: SonarQube, Trivy, Vault, Kyverno
- **Observability**: Prometheus, Grafana, OpenTelemetry, Fluent Bit
- **Registry**: Harbor
- **DORA Metrics**: DevLake
- **Supporting Services**: cert-manager, ingress-nginx, External Secrets Operator

---

## Component Status Checks

### Quick Health Check (All Components)

```bash
# Check all platform namespaces
kubectl get namespaces | grep -E 'argocd|backstage|jenkins|sonarqube|prometheus|grafana|harbor|devlake|vault|kyverno'

# Check pod status across all platform components
kubectl get pods -A | grep -E 'argocd|backstage|jenkins|sonarqube|prometheus|grafana|harbor|devlake|vault|kyverno'

# Check all critical services
kubectl get svc -A | grep -E 'argocd-server|backstage|jenkins|sonarqube|prometheus|grafana|harbor|devlake|vault'
```

### Kubernetes Cluster

```bash
# Check node status
kubectl get nodes
kubectl top nodes

# Check cluster resource utilization (should be <70%)
kubectl top nodes --no-headers | awk '{print $3}' | sed 's/%//' | awk '{sum+=$1; count++} END {print "Average CPU: " sum/count "%"}'
kubectl top nodes --no-headers | awk '{print $5}' | sed 's/%//' | awk '{sum+=$1; count++} END {print "Average Memory: " sum/count "%"}'

# Check for pending pods
kubectl get pods -A | grep Pending

# Check for failed pods
kubectl get pods -A | grep -E 'Error|CrashLoopBackOff|ImagePullBackOff'
```

### ArgoCD (GitOps)

```bash
# Check ArgoCD health
kubectl get pods -n argocd
kubectl get applications -n argocd

# Check application sync status
argocd app list

# Check for out-of-sync applications
argocd app list | grep -v Synced

# Access ArgoCD UI
kubectl port-forward svc/argocd-server -n argocd 8080:443
# Navigate to https://localhost:8080
```

### Backstage (Developer Portal)

```bash
# Check Backstage health
kubectl get pods -n backstage
kubectl logs -n backstage -l app=backstage --tail=50

# Check PostgreSQL (Backstage database)
kubectl get pods -n backstage -l cnpg.io/cluster=db-backstage-dev

# Check Backstage service
kubectl get svc -n backstage backstage

# Access Backstage UI
kubectl port-forward svc/backstage -n backstage 7007:7007
# Navigate to http://localhost:7007
```

### Jenkins (CI/CD)

```bash
# Check Jenkins health
kubectl get pods -n jenkins
kubectl logs -n jenkins -l app.kubernetes.io/component=jenkins-controller --tail=50

# Check Jenkins agents
kubectl get pods -n jenkins -l jenkins/label

# Get Jenkins admin password
kubectl get secret -n jenkins jenkins -o jsonpath="{.data.jenkins-admin-password}" | base64 --decode

# Access Jenkins UI
kubectl port-forward svc/jenkins -n jenkins 8080:8080
# Navigate to http://localhost:8080
```

### SonarQube (Code Quality)

```bash
# Check SonarQube health
kubectl get pods -n sonarqube
kubectl logs -n sonarqube -l app=sonarqube --tail=50

# Check SonarQube database
kubectl get pods -n sonarqube -l app=postgresql

# Access SonarQube UI
kubectl port-forward svc/sonarqube-sonarqube -n sonarqube 9000:9000
# Navigate to http://localhost:9000
# Default credentials: admin/admin (change immediately)
```

### Vault (Secrets Management)

```bash
# Check Vault health
kubectl get pods -n vault
kubectl exec -n vault vault-0 -- vault status

# Check all Vault pods are unsealed
for i in 0 1 2; do
  echo "Checking vault-$i:"
  kubectl exec -n vault vault-$i -- vault status | grep "Sealed"
done

# Check Vault operator logs
kubectl logs -n vault -l app.kubernetes.io/name=vault --tail=50
```

### Kyverno (Policy Engine)

```bash
# Check Kyverno health
kubectl get pods -n kyverno
kubectl get clusterpolicies

# Check policy reports
kubectl get policyreports -A

# View policy violations
kubectl get policyreports -A -o json | jq '.items[] | select(.results[].result=="fail") | {namespace: .metadata.namespace, name: .metadata.name, violations: .results}'
```

### Prometheus & Grafana (Observability)

```bash
# Check Prometheus health
kubectl get pods -n prometheus
kubectl get svc -n prometheus

# Check Grafana health
kubectl get pods -n grafana
kubectl get svc -n grafana

# Access Prometheus UI
kubectl port-forward svc/prometheus-kube-prometheus-prometheus -n prometheus 9090:9090
# Navigate to http://localhost:9090

# Access Grafana UI
kubectl port-forward svc/grafana -n grafana 3000:80
# Navigate to http://localhost:3000
# Default credentials: admin/prom-operator
```

### Harbor (Container Registry)

```bash
# Check Harbor health
kubectl get pods -n harbor
kubectl logs -n harbor -l app=harbor --tail=50

# Check Harbor services
kubectl get svc -n harbor

# Access Harbor UI
kubectl port-forward svc/harbor -n harbor 8443:443
# Navigate to https://localhost:8443
# Default credentials: admin/Harbor12345
```

### DevLake (DORA Metrics)

```bash
# Check DevLake health
kubectl get pods -n devlake
kubectl logs -n devlake -l app.kubernetes.io/name=devlake --tail=50

# Check MySQL database
kubectl get pods -n devlake -l app.kubernetes.io/name=mysql

# Access DevLake UI
kubectl port-forward svc/devlake-ui -n devlake 4000:4000
# Navigate to http://localhost:4000
```

---

## Common Operations

### Restarting a Component

```bash
# Restart ArgoCD
kubectl rollout restart deployment argocd-server -n argocd
kubectl rollout restart deployment argocd-repo-server -n argocd

# Restart Backstage
kubectl rollout restart deployment backstage -n backstage

# Restart Jenkins
kubectl rollout restart deployment jenkins -n jenkins

# Restart SonarQube
kubectl rollout restart deployment sonarqube-sonarqube -n sonarqube

# Restart Grafana
kubectl rollout restart deployment grafana -n grafana

# Restart Prometheus (statefulset)
kubectl rollout restart statefulset prometheus-kube-prometheus-prometheus -n prometheus
```

### Scaling Components

```bash
# Scale Backstage
kubectl scale deployment backstage -n backstage --replicas=3

# Scale Jenkins agents (not the controller)
# Note: Jenkins agents are ephemeral and scale automatically

# Scale Grafana
kubectl scale deployment grafana -n grafana --replicas=2

# Note: Some components like Prometheus, Vault are StatefulSets
# and require special procedures for scaling
```

### Updating Component Configuration

```bash
# Update ArgoCD configuration
kubectl edit configmap argocd-cm -n argocd
kubectl rollout restart deployment argocd-server -n argocd

# Update Backstage configuration
kubectl edit configmap backstage-app-config -n backstage
kubectl rollout restart deployment backstage -n backstage

# Update Jenkins configuration (JCasC)
kubectl edit configmap jenkins-casc-config -n jenkins
kubectl rollout restart deployment jenkins -n jenkins
```

### Checking Logs

```bash
# Stream logs from a component
kubectl logs -n <namespace> -l <label-selector> -f

# Get recent logs from all replicas
kubectl logs -n <namespace> -l <label-selector> --tail=100 --all-containers=true

# Get logs from a specific pod
kubectl logs -n <namespace> <pod-name> -c <container-name>

# Export logs for analysis
kubectl logs -n <namespace> -l <label-selector> --since=1h > component-logs.txt
```

### Viewing Events

```bash
# Get recent events for a namespace
kubectl get events -n <namespace> --sort-by='.lastTimestamp'

# Watch events in real-time
kubectl get events -n <namespace> -w

# Filter events by type
kubectl get events -n <namespace> --field-selector type=Warning
```

---

## Troubleshooting

### Pod Not Starting

**Symptoms**: Pod stuck in `Pending`, `ContainerCreating`, or `CrashLoopBackOff` state

**Diagnosis**:
```bash
# Check pod status and events
kubectl describe pod <pod-name> -n <namespace>

# Check pod logs
kubectl logs <pod-name> -n <namespace>

# Check previous container logs if pod restarted
kubectl logs <pod-name> -n <namespace> --previous
```

**Common Causes**:
1. **Insufficient Resources**: Node doesn't have enough CPU/memory
   ```bash
   # Check node resources
   kubectl top nodes
   kubectl describe nodes | grep -A 5 "Allocated resources"
   ```
   **Solution**: Scale down other workloads or add nodes

2. **Image Pull Errors**: Cannot pull container image
   ```bash
   # Check image pull secrets
   kubectl get secrets -n <namespace>
   ```
   **Solution**: Verify Harbor credentials or image name

3. **Configuration Errors**: Invalid ConfigMap or Secret references
   ```bash
   # Verify ConfigMap exists
   kubectl get configmap -n <namespace>

   # Verify Secret exists
   kubectl get secret -n <namespace>
   ```
   **Solution**: Create missing resources or fix references

4. **Policy Violations**: Kyverno blocking pod creation
   ```bash
   # Check policy reports
   kubectl get policyreports -n <namespace>
   ```
   **Solution**: Fix policy violations or update policies

### Service Not Accessible

**Symptoms**: Cannot access service via port-forward or ingress

**Diagnosis**:
```bash
# Check service exists
kubectl get svc -n <namespace>

# Check endpoints
kubectl get endpoints -n <namespace>

# Check ingress
kubectl get ingress -n <namespace>

# Check ingress controller logs
kubectl logs -n ingress-nginx -l app.kubernetes.io/component=controller
```

**Common Causes**:
1. **No Healthy Pods**: Service has no ready endpoints
   ```bash
   kubectl get pods -n <namespace> -o wide
   ```
   **Solution**: Fix pod issues first

2. **Incorrect Service Selector**: Service not matching pods
   ```bash
   kubectl describe svc <service-name> -n <namespace>
   ```
   **Solution**: Update service selector to match pod labels

3. **Ingress Misconfiguration**: TLS or path issues
   ```bash
   kubectl describe ingress <ingress-name> -n <namespace>
   ```
   **Solution**: Verify hostname, paths, and TLS certificates

### ArgoCD Application Out of Sync

**Symptoms**: Application shows `OutOfSync` status in ArgoCD

**Diagnosis**:
```bash
# Check application status
argocd app get <app-name>

# Check differences
argocd app diff <app-name>

# Check sync history
argocd app history <app-name>
```

**Solutions**:
```bash
# Manual sync
argocd app sync <app-name>

# Force sync (if resources deleted)
argocd app sync <app-name> --force

# Sync with prune (remove extra resources)
argocd app sync <app-name> --prune

# Hard refresh (clear cache)
argocd app get <app-name> --hard-refresh
```

### Jenkins Build Failures

**Symptoms**: Builds failing consistently

**Diagnosis**:
```bash
# Check Jenkins agent pods
kubectl get pods -n jenkins -l jenkins/label

# Check Jenkins logs
kubectl logs -n jenkins -l app.kubernetes.io/component=jenkins-controller --tail=200

# Access Jenkins and check build console output
```

**Common Causes**:
1. **Agent Connection Issues**: Agents can't connect to controller
   **Solution**: Check network policies and service endpoints

2. **Insufficient Agent Resources**: Agents running out of memory/CPU
   ```bash
   kubectl top pods -n jenkins -l jenkins/label
   ```
   **Solution**: Increase agent resource requests/limits

3. **Quality Gate Failures**: SonarQube or security scan blocking build
   **Solution**: Review scan results and fix issues or adjust quality gates

### Prometheus Metrics Missing

**Symptoms**: Dashboards show "No data" or metrics not being collected

**Diagnosis**:
```bash
# Check Prometheus targets
kubectl port-forward svc/prometheus-kube-prometheus-prometheus -n prometheus 9090:9090
# Navigate to http://localhost:9090/targets

# Check ServiceMonitor resources
kubectl get servicemonitors -A

# Check Prometheus logs
kubectl logs -n prometheus prometheus-kube-prometheus-prometheus-0
```

**Solutions**:
```bash
# Verify ServiceMonitor exists for component
kubectl get servicemonitor -n <namespace>

# Verify pod has metrics port and prometheus annotations
kubectl describe pod <pod-name> -n <namespace>

# Restart Prometheus to reload configuration
kubectl delete pod -n prometheus prometheus-kube-prometheus-prometheus-0
```

### Vault Sealed

**Symptoms**: Vault pods show "Sealed" status

**Diagnosis**:
```bash
# Check Vault status
kubectl exec -n vault vault-0 -- vault status
```

**Solution**:
```bash
# Unseal Vault (requires unseal keys)
kubectl exec -n vault vault-0 -- vault operator unseal <key-1>
kubectl exec -n vault vault-0 -- vault operator unseal <key-2>
kubectl exec -n vault vault-0 -- vault operator unseal <key-3>

# Repeat for each Vault pod (vault-0, vault-1, vault-2)
```

**Prevention**: Configure auto-unseal with cloud KMS for production

### Certificate Errors

**Symptoms**: TLS errors when accessing services

**Diagnosis**:
```bash
# Check certificates
kubectl get certificates -A

# Check certificate requests
kubectl get certificaterequests -A

# Check cert-manager logs
kubectl logs -n cert-manager -l app=cert-manager
```

**Solutions**:
```bash
# Check certificate status
kubectl describe certificate <cert-name> -n <namespace>

# Force certificate renewal
kubectl delete secret <tls-secret-name> -n <namespace>
kubectl delete certificaterequest -n <namespace> --all

# Restart cert-manager
kubectl rollout restart deployment cert-manager -n cert-manager
```

---

## Maintenance Procedures

### Regular Maintenance Schedule

| Task | Frequency | Procedure |
|------|-----------|-----------|
| Check cluster resource usage | Daily | Run health checks, ensure <70% utilization |
| Review failed pods/jobs | Daily | Check for CrashLoopBackOff, fix issues |
| Check ArgoCD sync status | Daily | Ensure all apps synced |
| Review Prometheus alerts | Daily | Check Grafana for active alerts |
| Update component configurations | Weekly | Apply configuration changes via GitOps |
| Review security scan results | Weekly | Check SonarQube and Trivy reports |
| Rotate Vault secrets | Monthly | Follow secret rotation procedures |
| Update platform components | Monthly | Apply security patches and updates |
| Review DORA metrics | Weekly | Check DevLake dashboards |
| Backup critical data | Daily | Backup databases and persistent volumes |

### Backup Procedures

#### Backup Vault Data

```bash
# Backup Vault data
kubectl exec -n vault vault-0 -- vault operator raft snapshot save /tmp/vault-backup.snap
kubectl cp vault/vault-0:/tmp/vault-backup.snap ./vault-backup-$(date +%Y%m%d).snap
```

#### Backup Backstage Database

```bash
# Backup PostgreSQL (Backstage)
kubectl exec -n backstage db-backstage-dev-1 -- pg_dump -U postgres backstage > backstage-backup-$(date +%Y%m%d).sql
```

#### Backup ArgoCD Configuration

```bash
# Export ArgoCD applications
argocd app list -o yaml > argocd-apps-backup-$(date +%Y%m%d).yaml

# Backup ArgoCD secrets
kubectl get secrets -n argocd -o yaml > argocd-secrets-backup-$(date +%Y%m%d).yaml
```

#### Backup Jenkins Configuration

```bash
# Export Jenkins configuration (JCasC)
kubectl get configmap jenkins-casc-config -n jenkins -o yaml > jenkins-config-backup-$(date +%Y%m%d).yaml

# Backup Jenkins jobs (if not in Git)
kubectl exec -n jenkins jenkins-0 -- tar czf /tmp/jenkins-jobs.tar.gz /var/jenkins_home/jobs
kubectl cp jenkins/jenkins-0:/tmp/jenkins-jobs.tar.gz ./jenkins-jobs-backup-$(date +%Y%m%d).tar.gz
```

### Update Procedures

#### Update Platform Components via ArgoCD

```bash
# 1. Update image tag in Git repository
cd gitops-repo
vi platform/<component>/values.yaml
# Update image.tag to new version

# 2. Commit and push
git add .
git commit -m "Update <component> to version <version>"
git push

# 3. Sync ArgoCD application
argocd app sync <app-name>

# 4. Monitor rollout
kubectl rollout status deployment/<deployment-name> -n <namespace>

# 5. Verify health
kubectl get pods -n <namespace>
```

#### Emergency Rollback

```bash
# Rollback via ArgoCD
argocd app rollback <app-name> <revision-id>

# Or rollback via kubectl
kubectl rollout undo deployment/<deployment-name> -n <namespace>

# Verify rollback
kubectl rollout status deployment/<deployment-name> -n <namespace>
```

---

## Emergency Response

### Severity Levels

| Severity | Definition | Response Time | Escalation |
|----------|-----------|---------------|------------|
| **P0 - Critical** | Platform completely down, no users can access | Immediate | Page on-call engineer |
| **P1 - High** | Major feature broken, significant user impact | < 30 minutes | Notify team lead |
| **P2 - Medium** | Minor feature issue, workaround available | < 4 hours | Create ticket |
| **P3 - Low** | Cosmetic issue, no functional impact | Next business day | Backlog |

### Emergency Contacts

```yaml
# Update with actual contact information
Platform Team Lead: <name> <email> <phone>
SRE On-Call: <name> <email> <phone>
Security Team: <name> <email> <phone>
Cloud Provider Support: <phone> <portal-link>
```

### Incident Response Playbook

#### Step 1: Assess Severity

```bash
# Check overall cluster health
kubectl get nodes
kubectl get pods -A | grep -v Running

# Check critical services
kubectl get pods -n argocd
kubectl get pods -n backstage
kubectl get pods -n jenkins
```

#### Step 2: Gather Information

```bash
# Collect logs
kubectl logs -n <namespace> <pod-name> > incident-logs.txt

# Collect events
kubectl get events -A --sort-by='.lastTimestamp' > incident-events.txt

# Check resource usage
kubectl top nodes > incident-resources.txt
kubectl top pods -A >> incident-resources.txt
```

#### Step 3: Immediate Mitigation

```bash
# If a component is causing issues, scale it down
kubectl scale deployment <deployment-name> -n <namespace> --replicas=0

# If resource exhaustion, delete completed jobs/pods
kubectl delete pod --field-selector status.phase=Succeeded -A
kubectl delete pod --field-selector status.phase=Failed -A

# If storage full, clean up old data
kubectl exec -n <namespace> <pod-name> -- df -h
# Identify and remove large files
```

#### Step 4: Communicate

```markdown
# Incident notification template
Subject: [P0/P1/P2] <Brief Description> - Fawkes Platform

Status: Investigating/Mitigating/Resolved
Impact: <Description of user impact>
Start Time: <timestamp>
Current Status: <Current state>
Next Update: <Expected time>

Actions Taken:
- <Action 1>
- <Action 2>

Next Steps:
- <Next step 1>
- <Next step 2>
```

#### Step 5: Restore Service

```bash
# Apply fix (rollback, restart, scale up, etc.)
# Verify fix
kubectl get pods -n <namespace>
kubectl logs -n <namespace> <pod-name>

# Run smoke tests
# Access UI and verify functionality
```

#### Step 6: Post-Incident

```markdown
# Post-incident review template
1. Timeline of events
2. Root cause analysis
3. Impact assessment
4. Actions taken
5. Lessons learned
6. Action items to prevent recurrence
```

---

## Health Checks

### Automated Health Check Script

Save this as `scripts/health-check.sh`:

```bash
#!/bin/bash

echo "=== Fawkes Platform Health Check ==="
echo "Timestamp: $(date)"
echo

# Cluster health
echo "--- Cluster Health ---"
kubectl get nodes
echo

# Resource utilization
echo "--- Resource Utilization ---"
kubectl top nodes
echo

# Critical namespaces
echo "--- Critical Namespaces ---"
kubectl get namespaces | grep -E 'argocd|backstage|jenkins|prometheus|grafana|vault'
echo

# Pod health
echo "--- Pod Health (Non-Running) ---"
kubectl get pods -A | grep -v Running | grep -v Completed
echo

# ArgoCD sync status
echo "--- ArgoCD Applications ---"
kubectl get applications -n argocd -o custom-columns=NAME:.metadata.name,SYNC:.status.sync.status,HEALTH:.status.health.status
echo

# Prometheus targets
echo "--- Prometheus Targets (Down) ---"
kubectl exec -n prometheus prometheus-kube-prometheus-prometheus-0 -- \
  wget -qO- 'http://localhost:9090/api/v1/targets' | \
  jq -r '.data.activeTargets[] | select(.health!="up") | "\(.labels.job) - \(.health)"'
echo

# Certificate expiry
echo "--- Certificates Expiring Soon ---"
kubectl get certificates -A -o json | \
  jq -r '.items[] | select(.status.notAfter) | "\(.metadata.namespace)/\(.metadata.name): \(.status.notAfter)"'
echo

# Vault seal status
echo "--- Vault Seal Status ---"
for i in 0 1 2; do
  echo -n "vault-$i: "
  kubectl exec -n vault vault-$i -- vault status | grep "Sealed" || echo "Check failed"
done
echo

echo "=== Health Check Complete ==="
```

Make it executable:
```bash
chmod +x scripts/health-check.sh
```

Run daily or on-demand:
```bash
./scripts/health-check.sh
```

---

## Related Documentation

- [Architecture Overview](../architecture.md)
- [Troubleshooting Guide](../troubleshooting.md)
- [AT-E1-001 Validation](./at-e1-001-validation.md)
- [Azure AKS Setup](./azure-aks-setup.md)
- [DORA Metrics Implementation](../playbooks/dora-metrics-implementation.md)
- [Ingress Controller](../playbooks/ingress-controller.md)

---

## Change Log

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2024-12 | 1.0 | Initial Epic 1 runbook | Platform Team |
