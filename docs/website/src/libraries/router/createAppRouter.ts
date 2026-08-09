import {
  createRouter,
  createWebHistory,
  type RouteRecordRaw,
  type Router,
} from 'vue-router';

/**
 * Shared Vue Router factory for the docs website and future multi-framework
 * islands that need a standalone SPA history router (separate from game clients).
 *
 * The primary site router lives at `src/router.ts` and should keep using this
 * helper when routes are extended so history/base options stay consistent.
 */
export function createAppRouter(options: {
  routes: RouteRecordRaw[];
  base?: string;
}): Router {
  return createRouter({
    history: createWebHistory(options.base ?? import.meta.env.BASE_URL),
    routes: options.routes,
    scrollBehavior(to, _from, savedPosition) {
      if (savedPosition) return savedPosition;
      if (to.hash) return { el: to.hash, behavior: 'smooth', top: 80 };
      return { top: 0 };
    },
  });
}

export { createRouter, createWebHistory } from 'vue-router';
export type { RouteRecordRaw, Router } from 'vue-router';
