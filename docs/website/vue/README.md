# docs/website/vue/

A Vite + Vue 3 + TypeScript single-page app: the interactive design hub plus a documentation portal that renders every `docs/**/*.md` file (and a curated set of repo-wide guides) directly — no separate content pipeline. Deployed to GitHub Pages from the `gh-pages` branch by [`.github/workflows/docs.yml`](../../../.github/workflows/docs.yml).

For what the site actually contains and how to navigate/extend it, see [`../README.md`](../README.md). This file is about the app itself.

## How it works

- `scripts/generate-nav.mjs` parses [`../../mkdocs.yml`](../../mkdocs.yml)'s `nav:` tree (the single source of truth for site structure — shared with the MkDocs Material build) plus a hand-curated `EXTRA_SECTIONS` list of repo-wide guides that live outside `docs/`, into `src/nav.generated.ts`. Runs automatically before `dev`/`build` via the npm `pre*` hooks.
- `src/composables/useDocs.ts` bundles every matching Markdown file under the repo via `import.meta.glob` (raw-string imports, lazily loaded per route) — adding a page to the nav is enough, no manual import needed.
- `src/composables/useMarkdown.ts` renders Markdown with `markdown-it` (`markdown-it-anchor` for heading permalinks, `markdown-it-texmath` + KaTeX for `$...$`/`$$...$$` math, `highlight.js` for code blocks). Mermaid diagrams are rendered live, lazily, in `src/views/DocPage.vue`.
- Routing (`src/router.ts`) is `createWebHistory` plus a single catch-all route (`src/views/DocPage.vue`) that resolves the URL against the generated nav index, with `/` reserved for `src/views/HomeView.vue` (the design hub).
- `public/404.html` + the inline restore script in `index.html` implement the standard [GitHub Pages SPA redirect trick](https://github.com/rafgraph/spa-github-pages): GitHub Pages serves `404.html` for any unmatched deep link (e.g. reloading `/docs/design/game_design_document`), which re-encodes the path into a query string and redirects to the real `index.html`; the inline script there restores it via `history.replaceState` before Vue Router boots. Without this, deep links and hard reloads would 404 on GitHub Pages' static hosting.

## Local dev

```bash
cd docs/website/vue
npm install
npm run dev       # http://localhost:5173
```

## Build

```bash
npm run build      # vue-tsc type-check, then vite build -> dist/
npm run preview    # serve dist/ locally
```

Set `SITE_BASE` when building for a non-root deploy target so asset URLs and the 404 redirect resolve correctly — the production deploy (`.github/workflows/docs.yml`) sets it to `/<repo-name>/` to match the GitHub Pages project-site subpath:

```bash
SITE_BASE=/Project-Mobile-Fortress/ npm run build
```

## Project layout

```
vue/
├── index.html              # entry HTML + the 404-redirect restore script
├── public/404.html         # GitHub Pages SPA-fallback redirect
├── vite.config.ts          # base path (SITE_BASE), dev-server fs.allow
├── scripts/generate-nav.mjs
└── src/
    ├── main.ts             # app bootstrap, global CSS imports
    ├── router.ts            # routes: "/" -> HomeView, everything else -> DocPage
    ├── App.vue              # topbar + sidebar/full-width layout switch
    ├── nav.generated.ts     # AUTO-GENERATED — do not edit by hand
    ├── composables/
    │   ├── useDocs.ts        # import.meta.glob bundling + source resolution
    │   ├── useMarkdown.ts    # markdown-it render pipeline, TOC/title extraction
    │   └── useTheme.ts       # light/dark toggle, persisted to localStorage
    ├── components/
    │   ├── Sidebar.vue, SidebarSection.vue, SearchBox.vue, ThemeToggle.vue
    │   └── hub/               # the five interactive design-hub panels
    ├── views/
    │   ├── HomeView.vue       # hero + design-hub tabs
    │   └── DocPage.vue        # generic Markdown-doc renderer (sidebar/TOC/prev-next)
    └── styles/
        ├── theme.css          # CSS custom properties, light/dark palettes
        ├── markdown.css        # rendered-Markdown typography
        └── hub.css             # design-hub-specific styling
```

## Adding a page

Add the Markdown file wherever it belongs under `docs/`, then add an entry to [`../../mkdocs.yml`](../../mkdocs.yml)'s `nav:` — both the MkDocs/Material portal and this site pick it up automatically on the next build. For a guide that lives outside `docs/`, add it to `EXTRA_SECTIONS` in `scripts/generate-nav.mjs` instead — see that file's module doc comment for why the two are separate.

## Notable implementation gotcha

`useDocs.ts` lives *inside* `docs/` (at `docs/website/vue/src/composables/`). Its `import.meta.glob` pattern's `../../../../../**/*.md` climbs to the repo root, but because this file's own path re-enters `docs/` on the way back down for anything nested under `docs/`, Node's path normalization silently cancels one `docs/` segment (and one `..` step) in the resulting glob keys — e.g. `docs/ARCHITECTURE.md` resolves to a key ending in `.../ARCHITECTURE.md`, not `.../docs/ARCHITECTURE.md`. `resolveKey()` in `useDocs.ts` accounts for this explicitly (see the comment there); if you restructure this project's directory nesting, re-verify that logic rather than assuming the naive relative path is correct.
