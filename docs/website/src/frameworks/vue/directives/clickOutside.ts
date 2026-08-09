import type { Directive, DirectiveBinding } from 'vue';

type ClickOutsideEl = HTMLElement & {
  __clickOutsideHandler__?: (event: MouseEvent) => void;
};

/**
 * Calls the bound handler when a pointer event occurs outside the element.
 * Usage: `v-click-outside="onClose"`
 */
export const vClickOutside: Directive<ClickOutsideEl, (event: MouseEvent) => void> = {
  mounted(el, binding: DirectiveBinding<(event: MouseEvent) => void>) {
    el.__clickOutsideHandler__ = (event: MouseEvent) => {
      const target = event.target as Node | null;
      if (!target || el.contains(target)) return;
      binding.value?.(event);
    };
    // Capture phase so nested stopPropagation still observes outside clicks.
    document.addEventListener('click', el.__clickOutsideHandler__, true);
  },
  unmounted(el) {
    if (el.__clickOutsideHandler__) {
      document.removeEventListener('click', el.__clickOutsideHandler__, true);
      delete el.__clickOutsideHandler__;
    }
  },
};
