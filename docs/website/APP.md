# Why this site looks the way it does

`docs/website/` is deliberately more than a documentation static-site generator. It exists to do
two things at once: serve as Mobile Fortress's actual documentation portal and design hub, and
serve as a working demonstration of multi-framework interop patterns — kept in parity with the
equivalent site in the sibling `Image-Toolkit` repository, so contributors moving between this
org's docs sites find the same architecture wherever they land.

## Why React as the primary shell

The chrome (topbar, sidebar, search, theme toggle, doc rendering, the design hub) is React 19 +
Vite, under `src/frameworks/react/`. This site originally shipped a Vue 3 shell; it was migrated
to React so the whole site consolidates around a single first-class framework instead of splitting
state/behavior between a Vue host and Vue-owned mount points for its non-Vue islands. React was
the natural target: the pre-existing React island (`UnitRosterBoard.tsx`) and the new Apollo/
GraphQL island are both React-based, and `stack/next/` already existed as this site's React
meta-framework analogue. State management moved with it — `src/libraries/redux/` (legacy
`createStore`/`combineReducers`, typed `useAppDispatch`/`useAppSelector`) replaces the former
`src/libraries/vuex/`, and the custom Vue directives (`v-click-outside`, `v-focus`, `v-intersect`)
were reimplemented as plain hooks (`src/hooks/useClickOutside`, `useFocusWhen`, `useIntersect`).

## Why framework islands beyond React

Three islands live under `src/frameworks/` (alongside the pre-existing Astro island), each
demonstrating a different integration mechanic:

- **Aurelia 2** (`frameworks/aurelia/`) — `convergence-chart-app.ts`, a real Aurelia custom
  element with bindable state, a `repeat.for`-driven SVG polyline, and its own play/reset
  lifecycle, mounted via `Aurelia.app({ host, component }).start()` inside a React-owned host node
  (`ConvergenceChartWrapper.tsx`, mounted/unmounted from a `useEffect`). It visualizes
  `src/simulations/`'s existing HQ-layout GA convergence data (`generateConvergenceRun` /
  `createSimulationController`, previously only consumed by `TechPanel`'s own GA-grid demo) —
  reused rather than reinvented, since that domain logic already existed here. Demonstrates a
  framework whose component model (custom elements, binding commands) is fully independent of
  React's.
- **Apollo/GraphQL** (`frameworks/apollo/`) — `ApolloLorePanel.tsx` runs real `@apollo/client`
  `useQuery` calls against `src/graphql/schema.graphql`'s actual `Query` fields (`outposts`,
  `raidLanes`, `loreStories`). There is no live docs backend yet (see `src/graphql`'s own "MFP8+"
  header note), so `frameworks/apollo/client.ts` resolves those fields locally — against this
  repo's real coastal outpost/raid-lane layout (`frameworks/apollo/data.ts`) and the existing
  `src/stories/` lore catalog — instead of a live network call, the same reuse ethic the Aurelia
  island applies to `src/simulations/`. Demonstrates a data-fetching layer (normalized cache,
  typed `gql` queries, loading/error states) independent of any particular UI framework.
- **Astro** (`frameworks/astro/`) — `CoastalFlowField.astro`, a static land/sea raid-lane flow
  field, prebuilt into `public/astro-island/` and embedded via an iframe wrapper
  (`CoastalFlowFieldWrapper.tsx`, a React port of the original Vue wrapper — same lazy-load/
  intersection-observer/error-fallback behavior, now via `useIntersect`).

`UnitRosterBoard.tsx` (`frameworks/react/`) is no longer a separate "island" in the mount-into-a-
foreign-host sense — since the shell itself is React, it's used directly as a native component in
`HomeView.tsx`. It still reads `src/constants/fortress.ts` directly (the same roster data
`src/stories/` and the Game Design Document draw from) and is still documented in isolation via
Storybook (`stories/`), built standalone into `public/storybook/`.

Unlike `Image-Toolkit` (which has a real standalone React app under `frontend/` to mount
verbatim), this repository has no existing TypeScript/React codebase outside `docs/website/`
itself — `android/` is Kotlin, `ios/` is Swift, and `core/` is deliberately not a compiled shared
module (see `core/README.md`). So the Aurelia, Apollo, and Astro islands here are self-contained,
authored within `docs/website/`, not imports of a pre-existing app. What they're *not* is a
placeholder: each reads and renders this project's real data (the GA convergence simulation, the
docs/content graph, the raid-lane flow field) rather than a generic demo.

## Why MkDocs stays the way it is

`docs/mkdocs.yml` remains the source of truth for the documentation nav tree
(`scripts/generate-nav.mjs` parses it to build `src/nav.generated.ts`). This is unchanged by the
work described here — see `docs/mkdocs.yml`'s `nav:` and `.github/workflows/docs.yml` for how it
fits into the deploy pipeline.

## Why the extra tooling scaffolding (Next.js, TypeDoc, Storybook)

`stack/next/` is an alternate, React-capable surface over `src/frameworks/react/` — not used by
the default build (Vite drives the default build/deploy pipeline), kept so a real Next.js
requirement has a starting point instead of a from-scratch migration. (`stack/nuxt/`, the former
Vue analogue, was removed along with the Vue shell — a Vue meta-framework re-export had no purpose
once nothing in this site was Vue anymore.)

`typedoc.json` + `scripts/fix-api-links.mjs` generate `docs/api/typescript/` from
`src/simulations/` — this site's own framework-neutral simulation logic is the closest thing this
repository has to a reusable TypeScript library worth an API reference, so it's what gets
documented rather than inventing an unrelated module. `stories/` + `.storybook/` document the
React island's component(s) in isolation, built standalone into `public/storybook/`.

## Why `src/styles/tailwind.css` was added

`postcss.config.js` already wired `tailwindcss` into the PostCSS pipeline, and the hub panels
already used Tailwind utility classes — but no file in this project actually contained an
`@tailwind` directive, so none of that ever generated any CSS. This file fixes that gap directly.
It deliberately omits `@tailwind base` (Tailwind's global reset) since enabling that for the first
time on an already-shipping site is a real visual-regression risk that deserves its own reviewed
change, not a silent side effect of restoring the utility classes that were already written.
