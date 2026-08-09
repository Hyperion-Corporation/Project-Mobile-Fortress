# Multi-Framework Authoring Guide (docs/website/)

**ID:** MFP16 · **Status:** ✅ delivered · **Companion to:** [`multi_framework_platform.md`](multi_framework_platform.md), [`docs/website/APP.md`](../../website/APP.md)

This is the decision guide for adding new functionality to `docs/website/`: which of the site's
supported mounting patterns to reach for, and how to tear it down cleanly. It doesn't repeat the
*why* behind each existing island — that's `APP.md` — this is the *when/how* for the next one.

## Decision: which pattern?

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
`Worker` + WASM module with a pure-JS fallback rather than a UI framework — see
`multi_framework_platform.md`'s MFP12–MFP14 rows before starting that work. It doesn't get its own
branch in the decision tree above because nothing in this site needs it yet; don't add a WASM
island speculatively.

## Native React component

The default, and the right choice for anything that doesn't need a different framework's rendering
model. Live under `src/frameworks/react/components/` (shell chrome) or `.../components/hub/`
(design-hub panels); cross-cutting logic that isn't itself a component belongs in `src/hooks/`.
Example: `ConvergenceStatus.tsx` (MFP7) — a small, real feature, not a placeholder, implemented as
a plain function component with no special mounting concerns.

## Foreign-root island (Aurelia pattern)

Use when the feature's own component model — custom elements, binding commands, a DI container —
is the point (a demo of that framework), or when porting an existing non-React implementation isn't
worth a rewrite. Structure, following `src/frameworks/aurelia/`:

1. The framework-native implementation (`convergence-chart-app.ts`) — a self-contained component
   with no React imports.
2. A framework-neutral `mount.ts` that boots the other framework's app into a given host element
   and returns a handle with a `stop()` method.
3. A thin React wrapper (`ConvergenceChartWrapper.tsx`) that owns a host `<div>` ref and calls
   `mount.ts` from `useEffect`, returning the cleanup function from that same effect.

### Teardown rules

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

## Iframe island (Astro pattern)

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

## Cross-framework parity (when two islands describe the same data)

If a value is meaningful enough to show in more than one place (a design-hub metric, a simulation
result), put the computation in one framework-neutral module — see `src/simulations/summary.ts`
(MFP7) — and have each framework's presentation layer call it directly, rather than each
recomputing or hand-copying the text. This is what keeps `ConvergenceStatus.tsx` (React) and
`convergence-chart-app.ts`'s `statusSummary` getter (Aurelia) from silently drifting out of sync,
and it's directly testable: `test/unit/simulations/convergence-parity.test.ts` instantiates both
paths against the same input and asserts equal output.

## Data layer: Apollo vs Redux

- **Apollo** (`src/frameworks/apollo/`) owns anything shaped like the docs/content graph
  (`src/graphql/schema.graphql`'s `Outpost`/`RaidLane`/`LoreStory` types) — even though there's no
  live server, `InMemoryCache` still gives real cross-call-site cache reuse (see
  `test/unit/apollo/cache-broadcast.test.ts`).
- **Redux** (`src/libraries/redux/`) owns UI state that isn't GraphQL-shaped: theme, active hub tab,
  search-open. Don't reach for Apollo's cache to store this — it's not an entity with an identity a
  query resolves, it's local UI state.

## Budgets

Every foreign-root island's built chunk(s) are checked against the 300 kB gzip budget from
`multi_framework_platform.md`'s "Performance budgets" table by
`docs/website/scripts/check-island-budgets.mjs` (runs automatically via `postbuild`). Add a new
`{ name, pattern }` entry there when a new island produces its own chunk — iframe islands (prebuilt
separately, outside this bundle) and native React components (no separate "island open" moment)
don't need an entry.
