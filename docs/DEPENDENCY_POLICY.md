# Dependency Policy

*Last updated: 2026-08-06. Minimum version requirements, pinning policy, upgrade cadence, and the process for introducing a new dependency, across every stack this repository touches today (Android/Kotlin, iOS/Swift, the `docs/website/vue` Node/TypeScript site, the optional `infra/` backend) and the one it's converging on ([`docs/moon/roadmaps/shared_core.md`](moon/roadmaps/shared_core.md)'s Rust simulation core).*

---

## Table of Contents

- [Version Requirements](#version-requirements)
- [Pinning Policy](#pinning-policy)
- [Upgrade Cadence](#upgrade-cadence)
- [Introducing a New Dependency](#introducing-a-new-dependency)
- [Removing a Dependency](#removing-a-dependency)
- [Security Vulnerabilities](#security-vulnerabilities)
- [Per-Stack Notes](#per-stack-notes)

---

## Version Requirements

| Stack | Runtime | Minimum Version | Rationale |
| --- | --- | --- | --- |
| Kotlin | Android | 2.0.20 | Current `kotlin-android` plugin baseline, see [`.agent/AGENTS.md`](../.agent/AGENTS.md) §2 |
| Android Gradle Plugin (AGP) | Android | 8.5.2 | `com.android.application` baseline |
| Gradle | Android | 8.7 (wrapper-pinned) | Always invoke via `./android/gradlew`, never a bare `gradle` |
| Android SDK | Android | compileSdk/targetSdk 35, minSdk 24 | ~97% device coverage as of 2026; see [`.agent/AGENTS.md`](../.agent/AGENTS.md) §2 |
| Swift | iOS | 5.0 | `ios/MyGame.xcodeproj` baseline |
| iOS / Xcode | iOS | iOS 16+ deployment target | SpriteKit + SwiftUI chrome baseline |
| Node.js | `docs/website/vue` | 20 LTS | Matches `actions/setup-node@v4`'s `node-version` in `.github/workflows/docs.yml` |
| npm | `docs/website/vue` | 10+ (ships with Node 20) | `package-lock.json` v3 lockfile format |
| Rust | Shared core (planned) | 1.75+ | `hecs` ECS + `rkyv` zero-copy serialization baseline once [`shared_core.md`](moon/roadmaps/shared_core.md) lands |
| Python | `docs/mkdocs.yml` (local `mkdocs serve` only) | 3.12 | Matches `actions/setup-python@v5`'s pin in historical `docs.yml` revisions |

---

## Pinning Policy

### Android (`gradle/libs.versions.toml`)

- All Gradle dependency versions live in the version catalog (`android/gradle/libs.versions.toml`), never hardcoded inline in a `build.gradle.kts` — see [`.agent/rules/kotlin.md`](../.agent/rules/kotlin.md).
- The Gradle wrapper (`android/gradle/wrapper/gradle-wrapper.properties`) pins the exact Gradle distribution; AGP's version must stay within that Gradle version's supported range (check the [AGP/Gradle compatibility matrix](https://developer.android.com/studio/releases/gradle-plugin#updating-gradle) before bumping either independently).

### iOS (Swift Package Manager)

- Prefer Swift Package Manager over CocoaPods for any new dependency — SPM resolves reproducibly from `Package.resolved` without a separate `pod install` step. This project has no CocoaPods `Podfile` today; keep it that way unless a dependency genuinely requires it.
- `Package.resolved` (once any SPM dependency is added) must be committed — it's the iOS equivalent of a lockfile.

### `docs/website/vue` (`package-lock.json`)

- `package-lock.json` is committed and is the authoritative pin for `npm ci` in CI (`.github/workflows/docs.yml`'s `docs-website` job runs `npm ci`, never `npm install`, so it fails loudly on lockfile drift instead of silently re-resolving).
- `package.json` uses `^` (caret) ranges for all dependencies — Vue, Vue Router, `markdown-it` and its plugins, `highlight.js`, `mermaid`, and KaTeX are all still pre-1.0-breakage-sensitive enough that patch/minor bumps should go through the normal `npm update` + test cycle rather than being pinned exact.

### Rust (planned — `Cargo.lock`)

- Once the shared core lands, `Cargo.lock` will be committed for the workspace, per this org's standard binary/library-with-FFI-boundary convention. `Cargo.toml` will use `^` (caret) requirements; UniFFI's generated bindings are sensitive to the `uniffi` crate's minor version matching exactly between the Rust side and the generated Kotlin/Swift — pin `uniffi` itself with `=` once adopted.

---

## Upgrade Cadence

| Category | Response time | Process |
| --- | --- | --- |
| **Security patch** (CVE, high severity) | Within 7 days | Direct PR, expedited review; run `npm audit` / Android Lint's dependency-vulnerability checks / `dependabot.yml`'s auto-PR as applicable. |
| **Security patch** (CVE, low/moderate severity) | Within 30 days | Normal PR process; batched with the next routine bump if one is already in flight. |
| **Minor version** (new features, backwards-compatible) | As Dependabot proposes | `.github/dependabot.yml` opens PRs automatically for Gradle, npm (`docs/website/vue`), and GitHub Actions — review and merge rather than bumping by hand. |
| **Major version** (breaking changes) | With a migration plan | Dedicated branch, full `just lint-check` / `just unit-test` / `docs-website` build passing, breaking changes called out in [`docs/moon/CHANGELOG.md`](moon/CHANGELOG.md). |
| **AGP / Gradle wrapper** | Coordinated bump | Update both together per the compatibility matrix; re-run the full Android CI matrix before merging. |
| **Xcode / iOS deployment target** | With a documented reason | Requires updating the ADR trail if it changes the rendering-approach tradeoffs recorded in [ADR 0003](adr/0003-ios-rendering-approach.md). |

---

## Introducing a New Dependency

Before adding any new package, answer:

1. **Is it already available?** `docs/website/vue` already covers Markdown rendering (`markdown-it`), syntax highlighting (`highlight.js`), diagrams (`mermaid`), and math (`katex`) — check before reaching for an alternative that duplicates one of these.
2. **What is the maintenance status?** Prefer packages with a release in the last 12 months and a responsive issue tracker.
3. **What is the transitive footprint?** For Android/Kotlin: check the dependency's own transitive graph doesn't pull in a second copy of Kotlin coroutines or a conflicting AndroidX version. For `docs/website/vue`: run `npm ls <package>` after installing to inspect what it pulled in.
4. **Does it have a compatible license?** Permitted: MIT, Apache-2.0, BSD-2/3, MPL-2.0, ISC. Avoid GPL/AGPL/SSPL for anything linked into a shipped client or the docs site.
5. **Is there a security history?** Check [osv.dev](https://osv.dev/) before adding, especially for anything touching the optional `infra/` backend's dependency surface.

Once approved: add to the correct manifest (`android/gradle/libs.versions.toml`, `docs/website/vue/package.json`, or the relevant `infra/` module), regenerate the lockfile, and document the addition in [`docs/moon/CHANGELOG.md`](moon/CHANGELOG.md).

---

## Removing a Dependency

1. Verify no code paths still reference it (`grep -r` across `android/app/src/`, `ios/MyGame/`, or `docs/website/vue/src/` as applicable).
2. Remove it from the manifest and regenerate the lockfile (`./android/gradlew --refresh-dependencies`, or `npm install` inside `docs/website/vue`).
3. Run the relevant test suite (`just unit-test`, `just ios-test`, or `docs/website/vue`'s `npm run build`).
4. Document the removal in [`docs/moon/CHANGELOG.md`](moon/CHANGELOG.md).

---

## Security Vulnerabilities

- `.github/dependabot.yml` covers Gradle, npm (`docs/website/vue`), and GitHub Actions version bumps, including security advisories.
- For `docs/website/vue`, run `npm audit --audit-level=moderate` locally before a release-adjacent change.
- If a vulnerability can't be patched within the SLA above (e.g. no upstream fix yet), document it inline as a code comment at the dependency's declaration site with the CVE ID and a target re-check date, and note it in [`docs/moon/CHANGELOG.md`](moon/CHANGELOG.md) under an "Known Issues" entry.

---

## Per-Stack Notes

### Android

- Keep Jetpack Compose (used for menu/HUD chrome only, per [`.agent/AGENTS.md`](../.agent/AGENTS.md) §1.1) on the BOM version aligned with the pinned Kotlin version — mismatches are a common source of opaque compiler errors.
- `SurfaceView`/`GameLoop` deliberately has zero third-party dependencies — see [`.agent/rules/game_loop_performance.md`](../.agent/rules/game_loop_performance.md) for why a hand-rolled thread beats pulling in a game-loop library here.

### iOS

- SpriteKit and SwiftUI are both first-party frameworks — no external rendering dependency is expected on this platform per [ADR 0003](adr/0003-ios-rendering-approach.md).
- If a dependency is ever added for netcode (once [`backend.md`](moon/roadmaps/backend.md) work starts), prefer one with an `async`/`await` API surface over a callback-based one, matching the rest of the iOS codebase's concurrency style.

### `docs/website/vue`

- `mermaid` and `katex` are both lazy-loaded per-page (dynamic `import()`), not bundled into the initial chunk — keep new heavy rendering dependencies lazy the same way rather than adding to the main bundle's parse/execute cost.
- `highlight.js`'s language grammars are registered individually (`highlight.js/lib/core` + explicit `registerLanguage` calls) rather than importing the "all languages" bundle, to keep the bundle small — add a new language registration rather than switching to the full bundle.

### Shared Rust core (planned)

- `hecs` and `rkyv` are the decided choices per [`shared_core.md`](moon/roadmaps/shared_core.md) and the underlying research in [`research/Multiplayer Tower Defense Implementation.md`](../research/Multiplayer%20Tower%20Defense%20Implementation.md) — don't introduce a competing ECS or serialization crate without a new ADR superseding that decision.
