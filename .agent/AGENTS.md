# AGENTS.md - Instructions for Coding Assistant LLMs

[![Kotlin](https://img.shields.io/badge/Kotlin-2.0-7F52FF?logo=kotlin&logoColor=white)](https://kotlinlang.org/)
[![Android](https://img.shields.io/badge/Android-API_24%2B-3DDC84?logo=android&logoColor=white)](https://developer.android.com/)
[![Swift](https://img.shields.io/badge/Swift-5.0-F05138?logo=swift&logoColor=white)](https://swift.org/)
[![iOS](https://img.shields.io/badge/iOS-16%2B-000000?logo=apple&logoColor=white)](https://developer.apple.com/ios/)
[![Just](https://img.shields.io/badge/Just-Task_Runner-000000?logoColor=white)](https://github.com/casey/just)
[![CI](https://github.com/ACFHarbinger/Mobile-Game-Template/actions/workflows/ci.yml/badge.svg)](https://github.com/ACFHarbinger/Mobile-Game-Template/actions/workflows/ci.yml)

> **Version**: 2.0
> **Last Updated**: 2026-08-03
> **Purpose**: Authoritative reference for AI assistants (Claude, GPT, Gemini, Copilot, etc.) working in repositories generated from this template.

## Table of Contents

1. [Project Overview & Mission](#1-project-overview--mission)
2. [Technical Stack & Governance](#2-technical-stack--governance)
3. [Module Boundaries](#3-module-boundaries)
4. [Key CLI Entry Points](#4-key-cli-entry-points)
5. [Coding Standards](#5-coding-standards)
6. [AI Review & Severity Protocol](#6-ai-review--severity-protocol)
7. [Known Constraints](#7-known-constraints)

## 1. Project Overview & Mission

> **TODO:** Replace with a one-paragraph description of the actual game once this template seeds a real project.

This repository is a scaffold for a **two-platform mobile game**: a Kotlin Android client (`android/`) and a Swift iOS client (`ios/`), not a product. Each ships a single, real product module — minimal but functional 2D game skeletons (Android: `SurfaceView` + a fixed-timestep loop thread; iOS: SpriteKit's `SKScene`) — plus the cross-cutting agentic/DevOps/docs framework shared across this org's other templates (`.agent/`, `docs/`, `moon/`, `.github/`, `infra/`). A `core/` module holds shared raw assets and a documented (not compiled) state-machine/level spec both clients implement independently — see [`core/README.md`](../core/README.md) before assuming any logic is actually shared. When used via "Use this template", update this section first.

### 1.1 Why SurfaceView + Canvas (Android) / SpriteKit (iOS), not Compose-only, SwiftUI-only, or a game engine

This template targets **simple, dependency-light 2D games** (arcade, puzzle, roguelike-lite) on each platform independently — it is **not** a shared cross-platform engine (see `moon/roadmaps/shared_core.md` for that option, not adopted by default). Each client uses its platform's idiomatic, zero-extra-dependency 2D approach, decoupled from its declarative-UI framework's recomposition/re-render timing:

| If your game needs... | Consider instead |
| --- | --- |
| Menus, HUD, settings screens, leaderboards UI | Keep those in Jetpack Compose (Android, [`ui_compose.md`](rules/ui_compose.md)) / SwiftUI (iOS, [`swift.md`](rules/swift.md)) layered *around* the game surface — this template already does this for the main menu on both platforms. |
| 3D rendering, physics engine, or a genuinely shared cross-platform codebase | [LibGDX](https://libgdx.com/)/[Godot](https://godotengine.org/) (Android), or revisit `moon/roadmaps/shared_core.md`'s KMP/Rust options — swap the platform-native surface/loop for the engine's own and keep everything else in this template (`.agent/`, CI, docs, infra). |
| Compose-only / SwiftUI-only rendering (shaders via `Canvas`/`Modifier.drawWithCache`, or SwiftUI `Canvas`) | Viable for lower-frequency/simpler games; see [ADR 0002](../docs/adr/0002-rendering-approach.md) (Android) and [ADR 0003](../docs/adr/0003-ios-rendering-approach.md) (iOS) for the tradeoffs we weighed on each platform. |

## 2. Technical Stack & Governance

| Component | Specification | Notes |
| --- | --- | --- |
| Kotlin | 2.0.20 | `kotlin-android` plugin, JVM target 17 (`android/`) |
| Android Gradle Plugin (AGP) | 8.5.2 | `com.android.application` |
| Gradle | 8.7 (wrapper-pinned) | Always invoke via `./android/gradlew`, never a bare `gradle` |
| compileSdk / targetSdk | 35 (Android 15) | |
| minSdk | 24 (Android 7.0) | ~97% device coverage as of 2026 |
| Android UI toolkit | Views (`SurfaceView`) for the game surface, Jetpack Compose for menus/HUD chrome | See §1.1 |
| Swift | 5.0 | `ios/MyGame.xcodeproj`, iOS 16+ deployment target |
| iOS UI toolkit | SpriteKit for the game surface, SwiftUI for menus/HUD chrome | See §1.1 — requires a macOS host to build, see `.devcontainer/README.md` |
| Build variants | Android: `debug`, `release` (minified + resource-shrunk, R8); iOS: `Debug`, `Release` | |
| Config | `android/local.properties` (git-ignored, SDK path + signing refs), `.env.example` for optional backend | |

## 3. Module Boundaries

- `android/app/src/main/java/com/example/gametemplate/` — the Android product module. Structured as:
  - `MainActivity.kt` — hosts the `GameView`, wires lifecycle to the game loop.
  - `GameView.kt` — `SurfaceView` + `SurfaceHolder.Callback`, owns the `GameLoop` thread.
  - `GameLoop.kt` — fixed-timestep loop thread (update/render separation), independent of any Android UI class beyond the `SurfaceHolder` it's given.
  - `engine/` — `GameEngine.kt` (update/draw orchestration), `GameState.kt` (save/restore state), `entities/` (game objects). No `android.app.Activity`/`Context` UI calls inside `engine/` beyond what's needed for asset/resource loading — keep it testable in a plain JVM unit test where possible.
  - `ui/` — optional Compose screens (main menu, pause, settings) that sit *outside* the `SurfaceView`, never mixed into the render loop.
- `ios/MyGame/` — the iOS product module. Structured as:
  - `App/` — `MyGameApp.swift` (SwiftUI `@main`), `AppDelegate.swift` (background/terminate hooks).
  - `Core/` — `GameManager.swift` (state machine), `Constants.swift`, `Extensions/`.
  - `Engine/` — `Audio/`, `Input/`, `Physics/`, `Storage/` — framework-light where possible, independently testable (see `ios/Tests/`).
  - `Scenes/` — `GameLevel/GameScene.swift` (the `SKScene`), `MainMenu/`, `GameOver/` (SwiftUI screens), `Nodes/` (`SKSpriteNode` subclasses).
  - `UI/` — SwiftUI chrome (`HUD/`, `Shop/`, `Theme/`) that sits *outside* the SpriteKit scene, never mixed into the render loop.
  - `Resources/` — `Levels/` (JSON referenced from `core/assets/levels/`, not duplicated), `Fonts/` (empty by default, see its `README.md`).
- `core/` — shared raw assets (`assets/`) and a documented, non-compiled spec (`src/`) for level data and the state-machine shape. See [`core/README.md`](../core/README.md) — do not assume anything in `core/src/` is compiled/linked into either app.
- Cross-module contracts (an optional backend's REST/WebSocket API) live under `docs/` — see [`docs/ARCHITECTURE.md`](../docs/ARCHITECTURE.md) — not duplicated in code comments.
- `infra/` describes an **optional** lightweight backend (leaderboards/cloud save) — a purely offline game needs none of it. See `infra/*/README.md`.

## 4. Key CLI Entry Points

| Command | Purpose | Platform |
| --- | --- | --- |
| `just --list` | List all available command-runner recipes | both |
| `just apk` | `./android/gradlew assembleDebug` | Android |
| `just unit-test` | Unit tests (`./android/gradlew testDebugUnitTest`) | Android |
| `just test-instrumented` | Instrumented tests on a connected device/emulator (`./android/gradlew connectedDebugAndroidTest`) | Android |
| `just lint-check` | `./android/gradlew lint ktlintCheck` | Android |
| `just assemble-release` | `./android/gradlew bundleRelease` (signed App Bundle for Play Store) | Android |
| `just install` | `./android/gradlew installDebug` onto a connected device/emulator | Android |
| `just ios-build` | `xcodebuild ... -destination 'generic/platform=iOS Simulator' build` | iOS (macOS host) |
| `just ios-test` | `xcodebuild ... test` — runs the `ios/Tests/` XCTest suite on a simulator | iOS (macOS host) |
| `just ios-check` | `xcodebuild ... analyze` | iOS (macOS host) |
| `just ios-archive` | `xcodebuild ... archive` — unsigned `.xcarchive`, see `moon/roadmaps/ios.md` | iOS (macOS host) |

## 5. Coding Standards

- Follow the per-topic rules in [`.agent/rules/`](rules/): `kotlin.md`, `swift.md`, `android_lifecycle.md`, `game_loop_performance.md`, `ui_compose.md`, `testing_qa.md`, `code_review.md`, `error_debug.md`, `documentation.md`, `reasoning_planning.md`.
- Prefer small, reviewable diffs. Do not reformat files unrelated to the change.
- Every new public Kotlin function/class needs a KDoc comment and every new Swift type/function a `///` doc comment; every new `engine/`-equivalent class (Android `engine/`, iOS `Engine/`/`Core/GameManager.swift`) needs at least one unit test.
- Never commit secrets, keystores, signing passwords, or provisioning profiles. Use `android/local.properties`/`.env` (git-ignored) and document new variables in `.env.example`; iOS signing is Automatic/local-only by default (no committed certs — see `docs/DEVELOPMENT.md`).
- Changes to shared behavior (state-machine states/transitions, level-data shape) must update [`core/src/game-state-machine.md`](../core/src/game-state-machine.md) / [`core/src/level-schema.json`](../core/src/level-schema.json) and both platforms' implementations in the same PR — see `.agent/rules/swift.md` and `.agent/rules/kotlin.md`.

## 6. AI Review & Severity Protocol

### 6.1 CRITICAL (must fix before merge)

- Blocking work (I/O, bitmap/image decode, network) on the render/update thread or the UI thread, on either platform.
- Android: `SurfaceView` callbacks (`surfaceCreated`/`surfaceDestroyed`) not correctly starting/stopping the `GameLoop` thread — leaked threads crash on rotation/backgrounding.
- iOS: `GameScene`/`AppDelegate` not pausing gameplay on backgrounding — see `.agent/workflows/ios_lifecycle.md`.
- Signing credentials, a keystore file, or a provisioning profile committed to the repo.
- Game state not persisted in `onPause`/`onSaveInstanceState` (Android) or on backgrounding (iOS) — the OS can kill either app at any time.

### 6.2 HIGH (fix before merge)

- Per-frame allocations in the update/render hot path (new objects inside Android's `GameLoop` body, or iOS's `GameScene.update(_:)`) — triggers GC/ARC-driven frame drops.
- Missing null-safety handling around `SurfaceHolder.lockCanvas()` (Android, can return `null`) or force-unwraps in `GameScene`/node code (iOS, see `.agent/rules/swift.md`).
- Unhandled configuration changes (rotation) that don't resize/reset the game surface, on either platform.

### 6.3 MEDIUM (fix soon)

- Missing KDoc/doc-comments on public `engine/`/`Engine/`-equivalent classes.
- Magic numbers for tuning values (speed, spawn rate) not hoisted to named constants (`GameConstants` on iOS, equivalent on Android).

### 6.4 LOW (nice to have)

- Minor Compose/SwiftUI UI polish, string resource organization.

## 7. Known Constraints

> **TODO:** Document real device/performance constraints once the project has them.

- This template repository does not ship a complete game on either platform — `engine/`/`Engine/` contain illustrative skeletons (a bouncing-entity demo on Android, a top-down shooter skeleton on iOS), not final or even matching gameplay. See the documented Android/iOS asymmetry in `core/src/game-state-machine.md`.
- The optional backend under `infra/` is unimplemented scaffolding — see each `infra/*/README.md` before assuming any service exists.
- `core/` is assets + documentation only, not a compiled shared module — see `core/README.md` and `moon/roadmaps/shared_core.md` before assuming any logic is actually shared between the two clients.
- The iOS client cannot be built, tested, or run inside `.devcontainer/` (Linux-only) — it requires a native macOS host or a `macos-latest` CI runner.
