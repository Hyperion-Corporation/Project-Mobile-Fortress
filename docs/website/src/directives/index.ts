import type { App, Plugin } from 'vue';
import { vClickOutside } from './clickOutside';
import { vFocus } from './focus';
import { vIntersect } from './intersect';

/** Registers all custom Vue directives used by the docs website. */
export const directivesPlugin: Plugin = {
  install(app: App) {
    app.directive('click-outside', vClickOutside);
    app.directive('focus', vFocus);
    app.directive('intersect', vIntersect);
  },
};

export { vClickOutside, vFocus, vIntersect };
