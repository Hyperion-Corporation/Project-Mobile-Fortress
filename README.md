<div align="center">

# Mobile Fortress

**A cooperative tower-defense mobile game set during the 1540s–1560s Wōkòu pirate crisis on the East Asian coast — defend a Main HQ and its Resource/Trading Outposts, command an East Asian primary civilization (Ming China by default) alongside a supporting Western civilization (Portuguese by default), and extend the fight into a coastal-territory meta-game. Built as real, idiomatic Android Studio (Kotlin) and Xcode (Swift) app modules, sharing a planned C++ simulation core, CI/CD, docs, containerization, and LLM agent scaffolding.**

<a href="https://github.com/ACFHarbinger/Project-Mobile-Fortress/actions/workflows/ci.yml"><img alt="CI" src="https://github.com/ACFHarbinger/Project-Mobile-Fortress/actions/workflows/ci.yml/badge.svg"></a>
<a href="https://github.com/ACFHarbinger/Project-Mobile-Fortress/actions/workflows/docs.yml"><img alt="Docs" src="https://github.com/ACFHarbinger/Project-Mobile-Fortress/actions/workflows/docs.yml/badge.svg"></a>
<img alt="PRs Welcome" src="https://img.shields.io/badge/PRs-welcome-brightgreen.svg">

</br>

<a href="https://github.com/ACFHarbinger/Project-Mobile-Fortress/releases"><img alt="Release" src="https://img.shields.io/github/v/release/ACFHarbinger/Project-Mobile-Fortress?include_prereleases&logo=github&color=blue"></a>
<a href="LICENSE.md"><img alt="License" src="https://img.shields.io/badge/License-AGPL--3.0%20%2F%20Commercial-blue.svg"></a>
<a href="https://github.com/ACFHarbinger/Project-Mobile-Fortress/issues"><img alt="Open Issues" src="https://img.shields.io/github/issues/ACFHarbinger/Project-Mobile-Fortress?color=yellow"></a>

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

**Mobile Fortress** is a cooperative tower-defense mobile game: players defend a Wōkòu-pirate-era coastal fortress network — a Main HQ plus Resource Outposts (fund land units) and Trading Outposts (fund naval units) — against raids from land and sea, then extend that fight into a light 4X-style coastal-territory meta-game. The design targets an underserved market gap identified in [`docs/moon/reports/Tower Defense Market Research.md`](docs/moon/reports/Tower%20Defense%20Market%20Research.md) — a AAA-quality, historically grounded 16th-century East Asian setting is largely absent from the current top-grossing tower-defense/4X-hybrid charts.

The game is a **two-platform mobile client**: a Kotlin Android client under [`android/`](android/) and a Swift iOS client under [`ios/`](ios/), each following its platform's official conventions exactly (standard Android Studio / Gradle Kotlin DSL layout, standard Xcode project layout) — Android renders via a `SurfaceView` on a fixed-timestep game loop thread, iOS via a SpriteKit `SKScene`. Both clients are converging on a shared C++ simulation core (ECS via EnTT, bridged via JNI/Swift C++ interop) so Co-Op multiplayer sessions stay deterministic across platforms — see [`docs/moon/research/Multiplayer Tower Defense Implementation.md`](docs/moon/research/Multiplayer%20Tower%20Defense%20Implementation.md) for the full technical rationale and [`docs/moon/roadmaps/shared_core.md`](docs/moon/roadmaps/shared_core.md) for the migration plan. Raw assets and the shared spec live under [`core/`](core/) — see `core/README.md` for exactly what's shared today vs. planned. Around all of that, the repository carries a cross-cutting agentic/DevOps/docs framework (`.agent/`, `docs/`, `docs/moon/`, `.github/`, `infra/`) shared with this org's other project templates.

See [`docs/moon/ROADMAP.md`](docs/moon/ROADMAP.md) for the full game concept, architecture decisions, and phased delivery plan.

## Why SurfaceView + Canvas (Android) / SpriteKit (iOS)?

This project targets simple, dependency-light 2D game clients (per platform, ahead of the shared C++ core landing) on each platform independently — it is **not** a shared cross-platform engine. Android uses `SurfaceView` + a dedicated fixed-timestep loop thread; iOS uses SpriteKit's own display-link-driven `update(_:)`, with a clamped per-frame delta for the same "don't spiral after a long pause" reason. Jetpack Compose / SwiftUI are used for chrome around each game surface (menus, HUD, settings). For 3D, physics-heavy games, or a genuinely shared cross-platform core, see [`.agent/AGENTS.md`](.agent/AGENTS.md) §1.1, [`docs/adr/0002-rendering-approach.md`](docs/adr/0002-rendering-approach.md), [`docs/adr/0003-ios-rendering-approach.md`](docs/adr/0003-ios-rendering-approach.md), and [`docs/moon/roadmaps/shared_core.md`](docs/moon/roadmaps/shared_core.md).

## Repository Layout

```
Project-Mobile-Fortress/
├── android/                 # Kotlin Android client
│   └── app/                 # standard com.android.application + kotlin-android module
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
├── docs/                       # architecture notes, ADRs, roadmap, design docs, research
│   ├── design/                 # GDD, art/audio bibles, pitch deck, production/QA plans
│   ├── moon/                   # ROADMAP.md, CHANGELOG.md, per-topic roadmaps, reports/, research/
│   └── website/vue/             # Vite + Vue 3 + TS SPA: interactive design hub + doc reader (deployed to gh-pages)
├── git/                        # CONTRIBUTING.md, codecov.yaml
├── tools/{build,test,validation,ci,docs,infra,reducer,helper}/justfile
├── justfile                    # root — imports tools/*/justfile as `just` modules
├── gradlew, gradle/, build.gradle.kts, settings.gradle.kts, gradle.properties
│                              # Gradle workspace root (:app → android/app/), so `./gradlew <task>` works from here directly
├── package.json                 # npm workspaces root (docs/website/vue), so `npm run <script> -w docs/website/vue` works from here directly
└── pyproject.toml               # Python tooling deps (mkdocs-material, for local `mkdocs serve` only)
```

| Path | Purpose |
| --- | --- |
| `android/app/` | `MainActivity`, `GameView` (SurfaceView), `GameLoop` (fixed-timestep thread), `engine/` (GameEngine, GameState, entities), `ui/` (Compose chrome). Gradle root lives at the repo root — see below. |
| `ios/MyGame/` | `App/` (SwiftUI `@main`), `Core/GameManager.swift` (state machine), `Engine/` (Audio/Input/Physics/Storage), `Scenes/` (`GameScene` + nodes + SwiftUI screens), `UI/` (HUD/Shop/Theme). |
| `core/` | Canonical shared assets (`assets/levels/`) and a documented, **not compiled**, spec both clients implement independently — see `core/README.md`. |
| `.agent/` | LLM coding-agent prompts, rules, skills, and workflows (source of truth for `AGENTS.md`) |
| `.devcontainer/` | VS Code Dev Container with the Android SDK cmdline-tools, JDK 17, emulator deps — **Android only**; iOS requires a native macOS host, see `.devcontainer/README.md` |
| `.github/` | Issue/PR templates, Dependabot config, GitHub Actions workflows (`ci.yml` runs both an Android job set and a `macos-latest` iOS job; `release.yml` builds the signed Android bundle) |
| `infra/` | **Optional** lightweight backend scaffolding for leaderboards/cloud save: `docker/`, `k8s/`, `helm/`, `terraform/`, `ansible/` — not needed for an offline game |
| `docs/` | Architecture notes, ADRs (including the Android and iOS rendering-approach ADRs), design docs, research write-ups, roadmap, and `docs/website/` — the Vue 3 interactive design-hub + docs site deployed to GitHub Pages (MkDocs Material remains available locally for browsing the same Markdown) |
| `git/` | `CONTRIBUTING.md` and `codecov.yaml` |
| `docs/moon/` | `ROADMAP.md`, `CHANGELOG.md`, and per-topic roadmaps (including `ios.md` and `shared_core.md`) |
| `tools/*/justfile` | `just` recipe modules — each now covers both platforms where relevant (e.g. `tools/build/justfile` has both Gradle and `xcodebuild` recipes) |
| `gradlew` / `gradle/` / `build.gradle.kts` / `settings.gradle.kts` | The Gradle **workspace root** — `:app` (`android/app/`) is the only module today; a future native module just needs an `include(...)` line here. See [`docs/DEPENDENCY_POLICY.md`](docs/DEPENDENCY_POLICY.md#android-gradlelibsversionstoml). |
| `package.json` | The npm **workspace root** — declares `docs/website/vue` under `"workspaces"`; a future JS/TS package just needs adding to that array. See [`docs/DEPENDENCY_POLICY.md`](docs/DEPENDENCY_POLICY.md#node--npm-root-package-lockjson-npm-workspaces). |
| `pyproject.toml` | Pins `mkdocs-material` for local `mkdocs serve` — this repo has no Python application code. |

## Quick Start

All commands below run from the repo root — none of them require `cd`-ing into a subdirectory first (Gradle, npm, and Python each have a workspace root file at the top level; see [Repository Layout](#repository-layout)).

```bash
# Clone the repo
git clone https://github.com/ACFHarbinger/Project-Mobile-Fortress.git
cd Project-Mobile-Fortress

# Install pre-commit hooks
pip install pre-commit && pre-commit install

# Explore the available command-runner recipes
just --list
```

### Android

```bash
./gradlew assembleDebug     # or: just install (build + install onto a connected device/emulator)
```

Or open `android/` in Android Studio and let it sync Gradle — it reads the root `settings.gradle.kts`/`build.gradle.kts` the same way the CLI does.

### iOS

**Requires a native macOS host with Xcode 15+** — see [`docs/DEVELOPMENT.md`](docs/DEVELOPMENT.md#ios-ios).

```bash
open ios/MyGame.xcodeproj
```

Select the `MyGame` scheme and an iOS Simulator destination, then Run (⌘R). Or from the CLI: `just ios-build` / `just ios-test`.

### Documentation website

The interactive design hub + full-repo documentation portal at [`docs/website/`](docs/website/) — see [`docs/website/README.md`](docs/website/README.md) for what's on it and [`docs/website/vue/README.md`](docs/website/vue/README.md) for implementation notes. `docs/website/vue` is an npm workspace declared in the root `package.json`, so every command below targets it with `-w`/`--workspace` instead of `cd`-ing in:

```bash
npm install                              # installs deps for every npm workspace (currently just docs/website/vue)
npm run dev -w docs/website/vue          # http://localhost:5173, hot-reloading
npm run build -w docs/website/vue        # type-check (vue-tsc) + production build -> docs/website/vue/dist/
npm run preview -w docs/website/vue      # serve the production build locally
node docs/website/vue/scripts/generate-nav.mjs   # regenerate nav.generated.ts after editing docs/mkdocs.yml's nav
```

Equivalent shorthands are predefined in the root `package.json`: `npm run site:dev`, `npm run site:build`, `npm run site:preview`, `npm run site:nav`.

The production build is deployed automatically to the `gh-pages` branch by [`.github/workflows/docs.yml`](.github/workflows/docs.yml) on every push to `main` that touches `docs/**` or any tracked Markdown file.

### Documentation portal (MkDocs, optional local alternative)

`docs/website/` above is the primary, deployed documentation site — this is a secondary, local-only way to browse the same `docs/**/*.md` content via [MkDocs Material](https://squidfunk.github.io/mkdocs-material/):

```bash
pip install .                                        # installs mkdocs-material, pinned in pyproject.toml
mkdocs serve --config-file docs/mkdocs.yml            # http://localhost:8000
```

## Development

See [`git/CONTRIBUTING.md`](git/CONTRIBUTING.md) for the contribution workflow, [`docs/DEVELOPMENT.md`](docs/DEVELOPMENT.md) for local setup on both platforms, and [`.devcontainer/`](.devcontainer/devcontainer.json) for a one-click containerized **Android** dev environment.

## Releasing

- **Android → Play Store**: see [`.agent/skills/release-to-play-store.md`](.agent/skills/release-to-play-store.md) and [`.github/workflows/release.yml`](.github/workflows/release.yml) — tagging `vX.Y.Z` builds a signed AAB/APK and (optionally, once fastlane credentials are configured) uploads to the Play Console's internal testing track.
- **iOS → App Store**: not automated yet — see [`docs/moon/roadmaps/ios.md`](docs/moon/roadmaps/ios.md); `just ios-archive` produces an unsigned `.xcarchive` as a starting point.

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
