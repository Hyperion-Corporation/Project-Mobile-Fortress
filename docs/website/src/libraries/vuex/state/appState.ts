/**
 * Root application state for the documentation website shell
 * (theme, hub selection, active doc route metadata).
 */
export interface AppState {
  theme: 'light' | 'dark';
  activeHubTab: string | null;
  lastDocPath: string | null;
  searchOpen: boolean;
}

export const initialAppState: AppState = {
  theme: 'dark',
  activeHubTab: null,
  lastDocPath: null,
  searchOpen: false,
};
