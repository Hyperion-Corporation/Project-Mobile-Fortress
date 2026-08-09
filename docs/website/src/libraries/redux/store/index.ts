import { legacy_createStore as createStore, type Store } from 'redux';
import { rootReducer, type RootState as CombinedState } from '../reducers/rootReducer';
import { initialAppState } from '../state/appState';
import { readStoredTheme } from '../services/persistence';
import type { AppAction } from '../actions/appActions';

const preloadedState: CombinedState = {
  app: { ...initialAppState, theme: readStoredTheme() },
};

// combineReducers' PreloadedState inference only matches reducers typed
// against redux's own UnknownAction, not our narrower AppAction union — a
// known TS/redux generic-inference gap that makes createStore's preloaded
// state parameter type-check as `Partial<{ app: never }>`. The `as any` is
// harmless here since preloadedState already fully satisfies CombinedState.
export const store: Store<CombinedState, AppAction> = createStore(rootReducer, preloadedState as any);
export type AppDispatch = typeof store.dispatch;
export type RootState = CombinedState;
