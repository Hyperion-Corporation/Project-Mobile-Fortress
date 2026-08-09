// Next.js config — not the primary build here (Vite drives the default
// build/deploy pipeline); kept as an alternate React-rendered surface over
// the frameworks/react/ shell + island components. Reachable only via
// `npm run next:*`.
/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  pageExtensions: ["tsx", "ts"],
};

export default nextConfig;
