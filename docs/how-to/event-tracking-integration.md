# Event Tracking Integration Guide for Backstage

This guide shows how to integrate the Fawkes event tracking library into Backstage components.

## Setup

### 1. Initialize the Tracker

Add initialization to your Backstage app's entry point (e.g., `packages/app/src/App.tsx` or `packages/app/src/index.tsx`):

```typescript
import { initializeTracker } from '@fawkes/design-system/analytics';

// Initialize tracker early in app lifecycle
initializeTracker({
  baseUrl: 'https://plausible.fawkes.idp',
  domain: 'backstage.fawkes.idp',
  debug: process.env.NODE_ENV === 'development',
  trackLocalhost: true, // Enable for development
});
```

### 2. Update app-config.yaml

Ensure Plausible is configured in Backstage:

```yaml
app:
  analytics:
    plausible:
      domain: backstage.fawkes.idp
      src: https://plausible.fawkes.idp/js/script.js

proxy:
  endpoints:
    '/plausible/api':
      target: http://plausible.fawkes.svc:8000/api/
      changeOrigin: true
      secure: false
```

## Usage Examples

### Track Page Views

```typescript
import { usePageViewTracking } from '@fawkes/design-system/analytics';

function HomePage() {
  // Automatically track page view on mount
  usePageViewTracking();

  return <div>Welcome to Fawkes Platform</div>;
}
```

### Track User Actions

```typescript
import { useEventTracking, PredefinedEvents } from '@fawkes/design-system/analytics';

function CatalogPage() {
  const { trackPredefined } = useEventTracking();

  const handleViewService = (service: string) => {
    trackPredefined(PredefinedEvents.VIEW_SERVICE, {
      entityName: service,
      entityKind: 'service',
    });
  };

  return (
    <ServiceList onServiceClick={handleViewService} />
  );
}
```

### Track Scaffolding Flow

```typescript
import { useEventTracking, PredefinedEvents } from '@fawkes/design-system/analytics';

function ScaffoldingWizard() {
  const { trackPredefined } = useEventTracking();

  useEffect(() => {
    // Track scaffolding start
    trackPredefined(PredefinedEvents.START_SCAFFOLDING);
  }, []);

  const handleTemplateSelection = (template: string) => {
    trackPredefined(PredefinedEvents.SELECT_TEMPLATE, {
      template,
      language: getLanguageFromTemplate(template),
    });
  };

  const handleComplete = (serviceName: string) => {
    trackPredefined(PredefinedEvents.COMPLETE_SCAFFOLDING, {
      entityName: serviceName,
      template: selectedTemplate,
    });
  };

  const handleCancel = () => {
    trackPredefined(PredefinedEvents.CANCEL_SCAFFOLDING);
  };

  return (
    <Wizard
      onTemplateSelect={handleTemplateSelection}
      onComplete={handleComplete}
      onCancel={handleCancel}
    />
  );
}
```

### Track Search Queries

```typescript
import { useSearchTracking } from '@fawkes/design-system/analytics';

function CatalogSearch() {
  const { trackSearch } = useSearchTracking('catalog');

  const handleSearch = (query: string, results: any[]) => {
    trackSearch(query, results.length);
  };

  return (
    <SearchBar
      onSearch={(query) => {
        const results = performSearch(query);
        handleSearch(query, results);
        return results;
      }}
    />
  );
}
```

### Track CI/CD Events

```typescript
import { useEventTracking, PredefinedEvents } from '@fawkes/design-system/analytics';

function PipelineCard({ pipelineId }: { pipelineId: string }) {
  const { trackPredefined } = useEventTracking();

  const handleTriggerBuild = async () => {
    const startTime = Date.now();

    trackPredefined(PredefinedEvents.TRIGGER_BUILD, {
      pipelineId,
      component: 'PipelineCard',
    });

    try {
      await triggerJenkinsBuild(pipelineId);

      trackPredefined(PredefinedEvents.BUILD_COMPLETE, {
        pipelineId,
        duration: Date.now() - startTime,
      });
    } catch (error) {
      trackPredefined(PredefinedEvents.BUILD_FAILED, {
        pipelineId,
        errorCode: error.code,
        errorMessage: error.message,
      });
    }
  };

  const handleViewLogs = () => {
    trackPredefined(PredefinedEvents.VIEW_BUILD_LOGS, {
      pipelineId,
    });
  };

  return (
    <Card>
      <Button onClick={handleTriggerBuild}>Trigger Build</Button>
      <Button onClick={handleViewLogs}>View Logs</Button>
    </Card>
  );
}
```

### Track Deployment Events

```typescript
import { useEventTracking, PredefinedEvents } from '@fawkes/design-system/analytics';

function DeployButton({ serviceName, environment }: DeployButtonProps) {
  const { trackPredefined } = useEventTracking();

  const handleDeploy = async () => {
    trackPredefined(PredefinedEvents.DEPLOY_APPLICATION, {
      entityName: serviceName,
      deploymentTarget: environment,
    });

    try {
      await deployToArgoCD(serviceName, environment);

      trackPredefined(PredefinedEvents.DEPLOYMENT_COMPLETE, {
        entityName: serviceName,
        deploymentTarget: environment,
      });
    } catch (error) {
      trackPredefined(PredefinedEvents.DEPLOYMENT_FAILED, {
        entityName: serviceName,
        deploymentTarget: environment,
        errorMessage: error.message,
      });
    }
  };

  return (
    <Button onClick={handleDeploy}>
      Deploy to {environment}
    </Button>
  );
}
```

### Track Form Interactions

```typescript
import { useFormTracking } from '@fawkes/design-system/analytics';

function ServiceCreationForm() {
  const { trackFormStart, trackFormSubmit, trackFormError } = useFormTracking('service-creation');

  useEffect(() => {
    trackFormStart();
  }, []);

  const handleSubmit = async (data: FormData) => {
    try {
      await createService(data);
      trackFormSubmit({
        template: data.template,
        language: data.language,
      });
    } catch (error) {
      trackFormError(error.message, {
        field: error.field,
      });
    }
  };

  return <Form onSubmit={handleSubmit}>...</Form>;
}
```

### Track Errors

```typescript
import { useErrorTracking } from '@fawkes/design-system/analytics';

function ServiceDetailPage({ serviceId }: { serviceId: string }) {
  const { trackError, trackAPIError } = useErrorTracking();

  const fetchServiceData = async () => {
    try {
      const response = await fetch(`/api/services/${serviceId}`);

      if (!response.ok) {
        trackAPIError(
          `/api/services/${serviceId}`,
          response.status,
          response.statusText
        );
        throw new Error('Failed to fetch service data');
      }

      return response.json();
    } catch (error) {
      trackError(error, {
        component: 'ServiceDetailPage',
        serviceId,
      });
      throw error;
    }
  };

  return <ErrorBoundary onError={trackError}>...</ErrorBoundary>;
}
```

### Track Performance

```typescript
import { usePerformanceTracking } from '@fawkes/design-system/analytics';

function HeavyComponent() {
  const { trackPerformance } = usePerformanceTracking('heavy-component-load');

  useEffect(() => {
    const startTime = performance.now();

    loadHeavyData().then(() => {
      const duration = performance.now() - startTime;
      trackPerformance(duration, {
        component: 'HeavyComponent',
      });
    });
  }, []);

  return <div>...</div>;
}
```

### Track Button Clicks

```typescript
import { useButtonClick } from '@fawkes/design-system/analytics';

function FeedbackWidget() {
  const trackOpenFeedback = useButtonClick('Open Feedback', {
    component: 'FeedbackWidget',
  });

  return (
    <IconButton onClick={trackOpenFeedback}>
      <FeedbackIcon />
    </IconButton>
  );
}
```

### Track Documentation Access

```typescript
import { useEventTracking, PredefinedEvents } from '@fawkes/design-system/analytics';

function TechDocsViewer({ docId }: { docId: string }) {
  const { trackPredefined } = useEventTracking();

  useEffect(() => {
    trackPredefined(PredefinedEvents.VIEW_TECHDOCS, {
      entityId: docId,
    });
  }, [docId]);

  const handleDownload = () => {
    trackPredefined(PredefinedEvents.DOWNLOAD_DOCS, {
      entityId: docId,
      format: 'pdf',
    });
  };

  return (
    <div>
      <DocContent docId={docId} />
      <Button onClick={handleDownload}>Download PDF</Button>
    </div>
  );
}
```

### Track Plugin Interactions

```typescript
import { useEventTracking, PredefinedEvents } from '@fawkes/design-system/analytics';

function KubernetesPlugin() {
  const { trackPredefined } = useEventTracking();

  useEffect(() => {
    trackPredefined(PredefinedEvents.USE_KUBERNETES_PLUGIN);
  }, []);

  return <KubernetesContent />;
}

function ArgoCDPlugin() {
  const { trackPredefined } = useEventTracking();

  useEffect(() => {
    trackPredefined(PredefinedEvents.USE_ARGOCD_PLUGIN);
  }, []);

  return <ArgoCDContent />;
}
```

### Track Component Lifecycle

```typescript
import { useComponentTracking } from '@fawkes/design-system/analytics';

function ServiceCard({ service }: { service: Service }) {
  useComponentTracking('ServiceCard', {
    entityName: service.name,
    entityKind: 'service',
  });

  return <Card>...</Card>;
}
```

### Track Navigation

```typescript
import { useNavigationTracking } from '@fawkes/design-system/analytics';
import { useNavigate } from 'react-router-dom';

function NavigationMenu() {
  const { trackNavigation } = useNavigationTracking();
  const navigate = useNavigate();

  const handleNavigate = (path: string) => {
    trackNavigation(path, {
      source: 'navigation-menu',
    });
    navigate(path);
  };

  return (
    <Menu>
      <MenuItem onClick={() => handleNavigate('/catalog')}>
        Catalog
      </MenuItem>
      <MenuItem onClick={() => handleNavigate('/docs')}>
        Documentation
      </MenuItem>
    </Menu>
  );
}
```

## Advanced Usage

### Custom Middleware

```typescript
import {
  initializeTracker,
  EventTracker,
  MiddlewareChain,
  validationMiddleware,
  privacyMiddleware,
  enrichmentMiddleware,
  userContextMiddleware,
} from '@fawkes/design-system/analytics';

// Create custom middleware
const customMiddleware = (event) => {
  // Add custom logic
  return {
    ...event,
    properties: {
      ...event.properties,
      appVersion: '1.0.0',
    },
  };
};

// Configure middleware chain
const chain = new MiddlewareChain();
chain.use(validationMiddleware);
chain.use(privacyMiddleware);
chain.use(enrichmentMiddleware({ platform: 'fawkes' }));
chain.use(userContextMiddleware(() => ({
  userId: getCurrentUser()?.id,
  team: getCurrentUser()?.team,
})));
chain.use(customMiddleware);

// Initialize tracker
const tracker = initializeTracker({
  baseUrl: 'https://plausible.fawkes.idp',
  domain: 'backstage.fawkes.idp',
});

// Track with middleware
const processedEvent = chain.execute(event);
if (processedEvent) {
  tracker.track(processedEvent);
}
```

### Custom Events

```typescript
import { trackEvent, EventCategory, EventAction } from '@fawkes/design-system/analytics';

// Track custom event
trackEvent({
  category: EventCategory.FEATURE_USAGE,
  action: EventAction.CLICK,
  label: 'Custom Feature',
  properties: {
    featureName: 'my-custom-feature',
    version: '2.0',
  },
  value: 1,
});
```

### Conditional Tracking

```typescript
import { getTracker } from '@fawkes/design-system/analytics';

function ConditionalTracking() {
  const tracker = getTracker();

  // Enable/disable tracking based on user preference
  const handleToggleTracking = (enabled: boolean) => {
    tracker.setEnabled(enabled);
  };

  // Check tracker status
  const status = tracker.getStatus();
  console.log('Tracker initialized:', status.initialized);
  console.log('Queued events:', status.queueSize);

  return (
    <Toggle
      checked={status.initialized}
      onChange={handleToggleTracking}
      label="Enable Analytics"
    />
  );
}
```

## Best Practices

1. **Track User Intent**: Focus on what the user is trying to accomplish, not technical implementation details
2. **Use Predefined Events**: Prefer predefined events for consistency
3. **Add Context**: Include relevant properties for better insights
4. **Handle Errors**: Always track errors with context
5. **Performance**: Track performance metrics for slow operations
6. **Privacy**: Never include PII in event properties
7. **Validation**: Events are automatically validated before sending

## Testing

```typescript
import { trackEvent } from '@fawkes/design-system/analytics';

// Mock in tests
jest.mock('@fawkes/design-system/analytics', () => ({
  trackEvent: jest.fn(),
  trackPredefinedEvent: jest.fn(),
  useEventTracking: () => ({
    track: jest.fn(),
    trackPredefined: jest.fn(),
  }),
}));

// Test tracking
test('tracks deployment event', () => {
  const { getByText } = render(<DeployButton />);
  fireEvent.click(getByText('Deploy'));

  expect(trackEvent).toHaveBeenCalledWith(
    expect.objectContaining({
      category: EventCategory.DEPLOYMENT,
      action: EventAction.DEPLOY,
    })
  );
});
```

## Viewing Analytics

1. Navigate to `https://plausible.fawkes.idp`
2. Login with admin credentials
3. Select `backstage.fawkes.idp` site
4. View custom events in Goals section
5. Create dashboards and reports

## Troubleshooting

### Events Not Appearing

1. Check tracker initialization: `getTracker().getStatus()`
2. Verify Plausible script loaded in browser DevTools
3. Enable debug mode: `debug: true` in config
4. Check browser console for errors

### Missing Events

1. Verify event validation passed
2. Check middleware isn't filtering events
3. Ensure Plausible service is running
4. Review event naming and properties

For more details, see the [Analytics README](../../design-system/src/analytics/README.md).
