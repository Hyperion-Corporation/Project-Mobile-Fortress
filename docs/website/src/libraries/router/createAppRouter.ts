import { createBrowserRouter, type RouteObject, type DataRouter } from 'react-router-dom';

/**
 * Shared React Router factory for the docs website and future multi-framework
 * islands that need a standalone SPA history router (separate from game clients).
 *
 * The primary site router lives at `src/router.tsx` and should keep using this
 * helper when routes are extended so basename/history options stay consistent.
 */
export function createAppRouter(options: { routes: RouteObject[]; basename?: string }): DataRouter {
  return createBrowserRouter(options.routes, {
    basename: options.basename ?? import.meta.env.BASE_URL,
  });
}

export { createBrowserRouter } from 'react-router-dom';
export type { RouteObject } from 'react-router-dom';
