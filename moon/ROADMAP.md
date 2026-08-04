# Mobile Fortress — Roadmap

[![Kotlin](https://img.shields.io/badge/Kotlin-2.0-7F52FF?logo=kotlin&logoColor=white)](https://kotlinlang.org/)
[![Android](https://img.shields.io/badge/Android-API_24%2B-3DDC84?logo=android&logoColor=white)](https://developer.android.com/)
[![Swift](https://img.shields.io/badge/Swift-5.0-F05138?logo=swift&logoColor=white)](https://swift.org/)
[![iOS](https://img.shields.io/badge/iOS-16%2B-000000?logo=apple&logoColor=white)](https://developer.apple.com/ios/)
[![Rust](https://img.shields.io/badge/Rust-Shared_Core_(planned)-000000?logo=rust&logoColor=white)](https://www.rust-lang.org/)

> **Version**: 3.0
> **Date**: 2026-08-04
> **Status**: Active development

## Overview

**Mobile Fortress** is a cooperative tower-defense mobile game set in **1520s Sengoku-period Japan**: players defend a Daimyo's castle against sieging armies of Ashigaru, rival Samurai clans, and Yokai-corrupted invaders, then extend that defense into a light 4X-style clan/territory meta-game. The design targets the market gap identified in [`reports/Tower Defense Market Research.md`](../reports/Tower%20Defense%20Market%20Research.md) — a AAA-quality, culturally specific Feudal Japan setting is conspicuously absent from the current top-grossing TD/4X-hybrid charts — while the client/server/netcode architecture follows the technical blueprint in [`research/Multiplayer Tower Defense Implementation.md`](../research/Multiplayer%20Tower%20Defense%20Implementation.md).

Both source documents live under [`reports/`](../reports/) and [`research/`](../research/) and are the canonical references for the design and technical decisions summarized below — read them before making significant architecture or monetization changes.

This repository started life as a generic two-platform mobile game template; that scaffolding (Android `SurfaceView` skeleton, iOS SpriteKit skeleton, CI/CD, docs, `.agent/` LLM tooling) is now being seeded with Mobile Fortress' actual game design. Completed template groundwork is listed under [Track: Template Scaffolding](#track-template-scaffolding-complete) below and in [`CHANGELOG.md`](CHANGELOG.md); everything else in this document is the real game roadmap.

Status markers: ✅ Done · 🚧 In Progress · 📋 Pending

---

## Game Concept Summary

| Aspect | Decision | Source |
| --- | --- | --- |
| **Setting** | 1520s Sengoku Japan — Daimyo's castle defense | Market Gap 1, Tower Defense Market Research §"Strategic Market Gaps" |
| **Core loop** | Grid-based tower defense: deploy Ashigaru spearmen, Matchlock gunners, and Samurai hero-commanders along Flow-Field-routed siege lanes | Market Research §"Technical Underpinnings"; Multiplayer TD Implementation §"Flow Fields" |
| **Meta-game** | Clan/territory light-4X layer over a persistent map; synchronous and asynchronous Co-Op defense of shared strongholds | Market Research §"4X Strategy and Tower Defense Fusion" |
| **Monetization** | Gacha hero-commander banners (Performance Expectancy), cosmetics/skins (Hedonic Motivation), clan-contribution premium currency (Social Influence), frictionless battle pass — Kompu-Gacha-compliant probability disclosure from day one | Market Research §"UTAUT3"; §"Regulatory Pressures" |
| **Shared core** | Rust simulation core (ECS via `hecs`), bridged to Kotlin/Swift via UniFFI, `rkyv` zero-copy state serialization | Multiplayer TD Implementation §"Rust and UniFFI Paradigm", §"ECS", §"Zero-Copy Serialization" — supersedes the "stay documentation-only" default in [`shared_core.md`](roadmaps/shared_core.md) |
| **Multiplayer** | Server-authoritative state sync with client-side prediction/reconciliation; AWS GameLift + FlexMatch for latency-optimized matchmaking and fleet orchestration | Multiplayer TD Implementation §"Server-Authoritative State Synchronization", §"Matchmaking and Fleet Orchestration" |
| **Procedural content / AI** | Wave Function Collapse for siege-map generation; RL-driven dynamic difficulty adjustment; Contextual Multi-Armed Bandits for offer personalization; survival-analysis churn/LTV modeling | Multiplayer TD Implementation §"Algorithmic PCG", §"Dynamic Difficulty Adjustment", §"Optimizing Monetization and Player Retention" |

## Roadmap Phases

| Phase | Focus | Status |
| --- | --- | --- |
| 0 | Template scaffolding (two native clients, CI/CD, docs, agent tooling) | ✅ Done |
| 1 | Single-player Sengoku TD core loop (MVP), per-platform | 🚧 In Progress |
| 2 | Shared Rust simulation core (ECS + UniFFI), replacing per-platform duplicated engine logic | 📋 Pending |
| 3 | Meta-progression: gacha commanders, clan/territory layer, monetization, LiveOps foundations | 📋 Pending |
| 4 | Server-authoritative Co-Op multiplayer + matchmaking (GameLift/FlexMatch) | 📋 Pending |
| 5 | Procedural content & ML systems (WFC maps, RL difficulty, CMAB offers, churn prediction) | 📋 Pending |
| 6 | LiveOps, regulatory compliance, regional launch | 📋 Pending |

See per-topic detail in [`moon/roadmaps/`](roadmaps/):

- [`gameplay.md`](roadmaps/gameplay.md) — core TD loop, castle defense, hero commanders, pathfinding
- [`ui_ux.md`](roadmaps/ui_ux.md) — menus, HUD, clan UI, accessibility
- [`performance.md`](roadmaps/performance.md) — ECS, Flow Field optimization, profiling
- [`monetization.md`](roadmaps/monetization.md) — gacha, battle pass, UTAUT3 alignment, compliance
- [`backend.md`](roadmaps/backend.md) — server-authoritative netcode, GameLift/FlexMatch, leaderboards, cloud save
- [`ai_systems.md`](roadmaps/ai_systems.md) — Wave Function Collapse procgen, RL dynamic difficulty, CMAB monetization, churn/LTV modeling
- [`qa_testing.md`](roadmaps/qa_testing.md) — determinism/netcode testing, device coverage, retention benchmarks
- [`ios.md`](roadmaps/ios.md) — iOS-specific client work
- [`shared_core.md`](roadmaps/shared_core.md) — Rust/UniFFI shared-core architecture decision (superseded default, now Option B)

Completed items move to [`moon/CHANGELOG.md`](CHANGELOG.md).

---

## Track: Template Scaffolding (complete)

| # | Item | Effort | Status |
| --- | --- | --- | --- |
| T1 | Root scaffolding: LICENSE, README, `.pre-commit-config.yaml`, `.gitignore` | S | ✅ Done |
| T2 | `.github/` CI/CD: workflows, issue/PR templates, dependabot | M | ✅ Done |
| T3 | `docs/` documentation portal: MkDocs, ADRs | M | ✅ Done |
| T4 | `moon/` roadmap and changelog | S | ✅ Done |
| T5 | `infra/{docker,k8s,helm,terraform,ansible}/` optional backend scaffolding | M | ✅ Done |
| T6 | `.agent/` LLM coding-agent scaffolding | M | ✅ Done |
| T7 | Root `justfile` wrapping Gradle + Xcode tasks | S | ✅ Done |
| T8 | `.devcontainer/` Dev Container definition (Android SDK, JDK 17, emulator) — iOS/Xcode builds require a native macOS host, documented as a known limitation | S | ✅ Done |
| T9 | Standard Android `app/` module skeleton (SurfaceView game loop, one demo entity) — now under `android/` | M | ✅ Done |
| T10 | Unit test + instrumented test skeleton (Android) | S | ✅ Done |
| T11 | `release.yml` signed AAB/APK pipeline + optional fastlane Play Store upload (Android) | M | ✅ Done |
| T12 | iOS `MyGame` app skeleton under `ios/` (SpriteKit + SwiftUI chrome, feature-parity with Android where the two platforms' scope overlaps) | M | ✅ Done |
| T13 | iOS `XCTest` unit test skeleton + shared Xcode scheme for CI | S | ✅ Done |
| T14 | `core/` shared-assets module + documented (non-compiled) state-machine/level-schema spec | S | ✅ Done |
