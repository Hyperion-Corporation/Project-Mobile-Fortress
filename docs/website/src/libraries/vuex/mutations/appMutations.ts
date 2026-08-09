import type { AppState } from '../state/appState';
import {
  SET_ACTIVE_HUB_TAB,
  SET_LAST_DOC_PATH,
  SET_SEARCH_OPEN,
  SET_THEME,
} from '../actions/actionTypes';

export const appMutations = {
  [SET_THEME](state: AppState, theme: 'light' | 'dark') {
    state.theme = theme;
  },
  [SET_ACTIVE_HUB_TAB](state: AppState, tabId: string | null) {
    state.activeHubTab = tabId;
  },
  [SET_LAST_DOC_PATH](state: AppState, path: string | null) {
    state.lastDocPath = path;
  },
  [SET_SEARCH_OPEN](state: AppState, open: boolean) {
    state.searchOpen = open;
  },
};
