# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Game design and technical architecture research: `reports/Tower Defense Market Research.md` (market/genre/monetization analysis) and `research/Multiplayer Tower Defense Implementation.md` (Rust/UniFFI shared core, ECS, netcode, matchmaking, and ML systems research), informing the roadmap below.
- Rewrote `moon/ROADMAP.md` and all `moon/roadmaps/*.md` around the concrete game concept: **Mobile Fortress**, a cooperative tower-defense game set in 1520s Sengoku Japan with a light 4X clan/territory meta-game, a planned Rust shared simulation core, server-authoritative Co-Op netcode, and procedural/ML systems (Flow Field pathfinding, Wave Function Collapse, RL-based dynamic difficulty, CMAB-personalized offers).
- New `moon/roadmaps/ai_systems.md` tracking procedural content generation and ML-driven difficulty/monetization/retention systems.
- Rewrote `README.md` and updated `.agent/AGENTS.md`'s project overview to describe Mobile Fortress instead of the generic template.
- Filed 76 GitHub issues (one per roadmap line item across `gameplay`, `ui_ux`, `performance`, `monetization`, `backend`, `qa_testing`, `ios`, `shared_core`, `ai_systems`), each labeled `roadmap:<topic>`, and added them all to the [Project Mobile Fortress](https://github.com/users/ACFHarbinger/projects/17) GitHub Project board.

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
