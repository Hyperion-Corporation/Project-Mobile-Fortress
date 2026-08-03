<div align="center">

# Mobile-Game-Template

**A batteries-included GitHub template for a two-platform mobile game — real, idiomatic Android Studio (Kotlin) and Xcode (Swift) app modules, sharing assets, plus CI/CD, docs, containerization, and LLM agent scaffolding.**

<a href="https://github.com/ACFHarbinger/Mobile-Game-Template/actions/workflows/ci.yml"><img alt="CI" src="https://github.com/ACFHarbinger/Mobile-Game-Template/actions/workflows/ci.yml/badge.svg"></a>
<a href="https://github.com/ACFHarbinger/Mobile-Game-Template/actions/workflows/docs.yml"><img alt="Docs" src="https://github.com/ACFHarbinger/Mobile-Game-Template/actions/workflows/docs.yml/badge.svg"></a>
<img alt="PRs Welcome" src="https://img.shields.io/badge/PRs-welcome-brightgreen.svg">

</br>

<a href="https://github.com/ACFHarbinger/Mobile-Game-Template/releases"><img alt="Release" src="https://img.shields.io/github/v/release/ACFHarbinger/Mobile-Game-Template?include_prereleases&logo=github&color=blue"></a>
<a href="LICENSE.md"><img alt="License" src="https://img.shields.io/badge/License-AGPL--3.0%20%2F%20Commercial-blue.svg"></a>
<a href="https://github.com/ACFHarbinger/Mobile-Game-Template/issues"><img alt="Open Issues" src="https://img.shields.io/github/issues/ACFHarbinger/Mobile-Game-Template?color=yellow"></a>

</br>

<a href="https://kotlinlang.org/"><img alt="Kotlin" src="https://img.shields.io/badge/Kotlin-2.0-7F52FF?logo=kotlin&logoColor=white"></a>
<a href="https://developer.android.com/"><img alt="Android" src="https://img.shields.io/badge/Android-API_24%2B-3DDC84?logo=android&logoColor=white"></a>
<a href="https://developer.android.com/build/releases/gradle-plugin"><img alt="AGP" src="https://img.shields.io/badge/AGP-8.5-02303A?logo=gradle&logoColor=white"></a>
<a href="https://swift.org/"><img alt="Swift" src="https://img.shields.io/badge/Swift-5.0-F05138?logo=swift&logoColor=white"></a>
<a href="https://developer.apple.com/ios/"><img alt="iOS" src="https://img.shields.io/badge/iOS-16%2B-000000?logo=apple&logoColor=white"></a>
<a href="https://github.com/casey/just"><img alt="Just" src="https://img.shields.io/badge/Just-Task_Runner-black"></a>

</br>

<a href="https://www.docker.com/"><img alt="Docker" src="https://img.shields.io/badge/Docker-Optional_Backend-2496ED?logo=docker&logoColor=white"></a>
<a href="https://containers.dev/"><img alt="Dev Containers" src="https://img.shields.io/badge/Dev_Containers-Android_only-2496ED?logo=docker&logoColor=white"></a>
<a href="https://github.com/features/actions"><img alt="GitHub Actions" src="https://img.shields.io/badge/GitHub_Actions-CI%2FCD-2088FF?logo=githubactions&logoColor=white"></a>
<a href="https://squidfunk.github.io/mkdocs-material/"><img alt="MkDocs Material" src="https://img.shields.io/badge/MkDocs-Material-526CFE?logo=materialformkdocs&logoColor=white"></a>

</div>

## About

`Mobile-Game-Template` is a GitHub template repository for a **two-platform mobile game**: a Kotlin Android client under [`android/`](android/) and a Swift iOS client under [`ios/`](ios/). Unlike a generic app scaffold, it ships real, working (if minimal) game skeletons on both platforms — Android: a `SurfaceView`-based render surface on a fixed-timestep game loop thread; iOS: a SpriteKit `SKScene` — following each platform's official conventions exactly (standard Android Studio / Gradle Kotlin DSL layout, standard Xcode project layout). Raw assets and a documented (non-compiled) shared spec live under [`core/`](core/) — see `core/README.md` for exactly what's shared today vs. aspirational. Around all of that, it carries the same cross-cutting agentic/DevOps/docs framework (`.agent/`, `docs/`, `moon/`, `.github/`, `infra/`) used across this org's other project templates.

Use **"Use this template"** on GitHub to create a new repository, rename the Android package from `com.example.gametemplate` and the iOS bundle ID from `com.example.mygame`, and start building.

## Why SurfaceView + Canvas (Android) / SpriteKit (iOS)?

This template targets simple, dependency-light 2D games (arcade, puzzle, roguelike-lite) on each platform independently — it is **not** a shared cross-platform engine. Android uses `SurfaceView` + a dedicated fixed-timestep loop thread; iOS uses SpriteKit's own display-link-driven `update(_:)`, with a clamped per-frame delta for the same "don't spiral after a long pause" reason. Jetpack Compose / SwiftUI are used for chrome around each game surface (menus, HUD, settings). For 3D, physics-heavy games, or a genuinely shared cross-platform core, see [`.agent/AGENTS.md`](.agent/AGENTS.md) §1.1, [`docs/adr/0002-rendering-approach.md`](docs/adr/0002-rendering-approach.md), [`docs/adr/0003-ios-rendering-approach.md`](docs/adr/0003-ios-rendering-approach.md), and [`moon/roadmaps/shared_core.md`](moon/roadmaps/shared_core.md).

## Repository Layout

```
Mobile-Game-Template/
├── android/                 # Kotlin Android client
│   ├── app/                 # standard com.android.application + kotlin-android module
│   ├── gradlew, gradle/, build.gradle.kts, settings.gradle.kts, gradle.properties
├── ios/                      # Swift iOS client
│   ├── MyGame/               # App/, Core/, Engine/, Scenes/, UI/, Resources/
│   ├── MyGame.xcodeproj
│   └── Tests/                 # XCTest suite
├── core/                     # Shared raw assets + documented (non-compiled) spec
│   ├── assets/                # canonical level/wave JSON, shared textures/audio
│   └── src/                   # level-schema.json, game-state-machine.md
├── .agent/                   # LLM coding-agent prompts, rules, skills, workflows
├── .devcontainer/             # Dev Container — Android toolchain only, see below
├── .github/                   # Issue/PR templates, Dependabot, CI/release/docs workflows
├── infra/                     # Optional lightweight backend (leaderboards/cloud save)
├── docs/                       # MkDocs site, architecture notes, ADRs
├── git/                        # CONTRIBUTING.md, codecov.yaml
├── moon/                       # ROADMAP.md, CHANGELOG.md, per-topic roadmaps
├── tools/{build,test,validation,ci,docs,infra,reducer,helper}/justfile
└── justfile                    # root — imports tools/*/justfile as `just` modules
```

| Path | Purpose |
| --- | --- |
| `android/app/` | `MainActivity`, `GameView` (SurfaceView), `GameLoop` (fixed-timestep thread), `engine/` (GameEngine, GameState, entities), `ui/` (Compose chrome). |
| `ios/MyGame/` | `App/` (SwiftUI `@main`), `Core/GameManager.swift` (state machine), `Engine/` (Audio/Input/Physics/Storage), `Scenes/` (`GameScene` + nodes + SwiftUI screens), `UI/` (HUD/Shop/Theme). |
| `core/` | Canonical shared assets (`assets/levels/`) and a documented, **not compiled**, spec both clients implement independently — see `core/README.md`. |
| `.agent/` | LLM coding-agent prompts, rules, skills, and workflows (source of truth for `AGENTS.md`) |
| `.devcontainer/` | VS Code Dev Container with the Android SDK cmdline-tools, JDK 17, emulator deps — **Android only**; iOS requires a native macOS host, see `.devcontainer/README.md` |
| `.github/` | Issue/PR templates, Dependabot config, GitHub Actions workflows (`ci.yml` runs both an Android job set and a `macos-latest` iOS job; `release.yml` builds the signed Android bundle) |
| `infra/` | **Optional** lightweight backend scaffolding for leaderboards/cloud save: `docker/`, `k8s/`, `helm/`, `terraform/`, `ansible/` — not needed for an offline game |
| `docs/` | MkDocs site, architecture notes, ADRs (including the Android and iOS rendering-approach ADRs) |
| `git/` | `CONTRIBUTING.md` and `codecov.yaml` |
| `moon/` | `ROADMAP.md`, `CHANGELOG.md`, and per-topic roadmaps (including `ios.md` and `shared_core.md`) |
| `tools/*/justfile` | `just` recipe modules — each now covers both platforms where relevant (e.g. `tools/build/justfile` has both Gradle and `xcodebuild` recipes) |

## Quick Start

```bash
# Clone from the template
git clone https://github.com/<org>/<your-new-repo>.git
cd <your-new-repo>

# Install pre-commit hooks
pip install pre-commit && pre-commit install

# Explore the available command-runner recipes
just --list
```

### Android

```bash
just install     # build + install the debug APK on a connected device/emulator
```

Or open `android/` in Android Studio and let it sync Gradle.

### iOS

**Requires a native macOS host with Xcode 15+** — see [`docs/DEVELOPMENT.md`](docs/DEVELOPMENT.md#ios-ios).

```bash
open ios/MyGame.xcodeproj
```

Select the `MyGame` scheme and an iOS Simulator destination, then Run (⌘R). Or from the CLI: `just ios-build` / `just ios-test`.

## Development

See [`git/CONTRIBUTING.md`](git/CONTRIBUTING.md) for the contribution workflow, [`docs/DEVELOPMENT.md`](docs/DEVELOPMENT.md) for local setup on both platforms, and [`.devcontainer/`](.devcontainer/devcontainer.json) for a one-click containerized **Android** dev environment.

## Releasing

- **Android → Play Store**: see [`.agent/skills/release-to-play-store.md`](.agent/skills/release-to-play-store.md) and [`.github/workflows/release.yml`](.github/workflows/release.yml) — tagging `vX.Y.Z` builds a signed AAB/APK and (optionally, once fastlane credentials are configured) uploads to the Play Console's internal testing track.
- **iOS → App Store**: not automated yet — see [`moon/roadmaps/ios.md`](moon/roadmaps/ios.md); `just ios-archive` produces an unsigned `.xcarchive` as a starting point.

## License

This project is dual-licensed under an open-core model:

- **Open source (free) — GNU AGPL-3.0.** Free to use, modify, and
  distribute for hobbyists, students, researchers, non-profits, and any
  other use that complies with the [AGPL-3.0](LICENSE.md)'s copyleft and
  network source-disclosure terms.
- **Commercial (paid).** For proprietary, closed-source, or SaaS use that
  can't comply with the AGPL's obligations, a paid
  [commercial license](LICENSE.txt) is available — contact ACFHarbinger
  <afonso.fernandes100@gmail.com> for pricing and terms.
