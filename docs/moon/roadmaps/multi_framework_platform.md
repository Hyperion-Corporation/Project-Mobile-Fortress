# Multi-Framework Platform Roadmap (Docs Site + Hybrid UI)

**IDs:** MFP1–MFP16 · **Status:** 🔄 Vue host foundation · **Evidence base:** [`Hybrid Micro-Frontend Architecture Research.md`](../research/Hybrid%20Micro-Frontend%20Architecture%20Research.md), [`Hybrid Vue React Architecture.md`](../research/Hybrid%20Vue%20React%20Architecture.md), [`Vue 3 Visualization Stack Research.md`](../research/Vue%203%20Visualization%20Stack%20Research.md), [`WASM Micro-Frontend Integration Research.md`](../research/WASM%20Micro-Frontend%20Integration%20Research.md)

Goal: evolve the **Vue 3 + Vite documentation portal** (`docs/website/`) into a controlled polyglot shell where Vue owns navigation, Markdown docs, and hub chrome; **React** powers specialized 3D/visualization islands (e.g. R3F); **Astro** and **Aurelia** may appear as tertiary islands; **GraphQL + Apollo** provide a shared entity cache; and **WASM** (aligned with the planned C++ core story) accelerates heavy client-side work—without breaking static GitHub Pages deploy, accessibility, or Web Vitals.

## Current codebase baseline (2026-08-09)

| Layer | Path / state | Notes |
| --- | --- | --- |
| Vue host | `docs/website/` package; `src/main.ts` + `src/views` + `src/styles` | Design hub + docs portal; components under `src/frameworks/vue/components` |
| React | — | **Not present** in the website package (research: R3F for 3D modules) |
| Astro | — | **Not present** |
| Aurelia | — | **Not present** |
| GraphQL / Apollo | — | **Not present** |
| WASM | — | **Not present** in website; shared **C++** core planned for game clients ([`shared_core.md`](shared_core.md)) |
| Game clients | `android/`, `ios/`, `core/` | Native TD game — multi-framework work here targets the **docs/website** surface unless noted |
| Deploy | `.github/workflows/docs.yml` → `docs/website/dist` | Static SPA on `gh-pages`; no runtime API |

## Deliverable index

| ID | Deliverable | Effort | Depends on | Status |
| --- | --- | --- | --- | --- |
| MFP1 | Document host/island contract: Vue host, React/Astro/Aurelia islands, directory layout under `docs/website/src/frameworks/*`, ADR (no heavy federation default) | S | — | 🔄 |
| MFP2 | Vite multi-framework blueprint: React (plugin), optional Astro/Aurelia packaging, vendor chunking for `vue` / `react` / `three`, singleton WASM load strategy | L | MFP1 | ⬜ |
| MFP3 | Vue island host utilities: dynamic mount of foreign roots, layout reservation, error fallback, visibility/intent load, unmount cleanup | M | MFP1 | 🔄 |
| MFP4 | React island path: `createRoot` mount from Vue lifecycle, first R3F or graph demo, heap/WebGL dispose on route leave | L | MFP2, MFP3 | ⬜ |
| MFP5 | Astro tertiary island (optional): prebuilt static island or content component consumed by host | M | MFP1, MFP3 | ⬜ |
| MFP6 | Aurelia tertiary island (optional): host element + DI bootstrap, strict stop on unmount | M | MFP3 | ⬜ |
| MFP7 | Cross-framework parity kit: one visitor question (e.g. design-hub metric) in Vue + React with shared a11y summary | M | MFP4 | ⬜ |
| MFP8 | GraphQL schema v1 for **docs/content graph** (design docs, roadmaps, research nodes, hub panel state entities) | M | DOC model | ⬜ |
| MFP9 | Apollo Client singleton (framework-agnostic core under `docs/website/src/libraries/apollo` or repo-level `src/libraries/apollo`) | M | MFP8 | ⬜ |
| MFP10 | Framework Apollo adapters: Vue composition helper + React hooks; optional Aurelia DI | L | MFP9, MFP4 | ⬜ |
| MFP11 | Static-export GraphQL strategy: build-time fixtures / MSW; no required live endpoint on `gh-pages` | M | MFP8, MFP9 | ⬜ |
| MFP12 | WASM toolchain for website compute demos (`wasm-pack`/C++/AssemblyScript), loader module, CI artifact check | L | MFP2 | ⬜ |
| MFP13 | WASM worker for hub/sim demos (flow-field, GA layout, audio DSP slice) with pure-JS fallback and cancel | L | MFP12 | ⬜ |
| MFP14 | Bridge narrative: document how website WASM demos relate to future **C++ `core/`** simulation (shared concepts, not shared binary yet) | M | MFP13, shared_core | 🔬 |
| MFP15 | Test matrix: unit mount/unmount, cache broadcast, Cypress/docs smoke, per-island budgets | L | MFP4, MFP10, MFP13 | ⬜ |
| MFP16 | Authoring guide: when Vue vs React island vs WASM; teardown rules; ADR links | M | MFP7, MFP11, MFP15 | ⬜ |

## Architecture principles (PMF-specific)

1. **Vue is the host** for the documentation website (navigation, Markdown portal, design hub chrome)—not React/Next.
2. **React is specialized**, not a second full app: use it where the ecosystem wins (R3F, complex 3D/analytics modules per research).
3. **Prefer lightweight mounting** over Single-SPA / Module Federation by default (research notes federation build cost and App Router/webpack pain; this site is Vite-static).
4. **One shared data graph** when cross-island entities exist: Apollo `InMemoryCache` (or Nano Stores for non-GraphQL UI state) rather than dual Pinia+Redux copies of the same entities.
5. **WebGL lifecycle is hostile to naive remounts.** Prefer canvas pooling / single persistent canvas when React 3D islands route-switch frequently (per Hybrid Vue React research).
6. **WASM is opt-in acceleration** for hub demos and later game-adjacent tools; pure JS remains the reduced path.
7. **Static GitHub Pages remains the product constraint** for the website: no required runtime GraphQL server.
8. **Game clients stay native.** Multi-framework work does not replace Kotlin/Swift/C++ game architecture; it extends the **docs/website** and optional tooling UIs.

## Target directory layout (website package)

```text
docs/website/
  src/
    main.ts                      # bootstrap
    router.ts, nav.generated.ts
    views/                       # pages (HomeView, DocPage)
    styles/                      # theme, markdown, hub
    composables/                 # docs/markdown/theme helpers
    frameworks/
      vue/                       # HOST components + shell wrapper
        App.vue
        components/              # shell chrome + hub/
      react/                     # islands (MFP4)
        components/
        mount.ts
      astro/                     # optional (MFP5)
      aurelia/                   # optional (MFP6)
      shared/                    # mount helpers, types (no framework imports)
    libraries/
      apollo/                    # client singleton (MFP9)
      wasm/                      # loaders + bindings (MFP12)
    graphql/
      schema.graphql
      fragments/
      fixtures/
```

## Work packages

### MFP1–MFP3 — Host contract

Formalize that `docs/website/src/frameworks/vue` is the host application. Document island mount protocol (create foreign root on `onMounted`, dispose on `onBeforeUnmount`). Reject heavy federation unless a multi-deploy Multi-Zone need appears.

### MFP4–MFP7 — Foreign islands

**React first (MFP4).** Research prioritizes Vue host + React 3D. Implement a single demo island (e.g. dependency graph or lore map stub) with:

- Vue wrapper component that owns the host `div`
- React `createRoot` + strict unmount
- `markRaw` / non-proxied Three objects if using R3F later
- Budget: React+Three vendor chunk not loaded until island open

**Astro / Aurelia (MFP5–MFP6).** Only after React island path is proven; keep as optional demos of polyglot skill, not production requirements for the game.

### MFP8–MFP11 — GraphQL + Apollo

Schema describes **documentation and hub entities**, not live game servers. Default transport: static fixtures generated at build or checked-in JSON. Tests use MSW. Live HTTP GraphQL is an explicit backend fork.

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

- **MF-G1:** Documented host contract; Vue site still deploys to `gh-pages`.
- **MF-G2:** React island demo with leak-safe unmount and budget evidence.
- **MF-G3:** GraphQL schema + Apollo fixtures offline.
- **MF-G4:** WASM worker demo with JS fallback.

## Document history

| Date | Revision | Change |
| --- | --- | --- |
| 2026-08-09 | R1 | Initial PMF multi-framework roadmap after `docs/website` flatten + `src/frameworks/vue` layout. |
