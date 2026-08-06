<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted, nextTick, watch } from "vue";
import { useRouter } from "vue-router";
import { searchIndex } from "../nav.generated";

const open = ref(false);
const query = ref("");
const activeIndex = ref(0);
const inputRef = ref<HTMLInputElement | null>(null);
const router = useRouter();

const results = computed(() => {
  const q = query.value.trim().toLowerCase();
  if (!q) return searchIndex.slice(0, 8);
  return searchIndex.filter((p) => p.title.toLowerCase().includes(q) || p.source.toLowerCase().includes(q)).slice(0, 20);
});

watch(results, () => (activeIndex.value = 0));

function openSearch() {
  open.value = true;
  query.value = "";
  nextTick(() => inputRef.value?.focus());
}
function closeSearch() {
  open.value = false;
}
function go(path: string) {
  router.push(path);
  closeSearch();
}

function onKeydown(e: KeyboardEvent) {
  if ((e.metaKey || e.ctrlKey) && e.key.toLowerCase() === "k") {
    e.preventDefault();
    open.value ? closeSearch() : openSearch();
    return;
  }
  if (!open.value) return;
  if (e.key === "Escape") closeSearch();
  if (e.key === "ArrowDown") {
    e.preventDefault();
    activeIndex.value = Math.min(activeIndex.value + 1, results.value.length - 1);
  }
  if (e.key === "ArrowUp") {
    e.preventDefault();
    activeIndex.value = Math.max(activeIndex.value - 1, 0);
  }
  if (e.key === "Enter") {
    const r = results.value[activeIndex.value];
    if (r) go(r.path);
  }
}

onMounted(() => window.addEventListener("keydown", onKeydown));
onUnmounted(() => window.removeEventListener("keydown", onKeydown));
</script>

<template>
  <button class="search-trigger" @click="openSearch" aria-label="Search docs">
    <svg viewBox="0 0 20 20" width="15" height="15" fill="none"><circle cx="9" cy="9" r="6" stroke="currentColor" stroke-width="1.8" /><path d="M17 17l-3.5-3.5" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" /></svg>
    <span class="search-trigger-text">Search docs…</span>
    <kbd>⌘K</kbd>
  </button>

  <Teleport to="body">
    <div v-if="open" class="search-overlay" @click.self="closeSearch">
      <div class="search-modal">
        <div class="search-input-row">
          <svg viewBox="0 0 20 20" width="16" height="16" fill="none"><circle cx="9" cy="9" r="6" stroke="currentColor" stroke-width="1.8" /><path d="M17 17l-3.5-3.5" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" /></svg>
          <input
            ref="inputRef"
            v-model="query"
            type="text"
            placeholder="Search pages by title or path…"
            autocomplete="off"
          />
          <kbd>Esc</kbd>
        </div>
        <div class="search-results">
          <button
            v-for="(r, i) in results"
            :key="r.path"
            class="search-result"
            :class="{ active: i === activeIndex }"
            @mouseenter="activeIndex = i"
            @click="go(r.path)"
          >
            <span class="result-title">{{ r.title }}</span>
            <span class="result-path">{{ r.source }}</span>
          </button>
          <div v-if="!results.length" class="search-empty">No pages found.</div>
        </div>
      </div>
    </div>
  </Teleport>
</template>

<style scoped>
.search-trigger {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  padding: 0.4rem 0.6rem;
  border: 1px solid var(--border);
  border-radius: 8px;
  background: var(--surface);
  color: var(--text-muted);
  font-size: 0.8125rem;
  min-width: 200px;
}
.search-trigger:hover {
  border-color: var(--accent);
}
.search-trigger-text {
  flex: 1;
  text-align: left;
}
kbd {
  font-family: inherit;
  font-size: 0.6875rem;
  padding: 0.05rem 0.35rem;
  border-radius: 4px;
  background: var(--surface-hover);
  border: 1px solid var(--border);
}

.search-overlay {
  position: fixed;
  inset: 0;
  background: rgba(15, 15, 20, 0.5);
  backdrop-filter: blur(2px);
  z-index: 100;
  display: flex;
  align-items: flex-start;
  justify-content: center;
  padding-top: 12vh;
}
.search-modal {
  width: min(560px, 92vw);
  background: var(--bg);
  border: 1px solid var(--border);
  border-radius: 14px;
  box-shadow: 0 24px 60px rgba(0, 0, 0, 0.35);
  overflow: hidden;
}
.search-input-row {
  display: flex;
  align-items: center;
  gap: 0.6rem;
  padding: 0.9rem 1rem;
  border-bottom: 1px solid var(--border);
  color: var(--text-muted);
}
.search-input-row input {
  flex: 1;
  border: none;
  background: none;
  outline: none;
  font-size: 0.95rem;
  color: var(--text);
}
.search-results {
  max-height: 50vh;
  overflow-y: auto;
  padding: 0.5rem;
}
.search-result {
  width: 100%;
  display: flex;
  flex-direction: column;
  align-items: flex-start;
  gap: 0.1rem;
  padding: 0.55rem 0.75rem;
  border-radius: 8px;
  text-align: left;
}
.search-result.active,
.search-result:hover {
  background: var(--accent-soft);
}
.result-title {
  font-size: 0.875rem;
  color: var(--text);
  font-weight: 500;
}
.result-path {
  font-size: 0.75rem;
  color: var(--text-muted);
}
.search-empty {
  padding: 1.5rem;
  text-align: center;
  color: var(--text-muted);
  font-size: 0.875rem;
}

@media (max-width: 640px) {
  .search-trigger-text,
  .search-trigger kbd {
    display: none;
  }
}
</style>
