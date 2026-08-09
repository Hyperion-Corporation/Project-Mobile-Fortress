import type { ActionContext } from 'vuex';
import type { AppState } from '../state/appState';
import {
  SET_ACTIVE_HUB_TAB,
  SET_LAST_DOC_PATH,
  SET_SEARCH_OPEN,
  SET_THEME,
} from './actionTypes';
import { persistTheme } from '../services/persistence';

type Ctx = ActionContext<AppState, AppState>;

export const appActions = {
  setTheme({ commit }: Ctx, theme: 'light' | 'dark') {
    commit(SET_THEME, theme);
    persistTheme(theme);
  },
  setActiveHubTab({ commit }: Ctx, tabId: string | null) {
    commit(SET_ACTIVE_HUB_TAB, tabId);
  },
  setLastDocPath({ commit }: Ctx, path: string | null) {
    commit(SET_LAST_DOC_PATH, path);
  },
  setSearchOpen({ commit }: Ctx, open: boolean) {
    commit(SET_SEARCH_OPEN, open);
  },
};
