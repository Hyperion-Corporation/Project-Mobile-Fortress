# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed

- Retconned the setting from 1520s Sengoku Japan to the **1540s–1560s Wōkòu (倭寇) / Wakō pirate crisis** on the East Asian coast: the player defends a coastal fortress network — a Main HQ/Citadel (loss condition), Resource Outposts (fund land units), and Trading Outposts (fund naval units) — against raiding Wōkòu pirate fleets striking by land and sea, commanding an East Asian primary civilization (Ming China by default; Japan/Joseon Korea as alternates) reinforced by a supporting Western civilization (Portuguese by default; Spanish/Dutch/British/French as alternates). Reworked the unit roster accordingly (Ming Garrison Spearmen, Fo-lang-ji Cannon Crews, East Asian Archers, Veteran Commanders, Portuguese Arquebusiers, East Asian War Junks, Western Galleons) and dropped the supernatural Yokai-corruption mechanic in favor of grounded raider warfare. Updated `docs/design/*.md`, `docs/moon/ROADMAP.md`, `docs/moon/roadmaps/*.md`, `README.md`, `.agent/AGENTS.md`, `docs/index.md`, `docs/ARCHITECTURE.md`, `docs/GLOSSARY.md`, and the interactive design website (`docs/design/website/`) accordingly. Added a new Resource/Trading Outpost economy line item to `docs/moon/roadmaps/gameplay.md`.
- Moved `design/` → `docs/design/` and `moon/` → `docs/moon/` so all design, roadmap, and reference documentation lives under a single `docs/` tree; fixed all cross-references (relative links in docs, `.agent/`, PR/MR templates, CI workflow comments) to the new paths.
- Merged the interactive design-hub website (formerly `docs/design/website/`) and the documentation portal (formerly `docs/public/`) into a single `docs/website/` and rewrote it as a **Vue 3** single-page app (CDN/global builds, no bundler): `docs/website/{index.html,app.js,styles.css,assets/}`. The design-hub tabs (Flow Field simulator, GA wall-layout visualizer, dynamic-audio mixer, sprint roadmap, QA net-sync dashboard) are now genuinely reactive Vue components (reactive grid/enemy state, computed excitement/desync formulas, `v-model` sliders) instead of manual DOM manipulation. Added a full **Documentation** section: a Vue Router (hash-mode) view with a searchable sidebar, breadcrumbs, prev/next navigation, and an "Edit on GitHub" link, that fetches every `docs/**/*.md` source at runtime and renders it with `marked` + `DOMPurify`, including Mermaid diagram rendering, KaTeX math rendering, per-page "on this page" heading TOC, code-block copy buttons, and click-through resolution of a doc's relative Markdown links (internal links route client-side; links outside `docs/`, e.g. to `reports/`, `research/`, `android/`, `.agent/`, open as GitHub blob links instead of 404ing).
- Reworked `.github/workflows/docs.yml` to assemble `docs/website/` plus a `content/` mirror of every `docs/**/*.md` file (everything the SPA fetches at runtime) and publish it to a `gh-pages` branch via `peaceiris/actions-gh-pages`, instead of GitHub's managed Pages artifact/OIDC deploy. No longer runs `mkdocs build` as part of the deploy (the Vue app renders the Markdown directly); `docs/mkdocs.yml` (now excluding `website/` via `exclude_docs`) remains for local browsing via `mkdocs serve`.

### Added

- Game design and technical architecture research: `reports/Tower Defense Market Research.md` (market/genre/monetization analysis) and `research/Multiplayer Tower Defense Implementation.md` (Rust/UniFFI shared core, ECS, netcode, matchmaking, and ML systems research), informing the roadmap below.
- Rewrote `moon/ROADMAP.md` and all `moon/roadmaps/*.md` around the concrete game concept: **Mobile Fortress**, a cooperative tower-defense game set in 1520s Sengoku Japan with a light 4X clan/territory meta-game, a planned Rust shared simulation core, server-authoritative Co-Op netcode, and procedural/ML systems (Flow Field pathfinding, Wave Function Collapse, RL-based dynamic difficulty, CMAB-personalized offers).
- New `moon/roadmaps/ai_systems.md` tracking procedural content generation and ML-driven difficulty/monetization/retention systems.
- Rewrote `README.md` and updated `.agent/AGENTS.md`'s project overview to describe Mobile Fortress instead of the generic template.
- Filed 76 GitHub issues (one per roadmap line item across `gameplay`, `ui_ux`, `performance`, `monetization`, `backend`, `qa_testing`, `ios`, `shared_core`, `ai_systems`), each labeled `roadmap:<topic>`, and added them all to the [Project Mobile Fortress](https://github.com/users/ACFHarbinger/projects/17) GitHub Project board.

### Changed

- Renamed the Android package `com.example.gametemplate` → `com.acfharbinger.mobilefortress` (directories, `build.gradle.kts` namespace/applicationId, ProGuard rules, manifest, `Theme.GameTemplate` → `Theme.MobileFortress`, app name string) and the iOS bundle identifier `com.example.mygame` → `com.acfharbinger.mobilefortress` (`.pbxproj`, `UserDefaults` keys in `SettingsStore`/`HighScoreStore`).
- Renamed the optional backend's Helm chart directory `infra/helm/mobile-game-template/` → `infra/helm/mobile-fortress/` (chart name, template helper names, image repository references), and updated matching image references in `infra/ansible/`, `infra/k8s/`, `infra/terraform/`.
- Scrubbed remaining "Mobile-Game-Template"/generic-template wording from `README.md`, `.agent/` (`AGENTS.md`, prompts, rules, skills, workflows), `docs/` (`index.md`, `ARCHITECTURE.md`, `GLOSSARY.md`, `DEVELOPMENT.md`, `mkdocs.yml`, ADRs 0002/0003), `git/CONTRIBUTING.md`, `LICENSE.txt`, `justfile`, `tools/*/justfile`, `.devcontainer/`, and `.github/ISSUE_TEMPLATE/config.yml` — all now describe Mobile Fortress specifically. Historical "template era" framing in `moon/ROADMAP.md`/`CHANGELOG.md` (documenting the repo's actual scaffolding phase) is intentionally kept.

### Added (template era)

- Initial template scaffolding: root files (`LICENSE`, `README.md`, `.pre-commit-config.yaml`, `.gitignore`), `.github/` CI/CD, `git/` (`CONTRIBUTING.md`, `codecov.yaml`), `docs/` documentation portal (MkDocs + ADRs), `moon/` roadmap and changelog.
- `.agent/` LLM coding-agent scaffolding: `AGENTS.md` plus rules, workflows, prompts, and skills covering Kotlin, Android lifecycle, game-loop performance, Compose UI, testing/QA, code review, debugging, documentation, and planning.
- Standard Android app module (`app/`) built on `com.android.application` + `kotlin-android`: `MainActivity`, `GameView` (SurfaceView), `GameLoop` (fixed-timestep thread), `GameEngine`/`GameState`, one demo entity (`Ball`), one unit test, one instrumented test.
- Root Gradle wrapper and `settings.gradle.kts` including `:app`.
- `infra/{docker,k8s,helm,terraform,ansible}/` — optional, lightweight leaderboards/cloud-save backend scaffolding, explicitly optional for offline play.
- `.devcontainer/` with Android SDK cmdline-tools, JDK 17, and an emulator system image.
- `.github/workflows/ci.yml` (unit tests + lint + instrumented tests via emulator matrix), `release.yml` (signed AAB/APK + optional fastlane Play Store upload), `docs.yml`.

## [0.1.0] — 2026-08-02

### Added

- Repository created from scratch as a GitHub template.
