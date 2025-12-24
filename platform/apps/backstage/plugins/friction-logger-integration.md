# Backstage Friction Logger Integration

This integration adds friction logging capability to Backstage portal, allowing developers to report friction points directly from the UI.

## Overview

The friction logger integration provides:
- **Web Form**: Simple form to log friction points
- **Proxy Endpoint**: Routes friction logs to Insights API
- **Dashboard Widget**: View recent friction points (optional)

## Configuration

### 1. Add Proxy Endpoint

Add to `app-config.yaml`:

```yaml
proxy:
  endpoints:
    '/friction/api':
      target: http://insights-service.fawkes.svc.cluster.local:8000
      changeOrigin: true
      pathRewrite:
        '^/friction/api': ''
      headers:
        X-Source: 'Backstage'
```

### 2. Add Navigation Menu Item

Add to `packages/app/src/components/Root/Root.tsx`:

```typescript
import AssignmentLateIcon from '@material-ui/icons/AssignmentLate';

// In the sidebar:
<SidebarItem icon={AssignmentLateIcon} to="friction-logger" text="Report Friction" />
```

### 3. Create Friction Logger Page

Create `packages/app/src/components/FrictionLogger/FrictionLogger.tsx`:

```typescript
import React, { useState } from 'react';
import {
  Content,
  Header,
  Page,
  InfoCard,
} from '@backstage/core-components';
import {
  Button,
  TextField,
  MenuItem,
  Grid,
  Snackbar,
  Alert,
} from '@material-ui/core';
import { useApi, configApiRef } from '@backstage/core-plugin-api';

export const FrictionLoggerPage = () => {
  const config = useApi(configApiRef);
  const backendUrl = config.getString('backend.baseUrl');

  const [title, setTitle] = useState('');
  const [description, setDescription] = useState('');
  const [category, setCategory] = useState('Developer Experience');
  const [priority, setPriority] = useState('medium');
  const [tags, setTags] = useState('');
  const [snackbar, setSnackbar] = useState({ open: false, message: '', severity: 'success' as any });

  const categories = [
    'CI/CD',
    'Documentation',
    'Tooling',
    'Infrastructure',
    'Testing',
    'Developer Experience',
    'Security',
    'Performance',
  ];

  const priorities = [
    { value: 'low', label: 'Low' },
    { value: 'medium', label: 'Medium' },
    { value: 'high', label: 'High' },
    { value: 'critical', label: 'Critical' },
  ];

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    const frictionData = {
      title,
      description,
      content: `# ${title}\n\n${description}\n\n**Logged via Backstage**`,
      category_name: category,
      tags: tags.split(',').map(t => t.trim()).filter(t => t).concat(['friction', 'backstage']),
      priority,
      source: 'Backstage',
      author: 'backstage-user', // TODO: Get from auth context
      metadata: {
        platform: 'backstage',
        timestamp: new Date().toISOString(),
      },
    };

    try {
      const response = await fetch(`${backendUrl}/api/proxy/friction/api/insights`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(frictionData),
      });

      if (!response.ok) {
        throw new Error(`Failed to submit: ${response.statusText}`);
      }

      const result = await response.json();

      setSnackbar({
        open: true,
        message: `Friction point logged successfully! (ID: ${result.id})`,
        severity: 'success',
      });

      // Reset form
      setTitle('');
      setDescription('');
      setCategory('Developer Experience');
      setPriority('medium');
      setTags('');
    } catch (error) {
      setSnackbar({
        open: true,
        message: `Failed to submit friction: ${error.message}`,
        severity: 'error',
      });
    }
  };

  return (
    <Page themeId="tool">
      <Header title="Friction Logger" subtitle="Report friction points to help improve the platform" />
      <Content>
        <Grid container spacing={3}>
          <Grid item xs={12} md={8}>
            <InfoCard title="Log a Friction Point">
              <form onSubmit={handleSubmit}>
                <Grid container spacing={2}>
                  <Grid item xs={12}>
                    <TextField
                      label="Title"
                      fullWidth
                      required
                      value={title}
                      onChange={(e) => setTitle(e.target.value)}
                      placeholder="Brief description of the friction"
                      helperText="e.g., 'Slow CI builds' or 'Missing documentation'"
                    />
                  </Grid>
                  <Grid item xs={12}>
                    <TextField
                      label="Description"
                      fullWidth
                      required
                      multiline
                      rows={4}
                      value={description}
                      onChange={(e) => setDescription(e.target.value)}
                      placeholder="Detailed description of the friction point"
                      helperText="What happened? When? What was the impact?"
                    />
                  </Grid>
                  <Grid item xs={12} sm={6}>
                    <TextField
                      label="Category"
                      fullWidth
                      select
                      value={category}
                      onChange={(e) => setCategory(e.target.value)}
                    >
                      {categories.map((cat) => (
                        <MenuItem key={cat} value={cat}>
                          {cat}
                        </MenuItem>
                      ))}
                    </TextField>
                  </Grid>
                  <Grid item xs={12} sm={6}>
                    <TextField
                      label="Priority"
                      fullWidth
                      select
                      value={priority}
                      onChange={(e) => setPriority(e.target.value)}
                    >
                      {priorities.map((p) => (
                        <MenuItem key={p.value} value={p.value}>
                          {p.label}
                        </MenuItem>
                      ))}
                    </TextField>
                  </Grid>
                  <Grid item xs={12}>
                    <TextField
                      label="Tags (optional)"
                      fullWidth
                      value={tags}
                      onChange={(e) => setTags(e.target.value)}
                      placeholder="deployment, performance, docs"
                      helperText="Comma-separated tags for categorization"
                    />
                  </Grid>
                  <Grid item xs={12}>
                    <Button
                      type="submit"
                      variant="contained"
                      color="primary"
                      disabled={!title || !description}
                    >
                      Submit Friction Point
                    </Button>
                  </Grid>
                </Grid>
              </form>
            </InfoCard>
          </Grid>
          <Grid item xs={12} md={4}>
            <InfoCard title="How It Works">
              <p>Use this form to report any friction you encounter while using the platform:</p>
              <ul>
                <li><strong>CI/CD</strong>: Build, test, deployment issues</li>
                <li><strong>Documentation</strong>: Missing or unclear docs</li>
                <li><strong>Tooling</strong>: IDE, CLI, developer tools</li>
                <li><strong>Infrastructure</strong>: K8s, cloud, networking</li>
              </ul>
              <p>Your feedback helps us continuously improve the platform!</p>
            </InfoCard>
          </Grid>
        </Grid>

        <Snackbar
          open={snackbar.open}
          autoHideDuration={6000}
          onClose={() => setSnackbar({ ...snackbar, open: false })}
        >
          <Alert onClose={() => setSnackbar({ ...snackbar, open: false })} severity={snackbar.severity}>
            {snackbar.message}
          </Alert>
        </Snackbar>
      </Content>
    </Page>
  );
};
```

### 4. Register Route

Add to `packages/app/src/App.tsx`:

```typescript
import { FrictionLoggerPage } from './components/FrictionLogger';

// In the routes:
<Route path="/friction-logger" element={<FrictionLoggerPage />} />
```

### 5. Create Index Export

Create `packages/app/src/components/FrictionLogger/index.ts`:

```typescript
export { FrictionLoggerPage } from './FrictionLogger';
```

## Usage

1. Navigate to "Report Friction" in the Backstage sidebar
2. Fill in the form:
   - **Title**: Brief description (required)
   - **Description**: Detailed explanation (required)
   - **Category**: Select appropriate category
   - **Priority**: Select severity level
   - **Tags**: Add comma-separated tags (optional)
3. Click "Submit Friction Point"
4. Success message will appear with the friction ID

## API Integration

The form submits to:
```
POST /api/proxy/friction/api/insights
```

Which proxies to:
```
POST http://insights-service.fawkes.svc.cluster.local:8000/insights
```

## Authentication

The integration uses Backstage's auth context. To include the authenticated user:

```typescript
import { useApi, identityApiRef } from '@backstage/core-plugin-api';

const identity = useApi(identityApiRef);
const userEntity = await identity.getBackstageIdentity();

// Use in frictionData:
author: userEntity.userEntityRef,
```

## Dashboard Widget (Optional)

To show recent friction points on the homepage, create:

`packages/app/src/components/FrictionWidget/FrictionWidget.tsx`:

```typescript
import React, { useEffect, useState } from 'react';
import { InfoCard } from '@backstage/core-components';
import { useApi, configApiRef } from '@backstage/core-plugin-api';
import { List, ListItem, ListItemText, Chip } from '@material-ui/core';

export const FrictionWidget = () => {
  const config = useApi(configApiRef);
  const backendUrl = config.getString('backend.baseUrl');
  const [frictions, setFrictions] = useState([]);

  useEffect(() => {
    fetch(`${backendUrl}/api/proxy/friction/api/insights?limit=5`)
      .then(res => res.json())
      .then(data => setFrictions(data))
      .catch(err => console.error('Failed to fetch frictions:', err));
  }, [backendUrl]);

  return (
    <InfoCard title="Recent Friction Points">
      <List>
        {frictions.map((friction: any) => (
          <ListItem key={friction.id}>
            <ListItemText
              primary={friction.title}
              secondary={
                <>
                  <Chip
                    label={friction.priority}
                    size="small"
                    color={friction.priority === 'high' || friction.priority === 'critical' ? 'secondary' : 'default'}
                  />
                  {' '}
                  {friction.category?.name}
                </>
              }
            />
          </ListItem>
        ))}
      </List>
    </InfoCard>
  );
};
```

Add to homepage in `packages/app/src/components/home/HomePage.tsx`.

## Troubleshooting

### Proxy Not Working

Check `app-config.yaml`:
```bash
# Verify proxy endpoint is configured
cat app-config.yaml | grep -A 5 "friction/api"
```

### Cannot Connect to Insights API

```bash
# Test from within cluster
kubectl run -it --rm debug --image=curlimages/curl --restart=Never -- \
  curl http://insights-service.fawkes.svc.cluster.local:8000/health
```

### Form Submission Fails

1. Check browser console for errors
2. Verify backend proxy is working:
   ```bash
   curl http://backstage.fawkes.local/api/proxy/friction/api/health
   ```
3. Check Backstage backend logs:
   ```bash
   kubectl logs -n fawkes -l app=backstage -c backstage
   ```

## Benefits

- **Integrated Experience**: Log friction without leaving Backstage
- **User Context**: Automatically captures authenticated user
- **Rich UI**: Better than CLI for detailed friction reports
- **Discoverable**: Visible in Backstage navigation
- **Tracked**: All submissions go to Insights database

## Related

- [CLI Tool](../../../services/friction-cli/README.md)
- [Slack/Mattermost Bot](../../../services/friction-bot/README.md)
- [Insights API](../../../services/insights/README.md)
