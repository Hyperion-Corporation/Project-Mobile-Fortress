// Loads the body of any Markdown page this site can navigate to, keyed by
// the same `source` string nav.generated.ts's searchIndex entries carry
// (e.g. "docs/foo.md", "README.md", "game/README.md").
//
// docs-content.generated.ts is produced by scripts/generate-nav.mjs (see its
// "doc content manifest" section) as a static map of per-file `import()`
// calls — deliberately not Vite's `import.meta.glob()`, which has no
// equivalent under webpack (the stack/next/ surface) and threw a runtime
// "{}.glob is not a function" there. Both Vite and webpack code-split plain,
// literal `import()` calls natively, so this works identically on both.
import { docsContent } from "../docs-content.generated";

export async function loadDoc(source: string): Promise<string | null> {
  const loader = docsContent[source];
  if (!loader) return null;
  return loader();
}

export function docExists(source: string): boolean {
  return source in docsContent;
}
