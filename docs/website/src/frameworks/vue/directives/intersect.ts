import type { Directive, DirectiveBinding } from 'vue';

type IntersectEl = HTMLElement & {
  __intersectObserver__?: IntersectionObserver;
};

export type IntersectHandler = (entry: IntersectionObserverEntry) => void;

/**
 * Fires when the element enters (or optionally leaves) the viewport.
 * Usage: `v-intersect="onVisible"` or
 * `v-intersect="{ handler, once: true, threshold: 0.25 }"`
 */
export const vIntersect: Directive<
  IntersectEl,
  IntersectHandler | { handler: IntersectHandler; once?: boolean; threshold?: number | number[] }
> = {
  mounted(el, binding: DirectiveBinding) {
    const raw = binding.value;
    if (!raw || typeof IntersectionObserver === 'undefined') return;

    const options =
      typeof raw === 'function'
        ? { handler: raw, once: true, threshold: 0.15 }
        : { once: true, threshold: 0.15, ...raw };

    const observer = new IntersectionObserver(
      (entries) => {
        for (const entry of entries) {
          if (!entry.isIntersecting) continue;
          options.handler(entry);
          if (options.once) observer.unobserve(el);
        }
      },
      { threshold: options.threshold }
    );

    el.__intersectObserver__ = observer;
    observer.observe(el);
  },
  unmounted(el) {
    el.__intersectObserver__?.disconnect();
    delete el.__intersectObserver__;
  },
};
