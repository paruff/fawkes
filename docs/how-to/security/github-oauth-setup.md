# Configure GitHub OAuth for Backstage

## Overview

This guide walks through configuring GitHub OAuth authentication for Backstage, enabling users to login with their GitHub accounts.

## Prerequisites

- GitHub account with admin access to your organization (or personal account)
- Backstage deployed and accessible via URL
- `kubectl` access to the Kubernetes cluster

## Architecture

```
┌──────────────┐
│   User's     │
│   Browser    │
└──────┬───────┘
       │ 1. Click "Sign in with GitHub"
       ▼
┌──────────────────────────────────────┐
│    Backstage Frontend                │
│    https://backstage.fawkes.idp      │
└──────┬───────────────────────────────┘
       │ 2. Redirect to GitHub OAuth
       ▼
┌──────────────────────────────────────┐
│    GitHub OAuth Provider             │
│    https://github.com/login/oauth    │
└──────┬───────────────────────────────┘
       │ 3. User authorizes
       │ 4. Redirect with auth code
       ▼
┌──────────────────────────────────────┐
│    Backstage Backend                 │
│    /api/auth/github/handler/frame    │
└──────┬───────────────────────────────┘
       │ 5. Exchange code for token
       │ 6. Create session
       ▼
┌──────────────────────────────────────┐
│    Authenticated User Session        │
└──────────────────────────────────────┘
```

## Step 1: Create GitHub OAuth Application

### Option A: Organization OAuth App (Recommended for Teams)

1. Navigate to your GitHub organization settings:
   ```
   https://github.com/organizations/YOUR_ORG/settings/applications
   ```

2. Click **"New OAuth App"** under OAuth Apps

3. Fill in the application details:
   - **Application name**: `Fawkes Backstage - [Environment]`
     - Example: `Fawkes Backstage - Development` or `Fawkes Backstage - Production`
   - **Homepage URL**: Your Backstage URL
     - Development: `http://backstage.127.0.0.1.nip.io` or `http://localhost:7007`
     - Production: `https://backstage.fawkes.idp`
   - **Application description**: `Fawkes Internal Developer Platform - Backstage Portal`
   - **Authorization callback URL**: Your Backstage URL + `/api/auth/github/handler/frame`
     - Development: `http://backstage.127.0.0.1.nip.io/api/auth/github/handler/frame`
     - Production: `https://backstage.fawkes.idp/api/auth/github/handler/frame`

4. Click **"Register application"**

5. After registration:
   - Copy the **Client ID** (you'll need this)
   - Click **"Generate a new client secret"**
   - Copy the **Client Secret** immediately (it won't be shown again)

### Option B: Personal OAuth App (For Testing/Development)

1. Navigate to your personal settings:
   ```
   https://github.com/settings/developers
   ```

2. Click **"OAuth Apps"** in the sidebar

3. Click **"New OAuth App"**

4. Fill in the same details as Option A above

5. Copy the Client ID and generate a Client Secret

## Step 2: Configure Backstage Secrets

Update the Kubernetes secret with your GitHub OAuth credentials:

### Method 1: Update secrets.yaml and Apply

```bash
# Edit the secrets file
cd /path/to/fawkes  # Navigate to your Fawkes repository root
vim platform/apps/backstage/secrets.yaml
```

Update the OAuth credentials section:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: backstage-oauth-credentials
  namespace: fawkes
type: Opaque
stringData:
  github-client-id: "YOUR_CLIENT_ID_HERE"
  github-client-secret: "YOUR_CLIENT_SECRET_HERE"
```

Apply the updated secret:

```bash
kubectl apply -f platform/apps/backstage/secrets.yaml
```

### Method 2: Direct kubectl Secret Creation (More Secure)

This method doesn't store secrets in Git:

```bash
# Create the secret directly
kubectl create secret generic backstage-oauth-credentials \
  --from-literal=github-client-id='YOUR_CLIENT_ID_HERE' \
  --from-literal=github-client-secret='YOUR_CLIENT_SECRET_HERE' \
  --namespace=fawkes \
  --dry-run=client -o yaml | kubectl apply -f -
```

### Method 3: Using External Secrets Operator with Vault (Production)

For production environments, use External Secrets Operator with Vault:

1. Store secrets in Vault:

```bash
vault kv put secret/backstage/oauth \
  github-client-id="YOUR_CLIENT_ID_HERE" \
  github-client-secret="YOUR_CLIENT_SECRET_HERE"
```

2. Create ExternalSecret resource:

```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: backstage-oauth-credentials
  namespace: fawkes
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: vault-backend
    kind: SecretStore
  target:
    name: backstage-oauth-credentials
    creationPolicy: Owner
  data:
    - secretKey: github-client-id
      remoteRef:
        key: secret/backstage/oauth
        property: github-client-id
    - secretKey: github-client-secret
      remoteRef:
        key: secret/backstage/oauth
        property: github-client-secret
```

## Step 3: Restart Backstage

Restart Backstage pods to pick up the new secrets:

```bash
# Restart the deployment
kubectl rollout restart deployment/backstage -n fawkes

# Watch the rollout status
kubectl rollout status deployment/backstage -n fawkes

# Verify pods are running
kubectl get pods -n fawkes -l app.kubernetes.io/name=backstage
```

## Step 4: Verify OAuth Configuration

### Test Authentication Flow

1. Access Backstage UI:
   - Local: http://backstage.127.0.0.1.nip.io or http://localhost:7007
   - Production: https://backstage.fawkes.idp

2. You should see a "Sign in with GitHub" button

3. Click the button:
   - You'll be redirected to GitHub
   - GitHub will ask for authorization
   - After authorizing, you'll be redirected back to Backstage
   - You should be logged in with your GitHub identity displayed

### Check Backend Logs

```bash
# View Backstage logs for auth events
kubectl logs -n fawkes -l app.kubernetes.io/name=backstage --tail=50 | grep -i auth

# Look for successful auth messages like:
# "GitHub authentication successful for user: username"
```

### Verify Environment Variables

```bash
# Check that secrets are mounted correctly
kubectl exec -n fawkes deployment/backstage -- printenv | grep AUTH_GITHUB

# Should show:
# AUTH_GITHUB_CLIENT_ID=<your-client-id>
# (Client secret won't be displayed for security)
```

## Step 5: Configure User Resolver (Optional)

By default, Backstage uses `usernameMatchingUserEntityName` resolver. You can configure additional resolvers in `app-config.yaml`:

```yaml
auth:
  environment: production
  providers:
    github:
      production:
        clientId: ${AUTH_GITHUB_CLIENT_ID}
        clientSecret: ${AUTH_GITHUB_CLIENT_SECRET}
        signIn:
          resolvers:
            # Match GitHub username to catalog User entity
            - resolver: usernameMatchingUserEntityName
            
            # Or use email matching
            # - resolver: emailMatchingUserEntityProfileEmail
            
            # Or use multiple resolvers (first match wins)
            # - resolver: emailLocalPartMatchingUserEntityName
```

## Troubleshooting

### Error: "Invalid redirect_uri"

**Cause**: The callback URL in GitHub OAuth app doesn't match the one Backstage is using.

**Solution**:
1. Check the URL in your GitHub OAuth app settings
2. Ensure it matches exactly: `https://backstage.fawkes.idp/api/auth/github/handler/frame`
3. Check for trailing slashes or http vs https mismatch

### Error: "Failed to authenticate with GitHub"

**Cause**: Client ID or Client Secret is incorrect.

**Solution**:
1. Verify the secret values in Kubernetes:
   ```bash
   kubectl get secret backstage-oauth-credentials -n fawkes -o jsonpath='{.data.github-client-id}' | base64 -d
   ```
2. Compare with your GitHub OAuth app
3. Regenerate client secret if necessary and update Kubernetes secret

### Error: "User not found in catalog"

**Cause**: Backstage can't find a User entity matching your GitHub username.

**Solution**:

Option 1: Create a User entity in the catalog:

```yaml
# Create file: catalog/users/your-username.yaml
apiVersion: backstage.io/v1alpha1
kind: User
metadata:
  name: your-github-username
spec:
  profile:
    displayName: Your Full Name
    email: your-email@example.com
  memberOf:
    - platform-team
```

Option 2: Use a different resolver that doesn't require User entities:

```yaml
# In app-config.yaml
auth:
  providers:
    github:
      production:
        signIn:
          resolvers:
            - resolver: emailMatchingUserEntityProfileEmail
```

### OAuth Works Locally But Not in Production

**Common Issues**:

1. **HTTP vs HTTPS**: Ensure GitHub OAuth app uses HTTPS for production URL
2. **DNS Resolution**: Verify `backstage.fawkes.idp` resolves correctly
3. **Firewall**: Ensure GitHub can reach your callback URL (for self-hosted)
4. **Certificate Issues**: Check TLS certificate is valid for your domain

## Security Best Practices

### 1. Separate OAuth Apps per Environment

Create separate OAuth apps for each environment:
- `Fawkes Backstage - Development` (http://localhost:7007)
- `Fawkes Backstage - Staging` (https://backstage-staging.fawkes.idp)
- `Fawkes Backstage - Production` (https://backstage.fawkes.idp)

### 2. Restrict Organization Access

For organization OAuth apps, configure organization access:
1. Go to OAuth app settings
2. Under "Organization access", configure which organizations can use the app
3. For internal platforms, restrict to your organization only

### 3. Review Authorized Users

Periodically review which users have authorized the application:
1. Users can revoke access at: https://github.com/settings/applications
2. Admins can view all authorized users in the OAuth app settings

### 4. Use Vault for Production Secrets

Never commit OAuth client secrets to Git. Use one of:
- External Secrets Operator with Vault (recommended)
- Sealed Secrets
- Cloud provider secret managers (AWS Secrets Manager, Azure Key Vault, GCP Secret Manager)

### 5. Rotate Secrets Regularly

Establish a rotation schedule:
1. Generate new client secret in GitHub
2. Update Kubernetes secret
3. Restart Backstage
4. Delete old client secret after verifying new one works
5. Recommended: Rotate every 90 days

## Testing OAuth Configuration

### Manual Test

```bash
# 1. Port-forward Backstage
kubectl port-forward -n fawkes svc/backstage 7007:7007

# 2. Open browser
open http://localhost:7007

# 3. Click "Sign in with GitHub"

# 4. Verify redirect to GitHub

# 5. Authorize the app

# 6. Verify redirect back to Backstage

# 7. Confirm you're logged in (your username should appear)
```

### Automated BDD Test

Run the acceptance test for OAuth:

```bash
# Run the authentication scenario
behave tests/bdd/features/backstage-deployment.feature \
  --tags=@authentication --tags=@success
```

## Related Documentation

- [Backstage Authentication Documentation](https://backstage.io/docs/auth/)
- [GitHub OAuth Apps Documentation](https://docs.github.com/en/developers/apps/building-oauth-apps)
- [ADR-002: Backstage for Developer Portal](../../adr/ADR-002%20backstage.md)
- [Backstage Deployment Guide](../../deployment/backstage-postgresql.md)

## Support

If you encounter issues not covered in this guide:

1. Check Backstage logs: `kubectl logs -n fawkes -l app.kubernetes.io/name=backstage`
2. Review Backstage auth documentation: https://backstage.io/docs/auth/github/provider
3. Open an issue in the Fawkes repository: https://github.com/paruff/fawkes/issues
4. Ask in Backstage Discord: https://discord.gg/backstage

---

**Last Updated**: December 2024  
**Tested With**: Backstage 1.20+, Kubernetes 1.28+
