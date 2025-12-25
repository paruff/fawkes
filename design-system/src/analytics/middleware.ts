/**
 * Event validation middleware
 */

import { Event, validateEvent } from './eventSchema';

/**
 * Middleware function type
 */
export type EventMiddleware = (event: Event) => Event | null;

/**
 * Chain of middleware functions
 */
export class MiddlewareChain {
  private middlewares: EventMiddleware[] = [];

  /**
   * Add middleware to the chain
   */
  public use(middleware: EventMiddleware): void {
    this.middlewares.push(middleware);
  }

  /**
   * Execute middleware chain
   */
  public execute(event: Event): Event | null {
    let current: Event | null = event;

    for (const middleware of this.middlewares) {
      if (current === null) {
        break;
      }
      current = middleware(current);
    }

    return current;
  }

  /**
   * Clear all middleware
   */
  public clear(): void {
    this.middlewares = [];
  }
}

/**
 * Validation middleware - ensures events are valid
 */
export const validationMiddleware: EventMiddleware = (event: Event) => {
  if (!validateEvent(event)) {
    console.error('Event validation failed', event);
    return null;
  }
  return event;
};

/**
 * Sampling middleware - only track a percentage of events
 */
export function samplingMiddleware(sampleRate: number): EventMiddleware {
  return (event: Event) => {
    if (Math.random() > sampleRate) {
      return null;
    }
    return event;
  };
}

/**
 * Enrichment middleware - add default properties
 */
export function enrichmentMiddleware(defaultProperties: Record<string, any>): EventMiddleware {
  return (event: Event) => {
    return {
      ...event,
      properties: {
        ...defaultProperties,
        ...event.properties,
      },
    };
  };
}

/**
 * Filter middleware - filter events by category or action
 */
export function filterMiddleware(
  filter: (event: Event) => boolean
): EventMiddleware {
  return (event: Event) => {
    if (!filter(event)) {
      return null;
    }
    return event;
  };
}

/**
 * Rate limiting middleware - limit events by time window
 */
export function rateLimitMiddleware(
  maxEventsPerWindow: number,
  windowMs: number
): EventMiddleware {
  const eventCounts = new Map<string, { count: number; windowStart: number }>();

  return (event: Event) => {
    const now = Date.now();
    const key = `${event.category}.${event.action}`;

    const record = eventCounts.get(key);

    // Check if window has expired
    if (!record || now - record.windowStart > windowMs) {
      eventCounts.set(key, { count: 1, windowStart: now });
      return event;
    }

    // Check if limit exceeded
    if (record.count >= maxEventsPerWindow) {
      return null;
    }

    // Increment count
    record.count++;
    return event;
  };
}

/**
 * Deduplication middleware - prevent duplicate events within time window
 */
export function deduplicationMiddleware(windowMs: number): EventMiddleware {
  const recentEvents = new Map<string, number>();

  return (event: Event) => {
    const now = Date.now();
    const key = `${event.category}.${event.action}.${event.label}`;

    const lastSeen = recentEvents.get(key);

    // Check if duplicate within window
    if (lastSeen && now - lastSeen < windowMs) {
      return null;
    }

    // Store timestamp
    recentEvents.set(key, now);

    // Clean up old entries
    if (recentEvents.size > 1000) {
      const cutoff = now - windowMs;
      for (const [k, timestamp] of recentEvents.entries()) {
        if (timestamp < cutoff) {
          recentEvents.delete(k);
        }
      }
    }

    return event;
  };
}

/**
 * Privacy middleware - sanitize sensitive data
 */
export const privacyMiddleware: EventMiddleware = (event: Event) => {
  if (!event.properties) {
    return event;
  }

  const sanitized = { ...event.properties };

  // Remove sensitive fields
  const sensitiveFields = ['email', 'password', 'token', 'apiKey', 'secret', 'ssn'];

  for (const field of sensitiveFields) {
    if (field in sanitized) {
      delete sanitized[field];
    }
  }

  // Truncate long strings
  for (const [key, value] of Object.entries(sanitized)) {
    if (typeof value === 'string' && value.length > 500) {
      sanitized[key] = value.substring(0, 500) + '...';
    }
  }

  return {
    ...event,
    properties: sanitized,
  };
};

/**
 * Logging middleware - log events for debugging
 */
export function loggingMiddleware(logLevel: 'debug' | 'info' | 'warn' | 'error' = 'info'): EventMiddleware {
  return (event: Event) => {
    const message = `Event: ${event.category}.${event.action}`;
    
    switch (logLevel) {
      case 'debug':
        console.debug(message, event);
        break;
      case 'info':
        console.info(message, event);
        break;
      case 'warn':
        console.warn(message, event);
        break;
      case 'error':
        console.error(message, event);
        break;
    }

    return event;
  };
}

/**
 * Timestamp middleware - add timestamp to events
 */
export const timestampMiddleware: EventMiddleware = (event: Event) => {
  return {
    ...event,
    properties: {
      ...event.properties,
      timestamp: Date.now(),
    },
  };
};

/**
 * User context middleware - add user information
 */
export function userContextMiddleware(getUserContext: () => { userId?: string; team?: string; role?: string }): EventMiddleware {
  return (event: Event) => {
    const context = getUserContext();

    return {
      ...event,
      properties: {
        ...event.properties,
        ...context,
      },
    };
  };
}
