<script setup lang="ts">
import { ref, computed, watch } from "vue";
import { useRoute } from "vue-router";
import Sidebar from "./components/Sidebar.vue";
import SearchBox from "./components/SearchBox.vue";
import ThemeToggle from "./components/ThemeToggle.vue";

const sidebarOpen = ref(false);
const route = useRoute();
watch(() => route.fullPath, () => (sidebarOpen.value = false));

// The "/" route is the interactive design-hub landing page, not a doc — hide
// the persistent docs sidebar there so the hero reads as a full-width page,
// and show it (with a full nav grid) for every actual documentation route.
const isHome = computed(() => route.path === "/");
</script>

<template>
  <div class="layout">
    <header class="topbar">
      <div class="topbar-left">
        <button v-if="!isHome" class="menu-btn" @click="sidebarOpen = !sidebarOpen" aria-label="Toggle navigation">
          <svg viewBox="0 0 20 20" width="18" height="18" fill="none">
            <path d="M3 5h14M3 10h14M3 15h14" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" />
          </svg>
        </button>
        <router-link to="/" class="brand">
          <span class="brand-mark">🏯</span>
          <span class="brand-name">Mobile Fortress</span>
          <span class="brand-tag">嘉靖倭寇 1540s–1560s</span>
        </router-link>
      </div>
      <div class="topbar-right">
        <router-link to="/docs" class="docs-link" :class="{ active: !isHome }">Documentation</router-link>
        <SearchBox />
        <a
          class="icon-link"
          href="https://github.com/ACFHarbinger/Project-Mobile-Fortress"
          target="_blank"
          rel="noopener noreferrer"
          aria-label="GitHub repository"
        >
          <svg viewBox="0 0 24 24" width="19" height="19" fill="currentColor">
            <path
              d="M12 2C6.477 2 2 6.484 2 12.017c0 4.425 2.865 8.18 6.839 9.504.5.092.682-.217.682-.483 0-.237-.008-.868-.013-1.703-2.782.605-3.369-1.343-3.369-1.343-.454-1.158-1.11-1.466-1.11-1.466-.908-.62.069-.608.069-.608 1.003.07 1.531 1.032 1.531 1.032.892 1.53 2.341 1.088 2.91.833.092-.647.35-1.088.636-1.339-2.221-.253-4.555-1.113-4.555-4.951 0-1.093.39-1.988 1.029-2.688-.103-.253-.446-1.272.098-2.65 0 0 .84-.269 2.75 1.026A9.564 9.564 0 0 1 12 6.844c.85.004 1.705.115 2.504.337 1.909-1.295 2.747-1.026 2.747-1.026.546 1.378.203 2.397.1 2.65.64.7 1.028 1.595 1.028 2.688 0 3.848-2.339 4.695-4.566 4.943.359.309.678.919.678 1.852 0 1.336-.012 2.415-.012 2.744 0 .268.18.58.688.482A10.02 10.02 0 0 0 22 12.017C22 6.484 17.523 2 12 2Z"
            />
          </svg>
        </a>
        <ThemeToggle />
      </div>
    </header>

    <div class="body" :class="{ 'body-full': isHome }">
      <Sidebar v-if="!isHome" :open="sidebarOpen" @close="sidebarOpen = false" />
      <main class="content">
        <router-view />
      </main>
    </div>
  </div>
</template>

<style scoped>
.layout {
  min-height: 100vh;
  display: flex;
  flex-direction: column;
}

.topbar {
  position: sticky;
  top: 0;
  z-index: 20;
  height: 3.5rem;
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 0 1.25rem;
  background: color-mix(in srgb, var(--bg) 88%, transparent);
  backdrop-filter: blur(10px);
  border-bottom: 1px solid var(--border);
}
.topbar-left,
.topbar-right {
  display: flex;
  align-items: center;
  gap: 0.9rem;
}

.menu-btn {
  display: none;
  color: var(--text-muted);
}

.brand {
  display: flex;
  align-items: baseline;
  gap: 0.5rem;
  color: var(--text);
  font-weight: 600;
  font-size: 0.95rem;
}
.brand-mark {
  font-size: 1.3rem;
  line-height: 1;
}
.brand-name {
  font-family: var(--font-display);
  letter-spacing: 0.02em;
}
.brand-tag {
  font-size: 0.7rem;
  color: var(--accent);
  font-weight: 700;
  letter-spacing: 0.05em;
  display: none;
}

.docs-link {
  font-size: 0.85rem;
  font-weight: 600;
  color: var(--text-muted);
  padding: 0.4rem 0.1rem;
  position: relative;
}
.docs-link:hover {
  color: var(--text);
}
.docs-link.active {
  color: var(--accent);
}
@media (max-width: 640px) {
  .docs-link {
    display: none;
  }
}

.icon-link {
  display: grid;
  place-items: center;
  width: 2.1rem;
  height: 2.1rem;
  border-radius: 8px;
  color: var(--text-muted);
}
.icon-link:hover {
  color: var(--text);
  background: var(--surface-hover);
}

.body {
  flex: 1;
  display: grid;
  grid-template-columns: 260px minmax(0, 1fr);
}
.body.body-full {
  grid-template-columns: minmax(0, 1fr);
}

.content {
  min-width: 0;
}

@media (min-width: 1200px) {
  .brand-tag {
    display: inline;
  }
}

@media (max-width: 980px) {
  .body {
    grid-template-columns: 1fr;
  }
  .menu-btn {
    display: grid;
    place-items: center;
    width: 2rem;
    height: 2rem;
  }
}
</style>
