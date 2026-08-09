import { createStore, type Store } from 'vuex';
import { initialAppState, type AppState } from '../state/appState';
import { appMutations } from '../mutations/appMutations';
import { appActions } from '../actions/appActions';
import { readStoredTheme } from '../services/persistence';

export type RootState = AppState;

const state = (): AppState => ({
  ...initialAppState,
  theme: readStoredTheme(),
});

export const store: Store<RootState> = createStore<RootState>({
  state,
  mutations: appMutations,
  actions: appActions,
});

export function createAppStore(): Store<RootState> {
  return createStore<RootState>({
    state,
    mutations: appMutations,
    actions: appActions,
  });
}
