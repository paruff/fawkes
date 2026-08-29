---
title: Sealed Secrets Backup Strategy
description: Backup and disaster recovery for Bitnami Sealed Secrets in Fawkes
---

# Sealed Secrets Backup Strategy

This document describes the backup and disaster recovery strategy for Bitnami Sealed Secrets in Fawkes.

## What Needs Backup

The critical component to backup is the **Sealed Secrets private key** (stored in a Kubernetes Secret in `kube-system` namespace). Without this key, you cannot decrypt existing SealedSecrets.

### Components to Backup

| Component | Location | Criticality | Backup Frequency |
|-----------|----------|-------------|------------------|
| Private Key | `kube-system` namespace, Secret with label `sealedsecrets.bitnami.com/sealed-secrets-key` | **CRITICAL** | Every change + daily |
| Public Certificate | Can be derived from private key | Low | Not needed |
| SealedSecret Resources | Git repository (platform/apps/) | Medium | Git history |
| Controller Config | Helm values / ArgoCD Application | Low | Git history |

## Backup Methods

### Method 1: Automated Backup CronJob (Recommended)

Deploy a CronJob that backs up the private key to secure storage.

```yaml
# platform/apps/sealed-secrets/backup-cronjob.yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: sealed-secrets-backup
  namespace: kube-system
  labels:
    app: sealed-secrets-backup
    component: backup
spec:
  schedule: "0 2 * * *"  # Daily at 2 AM UTC
  successfulJobsHistoryLimit: 3
  failedJobsHistoryLimit: 3
  concurrencyPolicy: Forbid
  jobTemplate:
    spec:
      ttlSecondsAfterFinished: 86400  # 24 hours
      template:
        spec:
          serviceAccountName: sealed-secrets-backup-sa
          restartPolicy: OnFailure
          containers:
          - name: backup
            image: bitnami/kubectl:1.28
            imagePullPolicy: IfNotPresent
            env:
            - name: BACKUP_BUCKET
              value: "s3://fawkes-sealed-secrets-backups"
            - name: ENCRYPTION_KEY
              valueFrom:
                secretKeyRef:
                  name: backup-encryption-key
                  key: key
            command:
            - /bin/bash
            - -c
            - |
              set -euo pipefail
              
              TIMESTAMP=$(date -u +%Y%m%d-%H%M%S)
              BACKUP_FILE="sealed-secrets-key-${TIMESTAMP}.yaml.enc"
              
              # Get the private key secret
              kubectl get secret -n kube-system \
                -l sealedsecrets.bitnami.com/sealed-secrets-key \
                -o yaml > /tmp/sealed-secrets-key.yaml
              
              # Encrypt backup
              gpg --symmetric --cipher-algo AES256 \
                --passphrase "${ENCRYPTION_KEY}" \
                --output "/tmp/${BACKUP_FILE}" \
                /tmp/sealed-secrets-key.yaml
              
              # Upload to S3 (or GCS, Azure Blob)
              aws s3 cp "/tmp/${BACKUP_FILE}" "${BACKUP_BUCKET}/${BACKUP_FILE}"
              
              # Verify upload
              aws s3 ls "${BACKUP_BUCKET}/${BACKUP_FILE}"
              
              echo "Backup completed: ${BACKUP_FILE}"
---
# RBAC for backup job
apiVersion: v1
kind: ServiceAccount
metadata:
  name: sealed-secrets-backup-sa
  namespace: kube-system
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: sealed-secrets-backup-role
  namespace: kube-system
rules:
- apiGroups: [""]
  resources: ["secrets"]
  verbs: ["get", "list"]
  resourceNames: ["sealed-secrets-key"]  # Specific key name varies
- apiGroups: [""]
  resources: ["secrets"]
  verbs: ["get", "list"]
  selector:
    matchLabels:
      sealedsecrets.bitnami.com/sealed-secrets-key: "true"
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: sealed-secrets-backup-binding
  namespace: kube-system
subjects:
- kind: ServiceAccount
  name: sealed-secrets-backup-sa
  namespace: kube-system
roleRef:
  kind: Role
  name: sealed-secrets-backup-role
  apiGroup: rbac.authorization.k8s.io
```

### Method 2: Manual Backup (One-time / Ad-hoc)

```bash
# Backup the private key
kubectl get secret -n kube-system \
  -l sealedsecrets.bitnami.com/sealed-secrets-key \
  -o yaml > sealed-secrets-key-backup-$(date +%Y%m%d).yaml

# Encrypt before storing
gpg --symmetric --cipher-algo AES256 \
  --output sealed-secrets-key-backup-$(date +%Y%m%d).yaml.gpg \
  sealed-secrets-key-backup-$(date +%Y%m%d).yaml

# Store in secure location (password manager, encrypted drive, HSM)
```

### Method 3: Velero Integration (Cluster Backup)

If using Velero for cluster backups:

```yaml
# Include in Velero backup
velero backup create sealed-secrets-backup \
  --include-namespaces kube-system \
  --selector sealedsecrets.bitnami.com/sealed-secrets-key=true \
  --wait
```

## Recovery Procedures

### Scenario 1: Controller Restart (Key Persists)

If the controller pod restarts but the key Secret persists:

```bash
# No action needed - controller reads existing key
# Verify:
kubectl get secret -n kube-system -l sealedsecrets.bitnami.com/sealed-secrets-key
kubectl logs -n kube-system deployment/sealed-secrets-controller | head -20
```

### Scenario 2: Key Secret Deleted (Cluster Intact)

If the key Secret is deleted but cluster is otherwise healthy:

```bash
# 1. Restore key from backup
kubectl apply -f sealed-secrets-key-backup-YYYYMMDD.yaml

# 2. Restart controller to pick up restored key
kubectl rollout restart deployment/sealed-secrets-controller -n kube-system

# 3. Verify controller can decrypt
kubectl get sealedsecret -A -o custom-columns=NAME:.metadata.name,NAMESPACE:.metadata.namespace,STATUS:.status.conditions[0].status
```

### Scenario 3: Full Cluster Loss (Disaster Recovery)

Complete cluster loss - restore to new cluster:

#### Prerequisites

- New Kubernetes cluster provisioned
- ArgoCD installed
- Sealed Secrets Helm chart deployed (but not yet synced)

#### Recovery Steps

```bash
# 1. Install Sealed Secrets controller (do NOT let it generate new key)
helm install sealed-secrets oci://registry-1.docker.io/bitnamicharts/sealed-secrets \
  --namespace kube-system \
  --version 2.19.3 \
  --set keyRenewalPeriod=0 \
  --wait

# 2. Restore private key from backup
gpg --decrypt --output /tmp/sealed-secrets-key.yaml sealed-secrets-key-backup-YYYYMMDD.yaml.gpg
kubectl apply -f /tmp/sealed-secrets-key.yaml

# 3. Restart controller to load restored key
kubectl rollout restart deployment/sealed-secrets-controller -n kube-system

# 4. Deploy ArgoCD Applications (will sync SealedSecrets)
# ArgoCD will apply all SealedSecrets from Git

# 5. Verify all secrets decrypted
kubectl get sealedsecret -A --no-headers | wc -l
kubectl get sealedsecret -A -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.conditions[?(@.type=="SealedSecretDecrypted")].status}{"\n"}{end}' | grep -v True
```

## Backup Verification

### Regular Verification (Monthly)

```bash
#!/bin/bash
# verify-backup.sh

BACKUP_FILE="sealed-secrets-key-backup-YYYYMMDD.yaml.gpg"

# 1. Decrypt backup
gpg --decrypt --output /tmp/test-restore.yaml "$BACKUP_FILE"

# 2. Validate YAML structure
kubectl apply --dry-run=client -f /tmp/test-restore.yaml

# 3. Verify key format
yq '.data."tls.key"' /tmp/test-restore.yaml | base64 -d | openssl rsa -check -noout

# 4. Test decryption (in test cluster or namespace)
# Create test SealedSecret with known value
# Verify it decrypts correctly

echo "Backup verification: PASSED"
```

### Automated Verification in CI

```groovy
stage('Verify Sealed Secrets Backup') {
    when {
        cron '0 3 * * 1'  // Weekly on Monday
    }
    steps {
        container('kubectl') {
            sh '''
            # Download latest backup
            aws s3 cp s3://fawkes-sealed-secrets-backups/ \
              --recursive --exclude "*" --include "*.gpg" \
              --query "reverse(sort_by(Contents, &LastModified))[0].Key" \
              --output text | read LATEST_BACKUP
            
            aws s3 cp "s3://fawkes-sealed-secrets-backups/${LATEST_BACKUP}" /tmp/
            
            # Run verification script
            ./scripts/verify-sealed-secrets-backup.sh "/tmp/${LATEST_BACKUP}"
            '''
        }
    }
}
```

## Storage Locations

### Primary: Encrypted S3 Bucket

```bash
# Bucket configuration
Bucket: fawkes-sealed-secrets-backups
Encryption: SSE-KMS (AWS KMS key)
Versioning: Enabled
Lifecycle: Delete after 90 days
Access: Restricted to backup role + security team
```

### Secondary: Encrypted GCS Bucket (Cross-region)

```bash
# Cross-region redundancy
Bucket: fawkes-sealed-secrets-backups-dr
Region: us-east-1 (if primary is us-west-2)
Same encryption and lifecycle
```

### Tertiary: Offline/Offsite

- Encrypted USB drives in secure physical storage
- Updated quarterly
- Tested annually

## Key Rotation and Backup

When rotating the Sealed Secrets key (see [Rotation Guide](rotate-sealed-secrets.md)):

1. **Backup OLD key** before rotation
2. **Backup NEW key** immediately after rotation
3. **Keep both** until all SealedSecrets re-sealed
4. **Archive old key** after verification

## Access Control

| Role | Permissions |
|------|-------------|
| Platform Engineers | Create/view backups, initiate restore |
| Security Team | Full access, audit logs |
| Automation (CI/CD) | Write-only to backup bucket |
| Developers | No access |

## Monitoring and Alerting

### Alert: Backup Job Failed

```yaml
# PrometheusRule
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: sealed-secrets-backup-alerts
  namespace: monitoring
spec:
  groups:
  - name: sealed-secrets-backup
    rules:
    - alert: SealedSecretsBackupFailed
      expr: |
        kube_job_status_failed{job="sealed-secrets-backup"} > 0
      for: 5m
      labels:
        severity: critical
      annotations:
        summary: "Sealed Secrets backup job failed"
        description: "Backup job has failed. Private key not backed up."
```

### Alert: Backup Age

```yaml
- alert: SealedSecretsBackupStale
  expr: |
    time() - kube_job_status_succeeded_timestamp{job="sealed-secrets-backup"} > 86400 * 2
  for: 1h
  labels:
    severity: warning
  annotations:
    summary: "Sealed Secrets backup is stale"
    description: "No successful backup in 48 hours."
```

## Disaster Recovery Testing

### Quarterly DR Drill

1. Provision test cluster (kind/k3d or temporary EKS)
2. Restore key from backup
3. Deploy Sealed Secrets controller
4. Apply sample SealedSecrets from Git
5. Verify decryption
6. Document RTO/RPO

### RTO/RPO Targets

| Metric | Target |
|--------|--------|
| RPO (Recovery Point Objective) | 24 hours (daily backup) |
| RTO (Recovery Time Objective) | 2 hours (automated restore) |

## Related Documentation

- [Sealed Secrets Developer Guide](sealed-secrets-guide.md)
- [Sealed Secrets Rotation](rotate-sealed-secrets.md)
- [Velero Backup Documentation](../../operations/velero-backup.md)
- [Disaster Recovery Plan](../../operations/disaster-recovery.md)

---

*Last updated: 2025*
*Part of Fawkes security documentation*