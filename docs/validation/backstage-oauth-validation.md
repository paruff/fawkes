# Backstage GitHub OAuth Validation Checklist

## Overview

This checklist validates that GitHub OAuth authentication is properly configured for Backstage.

## Prerequisites

- [ ] Backstage is deployed and running
- [ ] GitHub OAuth app has been created
- [ ] OAuth credentials are configured in Kubernetes secrets

## Validation Steps

### 1. Verify OAuth Credentials Secret

```bash
# Check secret exists
kubectl get secret backstage-oauth-credentials -n fawkes

# Verify secret has required keys (don't decode values in production)
kubectl get secret backstage-oauth-credentials -n fawkes -o jsonpath='{.data}' | grep -o '"[^"]*"' | head -5

# Expected output should show:
# "github-client-id"
# "github-client-secret"
```

**Expected Result**: ✅ Secret exists with both required keys

### 2. Verify Environment Variables in Backstage Pods

```bash
# Check environment variables are set
kubectl exec -n fawkes deployment/backstage -- printenv | grep AUTH_GITHUB

# Expected output:
# AUTH_GITHUB_CLIENT_ID=<your-client-id>
# AUTH_GITHUB_CLIENT_SECRET=<redacted>
```

**Expected Result**: ✅ Both environment variables are set and don't contain "CHANGE_ME"

### 3. Verify App Configuration

```bash
# Check app-config has auth section
kubectl get configmap backstage-app-config -n fawkes -o yaml | grep -A 10 "auth:"

# Expected output should include:
# auth:
#   environment: production
#   providers:
#     github:
#       production:
#         clientId: ${AUTH_GITHUB_CLIENT_ID}
#         clientSecret: ${AUTH_GITHUB_CLIENT_SECRET}
```

**Expected Result**: ✅ Auth configuration is present with GitHub provider

### 4. Test OAuth Callback Endpoint

```bash
# Get a Backstage pod name
POD_NAME=$(kubectl get pods -n fawkes -l app.kubernetes.io/name=backstage -o jsonpath='{.items[0].metadata.name}')

# Test callback endpoint (should return 404 or 400 without auth code, not 500)
kubectl exec -n fawkes $POD_NAME -- curl -s -o /dev/null -w '%{http_code}' http://localhost:7007/api/auth/github/handler/frame

# Expected: 404 or 400 (not 500 which indicates config error)
```

**Expected Result**: ✅ Returns 404 or 400 (endpoint exists but needs auth code)

### 5. Test Health Check Endpoint

```bash
# Verify Backstage is healthy
kubectl exec -n fawkes $POD_NAME -- curl -s http://localhost:7007/healthcheck

# Expected: {"status":"ok"}
```

**Expected Result**: ✅ Health check returns OK

### 6. Verify GitHub OAuth App Configuration

Manually verify in GitHub:

1. Go to your OAuth app settings:
   - Personal: https://github.com/settings/developers
   - Organization: https://github.com/organizations/YOUR_ORG/settings/applications

2. Check configuration:
   - [ ] Application name is descriptive (e.g., "Fawkes Backstage - Production")
   - [ ] Homepage URL matches your Backstage URL
   - [ ] Authorization callback URL is: `https://backstage.fawkes.idp/api/auth/github/handler/frame`
   - [ ] Callback URL uses correct protocol (http for local, https for production)
   - [ ] Callback URL ends with `/api/auth/github/handler/frame`

**Expected Result**: ✅ All OAuth app settings are correct

### 7. Test Login Flow (Manual)

1. **Access Backstage**:
   ```bash
   # If using port-forward for local testing:
   kubectl port-forward -n fawkes svc/backstage 7007:7007
   
   # Open browser to: http://localhost:7007
   # Or for production: https://backstage.fawkes.idp
   ```

2. **Verify Login Button**:
   - [ ] "Sign in with GitHub" button is visible on the page
   - [ ] No error messages are displayed on the login page

3. **Test Authentication**:
   - [ ] Click "Sign in with GitHub"
   - [ ] Browser redirects to GitHub
   - [ ] GitHub shows OAuth authorization prompt
   - [ ] Authorization prompt shows correct app name
   - [ ] After clicking "Authorize", browser redirects back to Backstage
   - [ ] User is logged in (username visible in top-right corner)
   - [ ] No console errors in browser developer tools

**Expected Result**: ✅ Complete login flow works without errors

### 8. Test Permissions (Manual)

After logging in:

1. **Access Service Catalog**:
   - [ ] Navigate to "Catalog" section
   - [ ] Can view catalog entities
   - [ ] Username/identity is displayed correctly

2. **Test Authenticated Routes**:
   - [ ] Can access all main sections (Catalog, Create, Docs)
   - [ ] No unexpected "unauthorized" errors

**Expected Result**: ✅ All routes accessible after authentication

### 9. Test Logout

1. **Logout**:
   - [ ] Click username in top-right corner
   - [ ] Click "Sign Out"
   - [ ] Redirected to login page
   - [ ] Cannot access protected routes without re-authentication

**Expected Result**: ✅ Logout works and session is terminated

### 10. Verify Logs

```bash
# Check Backstage logs for auth-related messages
kubectl logs -n fawkes -l app.kubernetes.io/name=backstage --tail=100 | grep -i auth

# Look for successful auth messages, no errors like:
# ❌ "GitHub OAuth configuration error"
# ❌ "Invalid client ID or secret"
# ✅ "GitHub authentication successful"
```

**Expected Result**: ✅ No auth errors in logs

## Run BDD Acceptance Tests

```bash
# Run OAuth authentication tests
cd /home/runner/work/fawkes/fawkes
behave tests/bdd/features/backstage-deployment.feature --tags=@authentication
```

**Expected Result**: ✅ All authentication tests pass

## Common Issues and Solutions

### Issue 1: "Invalid redirect_uri" Error

**Symptoms**: Error when clicking "Sign in with GitHub"

**Diagnosis**:
```bash
# Check callback URL in secret
kubectl get secret backstage-oauth-credentials -n fawkes -o jsonpath='{.data.github-client-id}' | base64 -d
```

**Solution**: 
- Verify callback URL in GitHub OAuth app matches: `https://backstage.fawkes.idp/api/auth/github/handler/frame`
- Check protocol (http vs https)
- Check for trailing slashes
- Update GitHub OAuth app if needed

### Issue 2: "GitHub OAuth configuration error"

**Symptoms**: Error in logs about OAuth configuration

**Diagnosis**:
```bash
# Check if secrets contain placeholder values
kubectl get secret backstage-oauth-credentials -n fawkes -o yaml | grep CHANGE_ME
```

**Solution**:
- Update secrets with real GitHub OAuth credentials
- Apply updated secret: `kubectl apply -f platform/apps/backstage/secrets.yaml`
- Restart Backstage: `kubectl rollout restart deployment/backstage -n fawkes`

### Issue 3: Login Button Not Visible

**Symptoms**: No "Sign in with GitHub" button on login page

**Diagnosis**:
```bash
# Check app-config has auth section
kubectl get configmap backstage-app-config -n fawkes -o yaml | grep -A 5 "auth:"
```

**Solution**:
- Verify app-config.yaml has auth.providers.github section
- Check environment variables are properly injected
- Restart Backstage pods

### Issue 4: 500 Error on Callback

**Symptoms**: After GitHub authorization, get 500 error

**Diagnosis**:
```bash
# Check Backstage logs for errors
kubectl logs -n fawkes -l app.kubernetes.io/name=backstage --tail=50
```

**Solution**:
- Verify client secret is correct (regenerate if needed)
- Check database connectivity
- Ensure all environment variables are set correctly

## Success Criteria

All of the following must be true:

- ✅ OAuth credentials secret exists and is correctly configured
- ✅ Environment variables are set in Backstage pods
- ✅ App configuration includes GitHub auth provider
- ✅ OAuth callback endpoint responds (not 500)
- ✅ Health check passes
- ✅ GitHub OAuth app configuration is correct
- ✅ Login flow completes successfully
- ✅ User identity is displayed after login
- ✅ Permissions work correctly
- ✅ Logout works correctly
- ✅ No auth errors in logs
- ✅ BDD tests pass

## Sign-Off

- [ ] Validated by: ________________
- [ ] Date: ________________
- [ ] Environment: [ ] Development [ ] Staging [ ] Production
- [ ] Issues found: ________________
- [ ] All issues resolved: [ ] Yes [ ] No

## References

- [GitHub OAuth Setup Guide](../how-to/security/github-oauth-setup.md)
- [Backstage Deployment Guide](../deployment/backstage-postgresql.md)
- [Backstage Authentication Documentation](https://backstage.io/docs/auth/github/provider)

---

**Last Updated**: December 2024
