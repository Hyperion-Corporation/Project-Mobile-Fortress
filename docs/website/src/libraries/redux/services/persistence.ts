const THEME_KEY = 'mf-docs-theme';

export function readStoredTheme(): 'light' | 'dark' {
  if (typeof window === 'undefined') return 'dark';
  return window.localStorage.getItem(THEME_KEY) === 'light' ? 'light' : 'dark';
}

export function persistTheme(theme: 'light' | 'dark'): void {
  if (typeof window !== 'undefined') {
    window.localStorage.setItem(THEME_KEY, theme);
  }
}
