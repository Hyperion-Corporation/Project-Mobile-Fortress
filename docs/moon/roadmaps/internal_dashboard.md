# Internal Dashboard Roadmap (Docs Site + Product/Dev Analytics)

**IDs:** MFP1–MFP16 (multi-framework platform infrastructure, merged in verbatim below) · ID1–ID11 (dashboard/analytics deliverables, new) · **Status:** 🔄 host/island infrastructure delivered, dashboard layer not started · **Owner:** TBD (ID11 ML-signal sourcing depends on [`ai_systems.md`](ai_systems.md), owned by ACFHarbinger)

**2026-08-11 note:** dashboard remains **developer-first** (players may browse later); **static/local/batch first** — no remote live hosting required until the team needs it. Game work is 75% of capacity; this track is secondary. Sentiment ingestion (ID9/ID10) stays research; automated in-game responses are HITL-gated research in `ai_systems.md` A12/A13.

**2026-08-09 merge note:** this file replaces `multi_framework_platform.md`, which is deleted. The React/Aurelia/Astro/Apollo host-and-island work tracked as MFP1–MFP16 was never an end in itself — it was always building the technical substrate (a controlled polyglot shell that can mount specialized visualization islands without breaking static-hosting or a11y/perf budgets) that this dashboard initiative now needs: developer-facing telemetry, monetization metrics, lore/product tracking, player-feedback ingestion, 3D/data visualization, and zoomable in-game-lore maps, all living on `docs/website/`. The two initiatives are one initiative, tracked in one file from here on. MFP1–MFP16 content below is preserved verbatim (per owner decision, 2026-08-09) as the "how the dashboard is built" section; ID1–ID11 are the new "what the dashboard does" deliverables, including the former `product-metrics`-labeled GitHub issues (#120–125).

---

## Part A — Dashboard/analytics deliverables (ID1–ID11, new)

Scope: extend `docs/website/` from a documentation portal + interop showcase into a real internal dashboard for developers — game/product telemetry, monetization metrics, in-game lore browsing (zoomable map, drill into a building/location for local lore, zoom out for regional lore), player feedback and app/store review tracking, ML-personalization signal surfacing (which civs/heroes a player favors, and their friends'/clan-mates' preferences, feeding future store-offer personalization in [`ai_systems.md`](ai_systems.md) A7/A11), and interactive demos of game elements (animations, mini-games). This absorbs the former `product-metrics`-labeled GitHub issues (#120–125).

| # | Item | Effort | Depends on | Status | Source issue |
| --- | --- | --- | --- | --- | --- |
| ID1 | Define dashboard requirements: which game/product metrics matter first (retention, monetization, telemetry, lore/product tracking, player feedback) — scope before building | S | — | 📋 Pending | #121 |
| ID2 | Information architecture & wireframes for the dashboard surface within the existing React host | M | ID1 | 📋 Pending | #122 |
| ID3 | Stand up the dashboard website skeleton as a new `docs/website/src/frameworks/react` view (or a dedicated island, per the Authoring guide below) | M | ID2, MFP1–MFP3 | 📋 Pending | #123 |
| ID4 | Wire the dashboard to a backend analytics/leaderboard API — depends on [`backend.md`](backend.md) B7 (Leaderboards REST API) existing first; no dashboard-side telemetry ingestion without a real backend to read from | L | ID3, backend.md#B7 | 📋 Pending | #124 |
| ID5 | Real-time WebSocket metrics streaming for the v1 dashboard | — | ID4 | ❌ Rejected for v1 — polling/batch refresh is sufficient until a demonstrated need for sub-minute latency exists; revisit post-MVP | #125 |
| ID6 | Zoomable in-game-lore map: drill into a building/settlement/coastal outpost for local lore text, zoom out for regional/historical context — reuses `CoastalFlowField.astro`'s coordinate model (MFP5) as a starting point, not a from-scratch map | L | MFP5 | 📋 Pending | — |
| ID7 | 3D model viewer + data-visualization component library for the dashboard (unit/hero 3D previews, dynamic + interactive charts/plots for telemetry and monetization) — evaluate against [`Vue 3 Visualization Stack Research.md`](../research/Vue%203%20Visualization%20Stack%20Research.md)'s library findings, re-scoped to the current React host | L | ID3 | 📋 Pending | — |
| ID8 | Interactive demos for game elements on the dashboard/marketing surface (unit animations, small playable mini-games) | M | ID3, ID7 | 📋 Pending | — |
| ID9 | Player feedback + app/Play Store review ingestion pipeline, surfaced on the dashboard alongside telemetry | L | ID4 | 📋 Pending | — |
| ID10 | Future extension (research, not committed): scrape/ingest community posts (Reddit, X/Twitter) for lore-mention and sentiment signal | L | ID9 | 🔬 Research backlog — needs a named use case and a data-retention/ToS review before this becomes a committed deliverable, not just "would be interesting" | — |
| ID11 | Surface ML-personalization signals (per-player civ/hero preference, friend/clan-mate preference) on the dashboard for devs, sourced from [`ai_systems.md`](ai_systems.md) A7 (CMAB offers)/A9 (churn) — dashboard-side visualization only, the modeling itself lives in `ai_systems.md` and is owned by ACFHarbinger | L | ai_systems.md#A7, ai_systems.md#A9 | 📋 Pending | — |

Effort key: S = days, M = 1–2 weeks, L = 3–6 weeks, XL = multi-month/cross-cutting.

---

## Part B — Multi-framework platform infrastructure (MFP1–MFP16, merged verbatim from `multi_framework_platform.md`, 2026-08-09)

Goal: evolve the **React 19 + Vite documentation portal** (`docs/website/`) into a controlled polyglot shell where React owns navigation, Markdown docs, and hub chrome; specialized visualization/interop islands live alongside it (**Aurelia**, **Astro**, and now **Apollo/GraphQL**); and **WASM** (aligned with the planned C++ core story) accelerates heavy client-side work—without breaking static GitHub Pages deploy, accessibility, or Web Vitals.

> **2026-08-09 update:** the site originally shipped Vue 3 as the host framework (see Document history below for the superseded baseline). It has since been migrated to a React 19 host — see [`docs/website/APP.md`](../../website/APP.md) for the rationale. This roadmap's IDs/deliverables are reinterpreted against the React host below rather than rewritten wholesale; MFP1–MFP4's "Vue host + React island" framing is now moot since React *is* the host, and MFP8–MFP11's GraphQL/Apollo work has landed as a real (client-resolved) island rather than remaining a future milestone.

### Current codebase baseline (2026-08-09, post-React-migration)

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

### Deliverable index

| ID | Deliverable | Effort | Depends on | Status |
| --- | --- | --- | --- | --- |
| MFP1 | Document host/island contract: React host, Aurelia/Astro/Apollo islands, directory layout under `docs/website/src/frameworks/*`, ADR (no heavy federation default) | S | — | ✅ host is now React; contract documented in `APP.md`/`README.md` |
| MFP2 | Vite multi-framework blueprint: React plugin covers the full host, Astro/Aurelia packaging, singleton load strategy for islands | L | MFP1 | ✅ `vite.config.ts` — single `react()` plugin, no dual-framework split needed post-migration |
| MFP3 | React island host utilities: dynamic mount of foreign roots (Aurelia, Astro iframe), layout reservation, error fallback, visibility/intent load, unmount cleanup | M | MFP1 | ✅ `useIntersect`/`useClickOutside`/`useFocusWhen` hooks + `ConvergenceChartWrapper.tsx`/`CoastalFlowFieldWrapper.tsx` |
| MFP4 | ~~React island path~~ — superseded: React is now the host itself, not a mounted island. `UnitRosterBoard.tsx` is used natively in `HomeView.tsx`. R3F/3D demo work remains open (see ID7 above). | L | MFP2, MFP3 | 🔁 reframed — no foreign-root React mount needed; 3D/R3F demo now tracked as ID7 |
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
| MFP16 | Authoring guide: when host vs foreign-root island vs WASM; teardown rules; ADR links | M | MFP7, MFP11, MFP15 | ✅ [Authoring guide](#authoring-guide), below |

### Architecture principles (PMF-specific)

1. **React is the host** for the documentation website (navigation, Markdown portal, design hub chrome)—not Vue/Nuxt. (Superseded principle: this site originally ran Vue as host; see Document history.)
2. **Aurelia and Astro are specialized islands**, not second full apps: mounted into React-owned host nodes for a self-contained visualization/interop demo each (GA convergence chart; static flow-field diagram).
3. **Prefer lightweight mounting** over Single-SPA / Module Federation by default (research notes federation build cost and App Router/webpack pain; this site is Vite-static).
4. **One shared data graph** when cross-island entities exist: Apollo `InMemoryCache` is now live for the docs/content graph (`src/frameworks/apollo/`); UI state that isn't GraphQL-shaped (theme, active hub tab, search-open) lives in `src/libraries/redux/` instead of a second copy.
5. **WebGL lifecycle is hostile to naive remounts.** Prefer canvas pooling / single persistent canvas if/when a 3D (R3F) island lands (per Hybrid Vue React research — still applicable to a React host).
6. **WASM is opt-in acceleration** for hub demos and later game-adjacent tools; pure JS remains the reduced path.
7. **Static GitHub Pages remains the product constraint** for the website: no required runtime GraphQL server — confirmed by the Apollo island's local-resolver design (MFP11).
8. **Game clients stay native.** Multi-framework work does not replace Kotlin/Swift/C++ game architecture; it extends the **docs/website** and optional tooling UIs — now including the dashboard deliverables in Part A above.

### Target directory layout (website package, current)

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

### Work packages

#### MFP1–MFP3 — Host contract

`docs/website/src/frameworks/react` is now the host application (migrated from the original `frameworks/vue`). Island mount protocol for foreign-root frameworks (Aurelia) uses `useEffect` mount/cleanup instead of Vue's `onMounted`/`onBeforeUnmount`; the Astro island stays an iframe embed (no mount protocol needed, just `useIntersect` for lazy load). Federation remains rejected unless a multi-deploy Multi-Zone need appears.

#### MFP4–MFP7 — Foreign islands

**React (MFP4) — superseded.** React is the host itself now, so there's no "mount React into a foreign host" step left to do; `UnitRosterBoard.tsx` is a native component in `HomeView.tsx`. A future R3F/3D demo (ID7) would mount *inside* the React tree directly (no `createRoot`/foreign-root dance needed), but that demo itself hasn't been built yet.

**Astro (MFP5).** `CoastalFlowField.astro` is a real design-hub island (deterministic land/sea raid-lane vectors toward the citadel). Build with `npm run build:astro` (also runs on `prebuild`) into `public/astro-island/`; the React host embeds it via `CoastalFlowFieldWrapper.tsx` (iframe + `BASE_URL`). Further promotion: typed props bridge, `client:visible` hydration experiments, and budget checks. ID6 (zoomable lore map) builds on this island's coordinate model.

**Aurelia (MFP6) — delivered.** `convergence-chart-app.ts` (a real Aurelia 2 custom element) + `mount.ts` (`Aurelia.app({ host, component }).start()`) + `ConvergenceChartWrapper.tsx` (React host, mounts/unmounts via `useEffect`). Visualizes `src/simulations/`'s HQ-layout GA convergence data.

#### MFP8–MFP11 — GraphQL + Apollo

Schema describes **documentation and hub entities**, not live game servers — delivered as `src/graphql/schema.graphql`'s `Outpost`/`RaidLane`/`LoreStory` types. Transport is a local `ApolloLink` (`src/frameworks/apollo/client.ts`) resolving those fields against real repo data (`src/stories/` lore, a curated outpost/raid-lane layout) rather than checked-in JSON fixtures or MSW — same end result (no live endpoint required on `gh-pages`) via a slightly different mechanism than originally scoped. `ApolloLorePanel.tsx` is the React consumer (`useQuery`); an Aurelia DI adapter (MFP10) was not attempted, since the Aurelia island doesn't currently need docs/content-graph data. ID4/ID9's telemetry and review data are expected to extend this same schema once a real backend exists (`backend.md` B7), rather than introducing a second data layer.

#### MFP12–MFP14 — WASM

Website WASM demos should teach flow-field / layout / audio ideas from the design hub without pretending to be the authoritative multiplayer simulation. Link conceptually to [`shared_core.md`](shared_core.md) C++ plans; do not block game milestones on website WASM.

#### MFP15–MFP16 — Quality and docs

Per-island gzip budgets; ten mount/unmount leak probes; Cypress smoke that host docs still work when islands fail to load.

### Authoring guide

**(MFP16, delivered)** This is the decision guide for adding new functionality to `docs/website/`:
which of the site's supported mounting patterns to reach for, and how to tear it down cleanly. It
doesn't repeat the *why* behind each existing island — that's `docs/website/APP.md` — this is the
*when/how* for the next one. The new dashboard deliverables (Part A) should be built using this
same decision process, not a parallel one.

#### Decision: which pattern?

```text
Does it need its own component model / rendering engine
(not just a React component)?
│
├─ No → Native React component (src/frameworks/react/, or src/hooks/ for
│        cross-cutting behavior). This is the default. Don't reach for a
│        foreign-root mount just because a feature feels "separate" —
│        UnitRosterBoard.tsx and ConvergenceStatus.tsx are both real,
│        substantial features implemented as plain React components.
│
└─ Yes → Is it prebuilt/static, with no need to react to host state?
         │
         ├─ Yes → Iframe island (Astro pattern). Prebuild it
         │         (`npm run build:astro` → public/astro-island/), embed via
         │         an iframe wrapper using useIntersect for lazy load. No
         │         mount/unmount lifecycle to manage — the browser owns the
         │         iframe's lifecycle.
         │
         └─ No  → Foreign-root island (Aurelia pattern). Mount a real
                   instance of the other framework's runtime into a
                   React-owned DOM node from useEffect; tear it down in the
                   same effect's cleanup function. See "Teardown rules" below
                   — this is the pattern that leaks if you get it wrong.
```

A fourth option, **WASM**, is forward-looking (MFP12–MFP14, not yet started): once a compute-heavy
hub demo needs it, the same "does it need its own runtime" question applies, but the answer is a
`Worker` + WASM module with a pure-JS fallback rather than a UI framework — see this roadmap's
MFP12–MFP14 rows before starting that work. It doesn't get its own branch in the decision tree
above because nothing in this site needs it yet; don't add a WASM island speculatively.

#### Native React component

The default, and the right choice for anything that doesn't need a different framework's rendering
model. Live under `src/frameworks/react/components/` (shell chrome) or `.../components/hub/`
(design-hub panels); cross-cutting logic that isn't itself a component belongs in `src/hooks/`.
Example: `ConvergenceStatus.tsx` (MFP7) — a small, real feature, not a placeholder, implemented as
a plain function component with no special mounting concerns.

#### Foreign-root island (Aurelia pattern)

Use when the feature's own component model — custom elements, binding commands, a DI container —
is the point (a demo of that framework), or when porting an existing non-React implementation isn't
worth a rewrite. Structure, following `src/frameworks/aurelia/`:

1. The framework-native implementation (`convergence-chart-app.ts`) — a self-contained component
   with no React imports.
2. A framework-neutral `mount.ts` that boots the other framework's app into a given host element
   and returns a handle with a `stop()` method.
3. A thin React wrapper (`ConvergenceChartWrapper.tsx`) that owns a host `<div>` ref and calls
   `mount.ts` from `useEffect`, returning the cleanup function from that same effect.

##### Teardown rules

- **Always return the cleanup function from the same `useEffect` that mounted.** Don't mount in one
  effect and try to tear down in another — React's effect cleanup contract is what guarantees this
  runs on unmount (and on every re-render if the dependency array changes, which is why the mount
  effect should have a stable, empty-or-near-empty dependency array).
- **The other framework's own stop/dispose API, not DOM removal.** `mount.ts`'s handle calls
  `au.stop(true)` (Aurelia) — the `true` forces disposal, releasing bindings/observers, not just
  detaching the view. Removing the host `<div>` from the DOM without calling this first leaks
  whatever the framework's runtime was still tracking (timers, observers, DI registrations).
- **Decorator-free resource definitions where the framework supports them.** The Aurelia island
  originally used `@customElement`/`@bindable` decorators; they were replaced with the static `$au`
  resource-definition property (plain data, see `convergence-chart-app.ts`'s own comments) after a
  real cross-bundler bug — Aurelia's decorator metadata relies on the TC39 stage-3
  decorator-metadata proposal (`Symbol.metadata`), which Vite/esbuild emits by default but Next's
  SWC (`stack/next/`) cannot produce regardless of tsconfig. If a future island's framework has a
  similar decorator-free escape hatch, prefer it — it sidesteps an entire class of bundler-specific
  breakage this site has already hit once.
- **Verify with a real render, not just a build.** The `$au` migration above initially "passed"
  `vite build`/`next build` while still crashing at runtime — decorator/metadata issues and
  framework-specific DOM-binding bugs (e.g. `SVGPolylineElement.points` being a getter-only
  property, breaking Aurelia's default property-binding heuristic) only surface when the component
  actually mounts in a browser. `npx cypress run` against `vite preview`/`next dev` is a fast way to
  check this without a full E2E suite.

#### Iframe island (Astro pattern)

Use for prebuilt, static content that doesn't need to read or write host state — a diagram, a
visualization with its own self-contained interactivity. Structure, following
`src/frameworks/astro/`:

1. The Astro source (`CoastalFlowField.astro`), built standalone via `npm run build:astro` into
   `public/astro-island/` (also runs on `prebuild`).
2. A React wrapper (`CoastalFlowFieldWrapper.tsx`) — an `<iframe>` pointed at the built island via
   `siteBaseUrl()` (`src/utils/baseUrl.ts` — not `import.meta.env.BASE_URL` directly; that throws
   under `stack/next/`, where `import.meta.env` doesn't exist), lazy-loaded with `useIntersect` so
   it doesn't cost anything until scrolled into view, with a `failed`/`loaded` state pair so a
   missing prebuilt island (e.g. local dev without having run `build:astro`) degrades to a visible
   fallback message instead of a broken iframe.

No mount/unmount lifecycle to manage here — the browser's own iframe lifecycle handles it, which is
exactly why this pattern is preferred over a foreign-root mount whenever the content is genuinely
static.

#### Cross-framework parity (when two islands describe the same data)

If a value is meaningful enough to show in more than one place (a design-hub metric, a simulation
result), put the computation in one framework-neutral module — see `src/simulations/summary.ts`
(MFP7) — and have each framework's presentation layer call it directly, rather than each
recomputing or hand-copying the text. This is what keeps `ConvergenceStatus.tsx` (React) and
`convergence-chart-app.ts`'s `statusSummary` getter (Aurelia) from silently drifting out of sync,
and it's directly testable: `test/unit/simulations/convergence-parity.test.ts` instantiates both
paths against the same input and asserts equal output.

#### Data layer: Apollo vs Redux

- **Apollo** (`src/frameworks/apollo/`) owns anything shaped like the docs/content graph
  (`src/graphql/schema.graphql`'s `Outpost`/`RaidLane`/`LoreStory` types) — even though there's no
  live server, `InMemoryCache` still gives real cross-call-site cache reuse (see
  `test/unit/apollo/cache-broadcast.test.ts`). ID4/ID9's telemetry/review data should extend this
  schema once a backend exists, not introduce a second query layer.
- **Redux** (`src/libraries/redux/`) owns UI state that isn't GraphQL-shaped: theme, active hub tab,
  search-open. Don't reach for Apollo's cache to store this — it's not an entity with an identity a
  query resolves, it's local UI state.

#### Budgets

Every foreign-root island's built chunk(s) are checked against the 300 kB gzip budget from this
roadmap's "Performance budgets" table by `docs/website/scripts/check-island-budgets.mjs` (runs
automatically via `postbuild`). Add a new `{ name, pattern }` entry there when a new island produces
its own chunk — iframe islands (prebuilt separately, outside this bundle) and native React
components (no separate "island open" moment) don't need an entry. New dashboard deliverables
(ID6–ID8, if built as islands rather than native components) must add budget entries the same way.

### Testing plan

| Layer | Proof |
| --- | --- |
| Unit | Vue host helpers; React mount/unmount; Apollo cache write→read; WASM load failure |
| Integration | Island open does not break doc router; theme toggle still works |
| E2E/smoke | `/` hub + one doc route; no uncaught errors when island disabled |
| Perf | LCP of docs routes unchanged when islands closed; INP when opening React island |
| GPU | Route thrash does not leak WebGL contexts (canvas pool when MFP4/ID7 ships 3D) |

### Performance budgets (website)

| Budget | Target |
| --- | --- |
| Docs route JS (islands closed) | No regression vs pre-MFP baseline (±5%) |
| First foreign island open | ≤ 300 kB gzip additional vendor for that island |
| Dual-runtime concurrent islands | Prefer exclusive mode if INP > 200 ms |
| WASM module | Progress UI if > 1 MB; never block first docs paint |
| Dashboard route (ID3+) | Same LCP/INP budgets as docs routes — a dashboard is not exempt from the site's perf discipline just because it's dev-facing |

### Risks

| Risk | Mitigation |
| --- | --- |
| Dual Vue+React payload | Lazy islands; chunk splitting; one heavy island per route |
| WebGL context loss on route change | Canvas pooling; dispose R3F resources |
| Federation complexity | Not default; document rejection in ADR |
| GraphQL live dependency | Fixtures only on Pages |
| Scope bleed into game clients | MFP/dashboard issues labeled `website`/`product-metrics`; game remains `android`/`ios`/`core` |
| Dashboard scope creep (ID10 scraping) | Kept in research backlog, not committed, until a named use case + ToS/retention review exists |

### Research mapping

| Research doc | Primary IDs |
| --- | --- |
| Hybrid Vue React Architecture | MFP1–MFP4, MFP7, canvas pooling |
| Hybrid Micro-Frontend Architecture | MFP2, MFP5–MFP6, host choice (Vue) |
| Vue 3 Visualization Stack | MFP4 viz library choices, worker offload; re-evaluate against ID7 (dashboard viz library choice) now that the host is React |
| WASM Micro-Frontend Integration | MFP9–MFP14 (adapt federation claims to Vite-static reality) |

### Exit gates

- **MF-G1:** Documented host contract; site still deploys to `gh-pages`. ✅ (host contract now React-based; deploy pipeline unchanged)
- **MF-G2:** React island demo with leak-safe unmount and budget evidence. 🔁 reframed — no React foreign-root island applicable post-migration; Aurelia's leak-safe unmount (`useEffect` cleanup calling `au.stop(true)`) is the closest equivalent, delivered.
- **MF-G3:** GraphQL schema + Apollo fixtures offline. ✅ delivered via `src/frameworks/apollo/` (schema-shaped local resolver, no live endpoint).
- **MF-G4:** WASM worker demo with JS fallback. ⬜ not started.
- **ID-G1 (new):** Dashboard requirements + IA signed off (ID1, ID2) before any dashboard UI code lands.
- **ID-G2 (new):** Dashboard reads from a real backend endpoint (ID4, gated on `backend.md` B7), not mock data, before it's considered anything beyond a prototype.

## Document history

| Date | Revision | Change |
| --- | --- | --- |
| 2026-08-09 | R1 | Initial PMF multi-framework roadmap after `docs/website` flatten + `src/frameworks/vue` layout. |
| 2026-08-09 | R2 | Updated after migrating the docs site's host framework from Vue 3 to React 19, replacing Vuex with Redux (`src/libraries/redux/`), and delivering the Apollo/GraphQL island (MFP8, MFP9, MFP11) against `src/graphql/schema.graphql`. MFP4 and MF-G2 reframed since React is now the host rather than a mounted island; MFP1–MFP3, MFP6 status updated to reflect delivered work. See [`docs/website/APP.md`](../../website/APP.md) for the full rationale. |
| 2026-08-09 | R3 | Delivered MFP7 (cross-framework a11y parity kit — `src/simulations/summary.ts` shared by React's `ConvergenceStatus.tsx` and the Aurelia island's `statusSummary` getter) and the remainder of MFP15 (Apollo `InMemoryCache` broadcast test; `scripts/check-island-budgets.mjs` per-island gzip budget check wired into `postbuild`). Also wired this roadmap into `docs/mkdocs.yml`'s Roadmap nav section (it existed on disk but wasn't linked from the docs site sidebar). |
| 2026-08-09 | R4 | Delivered MFP16: the "Authoring guide" section above — the decision guide for native React component vs foreign-root island (Aurelia pattern) vs iframe island (Astro pattern) vs WASM (forward-looking), teardown rules, and links into `APP.md`'s per-island rationale. Originally landed as a standalone `multi_framework_authoring_guide.md`; merged into this file in R5 for a single source of truth. |
| 2026-08-09 | R5 | Merged `multi_framework_authoring_guide.md` into this file (single source of truth for the multi-framework platform roadmap — deliverable table, work packages, *and* the authoring guide, rather than splitting the guide into a sibling doc). `docs/mkdocs.yml`'s nav entry for the standalone guide removed. |
| 2026-08-09 | R6 | **File renamed from `multi_framework_platform.md` to `internal_dashboard.md`.** Owner decision (multi-agent brainstorm session, 2026-08-09): the multi-framework platform work and the `product-metrics` GitHub-issue initiative (#120–125) are one initiative, not two — merged into Part A (ID1–ID11, new dashboard/analytics deliverables) + Part B (MFP1–MFP16, preserved verbatim). `multi_framework_platform.md` deleted; all cross-references (`ROADMAP.md`, `docs/mkdocs.yml`, `repo_automation.md`) updated to point here. |
