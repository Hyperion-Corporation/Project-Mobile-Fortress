<script setup lang="ts">
import { ref, computed, watch, nextTick, onMounted } from "vue";
import { useRoute } from "vue-router";
import { searchIndex } from "../../../nav.generated";
import { loadDoc } from "../../../composables/useDocs";
import { renderMarkdown, extractTitle, extractToc, type TocEntry } from "../../../composables/useMarkdown";

const route = useRoute();

const state = ref<"loading" | "ok" | "notfound">("loading");
const html = ref("");
const title = ref("");
const toc = ref<TocEntry[]>([]);
const editSource = ref("");
const contentEl = ref<HTMLElement | null>(null);

const REPO_EDIT_BASE = "https://github.com/ACFHarbinger/Project-Mobile-Fortress/edit/main/";

const currentPath = computed(() => {
  const p = "/" + (Array.isArray(route.params.pathMatch) ? route.params.pathMatch.join("/") : "");
  return p.replace(/\/$/, "") || "/";
});

const currentIndex = computed(() => searchIndex.findIndex((p) => p.path === currentPath.value));
const prevDoc = computed(() => (currentIndex.value > 0 ? searchIndex[currentIndex.value - 1] : null));
const nextDoc = computed(() =>
  currentIndex.value >= 0 && currentIndex.value < searchIndex.length - 1 ? searchIndex[currentIndex.value + 1] : null
);

async function renderMermaid() {
  const nodes = contentEl.value?.querySelectorAll<HTMLElement>(".mermaid");
  if (!nodes || !nodes.length) return;
  const mermaid = (await import("mermaid")).default;
  mermaid.initialize({
    startOnLoad: false,
    theme: document.documentElement.getAttribute("data-theme") === "dark" ? "dark" : "default",
    securityLevel: "loose",
  });
  try {
    await mermaid.run({ nodes: Array.from(nodes) });
  } catch (e) {
    console.warn("mermaid render failed", e);
  }
}

function addCopyButtons() {
  const blocks = contentEl.value?.querySelectorAll<HTMLElement>("pre.hljs");
  blocks?.forEach((pre) => {
    if (pre.querySelector(".copy-btn")) return;
    const code = pre.querySelector("code");
    if (!code) return;
    const btn = document.createElement("button");
    btn.type = "button";
    btn.className = "copy-btn";
    btn.textContent = "Copy";
    btn.addEventListener("click", () => {
      navigator.clipboard.writeText(code.textContent || "").then(() => {
        btn.textContent = "Copied!";
        setTimeout(() => (btn.textContent = "Copy"), 1500);
      });
    });
    pre.appendChild(btn);
  });
}

async function load() {
  state.value = "loading";
  const entry = searchIndex.find((p) => p.path === currentPath.value);
  if (!entry) {
    state.value = "notfound";
    return;
  }
  editSource.value = entry.source;

  const raw = await loadDoc(entry.source);
  if (raw === null) {
    state.value = "notfound";
    return;
  }
  title.value = extractTitle(raw) || entry.title;
  toc.value = extractToc(raw);
  html.value = renderMarkdown(raw);
  state.value = "ok";
  document.title = `${title.value} — Mobile Fortress Docs`;
  await nextTick();
  renderMermaid();
  addCopyButtons();
}

watch(() => route.fullPath, load);
onMounted(load);
</script>

<template>
  <div class="doc-page">
    <div v-if="state === 'loading'" class="doc-loading">Loading…</div>

    <div v-else-if="state === 'notfound'" class="doc-notfound">
      <h1>404</h1>
      <p>No page found for <code>{{ currentPath }}</code>.</p>
      <router-link to="/docs">← Back to documentation</router-link>
    </div>

    <template v-else>
      <article class="doc-content">
        <div ref="contentEl" class="markdown-body" v-html="html"></div>
        <a class="edit-link" :href="REPO_EDIT_BASE + editSource" target="_blank" rel="noopener noreferrer">
          Edit this page on GitHub ↗
        </a>

        <nav class="prev-next">
          <router-link v-if="prevDoc" :to="prevDoc.path" class="prev-next-link prev">
            <span>← Previous</span>{{ prevDoc.title }}
          </router-link>
          <span v-else></span>
          <router-link v-if="nextDoc" :to="nextDoc.path" class="prev-next-link next">
            <span>Next →</span>{{ nextDoc.title }}
          </router-link>
        </nav>
      </article>

      <aside v-if="toc.length" class="doc-toc">
        <div class="doc-toc-title">On this page</div>
        <nav>
          <a
            v-for="entry in toc"
            :key="entry.id"
            :href="'#' + entry.id"
            :class="['toc-link', `toc-level-${entry.level}`]"
          >
            {{ entry.text }}
          </a>
        </nav>
      </aside>
    </template>
  </div>
</template>

<style scoped>
.doc-page {
  display: grid;
  grid-template-columns: minmax(0, 1fr) 220px;
  gap: 2.5rem;
  align-items: start;
  max-width: 1100px;
  margin: 0 auto;
  padding: 2.5rem 2rem 6rem;
}

.doc-content {
  min-width: 0;
}

.doc-loading,
.doc-notfound {
  padding: 4rem 2rem;
  text-align: center;
  color: var(--text-muted);
}

.edit-link {
  display: inline-block;
  margin-top: 3rem;
  padding-top: 1.25rem;
  border-top: 1px solid var(--border);
  font-size: 0.875rem;
  color: var(--text-muted);
}
.edit-link:hover {
  color: var(--accent);
}

.prev-next {
  display: flex;
  justify-content: space-between;
  gap: 1rem;
  margin-top: 1.5rem;
}
.prev-next-link {
  display: flex;
  flex-direction: column;
  max-width: 45%;
  padding: 0.9rem 1.2rem;
  border: 1px solid var(--border);
  border-radius: 8px;
  color: var(--text);
  font-size: 0.9rem;
}
.prev-next-link:hover {
  border-color: var(--accent);
  background: var(--surface-hover);
}
.prev-next-link.next {
  text-align: right;
  margin-left: auto;
}
.prev-next-link span {
  font-size: 0.75rem;
  color: var(--text-muted);
  margin-bottom: 0.2rem;
}

.doc-toc {
  position: sticky;
  top: 5.5rem;
  font-size: 0.8125rem;
}
.doc-toc-title {
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.04em;
  font-size: 0.6875rem;
  color: var(--text-muted);
  margin-bottom: 0.75rem;
}
.doc-toc nav {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
  border-left: 1px solid var(--border);
}
.toc-link {
  color: var(--text-muted);
  padding-left: 0.875rem;
  line-height: 1.4;
}
.toc-link:hover {
  color: var(--text);
}
.toc-level-3 {
  padding-left: 1.75rem;
  font-size: 0.75rem;
}

@media (max-width: 980px) {
  .doc-page {
    grid-template-columns: 1fr;
    padding: 1.5rem 1.25rem 4rem;
  }
  .doc-toc {
    display: none;
  }
}
</style>
