---
title: Focalboard
description: Project management and Kanban boards for the Fawkes platform
---

# Focalboard - Project Management

Focalboard is an open source, self-hosted alternative to Trello, Notion, and Asana. It provides a centralized Kanban board application for the Fawkes platform to manage features, incidents, and stories.

## Overview

Focalboard is deployed as part of the Fawkes platform to provide:

- **Kanban Boards**: Visual task management with drag-and-drop cards
- **Multiple Views**: Board, table, gallery, and calendar views
- **Real-time Collaboration**: Changes are immediately visible to all team members
- **Data Persistence**: All data stored in PostgreSQL with high availability

## Access

| Environment | URL |
|-------------|-----|
| Local Dev | [http://pm.127.0.0.1.nip.io](http://pm.127.0.0.1.nip.io) |
| Production | `https://pm.fawkes.io` |

## Quick Start

### Creating Your First Board

1. Navigate to the Focalboard URL
2. Log in with your platform credentials
3. Click **+ Add Board** to create a new board
4. Choose a template or start from scratch

### Board Templates

The platform provides a default template with the following columns:

| Column | Purpose |
|--------|---------|
| **Backlog** | Items waiting to be prioritized |
| **To Do** | Ready to be worked on |
| **In Progress** | Currently being worked on |
| **Review** | Pending review or approval |
| **Done** | Completed items |

### Working with Cards

1. **Create a Card**: Click **+ New** in any column
2. **Move a Card**: Drag and drop between columns
3. **Edit a Card**: Click to open and add details
4. **Assign Priority**: Use the properties panel to set priority
5. **Add Comments**: Collaborate with team members on cards

## Architecture

```
┌─────────────────────────────────────────────────────┐
│                   Ingress (nginx)                    │
│              pm.127.0.0.1.nip.io                     │
└─────────────────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────┐
│               Focalboard Service                     │
│                  (ClusterIP)                         │
└─────────────────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────┐
│              Focalboard Deployment                   │
│         mattermost/focalboard:7.11.4                 │
│                                                      │
│  ┌─────────────┐    ┌─────────────────────────────┐ │
│  │ Config Vol  │    │    Files PVC (5Gi)          │ │
│  │ (ConfigMap) │    │    Attachments/Uploads      │ │
│  └─────────────┘    └─────────────────────────────┘ │
└─────────────────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────┐
│         PostgreSQL (CloudNativePG)                   │
│         db-focalboard-dev cluster                    │
│         3 replicas for High Availability             │
└─────────────────────────────────────────────────────┘
```

## Configuration

### Environment Variables

The following environment variables are available in `env.example`:

| Variable | Description | Default |
|----------|-------------|---------|
| `FOCALBOARD_URL` | Internal service URL | `http://focalboard.fawkes.svc:8000` |
| `FOCALBOARD_EXTERNAL_URL` | External URL via ingress | `http://pm.127.0.0.1.nip.io` |
| `POSTGRESQL_HOST` | PostgreSQL primary host | `db-focalboard-dev-rw.fawkes.svc.cluster.local` |
| `POSTGRESQL_DATABASE` | Database name | `focalboard` |
| `POSTGRESQL_USER` | Database user | `focalboard_user` |

### Resource Limits

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | 100m | 500m |
| Memory | 128Mi | 512Mi |

### Storage

| Volume | Size | Purpose |
|--------|------|---------|
| PostgreSQL | 10Gi | Database storage (per replica) |
| Files PVC | 5Gi | File attachments and uploads |

## Database

Focalboard uses a dedicated PostgreSQL cluster managed by CloudNativePG:

- **Cluster Name**: `db-focalboard-dev`
- **Instances**: 3 (1 primary + 2 replicas)
- **High Availability**: Automatic failover within 90 seconds
- **TLS**: Encrypted connections required

### Connection Details

```yaml
Host (Read-Write): db-focalboard-dev-rw.fawkes.svc.cluster.local
Host (Read-Only): db-focalboard-dev-ro.fawkes.svc.cluster.local
Port: 5432
Database: focalboard
Username: focalboard_user
SSL Mode: require
```

### Credentials

Database credentials are stored in Kubernetes Secrets:

- **Secret Name**: `db-focalboard-credentials`
- **Keys**: `username`, `password`

For production, use External Secrets Operator to pull credentials from your secret manager.

## Monitoring

Focalboard exposes Prometheus metrics at port 9092:

- **Endpoint**: `http://focalboard.fawkes.svc:9092/metrics`
- **Scrape Interval**: 30s

### Key Metrics

| Metric | Description |
|--------|-------------|
| `focalboard_api_request_duration_seconds` | API request latency |
| `focalboard_active_users` | Number of active users |
| `focalboard_boards_total` | Total number of boards |
| `focalboard_cards_total` | Total number of cards |

## Troubleshooting

### Common Issues

#### Service Not Accessible

1. Check if the pod is running:
   ```bash
   kubectl get pods -n fawkes -l app=focalboard
   ```

2. Check pod logs:
   ```bash
   kubectl logs -n fawkes -l app=focalboard
   ```

3. Verify ingress configuration:
   ```bash
   kubectl get ingress -n fawkes focalboard
   ```

#### Database Connection Failed

1. Verify PostgreSQL cluster is healthy:
   ```bash
   kubectl get cluster -n fawkes db-focalboard-dev
   ```

2. Check database credentials:
   ```bash
   kubectl get secret -n fawkes db-focalboard-credentials
   ```

3. Test database connectivity from the pod:
   ```bash
   kubectl exec -n fawkes -it deployment/focalboard -- \
     psql "postgres://focalboard_user@db-focalboard-dev-rw:5432/focalboard?sslmode=require"
   ```

### Pod Restart Loop

Check for resource constraints:
```bash
kubectl describe pod -n fawkes -l app=focalboard
```

## Related Resources

- [Focalboard GitHub](https://github.com/mattermost/focalboard)
- [Focalboard Documentation](https://docs.mattermost.com/guides/boards.html)
- [PostgreSQL Deployment](postgresql-deployment.feature)
- [CloudNativePG Documentation](https://cloudnative-pg.io/docs/)

## Support

For issues with Focalboard on the Fawkes platform:

1. Check the [Troubleshooting Guide](#troubleshooting)
2. Search existing [GitHub Issues](https://github.com/paruff/fawkes/issues)
3. Open a new issue if needed
4. Contact the Platform Team via Mattermost
