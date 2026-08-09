<script setup lang="ts">
import { computed, ref } from 'vue';

const props = withDefaults(
  defineProps<{
    /** iframe height */
    height?: string;
    /** Optional title override for accessibility */
    title?: string;
  }>(),
  {
    height: '420px',
    title: 'Astro coastal flow field island',
  }
);

const loaded = ref(false);
const failed = ref(false);
const inView = ref(false);

// public/ assets need BASE_URL when deployed under a GitHub Pages subpath.
const islandSrc = computed(
  () => `${import.meta.env.BASE_URL}astro-island/index.html`
);

function onLoad() {
  loaded.value = true;
}

function onError() {
  failed.value = true;
}

function onEnterViewport() {
  inView.value = true;
}
</script>

<template>
  <section
    class="astro-island-wrap"
    :data-in-view="inView ? 'true' : 'false'"
    v-intersect="{ handler: onEnterViewport, once: true, threshold: 0.2 }"
  >
    <header class="wrap-header">
      <p class="kicker">Framework island · Astro</p>
      <h2>Raid-lane flow field</h2>
      <p class="lede">
        Static Astro island illustrating land and sea approach vectors toward the citadel — a design-hub
        companion to Flow Field / Dijkstra pathing notes in the technical blueprint (MFP5).
      </p>
    </header>

    <div class="frame-shell" :style="{ minHeight: height }">
      <p v-if="failed" class="fallback" role="alert">
        Astro island failed to load. Rebuild with <code>npm run build:astro</code> so
        <code>public/astro-island/</code> is present.
      </p>
      <iframe
        v-show="!failed"
        class="island-frame"
        :src="islandSrc"
        :title="title"
        :style="{ height }"
        loading="lazy"
        referrerpolicy="no-referrer"
        @load="onLoad"
        @error="onError"
      />
      <p v-if="!loaded && !failed" class="loading">Loading Astro island…</p>
    </div>
  </section>
</template>

<style scoped>
.astro-island-wrap {
  margin: 2rem 0 2.5rem;
}
.wrap-header {
  margin-bottom: 0.85rem;
}
.kicker {
  margin: 0 0 0.25rem;
  font-size: 0.72rem;
  letter-spacing: 0.08em;
  text-transform: uppercase;
  color: var(--text-muted);
}
.wrap-header h2 {
  margin: 0;
  font-size: 1.35rem;
}
.lede {
  margin: 0.4rem 0 0;
  max-width: 42rem;
  color: var(--text-muted);
  font-size: 0.95rem;
}
.frame-shell {
  position: relative;
  border-radius: 14px;
  overflow: hidden;
  border: 1px solid var(--border);
  background: var(--surface);
}
.island-frame {
  width: 100%;
  border: 0;
  display: block;
  background: transparent;
}
.loading,
.fallback {
  position: absolute;
  inset: 0;
  display: grid;
  place-items: center;
  margin: 0;
  padding: 1rem;
  text-align: center;
  color: var(--text-muted);
  font-size: 0.9rem;
}
.fallback code {
  font-size: 0.85em;
}
</style>
