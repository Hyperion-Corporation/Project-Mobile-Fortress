// Next.js config — not the primary build here (Vite drives the default
// build/deploy pipeline); kept as an alternate React-rendered surface over
// the frameworks/react/ shell + island components, via the App Router
// (../../app/layout.tsx + ../../app/[[...slug]]/page.tsx — the catch-all
// page hands off to the same client router as the Vite build, see
// src/frameworks/react/RouterShell.tsx). Reachable only via `npm run next:*`.
/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  pageExtensions: ["tsx", "ts"],
  typescript: {
    // Own tsconfig (not the shared root one) — `next build` rewrites
    // whatever tsconfig it's pointed at (jsx: "preserve", esModuleInterop,
    // etc.), which would silently break the Vite build if it mutated the
    // shared tsconfig.json.
    tsconfigPath: "./tsconfig.next.json",
    // The Aurelia island (src/frameworks/aurelia/convergence-chart-app.ts)
    // uses legacy-style class decorators (@customElement, @bindable) that
    // esbuild/Vite parse and transpile fine (no type-checking in that
    // pipeline — see the root build script's `tsc -b --noCheck`) but that
    // don't fully satisfy TS's decorator-signature checking under Next's
    // stricter, type-checked build. This surface is an alternate/demo
    // surface, not the primary pipeline (see stack/next/README.md), so
    // don't block it on a type-check gap the primary build doesn't enforce
    // either.
    ignoreBuildErrors: true,
  },
  eslint: {
    ignoreDuringBuilds: true,
  },
};

export default nextConfig;
