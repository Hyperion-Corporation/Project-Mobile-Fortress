<script setup lang="ts">
import { navTree } from "../nav.generated";
import SidebarSection from "./SidebarSection.vue";

defineProps<{ open: boolean }>();
const emit = defineEmits<{ close: [] }>();
</script>

<template>
  <div v-if="open" class="sidebar-scrim" @click="emit('close')" />
  <nav class="sidebar" :class="{ open }">
    <SidebarSection v-for="(node, i) in navTree" :key="i" :node="node" :depth="0" />
  </nav>
</template>

<style scoped>
.sidebar {
  display: flex;
  flex-direction: column;
  gap: 0.125rem;
  padding: 1.25rem 0.75rem 3rem;
  overflow-y: auto;
}

.sidebar-scrim {
  display: none;
}

@media (max-width: 980px) {
  .sidebar {
    position: fixed;
    top: 3.5rem;
    left: 0;
    bottom: 0;
    width: 280px;
    background: var(--bg);
    border-right: 1px solid var(--border);
    transform: translateX(-100%);
    transition: transform 0.2s ease;
    z-index: 40;
  }
  .sidebar.open {
    transform: translateX(0);
  }
  .sidebar-scrim {
    display: block;
    position: fixed;
    inset: 3.5rem 0 0 0;
    background: rgba(0, 0, 0, 0.4);
    z-index: 30;
  }
}
</style>
