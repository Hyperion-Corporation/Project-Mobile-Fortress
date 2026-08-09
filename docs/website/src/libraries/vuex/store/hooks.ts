import { computed, type ComputedRef } from 'vue';
import { useStore } from 'vuex';
import type { RootState } from './index';

/**
 * Typed Vuex helpers mirroring the Redux `useAppSelector` / `useAppDispatch`
 * pattern used in this org's React sites.
 */
export function useAppStore() {
  return useStore<RootState>();
}

export function useAppDispatch() {
  const store = useStore<RootState>();
  return store.dispatch;
}

export function useAppSelector<T>(
  selector: (state: RootState) => T
): ComputedRef<T> {
  const store = useStore<RootState>();
  return computed(() => selector(store.state));
}
