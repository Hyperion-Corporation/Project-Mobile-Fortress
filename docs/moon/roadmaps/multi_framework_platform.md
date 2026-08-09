# Multi-Framework Platform Roadmap (Docs Site + Hybrid UI)

**IDs:** MFP1–MFP16 · **Status:** 🔄 React host foundation (migrated from Vue) · **Evidence base:** [`Hybrid Micro-Frontend Architecture Research.md`](../research/Hybrid%20Micro-Frontend%20Architecture%20Research.md), [`Hybrid Vue React Architecture.md`](../research/Hybrid%20Vue%20React%20Architecture.md), [`Vue 3 Visualization Stack Research.md`](../research/Vue%203%20Visualization%20Stack%20Research.md), [`WASM Micro-Frontend Integration Research.md`](../research/WASM%20Micro-Frontend%20Integration%20Research.md)

Goal: evolve the **React 19 + Vite documentation portal** (`docs/website/`) into a controlled polyglot shell where React owns navigation, Markdown docs, and hub chrome; specialized visualization/interop islands live alongside it (**Aurelia**, **Astro**, and now **Apollo/GraphQL**); and **WASM** (aligned with the planned C++ core story) accelerates heavy client-side work—without breaking static GitHub Pages deploy, accessibility, or Web Vitals.

> **2026-08-09 update:** the site originally shipped Vue 3 as the host framework (see Document history below for the superseded baseline). It has since been migrated to a React 19 host — see [`docs/website/APP.md`](../../website/APP.md) for the rationale. This roadmap's IDs/deliverables are reinterpreted against the React host below rather than rewritten wholesale; MFP1–MFP4's "Vue host + React island" framing is now moot since React *is* the host, and MFP8–MFP11's GraphQL/Apollo work has landed as a real (client-resolved) island rather than remaining a future milestone.

## Current codebase baseline (2026-08-09, post-React-migration)

| Layer | Path / state | Notes |
| --- | --- | --- |
| React host | `docs/website/` package; `src/main.tsx` + `src/styles` + `src/frameworks/react/{views,components}` | Design hub + docs portal; lore in `src/stories/`; shared modules under configs/constants/enums/hooks/…; state via `src/libraries/redux/` (replaces the former Vuex store) |
| React (islands) | `src/frameworks/react/UnitRosterBoard.tsx` | Mounted natively in the host (no longer a foreign-root island now that the host itself is React); documented in isolation via Storybook |
| Astro | `src/frameworks/astro/CoastalFlowField.astro` + React iframe wrapper (`CoastalFlowFieldWrapper.tsx`); `npm run build:astro` → `public/astro-island/` | Seeded coastal raid-lane flow field (MFP5 foundation) — unchanged by the host migration beyond its wrapper's host framework |
| Aurelia | `src/frameworks/aurelia/convergence-chart-app.ts` + `mount.ts` + React wrapper (`ConvergenceChartWrapper.tsx`) | **Delivered** (MFP6) — HQ-layout GA convergence chart, visualizes `src/simulations/` |
| GraphQL / Apollo | `src/frameworks/apollo/{client,queries,data}.ts` + `ApolloLorePanel.tsx`; schema at `src/graphql/schema.graphql` | **Delivered** (MFP8, MFP9, MFP11 — client-resolved, no live server) — real `@apollo/client` `useQuery` calls against real schema fields, resolved locally from `src/stories/` lore + a curated outpost/raid-lane layout |
| WASM | — | **Not present** in website; shared **C++** core planned for game clients ([`shared_core.md`](shared_core.md)) |
| Game clients | `android/`, `ios/`, `core/` | Native TD game — multi-framework work here targets the **docs/website** surface unless noted |
| Deploy | `.github/workflows/docs.yml` → `docs/website/dist` | Static SPA on `gh-pages`; no runtime API |

## Deliverable index

| ID | Deliverable | Effort | Depends on | Status |
| --- | --- | --- | --- | --- |
| MFP1 | Document host/island contract: React host, Aurelia/Astro/Apollo islands, directory layout under `docs/website/src/frameworks/*`, ADR (no heavy federation default) | S | — | ✅ host is now React; contract documented in `APP.md`/`README.md` |
| MFP2 | Vite multi-framework blueprint: React plugin covers the full host, Astro/Aurelia packaging, singleton load strategy for islands | L | MFP1 | ✅ `vite.config.ts` — single `react()` plugin, no dual-framework split needed post-migration |
| MFP3 | React island host utilities: dynamic mount of foreign roots (Aurelia, Astro iframe), layout reservation, error fallback, visibility/intent load, unmount cleanup | M | MFP1 | ✅ `useIntersect`/`useClickOutside`/`useFocusWhen` hooks + `ConvergenceChartWrapper.tsx`/`CoastalFlowFieldWrapper.tsx` |
| MFP4 | ~~React island path~~ — superseded: React is now the host itself, not a mounted island. `UnitRosterBoard.tsx` is used natively in `HomeView.tsx`. R3F/3D demo work remains open. | L | MFP2, MFP3 | 🔁 reframed — no foreign-root React mount needed; 3D/R3F demo still ⬜ |
| MFP5 | Astro tertiary island (optional): prebuilt static island or content component consumed by host | M | MFP1, MFP3 | 🔄 CoastalFlowField island + React wrapper |
| MFP6 | Aurelia tertiary island (optional): host element + DI bootstrap, strict stop on unmount | M | MFP3 | ✅ `convergence-chart-app.ts` + `mount.ts` + React wrapper, visualizes `src/simulations/` |
| MFP7 | Cross-framework parity kit: one visitor question (e.g. design-hub metric) in React + a second framework with shared a11y summary | M | MFP4 | ✅ `src/simulations/summary.ts`'s `convergenceSummary()` — one `role="status"` region in React (`ConvergenceStatus.tsx`) and one in the Aurelia island (`convergence-chart-app.ts`'s `statusSummary` getter), both deriving from the same GA-convergence run |
| MFP8 | GraphQL schema v1 for **docs/content graph** (design docs, roadmaps, research nodes, hub panel state entities) | M | DOC model | ✅ `src/graphql/schema.graphql` — `Outpost`/`RaidLane`/`LoreStory` query fields |
| MFP9 | Apollo Client singleton (framework-agnostic core under `docs/website/src/frameworks/apollo`) | M | MFP8 | ✅ `src/frameworks/apollo/client.ts` |
| MFP10 | Framework Apollo adapters: React hooks (`useQuery`); optional Aurelia DI | L | MFP9, MFP4 | 🔄 React (`ApolloLorePanel.tsx`) delivered; Aurelia adapter not attempted |
| MFP11 | Static-export GraphQL strategy: build-time fixtures / MSW; no required live endpoint on `gh-pages` | M | MFP8, MFP9 | ✅ `client.ts`'s local `ApolloLink` resolves schema fields from repo data — no live endpoint |
| MFP12 | WASM toolchain for website compute demos (`wasm-pack`/C++/AssemblyScript), loader module, CI artifact check | L | MFP2 | ⬜ |
| MFP13 | WASM worker for hub/sim demos (flow-field, GA layout, audio DSP slice) with pure-JS fallback and cancel | L | MFP12 | ⬜ |
| MFP14 | Bridge narrative: document how website WASM demos relate to future **C++ `core/`** simulation (shared concepts, not shared binary yet) | M | MFP13, shared_core | 🔬 |
| MFP15 | Test matrix: unit mount/unmount, cache broadcast, Cypress/docs smoke, per-island budgets | L | MFP4, MFP10, MFP13 | 🔄 directive/hook unit tests ported to React Testing Library; cache broadcast (`test/unit/apollo/cache-broadcast.test.ts`) and per-island gzip budgets (`scripts/check-island-budgets.mjs`, wired into `postbuild`) now ✅; Cypress/docs smoke beyond the ad hoc real-browser checks done while fixing the `stack/next/` surface still ⬜ as a committed spec |
| MFP16 | Authoring guide: when host vs foreign-root island vs WASM; teardown rules; ADR links | M | MFP7, MFP11, MFP15 | ⬜ |

## Architecture principles (PMF-specific)

1. **React is the host** for the documentation website (navigation, Markdown portal, design hub chrome)—not Vue/Nuxt. (Superseded principle: this site originally ran Vue as host; see Document history.)
2. **Aurelia and Astro are specialized islands**, not second full apps: mounted into React-owned host nodes for a self-contained visualization/interop demo each (GA convergence chart; static flow-field diagram).
3. **Prefer lightweight mounting** over Single-SPA / Module Federation by default (research notes federation build cost and App Router/webpack pain; this site is Vite-static).
4. **One shared data graph** when cross-island entities exist: Apollo `InMemoryCache` is now live for the docs/content graph (`src/frameworks/apollo/`); UI state that isn't GraphQL-shaped (theme, active hub tab, search-open) lives in `src/libraries/redux/` instead of a second copy.
5. **WebGL lifecycle is hostile to naive remounts.** Prefer canvas pooling / single persistent canvas if/when a 3D (R3F) island lands (per Hybrid Vue React research — still applicable to a React host).
6. **WASM is opt-in acceleration** for hub demos and later game-adjacent tools; pure JS remains the reduced path.
7. **Static GitHub Pages remains the product constraint** for the website: no required runtime GraphQL server — confirmed by the Apollo island's local-resolver design (MFP11).
8. **Game clients stay native.** Multi-framework work does not replace Kotlin/Swift/C++ game architecture; it extends the **docs/website** and optional tooling UIs.

## Target directory layout (website package, current)

```text
docs/website/
  eslint.config.js               # re-export → stack/eslint
  next.config.js                 # re-export → stack/next
  stack/
    eslint/
    next/                        # Next.js config only (not a full SPA copy)
  src/
    main.tsx                     # bootstrap
    router.tsx, nav.generated.ts
    styles/                      # theme, markdown, hub
    hooks/                       # docs/markdown/theme/click-outside/focus/intersect helpers
    configs/, constants/, enums/
    interfaces/, utils/
    graphql/                     # schema + fragments (consumed by frameworks/apollo/, MFP8+)
    simulations/                 # framework-neutral hub demos
    stories/                     # game lore catalog (also the Apollo island's mock data source)
    frameworks/
      react/                     # HOST — components, views
        App.tsx
        views/                   # HomeView, DocPage
        components/              # shell chrome + hub/
        UnitRosterBoard.tsx      # native component, not a mounted island
      apollo/                    # MFP8–MFP11 — client.ts, queries.ts, data.ts, ApolloLorePanel.tsx
      astro/                     # MFP5 — .astro sources + React wrappers
        CoastalFlowField.astro
        components/              # CoastalFlowFieldWrapper.tsx (iframe host)
        pages/                   # island entry (index.astro)
      aurelia/                   # MFP6 — convergence-chart-app.ts, mount.ts, React wrapper
      shared/                    # mount helpers, types (no framework imports)
    libraries/
      redux/                     # UI state store (theme, active hub tab, search-open)
      router/                    # React Router factory
      form/                      # TanStack Form helper
      wasm/                      # loaders + bindings (MFP12, not yet present)
  public/
    astro-island/                # `astro build` output (iframe target)
```

## Work packages

### MFP1–MFP3 — Host contract

`docs/website/src/frameworks/react` is now the host application (migrated from the original `frameworks/vue`). Island mount protocol for foreign-root frameworks (Aurelia) uses `useEffect` mount/cleanup instead of Vue's `onMounted`/`onBeforeUnmount`; the Astro island stays an iframe embed (no mount protocol needed, just `useIntersect` for lazy load). Federation remains rejected unless a multi-deploy Multi-Zone need appears.

### MFP4–MFP7 — Foreign islands

**React (MFP4) — superseded.** React is the host itself now, so there's no "mount React into a foreign host" step left to do; `UnitRosterBoard.tsx` is a native component in `HomeView.tsx`. A future R3F/3D demo would mount *inside* the React tree directly (no `createRoot`/foreign-root dance needed), but that demo itself hasn't been built yet.

**Astro (MFP5).** `CoastalFlowField.astro` is a real design-hub island (deterministic land/sea raid-lane vectors toward the citadel). Build with `npm run build:astro` (also runs on `prebuild`) into `public/astro-island/`; the React host embeds it via `CoastalFlowFieldWrapper.tsx` (iframe + `BASE_URL`). Further promotion: typed props bridge, `client:visible` hydration experiments, and budget checks.

**Aurelia (MFP6) — delivered.** `convergence-chart-app.ts` (a real Aurelia 2 custom element) + `mount.ts` (`Aurelia.app({ host, component }).start()`) + `ConvergenceChartWrapper.tsx` (React host, mounts/unmounts via `useEffect`). Visualizes `src/simulations/`'s HQ-layout GA convergence data.

### MFP8–MFP11 — GraphQL + Apollo

Schema describes **documentation and hub entities**, not live game servers — delivered as `src/graphql/schema.graphql`'s `Outpost`/`RaidLane`/`LoreStory` types. Transport is a local `ApolloLink` (`src/frameworks/apollo/client.ts`) resolving those fields against real repo data (`src/stories/` lore, a curated outpost/raid-lane layout) rather than checked-in JSON fixtures or MSW — same end result (no live endpoint required on `gh-pages`) via a slightly different mechanism than originally scoped. `ApolloLorePanel.tsx` is the React consumer (`useQuery`); an Aurelia DI adapter (MFP10) was not attempted, since the Aurelia island doesn't currently need docs/content-graph data.

### MFP12–MFP14 — WASM

Website WASM demos should teach flow-field / layout / audio ideas from the design hub without pretending to be the authoritative multiplayer simulation. Link conceptually to [`shared_core.md`](shared_core.md) C++ plans; do not block game milestones on website WASM.

### MFP15–MFP16 — Quality and docs

Per-island gzip budgets; ten mount/unmount leak probes; Cypress smoke that host docs still work when islands fail to load.

## Testing plan

| Layer | Proof |
| --- | --- |
| Unit | Vue host helpers; React mount/unmount; Apollo cache write→read; WASM load failure |
| Integration | Island open does not break doc router; theme toggle still works |
| E2E/smoke | `/` hub + one doc route; no uncaught errors when island disabled |
| Perf | LCP of docs routes unchanged when islands closed; INP when opening React island |
| GPU | Route thrash does not leak WebGL contexts (canvas pool when MFP4 ships 3D) |

## Performance budgets (website)

| Budget | Target |
| --- | --- |
| Docs route JS (islands closed) | No regression vs pre-MFP baseline (±5%) |
| First foreign island open | ≤ 300 kB gzip additional vendor for that island |
| Dual-runtime concurrent islands | Prefer exclusive mode if INP > 200 ms |
| WASM module | Progress UI if > 1 MB; never block first docs paint |

## Risks

| Risk | Mitigation |
| --- | --- |
| Dual Vue+React payload | Lazy islands; chunk splitting; one heavy island per route |
| WebGL context loss on route change | Canvas pooling; dispose R3F resources |
| Federation complexity | Not default; document rejection in ADR |
| GraphQL live dependency | Fixtures only on Pages |
| Scope bleed into game clients | MFP issues labeled `website`; game remains `android`/`ios`/`core` |

## Research mapping

| Research doc | Primary IDs |
| --- | --- |
| Hybrid Vue React Architecture | MFP1–MFP4, MFP7, canvas pooling |
| Hybrid Micro-Frontend Architecture | MFP2, MFP5–MFP6, host choice (Vue) |
| Vue 3 Visualization Stack | MFP4 viz library choices, worker offload |
| WASM Micro-Frontend Integration | MFP9–MFP14 (adapt federation claims to Vite-static reality) |

## Exit gates

- **MF-G1:** Documented host contract; site still deploys to `gh-pages`. ✅ (host contract now React-based; deploy pipeline unchanged)
- **MF-G2:** React island demo with leak-safe unmount and budget evidence. 🔁 reframed — no React foreign-root island applicable post-migration; Aurelia's leak-safe unmount (`useEffect` cleanup calling `au.stop(true)`) is the closest equivalent, delivered.
- **MF-G3:** GraphQL schema + Apollo fixtures offline. ✅ delivered via `src/frameworks/apollo/` (schema-shaped local resolver, no live endpoint).
- **MF-G4:** WASM worker demo with JS fallback. ⬜ not started.

## Document history

| Date | Revision | Change |
| --- | --- | --- |
| 2026-08-09 | R1 | Initial PMF multi-framework roadmap after `docs/website` flatten + `src/frameworks/vue` layout. |
| 2026-08-09 | R2 | Updated after migrating the docs site's host framework from Vue 3 to React 19, replacing Vuex with Redux (`src/libraries/redux/`), and delivering the Apollo/GraphQL island (MFP8, MFP9, MFP11) against `src/graphql/schema.graphql`. MFP4 and MF-G2 reframed since React is now the host rather than a mounted island; MFP1–MFP3, MFP6 status updated to reflect delivered work. See [`docs/website/APP.md`](../../website/APP.md) for the full rationale. |
| 2026-08-09 | R3 | Delivered MFP7 (cross-framework a11y parity kit — `src/simulations/summary.ts` shared by React's `ConvergenceStatus.tsx` and the Aurelia island's `statusSummary` getter) and the remainder of MFP15 (Apollo `InMemoryCache` broadcast test; `scripts/check-island-budgets.mjs` per-island gzip budget check wired into `postbuild`). Also wired this roadmap into `docs/mkdocs.yml`'s Roadmap nav section (it existed on disk but wasn't linked from the docs site sidebar). |
