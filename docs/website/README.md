# docs/website/

The interactive Mobile Fortress site: a documentation portal for the whole repository plus an interactive design hub with live gameplay-systems simulators. Deployed to GitHub Pages (`gh-pages` branch) by [`.github/workflows/docs.yml`](../../.github/workflows/docs.yml).

The actual project lives in [`vue/`](vue/) — see [`vue/README.md`](vue/README.md) for local dev/build commands and implementation notes. This file covers what the *site* contains and how to extend it; `vue/README.md` covers how the *app* is built.

## What's on the site

- **Home (`/`)** — the interactive design hub. Five tabs, each a real Vue component under `vue/src/components/hub/`, not static screenshots:
  - **Design** — a Flow Field pathfinding simulator (paint walls/swamp, spawn a raid wave, watch the Dijkstra-routed vector field steer enemies around obstacles).
  - **Tech** — a Genetic Algorithm wall-layout visualizer.
  - **Audio** — a dynamic-mix simulator driven by the same excitement-scale formula the design doc specifies.
  - **Production** — the sprint/phase roadmap.
  - **QA** — a network latency/desync dashboard.
- **Documentation (`/docs` and everything else)** — every Markdown file worth reading in this repository, rendered live with a sidebar, search, table of contents, and prev/next navigation:
  - `docs/*.md` — Architecture, Development, Testing, Glossary, Troubleshooting, Dependency Policy, Documentation Standards, Benchmarks.
  - `docs/adr/` — Architecture Decision Records (auto-expanded from the directory, titled from each file's own `# H1`).
  - `docs/moon/` — the roadmap and changelog.
  - `docs/design/` — the Game Design Document, art bible, audio design doc, pitch deck, production roadmap, QA test plan, technical design document.
  - A curated set of guides that live *outside* `docs/` — the root `README.md`, `git/CONTRIBUTING.md`, `core/README.md` and `core/src/game-state-machine.md`, infra runbooks (`infra/{docker,k8s,helm,terraform,ansible}/README.md`), `.devcontainer/README.md`, and the two research write-ups under `reports/` and `research/`.

## Running it locally

```bash
cd docs/website/vue
npm install
npm run dev       # http://localhost:5173
```

See [`vue/README.md`](vue/README.md) for the build/preview commands and how the production deploy works.

## Navigating the site

- The **topbar** switches between the design hub (logo/brand link) and the documentation portal (**Documentation** link) — the docs sidebar only appears once you're inside `/docs/...`, keeping the hub's hero full-width.
- The **sidebar** is grouped into the sections listed above; click a section header to expand/collapse it, click a page to open it.
- **⌘K / Ctrl+K** opens a fuzzy search over every page's title and source path — arrow keys + Enter to jump straight to a result.
- Every doc page has an **"On this page"** table of contents (from that page's `##`/`###` headings) and **prev/next** links that step through the sidebar in order.
- **"Edit on GitHub"** at the bottom of a page links straight to that file's editor on the `main` branch.
- The **☀️/🌙 toggle** switches light/dark theme; the choice persists across visits (`localStorage`).

## Adding new information

**A new page under `docs/`** (a new roadmap file, a new ADR, a new design doc): add it to [`docs/mkdocs.yml`](../mkdocs.yml)'s `nav:` tree. That's the single source of truth both this site and the MkDocs Material portal (`mkdocs serve`, for local browsing) read from — nothing else to touch. Run `cd docs/website/vue && node scripts/generate-nav.mjs` to confirm it picks up the new entry (this also runs automatically before `npm run dev`/`npm run build`).

- A directory-style `nav:` entry (e.g. `- Architecture Decisions: adr/`) auto-expands into a section from that directory's `*.md` files, using each file's own `# H1` as the title — you don't need to list ADRs individually.
- Route paths are derived from the file path (`moon/ROADMAP.md` → `/moon/ROADMAP`), except `index.md` in any directory, which maps to `/docs` (the docs-portal landing page — `/` itself is reserved for the design hub, see `vue/src/router.ts`).

**A new repo-wide guide that lives outside `docs/`** (e.g. a new module's `README.md`): add an entry to `EXTRA_SECTIONS` in [`vue/scripts/generate-nav.mjs`](vue/scripts/generate-nav.mjs) — a `{ title, source }` pair under the appropriate section (`Codebase Guides`, `Infrastructure`, `Research`, or a new section). This list is hand-curated rather than a full repo walk, so the nav stays deliberate — a file won't appear here just by existing.

**Content inside an existing page**: just edit the Markdown file itself (or use the page's own "Edit on GitHub" link) — no site code changes needed. Supported in every page: GitHub-flavored Markdown, fenced code blocks with syntax highlighting (see `vue/src/composables/useMarkdown.ts` for the registered languages — add a `highlight.js` language import there if you need one that isn't), ` ```mermaid ` fences for diagrams, and `$inline$` / `$$block$$` math via KaTeX.

**A new interactive design-hub panel**: add a `.vue` component under `vue/src/components/hub/`, then register it in the `tabs` array in `vue/src/views/HomeView.vue`.

## Important things to know

- **The generated nav file is not hand-edited.** `vue/src/nav.generated.ts` is overwritten by `generate-nav.mjs` on every `dev`/`build` run — never edit it directly, and don't be surprised when your manual edit disappears.
- **Two documentation front-ends share one source of truth.** `docs/mkdocs.yml`'s `nav:` tree drives both this Vue site and the MkDocs Material portal — keep entries there, not duplicated into this site's config.
- **Duplicate routes fail the build, loudly.** `generate-nav.mjs` throws if two pages resolve to the same URL path, so a copy-pasted nav entry or a colliding filename is caught at generation time, not silently at runtime.
- **No content/ mirror at deploy time.** Every Markdown source is bundled directly into the site at build time via `import.meta.glob` — nothing is fetched at runtime, so there's no separate "publish the docs somewhere the site can read them" step to forget.
- **The docs sidebar and the design hub are deliberately separate layouts.** The hub (`/`) is full-width with no sidebar; every documentation route gets the sidebar/TOC layout. If a new top-level view needs a *third* layout, it belongs alongside these two in `vue/src/App.vue`, not bolted onto either existing one.
- **`README.md` here vs. `vue/README.md`**: this file is about the *site* (what's on it, how to use it, how to add content); `vue/README.md` is about the *app* (how the code is built, local dev, deploy mechanics). Update the one that actually changed.
