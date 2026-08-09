import { useEffect, type RefObject } from "react";

/**
 * Calls `handler` on a pointer event outside `ref`'s element.
 * React port of the Vue `v-click-outside` directive — same capture-phase
 * listener so nested `stopPropagation()` calls still observe outside clicks.
 */
export function useClickOutside<T extends HTMLElement>(
  ref: RefObject<T | null>,
  handler: (event: MouseEvent) => void
): void {
  useEffect(() => {
    function onClick(event: MouseEvent) {
      const target = event.target as Node | null;
      if (!ref.current || !target || ref.current.contains(target)) return;
      handler(event);
    }
    document.addEventListener("click", onClick, true);
    return () => document.removeEventListener("click", onClick, true);
  }, [ref, handler]);
}
