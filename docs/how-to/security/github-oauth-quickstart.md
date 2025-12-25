# GitHub OAuth Quick Start for Backstage

> **Quick reference for setting up GitHub OAuth. For detailed instructions, see [github-oauth-setup.md](github-oauth-setup.md)**

## 🚀 5-Minute Setup

### 1. Create GitHub OAuth App

**Personal Account:**

- Go to: https://github.com/settings/developers
- Click "OAuth Apps" → "New OAuth App"

**Organization:**

- Go to: https://github.com/organizations/YOUR_ORG/settings/applications
- Click "New OAuth App"

### 2. Configure OAuth App

```
Application name:        Fawkes Backstage - [Environment]
Homepage URL:            https://backstage.fawkes.idp
Authorization callback:  https://backstage.fawkes.idp/api/auth/github/handler/frame
```

⚠️ **Important**: The callback URL must end with `/api/auth/github/handler/frame`

### 3. Get Credentials

- Copy the **Client ID**
- Click "Generate a new client secret"
- Copy the **Client Secret** (shown only once!)

### 4. Update Kubernetes Secret

```bash
# Edit the secrets file
vim platform/apps/backstage/secrets.yaml

# Replace these values:
github-client-id: "YOUR_CLIENT_ID"
github-client-secret: "YOUR_CLIENT_SECRET"

# Apply the secret
kubectl apply -f platform/apps/backstage/secrets.yaml

# Restart Backstage
kubectl rollout restart deployment/backstage -n fawkes
```

### 5. Test Login

```bash
# Port-forward (for local)
kubectl port-forward -n fawkes svc/backstage 7007:7007

# Open browser
open http://localhost:7007

# Click "Sign in with GitHub"
```

## 🔍 Verify Setup

```bash
# Check secret exists
kubectl get secret backstage-oauth-credentials -n fawkes

# Check pods are running
kubectl get pods -n fawkes -l app.kubernetes.io/name=backstage

# Check health
kubectl exec -n fawkes deployment/backstage -- curl -s http://localhost:7007/healthcheck
```

## 🐛 Common Issues

| Issue                  | Solution                                      |
| ---------------------- | --------------------------------------------- |
| "Invalid redirect_uri" | Verify callback URL in GitHub matches exactly |
| "Configuration error"  | Check secret values don't contain "CHANGE_ME" |
| No login button        | Verify app-config.yaml has auth section       |
| 500 on callback        | Check client secret is correct                |

## 📚 More Information

- **Full Setup Guide**: [github-oauth-setup.md](github-oauth-setup.md)
- **Validation Checklist**: [../../validation/backstage-oauth-validation.md](../../validation/backstage-oauth-validation.md)
- **Troubleshooting**: [../../troubleshooting.md](../../troubleshooting.md)
- **Backstage Docs**: https://backstage.io/docs/auth/github/provider

## 🔐 Production Best Practices

1. **Use separate OAuth apps per environment**

   - Development: `Fawkes Backstage - Dev`
   - Production: `Fawkes Backstage - Prod`

2. **Use Vault for secrets** (not Git)

   ```bash
   vault kv put secret/backstage/oauth \
     github-client-id="..." \
     github-client-secret="..."
   ```

3. **Rotate secrets every 90 days**

4. **Use organization OAuth apps** (not personal)

5. **Review authorized users regularly**

---

**Need help?** Check the [full setup guide](github-oauth-setup.md) or open an issue.
