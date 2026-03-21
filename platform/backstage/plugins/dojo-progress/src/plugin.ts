import {
  createPlugin,
  createRoutableExtension,
  createApiFactory,
  discoveryApiRef,
  fetchApiRef,
} from '@backstage/core-plugin-api';
import { rootRouteRef } from './routes';
import { dojoProgressApiRef, DojoProgressClient } from './api';

/**
 * The Fawkes Dojo Progress plugin.
 *
 * Reads belt progress from the `fawkes-dojo-progress` Kubernetes ConfigMap
 * keyed by GitHub username and renders a belt dashboard.
 */
export const dojoProgressPlugin = createPlugin({
  id: 'dojo-progress',
  apis: [
    createApiFactory({
      api: dojoProgressApiRef,
      deps: { discoveryApi: discoveryApiRef, fetchApi: fetchApiRef },
      factory: ({ discoveryApi, fetchApi }) =>
        new DojoProgressClient({ discoveryApi, fetchApi }),
    }),
  ],
  routes: {
    root: rootRouteRef,
  },
});

/**
 * The routable DojoProgressPage extension.
 * Register this in your Backstage app's router.
 *
 * @example
 * // packages/app/src/App.tsx
 * import { DojoProgressPage } from '@fawkes/backstage-plugin-dojo-progress';
 * <Route path="/dojo" element={<DojoProgressPage />} />
 */
export const DojoProgressPage = dojoProgressPlugin.provide(
  createRoutableExtension({
    name: 'DojoProgressPage',
    component: () =>
      import('./components/DojoProgressPage').then(m => m.DojoProgressPage),
    mountPoint: rootRouteRef,
  }),
);
