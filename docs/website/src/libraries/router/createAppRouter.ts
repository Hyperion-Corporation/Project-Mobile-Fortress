import { createBrowserRouter, type RouteObject, type DataRouter } from 'react-router-dom';

/**
 * Shared React Router factory for the docs website and future multi-framework
 * islands that need a standalone SPA history router (separate from game clients).
 *
 * The primary site router lives at `src/router.tsx` and should keep using this
 * helper when routes are extended so basename/history options stay consistent.
 */
// `import.meta.env` is a Vite-ism — this factory is also reused by the
// stack/next/ surface (webpack/SWC), where it's undefined, so read it
// defensively rather than assuming Vite's define-time replacement ran.
function viteBaseUrl(): string | undefined {
  try {
    return import.meta.env?.BASE_URL;
  } catch {
    return undefined;
  }
}

export function createAppRouter(options: { routes: RouteObject[]; basename?: string }): DataRouter {
  return createBrowserRouter(options.routes, {
    basename: options.basename ?? viteBaseUrl() ?? "/",
  });
}

export { createBrowserRouter } from 'react-router-dom';
export type { RouteObject } from 'react-router-dom';
