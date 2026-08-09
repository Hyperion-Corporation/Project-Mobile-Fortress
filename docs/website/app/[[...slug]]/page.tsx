"use client";

import dynamic from "next/dynamic";

// react-router's createBrowserRouter runs at module scope and touches
// `window`, so it can't be part of App Router's server render — deferred to
// a client-only chunk via next/dynamic's ssr:false (only valid from inside a
// Client Component, hence "use client" above). This single catch-all route
// hands off every path to the same client router the Vite build uses
// (src/router.tsx), so the route table is defined once, not duplicated.
const RouterShell = dynamic(() => import("../../src/frameworks/react/RouterShell"), {
  ssr: false,
});

export default function CatchAllPage() {
  return <RouterShell />;
}
