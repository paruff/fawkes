# Penpot Access Controls Configuration

This document describes the access control and authentication setup for Penpot in the Fawkes platform.

## Overview

Penpot supports multiple authentication methods and provides role-based access control for teams and projects.

## Authentication Methods

### 1. Local Authentication (Enabled)

Users can register and log in with email and password.

**Configuration** (in `deployment.yaml`):

```yaml
env:
  - name: PENPOT_FLAGS
    value: "enable-registration enable-login-with-password"
```

**User Registration**:

- Navigate to https://penpot.fawkes.local
- Click "Sign Up"
- Enter email and password
- Email verification is disabled for development (can be enabled for production)

### 2. OAuth Integration (Future)

Planned integration with Backstage OAuth for single sign-on.

**Benefits**:

- Single sign-on across Fawkes platform
- Consistent user identity
- Centralized access management

**Implementation Plan**:

```yaml
# Future configuration
penpot:
  auth:
    providers:
      - name: backstage
        type: oauth2
        clientId: ${BACKSTAGE_CLIENT_ID}
        clientSecret: ${BACKSTAGE_CLIENT_SECRET}
        authorizationUrl: https://backstage.fawkes.local/oauth/authorize
        tokenUrl: https://backstage.fawkes.local/oauth/token
```

### 3. LDAP/SAML (Available)

Penpot supports LDAP and SAML for enterprise authentication.

**Configuration Example**:

```yaml
env:
  - name: PENPOT_LDAP_HOST
    value: "ldap.example.com"
  - name: PENPOT_LDAP_PORT
    value: "389"
  - name: PENPOT_LDAP_BIND_DN
    value: "cn=admin,dc=example,dc=com"
  - name: PENPOT_LDAP_BASE_DN
    value: "ou=users,dc=example,dc=com"
```

## Role-Based Access Control

### User Roles

Penpot supports the following roles at the team level:

1. **Owner**

   - Full control over team and all projects
   - Can add/remove members
   - Can manage team settings
   - Can delete team

2. **Admin**

   - Can manage projects and members
   - Can create/delete projects
   - Can invite new members
   - Cannot delete team

3. **Editor**

   - Can create and edit designs
   - Can comment on designs
   - Can share designs
   - Cannot manage team settings

4. **Viewer**
   - Read-only access to designs
   - Can view and comment
   - Cannot edit or create designs
   - Ideal for developers and stakeholders

### Project Permissions

Permissions can be set at the project level:

- **Private**: Only team members can access
- **Team**: All team members can view
- **Public Link**: Anyone with link can view (read-only)
- **Public**: Listed in public projects (not recommended for internal use)

### Recommended Team Structure

```
Fawkes Platform Team
├── Owners
│   ├── Platform Lead
│   └── Design Lead
├── Admins
│   ├── Senior Designers
│   └── Engineering Leads
├── Editors
│   ├── Designers
│   └── UX Researchers
└── Viewers
    ├── Developers
    ├── Product Managers
    └── QA Engineers
```

## Access Control Configuration

### Initial Setup

1. **Create Admin User**:

   ```bash
   # Access Penpot backend pod
   kubectl exec -it -n fawkes penpot-backend-xxx -- bash

   # Create admin user (if not using first-user auto-admin)
   # This is typically done through the UI on first login
   ```

2. **Create Platform Team**:

   - Log in as admin
   - Click "Teams" → "Create Team"
   - Name: "Fawkes Platform"
   - Invite team members

3. **Set Default Permissions**:
   - Navigate to Team Settings
   - Set default role for new members (recommend: Viewer)
   - Configure project visibility defaults

### Managing Users

#### Add User to Team

1. Navigate to Team Settings
2. Click "Members" tab
3. Click "Invite Member"
4. Enter email address
5. Select role (Owner, Admin, Editor, Viewer)
6. Send invitation

#### Remove User from Team

1. Navigate to Team Settings → Members
2. Find user in list
3. Click "..." menu
4. Select "Remove from team"

#### Change User Role

1. Navigate to Team Settings → Members
2. Find user in list
3. Click role dropdown
4. Select new role

### Project Access Control

#### Set Project Visibility

1. Open project
2. Click project menu (...)
3. Select "Project Settings"
4. Set visibility:
   - **Private**: Team members only
   - **Public Link**: Anyone with link (for stakeholder reviews)

#### Share with External Reviewers

1. Open project
2. Click "Share" button
3. Generate public link
4. Set expiration (optional)
5. Share link via Mattermost or email

**Security Best Practices**:

- Use expiring links for external reviews
- Revoke links after review completion
- Don't share internal/sensitive designs publicly

## Integration with Backstage

### Viewer Access for Developers

Developers accessing designs through Backstage should have **Viewer** role:

1. **Automatic Access** (Future):

   - Backstage catalog references Penpot designs
   - Developers automatically get viewer access via OAuth

2. **Manual Access** (Current):
   - Add developers to team with Viewer role
   - Developers log in to Penpot to view designs
   - Or share public links for specific designs

### API Access

For automation and component sync:

1. **Create Service Account**:

   ```bash
   # API tokens are per-user in Penpot
   # Create a dedicated "service" user for automation
   ```

2. **Generate API Token**:

   - Log in as service user
   - Navigate to Profile → API Tokens
   - Create new token with read-only access

3. **Store Token Securely**:

   ```bash
   # Create Kubernetes secret
   kubectl create secret generic penpot-api-token \
     -n fawkes \
     --from-literal=token='YOUR_TOKEN_HERE'
   ```

4. **Use in Sync Jobs**:
   ```yaml
   env:
     - name: PENPOT_API_TOKEN
       valueFrom:
         secretKeyRef:
           name: penpot-api-token
           key: token
   ```

## Security Best Practices

### Password Policy

Configure strong password requirements:

```yaml
env:
  - name: PENPOT_FLAGS
    value: "enable-registration enable-login-with-password"
  # Password requirements enforced by Penpot defaults:
  # - Minimum 8 characters
  # - Mix of letters and numbers recommended
```

### Session Management

```yaml
env:
  - name: PENPOT_REDIS_URI
    value: "redis://penpot-redis.fawkes.svc:6379/0"
  # Sessions stored in Redis for scalability
  # Sessions expire after 7 days of inactivity (Penpot default)
```

### Rate Limiting

Penpot includes built-in rate limiting:

- API requests: 100 requests/minute per user
- Login attempts: 5 failed attempts trigger 15-minute lockout
- Export requests: 10 exports/minute per user

### Audit Logging

Enable audit logging for compliance:

```yaml
env:
  - name: PENPOT_FLAGS
    value: "enable-audit-log"
  # Audit logs include:
  # - User login/logout events
  # - Project access
  # - File modifications
  # - Permission changes
```

Access audit logs:

```bash
kubectl logs -n fawkes penpot-backend-xxx | grep "audit"
```

## Monitoring and Alerts

### User Activity Monitoring

Track user activity via Prometheus metrics:

```yaml
# ServiceMonitor for Penpot
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: penpot
  namespace: fawkes
spec:
  selector:
    matchLabels:
      app: penpot
  endpoints:
    - port: http
      path: /metrics
```

### Access Control Alerts

Configure alerts for suspicious activity:

```yaml
# PrometheusRule for Penpot security
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: penpot-security
  namespace: fawkes
spec:
  groups:
    - name: penpot-security
      rules:
        - alert: MultipleFailedLogins
          expr: rate(penpot_failed_login_attempts[5m]) > 5
          annotations:
            summary: "Multiple failed login attempts detected"
        - alert: UnusualAPIActivity
          expr: rate(penpot_api_requests[1m]) > 100
          annotations:
            summary: "Unusual API activity detected"
```

## Compliance

### Data Privacy

Penpot stores the following user data:

- Email addresses
- Hashed passwords (bcrypt)
- Design files and assets
- Activity logs

**GDPR Compliance**:

- Users can request data export
- Users can request account deletion
- All data is stored within cluster (no external cloud)

### Data Retention

Configure retention policies:

```yaml
# In deployment.yaml
env:
  - name: PENPOT_DATA_RETENTION_DAYS
    value: "365" # Keep inactive projects for 1 year
```

## Troubleshooting

### User Cannot Log In

1. **Check user exists**:

   ```bash
   kubectl exec -n fawkes penpot-backend-xxx -- \
     psql -U penpot -d penpot -c "SELECT email FROM profile;"
   ```

2. **Reset password**:

   - User clicks "Forgot Password" on login page
   - Or admin resets via database (not recommended)

3. **Check account status**:
   ```bash
   kubectl exec -n fawkes penpot-backend-xxx -- \
     psql -U penpot -d penpot -c \
     "SELECT email, is_active FROM profile WHERE email='user@example.com';"
   ```

### User Cannot Access Project

1. **Verify team membership**:

   - Check if user is member of team that owns project

2. **Check project permissions**:

   - Verify project is not set to "Private" if user is external

3. **Check user role**:
   - Verify user has appropriate role (Viewer, Editor, Admin)

### API Token Not Working

1. **Verify token is valid**:

   ```bash
   curl -H "Authorization: Token YOUR_TOKEN" \
     https://penpot.fawkes.local/api/rpc/command/get-profile
   ```

2. **Check token expiration**:

   - Tokens don't expire by default in Penpot
   - But can be revoked by user

3. **Regenerate token**:
   - Log in as service user
   - Navigate to Profile → API Tokens
   - Revoke old token and create new one

## References

- [Penpot Self-Hosting Guide](https://help.penpot.app/technical-guide/getting-started/)
- [Penpot Authentication Documentation](https://help.penpot.app/technical-guide/configuration/#authentication)
- [Kubernetes Secrets Management](https://kubernetes.io/docs/concepts/configuration/secret/)
- [Backstage Authentication](https://backstage.io/docs/auth/)

## Support

- **Issues**: [GitHub Issues](https://github.com/paruff/fawkes/issues)
- **Slack**: #design-tools, #security
- **Security Incidents**: security@fawkes.io
