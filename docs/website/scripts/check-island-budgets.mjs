#!/usr/bin/env node
// MFP15 — per-island performance budgets. Run after `vite build`
// (`npm run check:budgets`, wired into `postbuild` — see package.json) and
// asserts each *foreign-root* island's own built chunk(s) stay under the
// roadmap's "First foreign island open" budget (see
// docs/moon/roadmaps/multi_framework_platform.md, "Performance budgets
// (website)" table): ≤ 300 kB gzip additional vendor for that island.
//
// Only Aurelia currently produces a separately-loaded chunk: it's mounted
// via a dynamic `import()` from ConvergenceChartWrapper.tsx, so Rollup
// code-splits it out (see dist/assets/mount-*.js). React's UnitRosterBoard
// and the Apollo island are native, statically-bundled components (not
// foreign-root mounts — see APP.md/the roadmap's MFP4 note), so they have
// no separate "island open" moment to budget; the Astro island is a
// prebuilt static site loaded via <iframe>, entirely outside this build's
// JS bundle. Add a pattern below if a future island gets its own chunk.

import { readFileSync, readdirSync, existsSync } from "node:fs";
import { gzipSync } from "node:zlib";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const DIST_ASSETS = path.join(__dirname, "..", "dist", "assets");
const BUDGET_BYTES = 300 * 1024; // 300 kB gzip, per the roadmap table above.

const ISLANDS = [
  { name: "Aurelia (convergence-chart island)", pattern: /^mount-.*\.js$/ },
];

function formatKb(bytes) {
  return `${(bytes / 1024).toFixed(1)} kB`;
}

if (!existsSync(DIST_ASSETS)) {
  console.error(`[check-island-budgets] ${path.relative(process.cwd(), DIST_ASSETS)} not found — run \`vite build\` first.`);
  process.exit(1);
}

const files = readdirSync(DIST_ASSETS);
let failed = false;

for (const island of ISLANDS) {
  const matches = files.filter((f) => island.pattern.test(f));
  if (matches.length === 0) {
    console.warn(`[check-island-budgets] no chunk matched for "${island.name}" (pattern ${island.pattern}) — skipping.`);
    continue;
  }
  const totalGzip = matches.reduce((sum, f) => sum + gzipSync(readFileSync(path.join(DIST_ASSETS, f))).length, 0);
  const status = totalGzip <= BUDGET_BYTES ? "OK" : "OVER BUDGET";
  if (totalGzip > BUDGET_BYTES) failed = true;
  console.log(
    `[check-island-budgets] ${island.name}: ${formatKb(totalGzip)} gzip (budget ${formatKb(BUDGET_BYTES)}) — ${status}` +
      ` [${matches.join(", ")}]`
  );
}

if (failed) {
  console.error("[check-island-budgets] one or more islands exceeded their gzip budget.");
  process.exit(1);
}
