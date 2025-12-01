# PostgreSQL Database Service

This document describes how to use and configure the PostgreSQL database service in the Fawkes platform.

## Overview

The Fawkes platform uses [CloudNativePG](https://cloudnative-pg.io/) as the PostgreSQL Operator to manage highly available PostgreSQL clusters on Kubernetes. CloudNativePG provides:

- **High Availability**: Automatic failover with configurable RTO (Recovery Time Objective)
- **Automated Backups**: Point-in-time recovery (PITR) with S3/Azure/GCS object storage
- **TLS Encryption**: Secure connections with TLS certificates
- **Connection Pooling**: PgBouncer integration for connection management
- **Monitoring**: Prometheus metrics and Grafana dashboards

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    CloudNativePG Operator                   │
│                  (cloudnativepg-system namespace)           │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                   PostgreSQL Cluster                        │
│                    (fawkes namespace)                       │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐           │
│  │   Primary   │ │  Replica 1  │ │  Replica 2  │           │
│  │   (RW)      │ │   (RO)      │ │   (RO)      │           │
│  └─────────────┘ └─────────────┘ └─────────────┘           │
│         │                │               │                  │
│         └────────────────┼───────────────┘                  │
│                          ▼                                  │
│                 ┌─────────────────┐                         │
│                 │  Persistent     │                         │
│                 │  Volumes (PVC)  │                         │
│                 └─────────────────┘                         │
└─────────────────────────────────────────────────────────────┘
```

## Naming Convention

Database instances follow the naming pattern:
```
db-{service}-{environment}
```

Examples:
- `db-focalboard-dev`
- `db-focalboard-prod`
- `db-sonarqube-staging`
- `db-backstage-prod`

## Connection Details

### Focalboard Database

| Property | Value |
|----------|-------|
| Host (Primary/RW) | `db-focalboard-dev-rw.fawkes.svc.cluster.local` |
| Host (Replicas/RO) | `db-focalboard-dev-ro.fawkes.svc.cluster.local` |
| Port | `5432` |
| Database | `focalboard` |
| Username | Stored in Secret `db-focalboard-credentials` |
| Password | Stored in Secret `db-focalboard-credentials` |

### SonarQube Database

| Property | Value |
|----------|-------|
| Host (Primary/RW) | `db-sonarqube-dev-rw.fawkes.svc.cluster.local` |
| Host (Replicas/RO) | `db-sonarqube-dev-ro.fawkes.svc.cluster.local` |
| Port | `5432` |
| Database | `sonarqube` |
| Username | Stored in Secret `db-sonarqube-credentials` |
| Password | Stored in Secret `db-sonarqube-credentials` |

**JDBC Connection String** (for SonarQube configuration):
```
jdbc:postgresql://db-sonarqube-dev-rw.fawkes.svc.cluster.local:5432/sonarqube
```

### Connection String Format

```
postgresql://<username>:<password>@<host>:5432/<database>?sslmode=require
```

Example for Focalboard:
```
postgresql://focalboard_user:$(password)@db-focalboard-dev-rw.fawkes.svc.cluster.local:5432/focalboard?sslmode=require
```

## Requesting a New Database

To provision a new database instance for your service:

### 1. Create Credentials Secret

Create a secret with your database credentials in `platform/apps/postgresql/`:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: db-{service}-credentials
  namespace: fawkes
  labels:
    app: {service}
    component: database
    environment: dev
type: kubernetes.io/basic-auth
stringData:
  username: {service}_user
  password: {secure_password}
```

### 2. Create Cluster Resource

Create a CloudNativePG Cluster resource:

```yaml
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: db-{service}-dev
  namespace: fawkes
  labels:
    app: {service}
    component: database
    environment: dev
spec:
  instances: 3  # HA with 1 primary + 2 replicas
  imageName: ghcr.io/cloudnative-pg/postgresql:16.4

  bootstrap:
    initdb:
      database: {service}
      owner: {service}_user
      secret:
        name: db-{service}-credentials

  storage:
    size: 10Gi
    storageClass: standard

  resources:
    requests:
      cpu: 500m
      memory: 512Mi
    limits:
      cpu: 2
      memory: 2Gi
```

### 3. Update Kustomization

Add your resources to `platform/apps/postgresql/kustomization.yaml`:

```yaml
resources:
  - db-{service}-credentials.yaml
  - db-{service}-cluster.yaml
```

### 4. Commit and Sync

Commit your changes and ArgoCD will automatically deploy the database.

## Connecting Your Application

### Environment Variables

Configure your application with these environment variables:

```yaml
env:
  - name: DATABASE_HOST
    value: "db-focalboard-dev-rw.fawkes.svc.cluster.local"
  - name: DATABASE_PORT
    value: "5432"
  - name: DATABASE_NAME
    value: "focalboard"
  - name: DATABASE_USER
    valueFrom:
      secretKeyRef:
        name: db-focalboard-credentials
        key: username
  - name: DATABASE_PASSWORD
    valueFrom:
      secretKeyRef:
        name: db-focalboard-credentials
        key: password
  - name: DATABASE_SSLMODE
    value: "require"
```

### Read-Only Access

For dashboards and reporting tools that only need read access:

1. Use the read-only service endpoint: `db-focalboard-dev-ro.fawkes.svc.cluster.local`
2. Use read-only credentials: `db-focalboard-readonly-credentials`

```yaml
env:
  - name: DATABASE_HOST
    value: "db-focalboard-dev-ro.fawkes.svc.cluster.local"
  - name: DATABASE_USER
    valueFrom:
      secretKeyRef:
        name: db-focalboard-readonly-credentials
        key: username
```

## Connection Pooling

For applications with high connection requirements, use PgBouncer. CloudNativePG provides built-in pooler support:

```yaml
apiVersion: postgresql.cnpg.io/v1
kind: Pooler
metadata:
  name: db-focalboard-dev-pooler
  namespace: fawkes
spec:
  cluster:
    name: db-focalboard-dev
  instances: 2
  type: rw
  pgbouncer:
    poolMode: transaction
    parameters:
      max_client_conn: "1000"
      default_pool_size: "50"
```

## High Availability and Failover

### Recovery Objectives

| Metric | Target |
|--------|--------|
| RTO (Recovery Time Objective) | < 90 seconds |
| RPO (Recovery Point Objective) | 0 (synchronous) or near-zero (async) |

### Testing Failover

To test failover in a development environment:

```bash
# Delete the primary pod to trigger failover
kubectl delete pod db-focalboard-dev-1 -n fawkes

# Watch the cluster status
kubectl get cluster db-focalboard-dev -n fawkes -w
```

## Backup and Restore

### Backup Configuration

For production, configure backups to object storage:

```yaml
spec:
  backup:
    barmanObjectStore:
      destinationPath: s3://fawkes-db-backups/focalboard/
      s3Credentials:
        accessKeyId:
          name: db-backup-credentials
          key: ACCESS_KEY_ID
        secretAccessKey:
          name: db-backup-credentials
          key: SECRET_ACCESS_KEY
      wal:
        compression: gzip
      data:
        compression: gzip
    retentionPolicy: "30d"
```

### Point-in-Time Recovery (PITR)

To restore to a specific point in time:

```yaml
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: db-focalboard-dev-restored
spec:
  instances: 3
  bootstrap:
    recovery:
      source: db-focalboard-dev
      recoveryTarget:
        targetTime: "2024-01-15 10:30:00 UTC"
  externalClusters:
    - name: db-focalboard-dev
      barmanObjectStore:
        destinationPath: s3://fawkes-db-backups/focalboard/
        s3Credentials:
          accessKeyId:
            name: db-backup-credentials
            key: ACCESS_KEY_ID
          secretAccessKey:
            name: db-backup-credentials
            key: SECRET_ACCESS_KEY
```

## Monitoring

### Prometheus Metrics

CloudNativePG exposes metrics at `/metrics` endpoint on each pod. Key metrics:

- `cnpg_pg_replication_lag` - Replication lag in seconds
- `cnpg_pg_stat_bgwriter_*` - Background writer statistics
- `cnpg_pg_database_size_bytes` - Database size
- `cnpg_pg_connections` - Active connections

### Grafana Dashboards

Import the official CloudNativePG Grafana dashboard:
- Dashboard ID: `20417`

## Troubleshooting

### Check Cluster Status

```bash
kubectl get cluster -n fawkes
kubectl describe cluster db-focalboard-dev -n fawkes
```

### View Pod Logs

```bash
kubectl logs -n fawkes -l cnpg.io/cluster=db-focalboard-dev --tail=100
```

### Connect to PostgreSQL

```bash
kubectl exec -it db-focalboard-dev-1 -n fawkes -- psql -U focalboard_user -d focalboard
```

### Check Replication Status

```sql
SELECT * FROM pg_stat_replication;
```

## Security Best Practices

1. **Use External Secrets**: For production, use External Secrets Operator to manage credentials
2. **Rotate Passwords**: Implement regular password rotation
3. **Network Policies**: Restrict database access to authorized pods only
4. **TLS Required**: Always use `sslmode=require` in connection strings
5. **Least Privilege**: Create separate users for read-only access

## References

- [CloudNativePG Documentation](https://cloudnative-pg.io/documentation/)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [Fawkes Platform Handbook](../../../docs/index.md)
