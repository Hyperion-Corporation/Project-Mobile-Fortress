# docs/website/

Vite + Vue 3 + TypeScript documentation portal and interactive design hub for **Project Mobile Fortress**. Deployed to GitHub Pages from the `gh-pages` branch by [`.github/workflows/docs.yml`](../../.github/workflows/docs.yml).

This package lives at `docs/website/` (not a nested `vue/` subfolder). Base app modules (`styles/`, `views/`, `composables/`, `router.ts`) sit under `src/` like github-pages; Vue UI components and the shell wrapper live under `src/frameworks/vue/`.

## What the site is

A single SPA that combines:

1. **Design hub** (`/`) — interactive panels (design, tech, audio, production, QA) implemented as Vue SFCs.
2. **Documentation portal** (`/docs/...` and other nav routes) — every page in [`docs/mkdocs.yml`](../mkdocs.yml)'s `nav:` tree, plus a curated list of repo-wide guides outside `docs/`, rendered from Markdown at build time.

### Running it locally

```bash
# from the repository root
npm install
npm run dev          # or: npm run site:dev
# http://localhost:5173
```

Or from this package:

```bash
cd docs/website
npm install
npm run dev
```

### Navigating the site

- The **topbar** switches between the design hub (logo/brand) and the documentation portal (**Documentation**).
- The **sidebar** groups sections from `mkdocs.yml` + `scripts/generate-nav.mjs` `EXTRA_SECTIONS`.
- **⌘K / Ctrl+K** fuzzy-searches page titles and source paths.
- Doc pages include an **"On this page"** TOC, **prev/next** links, and **Edit on GitHub**.
- **☀️/🌙** theme toggle (persisted in `localStorage`).

### Adding content

- **New docs page:** add the Markdown under `docs/` and list it in [`docs/mkdocs.yml`](../mkdocs.yml) `nav:`. Run `npm run site:nav` (or any `dev`/`build`) to regenerate the nav.
- **Repo-wide guide outside `docs/`:** add `{ title, source }` under `EXTRA_SECTIONS` in [`scripts/generate-nav.mjs`](scripts/generate-nav.mjs).
- **New design-hub panel:** add a SFC under `src/frameworks/vue/components/hub/`, then register it in `src/views/HomeView.vue`.

## How the app is built

| Path | Role |
| --- | --- |
| `index.html` | Entry HTML + GitHub Pages SPA redirect restore script |
| `public/404.html` | SPA fallback for deep links on GitHub Pages |
| `vite.config.ts` | `SITE_BASE`, `server.fs.allow` for repo-root Markdown |
| `scripts/generate-nav.mjs` | Builds `src/nav.generated.ts` from `mkdocs.yml` + extras |
| `src/main.ts` | App bootstrap |
| `src/router.ts` | Routes: `/` hub, catch-all docs |
| `src/views/` | `HomeView` (hub) and `DocPage` (Markdown portal) |
| `src/styles/` | Theme, markdown, hub CSS |
| `src/composables/` | Docs loading, Markdown pipeline, theme |
| `src/frameworks/vue/App.vue` | Shell layout wrapper (topbar / sidebar) |
| `src/frameworks/vue/components/` | Shell chrome + `hub/` interactive panels |

### Build / deploy

```bash
npm run build                 # from repo root workspace
# or
cd docs/website && npm run build

SITE_BASE=/Project-Mobile-Fortress/ npm run build   # production subpath
```

Production CI (`.github/workflows/docs.yml`) runs `npm ci && npm run build --workspace docs/website` and publishes `docs/website/dist/` to `gh-pages`.

### Project layout

```
docs/website/
├── index.html
├── public/
├── vite.config.ts
├── scripts/generate-nav.mjs
└── src/
    ├── main.ts
    ├── router.ts
    ├── nav.generated.ts       # AUTO-GENERATED
    ├── views/
    ├── styles/
    ├── composables/
    └── frameworks/
        └── vue/
            ├── App.vue          # shell wrapper
            └── components/
                ├── Sidebar.vue, SearchBox.vue, ThemeToggle.vue, …
                └── hub/         # design-hub panels
```

### Notable implementation notes

- **`nav.generated.ts` is not hand-edited** — regenerated on every `predev` / `prebuild`.
- **`useDocs.ts` lives under `docs/`**, so `import.meta.glob` keys collapse one `docs/` segment for in-docs sources; `resolveKey()` handles that (see comments in the file). If you change nesting depth, re-verify the glob.
- **Two documentation front-ends** share `mkdocs.yml` nav: this Vue site and optional `mkdocs serve`.
