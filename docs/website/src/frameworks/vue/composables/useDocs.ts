// Bundles every Markdown file this site can navigate to as a raw-string
// import, lazily loaded per-route. Vite resolves this glob at build time, so
// adding a new page just works once it's listed in mkdocs.yml's nav (or
// scripts/generate-nav.mjs's EXTRA_SECTIONS) — no manual import needed here.
//
// The glob pattern's six ".." reach the repo root from this file's real
// location (composables/ -> vue/ -> frameworks/ -> src/ -> website/ -> docs/
// -> repo root). Because this file lives *inside* docs/ itself, Vite's glob
// keys — which are Node-style normalized relative paths — collapse exactly
// one "docs/" segment (and one ".." step) for every match that is itself
// under docs/, since going up through docs/ and back down into it cancels
// out. Files outside docs/ (README.md, core/README.md, ...) aren't affected.
// resolveKey() accounts for this by trying the source both as-is and with a
// leading "docs/" stripped.
const rawDocs = import.meta.glob("../../../../../../**/*.md", {
  query: "?raw",
  import: "default",
}) as Record<string, () => Promise<string>>;

function resolveKey(source: string): string | undefined {
  const candidates = source.startsWith("docs/") ? [source, source.slice("docs/".length)] : [source];
  for (const candidate of candidates) {
    const key = Object.keys(rawDocs).find((k) => k.endsWith("/" + candidate));
    if (key) return key;
  }
  return undefined;
}

export async function loadDoc(source: string): Promise<string | null> {
  const key = resolveKey(source);
  if (!key) return null;
  return rawDocs[key]();
}

export function docExists(source: string): boolean {
  return resolveKey(source) !== undefined;
}
