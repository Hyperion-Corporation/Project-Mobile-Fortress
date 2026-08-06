# Mobile Fortress Documentation

Welcome to the documentation portal for **Mobile Fortress** — a cooperative tower-defense mobile game set during the 1540s–1560s Wōkòu pirate crisis on the East Asian coast. The primary, deployed way to read this documentation is the interactive site under [`docs/website/`](website/) (a Vue 3 SPA combining the design hub with a live doc reader, published to [GitHub Pages](https://acfharbinger.github.io/Project-Mobile-Fortress/)); this MkDocs-built portal ([MkDocs Material](https://squidfunk.github.io/mkdocs-material/)) remains available for local browsing (`mkdocs serve --config-file docs/mkdocs.yml`).

See [`moon/ROADMAP.md`](moon/ROADMAP.md) for the full game concept and phased delivery plan.

This is a two-client repository: a Kotlin Android app (`android/`) and a Swift iOS app (`ios/`), sharing raw assets and a documented spec under `core/` (migrating to a compiled Rust shared core — see [`moon/roadmaps/shared_core.md`](moon/roadmaps/shared_core.md)).

## Where to start

- [Architecture](ARCHITECTURE.md) — system design, module boundaries (both clients), and the rendering-approach decisions
- [Development](DEVELOPMENT.md) — local setup for Android Studio + emulator, and Xcode + Simulator (macOS host required for iOS)
- [Testing](TESTING.md) — how to run and write Android unit/instrumented tests and iOS XCTest suites
- [Glossary](GLOSSARY.md) — project-specific terms, both platforms
- [Troubleshooting](TROUBLESHOOTING.md) — common Android/iOS/CI/docs-site build failures and fixes
- [Dependency Policy](DEPENDENCY_POLICY.md) — version requirements, pinning, and upgrade cadence per stack
- [Documentation Standards](DOCUMENTATION_STANDARDS.md) — KDoc/DocC/Markdown conventions and where a fact belongs
- [Benchmarks](BENCHMARKS.md) — target performance budgets and the planned benchmark suite
- [`moon/ROADMAP.md`](moon/ROADMAP.md) — what's planned
- [`moon/CHANGELOG.md`](moon/CHANGELOG.md) — what shipped
- [Architecture Decision Records](adr/) — significant, hard-to-reverse decisions, including the per-platform rendering-approach ADRs
