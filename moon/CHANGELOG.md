# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

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
