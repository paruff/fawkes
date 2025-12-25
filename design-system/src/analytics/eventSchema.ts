/**
 * Event Tracking Schema for Fawkes Platform
 *
 * This file defines the comprehensive event taxonomy for tracking
 * user actions, feature usage, errors, and performance metrics
 * across the Fawkes Internal Delivery Platform.
 */

/**
 * Event categories group related events
 */
export enum EventCategory {
  // User Navigation & Discovery
  NAVIGATION = 'navigation',
  CATALOG = 'catalog',
  SEARCH = 'search',

  // Service Creation & Management
  SCAFFOLDING = 'scaffolding',
  SERVICE_MANAGEMENT = 'service_management',

  // Documentation
  DOCUMENTATION = 'documentation',
  TECHDOCS = 'techdocs',

  // CI/CD & Deployment
  CICD = 'cicd',
  DEPLOYMENT = 'deployment',
  PIPELINE = 'pipeline',

  // Collaboration & Feedback
  FEEDBACK = 'feedback',
  COLLABORATION = 'collaboration',

  // Platform Features
  FEATURE_USAGE = 'feature_usage',
  PLUGIN_INTERACTION = 'plugin_interaction',

  // Errors & Issues
  ERROR = 'error',
  VALIDATION = 'validation',

  // Performance
  PERFORMANCE = 'performance',
  METRICS = 'metrics',

  // Security & Compliance
  SECURITY = 'security',
  COMPLIANCE = 'compliance',

  // User Management
  USER = 'user',
  AUTHENTICATION = 'authentication',
}

/**
 * Standard event actions across categories
 */
export enum EventAction {
  // General actions
  VIEW = 'view',
  CLICK = 'click',
  SUBMIT = 'submit',
  CANCEL = 'cancel',

  // CRUD operations
  CREATE = 'create',
  READ = 'read',
  UPDATE = 'update',
  DELETE = 'delete',

  // Navigation
  NAVIGATE = 'navigate',
  SEARCH = 'search',
  FILTER = 'filter',
  SORT = 'sort',

  // CI/CD
  BUILD = 'build',
  DEPLOY = 'deploy',
  SYNC = 'sync',
  ROLLBACK = 'rollback',

  // Interaction
  EXPAND = 'expand',
  COLLAPSE = 'collapse',
  DOWNLOAD = 'download',
  UPLOAD = 'upload',

  // Status
  START = 'start',
  COMPLETE = 'complete',
  FAIL = 'fail',
  TIMEOUT = 'timeout',

  // Error handling
  ERROR = 'error',
  WARNING = 'warning',
  RETRY = 'retry',
}

/**
 * Custom properties that can be attached to events
 */
export interface EventProperties {
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

  // Custom fields
  [key: string]: string | number | boolean | undefined;
}

/**
 * Complete event structure
 */
export interface Event {
  category: EventCategory | string;
  action: EventAction | string;
  label?: string;
  properties?: EventProperties;
  value?: number;
}

/**
 * Predefined events for common platform actions
 */
export const PredefinedEvents = {
  // Navigation events (5 events)
  VIEW_HOMEPAGE: {
    category: EventCategory.NAVIGATION,
    action: EventAction.VIEW,
    label: 'Homepage',
  },
  VIEW_CATALOG: {
    category: EventCategory.CATALOG,
    action: EventAction.VIEW,
    label: 'Service Catalog',
  },
  SEARCH_CATALOG: {
    category: EventCategory.SEARCH,
    action: EventAction.SEARCH,
    label: 'Catalog Search',
  },
  VIEW_SERVICE: {
    category: EventCategory.CATALOG,
    action: EventAction.VIEW,
    label: 'Service Detail',
  },
  VIEW_COMPONENT: {
    category: EventCategory.CATALOG,
    action: EventAction.VIEW,
    label: 'Component Detail',
  },

  // Scaffolding events (10 events)
  START_SCAFFOLDING: {
    category: EventCategory.SCAFFOLDING,
    action: EventAction.START,
    label: 'Start Service Creation',
  },
  SELECT_TEMPLATE: {
    category: EventCategory.SCAFFOLDING,
    action: EventAction.CLICK,
    label: 'Select Template',
  },
  COMPLETE_SCAFFOLDING: {
    category: EventCategory.SCAFFOLDING,
    action: EventAction.COMPLETE,
    label: 'Service Created',
  },
  CANCEL_SCAFFOLDING: {
    category: EventCategory.SCAFFOLDING,
    action: EventAction.CANCEL,
    label: 'Cancel Service Creation',
  },
  VALIDATE_INPUT: {
    category: EventCategory.VALIDATION,
    action: EventAction.SUBMIT,
    label: 'Validate Form Input',
  },
  TEMPLATE_JAVA: {
    category: EventCategory.SCAFFOLDING,
    action: EventAction.CREATE,
    label: 'Java Service Template',
  },
  TEMPLATE_NODEJS: {
    category: EventCategory.SCAFFOLDING,
    action: EventAction.CREATE,
    label: 'Node.js Service Template',
  },
  TEMPLATE_PYTHON: {
    category: EventCategory.SCAFFOLDING,
    action: EventAction.CREATE,
    label: 'Python Service Template',
  },
  TEMPLATE_GOLANG: {
    category: EventCategory.SCAFFOLDING,
    action: EventAction.CREATE,
    label: 'Go Service Template',
  },
  TEMPLATE_REACT: {
    category: EventCategory.SCAFFOLDING,
    action: EventAction.CREATE,
    label: 'React App Template',
  },

  // Documentation events (6 events)
  VIEW_DOCS: {
    category: EventCategory.DOCUMENTATION,
    action: EventAction.VIEW,
    label: 'View Documentation',
  },
  SEARCH_DOCS: {
    category: EventCategory.SEARCH,
    action: EventAction.SEARCH,
    label: 'Search Documentation',
  },
  VIEW_TECHDOCS: {
    category: EventCategory.TECHDOCS,
    action: EventAction.VIEW,
    label: 'View TechDocs',
  },
  VIEW_API_DOCS: {
    category: EventCategory.DOCUMENTATION,
    action: EventAction.VIEW,
    label: 'View API Documentation',
  },
  VIEW_GETTING_STARTED: {
    category: EventCategory.DOCUMENTATION,
    action: EventAction.VIEW,
    label: 'View Getting Started Guide',
  },
  DOWNLOAD_DOCS: {
    category: EventCategory.DOCUMENTATION,
    action: EventAction.DOWNLOAD,
    label: 'Download Documentation',
  },

  // CI/CD events (12 events)
  VIEW_PIPELINE: {
    category: EventCategory.CICD,
    action: EventAction.VIEW,
    label: 'View Pipeline',
  },
  TRIGGER_BUILD: {
    category: EventCategory.CICD,
    action: EventAction.START,
    label: 'Trigger Build',
  },
  BUILD_COMPLETE: {
    category: EventCategory.CICD,
    action: EventAction.COMPLETE,
    label: 'Build Complete',
  },
  BUILD_FAILED: {
    category: EventCategory.CICD,
    action: EventAction.FAIL,
    label: 'Build Failed',
  },
  DEPLOY_APPLICATION: {
    category: EventCategory.DEPLOYMENT,
    action: EventAction.DEPLOY,
    label: 'Deploy Application',
  },
  DEPLOYMENT_COMPLETE: {
    category: EventCategory.DEPLOYMENT,
    action: EventAction.COMPLETE,
    label: 'Deployment Complete',
  },
  DEPLOYMENT_FAILED: {
    category: EventCategory.DEPLOYMENT,
    action: EventAction.FAIL,
    label: 'Deployment Failed',
  },
  ARGOCD_SYNC: {
    category: EventCategory.DEPLOYMENT,
    action: EventAction.SYNC,
    label: 'ArgoCD Sync',
  },
  ARGOCD_ROLLBACK: {
    category: EventCategory.DEPLOYMENT,
    action: EventAction.ROLLBACK,
    label: 'ArgoCD Rollback',
  },
  VIEW_BUILD_LOGS: {
    category: EventCategory.CICD,
    action: EventAction.VIEW,
    label: 'View Build Logs',
  },
  VIEW_DEPLOYMENT_STATUS: {
    category: EventCategory.DEPLOYMENT,
    action: EventAction.VIEW,
    label: 'View Deployment Status',
  },
  CANCEL_DEPLOYMENT: {
    category: EventCategory.DEPLOYMENT,
    action: EventAction.CANCEL,
    label: 'Cancel Deployment',
  },

  // Feedback events (8 events)
  SUBMIT_FEEDBACK: {
    category: EventCategory.FEEDBACK,
    action: EventAction.SUBMIT,
    label: 'Submit Feedback',
  },
  REPORT_BUG: {
    category: EventCategory.FEEDBACK,
    action: EventAction.SUBMIT,
    label: 'Report Bug',
  },
  REQUEST_FEATURE: {
    category: EventCategory.FEEDBACK,
    action: EventAction.SUBMIT,
    label: 'Request Feature',
  },
  OPEN_FEEDBACK_WIDGET: {
    category: EventCategory.FEEDBACK,
    action: EventAction.CLICK,
    label: 'Open Feedback Widget',
  },
  CLOSE_FEEDBACK_WIDGET: {
    category: EventCategory.FEEDBACK,
    action: EventAction.CANCEL,
    label: 'Close Feedback Widget',
  },
  FRICTION_LOG: {
    category: EventCategory.FEEDBACK,
    action: EventAction.SUBMIT,
    label: 'Log Friction Point',
  },
  VIEW_FEEDBACK: {
    category: EventCategory.FEEDBACK,
    action: EventAction.VIEW,
    label: 'View Feedback',
  },
  RESPOND_TO_FEEDBACK: {
    category: EventCategory.FEEDBACK,
    action: EventAction.SUBMIT,
    label: 'Respond to Feedback',
  },

  // Feature usage events (6 events)
  USE_KUBERNETES_PLUGIN: {
    category: EventCategory.PLUGIN_INTERACTION,
    action: EventAction.CLICK,
    label: 'Kubernetes Plugin',
  },
  USE_ARGOCD_PLUGIN: {
    category: EventCategory.PLUGIN_INTERACTION,
    action: EventAction.CLICK,
    label: 'ArgoCD Plugin',
  },
  USE_GRAFANA_PLUGIN: {
    category: EventCategory.PLUGIN_INTERACTION,
    action: EventAction.CLICK,
    label: 'Grafana Plugin',
  },
  USE_SONARQUBE_PLUGIN: {
    category: EventCategory.PLUGIN_INTERACTION,
    action: EventAction.CLICK,
    label: 'SonarQube Plugin',
  },
  EXPORT_DATA: {
    category: EventCategory.FEATURE_USAGE,
    action: EventAction.DOWNLOAD,
    label: 'Export Data',
  },
  SHARE_RESOURCE: {
    category: EventCategory.FEATURE_USAGE,
    action: EventAction.CLICK,
    label: 'Share Resource',
  },

  // Error events (5 events)
  PAGE_ERROR: {
    category: EventCategory.ERROR,
    action: EventAction.ERROR,
    label: 'Page Load Error',
  },
  API_ERROR: {
    category: EventCategory.ERROR,
    action: EventAction.ERROR,
    label: 'API Error',
  },
  VALIDATION_ERROR: {
    category: EventCategory.VALIDATION,
    action: EventAction.ERROR,
    label: 'Validation Error',
  },
  AUTHENTICATION_ERROR: {
    category: EventCategory.AUTHENTICATION,
    action: EventAction.ERROR,
    label: 'Authentication Error',
  },
  AUTHORIZATION_ERROR: {
    category: EventCategory.SECURITY,
    action: EventAction.ERROR,
    label: 'Authorization Error',
  },

  // Performance events (4 events)
  PAGE_LOAD: {
    category: EventCategory.PERFORMANCE,
    action: EventAction.COMPLETE,
    label: 'Page Load',
  },
  API_RESPONSE: {
    category: EventCategory.PERFORMANCE,
    action: EventAction.COMPLETE,
    label: 'API Response',
  },
  SLOW_OPERATION: {
    category: EventCategory.PERFORMANCE,
    action: EventAction.WARNING,
    label: 'Slow Operation',
  },
  TIMEOUT: {
    category: EventCategory.PERFORMANCE,
    action: EventAction.TIMEOUT,
    label: 'Operation Timeout',
  },

  // User events (4 events)
  LOGIN: {
    category: EventCategory.AUTHENTICATION,
    action: EventAction.COMPLETE,
    label: 'User Login',
  },
  LOGOUT: {
    category: EventCategory.AUTHENTICATION,
    action: EventAction.COMPLETE,
    label: 'User Logout',
  },
  UPDATE_PROFILE: {
    category: EventCategory.USER,
    action: EventAction.UPDATE,
    label: 'Update Profile',
  },
  VIEW_PROFILE: {
    category: EventCategory.USER,
    action: EventAction.VIEW,
    label: 'View Profile',
  },
};

/**
 * Event naming conventions
 *
 * Format: {category}.{action}.{label}
 * Example: scaffolding.create.java_service
 *
 * Guidelines:
 * - Use lowercase with underscores
 * - Be specific but concise
 * - Include context in properties, not in label
 * - Group related events by category
 */
export function formatEventName(event: Event): string {
  const parts = [event.category, event.action];
  if (event.label) {
    parts.push(event.label.toLowerCase().replace(/\s+/g, '_'));
  }
  return parts.join('.');
}

/**
 * Validate event structure
 */
export function validateEvent(event: Event): boolean {
  if (!event.category || !event.action) {
    console.error('Event must have category and action');
    return false;
  }

  if (event.properties) {
    // Ensure properties are serializable
    try {
      JSON.stringify(event.properties);
    } catch (error) {
      console.error('Event properties must be serializable', error);
      return false;
    }
  }

  return true;
}
