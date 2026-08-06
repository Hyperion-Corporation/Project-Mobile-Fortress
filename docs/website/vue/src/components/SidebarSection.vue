<script setup lang="ts">
import { ref, computed } from "vue";
import { useRoute } from "vue-router";
import type { NavNode } from "../nav.generated";

const props = defineProps<{ node: NavNode; depth: number }>();
const route = useRoute();

function containsActive(node: NavNode): boolean {
  if (node.kind === "section") return node.children.some(containsActive);
  if (node.kind === "external") return false;
  return node.path === route.path;
}

const isOpen = ref(props.node.kind === "section" ? containsActive(props.node) || props.depth === 0 : false);
const isActive = computed(
  () => props.node.kind !== "section" && props.node.kind !== "external" && props.node.path === route.path
);
</script>

<template>
  <div v-if="node.kind === 'section'" class="nav-section" :style="{ '--depth': depth }">
    <button class="nav-section-toggle" @click="isOpen = !isOpen" :class="{ open: isOpen }">
      <span class="chevron">▸</span>
      {{ node.title }}
    </button>
    <div v-show="isOpen" class="nav-children">
      <SidebarSection v-for="(child, i) in node.children" :key="i" :node="child" :depth="depth + 1" />
    </div>
  </div>

  <a
    v-else-if="node.kind === 'external'"
    class="nav-leaf nav-external"
    :href="node.href"
    target="_blank"
    rel="noopener noreferrer"
    :style="{ '--depth': depth }"
  >
    {{ node.title }} <span class="ext-icon">↗</span>
  </a>

  <router-link v-else class="nav-leaf" :class="{ active: isActive }" :to="node.path" :style="{ '--depth': depth }">
    {{ node.title }}
  </router-link>
</template>

<style scoped>
.nav-section-toggle {
  display: flex;
  align-items: center;
  gap: 0.4rem;
  width: 100%;
  text-align: left;
  padding: 0.4rem 0.75rem;
  padding-left: calc(0.75rem + var(--depth) * 0.85rem);
  background: none;
  border: none;
  font: inherit;
  font-weight: 600;
  font-size: 0.8125rem;
  color: var(--text);
  cursor: pointer;
  border-radius: 6px;
}
.nav-section-toggle:hover {
  background: var(--surface-hover);
}
.chevron {
  display: inline-block;
  font-size: 0.65rem;
  transition: transform 0.15s ease;
  color: var(--text-muted);
}
.nav-section-toggle.open .chevron {
  transform: rotate(90deg);
}

.nav-leaf {
  display: flex;
  align-items: center;
  gap: 0.3rem;
  padding: 0.375rem 0.75rem;
  padding-left: calc(0.75rem + var(--depth) * 0.85rem);
  font-size: 0.8125rem;
  color: var(--text-muted);
  border-radius: 6px;
  border-left: 2px solid transparent;
}
.nav-leaf:hover {
  color: var(--text);
  background: var(--surface-hover);
}
.nav-leaf.active {
  color: var(--accent);
  background: var(--accent-soft);
  font-weight: 600;
  border-left-color: var(--accent);
}
.ext-icon {
  font-size: 0.7rem;
  opacity: 0.6;
}
</style>
