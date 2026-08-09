# Mobile Fortress — Roadmap

[![Kotlin](https://img.shields.io/badge/Kotlin-2.0-7F52FF?logo=kotlin&logoColor=white)](https://kotlinlang.org/)
[![Android](https://img.shields.io/badge/Android-API_24%2B-3DDC84?logo=android&logoColor=white)](https://developer.android.com/)
[![Swift](https://img.shields.io/badge/Swift-5.0-F05138?logo=swift&logoColor=white)](https://swift.org/)
[![iOS](https://img.shields.io/badge/iOS-16%2B-000000?logo=apple&logoColor=white)](https://developer.apple.com/ios/)
[![C++](https://img.shields.io/badge/C%2B%2B20-Shared_Core_(planned)-00599C?logo=cplusplus&logoColor=white)](https://isocpp.org/)

> **Version**: 4.1
> **Date**: 2026-08-09
> **Status**: Active development

## Overview

**Mobile Fortress** is a cooperative tower-defense mobile game set during the **1540s–1560s Wōkòu (倭寇) / Wakō pirate crisis** on the East Asian coast: players defend a coastal fortress network — a Main HQ/Citadel, Resource Outposts, and Trading Outposts — against raiding Wōkòu pirate fleets striking by land and sea, then extend that defense into a light 4X-style coastal-territory meta-game. The defending garrison is an East Asian primary civilization (Ming China's coastal garrison by default; Japan or Joseon Korea as alternate settings) reinforced by a supporting Western civilization (Portuguese by default, with Spanish/Dutch/British/French alternates). The design targets the market gap identified in [`reports/Tower Defense Market Research.md`](reports/Tower%20Defense%20Market%20Research.md) — a AAA-quality, culturally specific East Asian historical setting is conspicuously absent from the current top-grossing TD/4X-hybrid charts — while the client/server/netcode architecture follows the technical blueprint in [`research/Multiplayer Tower Defense Implementation.md`](research/Multiplayer%20Tower%20Defense%20Implementation.md).

Both source documents live under [`reports/`](reports/Tower%20Defense%20Market%20Research.md) and [`research/`](research/Multiplayer%20Tower%20Defense%20Implementation.md) and are the canonical references for the design and technical decisions summarized below — read them before making significant architecture or monetization changes.

This repository started life as a generic two-platform mobile game template; that scaffolding (Android `SurfaceView` skeleton, iOS SpriteKit skeleton, CI/CD, docs, `.agent/` LLM tooling) is now being seeded with Mobile Fortress' actual game design. Completed template groundwork is listed under [Track: Template Scaffolding](#track-template-scaffolding-complete) below and in [`CHANGELOG.md`](CHANGELOG.md); everything else in this document is the real game roadmap.

Status markers: ✅ Done · 🚧 In Progress · 📋 Pending

---

## Game Concept Summary

| Aspect | Decision | Source |
| --- | --- | --- |
| **Setting** | 1540s–1560s Wōkòu pirate crisis, East Asian coast — Main HQ + Resource/Trading Outpost defense, East Asian primary civ (Ming China default) + Western supporting civ (Portuguese default) | Market Gap 1, Tower Defense Market Research §"Strategic Market Gaps" |
| **Core loop** | Grid-based tower defense spanning land and sea: deploy Ming Garrison Spearmen, Fo-lang-ji Cannon Crews, Portuguese Arquebusiers, and Veteran Commander heroes along Flow-Field-routed land and naval raid lanes | Market Research §"Technical Underpinnings"; Multiplayer TD Implementation §"Flow Fields" |
| **Meta-game** | Coastal-territory light-4X layer over a persistent map; synchronous and asynchronous Co-Op defense of shared strongholds | Market Research §"4X Strategy and Tower Defense Fusion" |
| **Monetization** | Gacha hero-commander banners (Performance Expectancy), cosmetics/skins (Hedonic Motivation), faction-contribution premium currency (Social Influence), frictionless battle pass — Kompu-Gacha-compliant probability disclosure from day one | Market Research §"UTAUT3"; §"Regulatory Pressures" |
| **Shared core** | C++20 simulation core (ECS via EnTT), bridged to Kotlin/Swift via JNI/Swift C++ interop, FlatBuffers zero-copy state serialization | Multiplayer TD Implementation §"ECS", §"Zero-Copy Serialization" (originally researched a Rust/UniFFI approach — see [`shared_core.md`](roadmaps/shared_core.md) for why C++ was chosen instead) — supersedes the "stay documentation-only" default |
| **Multiplayer** | Server-authoritative state sync with client-side prediction/reconciliation; AWS GameLift + FlexMatch for latency-optimized matchmaking and fleet orchestration | Multiplayer TD Implementation §"Server-Authoritative State Synchronization", §"Matchmaking and Fleet Orchestration" |
| **Procedural content / AI** | Wave Function Collapse for siege-map generation; RL-driven dynamic difficulty adjustment; Contextual Multi-Armed Bandits for offer personalization; survival-analysis churn/LTV modeling | Multiplayer TD Implementation §"Algorithmic PCG", §"Dynamic Difficulty Adjustment", §"Optimizing Monetization and Player Retention" |

## Roadmap Phases

| Phase | Focus | Status |
| --- | --- | --- |
| 0 | Template scaffolding (two native clients, CI/CD, docs, agent tooling) | ✅ Done |
| 1 | Single-player Wōkòu-era TD core loop (MVP), per-platform | 🚧 In Progress |
| 2 | Shared C++ simulation core (ECS + JNI/Swift C++ interop), replacing per-platform duplicated engine logic | 📋 Pending |
| 3 | Meta-progression: gacha commanders, clan/territory layer, monetization, LiveOps foundations | 📋 Pending |
| 4 | Server-authoritative Co-Op multiplayer + matchmaking (GameLift/FlexMatch) | 📋 Pending |
| 5 | Procedural content & ML systems (WFC maps, RL difficulty, CMAB offers, churn prediction) | 📋 Pending |
| 6 | LiveOps, regulatory compliance, regional launch | 📋 Pending |
| 7 | Docs-site multi-framework platform (Vue host + React/WASM islands, GraphQL fixtures) | 📋 Pending |

See per-topic detail in [`docs/moon/roadmaps/`](roadmaps/):

- [`gameplay.md`](roadmaps/gameplay.md) — core TD loop, castle defense, hero commanders, pathfinding
- [`ui_ux.md`](roadmaps/ui_ux.md) — menus, HUD, clan UI, accessibility
- [`performance.md`](roadmaps/performance.md) — ECS, Flow Field optimization, profiling
- [`monetization.md`](roadmaps/monetization.md) — gacha, battle pass, UTAUT3 alignment, compliance
- [`backend.md`](roadmaps/backend.md) — server-authoritative netcode, GameLift/FlexMatch, leaderboards, cloud save
- [`ai_systems.md`](roadmaps/ai_systems.md) — Wave Function Collapse procgen, RL dynamic difficulty, CMAB monetization, churn/LTV modeling
- [`qa_testing.md`](roadmaps/qa_testing.md) — determinism/netcode testing, device coverage, retention benchmarks
- [`ios.md`](roadmaps/ios.md) — iOS-specific client work
- [`shared_core.md`](roadmaps/shared_core.md) — C++ shared-core architecture decision (superseded default, now Option B)
- [`multi_framework_platform.md`](roadmaps/multi_framework_platform.md) — Vue-host docs site polyglot islands (React/Astro/Aurelia), GraphQL/Apollo, WASM (MFP1–MFP16)

Completed items move to [`docs/moon/CHANGELOG.md`](CHANGELOG.md).

---

## Track: Template Scaffolding (complete)

| # | Item | Effort | Status |
| --- | --- | --- | --- |
| T1 | Root scaffolding: LICENSE, README, `.pre-commit-config.yaml`, `.gitignore` | S | ✅ Done |
| T2 | `.github/` CI/CD: workflows, issue/PR templates, dependabot | M | ✅ Done |
| T3 | Unified Vue documentation and interactive design portal, including ADRs, roadmaps, design documents, codebase guides, research, and `gh-pages` deployment | M | ✅ Done |
| T3b | Flatten `docs/website/vue` → `docs/website` and nest Vue sources under `src/frameworks/vue` (github-pages-style frameworks layout) | S | ✅ Done |
| T4 | `moon/` roadmap and changelog | S | ✅ Done |
| T5 | `infra/global/{docker,k8s,helm,terraform,ansible}/` optional backend scaffolding (+ cloud/private/server layout) | M | ✅ Done |
| T6 | `.agent/` LLM coding-agent scaffolding | M | ✅ Done |
| T7 | Root `justfile` wrapping Gradle + Xcode tasks | S | ✅ Done |
| T8 | `.devcontainer/` Dev Container definition (Android SDK, JDK 17, emulator) — iOS/Xcode builds require a native macOS host, documented as a known limitation | S | ✅ Done |
| T9 | Standard Android `app/` module skeleton (SurfaceView game loop, one demo entity) — now under `android/` | M | ✅ Done |
| T10 | Unit test + instrumented test skeleton (Android) | S | ✅ Done |
| T11 | `release.yml` signed AAB/APK pipeline + optional fastlane Play Store upload (Android) | M | ✅ Done |
| T12 | iOS `MyGame` app skeleton under `ios/` (SpriteKit + SwiftUI chrome, feature-parity with Android where the two platforms' scope overlaps) | M | ✅ Done |
| T13 | iOS `XCTest` unit test skeleton + shared Xcode scheme for CI | S | ✅ Done |
| T14 | `core/` shared-assets module + documented (non-compiled) state-machine/level-schema spec | S | ✅ Done |

---

## Track: Multi-Framework Docs Platform (planned)

Vue remains the **website host** under `docs/website/src/frameworks/vue`. Research under `docs/moon/research/` (Hybrid Vue/React, Hybrid Micro-Frontend, Vue visualization stack, WASM integration) drives the **MFP1–MFP16** workstream in [`roadmaps/multi_framework_platform.md`](roadmaps/multi_framework_platform.md).

| # | Item | Effort | Status |
| --- | --- | --- | --- |
| MFP-B1 | Host/island ADR + frameworks layout (Vue host complete) | S | 🔄 |
| MFP-B2 | React island mount path + first demo | L | 📋 |
| MFP-B3 | GraphQL schema + Apollo fixtures (static Pages-safe) | M | 📋 |
| MFP-B4 | WASM worker stub for a hub compute demo + JS fallback | L | 📋 |

Native game clients (`android/`, `ios/`, `core/`) stay out of scope for MFP unless a shared tooling UI explicitly needs them.
