# Documentation Standards

*Last updated: 2026-08-06. Required doc-comment styles per language, Markdown conventions, and where a given kind of fact belongs. Complements [`.agent/rules/documentation.md`](../.agent/rules/documentation.md) (the authoritative, terse version an AI coding assistant reads) with the fuller rationale for humans.*

---

## Table of Contents

- [General Principles](#general-principles)
- [Kotlin (KDoc)](#kotlin-kdoc)
- [Swift (DocC)](#swift-docc)
- [TypeScript / Vue (`docs/website/vue`)](#typescript--vue-docswebsitevue)
- [Markdown Files](#markdown-files)
- [Where a Fact Belongs](#where-a-fact-belongs)
- [Enforcement](#enforcement)

---

## General Principles

1. **Document the why, not the what.** A well-named function or class already says what it does; a doc comment earns its place only when it explains a non-obvious constraint, an invariant, or a piece of domain knowledge (e.g. why the `GameLoop` uses a plain `Thread` instead of coroutines — see [`.agent/rules/kotlin.md`](../.agent/rules/kotlin.md)) that can't be inferred from the signature.
2. **One source of truth.** If a fact could live in a doc comment or a separate Markdown doc, put it in exactly one place and link the other to it, rather than duplicating and letting the copies drift.
3. **Docs mirror what's actually built.** [`docs/index.md`](index.md) and `README.md` describe what exists today; unfinished systems are marked `> **TODO:**` rather than written as if shipped — see [`.agent/AGENTS.md`](../.agent/AGENTS.md) §7 "Known Constraints" for the current example.
4. **Incremental coverage.** Don't block a PR over missing doc comments in code it doesn't touch — focus on new or substantially modified public APIs.

---

## Kotlin (KDoc)

Every new public class/function under `android/app/src/main/java/com/acfharbinger/mobilefortress/engine/` and `ui/` needs a KDoc comment (per [`.agent/AGENTS.md`](../.agent/AGENTS.md) §5).

### Format

```kotlin
/**
 * Recomputes the Flow Field vector grid from the current tower/obstacle layout.
 *
 * Runs a single grid-wide Dijkstra pass from the goal cell outward — see
 * [docs/moon/roadmaps/gameplay.md] for the algorithm this mirrors from the
 * planned C++ core. Safe to call every frame a placement changes; it is
 * *not* safe to call from the render path (see [game_loop_performance.md]).
 *
 * @param grid the current traversal-cost grid, mutated in place.
 * @return the recomputed per-cell direction vectors.
 */
fun recomputeFlowField(grid: CostGrid): VectorField { ... }
```

- First line: short imperative summary.
- Blank line, then body prose explaining *why*, with `[brackets]` cross-references to other symbols or docs where useful.
- `@param`/`@return` only when the parameter/return value isn't self-explanatory from its name and type.
- No restating the type signature in prose.

### Enforcement

`ktlintCheck` catches formatting; missing KDoc on new public APIs is a review-time check, not (yet) an automated gate — see [`.agent/rules/code_review.md`](../.agent/rules/code_review.md) severity tiers (MEDIUM: "Missing KDoc/doc-comments on public `engine/`/`Engine/`-equivalent classes").

---

## Swift (DocC)

Every new public type/function under `ios/MyGame/Engine/`, `ios/MyGame/Core/`, and `ios/MyGame/Scenes/` needs a `///` doc comment (DocC-compatible).

### Format

```swift
/// Clamps the per-frame delta before advancing gameplay state.
///
/// SpriteKit already drives `update(_:)` off the display link, so there is
/// no hand-rolled accumulator to write — but an unclamped delta after a
/// backgrounding gap or a debugger pause would simulate minutes of missed
/// time in one call. Mirrors Android's catch-up cap; see
/// `game_loop_performance.md`.
///
/// - Parameter rawDelta: unclamped seconds since the previous frame.
/// - Returns: `rawDelta` clamped to `GameConstants.maxFrameDelta`.
func clampedDelta(_ rawDelta: TimeInterval) -> TimeInterval { ... }
```

- `///` triple-slash comments, not `/** ... */` block comments — matches Xcode's Quick Help and DocC rendering.
- `- Parameter`/`- Returns` markers only when non-obvious.
- No force-unwraps (`!`) in example code within doc comments — they're read as implicitly endorsed style (see [`.agent/rules/swift.md`](../.agent/rules/swift.md)).

---

## TypeScript / Vue (`docs/website/vue`)

- Exported functions in `src/composables/*.ts` get a `/** ... */` TSDoc-style comment when their behavior isn't obvious from the name and type signature — `useMarkdown.ts`'s `extractToc`/`renderMarkdown`, for example, are self-explanatory and don't need one; `resolveHref`-style link-resolution logic (if reintroduced) would.
- `.vue` Single-File Components use `<script setup lang="ts">` — prefer well-named `computed`/functions over comments explaining what a block of template markup does.
- `scripts/generate-nav.mjs` is the one file in this stack that *does* carry a substantial header comment, because it encodes a non-obvious two-source-of-truth design (`mkdocs.yml` nav + hand-curated `EXTRA_SECTIONS`) that isn't inferable from the code alone.

---

## Markdown Files

- **Title + one-line context.** Every doc under `docs/` starts with an `# H1` title; long-lived reference docs (this one, `TROUBLESHOOTING.md`, `DEPENDENCY_POLICY.md`, `BENCHMARKS.md`) follow it with an italicized "Last updated: YYYY-MM-DD. \<one-sentence scope\>" line so staleness is visible at a glance.
- **Table of contents for anything past ~100 lines.** Manually maintained (no TOC-generation tooling in this repo) — keep it in sync when adding/removing a `##` heading.
- **Relative links, repo-root-relative when crossing top-level directories.** Prefer `[text](../other/file.md)` over an absolute GitHub URL when linking within the repository — the [`docs/website/vue`](website/vue/) site and GitHub's own file browser both resolve these correctly; absolute `github.com/...` URLs are reserved for linking to a *specific commit/blob* (e.g. the "Edit on GitHub" link the docs site generates) or to another repository entirely.
- **Mermaid for diagrams, not ASCII art, when the diagram has more than ~4 nodes.** Both [`docs/mkdocs.yml`](mkdocs.yml) (via `mkdocs serve`) and `docs/website/vue` render Mermaid fences (` ```mermaid `) live.
- **`$...$` / `$$...$$` for math**, rendered via KaTeX in `docs/website/vue` — used throughout [`docs/design/game_design_document.md`](design/game_design_document.md) for the Flow Field, DDA, and monetization-bandit formulas.

---

## Where a Fact Belongs

| Kind of fact | Lives in |
| --- | --- |
| A module boundary or responsibility split | [`docs/ARCHITECTURE.md`](ARCHITECTURE.md) |
| A significant, hard-to-reverse decision (rendering approach, save-format, backend adoption) | A new [`docs/adr/`](adr/) record |
| Shipped, user-visible change | [`docs/moon/CHANGELOG.md`](moon/CHANGELOG.md) |
| Planned, not-yet-built work | The relevant [`docs/moon/roadmaps/*.md`](moon/roadmaps/) |
| Project-specific terminology | [`docs/GLOSSARY.md`](GLOSSARY.md) |
| A recurring build/runtime failure and its fix | [`docs/TROUBLESHOOTING.md`](TROUBLESHOOTING.md) |
| A dependency version constraint or upgrade rule | [`docs/DEPENDENCY_POLICY.md`](DEPENDENCY_POLICY.md) |
| Game design intent (setting, units, economy, aesthetics) | [`docs/design/`](design/) |

---

## Enforcement

- `ktlintCheck` / `lint` (Android) and Xcode's build warnings (iOS) catch formatting issues but not doc-comment *presence* — that's a code-review-time check per [`.agent/rules/code_review.md`](../.agent/rules/code_review.md).
- `docs/website/vue`'s `npm run build` runs `vue-tsc` type-checking, which indirectly catches TSDoc `@param`/`@returns` tags that no longer match a changed signature.
- `scripts/generate-nav.mjs` fails the `docs-website` CI job outright on a duplicate route or a `mkdocs.yml` nav entry pointing at a missing file — a structural check, not a prose-quality one.
