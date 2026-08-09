import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

// Deployed as the entire gh-pages site (see .github/workflows/docs.yml), i.e.
// https://acfharbinger.github.io/Project-Mobile-Fortress/ — override via
// SITE_BASE for other deploy targets (local preview under a subpath, forks).
const base = process.env.SITE_BASE || "/";

export default defineConfig({
  base,
  plugins: [react()],
  server: {
    fs: {
      // Allow importing markdown from the repo root (two levels up from
      // this file: website/ -> docs/ -> repo root) — useDocs.ts bundles
      // docs/**/*.md plus a curated set of repo-wide guides that live
      // outside docs/.
      allow: ["../.."],
    },
  },
  build: {
    outDir: "dist",
    emptyOutDir: true,
    chunkSizeWarningLimit: 1024,
  },
});
