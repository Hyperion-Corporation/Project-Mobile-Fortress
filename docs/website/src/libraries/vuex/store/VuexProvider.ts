import type { App } from 'vue';
import { store } from './index';

/**
 * Install the shared Vuex store on a Vue app instance
 * (equivalent role to ReduxProvider on React hosts).
 */
export function installVuex(app: App): void {
  app.use(store);
}

export { store };
