# Mobile-Game-Template Documentation

Welcome to the documentation portal for this repository. This site is built with [MkDocs Material](https://squidfunk.github.io/mkdocs-material/).

> **TODO:** Replace this landing page with a real project overview once this template is used to seed an actual game.

This is a two-client repository: a Kotlin Android app (`android/`) and a Swift iOS app (`ios/`), sharing raw assets and a documented spec under `core/`.

## Where to start

- [Architecture](ARCHITECTURE.md) — system design, module boundaries (both clients), and the rendering-approach decisions
- [Development](DEVELOPMENT.md) — local setup for Android Studio + emulator, and Xcode + Simulator (macOS host required for iOS)
- [Testing](TESTING.md) — how to run and write Android unit/instrumented tests and iOS XCTest suites
- [Glossary](GLOSSARY.md) — project-specific terms, both platforms
- [`moon/ROADMAP.md`](../moon/ROADMAP.md) — what's planned
- [`moon/CHANGELOG.md`](../moon/CHANGELOG.md) — what shipped
- [Architecture Decision Records](adr/) — significant, hard-to-reverse decisions, including the per-platform rendering-approach ADRs
