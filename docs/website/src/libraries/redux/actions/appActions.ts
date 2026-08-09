import {
  SET_ACTIVE_HUB_TAB,
  SET_LAST_DOC_PATH,
  SET_SEARCH_OPEN,
  SET_THEME,
} from './actionTypes';
import { persistTheme } from '../services/persistence';

export const setTheme = (theme: 'light' | 'dark') => {
  // Legacy `redux` has no middleware wired up here (no thunk) — this action
  // creator's side effect mirrors the reference github-pages redux library's
  // approach of keeping persistence next to the action rather than the
  // (pure) reducer.
  persistTheme(theme);
  return { type: SET_THEME, payload: theme } as const;
};
export const setActiveHubTab = (tabId: string | null) =>
  ({ type: SET_ACTIVE_HUB_TAB, payload: tabId } as const);
export const setLastDocPath = (path: string | null) =>
  ({ type: SET_LAST_DOC_PATH, payload: path } as const);
export const setSearchOpen = (open: boolean) =>
  ({ type: SET_SEARCH_OPEN, payload: open } as const);

export type AppAction = ReturnType<
  typeof setTheme | typeof setActiveHubTab | typeof setLastDocPath | typeof setSearchOpen
>;
