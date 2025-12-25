# Session Recording with OpenReplay

## Overview

OpenReplay is an open-source session replay stack that helps you understand user behavior by recording and replaying user sessions. This guide covers deploying and configuring OpenReplay for usability testing on the Fawkes platform.

## Features

- **Session Replay**: Watch exactly what users did
- **Console Logs**: Capture JavaScript errors and logs
- **Network Activity**: Monitor API calls and responses
- **Click Heatmaps**: Visualize where users click
- **Performance Monitoring**: Track page load times
- **Privacy Controls**: Sanitize sensitive data
- **Search and Filter**: Find specific sessions
- **Team Collaboration**: Share sessions with stakeholders

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│  User Browser                                               │
│  ┌─────────────────────┐                                    │
│  │ OpenReplay Tracker  │ ──────┐                           │
│  │ (JavaScript SDK)    │       │                           │
│  └─────────────────────┘       │                           │
└────────────────────────────────┼───────────────────────────┘
                                 │
                                 ▼
┌─────────────────────────────────────────────────────────────┐
│  Kubernetes Cluster (fawkes namespace)                      │
│                                                             │
│  ┌──────────────────┐    ┌──────────────────┐            │
│  │ OpenReplay API   │◄───┤ OpenReplay       │            │
│  │ (Ingestion)      │    │ Frontend         │            │
│  └──────────────────┘    └──────────────────┘            │
│           │                       ▲                        │
│           ▼                       │                        │
│  ┌──────────────────┐            │                        │
│  │ PostgreSQL       │            │                        │
│  │ (Metadata)       │            │                        │
│  └──────────────────┘    ┌───────┴──────────┐            │
│                           │ OpenReplay       │            │
│  ┌──────────────────┐    │ Storage          │            │
│  │ MinIO/S3         │◄───┤ (Session Data)   │            │
│  │ (Recordings)     │    └──────────────────┘            │
│  └──────────────────┘                                      │
└─────────────────────────────────────────────────────────────┘
```

## Prerequisites

- Kubernetes cluster with at least 8GB RAM available
- Storage class for persistent volumes (default: `standard`)
- Ingress controller configured (nginx-ingress)
- DNS configured for OpenReplay domain

## Installation

### Option 1: Using Helm (Recommended)

```bash
# Add OpenReplay Helm repository
helm repo add openreplay https://openreplay.com/charts
helm repo update

# Create namespace
kubectl create namespace openreplay

# Install OpenReplay
helm install openreplay openreplay/openreplay \
  --namespace openreplay \
  --set ingress.enabled=true \
  --set ingress.hosts[0].host=openreplay.fawkes.local \
  --set ingress.tls[0].secretName=openreplay-tls \
  --set ingress.tls[0].hosts[0]=openreplay.fawkes.local \
  --set postgresql.persistence.size=20Gi \
  --set minio.persistence.size=50Gi
```

### Option 2: Using Kustomize and ArgoCD

The OpenReplay deployment is managed by ArgoCD. To deploy:

```bash
# Apply the ArgoCD application
kubectl apply -f platform/apps/openreplay/openreplay-application.yaml

# Check deployment status
kubectl get pods -n openreplay
kubectl get ingress -n openreplay
```

## Configuration

### 1. Access OpenReplay Dashboard

Once deployed, access the dashboard:

```bash
# Get the URL
kubectl get ingress -n openreplay

# If using port-forward for local testing
kubectl port-forward -n openreplay svc/openreplay-frontend 8080:80
```

Navigate to: `https://openreplay.fawkes.local` or `http://localhost:8080`

### 2. Initial Setup

1. **Create Admin Account**:
   - Email: `admin@fawkes.local`
   - Password: [Set secure password]
   - Organization: `Fawkes Platform`

2. **Create Project**:
   - Name: `Fawkes Usability Testing`
   - Purpose: `Usability testing and user research`

3. **Get Tracking Key**:
   - Navigate to Settings → Projects
   - Copy the project key (needed for tracker installation)

### 3. Install Tracker in Applications

#### For Backstage (React)

Edit `platform/apps/backstage/config.yaml`:

```yaml
# Add OpenReplay configuration
app:
  # ... existing config ...
  
  # OpenReplay session recording
  openReplay:
    enabled: true
    projectKey: YOUR_PROJECT_KEY
    ingestPoint: https://openreplay.fawkes.local/ingest
    captureConsole: true
    captureNetwork: true
    sanitize:
      - selector: '[data-sensitive]'
      - selector: '.sensitive-data'
```

Install tracker in Backstage frontend:

```bash
cd platform/apps/backstage/packages/app
npm install @openreplay/tracker
```

Add to `src/App.tsx`:

```typescript
import Tracker from '@openreplay/tracker';

// Initialize OpenReplay
const tracker = new Tracker({
  projectKey: process.env.OPENREPLAY_PROJECT_KEY,
  ingestPoint: 'https://openreplay.fawkes.local/ingest',
  captureConsole: true,
  captureNetwork: true,
  // Sanitize sensitive data
  sanitize: [
    '[data-sensitive]',
    '.sensitive-data',
    'input[type="password"]',
  ],
});

// Start tracking only in usability testing environment
if (process.env.ENABLE_SESSION_RECORDING === 'true') {
  tracker.start();
}

// Optional: Set user metadata (anonymized)
tracker.setUserID('anonymous-user');
tracker.setMetadata('role', 'test-participant');
tracker.setMetadata('session_type', 'usability_test');
```

#### For Other Applications

Similar configuration can be added to:
- Grafana dashboards
- Jenkins UI
- Custom applications

See OpenReplay documentation for framework-specific guides.

### 4. Privacy and Data Sanitization

**Important**: Always sanitize sensitive data before recording.

**Configure Sanitization Rules**:

```javascript
// Sanitize by CSS selector
tracker.sanitize([
  'input[type="password"]',
  'input[type="email"]',
  '[data-sensitive]',
  '.api-key',
  '.secret-token',
  '.credentials',
]);

// Sanitize by regex (in network requests)
tracker.sanitizeNetwork({
  requestSanitizer: (request) => {
    if (request.url.includes('/api/secrets')) {
      request.body = '[REDACTED]';
    }
    return request;
  },
  responseSanitizer: (response) => {
    if (response.headers['content-type'].includes('application/json')) {
      const data = JSON.parse(response.body);
      if (data.apiKey) data.apiKey = '[REDACTED]';
      response.body = JSON.stringify(data);
    }
    return response;
  },
});
```

**Data to Always Sanitize**:
- Passwords
- API keys and tokens
- Email addresses (unless consent given)
- Personal identifiable information (PII)
- Internal URLs and IPs
- Error stack traces with file paths

### 5. Session Metadata

Tag sessions with useful metadata for filtering:

```javascript
// Set user role (anonymized)
tracker.setMetadata('participant_role', 'platform_engineer');
tracker.setMetadata('experience_level', 'senior');
tracker.setMetadata('test_scenario', 'deployment_workflow');
tracker.setMetadata('task_number', '1');

// Track custom events
tracker.event('task_started', { task: 'deploy_application' });
tracker.event('task_completed', { task: 'deploy_application', duration_ms: 120000 });
tracker.event('confusion_point', { element: 'create_button', action: 'looking_for' });
```

## Usage for Usability Testing

### Before Testing Session

1. **Enable Recording**:
   ```bash
   # Set environment variable to enable tracking
   kubectl set env deployment/backstage -n fawkes \
     ENABLE_SESSION_RECORDING=true
   ```

2. **Prepare Session Tags**:
   - Create a unique session ID
   - Prepare metadata tags (participant role, task scenario)

3. **Test Recording**:
   - Do a quick test to ensure recordings are working
   - Verify data is appearing in OpenReplay dashboard

### During Testing Session

1. **Start Session with Metadata**:
   ```javascript
   tracker.setUserID('P01'); // Participant ID
   tracker.setMetadata('test_date', '2025-12-25');
   tracker.setMetadata('facilitator', 'product_team');
   tracker.setMetadata('test_type', 'moderated_remote');
   ```

2. **Tag Task Transitions**:
   ```javascript
   tracker.event('task_1_started');
   // ... user performs task ...
   tracker.event('task_1_completed');
   ```

3. **Mark Confusion Points** (optional):
   ```javascript
   tracker.event('confusion', { 
     location: 'navigation_menu',
     looking_for: 'create_button' 
   });
   ```

### After Testing Session

1. **Find Session**:
   - Go to OpenReplay dashboard
   - Filter by participant ID or metadata
   - Example: `participant_role is platform_engineer AND test_date is 2025-12-25`

2. **Review Recording**:
   - Watch session replay at 1x-2x speed
   - Note timestamps of key moments
   - Check console logs for errors
   - Review network activity

3. **Share with Team**:
   - Generate shareable link
   - Add to usability test notes
   - Include in analysis document

4. **Export Data** (if needed):
   - Export session metadata
   - Download console logs
   - Extract network traces

## Maintenance

### Storage Management

Monitor storage usage:

```bash
# Check PVC usage
kubectl get pvc -n openreplay

# Check MinIO storage
kubectl exec -n openreplay deploy/openreplay-minio -- \
  mc du local/openreplay
```

**Retention Policy**:
- Sessions older than 90 days are automatically deleted
- Adjust in OpenReplay settings: Settings → Storage → Retention

**Manual Cleanup**:

```bash
# Delete sessions older than specific date
# Through OpenReplay UI: Settings → Sessions → Bulk Delete
```

### Backup

Backup PostgreSQL metadata:

```bash
# Create backup
kubectl exec -n openreplay deploy/openreplay-postgresql -- \
  pg_dump -U postgres openreplay > openreplay-backup-$(date +%Y%m%d).sql

# Store in secure location (not in Git)
```

### Monitoring

Check OpenReplay health:

```bash
# Check all pods are running
kubectl get pods -n openreplay

# Check logs
kubectl logs -n openreplay deploy/openreplay-api --tail=100

# Check ingestion
kubectl logs -n openreplay deploy/openreplay-ingestor --tail=100
```

**Metrics to Monitor**:
- Session ingestion rate
- Storage usage
- API response times
- Error rates

## Troubleshooting

### Sessions Not Recording

1. **Check Tracker Installation**:
   ```javascript
   // Verify tracker is initialized
   console.log(tracker.isActive());
   ```

2. **Check Network**:
   - Open browser DevTools → Network
   - Filter for requests to `openreplay.fawkes.local`
   - Check for 200 OK responses

3. **Check CORS**:
   ```bash
   # Verify ingress allows CORS
   kubectl get ingress openreplay -n openreplay -o yaml
   ```

### High Storage Usage

1. **Check Retention Settings**:
   - OpenReplay UI → Settings → Storage
   - Reduce retention period

2. **Clean Up Old Sessions**:
   - Bulk delete through UI
   - Or adjust retention policy

3. **Increase Storage**:
   ```bash
   # Expand PVC
   kubectl patch pvc openreplay-minio-pvc -n openreplay \
     -p '{"spec":{"resources":{"requests":{"storage":"100Gi"}}}}'
   ```

### Performance Issues

1. **Scale Components**:
   ```bash
   # Scale ingestion pods
   kubectl scale deployment openreplay-ingestor -n openreplay --replicas=3
   
   # Scale API pods
   kubectl scale deployment openreplay-api -n openreplay --replicas=2
   ```

2. **Reduce Capture Rate**:
   ```javascript
   // Sample sessions (e.g., only 50% of users)
   if (Math.random() < 0.5) {
     tracker.start();
   }
   ```

## Security Considerations

### Data Privacy

- ✅ Always obtain user consent before recording
- ✅ Clearly communicate what data is being captured
- ✅ Sanitize all sensitive data (passwords, tokens, PII)
- ✅ Use anonymized participant IDs
- ✅ Set appropriate data retention periods
- ✅ Restrict access to recordings (team only)

### Access Control

```bash
# Only product team should have access
# Configure RBAC in OpenReplay settings
# Settings → Team → Roles & Permissions
```

**Roles**:
- **Admin**: Product owner, research lead
- **Member**: Product team, researchers
- **Viewer**: Stakeholders (read-only)

### Network Security

```yaml
# Ensure TLS is enabled
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: openreplay
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
spec:
  tls:
    - hosts:
        - openreplay.fawkes.local
      secretName: openreplay-tls
```

## Best Practices

### Recording Strategy

1. **Only Record When Needed**:
   - Enable only in usability testing environment
   - Don't record in production without explicit consent

2. **Use Metadata Extensively**:
   - Tag every session with relevant context
   - Makes finding sessions much easier

3. **Review Recordings Promptly**:
   - Watch within 24 hours while memory is fresh
   - Take notes with timestamps

4. **Share Selectively**:
   - Only share with people who need to see it
   - Use shareable links with expiration

### Data Management

1. **Regular Cleanup**:
   - Delete sessions after analysis is complete
   - Keep only exemplary sessions for training

2. **Anonymize Everything**:
   - Use participant IDs, not names
   - Remove any PII from metadata

3. **Secure Storage**:
   - Keep raw recordings separate from anonymized notes
   - Encrypt backups

## Resources

### Documentation

- [OpenReplay Official Docs](https://docs.openreplay.com/)
- [Tracker SDK Reference](https://docs.openreplay.com/installation/javascript-sdk)
- [Privacy Configuration](https://docs.openreplay.com/installation/sanitize-data)

### Internal Resources

- [Usability Testing Guide](../how-to/usability-testing-guide.md)
- [Research Repository](../research/README.md)
- [Consent Form](../research/interviews/consent-form.md)

### Support

- **Technical Issues**: `#platform-support` on Mattermost
- **Research Questions**: `#product-research` on Mattermost
- **Product Team**: product-team@fawkes.local

---

**Document Version**: 1.0  
**Last Updated**: December 2025  
**Owner**: Product Team  
**Next Review**: June 2026
