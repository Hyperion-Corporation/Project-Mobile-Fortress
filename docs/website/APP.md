# Why this site looks the way it does

`docs/website/` is deliberately more than a documentation static-site generator. It exists to do
two things at once: serve as Mobile Fortress's actual documentation portal and design hub, and
serve as a working demonstration of multi-framework interop patterns — kept in parity with the
equivalent site in the sibling `Image-Toolkit` repository, so contributors moving between this
org's docs sites find the same architecture wherever they land.

## Why Vue as the primary shell

The chrome (topbar, sidebar, search, theme toggle, doc rendering, the design hub) is Vue 3 +
Vite. This was the original choice for this site and remains the primary framework; nothing here
changes that.

## Why framework islands beyond Vue

Two islands live under `src/frameworks/` (alongside the pre-existing Astro island), each
demonstrating a different integration mechanic:

- **React** (`frameworks/react/`) — `UnitRosterBoard.tsx` reads `src/constants/fortress.ts`
  directly (the same roster data `src/stories/` and the Game Design Document draw from) and
  mounts via `ReactDOM.createRoot()` into a Vue-owned DOM node
  (`UnitRosterBoardWrapper.vue`). Demonstrates the "live client-side mount" pattern. The same
  component is documented in isolation via Storybook (`stories/`), built standalone into
  `public/storybook/`.
- **Aurelia 2** (`frameworks/aurelia/`) — `convergence-chart-app.ts`, a real Aurelia custom
  element with bindable state, a `repeat.for`-driven SVG polyline, and its own play/reset
  lifecycle, mounted via `Aurelia.app({ host, component }).start()`. It visualizes
  `src/simulations/`'s existing HQ-layout GA convergence data (`generateConvergenceRun` /
  `createSimulationController`, previously only consumed by `TechPanel.vue`'s own GA-grid demo) —
  reused rather than reinvented, since that domain logic already existed here. Demonstrates a
  framework whose component model (custom elements, binding commands) is fully independent of
  Vue's.

Unlike `Image-Toolkit` (which has a real standalone React app under `frontend/` to mount
verbatim), this repository has no existing TypeScript/React codebase outside `docs/website/`
itself — `android/` is Kotlin, `ios/` is Swift, and `core/` is deliberately not a compiled shared
module (see `core/README.md`). So the React and Aurelia islands here are self-contained
components authored within `docs/website/`, not imports of a pre-existing app. What they're
*not* is a placeholder: both read and render this project's real data (the unit roster, the GA
convergence simulation), the same way the Astro island visualizes a real land/sea raid-lane flow
field rather than a generic demo.

## Why MkDocs stays the way it is

`docs/mkdocs.yml` remains the source of truth for the documentation nav tree
(`scripts/generate-nav.mjs` parses it to build `src/nav.generated.ts`). This is unchanged by the
work described here — see `docs/mkdocs.yml`'s `nav:` and `.github/workflows/docs.yml` for how it
fits into the deploy pipeline.

## Why the extra tooling scaffolding (Next.js, TypeDoc, Storybook)

`stack/next/` is an alternate, React-capable surface over `src/frameworks/react/` — not used by
the default build, kept for parity with `stack/nuxt/` (which the README already flagged as "the
Vue analogue of `stack/next`" before this directory existed) so a real Next.js requirement has a
starting point instead of a from-scratch migration.

`typedoc.json` + `scripts/fix-api-links.mjs` generate `docs/api/typescript/` from
`src/simulations/` — this site's own framework-neutral simulation logic is the closest thing this
repository has to a reusable TypeScript library worth an API reference, so it's what gets
documented rather than inventing an unrelated module. `stories/` + `.storybook/` document the
React island's component(s) in isolation, built standalone into `public/storybook/`.

## Why `src/styles/tailwind.css` was added

`postcss.config.js` already wired `tailwindcss` into the PostCSS pipeline, and the hub panels
already used Tailwind utility classes (`DesignPanel.vue`, `TechPanel.vue`, etc.) — but no file in
this project actually contained an `@tailwind` directive, so none of that ever generated any CSS.
This file fixes that gap directly (not a side effect of adding the React island, though the
island's markup benefits too). It deliberately omits `@tailwind base` (Tailwind's global reset)
since enabling that for the first time on an already-shipping site is a real visual-regression
risk that deserves its own reviewed change, not a silent side effect of restoring the utility
classes that were already written.
