/**
 * Event Tracking Library for Fawkes Platform
 * 
 * Provides a unified interface for tracking events across the platform
 * with Plausible Analytics integration and validation.
 */

import { Event, EventProperties, validateEvent, formatEventName } from './eventSchema';

/**
 * Configuration for the event tracker
 */
export interface TrackerConfig {
  /** Base URL for Plausible instance */
  baseUrl: string;
  /** Domain being tracked */
  domain: string;
  /** Enable debug logging */
  debug?: boolean;
  /** Custom API endpoint */
  apiEndpoint?: string;
  /** Hash mode for privacy (default: false) */
  hashMode?: boolean;
  /** Track local file URLs (default: false) */
  trackLocalhost?: boolean;
}

/**
 * Default configuration
 */
const DEFAULT_CONFIG: Partial<TrackerConfig> = {
  debug: false,
  apiEndpoint: '/api/event',
  hashMode: false,
  trackLocalhost: false,
};

/**
 * Event Tracker class
 */
export class EventTracker {
  private config: TrackerConfig;
  private queue: Event[] = [];
  private initialized = false;

  constructor(config: TrackerConfig) {
    this.config = { ...DEFAULT_CONFIG, ...config };
    this.initialize();
  }

  /**
   * Initialize the tracker
   */
  private initialize(): void {
    if (this.initialized) {
      return;
    }

    // Check if running on localhost and trackLocalhost is false
    if (!this.config.trackLocalhost && this.isLocalhost()) {
      this.log('Tracking disabled on localhost');
      return;
    }

    // Load Plausible script if not already loaded
    this.loadPlausibleScript();
    
    this.initialized = true;
    this.log('Event tracker initialized', this.config);
    
    // Process any queued events
    this.processQueue();
  }

  /**
   * Check if running on localhost
   */
  private isLocalhost(): boolean {
    if (typeof window === 'undefined') {
      return false;
    }
    return window.location.hostname === 'localhost' || 
           window.location.hostname === '127.0.0.1' ||
           window.location.hostname === '[::1]';
  }

  /**
   * Load Plausible tracking script
   */
  private loadPlausibleScript(): void {
    if (typeof window === 'undefined' || typeof document === 'undefined') {
      return;
    }

    // Check if Plausible script for this domain already exists
    const existingScript = document.querySelector(
      `script[data-domain="${this.config.domain}"]`
    );
    if (existingScript) {
      this.log('Plausible script already loaded');
      return;
    }

    const script = document.createElement('script');
    script.defer = true;
    script.setAttribute('data-domain', this.config.domain);
    script.src = `${this.config.baseUrl}/js/script.js`;
    
    document.head.appendChild(script);
    this.log('Plausible script loaded');
  }

  /**
   * Track an event
   */
  public track(event: Event): void {
    if (!validateEvent(event)) {
      console.error('Invalid event', event);
      return;
    }

    if (!this.initialized) {
      this.queue.push(event);
      this.log('Event queued (tracker not initialized)', event);
      return;
    }

    this.sendEvent(event);
  }

  /**
   * Track a predefined event
   */
  public trackPredefined(eventTemplate: Partial<Event>, properties?: EventProperties): void {
    const event: Event = {
      category: eventTemplate.category || 'unknown',
      action: eventTemplate.action || 'unknown',
      label: eventTemplate.label,
      properties: { ...eventTemplate.properties, ...properties },
      value: eventTemplate.value,
    };
    
    this.track(event);
  }

  /**
   * Track page view
   */
  public trackPageView(url?: string, properties?: EventProperties): void {
    if (typeof window !== 'undefined' && window.plausible) {
      const pageUrl = url || window.location.pathname;
      this.log('Tracking page view', pageUrl);
      
      // Use Plausible's built-in page view tracking
      window.plausible('pageview', { 
        props: properties as Record<string, string | number | boolean>
      });
    }
  }

  /**
   * Track custom event with name
   */
  public trackCustom(eventName: string, properties?: EventProperties): void {
    if (typeof window !== 'undefined' && window.plausible) {
      this.log('Tracking custom event', eventName, properties);
      
      window.plausible(eventName, { 
        props: properties as Record<string, string | number | boolean>
      });
    }
  }

  /**
   * Send event to Plausible
   */
  private sendEvent(event: Event): void {
    if (typeof window === 'undefined' || !window.plausible) {
      this.log('Plausible not available, event not sent', event);
      return;
    }

    // Format event name
    const eventName = formatEventName(event);
    
    // Prepare properties
    const props: Record<string, string | number | boolean> = {};
    
    if (event.label) {
      props.label = event.label;
    }
    
    if (event.value !== undefined) {
      props.value = event.value;
    }
    
    if (event.properties) {
      Object.entries(event.properties).forEach(([key, value]) => {
        if (value !== undefined && value !== null) {
          props[key] = value as string | number | boolean;
        }
      });
    }

    this.log('Sending event', eventName, props);
    
    try {
      window.plausible(eventName, { props });
    } catch (error) {
      console.error('Error sending event', error);
    }
  }

  /**
   * Process queued events
   */
  private processQueue(): void {
    if (this.queue.length === 0) {
      return;
    }

    this.log(`Processing ${this.queue.length} queued events`);
    
    const events = [...this.queue];
    this.queue = [];
    
    events.forEach(event => this.sendEvent(event));
  }

  /**
   * Debug logging
   */
  private log(message: string, ...args: any[]): void {
    if (this.config.debug) {
      console.log(`[EventTracker] ${message}`, ...args);
    }
  }

  /**
   * Enable/disable tracking
   */
  public setEnabled(enabled: boolean): void {
    this.initialized = enabled;
    
    if (enabled) {
      this.initialize();
    }
  }

  /**
   * Get tracker status
   */
  public getStatus(): { initialized: boolean; queueSize: number } {
    return {
      initialized: this.initialized,
      queueSize: this.queue.length,
    };
  }
}

/**
 * Singleton instance
 */
let trackerInstance: EventTracker | null = null;

/**
 * Initialize the global tracker
 */
export function initializeTracker(config: TrackerConfig): EventTracker {
  if (trackerInstance) {
    console.warn('Event tracker already initialized');
    return trackerInstance;
  }

  trackerInstance = new EventTracker(config);
  return trackerInstance;
}

/**
 * Get the global tracker instance
 */
export function getTracker(): EventTracker {
  if (!trackerInstance) {
    throw new Error('Event tracker not initialized. Call initializeTracker() first.');
  }
  return trackerInstance;
}

/**
 * Helper function to track an event
 */
export function trackEvent(event: Event): void {
  if (trackerInstance) {
    trackerInstance.track(event);
  } else {
    console.warn('Event tracker not initialized, event not tracked', event);
  }
}

/**
 * Helper function to track a predefined event
 */
export function trackPredefinedEvent(
  eventTemplate: Partial<Event>, 
  properties?: EventProperties
): void {
  if (trackerInstance) {
    trackerInstance.trackPredefined(eventTemplate, properties);
  } else {
    console.warn('Event tracker not initialized, event not tracked', eventTemplate);
  }
}

/**
 * Helper function to track custom event
 */
export function trackCustomEvent(eventName: string, properties?: EventProperties): void {
  if (trackerInstance) {
    trackerInstance.trackCustom(eventName, properties);
  } else {
    console.warn('Event tracker not initialized, event not tracked', eventName);
  }
}

/**
 * TypeScript declarations for window.plausible
 */
declare global {
  interface Window {
    plausible?: (
      eventName: string, 
      options?: { 
        props?: Record<string, string | number | boolean>;
        callback?: () => void;
      }
    ) => void;
  }
}
