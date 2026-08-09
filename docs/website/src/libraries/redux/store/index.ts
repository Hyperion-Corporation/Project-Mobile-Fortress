import { legacy_createStore as createStore } from 'redux';
import { rootReducer } from '../reducers/rootReducer';
import { initialAppState } from '../state/appState';
import { readStoredTheme } from '../services/persistence';

const preloadedState = {
  app: { ...initialAppState, theme: readStoredTheme() },
};

export const store = createStore(rootReducer, preloadedState);
export type AppDispatch = typeof store.dispatch;
export type RootState = ReturnType<typeof store.getState>;
