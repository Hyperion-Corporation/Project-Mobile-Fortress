# stack/next/

Next.js config for an alternate React-rendered surface over `src/frameworks/react/` — not part
of the default build/deploy pipeline (Vite drives that).

The actual App Router files live at the project root (Next resolves `app/` relative to where
`next.config.js` is, i.e. `docs/website/`, not inside this directory):

- `app/layout.tsx` — root layout; same providers (`ReduxProvider`) and global CSS as the Vite
  entry (`src/main.tsx`).
- `app/[[...slug]]/page.tsx` — a single client-only catch-all route that hands off every path to
  `src/frameworks/react/RouterShell.tsx`, which mounts the same `react-router` data router
  (`src/router.tsx`) the Vite build uses. It's loaded via `next/dynamic(..., { ssr: false })`
  because `createBrowserRouter` touches `window` at module scope and can't run during Next's
  server render — so the route table is defined once (`src/router.tsx`) and reused, not
  duplicated as Next pages.

```bash
npm run next:dev
```
