<div align="center">

# Mobile Fortress

**A cooperative tower-defense mobile game set during the 1540s–1560s Wōkòu pirate crisis on the East Asian coast — defend a Main HQ and its Resource/Trading Outposts, command an East Asian primary civilization (Ming China by default) alongside a supporting Western civilization (Portuguese by default), and extend the fight into a coastal-territory meta-game. Built as a Godot 4 game with a C++ simulation core (GDExtension), plus shared CI/CD, docs, and LLM agent scaffolding.**

<a href="https://github.com/Hyperion-Corporation/Project-Mobile-Fortress/actions/workflows/ci.yml"><img alt="CI" src="https://github.com/Hyperion-Corporation/Project-Mobile-Fortress/actions/workflows/ci.yml/badge.svg"></a>
<a href="https://github.com/Hyperion-Corporation/Project-Mobile-Fortress/actions/workflows/docs.yml"><img alt="Docs" src="https://github.com/Hyperion-Corporation/Project-Mobile-Fortress/actions/workflows/docs.yml/badge.svg"></a>
<img alt="PRs Welcome" src="https://img.shields.io/badge/PRs-welcome-brightgreen.svg">

</br>

<a href="https://github.com/Hyperion-Corporation/Project-Mobile-Fortress/releases"><img alt="Release" src="https://img.shields.io/github/v/release/Hyperion-Corporation/Project-Mobile-Fortress?include_prereleases&logo=github&color=blue"></a>
<a href="LICENSE"><img alt="License" src="https://img.shields.io/badge/License-AGPL--3.0%20%2F%20Commercial-blue.svg"></a>
<a href="https://github.com/Hyperion-Corporation/Project-Mobile-Fortress/issues"><img alt="Open Issues" src="https://img.shields.io/github/issues/Hyperion-Corporation/Project-Mobile-Fortress?color=yellow"></a>

</br>

<a href="https://godotengine.org/"><img alt="Godot" src="https://img.shields.io/badge/Godot-4.7-478CBF?logo=godotengine&logoColor=white"></a>
<a href="game/BUILD_CPP.md"><img alt="C++" src="https://img.shields.io/badge/C%2B%2B-GDExtension-00599C?logo=cplusplus&logoColor=white"></a>
<a href="https://github.com/casey/just"><img alt="Just" src="https://img.shields.io/badge/Just-Task_Runner-black"></a>

</br>

<a href="https://www.docker.com/"><img alt="Docker" src="https://img.shields.io/badge/Docker-Optional_Backend-2496ED?logo=docker&logoColor=white"></a>
<a href="https://containers.dev/"><img alt="Dev Containers" src="https://img.shields.io/badge/Dev_Containers-Android_only-2496ED?logo=containers&logoColor=white"></a>
<a href="https://github.com/features/actions"><img alt="GitHub Actions" src="https://img.shields.io/badge/GitHub_Actions-CI%2FCD-2088FF?logo=githubactions&logoColor=white"></a>
<a href="https://squidfunk.github.io/mkdocs-material/"><img alt="MkDocs Material" src="https://img.shields.io/badge/MkDocs-Material-526CFE?logo=materialformkdocs&logoColor=white"></a>

</div>

## About

**Mobile Fortress** is a cooperative tower-defense mobile game: players defend a Wōkòu-pirate-era coastal fortress network — a Main HQ plus Resource Outposts (fund land units) and Trading Outposts (fund naval units) — against raids from land and sea, then extend that fight into a light 4X-style coastal-territory meta-game. The design targets an underserved market gap identified in [`docs/moon/reports/Tower Defense Market Research.md`](docs/moon/reports/Tower%20Defense%20Market%20Research.md) — a AAA-quality, historically grounded 16th-century East Asian setting is largely absent from the current top-grossing tower-defense/4X-hybrid charts.

The live product is the **Godot 4.7 game under [`game/`](game/)**: a dual-front (land + sea) offline tower-defense prototype where GDScript handles presentation, input, and run orchestration while a C++ `SimulationCore` GDExtension (vector-backed `SimWorld`, FlatBuffers snapshots; EnTT scaffolding remains separate) owns the combat/economy simulation — see [`game/README.md`](game/README.md) to run it and [`docs/moon/roadmaps/shared_core.md`](docs/moon/roadmaps/shared_core.md) for the C++ core build-out. The Kotlin [`android/`](android/) and Swift [`ios/`](ios/) clients are **legacy inherited template trees** kept for reference — their CI jobs run only when their own paths change. Around all of that, the repository carries a cross-cutting agentic/DevOps/docs framework (`.agent/`, `docs/`, `docs/moon/`, `.github/`, `infra/`) shared with this org's other project templates, and a React dashboard/docs portal under [`docs/website/`](docs/website/).

See [`docs/moon/ROADMAP.md`](docs/moon/ROADMAP.md) for the full game concept, architecture decisions, and phased delivery plan.

## Repository Layout

```
Project-Mobile-Fortress/
├── game/                     # Godot 4.7 project — THE LIVE PRODUCT
│   ├── project.godot           # entry: scenes/main_menu.tscn
│   ├── scenes/                 # main menu, battle scenes
│   ├── scripts/                 # battle/, autoload/, ui/, data/ (GDScript)
│   ├── src/cpp/                 # SimulationCore GDExtension (C++; EnTT scaffold)
│   ├── src/schema/              # simulation_state.fbs snapshot schema
│   ├── src/level-schema.json    # level-JSON contract
│   ├── assets/levels/           # level/wave JSON
│   └── tests/                   # headless GDScript smokes + native C++ tests
├── android/                  # LEGACY Kotlin template client (SurfaceView)
├── ios/                      # LEGACY Swift template client (SpriteKit)
├── .agent/                   # LLM coding-agent rules, skills, workflows, AGENTS.md
├── .devcontainer/             # Dev Container — Android toolchain only, see below
├── .github/                   # Issue/PR templates, Dependabot, CI/release/docs workflows
├── infra/                     # Optional lightweight backend (leaderboards/cloud save)
├── docs/                       # architecture notes, ADRs, roadmap, design docs, research
│   ├── design/                 # GDD, art/audio bibles, pitch deck, production/QA plans
│   ├── moon/                   # ROADMAP.md, CHANGELOG.md, per-topic roadmaps, reports/, research/
│   └── website/             # React 19 + Vite + TS portal: dashboard + doc reader (deployed to gh-pages)
├── git/                        # CONTRIBUTING.md, codecov.yaml, agent/board sync tooling
├── scripts/                    # run_godot_smokes.sh, run_perf_bench.sh, export smoke, playtest sync
├── tools/{build,test,validation,ci,docs,infra,reducer,helper}/justfile
├── justfile                    # root — imports tools/*/justfile as `just` modules
├── gradlew, gradle/, build.gradle.kts, settings.gradle.kts, gradle.properties
│                              # Gradle workspace root (:app → legacy android/app/)
├── package.json                 # npm workspaces root (docs/website), so `npm run <script> -w docs/website` works from here directly
└── pyproject.toml               # Python tooling deps (mkdocs-material, for local `mkdocs serve` only)
```

| Path | Purpose |
| --- | --- |
| `game/` | **The live product** — Godot 4.7 dual-front game; C++ `SimulationCore` under `src/cpp/` (build per `game/BUILD_CPP.md`), smokes under `tests/`. |
| `game/scripts/` | GDScript layers: `battle/` (presentation/input), `autoload/` (`game_session.gd` run orchestration), `ui/` (menus/HUD/settings/dev overlay), `data/` (unit defs, level catalog, offline persistence, playtest log). |
| `android/app/` | **Legacy** Kotlin template client (`MainActivity`, `GameView` SurfaceView, `GameLoop`, `engine/`, `ui/`). Gradle workspace root lives at the repo root. |
| `ios/MyGame/` | **Legacy** Swift template client (`App/`, `Core/GameManager.swift`, `Engine/`, `Scenes/`, `UI/`). |
| `.agent/` | LLM coding-agent rules, skills, and workflows (source of truth for `AGENTS.md`) |
| `.devcontainer/` | VS Code Dev Container with the Android SDK cmdline-tools, JDK 17, emulator deps — **Android only**; iOS requires a native macOS host, see `.devcontainer/README.md` |
| `.github/` | Issue/PR templates, Dependabot config, GitHub Actions workflows (`godot-game.yml` covers `game/**`; `ci.yml` covers the legacy trees and `scripts/*.sh` shellcheck; `website.yml` covers `docs/website/**`; `docs.yml` builds/deploys the docs portal) |
| `infra/` | **Optional** lightweight backend scaffolding for leaderboards/cloud save: `docker/`, `k8s/`, `helm/`, `terraform/`, `ansible/` — not needed for an offline game |
| `docs/` | Architecture notes, ADRs, design docs, research write-ups, roadmap, and `docs/website/` — the React interactive dashboard + docs site deployed to GitHub Pages (MkDocs Material remains available locally for browsing the same Markdown) |
| `git/` | `CONTRIBUTING.md` and `codecov.yaml` |
| `docs/moon/` | `ROADMAP.md`, `CHANGELOG.md`, and per-topic roadmaps (including `shared_core.md` and `vertical_slice.md`) |
| `scripts/` | `run_godot_smokes.sh` (full headless smoke suite), `run_perf_bench.sh` (perf budget bench), `export_mobile_smoke.sh` (export config/APK smoke), `sync_playtest_session.sh` (playtest log sync) |
| `tools/*/justfile` | `just` recipe modules (the Gradle/xcodebuild recipes target the legacy trees; `just test::godot-smokes` runs the Godot suite) |
| `gradlew` / `gradle/` / `build.gradle.kts` / `settings.gradle.kts` | The Gradle **workspace root** — `:app` (legacy `android/app/`) is the only module today. See [`docs/DEPENDENCY_POLICY.md`](docs/DEPENDENCY_POLICY.md#android-gradlelibsversionstoml). |
| `package.json` | The npm **workspace root** — declares `docs/website` under `"workspaces"`. See [`docs/DEPENDENCY_POLICY.md`](docs/DEPENDENCY_POLICY.md#node--npm-root-package-lockjson-npm-workspaces). |
| `pyproject.toml` | Pins `mkdocs-material` for local `mkdocs serve` — this repo has no Python application code. |

## Quick Start

All commands below run from the repo root — none of them require `cd`-ing into a subdirectory first (Gradle, npm, and Python each have a workspace root file at the top level; see [Repository Layout](#repository-layout)).

```bash
# Clone the repo
git clone https://github.com/Hyperion-Corporation/Project-Mobile-Fortress.git
cd Project-Mobile-Fortress

# Install pre-commit hooks
pip install pre-commit && pre-commit install

# Explore the available command-runner recipes
just --list
```

### The game (Godot 4.7)

1. Install [Godot 4.7](https://godotengine.org/download) and a C++ toolchain (CMake).
2. Build the native simulation core: see [`game/BUILD_CPP.md`](game/BUILD_CPP.md) — `cmake -S game -B game/build && cmake --build game/build`, then copy the extension binary to `game/bin/`.
3. Import `game/project.godot` in Godot and run (F5) — entry scene is `scenes/main_menu.tscn`. See [`game/README.md`](game/README.md) for controls and the Slice-0 loop.

```bash
scripts/run_godot_smokes.sh            # full headless smoke suite (subset: pass smoke names)
ctest --test-dir game/build --output-on-failure   # native C++ sim tests
scripts/run_perf_bench.sh              # perf budget benchmark (manual gate)
```

### Legacy trees (reference only)

The [`android/`](android/) (Kotlin) and [`ios/`](ios/) (Swift) template clients are legacy — not the shipped product. They remain for reference; their CI jobs run only when their own paths change (known findings in [`docs/TESTING.md`](docs/TESTING.md)). The classic recipes still exist:

```bash
./gradlew assembleDebug     # legacy Android client (requires the AGP/Gradle mismatch fix recorded in docs/TESTING.md)
just ios-build              # legacy iOS client (macOS host only)
```

### Documentation website

The React dashboard + full-repo documentation portal at [`docs/website/`](docs/website/) — see [`docs/website/README.md`](docs/website/README.md) for site content and app layout. `docs/website` is an npm workspace declared in the root `package.json`, so every command below targets it with `-w`/`--workspace` instead of `cd`-ing in:

```bash
npm install                              # installs deps for every npm workspace (currently just docs/website)
npm run dev -w docs/website          # hot-reloading dev server
npm run build -w docs/website        # typedoc/API gen + astro/storybook assets + production build -> docs/website/dist/
npm test -w docs/website            # vitest suite
node docs/website/scripts/generate-nav.mjs   # regenerate nav.generated.ts after editing docs/mkdocs.yml's nav
```

Equivalent shorthands are predefined in the root `package.json`: `npm run site:dev`, `npm run site:build`, `npm run site:preview`, `npm run site:nav`.

The production build is deployed automatically to the `gh-pages` branch by [`.github/workflows/docs.yml`](.github/workflows/docs.yml) on every push to `main` that touches `docs/**` or any tracked Markdown file.

### Documentation portal (MkDocs, optional local alternative)

`docs/website/` above is the primary, deployed documentation site — this is a secondary, local-only way to browse the same `docs/**/*.md` content via [MkDocs Material](https://squidfunk.github.io/mkdocs-material/):

```bash
pip install .                                        # installs mkdocs-material, pinned in pyproject.toml
mkdocs build --config-file docs/mkdocs.yml --strict  # the exact gate the Docs workflow runs
mkdocs serve --config-file docs/mkdocs.yml            # http://localhost:8000
```

## Development

See [`git/CONTRIBUTING.md`](git/CONTRIBUTING.md) for the contribution workflow, [`docs/DEVELOPMENT.md`](docs/DEVELOPMENT.md) for local setup, and [`.devcontainer/`](.devcontainer/devcontainer.json) for a one-click containerized dev environment.

## Releasing

- **Godot → stores**: export presets live in `game/` — see [`game/EXPORT_MOBILE.md`](game/EXPORT_MOBILE.md) for the export setup. `scripts/export_mobile_smoke.sh` still references the old `core/` directory and needs that path corrected before use. Store automation is not wired yet for the Godot build.
- **Legacy Android → Play Store**: [`.github/workflows/release.yml`](.github/workflows/release.yml) still targets the legacy `android/` tree — tagging `vX.Y.Z` builds a signed AAB/APK from it; see [`docs/moon/roadmaps/ios.md`](docs/moon/roadmaps/ios.md) for the legacy iOS path.

## License

This project is dual-licensed under an open-core model:

- **Open source (free) — GNU AGPL-3.0.** Free to use, modify, and
  distribute for hobbyists, students, researchers, non-profits, and any
  other use that complies with the [AGPL-3.0](LICENSE)'s copyleft and
  network source-disclosure terms.
- **Commercial (paid).** For proprietary, closed-source, or SaaS use that
  can't comply with the AGPL's obligations, a paid
  [commercial license](LICENSE) is available — contact ACFHarbinger
  <afonso.fernandes100@gmail.com> for pricing and terms.
