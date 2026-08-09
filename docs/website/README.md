# docs/website/

Vite + Vue 3 + TypeScript documentation portal and interactive design hub for **Project Mobile Fortress**. Deployed to GitHub Pages from the `gh-pages` branch by [`.github/workflows/docs.yml`](../../.github/workflows/docs.yml).

This package lives at `docs/website/` (not a nested `vue/` subfolder). Shared modules (`styles/`, `composables/`, `configs/`, `stories/`, etc.) sit under `src/`; Vue host UI (`components/`, `views/`, `directives/`) and the shell live under `src/frameworks/vue/`.

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
- **New design-hub panel:** add a SFC under `src/frameworks/vue/components/hub/`, then register it in `src/frameworks/vue/views/HomeView.vue`.
- **Lore / stories:** add entries under `src/stories/` and export them from `src/stories/index.ts`.

## How the app is built

| Path | Role |
| --- | --- |
| `index.html` | Entry HTML + GitHub Pages SPA redirect restore script |
| `public/404.html` | SPA fallback for deep links on GitHub Pages |
| `vite.config.ts` | `SITE_BASE`, `server.fs.allow` for repo-root Markdown |
| `postcss.config.js` | Tailwind + Autoprefixer |
| `tailwind.config.js` | Content globs for Vue/Astro; dark mode via `[data-theme="dark"]` |
| `scripts/generate-nav.mjs` | Builds `src/nav.generated.ts` from `mkdocs.yml` + extras |
| `src/main.ts` | App bootstrap (+ Vuex + custom directives) |
| `src/router.ts` | Routes: `/` hub, catch-all docs |
| `src/styles/` | Theme, markdown, hub CSS |
| `src/composables/` | Docs loading, Markdown pipeline, theme |
| `src/configs/`, `constants/`, `enums/` | Hub tunables, fortress constants, shared enums |
| `src/hooks/` | Vue composition hooks (e.g. reduced-motion) |
| `src/interfaces/`, `utils/` | Shared types and helpers |
| `src/graphql/` | Docs/content GraphQL schema + fragments (MFP8+) |
| `src/simulations/` | Framework-neutral hub simulation demos |
| `src/stories/` | Game lore catalog for the design hub / docs |
| `src/frameworks/vue/App.vue` | Shell layout wrapper (topbar / sidebar) |
| `src/frameworks/vue/views/` | `HomeView` (hub) and `DocPage` (Markdown portal) |
| `src/frameworks/vue/directives/` | Custom Vue directives (`v-click-outside`, `v-focus`, `v-intersect`) |
| `src/frameworks/vue/components/` | Shell chrome + `hub/` interactive panels |
| `src/frameworks/astro/` | Astro island sources (`CoastalFlowField.astro`) + Vue iframe wrapper |
| `public/astro-island/` | Prebuilt Astro static island (from `npm run build:astro`) |
| `src/libraries/form/` | TanStack Form (`@tanstack/vue-form`) helper |
| `src/libraries/motion/` | Framer Motion variants / re-exports |
| `src/libraries/router/` | Vue Router factory (`createAppRouter`) |
| `src/libraries/vuex/` | Vuex store (actions/mutations/state/store), Redux-shaped layout |
| `nuxt.config.ts` | Re-exports `stack/nuxt/nuxt.config.ts` (like `eslint.config.js`) |

### Build / deploy

```bash
npm run build                 # from repo root workspace
# or
cd docs/website && npm run build

# Astro island only (also runs automatically on prebuild):
npm run build:astro

SITE_BASE=/Project-Mobile-Fortress/ npm run build   # production subpath
```

Production CI (`.github/workflows/docs.yml`) runs `npm ci && npm run build --workspace docs/website` and publishes `docs/website/dist/` to `gh-pages`. `prebuild` regenerates nav and builds the Astro island into `public/astro-island/` so the home hub iframe has content.

### Project layout

```
docs/website/
├── index.html
├── eslint.config.js           # re-export → stack/eslint
├── nuxt.config.ts             # re-export → stack/nuxt
├── astro.config.mjs           # Astro island → public/astro-island
├── public/
│   └── astro-island/          # built CoastalFlowField island
├── stack/
│   ├── eslint/
│   └── nuxt/                  # Nuxt config only (not a full website copy)
├── vite.config.ts
├── scripts/generate-nav.mjs
└── src/
    ├── main.ts
    ├── router.ts
    ├── nav.generated.ts       # AUTO-GENERATED
    ├── styles/
    ├── composables/
    ├── configs/, constants/, enums/
    ├── hooks/, interfaces/, utils/
    ├── graphql/, simulations/
    ├── stories/               # game lore
    ├── libraries/
    │   ├── form/, motion/, router/, vuex/
    └── frameworks/
        ├── vue/
        │   ├── App.vue
        │   ├── views/           # HomeView, DocPage
        │   ├── directives/      # click-outside, focus, intersect
        │   └── components/
        │       ├── Sidebar.vue, SearchBox.vue, ThemeToggle.vue, …
        │       └── hub/
        └── astro/
            ├── CoastalFlowField.astro
            ├── pages/index.astro
            └── components/CoastalFlowFieldWrapper.vue
```

### Notable implementation notes

- **`nav.generated.ts` is not hand-edited** — regenerated on every `predev` / `prebuild`.
- **`useDocs.ts` lives under `docs/`**, so `import.meta.glob` keys collapse one `docs/` segment for in-docs sources; `resolveKey()` handles that (see comments in the file). If you change nesting depth, re-verify the glob.
- **Two documentation front-ends** share `mkdocs.yml` nav: this Vue site and optional `mkdocs serve`.
- **Custom directives** live under `src/frameworks/vue/directives/` and register via `directivesPlugin` in `main.ts`.
- **Astro island** is a real static design visual (land/sea raid-lane flow field), not a placeholder — rebuild with `npm run build:astro` when you change `src/frameworks/astro/**`.
- **`src/stories/`** holds structured lore (Wōkòu crisis, fortress network, allied civilizations) for hub/docs surfaces.

## Tooling packages (`stack/`)

| Directory | Role |
| --- | --- |
| [`stack/eslint/`](stack/eslint/) | ESLint flat config; root `eslint.config.js` re-exports it |
| [`stack/nuxt/`](stack/nuxt/) | Nuxt 3 config; root `nuxt.config.ts` re-exports it (Vue analogue of `stack/next`) |

```bash
npm run lint                 # ESLint via stack/eslint/eslint.config.js

# Nuxt surface (workspace scripts from repo root, or from this package):
npm run nuxt:prepare
npm run nuxt:dev
npm run nuxt:generate
```

## Tests

Shared harness under [`test/`](test/):

| Path | Role |
| --- | --- |
| `test/unit/` | Components + utils (Vitest) |
| `test/integration/` | Integration tests + MSW `mocks/` |
| `test/cypress/e2e/` | End-to-end browser flows |
| `test/cypress/smoke/` | Fast smoke specs |

```bash
npm test
npm run test:unit
npm run test:integration
npm run dev   # terminal 1
npm run cypress:smoke   # terminal 2
```

