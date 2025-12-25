/**
 * React hooks for event tracking
 */

import { useCallback, useEffect, useRef } from 'react';
import { Event, EventProperties, PredefinedEvents } from './eventSchema';
import { getTracker } from './eventTracker';

/**
 * Hook to track events
 */
export function useEventTracking() {
  const tracker = useRef(getTracker());

  const track = useCallback((event: Event) => {
    tracker.current.track(event);
  }, []);

  const trackPredefined = useCallback(
    (eventTemplate: Partial<Event>, properties?: EventProperties) => {
      tracker.current.trackPredefined(eventTemplate, properties);
    },
    []
  );

  const trackCustom = useCallback((eventName: string, properties?: EventProperties) => {
    tracker.current.trackCustom(eventName, properties);
  }, []);

  return { track, trackPredefined, trackCustom };
}

/**
 * Hook to track page views
 */
export function usePageViewTracking(dependencies: any[] = []) {
  const tracker = useRef(getTracker());

  useEffect(() => {
    tracker.current.trackPageView();
  }, dependencies); // eslint-disable-line react-hooks/exhaustive-deps
}

/**
 * Hook to track component mount/unmount
 */
export function useComponentTracking(
  componentName: string,
  properties?: EventProperties
) {
  const tracker = useRef(getTracker());

  useEffect(() => {
    // Track component mount
    tracker.current.trackCustom('component.mount', {
      component: componentName,
      ...properties,
    });

    // Track component unmount
    return () => {
      tracker.current.trackCustom('component.unmount', {
        component: componentName,
        ...properties,
      });
    };
  }, []); // eslint-disable-line react-hooks/exhaustive-deps
}

/**
 * Hook to track button clicks
 */
export function useButtonClick(
  buttonLabel: string,
  properties?: EventProperties
) {
  const tracker = useRef(getTracker());

  return useCallback(() => {
    tracker.current.trackCustom('button.click', {
      button: buttonLabel,
      ...properties,
    });
  }, [buttonLabel, properties]);
}

/**
 * Hook to track form submissions
 */
export function useFormTracking(formName: string) {
  const tracker = useRef(getTracker());

  const trackFormStart = useCallback(() => {
    tracker.current.trackCustom('form.start', {
      form: formName,
    });
  }, [formName]);

  const trackFormSubmit = useCallback((properties?: EventProperties) => {
    tracker.current.trackCustom('form.submit', {
      form: formName,
      ...properties,
    });
  }, [formName]);

  const trackFormError = useCallback((errorMessage: string, properties?: EventProperties) => {
    tracker.current.trackCustom('form.error', {
      form: formName,
      error: errorMessage,
      ...properties,
    });
  }, [formName]);

  return { trackFormStart, trackFormSubmit, trackFormError };
}

/**
 * Hook to track search queries
 */
export function useSearchTracking(searchContext: string) {
  const tracker = useRef(getTracker());

  const trackSearch = useCallback(
    (query: string, resultsCount?: number) => {
      tracker.current.trackPredefined(PredefinedEvents.SEARCH_CATALOG, {
        context: searchContext,
        query,
        results: resultsCount,
      });
    },
    [searchContext]
  );

  return { trackSearch };
}

/**
 * Hook to track navigation
 */
export function useNavigationTracking() {
  const tracker = useRef(getTracker());

  const trackNavigation = useCallback(
    (destination: string, properties?: EventProperties) => {
      tracker.current.trackPredefined(PredefinedEvents.VIEW_HOMEPAGE, {
        destination,
        ...properties,
      });
    },
    []
  );

  return { trackNavigation };
}

/**
 * Hook to track errors
 */
export function useErrorTracking() {
  const tracker = useRef(getTracker());

  const trackError = useCallback(
    (error: Error, context?: EventProperties) => {
      tracker.current.trackPredefined(PredefinedEvents.PAGE_ERROR, {
        errorMessage: error.message,
        errorStack: error.stack?.substring(0, 500), // Limit stack trace length
        ...context,
      });
    },
    []
  );

  const trackAPIError = useCallback(
    (endpoint: string, statusCode: number, errorMessage: string) => {
      tracker.current.trackPredefined(PredefinedEvents.API_ERROR, {
        endpoint,
        statusCode: statusCode.toString(),
        errorMessage,
      });
    },
    []
  );

  return { trackError, trackAPIError };
}

/**
 * Hook to track performance metrics
 */
export function usePerformanceTracking(metricName: string) {
  const tracker = useRef(getTracker());

  const trackPerformance = useCallback(
    (duration: number, properties?: EventProperties) => {
      tracker.current.trackPredefined(PredefinedEvents.PAGE_LOAD, {
        metric: metricName,
        duration,
        ...properties,
      });
    },
    [metricName]
  );

  return { trackPerformance };
}
