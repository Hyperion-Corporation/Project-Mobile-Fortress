# AGENTS.md - Instructions for Coding Assistant LLMs

[![Kotlin](https://img.shields.io/badge/Kotlin-2.0-7F52FF?logo=kotlin&logoColor=white)](https://kotlinlang.org/)
[![Android](https://img.shields.io/badge/Android-API_24%2B-3DDC84?logo=android&logoColor=white)](https://developer.android.com/)
[![Swift](https://img.shields.io/badge/Swift-5.0-F05138?logo=swift&logoColor=white)](https://swift.org/)
[![iOS](https://img.shields.io/badge/iOS-16%2B-000000?logo=apple&logoColor=white)](https://developer.apple.com/ios/)
[![Just](https://img.shields.io/badge/Just-Task_Runner-000000?logoColor=white)](https://github.com/casey/just)
[![CI](https://github.com/ACFHarbinger/Project-Mobile-Fortress/actions/workflows/ci.yml/badge.svg)](https://github.com/ACFHarbinger/Project-Mobile-Fortress/actions/workflows/ci.yml)

> **Version**: 2.1
> **Last Updated**: 2026-08-06
> **Purpose**: Authoritative reference for AI assistants (Claude, GPT, Gemini, Copilot, etc.) working on Mobile Fortress.

## Table of Contents

1. [Project Overview & Mission](#1-project-overview--mission)
2. [Technical Stack & Governance](#2-technical-stack--governance)
3. [Module Boundaries](#3-module-boundaries)
4. [Key CLI Entry Points](#4-key-cli-entry-points)
5. [Coding Standards](#5-coding-standards)
6. [AI Review & Severity Protocol](#6-ai-review--severity-protocol)
7. [Known Constraints](#7-known-constraints)
8. [Multi-Agent Session Workflow](#8-multi-agent-session-workflow)

## 1. Project Overview & Mission

**Mobile Fortress** is a cooperative tower-defense mobile game set during the 1540s–1560s Wōkòu (倭寇) pirate crisis on the East Asian coast: players defend a Main HQ/Citadel plus Resource Outposts (fund land units) and Trading Outposts (fund naval units) against raiding Wōkòu pirate fleets — mixed Japanese rōnin and Chinese/Korean pirate-smugglers striking by land and sea — using Flow-Field-routed unit placement, commanding an East Asian primary civilization (Ming China by default) alongside a supporting Western civilization (Portuguese by default; Spanish/Dutch/British/French as alternates), then extend the fight into a light 4X-style coastal-territory meta-game. See [`docs/moon/ROADMAP.md`](../docs/moon/ROADMAP.md) for the full game concept and phased delivery plan, and [`docs/moon/reports/`](../docs/moon/reports/)/[`docs/moon/research/`](../docs/moon/research/) for the underlying market and technical research.

This repository is a **two-platform mobile game**: a Kotlin Android client (`android/`) and a Swift iOS client (`ios/`). Each ships a real product module — currently minimal 2D game skeletons inherited from this repo's template origin (Android: `SurfaceView` + a fixed-timestep loop thread; iOS: SpriteKit's `SKScene`), being built out into the actual Mobile Fortress core loop — plus the cross-cutting agentic/DevOps/docs framework shared across this org's other templates (`.agent/`, `docs/`, `docs/moon/`, `.github/`, `infra/`). A `game/` module holds shared raw assets and a documented (not yet compiled) state-machine/level spec both clients implement independently today — see [`game/README.md`](../game/README.md) and [`docs/moon/roadmaps/shared_core.md`](../docs/moon/roadmaps/shared_core.md) for the plan to replace this with a compiled C++ simulation core once Co-Op multiplayer work starts.

### 1.1 Why SurfaceView + Canvas (Android) / SpriteKit (iOS), not Compose-only, SwiftUI-only, or a game engine

This project targets **simple, dependency-light 2D game clients** (per platform, ahead of the shared C++ core landing) — it is **not** a shared cross-platform engine (see `docs/moon/roadmaps/shared_core.md` for that option, not adopted by default). Each client uses its platform's idiomatic, zero-extra-dependency 2D approach, decoupled from its declarative-UI framework's recomposition/re-render timing:

| If your game needs... | Consider instead |
| --- | --- |
| Menus, HUD, settings screens, leaderboards UI | Keep those in Jetpack Compose (Android, [`ui_compose.md`](rules/ui_compose.md)) / SwiftUI (iOS, [`swift.md`](rules/swift.md)) layered *around* the game surface — this project already does this for the main menu on both platforms. |
| 3D rendering, physics engine, or a genuinely shared cross-platform codebase | [LibGDX](https://libgdx.com/)/[Godot](https://godotengine.org/) (Android), or revisit `docs/moon/roadmaps/shared_core.md`'s KMP/C++ options — swap the platform-native surface/loop for the engine's own and keep everything else in this project (`.agent/`, CI, docs, infra). |
| Compose-only / SwiftUI-only rendering (shaders via `Canvas`/`Modifier.drawWithCache`, or SwiftUI `Canvas`) | Viable for lower-frequency/simpler games; see [ADR 0002](../docs/adr/0002-rendering-approach.md) (Android) and [ADR 0003](../docs/adr/0003-ios-rendering-approach.md) (iOS) for the tradeoffs we weighed on each platform. |

## 2. Technical Stack & Governance

| Component | Specification | Notes |
| --- | --- | --- |
| Kotlin | 2.0.20 | `kotlin-android` plugin, JVM target 17 (`android/`) |
| Android Gradle Plugin (AGP) | 8.5.2 | `com.android.application` |
| Gradle | 8.7 (wrapper-pinned) | Always invoke via `./gradlew`, never a bare `gradle` |
| compileSdk / targetSdk | 35 (Android 15) | |
| minSdk | 24 (Android 7.0) | ~97% device coverage as of 2026 |
| Android UI toolkit | Views (`SurfaceView`) for the game surface, Jetpack Compose for menus/HUD chrome | See §1.1 |
| Swift | 5.0 | `ios/MyGame.xcodeproj`, iOS 16+ deployment target |
| iOS UI toolkit | SpriteKit for the game surface, SwiftUI for menus/HUD chrome | See §1.1 — requires a macOS host to build, see `.devcontainer/README.md` |
| Build variants | Android: `debug`, `release` (minified + resource-shrunk, R8); iOS: `Debug`, `Release` | |
| Config | `local.properties` (git-ignored, SDK path + signing refs), `.env.example` for optional backend | |

## 3. Module Boundaries

- `android/app/src/main/java/com/acfharbinger/mobilefortress/` — the Android product module. Structured as:
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
  - `Resources/` — `Levels/` (JSON referenced from `game/assets/levels/`, not duplicated), `Fonts/` (empty by default, see its `README.md`).
- `game/` — shared raw assets (`assets/`) and a documented, non-compiled spec (`src/`) for level data and the state-machine shape. See [`game/README.md`](../game/README.md) — do not assume anything in `game/src/` is compiled/linked into either app.
- Cross-module contracts (an optional backend's REST/WebSocket API) live under `docs/` — see [`docs/ARCHITECTURE.md`](../docs/ARCHITECTURE.md) — not duplicated in code comments.
- `infra/` describes an **optional** lightweight backend (leaderboards/cloud save) — a purely offline game needs none of it. See `infra/*/README.md`.

## 4. Key CLI Entry Points

| Command | Purpose | Platform |
| --- | --- | --- |
| `just --list` | List all available command-runner recipes | both |
| `just apk` | `./gradlew assembleDebug` | Android |
| `just unit-test` | Unit tests (`./gradlew testDebugUnitTest`) | Android |
| `just test-instrumented` | Instrumented tests on a connected device/emulator (`./gradlew connectedDebugAndroidTest`) | Android |
| `just lint-check` | `./gradlew lint ktlintCheck` | Android |
| `just assemble-release` | `./gradlew bundleRelease` (signed App Bundle for Play Store) | Android |
| `just install` | `./gradlew installDebug` onto a connected device/emulator | Android |
| `just ios-build` | `xcodebuild ... -destination 'generic/platform=iOS Simulator' build` | iOS (macOS host) |
| `just ios-test` | `xcodebuild ... test` — runs the `ios/Tests/` XCTest suite on a simulator | iOS (macOS host) |
| `just ios-check` | `xcodebuild ... analyze` | iOS (macOS host) |
| `just ios-archive` | `xcodebuild ... archive` — unsigned `.xcarchive`, see `docs/moon/roadmaps/ios.md` | iOS (macOS host) |

## 5. Coding Standards

- Follow the per-topic rules in [`.agent/rules/`](rules/): `kotlin.md`, `swift.md`, `android_lifecycle.md`, `game_loop_performance.md`, `ui_compose.md`, `testing_qa.md`, `code_review.md`, `error_debug.md`, `documentation.md`, `reasoning_planning.md`.
- Prefer small, reviewable diffs. Do not reformat files unrelated to the change.
- Every new public Kotlin function/class needs a KDoc comment and every new Swift type/function a `///` doc comment; every new `engine/`-equivalent class (Android `engine/`, iOS `Engine/`/`Core/GameManager.swift`) needs at least one unit test.
- Never commit secrets, keystores, signing passwords, or provisioning profiles. Use `local.properties`/`.env` (git-ignored) and document new variables in `.env.example`; iOS signing is Automatic/local-only by default (no committed certs — see `docs/DEVELOPMENT.md`).
- Changes to shared behavior (state-machine states/transitions, level-data shape) must update [`game/src/game-state-machine.md`](../game/src/game-state-machine.md) / [`game/src/level-schema.json`](../game/src/level-schema.json) and both platforms' implementations in the same PR — see `.agent/rules/swift.md` and `.agent/rules/kotlin.md`.

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

- Neither platform ships the real Mobile Fortress core loop yet — `engine/`/`Engine/` still contain the inherited template skeletons (a bouncing-entity demo on Android, a top-down shooter skeleton on iOS), not the Wōkòu-era fortress-defense gameplay described in [`docs/moon/roadmaps/gameplay.md`](../docs/moon/roadmaps/gameplay.md). See the documented Android/iOS asymmetry in `game/src/game-state-machine.md`.
- The optional backend under `infra/` is unimplemented scaffolding — see each `infra/*/README.md` and [`docs/moon/roadmaps/backend.md`](../docs/moon/roadmaps/backend.md) before assuming any service exists.
- `game/` is assets + documentation only, not a compiled shared module — see `game/README.md` and [`docs/moon/roadmaps/shared_core.md`](../docs/moon/roadmaps/shared_core.md) (C++ is the decided direction) before assuming any logic is actually shared between the two clients.
- The iOS client cannot be built, tested, or run inside `.devcontainer/` (Linux-only) — it requires a native macOS host or a `macos-latest` CI runner.
- Multiplayer, gacha/monetization, and ML-driven systems (Flow Field pathfinding, WFC procgen, RL difficulty, CMAB offers) are all pre-implementation — see [`docs/moon/ROADMAP.md`](../docs/moon/ROADMAP.md) for phase sequencing before assuming any are wired up.

## 8. Multi-Agent Session Workflow

When multiple AI assistants (Claude, Grok, Chat/Codex, Gemini, etc.) are working this repo together in one session, coordinating through `.agent/cache/AGENT_BUS.md` (see that file's own protocol header):

- **Commit your own work before ending your session.** Whichever agent implemented a change is responsible for staging and committing it — with a scoped, conventional-commit message (`feat(core): ...`, `docs(moon): ...`, etc.) — before signing off, rather than leaving it for another agent or the owner to sort out later. Group commits by module/concern the same way you'd group a manual review: don't bundle unrelated trees (e.g. `game/src/cpp/` vs `docs/website/`) into one commit just because they landed in the same session.
- **Update the changelog and roadmap(s) as part of that same commit**, not as a follow-up: `docs/moon/CHANGELOG.md` gets an entry for what shipped, and the relevant `docs/moon/roadmaps/*.md` status line(s) move from `📋 Pending`/`🚧 Partial` to reflect reality. A task isn't done until the docs match the diff.
- **GitHub project issues are the team lead's responsibility, not each agent's.** Whoever is acting as team lead for the session (see the current role split logged on `AGENT_BUS.md`) owns retitling/commenting/closing issues after independently verifying the work — don't post to GitHub for your own unreviewed changes.
- If your session ends mid-task (blocked, handed off, or simply out of budget), say so on the bus instead of committing partial/broken work — an uncommitted working-tree diff plus a bus note is better than a commit that doesn't build or pass its own smokes.
