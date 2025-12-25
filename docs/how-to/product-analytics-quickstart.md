# Product Analytics Quick Start Guide

## Quick Deploy

Deploy Plausible Analytics in 5 minutes:

```bash
# 1. Deploy via ArgoCD
kubectl apply -f platform/apps/plausible-application.yaml

# 2. Wait for deployment
kubectl wait --for=condition=Ready pod -l app=plausible -n fawkes --timeout=300s

# 3. Validate
make validate-at-e3-011 NAMESPACE=fawkes
```

## First Login

1. Open https://plausible.fawkes.idp
2. Login with:
   - Email: `admin@fawkes.local`
   - Password: `changeme-admin-password`
3. **⚠️ Change password immediately!**

## Add Your First Site

1. Click **"+ Add website"**
2. Enter domain: `backstage.fawkes.idp`
3. Select timezone
4. Click **"Add site"**

## Start Tracking

Backstage is already configured! Just visit:
https://backstage.fawkes.idp

Check real-time stats in Plausible dashboard.

## Configure Custom Events

1. Go to Site Settings → Goals
2. Click **"+ Add goal"**
3. Add these custom events:
   - `Deploy Application`
   - `Create Service`
   - `View Documentation`
   - `Run Pipeline`

## Track Events from Code

```javascript
// In your application
plausible('Deploy Application', {
  props: {
    language: 'nodejs',
    template: 'express'
  }
})
```

## Next Steps

- [ ] Change default admin password
- [ ] Configure additional sites
- [ ] Set up custom goals
- [ ] Configure data retention (Settings → Data Retention)
- [ ] Explore dashboard features
- [ ] Set up API access (Settings → API Keys)

## Need Help?

- 📖 [Full Documentation](./platform/apps/plausible/README.md)
- 🔧 [Implementation Guide](./docs/implementation-plan/product-analytics-implementation.md)
- 🐛 [Troubleshooting](./platform/apps/plausible/README.md#troubleshooting)
- ✅ [Validation Script](./platform/apps/plausible/validate-plausible.sh)
