// ============================================================================
// FILE: platform/apps/unleash/examples/backstage-integration.ts
// PURPOSE: Example of integrating OpenFeature with Unleash in Backstage
// ============================================================================

import { OpenFeature } from '@openfeature/server-sdk';
import { UnleashProvider } from '@openfeature/unleash-provider';

/**
 * Initialize OpenFeature with Unleash provider
 * Call this during Backstage backend startup
 */
export async function initializeFeatureFlags() {
  await OpenFeature.setProviderAndWait(
    new UnleashProvider({
      url: process.env.UNLEASH_API_URL || 'https://unleash.fawkes.idp/api',
      appName: 'backstage',
      apiToken: process.env.UNLEASH_API_TOKEN,
      // Optional: custom headers
      customHeaders: {
        'X-Custom-Header': 'value',
      },
      // Optional: refresh interval (default: 15s)
      refreshInterval: 30,
    })
  );
}

/**
 * Example: Check if a feature is enabled
 */
export async function checkNewUIFeature(): Promise<boolean> {
  const client = OpenFeature.getClient();
  
  const isEnabled = await client.getBooleanValue(
    'new-ui-enabled',
    false, // default value
    {
      targetingKey: 'user-123', // user identifier
      team: 'platform',
      environment: 'production',
    }
  );
  
  return isEnabled;
}

/**
 * Example: Get feature variant for A/B testing
 */
export async function getSearchExperimentVariant(): Promise<string> {
  const client = OpenFeature.getClient();
  
  const variant = await client.getStringValue(
    'search-algorithm',
    'default', // default variant
    {
      targetingKey: 'user-456',
      team: 'search',
    }
  );
  
  // variant could be: 'default', 'elastic', 'algolia', etc.
  return variant;
}
