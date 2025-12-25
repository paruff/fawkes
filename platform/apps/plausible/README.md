# Plausible Analytics

## Overview

Plausible is a privacy-focused, open-source web analytics platform that provides insights into platform usage without tracking individual users or using cookies. It's fully GDPR, CCPA, and PECR compliant out of the box.

## Key Features

- **Privacy-First**: No cookies, no personal data collection
- **GDPR Compliant**: Privacy by design, no consent banners needed
- **Lightweight**: < 1KB script size
- **Real-time Dashboard**: Live visitor data and page views
- **Custom Events**: Track button clicks, form submissions, and other interactions
- **Simple & Clean UI**: Easy to understand metrics and trends

## Architecture

Plausible consists of:

1. **Plausible Application**: Main web application (Port 8000)
2. **PostgreSQL**: Metadata storage (users, sites, settings)
3. **ClickHouse**: Analytics data storage (events, page views)

```
┌─────────────┐
│  Backstage  │──┐
└─────────────┘  │
                 │ Tracking Script
┌─────────────┐  │
│ Other Apps  │──┤
└─────────────┘  │
                 ▼
         ┌──────────────┐
         │  Plausible   │
         │  Analytics   │
         └──────┬───────┘
                │
      ┌─────────┴─────────┐
      │                   │
      ▼                   ▼
┌──────────┐      ┌──────────────┐
│PostgreSQL│      │ ClickHouse   │
│(Metadata)│      │(Events/Stats)│
└──────────┘      └──────────────┘
```

## Deployment

### Prerequisites

- PostgreSQL cluster deployed (`db-plausible-dev`)
- Ingress controller configured
- Cert-manager for TLS certificates

### Deploy with ArgoCD

```bash
kubectl apply -f platform/apps/plausible-application.yaml
```

### Manual Deployment

```bash
# Apply PostgreSQL resources first
kubectl apply -f platform/apps/postgresql/db-plausible-cluster.yaml
kubectl apply -f platform/apps/postgresql/db-plausible-credentials.yaml

# Wait for database to be ready
kubectl wait --for=condition=Ready cluster/db-plausible-dev -n fawkes --timeout=300s

# Deploy Plausible
kubectl apply -k platform/apps/plausible/
```

## Configuration

### Environment Variables

Key configuration options in `plausible-config` ConfigMap:

- `BASE_URL`: Public URL for Plausible (https://plausible.fawkes.idp)
- `DISABLE_REGISTRATION`: Prevent public signups (true)
- `DISABLE_AUTH`: Disable authentication (false for production)
- `LOG_FAILED_LOGIN_ATTEMPTS`: GDPR compliance (false)

### Secrets

Update these secrets before production deployment:

```bash
# Generate a secure secret key base
openssl rand -base64 64 | tr -d '\n'

# Update the secret
kubectl create secret generic plausible-secret \
  --from-literal=SECRET_KEY_BASE="<your-secret-key>" \
  --from-literal=ADMIN_USER_EMAIL="admin@your-domain.com" \
  --from-literal=ADMIN_USER_NAME="Platform Admin" \
  --from-literal=ADMIN_USER_PWD="<secure-password>" \
  --dry-run=client -o yaml | kubectl apply -f -
```

## Access

- **Dashboard**: https://plausible.fawkes.idp
- **Default Credentials**:
  - Email: `admin@fawkes.local`
  - Password: `changeme-admin-password` (Change immediately!)

## Instrumenting Applications

### Backstage

Add to `app-config.yaml`:

```yaml
app:
  analytics:
    plausible:
      domain: backstage.fawkes.idp
      src: https://plausible.fawkes.idp/js/script.js
```

### Manual Integration

Add this script tag to your application's HTML:

```html
<script defer data-domain="your-app.fawkes.idp" src="https://plausible.fawkes.idp/js/script.js"></script>
```

### Custom Events

Track custom events using JavaScript:

```javascript
// Track a button click
plausible('Click', {props: {button: 'deploy-app'}})

// Track a form submission
plausible('Signup', {props: {method: 'github'}})

// Track with custom properties
plausible('Feature Used', {props: {feature: 'scaffolding', language: 'nodejs'}})
```

## Dashboard Features

### Available Metrics

- **Top Pages**: Most visited pages
- **Top Sources**: Traffic sources (direct, referral, etc.)
- **Locations**: Geographic distribution (country-level only)
- **Devices**: Desktop vs Mobile
- **Browsers**: Browser distribution
- **Operating Systems**: OS distribution
- **Custom Events**: Tracked interactions and conversions

### Goals and Funnels

1. Navigate to Site Settings → Goals
2. Add custom event goals
3. Track conversion rates
4. Create funnels for multi-step flows

Example goals:
- `Deploy Application`
- `Create New Service`
- `View Documentation`
- `Run CI/CD Pipeline`

## Privacy & Compliance

### GDPR Compliance

Plausible is GDPR compliant by default:

- ✅ No cookies
- ✅ No personal data collection
- ✅ All data aggregated
- ✅ No cross-site tracking
- ✅ No third-party data sharing

### Data Retention

Default retention: **All data kept indefinitely**

To configure data retention:

1. Navigate to Site Settings
2. Set retention period (e.g., 6 months, 1 year)
3. Old data automatically purged

## Monitoring

### Health Checks

- **Liveness**: `GET /api/health`
- **Readiness**: `GET /api/health`

### Metrics

Plausible exposes internal metrics for monitoring:

```bash
# Check service health
kubectl exec -it deployment/plausible -n fawkes -- wget -O- http://localhost:8000/api/health
```

## Troubleshooting

### Common Issues

#### 1. Plausible not starting

```bash
# Check logs
kubectl logs -n fawkes deployment/plausible

# Check database connection
kubectl exec -it deployment/plausible -n fawkes -- env | grep DATABASE
```

#### 2. Script not loading

- Verify ingress is configured correctly
- Check CORS settings in Backstage
- Ensure `data-domain` matches configured site

#### 3. Events not tracking

- Verify custom domain is added in Plausible dashboard
- Check browser console for errors
- Ensure script is loaded before calling `plausible()`

### Validation

```bash
# Run validation script
./platform/apps/plausible/validate-plausible.sh

# Check all components
kubectl get pods -n fawkes -l app=plausible
kubectl get svc -n fawkes -l app=plausible
kubectl get ingress -n fawkes plausible
```

## Resources

- [Official Documentation](https://plausible.io/docs)
- [API Documentation](https://plausible.io/docs/stats-api)
- [GitHub Repository](https://github.com/plausible/analytics)
- [Self-Hosting Guide](https://plausible.io/docs/self-hosting)

## Acceptance Criteria

- [x] Analytics platform deployed (Plausible)
- [x] GDPR-compliant configuration
- [x] Cookie-less tracking implemented
- [x] Custom event tracking configured
- [x] Dashboard accessible to team
- [x] Data retention policies set
