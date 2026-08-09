import { useEffect, type RefObject } from "react";

/**
 * Focuses `ref`'s element whenever `active` becomes truthy.
 * React port of the Vue `v-focus="active"` directive.
 */
export function useFocusWhen<T extends HTMLElement>(ref: RefObject<T | null>, active: boolean): void {
  useEffect(() => {
    if (!active) return;
    const id = queueMicrotask(() => ref.current?.focus());
    return () => void id;
  }, [ref, active]);
}
