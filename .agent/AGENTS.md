# AGENTS.md - Instructions for Coding Assistant LLMs

[![Godot](https://img.shields.io/badge/Godot-4.7-478CBF?logo=godotengine&logoColor=white)](https://godotengine.org/)
[![C++](https://img.shields.io/badge/C%2B%2B-GDExtension-00599C?logo=cplusplus&logoColor=white)](game/BUILD_CPP.md)
[![Just](https://img.shields.io/badge/Just-Task_Runner-000000?logoColor=white)](https://github.com/casey/just)
[![CI](https://github.com/Hyperion-Corporation/Project-Mobile-Fortress/actions/workflows/ci.yml/badge.svg)](https://github.com/Hyperion-Corporation/Project-Mobile-Fortress/actions/workflows/ci.yml)
[![Docs](https://github.com/Hyperion-Corporation/Project-Mobile-Fortress/actions/workflows/docs.yml/badge.svg)](https://github.com/Hyperion-Corporation/Project-Mobile-Fortress/actions/workflows/docs.yml)

> **Version**: 3.0
> **Last Updated**: 2026-10-08
> **Purpose**: Authoritative reference for AI assistants (Claude, GPT, Gemini, Mistral, Grok, Copilot, etc.) working on Mobile Fortress.

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

This repository's **live product is the Godot 4.7 game under `game/`**: a GDScript presentation/orchestration layer over a C++ `SimulationCore` GDExtension (EnTT ECS simulation core with FlatBuffers snapshots), playable offline today as the dual-front (land + sea) Slice-0 prototype — see [`game/README.md`](../game/README.md). The Kotlin Android (`android/`) and Swift iOS (`ios/`) clients are **legacy inherited template trees**, kept for reference but *not* the product: their CI jobs run only when their own paths change, and their known breakages are recorded in [`docs/TESTING.md`](../docs/TESTING.md) ("Legacy-tree findings"). The cross-cutting agentic/DevOps/docs framework (`.agent/`, `docs/`, `docs/moon/`, `.github/`, `infra/`, `git/`) is shared across this org's other templates; the React dashboard under `docs/website/` is a secondary deliverable (~25% effort share).

### 1.1 Why Godot 4 + a C++ simulation core

The locked consensus decision (2026-08, see [`docs/moon/ROADMAP.md`](../docs/moon/ROADMAP.md)): one engine — Godot 4 — ships both mobile platforms, with the combat/economy simulation in C++ behind a GDExtension (`godot-cpp`) boundary so Co-Op sessions can later share deterministic native state offline-first. GDScript owns presentation, input, and gameplay orchestration; C++ owns the simulation. ADR [0002](../docs/adr/0002-rendering-approach.md)/[0003](../docs/adr/0003-ios-rendering-approach.md) record the earlier platform-native rendering deliberations (SurfaceView/SpriteKit) as historical context; [`docs/moon/roadmaps/shared_core.md`](../docs/moon/roadmaps/shared_core.md) tracks the C++ core build-out and the exact module/API boundary.

## 2. Technical Stack & Governance

| Component | Specification | Notes |
| --- | --- | --- |
| Godot | 4.7 (Forward Plus renderer, Jolt physics) | `game/project.godot`; entry scene `game/scenes/main_menu.tscn` |
| Game scripting | GDScript 2 (Godot 4 syntax) | `game/scripts/**` |
| Simulation core | C++ GDExtension via `godot-cpp`; EnTT ECS; FlatBuffers snapshots | `game/src/cpp/**`, `game/src/schema/simulation_state.fbs`; build per [`game/BUILD_CPP.md`](../game/BUILD_CPP.md) (CMake, output `game/bin/libmobile_fortress_core*.so`) |
| Level data | JSON validated against `game/src/level-schema.json` | `game/assets/levels/`; catalog in `game/scripts/data/level_catalog.gd`; validation smoke `game/tests/level_schema_smoke.gd` |
| Mobile export | Godot Android/iOS export presets | [`game/EXPORT_MOBILE.md`](../game/EXPORT_MOBILE.md); iOS export requires a macOS/Xcode host |
| Docs portal | MkDocs Material (strict mode in CI) + Vite/React SPA under `docs/website/` | `docs/mkdocs.yml`, `.github/workflows/docs.yml` |
| Legacy Android client | Kotlin 2.0, AGP 8.5.2, Gradle 8.7 wrapper-pinned, minSdk 24 / compileSdk 35 | `android/` — legacy tree; always `./gradlew`, never bare `gradle` |
| Legacy iOS client | Swift 5, iOS 16+ target, SpriteKit | `ios/` — legacy tree; requires macOS to build |
| Config | `local.properties` (git-ignored), `.env.example` for optional backend | unchanged |

## 3. Module Boundaries

- `game/` — **the live product** (Godot 4.7 project):
  - `game/src/cpp/` — C++ simulation: `sim_world.{h,cpp}` (engine-free combat/economy/wave/flow-field state) and `simulation_core.{h,cpp}` (GDExtension façade; translates `Vector2`/`PackedVector2Array`/`Dictionary` at the Godot↔C++ boundary). **`SimWorld` must stay free of Godot dependencies**; engine types cross only through `SimulationCore`.
  - `game/src/schema/simulation_state.fbs` — FlatBuffers snapshot schema (offline save/load, later net replication).
  - `game/src/level-schema.json` — the level-JSON contract; changes must update the loaders (`sim_world.cpp`, `level_catalog.gd`) and `game/tests/level_schema_smoke.gd` in the same change.
  - `game/scripts/battle/` — battle presentation + input (`battle_root.gd`); `game/scripts/autoload/game_session.gd` — run orchestration (phases, pause/time scaling, placement validation, DDA application); `game/scripts/ui/` — menus, HUD, settings, dev overlay (theme via `theme_tokens.gd`); `game/scripts/data/` — `unit_defs.gd`, `level_catalog.gd`, `offline_persistence.gd`, `progression.gd`, `playtest_log.gd`.
  - `game/scenes/` — scenes (entry `main_menu.tscn`, modular `scenes/battle/battle.tscn`); `game/assets/levels/` — level JSON.
  - `game/tests/` — headless GDScript smokes (`*_smoke.gd`, auto-discovered); `game/tests/native/` — native C++ tests (CMake/`ctest`).
- `docs/website/` — React 19 + Vite + TypeScript dashboard SPA (npm workspace; runs, CI status, playtest notes, lore map, unit visualizer, interactive demo). Secondary to the game.
- `android/` and `ios/` — **legacy template trees** (SurfaceView/SpriteKit skeletons). Do not extend them; do not treat their CI failures as product regressions. Their structure is documented for reference only: Android `app/src/main/java/com/acfharbinger/mobilefortress/` (`MainActivity.kt`, `GameView.kt`, `GameLoop.kt`, `engine/`, `ui/`), iOS `MyGame/` (`App/`, `Core/`, `Engine/`, `Scenes/`, `UI/`).
- Cross-module contracts (optional backend REST/WebSocket API) live under `docs/` — see [`docs/ARCHITECTURE.md`](../docs/ARCHITECTURE.md) — not duplicated in code comments.
- `infra/` describes an **optional** lightweight backend (leaderboards/cloud save) — a purely offline game needs none of it. See `infra/*/README.md`.

## 4. Key CLI Entry Points

| Command | Purpose |
| --- | --- |
| `scripts/run_godot_smokes.sh` (or `just test::godot-smokes`) | Run every headless Godot smoke under `game/tests/` (auto-discovered). Optional args run a subset; overrides: `GODOT=`, `SMOKE_TIMEOUT=`. Build the native extension first (see `game/BUILD_CPP.md`). |
| `ctest --test-dir game/build --output-on-failure` | Native C++ sim tests (`sim_world_tests`). Build first: `cmake -S game -B game/build && cmake --build game/build`. |
| `scripts/run_perf_bench.sh` | Dual-front tick-budget + flow-recompute benchmark. Manual gate only (never CI); record results in `docs/BENCHMARKS.md`. |
| `scripts/export_mobile_smoke.sh [--export-android]` | Mobile export configuration smoke; `--export-android` writes a debug APK (`game/EXPORT_MOBILE.md`). |
| `scripts/sync_playtest_session.sh` | Sync DT7 playtest session logs from `user://` into the repo for analysis. |
| `mkdocs build --config-file docs/mkdocs.yml --strict` | Documentation gate — the exact command the `Docs` workflow runs; out-of-tree references must be absolute GitHub URLs, never relative escapes (strict mode fails on them). |
| `npm test -w docs/website` / `npm run build -w docs/website` | Dashboard SPA vitest suite / production build. |
| `just --list` | Recipe modules; the Gradle/xcodebuild recipes target the **legacy** trees only. |

## 5. Coding Standards

- Follow the per-topic rules in [`.agent/rules/`](rules/): `game_loop_performance.md`, `testing_qa.md`, `code_review.md`, `error_debug.md`, `documentation.md`, `reasoning_planning.md` apply repo-wide. `kotlin.md`, `swift.md`, `android_lifecycle.md`, `ui_compose.md` apply only to the legacy `android/`/`ios/` trees.
- Prefer small, reviewable diffs. Do not reformat files unrelated to the change.
- Every new public GDScript function/class needs a `##` doc comment and every new public C++ function/class a header doc comment; every new simulation behavior needs a smoke (`game/tests/*_smoke.gd`, auto-discovered) or a native test (`game/tests/native/`).
- Never commit secrets, keystores, signing passwords, or provisioning profiles. Use `local.properties`/`.env` (git-ignored) and document new variables in `.env.example`.
- Changes to shared behavior must keep the level-data and snapshot contracts in sync in the same change: `game/src/level-schema.json` (+ `level_schema_smoke.gd`, loaders in `sim_world.cpp`/`level_catalog.gd`) for level data; `game/src/schema/simulation_state.fbs` for save/replication state.

## 6. AI Review & Severity Protocol

### 6.1 CRITICAL (must fix before merge)

- Blocking work (file/network I/O, heavy allocation, `await` on long operations) inside `_process`/`_physics_process`, the battle HUD update path, or the C++ sim tick.
- Game state not persisted on pause/backgrounding/quit — saves go through `SimulationCore.save_state()` / `OfflinePersistence`, and resume must restore the full run (see `game_session_smoke.gd`).
- Shipping a stale `game/bin/libmobile_fortress_core*.so` or editing the `.gdextension`/`SimulationCore` exposed API without rebuilding and re-running the smokes — GDExtension binary/source mismatch breaks every downstream smoke.
- Signing credentials, a keystore file, or a provisioning profile committed to the repo.

### 6.2 HIGH (fix before merge)

- Per-frame allocations in hot paths (new objects inside `_process`/combat loops; per-tick container churn inside `SimWorld`), or unbounded node/entity growth over a run — GC-driven frame drops on the 30+ FPS mobile budget.
- Missing pause/time-scale gating so sim, spawn, or placement logic advances while `GameSession.is_paused` is true.
- Cross-boundary marshalling waste: per-frame `Dictionary`/`PackedVector2Array` copies between GDScript and C++ larger than the data actually needed.
- Snapshot changes that bump `schema_version` or alter `simulation_state.fbs` fields without a load path for the previous version.

### 6.3 MEDIUM (fix soon)

- Missing doc comments on public `SimulationCore` APIs or GDScript autoloads/data classes.
- Tuning values (speeds, costs, cooldowns, budgets) hardcoded away from `game/scripts/data/unit_defs.gd` or named constants.

### 6.4 LOW (nice to have)

- UI/theme polish (`theme_tokens.gd` adoption), string organization, minor HUD layout.

## 7. Known Constraints

- The game is at **Slice-0 / Phase 1**: playable offline dual-front prototype; the VS10 collaborator playtest gate remains open before Phase 1b (see `docs/moon/roadmaps/vertical_slice.md`).
- `android/` and `ios/` are legacy inherited template trees, not the product. Known open findings: the Android tree pins AGP 9.3.1 against the wrapper-pinned Gradle 8.7 (cannot build), and `ios/MyGame.xcodeproj` does not parse under current Xcode — recorded in `docs/TESTING.md` "Legacy-tree findings". CI runs these jobs only when their own paths change; do not "fix" them by deleting the trees or hiding failures.
- The A4 heuristic DDA baseline ships **off by default** (dev-overlay setting only) pending playtest tuning (#78 open).
- The optional backend under `infra/` is unimplemented scaffolding — see each `infra/*/README.md` and [`docs/moon/roadmaps/backend.md`](../docs/moon/roadmaps/backend.md) before assuming any service exists.
- Multiplayer/co-op networking, cosmetics monetization, sentiment automation, and RL difficulty tuning are pre-implementation — see [`docs/moon/ROADMAP.md`](../docs/moon/ROADMAP.md) for phase sequencing before assuming any are wired up.
- iOS export and on-device testing require a macOS/Xcode host; the dev container (`.devcontainer/`) covers the Android toolchain only.

## 8. Multi-Agent Session Workflow

When multiple AI assistants (Claude, Grok, Chat/Codex, Gemini, etc.) are working this repo together in one session, coordinating through `.agent/cache/AGENT_BUS.md` (see that file's own protocol header):

- **Commit your own work before ending your session.** Whichever agent implemented a change is responsible for staging and committing it — with a scoped, conventional-commit message (`feat(core): ...`, `docs(moon): ...`, etc.) — before signing off, rather than leaving it for another agent or the owner to sort out later. Group commits by module/concern the same way you'd group a manual review: don't bundle unrelated trees (e.g. `game/src/cpp/` vs `docs/website/`) into one commit just because they landed in the same session.
- **Update the changelog and roadmap(s) as part of that same commit**, not as a follow-up: `docs/moon/CHANGELOG.md` gets an entry for what shipped, and the relevant `docs/moon/roadmaps/*.md` status line(s) move from `📋 Pending`/`🚧 Partial` to reflect reality. A task isn't done until the docs match the diff.
- **GitHub project issues are the team lead's responsibility, not each agent's.** Whoever is acting as team lead for the session (see the current role split logged on `AGENT_BUS.md`) owns retitling/commenting/closing issues after independently verifying the work — don't post to GitHub for your own unreviewed changes.
- If your session ends mid-task (blocked, handed off, or simply out of budget), say so on the bus instead of committing partial/broken work — an uncommitted working-tree diff plus a bus note is better than a commit that doesn't build or pass its own smokes.
