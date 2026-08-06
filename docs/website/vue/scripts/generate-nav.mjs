#!/usr/bin/env node
// Generates src/nav.generated.ts from two sources of truth:
//
//   1. ../../mkdocs.yml's `nav:` tree (docs/mkdocs.yml) — the curated
//      documentation portal shared with the MkDocs Material build. Sources
//      here are relative to docs_dir ("."), rewritten below to be
//      repo-root-relative (prefixed with "docs/") so useDocs.ts can resolve
//      every page — mkdocs-only and repo-wide alike — with one glob.
//   2. EXTRA_SECTIONS below — repo-wide guides that intentionally live
//      outside docs/ (contributor guide, infra runbooks, research write-ups)
//      and so aren't part of mkdocs's docs_dir. Hand-curated rather than a
//      full repo walk, to keep the nav deliberate rather than noisy.
//
// Never edit src/nav.generated.ts by hand — it's overwritten by this script
// (runs automatically before `dev`/`build` via the npm "pre*" hooks).

import { readFileSync, writeFileSync, readdirSync } from "node:fs";
import { fileURLToPath } from "node:url";
import path from "node:path";
import yaml from "js-yaml";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const DOCS_DIR = path.resolve(__dirname, "..", "..", "..");
const MKDOCS_YML = path.join(DOCS_DIR, "mkdocs.yml");
const OUT_FILE = path.join(__dirname, "..", "src", "nav.generated.ts");

// mkdocs.yml may carry PyYAML tags (!!python/name:..., !!python/object/apply:...)
// for markdown_extensions config we don't care about here. js-yaml can't
// register a wildcard tag, so strip any such tag down to a plain quoted
// string before parsing instead.
const sanitizeYaml = (text) => text.replace(/!!python\/\S+/g, (m) => JSON.stringify(m));

/** Repo-wide guides outside docs_dir — see module doc comment above. */
const EXTRA_SECTIONS = [
  {
    title: "Codebase Guides",
    children: [
      { title: "Repository Guide", source: "README.md" },
      { title: "Contributing", source: "git/CONTRIBUTING.md" },
      { title: "Shared Core", source: "core/README.md" },
      { title: "Game State Machine", source: "core/src/game-state-machine.md" },
      { title: "iOS Font Assets", source: "ios/MyGame/Resources/Fonts/README.md" },
      { title: "Development Container", source: ".devcontainer/README.md" },
    ],
  },
  {
    title: "Infrastructure",
    children: [
      { title: "Docker", source: "infra/docker/README.md" },
      { title: "Kubernetes", source: "infra/k8s/README.md" },
      { title: "Helm", source: "infra/helm/README.md" },
      { title: "Terraform", source: "infra/terraform/README.md" },
      { title: "Ansible", source: "infra/ansible/README.md" },
    ],
  },
  {
    title: "Research",
    children: [
      { title: "Tower Defense Market", source: "reports/Tower Defense Market Research.md" },
      { title: "Multiplayer Architecture", source: "research/Multiplayer Tower Defense Implementation.md" },
    ],
  },
];

function isExternal(target) {
  return /^https?:\/\//.test(target);
}

/** "moon/ROADMAP.md" -> "/moon/ROADMAP" ; "index.md" -> "/docs" (the docs-portal
 * landing page — "/" itself is reserved for the interactive design-hub
 * HomeView, see src/router.ts). */
function slugify(mdPath) {
  const noExt = mdPath.replace(/\.md$/, "");
  if (noExt === "index") return "/docs";
  return "/" + noExt;
}

function extractH1(absPath) {
  try {
    const text = readFileSync(absPath, "utf-8");
    const match = text.match(/^#\s+(.+)$/m);
    return match ? match[1].replace(/[*`]/g, "").trim() : null;
  } catch {
    return null;
  }
}

function titleFromFilename(name) {
  return name
    .replace(/\.md$/, "")
    .replace(/[-_]+/g, " ")
    .replace(/\b\w/g, (c) => c.toUpperCase());
}

/** Expand a bare directory nav entry (e.g. "adr/") into a section, sourced
 * from the directory's own *.md files (mkdocs' built-in behavior for a
 * nav value ending in "/"). */
function walkDirectory(title, dirValue) {
  const absDir = path.join(DOCS_DIR, dirValue);
  const files = readdirSync(absDir)
    .filter((f) => f.endsWith(".md"))
    .sort();
  const children = files.map((f) => {
    const rel = path.posix.join(dirValue, f);
    const abs = path.join(absDir, f);
    return {
      title: extractH1(abs) || titleFromFilename(f),
      kind: "md",
      path: slugify(rel),
      source: "docs/" + rel,
    };
  });
  return { title, kind: "section", children };
}

/** @returns {{title:string, path?:string, href?:string, kind:'md'|'section'|'external', children?:any[]}} */
function walk(node) {
  if (typeof node === "string") return null; // shouldn't happen at top level
  const [title, value] = Object.entries(node)[0];

  if (typeof value === "string") {
    if (isExternal(value)) {
      return { title, kind: "external", href: value };
    }
    if (value.endsWith("/")) {
      return walkDirectory(title, value);
    }
    return { title, kind: "md", path: slugify(value), source: "docs/" + value };
  }

  if (Array.isArray(value)) {
    return { title, kind: "section", children: value.map(walk).filter(Boolean) };
  }

  return null;
}

/** Extra-section entries only carry {title, source}; derive path/kind here. */
function walkExtra(section) {
  return {
    title: section.title,
    kind: "section",
    children: section.children.map((c) => ({
      title: c.title,
      kind: "md",
      path: "/repo/" + c.source.replace(/\.md$/, "").replace(/[^a-zA-Z0-9/_-]+/g, "-"),
      source: c.source,
    })),
  };
}

function flatten(items, acc = []) {
  for (const item of items) {
    if (item.kind === "section") {
      flatten(item.children, acc);
    } else if (item.kind !== "external") {
      acc.push({ title: item.title, path: item.path, source: item.source });
    }
  }
  return acc;
}

const raw = readFileSync(MKDOCS_YML, "utf-8");
const doc = yaml.load(sanitizeYaml(raw));
const mkdocsTree = (doc.nav || []).map(walk).filter(Boolean);
const extraTree = EXTRA_SECTIONS.map(walkExtra);

const navTree = [...mkdocsTree, ...extraTree];
const searchIndex = flatten(navTree);

// Fail fast in CI if two pages resolve to the same route.
const seenPaths = new Map();
for (const entry of searchIndex) {
  if (seenPaths.has(entry.path)) {
    throw new Error(
      `[generate-nav] duplicate route "${entry.path}": "${seenPaths.get(entry.path)}" and "${entry.source}"`
    );
  }
  seenPaths.set(entry.path, entry.source);
}

const banner = "// AUTO-GENERATED by scripts/generate-nav.mjs from ../mkdocs.yml — do not edit by hand.\n";
const body =
  `export interface NavLeaf {\n` +
  `  title: string;\n` +
  `  kind: "md";\n` +
  `  path: string;\n` +
  `  source: string;\n` +
  `}\n` +
  `export interface NavExternal {\n` +
  `  title: string;\n` +
  `  kind: "external";\n` +
  `  href: string;\n` +
  `}\n` +
  `export interface NavSection {\n` +
  `  title: string;\n` +
  `  kind: "section";\n` +
  `  children: NavNode[];\n` +
  `}\n` +
  `export type NavNode = NavLeaf | NavExternal | NavSection;\n\n` +
  `export const navTree: NavNode[] = ${JSON.stringify(navTree, null, 2)};\n\n` +
  `export const searchIndex: { title: string; path: string; source: string }[] = ${JSON.stringify(
    searchIndex,
    null,
    2
  )};\n`;

writeFileSync(OUT_FILE, banner + body);
console.log(`[generate-nav] wrote ${path.relative(process.cwd(), OUT_FILE)} (${searchIndex.length} pages)`);
