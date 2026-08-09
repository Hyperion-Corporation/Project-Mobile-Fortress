import type { Directive } from 'vue';

/**
 * Focuses the host element when mounted (or when the binding is truthy).
 * Usage: `v-focus` or `v-focus="shouldFocus"`
 */
export const vFocus: Directive<HTMLElement, boolean | undefined> = {
  mounted(el, binding) {
    if (binding.value === false) return;
    queueMicrotask(() => el.focus());
  },
  updated(el, binding) {
    if (binding.value && !binding.oldValue) {
      queueMicrotask(() => el.focus());
    }
  },
};
