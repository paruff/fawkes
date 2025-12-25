# Event Tracking Infrastructure

Comprehensive event tracking system for the Fawkes Internal Delivery Platform, built on Plausible Analytics.

## Overview

This module provides:
- **Event Schema**: Standardized taxonomy for 60+ predefined events
- **Event Tracker**: Unified tracking library with Plausible integration
- **React Hooks**: Easy-to-use hooks for common tracking scenarios
- **Middleware**: Validation, filtering, enrichment, and privacy controls
- **Real-time Streaming**: Events sent to Plausible in real-time

## Quick Start

### Installation

The analytics module is part of the `@fawkes/design-system` package:

```bash
npm install @fawkes/design-system
```

### Initialization

Initialize the tracker in your application entry point:

```typescript
import { initializeTracker } from '@fawkes/design-system/analytics';

initializeTracker({
  baseUrl: 'https://plausible.fawkes.idp',
  domain: 'backstage.fawkes.idp',
  debug: process.env.NODE_ENV === 'development',
  trackLocalhost: true, // Enable for local development
});
```

### Basic Usage

```typescript
import { trackEvent, PredefinedEvents } from '@fawkes/design-system/analytics';

// Track a predefined event
trackEvent(PredefinedEvents.DEPLOY_APPLICATION);

// Track with custom properties
trackEvent({
  ...PredefinedEvents.CREATE_SERVICE,
  properties: {
    template: 'nodejs-service',
    language: 'typescript',
  },
});
```

### React Hooks

```typescript
import { useEventTracking, usePageViewTracking } from '@fawkes/design-system/analytics';

function MyComponent() {
  const { trackPredefined } = useEventTracking();

  // Track page views automatically
  usePageViewTracking();

  const handleDeploy = () => {
    trackPredefined(PredefinedEvents.DEPLOY_APPLICATION, {
      deploymentTarget: 'production',
    });
  };

  return <button onClick={handleDeploy}>Deploy</button>;
}
```

## Event Schema

### Event Categories

Events are grouped into logical categories:

- **Navigation** (`navigation`, `catalog`, `search`) - User navigation and discovery
- **Scaffolding** (`scaffolding`, `service_management`) - Service creation and management
- **Documentation** (`documentation`, `techdocs`) - Documentation access
- **CI/CD** (`cicd`, `deployment`, `pipeline`) - Build and deployment events
- **Feedback** (`feedback`, `collaboration`) - User feedback and collaboration
- **Features** (`feature_usage`, `plugin_interaction`) - Feature usage
- **Errors** (`error`, `validation`) - Error tracking
- **Performance** (`performance`, `metrics`) - Performance monitoring
- **Security** (`security`, `compliance`) - Security events
- **User** (`user`, `authentication`) - User management

### Event Actions

Standard actions across categories:

- **General**: `view`, `click`, `submit`, `cancel`
- **CRUD**: `create`, `read`, `update`, `delete`
- **Navigation**: `navigate`, `search`, `filter`, `sort`
- **CI/CD**: `build`, `deploy`, `sync`, `rollback`
- **Status**: `start`, `complete`, `fail`, `timeout`
- **Errors**: `error`, `warning`, `retry`

### Event Properties

Custom properties for context:

```typescript
interface EventProperties {
  // Context
  component?: string;
  page?: string;
  section?: string;

  // Identifiers
  entityId?: string;
  entityName?: string;
  entityKind?: string;

  // User context
  team?: string;
  role?: string;

  // Technical details
  language?: string;
  framework?: string;
  template?: string;

  // CI/CD context
  buildId?: string;
  pipelineId?: string;
  deploymentTarget?: string;

  // Performance metrics
  duration?: number;
  responseTime?: number;
  errorCode?: string;

  // Feature flags
  featureFlag?: string;
  experimentId?: string;
  variant?: string;
}
```

## Predefined Events (60+ Events)

### Navigation (5 events)
- `VIEW_HOMEPAGE` - View homepage
- `VIEW_CATALOG` - View service catalog
- `SEARCH_CATALOG` - Search catalog
- `VIEW_SERVICE` - View service detail
- `VIEW_COMPONENT` - View component detail

### Scaffolding (10 events)
- `START_SCAFFOLDING` - Start service creation
- `SELECT_TEMPLATE` - Select template
- `COMPLETE_SCAFFOLDING` - Service created
- `CANCEL_SCAFFOLDING` - Cancel service creation
- `VALIDATE_INPUT` - Validate form input
- `TEMPLATE_JAVA` - Java service template
- `TEMPLATE_NODEJS` - Node.js service template
- `TEMPLATE_PYTHON` - Python service template
- `TEMPLATE_GOLANG` - Go service template
- `TEMPLATE_REACT` - React app template

### Documentation (6 events)
- `VIEW_DOCS` - View documentation
- `SEARCH_DOCS` - Search documentation
- `VIEW_TECHDOCS` - View TechDocs
- `VIEW_API_DOCS` - View API documentation
- `VIEW_GETTING_STARTED` - View getting started guide
- `DOWNLOAD_DOCS` - Download documentation

### CI/CD (12 events)
- `VIEW_PIPELINE` - View pipeline
- `TRIGGER_BUILD` - Trigger build
- `BUILD_COMPLETE` - Build complete
- `BUILD_FAILED` - Build failed
- `DEPLOY_APPLICATION` - Deploy application
- `DEPLOYMENT_COMPLETE` - Deployment complete
- `DEPLOYMENT_FAILED` - Deployment failed
- `ARGOCD_SYNC` - ArgoCD sync
- `ARGOCD_ROLLBACK` - ArgoCD rollback
- `VIEW_BUILD_LOGS` - View build logs
- `VIEW_DEPLOYMENT_STATUS` - View deployment status
- `CANCEL_DEPLOYMENT` - Cancel deployment

### Feedback (8 events)
- `SUBMIT_FEEDBACK` - Submit feedback
- `REPORT_BUG` - Report bug
- `REQUEST_FEATURE` - Request feature
- `OPEN_FEEDBACK_WIDGET` - Open feedback widget
- `CLOSE_FEEDBACK_WIDGET` - Close feedback widget
- `FRICTION_LOG` - Log friction point
- `VIEW_FEEDBACK` - View feedback
- `RESPOND_TO_FEEDBACK` - Respond to feedback

### Feature Usage (6 events)
- `USE_KUBERNETES_PLUGIN` - Kubernetes plugin
- `USE_ARGOCD_PLUGIN` - ArgoCD plugin
- `USE_GRAFANA_PLUGIN` - Grafana plugin
- `USE_SONARQUBE_PLUGIN` - SonarQube plugin
- `EXPORT_DATA` - Export data
- `SHARE_RESOURCE` - Share resource

### Error Events (5 events)
- `PAGE_ERROR` - Page load error
- `API_ERROR` - API error
- `VALIDATION_ERROR` - Validation error
- `AUTHENTICATION_ERROR` - Authentication error
- `AUTHORIZATION_ERROR` - Authorization error

### Performance (4 events)
- `PAGE_LOAD` - Page load
- `API_RESPONSE` - API response
- `SLOW_OPERATION` - Slow operation
- `TIMEOUT` - Operation timeout

### User Events (4 events)
- `LOGIN` - User login
- `LOGOUT` - User logout
- `UPDATE_PROFILE` - Update profile
- `VIEW_PROFILE` - View profile

## React Hooks Reference

### useEventTracking()

Track events in components:

```typescript
const { track, trackPredefined, trackCustom } = useEventTracking();

// Track structured event
track({
  category: EventCategory.SCAFFOLDING,
  action: EventAction.CREATE,
  label: 'Java Service',
  properties: { template: 'java-spring-boot' },
});

// Track predefined event
trackPredefined(PredefinedEvents.DEPLOY_APPLICATION, {
  deploymentTarget: 'staging',
});

// Track custom event
trackCustom('custom.event', { foo: 'bar' });
```

### usePageViewTracking()

Automatically track page views:

```typescript
function MyPage() {
  // Track on mount and whenever dependencies change
  usePageViewTracking([location.pathname]);

  return <div>My Page</div>;
}
```

### useComponentTracking()

Track component lifecycle:

```typescript
function MyComponent() {
  // Tracks mount and unmount events
  useComponentTracking('MyComponent', {
    page: 'catalog',
    section: 'service-list',
  });

  return <div>Content</div>;
}
```

### useButtonClick()

Track button clicks:

```typescript
function DeployButton() {
  const onClick = useButtonClick('Deploy', {
    target: 'production',
  });

  return <button onClick={onClick}>Deploy</button>;
}
```

### useFormTracking()

Track form interactions:

```typescript
function MyForm() {
  const { trackFormStart, trackFormSubmit, trackFormError } = useFormTracking('service-creation');

  useEffect(() => {
    trackFormStart();
  }, []);

  const handleSubmit = async () => {
    try {
      // Form submission logic
      trackFormSubmit({ template: 'nodejs' });
    } catch (error) {
      trackFormError(error.message);
    }
  };

  return <form onSubmit={handleSubmit}>...</form>;
}
```

### useSearchTracking()

Track search queries:

```typescript
function SearchBox() {
  const { trackSearch } = useSearchTracking('catalog');

  const handleSearch = (query: string, results: any[]) => {
    trackSearch(query, results.length);
  };

  return <input onChange={e => handleSearch(e.target.value, [])} />;
}
```

### useErrorTracking()

Track errors:

```typescript
function MyComponent() {
  const { trackError, trackAPIError } = useErrorTracking();

  try {
    // Component logic
  } catch (error) {
    trackError(error, { component: 'MyComponent' });
  }

  // Track API errors
  const fetchData = async () => {
    try {
      const response = await fetch('/api/data');
      if (!response.ok) {
        trackAPIError('/api/data', response.status, response.statusText);
      }
    } catch (error) {
      trackError(error);
    }
  };
}
```

### usePerformanceTracking()

Track performance metrics:

```typescript
function PerformanceSensitiveComponent() {
  const { trackPerformance } = usePerformanceTracking('data-load');

  useEffect(() => {
    const start = performance.now();

    loadData().then(() => {
      const duration = performance.now() - start;
      trackPerformance(duration, { dataSize: '1MB' });
    });
  }, []);
}
```

## Middleware

### Built-in Middleware

```typescript
import {
  validationMiddleware,
  samplingMiddleware,
  enrichmentMiddleware,
  filterMiddleware,
  rateLimitMiddleware,
  deduplicationMiddleware,
  privacyMiddleware,
  loggingMiddleware,
  timestampMiddleware,
  userContextMiddleware,
  MiddlewareChain,
} from '@fawkes/design-system/analytics';
```

### Using Middleware

```typescript
const chain = new MiddlewareChain();

// Add middleware in order
chain.use(validationMiddleware);
chain.use(privacyMiddleware);
chain.use(timestampMiddleware);
chain.use(enrichmentMiddleware({ platform: 'fawkes' }));
chain.use(samplingMiddleware(0.1)); // Sample 10% of events
chain.use(rateLimitMiddleware(100, 60000)); // Max 100 events per minute
chain.use(deduplicationMiddleware(5000)); // Deduplicate within 5 seconds

// Process event through middleware
const processedEvent = chain.execute(event);
if (processedEvent) {
  tracker.track(processedEvent);
}
```

### Custom Middleware

```typescript
const customMiddleware: EventMiddleware = (event: Event) => {
  // Transform or filter event
  if (event.category === EventCategory.ERROR) {
    // Send to error tracking service
    sendToSentry(event);
  }
  return event;
};

chain.use(customMiddleware);
```

## Event Naming Conventions

Events follow a structured naming pattern:

```
{category}.{action}.{label}
```

Examples:
- `scaffolding.create.java_service`
- `deployment.deploy.production`
- `feedback.submit.bug_report`
- `navigation.view.homepage`

Guidelines:
- Use lowercase with underscores
- Be specific but concise
- Include context in properties, not in label
- Group related events by category

## Validation

Events are automatically validated before being sent:

```typescript
import { validateEvent } from '@fawkes/design-system/analytics';

const event = {
  category: EventCategory.DEPLOYMENT,
  action: EventAction.DEPLOY,
  properties: {
    target: 'production',
  },
};

if (validateEvent(event)) {
  trackEvent(event);
}
```

Validation checks:
- ✅ Category and action are required
- ✅ Properties are serializable
- ✅ No circular references
- ✅ Property values are primitive types

## Privacy & Compliance

The event tracking system is designed with privacy-first principles:

### Built-in Privacy Features

1. **Cookie-less tracking** - No cookies used
2. **No personal data** - No PII collected by default
3. **Privacy middleware** - Sanitizes sensitive data
4. **Localhost opt-out** - Disabled on localhost by default
5. **GDPR compliant** - No consent banners needed

### Sensitive Data Handling

The privacy middleware automatically removes sensitive fields:

```typescript
// These fields are automatically removed:
const sensitiveFields = [
  'email', 'password', 'token', 'apiKey',
  'secret', 'ssn'
];
```

### Custom Privacy Rules

```typescript
const customPrivacyMiddleware: EventMiddleware = (event: Event) => {
  if (event.properties?.customerId) {
    // Hash customer ID
    event.properties.customerId = hashValue(event.properties.customerId);
  }
  return event;
};
```

## Debugging

### Enable Debug Mode

```typescript
initializeTracker({
  baseUrl: 'https://plausible.fawkes.idp',
  domain: 'backstage.fawkes.idp',
  debug: true, // Enable debug logging
});
```

### Check Tracker Status

```typescript
import { getTracker } from '@fawkes/design-system/analytics';

const tracker = getTracker();
const status = tracker.getStatus();

console.log('Initialized:', status.initialized);
console.log('Queue size:', status.queueSize);
```

### Logging Middleware

```typescript
chain.use(loggingMiddleware('debug')); // Log all events to console
```

## Testing

### Mock Tracker for Tests

```typescript
jest.mock('@fawkes/design-system/analytics', () => ({
  initializeTracker: jest.fn(),
  trackEvent: jest.fn(),
  trackPredefinedEvent: jest.fn(),
  trackCustomEvent: jest.fn(),
}));
```

### Test Event Tracking

```typescript
import { trackEvent } from '@fawkes/design-system/analytics';

test('tracks deployment event', () => {
  const component = render(<DeployButton />);

  fireEvent.click(component.getByText('Deploy'));

  expect(trackEvent).toHaveBeenCalledWith(
    expect.objectContaining({
      category: EventCategory.DEPLOYMENT,
      action: EventAction.DEPLOY,
    })
  );
});
```

## Best Practices

### 1. Use Predefined Events

Prefer predefined events for consistency:

```typescript
// ✅ Good
trackPredefinedEvent(PredefinedEvents.DEPLOY_APPLICATION);

// ❌ Avoid
trackCustomEvent('deploy-app');
```

### 2. Add Context with Properties

Use properties for context, not event names:

```typescript
// ✅ Good
trackPredefinedEvent(PredefinedEvents.SELECT_TEMPLATE, {
  template: 'java-service',
  language: 'java',
});

// ❌ Avoid
trackCustomEvent('select-java-template');
```

### 3. Track User Intent, Not Technical Details

Focus on what the user is trying to accomplish:

```typescript
// ✅ Good
trackPredefinedEvent(PredefinedEvents.DEPLOY_APPLICATION, {
  deploymentTarget: 'production',
});

// ❌ Avoid
trackCustomEvent('kubernetes-apply-clicked');
```

### 4. Use Middleware for Cross-Cutting Concerns

Don't manually add common properties:

```typescript
// ✅ Good - use enrichment middleware
chain.use(enrichmentMiddleware({
  platform: 'fawkes',
  version: '1.0.0',
}));

// ❌ Avoid - manual enrichment
trackEvent({
  ...event,
  properties: {
    ...event.properties,
    platform: 'fawkes',
    version: '1.0.0',
  },
});
```

### 5. Handle Errors Gracefully

Always track errors with context:

```typescript
const { trackError } = useErrorTracking();

try {
  await deployApplication();
} catch (error) {
  trackError(error, {
    component: 'DeploymentService',
    action: 'deploy',
  });
  throw error;
}
```

## Performance Considerations

### Event Batching

Events are sent in real-time but can be batched for performance:

```typescript
// Rate limit to prevent excessive events
chain.use(rateLimitMiddleware(100, 60000)); // Max 100/min
```

### Deduplication

Prevent duplicate events:

```typescript
// Deduplicate within 5 seconds
chain.use(deduplicationMiddleware(5000));
```

### Sampling

For high-volume events, use sampling:

```typescript
// Track only 10% of page views
chain.use(filterMiddleware(event =>
  event.category !== EventCategory.NAVIGATION || Math.random() < 0.1
));
```

## Integration with Plausible

### Viewing Events

1. Navigate to `https://plausible.fawkes.idp`
2. Select your site (e.g., `backstage.fawkes.idp`)
3. View custom events in Goals section
4. Create dashboards and reports

### Setting Up Goals

1. Go to Site Settings → Goals
2. Add custom event goals
3. Track conversion rates
4. Create funnels

### API Access

```typescript
// Query Plausible API
const response = await fetch(
  'https://plausible.fawkes.idp/api/v1/stats/aggregate?' +
  'site_id=backstage.fawkes.idp&period=30d&metrics=visitors,pageviews'
);
```

## Troubleshooting

### Events Not Showing Up

1. Check tracker is initialized: `getTracker().getStatus()`
2. Verify Plausible script loaded: Check browser DevTools Network tab
3. Enable debug mode: `debug: true` in config
4. Check browser console for errors

### Performance Issues

1. Use sampling for high-volume events
2. Enable deduplication middleware
3. Implement rate limiting
4. Check for circular references in properties

### Privacy Concerns

1. Review event properties for PII
2. Enable privacy middleware
3. Configure custom sanitization rules
4. Test with compliance tools

## Resources

- [Plausible Documentation](https://plausible.io/docs)
- [Plausible API Reference](https://plausible.io/docs/stats-api)
- [Event Tracking Best Practices](https://plausible.io/docs/custom-event-goals)
- [Fawkes Platform Documentation](../../../docs/README.md)

## Support

For questions or issues:
- Open an issue on GitHub
- Contact the Platform Team on Mattermost (#fawkes-support)
- Review the [Troubleshooting Guide](../../../docs/troubleshooting.md)
