import { onMounted, onUnmounted, ref, type Ref } from 'vue';

/**
 * Tracks `prefers-reduced-motion` for hub animations and island effects.
 * Vue counterpart of github-pages `src/hooks/useReducedMotion`.
 */
export function useReducedMotion(): Ref<boolean> {
  const reducedMotion = ref(false);
  let media: MediaQueryList | null = null;

  function update() {
    reducedMotion.value = media?.matches ?? false;
  }

  onMounted(() => {
    if (typeof window.matchMedia !== 'function') return;
    media = window.matchMedia('(prefers-reduced-motion: reduce)');
    update();
    media.addEventListener('change', update);
  });

  onUnmounted(() => {
    media?.removeEventListener('change', update);
  });

  return reducedMotion;
}
