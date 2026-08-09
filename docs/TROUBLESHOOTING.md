# Troubleshooting Guide

*Last updated: 2026-08-06. Covers Android/Gradle build failures, the Dev Container, iOS/Xcode build failures (macOS host required), CI, and the `docs/website` documentation site. See [`docs/DEVELOPMENT.md`](DEVELOPMENT.md) for first-time setup and [`.agent/rules/`](https://github.com/ACFHarbinger/Project-Mobile-Fortress/tree/main/.agent/rules) for the coding conventions these failures usually trace back to.*

---

## Table of Contents

- [Android / Gradle](#android-gradle)
- [Dev Container](#dev-container)
- [iOS / Xcode](#ios-xcode)
- [GitHub Actions CI](#github-actions-ci)
- [Documentation Site (`docs/website`)](#documentation-site-docswebsitevue)
- [Game Loop / Frame-Drop Symptoms](#game-loop-frame-drop-symptoms)
- [Getting Further Help](#getting-further-help)

---

## Android / Gradle

### `./gradlew` fails with "SDK location not found"

`local.properties` is git-ignored and must be created locally (or by Android Studio on first project open):

```properties
sdk.dir=/path/to/Android/sdk
```

In the Dev Container this is templated automatically from `ANDROID_HOME` — see `.devcontainer/README.md` if it's missing.

### Gradle sync fails after pulling a branch that touched `gradle/libs.versions.toml`

Stop the Gradle daemon and retry — a stale daemon sometimes holds an old version catalog in memory:

```bash
./gradlew --stop
./gradlew build
```

### `ktlintCheck` / `lint` fails in CI but passes locally

CI runs against a clean checkout with no local Gradle caches or IDE-applied formatting. Run the exact CI commands before pushing:

```bash
just lint-check   # ./gradlew lint ktlintCheck
```

`ktlintFormat` auto-fixes most style violations; Android Lint findings (unused resources, missing content descriptions) need manual fixes.

### `connectedDebugAndroidTest` hangs or times out

- Confirm an emulator or device is actually attached: `adb devices`.
- Emulator boots but tests never start: cold-boot the AVD once (`emulator -avd <name> -no-snapshot-load`) — a corrupted snapshot is the most common cause of an emulator that boots visually but never responds to `adb`.
- In CI, this runs against the `android-emulator-runner` matrix in `ci.yml`; a red run here with no other Android job failures usually means an emulator API-level/target mismatch — check the job's `api-level` input against `android/app/build.gradle.kts`'s `compileSdk`/`targetSdk`.

### `SurfaceHolder.lockCanvas()` returns `null` / app crashes on rotation

This is the documented `GameLoop` lifecycle hazard, not a build problem — see [`.agent/rules/android_lifecycle.md`](https://github.com/ACFHarbinger/Project-Mobile-Fortress/blob/main/.agent/rules/android_lifecycle.md) and [`.agent/rules/game_loop_performance.md`](https://github.com/ACFHarbinger/Project-Mobile-Fortress/blob/main/.agent/rules/game_loop_performance.md). The loop thread must stop in `surfaceDestroyed` and restart in `surfaceCreated`; a leaked thread across a rotation is the #1 cause of this crash class.

---

## Dev Container

### Android SDK / emulator image missing inside the container

The Dev Container (`.devcontainer/devcontainer.json`) provisions the Android SDK cmdline-tools, JDK 17, and one emulator system image on first build — this can take several minutes and requires network access on first create. If a rebuild seems to have skipped provisioning, check the container build log for the `postCreateCommand` step, and see `.devcontainer/README.md` for the exact packages installed.

### iOS work is impossible inside the container

This is expected, not a bug — the Dev Container is Linux-only (Android toolchain only). iOS/Xcode builds require a native macOS host or a `macos-latest` CI runner; see [`.agent/AGENTS.md`](https://github.com/ACFHarbinger/Project-Mobile-Fortress/blob/main/.agent/AGENTS.md) §7 "Known Constraints".

---

## iOS / Xcode

### `xcodebuild` commands fail immediately with "no such SDK" or similar

`just ios-build` / `just ios-test` / `just ios-check` / `just ios-archive` all shell out to `xcodebuild`, which only exists on macOS with Xcode installed — these recipes cannot run in the Linux Dev Container or on GitHub's Linux runners. Run them on a macOS host, or rely on the `macos-latest` `ios` job in `ci.yml`.

### `xcodebuild test` can't find the `MyGame` scheme

The shared scheme lives at `ios/MyGame.xcodeproj/xcshareddata/xcschemes/MyGame.xcscheme` and must be checked in (Xcode schemes are user-local by default unless explicitly shared) — confirm it wasn't accidentally reverted to user-local in a merge.

### Simulator tests are flaky / time out

Prefer a pinned simulator runtime over "generic/platform=iOS Simulator" when debugging locally so you're not fighting a moving target:

```bash
xcodebuild test -project ios/MyGame.xcodeproj -scheme MyGame \
  -destination 'platform=iOS Simulator,name=iPhone 15,OS=17.5'
```

### App doesn't pause/save state on backgrounding

See [`.agent/workflows/ios_lifecycle.md`](https://github.com/ACFHarbinger/Project-Mobile-Fortress/blob/main/.agent/workflows/ios_lifecycle.md) — `GameScene`/`AppDelegate` must pause gameplay and persist state on backgrounding; the OS can kill the app at any time without a `applicationWillTerminate` guarantee.

---

## GitHub Actions CI

### `ci.yml`'s Android job set is green but the iOS job is skipped

The iOS job only runs on `macos-latest` runners and is gated the same way locally-run `xcodebuild` commands are — check the job's `if:` condition and runner label if it's unexpectedly skipped on a PR from a fork (fork PRs may have reduced runner access depending on repository settings).

### `docs.yml` fails on the "Vue website" build step

See [Documentation Site](#documentation-site-docswebsitevue) below — this is almost always a `nav.generated.ts` regeneration or `npm ci` lockfile-drift issue, not a real content problem.

### `release.yml` fails at signing

Signing credentials are intentionally never committed — the workflow expects `ANDROID_KEYSTORE_BASE64`/related secrets to be configured at the repository level. A failure here on a fork is expected (forks don't inherit secrets); on the upstream repo, check that the secrets haven't expired or been rotated without updating the workflow.

---

## Documentation Site (`docs/website`)

### `npm run build` fails with "Cannot find module '.../nav.generated.ts'" or stale nav content

`src/frameworks/vue/nav.generated.ts` is generated, not hand-written — run the generator directly if the `pre*` npm hooks didn't fire (e.g. you ran `vite build` instead of `npm run build`):

```bash
# from the repository root
node docs/website/scripts/generate-nav.mjs
# or: cd docs/website && node scripts/generate-nav.mjs
```

### Generator throws "duplicate route"

Two nav entries resolved to the same URL path — usually a copy-pasted `mkdocs.yml` nav entry, or a new page under `docs/adr/` whose filename collides with an existing slug after the `.md` extension is stripped. Rename one of the source files or adjust the nav entry.

### A new page under `docs/**/*.md` doesn't show up in the site

Pages come from two places (see `scripts/generate-nav.mjs`'s module doc comment): `docs/mkdocs.yml`'s `nav:` tree, or the hand-curated `EXTRA_SECTIONS` list in the generator script for repo-wide guides that live outside `docs/`. A new file under `docs/` needs an entry added to `mkdocs.yml`'s `nav:`; a new *outside* `docs/` (e.g. another module `README.md`) needs an entry added to `EXTRA_SECTIONS`.

### Mermaid diagrams or KaTeX math don't render

Both render client-side after the Markdown is injected into the DOM — check the browser console for a Mermaid/KaTeX parse error in the source diagram/formula itself (most common cause) before suspecting the site's rendering pipeline in `src/composables/useMarkdown.ts`.

### `npm run dev` can't read a file "outside of Vite serving allow list"

`vite.config.ts`'s `server.fs.allow` is intentionally scoped to the repo root (four levels up from `docs/website/`) so the dev server can serve `docs/**/*.md` and the curated repo-wide guides — if you've restructured the site's directory nesting, that path needs updating too.

---

## Game Loop / Frame-Drop Symptoms

These aren't build failures but are common enough to document here rather than re-derive per incident. See [`.agent/rules/game_loop_performance.md`](https://github.com/ACFHarbinger/Project-Mobile-Fortress/blob/main/.agent/rules/game_loop_performance.md) for the full rules and anti-pattern examples; short version:

| Symptom | Usual cause |
| --- | --- |
| Periodic stutter that gets worse over a play session | Per-frame allocation in the update/render hot path — triggers GC (Android) / ARC churn (iOS) pauses. Profile allocations first, not raw compute. |
| One huge stutter after backgrounding/resuming or a debugger pause | Missing catch-up cap (Android accumulator) or missing delta clamp (iOS `update(_:)`) — the loop tries to simulate minutes of missed time in one step. |
| Crash immediately after rotating the device (Android only) | `GameLoop` thread not stopped/restarted correctly across `surfaceDestroyed`/`surfaceCreated`. |

---

## Getting Further Help

1. Check [`docs/ARCHITECTURE.md`](ARCHITECTURE.md) and the relevant [`docs/adr/`](adr/0001-record-architecture-decisions.md) record — the issue may be a known, deliberate tradeoff.
2. Search [`docs/moon/CHANGELOG.md`](moon/CHANGELOG.md) for whether the affected area has shipped yet — several systems described in [`docs/moon/ROADMAP.md`](moon/ROADMAP.md) are still pre-implementation (see [`.agent/AGENTS.md`](https://github.com/ACFHarbinger/Project-Mobile-Fortress/blob/main/.agent/AGENTS.md) §7 "Known Constraints").
3. Open a GitHub issue with the exact command, full error output, and platform (OS, Android API level / iOS+Xcode version, or "Dev Container").
