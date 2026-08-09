# Mobile Fortress — Roadmap

[![Kotlin](https://img.shields.io/badge/Kotlin-2.0-7F52FF?logo=kotlin&logoColor=white)](https://kotlinlang.org/)
[![Android](https://img.shields.io/badge/Android-API_24%2B-3DDC84?logo=android&logoColor=white)](https://developer.android.com/)
[![Swift](https://img.shields.io/badge/Swift-5.0-F05138?logo=swift&logoColor=white)](https://swift.org/)
[![iOS](https://img.shields.io/badge/iOS-16%2B-000000?logo=apple&logoColor=white)](https://developer.apple.com/ios/)
[![C++](https://img.shields.io/badge/C%2B%2B20-Shared_Core_(planned)-00599C?logo=cplusplus&logoColor=white)](https://isocpp.org/)

> **Version**: 4.2
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
| 1a | **Playable vertical slice** (Android-first, timeboxed) — grid + naive pathfinding + touch input + one tower/enemy type + HQ win/lose, no art, no meta-progression | 🚧 In Progress — target 2026-08-23 |
| 1 | Single-player Wōkòu-era TD core loop (MVP), per-platform | 🚧 In Progress |
| 2 | Shared C++ simulation core (ECS + JNI/Swift C++ interop), replacing per-platform duplicated engine logic | 📋 Pending |
| 3 | Meta-progression: gacha commanders, clan/territory layer, monetization, LiveOps foundations | 📋 Pending |
| 4 | Server-authoritative Co-Op multiplayer + matchmaking (GameLift/FlexMatch) | 📋 Pending |
| 5 | Procedural content & ML systems (WFC maps, RL difficulty, CMAB offers, churn prediction) | 📋 Pending |
| 6 | LiveOps, regulatory compliance, regional launch | 📋 Pending |
| 7 | Internal dashboard: docs-site multi-framework platform (React host + Astro/Aurelia/Apollo islands) plus product/telemetry dashboard | 📋 Pending |

**Ownership note (2026-08-09, multi-agent brainstorm session):** this is a small team, not a solo effort. Track ownership is recorded per roadmap file below; most tracks are `Owner: TBD` pending role assignment — the one settled exception is [`ai_systems.md`](roadmaps/ai_systems.md), owned by ACFHarbinger (ML/RL/optimization research track).

See per-topic detail in [`docs/moon/roadmaps/`](roadmaps/):

| Roadmap | Scope | Owner |
| --- | --- | --- |
| [`gameplay.md`](roadmaps/gameplay.md) | core TD loop, castle defense, hero commanders, pathfinding | TBD |
| [`ui_ux.md`](roadmaps/ui_ux.md) | menus, HUD, clan UI, accessibility | TBD |
| [`performance.md`](roadmaps/performance.md) | ECS, Flow Field optimization, profiling | TBD |
| [`monetization.md`](roadmaps/monetization.md) | gacha, battle pass, UTAUT3 alignment, compliance | TBD |
| [`backend.md`](roadmaps/backend.md) | server-authoritative netcode, GameLift/FlexMatch, leaderboards, cloud save | TBD |
| [`ai_systems.md`](roadmaps/ai_systems.md) | Wave Function Collapse procgen, RL dynamic difficulty, CMAB monetization, churn/LTV modeling | **ACFHarbinger** |
| [`qa_testing.md`](roadmaps/qa_testing.md) | determinism/netcode testing, device coverage, retention benchmarks | TBD |
| [`ios.md`](roadmaps/ios.md) | iOS-specific client work | TBD |
| [`shared_core.md`](roadmaps/shared_core.md) | C++ shared-core architecture decision (superseded default, now Option B) | TBD |
| [`internal_dashboard.md`](roadmaps/internal_dashboard.md) | docs site polyglot islands (React/Astro/Aurelia), GraphQL/Apollo, WASM (MFP1–MFP16), and the internal product/telemetry dashboard built on top of them (ID1–ID11) | TBD |
| [`repo_automation.md`](roadmaps/repo_automation.md) | `git/` tooling: GitHub Project board sync, subagent-delegation conventions (RA1–RA4) | TBD |

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

## Track: Playable Vertical Slice (in progress, 2026-08-09 → 2026-08-23)

**Decided in the 2026-08-09 multi-agent brainstorm session:** roadmap/architecture work had run far ahead of a single played frame of actual gameplay (both `android/`'s `engine/` and `ios/`'s `Scenes/` are still the inherited template skeletons — a bouncing-ball demo and a generic top-down shooter, respectively; see [`.agent/reports/claude/PMF_Analysis_2026-08-09.md`](../../.agent/reports/claude/PMF_Analysis_2026-08-09.md) for the full reasoning). Rather than gate all other roadmap work, this track is **timeboxed**: a hard 2-week target (2026-08-09 → 2026-08-23) to get a playable, placeholder-art, single-lane fortress-defense loop running on Android, while other tracks continue in parallel.

| # | Item | Effort | Platform | Status |
| --- | --- | --- | --- | --- |
| VS1 | Minimal grid-based fortress-defense loop: one lane, one placeholder tower type, one placeholder enemy type, HQ HP win/lose condition — a cut-down slice of [`gameplay.md`](roadmaps/gameplay.md) G2 | M | Android first | 🚧 In Progress |
| VS2 | Naive per-unit pathfinding (A\* or even a fixed lane path) as a stand-in for the full Flow Field system ([`gameplay.md`](roadmaps/gameplay.md) G3) — full Flow Field is not required to validate pacing/feel | S | Android first | 📋 Pending |
| VS3 | Touch input for tower placement ([`gameplay.md`](roadmaps/gameplay.md) G10), cut down to the single lane above | S | Android first | 📋 Pending |
| VS4 | Play it. Record what the slice teaches about pacing, lane/tower tension, and the Day/Night structure (G6) before any further Phase 3–7 roadmap depth is added | S | — | 📋 Pending |
| VS5 | Port the validated slice to iOS (`Scenes/GameLevel/GameScene.swift`), once VS1–VS4 are done on Android | M | iOS | 📋 Pending — follows VS1–VS4 |

Effort key: S = days, M = 1–2 weeks. **Owner:** TBD.

## Track: Internal Dashboard (planned)

React is the **website host** under `docs/website/src/frameworks/react` (migrated from the original Vue host — see [`internal_dashboard.md`](roadmaps/internal_dashboard.md) Document history). Research under `docs/moon/research/` (Hybrid Vue/React, Hybrid Micro-Frontend, Vue visualization stack, WASM integration) drove the delivered **MFP1–MFP16** infrastructure workstream; the **ID1–ID11** deliverables in [`roadmaps/internal_dashboard.md`](roadmaps/internal_dashboard.md) build the actual product/telemetry dashboard on top of it (absorbing the former `product-metrics` GitHub issues #120–125). See that file for the full deliverable index — this section intentionally doesn't duplicate it.

Native game clients (`android/`, `ios/`, `core/`) stay out of scope for MFP unless a shared tooling UI explicitly needs them.
