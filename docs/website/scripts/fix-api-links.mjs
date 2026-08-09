#!/usr/bin/env node
// Post-processes typedoc-plugin-markdown's output (docs/api/typescript/) so
// its self-referential links work both in MkDocs (validation build, see
// .github/workflows/docs.yml) and in this site's client-side router:
//
//   - TypeDoc emits relative links like "../classes/Foo.md" or
//     "./functions/bar.md" between generated pages.
//   - MkDocs resolves those fine as relative files.
//   - Our SPA renders raw markdown through useDocs.ts/useMarkdown.ts with no
//     relative-path resolution — <router-link>-free rendered HTML needs
//     root-absolute "/api/typescript/..." paths (matching
//     generate-nav.mjs's slugify()) or the links 404 against vue-router.
//
// This only rewrites the entry point (readme.md) and any files it linked
// to that exist under out/ — it does not need to run recursively, because
// generate-nav.mjs / EXTRA_SECTIONS only exposes the entry point in nav;
// nested pages are still reachable by direct link even though unlisted.
import { readFileSync, writeFileSync, existsSync, readdirSync, statSync } from "node:fs";
import { fileURLToPath } from "node:url";
import path from "node:path";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const OUT_DIR = path.resolve(__dirname, "..", "..", "api", "typescript");

function walk(dir) {
  if (!existsSync(dir)) return [];
  return readdirSync(dir).flatMap((entry) => {
    const abs = path.join(dir, entry);
    return statSync(abs).isDirectory() ? walk(abs) : abs.endsWith(".md") ? [abs] : [];
  });
}

// Matches any non-absolute, non-external markdown link target ending in
// ".md" — TypeDoc emits both "./classes/Foo.md"-style and bare
// "classes/Foo.md"-style relative links depending on which page it's on.
const MD_LINK = /\]\(((?!https?:\/\/|mailto:|\/)[^()#]+?)\.md(#[^)]*)?\)/g;

function rewriteFile(absPath) {
  const raw = readFileSync(absPath, "utf-8");
  const dir = path.dirname(absPath);
  const rewritten = raw.replace(MD_LINK, (match, relTarget, hash = "") => {
    const targetAbs = path.resolve(dir, relTarget + ".md");
    if (!existsSync(targetAbs)) return match;
    const routePath = "/api/typescript/" + path.relative(OUT_DIR, targetAbs).replace(/\.md$/, "").replace(/\\/g, "/");
    return `](${routePath.replace(/\/readme$/, "")}${hash})`;
  });
  if (rewritten !== raw) writeFileSync(absPath, rewritten);
}

const files = walk(OUT_DIR);
files.forEach(rewriteFile);
console.log(`[fix-api-links] rewrote relative links in ${files.length} generated file(s) under ${path.relative(process.cwd(), OUT_DIR)}`);
