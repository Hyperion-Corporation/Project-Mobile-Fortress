# docs/website/

Vite + React 19 + TypeScript documentation portal and interactive design hub for **Project Mobile Fortress**. Deployed to GitHub Pages from the `gh-pages` branch by [`.github/workflows/docs.yml`](../../.github/workflows/docs.yml).

This package lives at `docs/website/` (not a nested `react/` subfolder). Shared modules (`styles/`, `hooks/`, `configs/`, `stories/`, etc.) sit under `src/`; React host UI (`components/`, `views/`) and the shell live under `src/frameworks/react/`.

## What the site is

A single SPA that combines:

1. **Design hub** (`/`) — interactive panels (design, tech, audio, production, QA) implemented as React components.
2. **Documentation portal** (`/docs/...` and other nav routes) — every page in [`docs/mkdocs.yml`](../mkdocs.yml)'s `nav:` tree, plus a curated list of repo-wide guides outside `docs/`, rendered from Markdown at build time.
3. **Framework islands** — this site's own chrome is React, but it embeds three more frameworks on the hub page, each mounting real functionality (not a placeholder): a live **Aurelia 2** island (`ConvergenceChart`, an HQ-layout GA convergence visualization driven by `src/simulations/`), an **Apollo/GraphQL** island (`ApolloLorePanel`, querying `src/graphql/schema.graphql`'s real docs/content graph), and an **Astro** island (`CoastalFlowField`, a static raid-lane flow field). The React island (`UnitRosterBoard`, a filterable browser over the real unit roster in `src/constants/fortress.ts`) is mounted natively, and documented in isolation via **Storybook**. See [`APP.md`](APP.md) for the rationale.

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
- **☀️/🌙** theme toggle (persisted in `localStorage`, Redux-owned — see `src/libraries/redux/`).

### Adding content

- **New docs page:** add the Markdown under `docs/` and list it in [`docs/mkdocs.yml`](../mkdocs.yml) `nav:`. Run `npm run site:nav` (or any `dev`/`build`) to regenerate the nav.
- **Repo-wide guide outside `docs/`:** add `{ title, source }` under `EXTRA_SECTIONS` in [`scripts/generate-nav.mjs`](scripts/generate-nav.mjs).
- **New design-hub panel:** add a component under `src/frameworks/react/components/hub/`, then register it in `src/frameworks/react/views/HomeView.tsx`.
- **Lore / stories:** add entries under `src/stories/` and export them from `src/stories/index.ts`.
- **New Storybook story:** add a `*.stories.tsx` under `stories/`, importing the real component from `src/frameworks/react/` (no copies).

## How the app is built

| Path | Role |
| --- | --- |
| `index.html` | Entry HTML + GitHub Pages SPA redirect restore script |
| `public/404.html` | SPA fallback for deep links on GitHub Pages |
| `vite.config.ts` | `SITE_BASE`, React plugin, `server.fs.allow` for repo-root Markdown |
| `postcss.config.js` | Tailwind + Autoprefixer |
| `tailwind.config.js` | Content globs for React/Astro; dark mode via `[data-theme="dark"]`; preflight deliberately left on the default (see `src/styles/tailwind.css`) |
| `scripts/generate-nav.mjs` | Builds `src/nav.generated.ts` from `mkdocs.yml` + extras |
| `scripts/fix-api-links.mjs` | Rewrites TypeDoc's relative markdown links into router-absolute paths after `gen:api` |
| `typedoc.json` | TypeDoc + `typedoc-plugin-markdown` config → `docs/api/typescript/` (from `src/simulations/`) |
| `.storybook/` | Storybook (`@storybook/react-vite`) → `public/storybook/`, documenting `src/frameworks/react/*` |
| `src/main.tsx` | App bootstrap (Redux provider, router provider, Tailwind/theme CSS) |
| `src/router.tsx` | Routes: `/` hub, catch-all docs |
| `src/styles/` | Tailwind entry, theme, markdown, hub CSS |
| `src/hooks/` | Docs loading, Markdown pipeline, theme (Redux-backed), click-outside/focus/intersect, reduced-motion |
| `src/configs/`, `constants/`, `enums/` | Hub tunables, fortress constants, shared enums |
| `src/interfaces/`, `utils/` | Shared types and helpers |
| `src/graphql/` | Docs/content GraphQL schema + fragments (MFP8+), queried by `src/frameworks/apollo/` |
| `src/simulations/` | Framework-neutral hub simulation demos; also this site's own TypeDoc target |
| `src/stories/` | Game lore catalog for the design hub / docs |
| `src/frameworks/react/App.tsx` | Shell layout wrapper (topbar / sidebar) |
| `src/frameworks/react/views/` | `HomeView` (hub) and `DocPage` (Markdown portal) |
| `src/frameworks/react/components/` | Shell chrome + `hub/` interactive panels |
| `src/frameworks/apollo/` | Apollo/GraphQL island — `client.ts`, `queries.ts`, `data.ts`, `ApolloLorePanel.tsx` |
| `src/frameworks/astro/` | Astro island sources (`CoastalFlowField.astro`) + React iframe wrapper |
| `src/frameworks/aurelia/` | `convergence-chart-app.ts` custom element + `mount.ts` + React wrapper |
| `src/frameworks/shared/` | Framework-neutral island lifecycle logging |
| `public/astro-island/` | Prebuilt Astro static island (from `npm run build:astro`) |
| `public/storybook/` | Prebuilt Storybook static site (from `npm run build-storybook`) |
| `src/libraries/form/` | TanStack Form (`@tanstack/react-form`) helper |
| `src/libraries/motion/` | Framer Motion variants / re-exports |
| `src/libraries/router/` | React Router factory (`createAppRouter`) |
| `src/libraries/redux/` | Redux store (actions/reducers/state/store) |
| `next.config.js` / `eslint.config.js` | Re-exports from `stack/{next,eslint}/` |

### Build / deploy

```bash
npm run build                 # from repo root workspace
# or
cd docs/website && npm run build

# Astro island only (also runs automatically on prebuild):
npm run build:astro

SITE_BASE=/Project-Mobile-Fortress/ npm run build   # production subpath
```

Production CI (`.github/workflows/docs.yml`) runs `npm ci && npm run build --workspace docs/website` and publishes `docs/website/dist/` to `gh-pages`. `prebuild` regenerates the nav, generates the TypeScript API reference (TypeDoc), builds the Astro island into `public/astro-island/`, and builds the Storybook static site into `public/storybook/` — all before `vite build` runs.

### Project layout

```
docs/website/
├── index.html
├── eslint.config.js / next.config.js   # re-export → stack/
├── typedoc.json                # → docs/api/typescript/
├── astro.config.mjs            # Astro island → public/astro-island
├── .storybook/                 # → public/storybook
├── stories/                    # Storybook stories for src/frameworks/react/*
├── public/
│   ├── astro-island/           # built CoastalFlowField island
│   └── storybook/              # built Storybook site
├── stack/
│   ├── eslint/, next/
├── vite.config.ts
├── scripts/{generate-nav,fix-api-links}.mjs
└── src/
    ├── main.tsx
    ├── router.tsx
    ├── nav.generated.ts       # AUTO-GENERATED
    ├── styles/                # tailwind.css entry + theme/markdown/hub CSS
    ├── hooks/
    ├── configs/, constants/, enums/
    ├── interfaces/, utils/
    ├── graphql/, simulations/
    ├── stories/               # game lore
    ├── libraries/
    │   ├── form/, motion/, router/, redux/
    └── frameworks/
        ├── react/     (primary — App.tsx, views/, components/)
        │   └── components/
        │       ├── Sidebar.tsx, SearchBox.tsx, ThemeToggle.tsx, …
        │       └── hub/
        ├── apollo/    (island — client.ts, queries.ts, ApolloLorePanel.tsx)
        ├── astro/     (island — CoastalFlowField.astro)
        ├── aurelia/   (island — convergence-chart-app.ts)
        └── shared/    (framework-neutral helpers)
```

### Notable implementation notes

- **`nav.generated.ts` is not hand-edited** — regenerated on every `predev` / `prebuild`.
- **`useDocs.ts` lives under `src/hooks/`**, so `import.meta.glob` keys collapse one `docs/` segment for in-docs sources; `resolveKey()` handles that (see comments in the file). If you change nesting depth, re-verify the glob.
- **Theme, active hub tab, and search-open state are Redux-owned** (`src/libraries/redux/`) rather than component-local — `src/hooks/useTheme.ts` wraps `useAppSelector`/`useAppDispatch`.
- **Astro island** is a real static design visual (land/sea raid-lane flow field), not a placeholder — rebuild with `npm run build:astro` when you change `src/frameworks/astro/**`.
- **`src/stories/`** holds structured lore (Wōkòu crisis, fortress network, allied civilizations) for hub/docs surfaces — not to be confused with `stories/` (root), which holds Storybook stories for `src/frameworks/react/*`. It's also the Apollo island's mock data source.
- **`src/frameworks/react/UnitRosterBoard.tsx`** reads `src/constants/fortress.ts` directly (no copy) — the same data the design docs and `src/stories/` draw from.
- **`src/frameworks/apollo/client.ts`** resolves `src/graphql/schema.graphql`'s Query fields locally (no live backend yet) against real repo data — see [`APP.md`](APP.md).
- **Tailwind's `base` layer (preflight) is deliberately not enabled** — `src/styles/tailwind.css` only pulls in `components`/`utilities` so the hub panels' existing Tailwind classes finally generate CSS, without also flipping on a sitewide reset that was never reviewed for visual impact.

## Tooling packages (`stack/`)

| Directory | Role |
| --- | --- |
| [`stack/eslint/`](stack/eslint/) | ESLint flat config; root `eslint.config.js` re-exports it |
| [`stack/next/`](stack/next/) | Alternate Next.js surface over `src/frameworks/react/`; root `next.config.js` re-exports it |

```bash
npm run lint                 # ESLint via stack/eslint/eslint.config.js

npm run next:dev
```

## Tests

Shared harness under [`test/`](test/):

| Path | Role |
| --- | --- |
| `test/unit/` | Components + utils (Vitest + React Testing Library) |
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
