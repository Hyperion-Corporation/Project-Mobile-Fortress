<script setup lang="ts">
import { useTheme } from "../composables/useTheme";
const { theme, toggle } = useTheme();
</script>

<template>
  <button class="theme-toggle" @click="toggle" :aria-label="`Switch to ${theme === 'light' ? 'dark' : 'light'} mode`">
    <svg v-if="theme === 'light'" viewBox="0 0 24 24" width="17" height="17" fill="none">
      <circle cx="12" cy="12" r="4.5" stroke="currentColor" stroke-width="1.8" />
      <path
        stroke="currentColor"
        stroke-width="1.8"
        stroke-linecap="round"
        d="M12 2.5v2M12 19.5v2M4.2 4.2l1.4 1.4M18.4 18.4l1.4 1.4M2.5 12h2M19.5 12h2M4.2 19.8l1.4-1.4M18.4 5.6l1.4-1.4"
      />
    </svg>
    <svg v-else viewBox="0 0 24 24" width="17" height="17" fill="none">
      <path
        d="M20 14.5A8.5 8.5 0 1 1 9.5 4a7 7 0 0 0 10.5 10.5Z"
        stroke="currentColor"
        stroke-width="1.8"
        stroke-linejoin="round"
      />
    </svg>
  </button>
</template>

<style scoped>
.theme-toggle {
  display: grid;
  place-items: center;
  width: 2.1rem;
  height: 2.1rem;
  border-radius: 8px;
  color: var(--text-muted);
  border: 1px solid var(--border);
  background: var(--surface);
}
.theme-toggle:hover {
  color: var(--text);
  border-color: var(--accent);
}
</style>
