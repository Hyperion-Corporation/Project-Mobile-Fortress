<script setup lang="ts">
// Mounts the React island (UnitRosterBoard.tsx) into a Vue-owned DOM node
// via ReactDOM.createRoot — Vite's @vitejs/plugin-react (scoped to
// frameworks/react/**/*.tsx in vite.config.ts) is what makes the .tsx
// import below compile at all inside a Vue project.
import { onMounted, onUnmounted, ref } from "vue";
import type { Root } from "react-dom/client";
import { logIslandMount, logIslandUnmount } from "../../../shared/utils";

const hostEl = ref<HTMLDivElement | null>(null);
let root: Root | null = null;

onMounted(async () => {
  if (!hostEl.value) return;
  const [{ createRoot }, React, { default: UnitRosterBoard }] = await Promise.all([
    import("react-dom/client"),
    import("react"),
    import("../../../react/UnitRosterBoard"),
  ]);
  root = createRoot(hostEl.value);
  root.render(React.createElement(UnitRosterBoard));
  logIslandMount("React", "unit-roster-board");
});

onUnmounted(() => {
  // Unmount outside React's own commit phase so the teardown doesn't race
  // Vue's own DOM removal of hostEl.
  const r = root;
  root = null;
  if (r) queueMicrotask(() => r.unmount());
  logIslandUnmount("React", "unit-roster-board");
});
</script>

<template>
  <section class="react-island-wrap panel">
    <p class="island-label">Framework island · React — live unit roster (src/constants/fortress.ts)</p>
    <div ref="hostEl" class="react-host" />
  </section>
</template>

<style scoped>
.react-island-wrap {
  padding: 1.25rem;
}
.island-label {
  font-size: 0.72rem;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  color: var(--text-muted);
  margin: 0 0 0.9rem;
}

.react-host :deep(.urb-filters) {
  display: flex;
  flex-wrap: wrap;
  gap: 0.75rem;
  margin-bottom: 1rem;
}
.react-host :deep(.urb-filter-group) {
  display: flex;
  flex-wrap: wrap;
  gap: 0.4rem;
}
.react-host :deep(.urb-chip) {
  padding: 0.35rem 0.8rem;
  border-radius: 999px;
  border: 1px solid var(--surface-hover);
  background: var(--surface);
  color: var(--text-muted);
  font-size: 0.8rem;
  font-weight: 600;
}
.react-host :deep(.urb-chip:hover) {
  color: var(--text);
  border-color: var(--accent);
}
.react-host :deep(.urb-chip.active) {
  background: var(--accent);
  border-color: var(--accent);
  color: #fff;
}
.react-host :deep(.urb-list) {
  list-style: none;
  margin: 0;
  padding: 0;
  display: flex;
  flex-direction: column;
  gap: 0.4rem;
}
.react-host :deep(.urb-row) {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  padding: 0.55rem 0.8rem;
  border-radius: 8px;
  background: var(--surface);
  font-size: 0.85rem;
}
.react-host :deep(.urb-name) {
  flex: 1;
  font-weight: 600;
}
.react-host :deep(.urb-badge) {
  font-size: 0.68rem;
  text-transform: uppercase;
  letter-spacing: 0.04em;
  padding: 0.15rem 0.5rem;
  border-radius: 999px;
  background: var(--surface-hover);
  color: var(--text-muted);
}
.react-host :deep(.urb-civ) {
  color: var(--text-muted);
  font-size: 0.78rem;
}
.react-host :deep(.urb-empty) {
  color: var(--text-muted);
  padding: 0.5rem;
  font-size: 0.85rem;
}
</style>
