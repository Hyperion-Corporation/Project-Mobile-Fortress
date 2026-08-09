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
  },
};

export default nextConfig;
