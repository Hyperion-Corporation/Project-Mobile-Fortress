import { initialAppState, type AppState } from '../state/appState';
import type { AppAction } from '../actions/appActions';
import {
  SET_ACTIVE_HUB_TAB,
  SET_LAST_DOC_PATH,
  SET_SEARCH_OPEN,
  SET_THEME,
} from '../actions/actionTypes';

export function appReducer(state: AppState = initialAppState, action: AppAction): AppState {
  switch (action.type) {
    case SET_THEME:
      return { ...state, theme: action.payload };
    case SET_ACTIVE_HUB_TAB:
      return { ...state, activeHubTab: action.payload };
    case SET_LAST_DOC_PATH:
      return { ...state, lastDocPath: action.payload };
    case SET_SEARCH_OPEN:
      return { ...state, searchOpen: action.payload };
    default:
      return state;
  }
}
