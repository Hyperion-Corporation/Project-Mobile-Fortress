import { describe, expect, it } from 'vitest';
import { readStoredTheme } from '../../../src/libraries/vuex/services/persistence';

describe('utils', () => {
  it('defaults theme to dark when storage is empty', () => {
    expect(readStoredTheme()).toBe('dark');
  });
});
