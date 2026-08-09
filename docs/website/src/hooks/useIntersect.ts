import { useEffect, type RefObject } from "react";

export type IntersectHandler = (entry: IntersectionObserverEntry) => void;

export interface UseIntersectOptions {
  once?: boolean;
  threshold?: number | number[];
}

/**
 * Fires `handler` when `ref`'s element enters the viewport.
 * React port of the Vue `v-intersect` directive.
 */
export function useIntersect<T extends HTMLElement>(
  ref: RefObject<T | null>,
  handler: IntersectHandler,
  { once = true, threshold = 0.15 }: UseIntersectOptions = {}
): void {
  useEffect(() => {
    const el = ref.current;
    if (!el || typeof IntersectionObserver === "undefined") return;

    const observer = new IntersectionObserver(
      (entries) => {
        for (const entry of entries) {
          if (!entry.isIntersecting) continue;
          handler(entry);
          if (once) observer.unobserve(el);
        }
      },
      { threshold }
    );
    observer.observe(el);
    return () => observer.disconnect();
    // handler/threshold are expected to be stable per call site.
  }, [ref, once]);
}
