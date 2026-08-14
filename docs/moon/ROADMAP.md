# Mobile Fortress — Roadmap

[![Godot](https://img.shields.io/badge/Godot-4.x-478CBF?logo=godotengine&logoColor=white)](https://godotengine.org/)
[![C++](https://img.shields.io/badge/C%2B%2B20-Simulation_Core-00599C?logo=cplusplus&logoColor=white)](https://isocpp.org/)
[![Android](https://img.shields.io/badge/Android-13%2B-3DDC84?logo=android&logoColor=white)](https://developer.android.com/)
[![iOS](https://img.shields.io/badge/iOS-17%2B-000000?logo=apple&logoColor=white)](https://developer.apple.com/ios/)

> **Version**: 5.0  
> **Date**: 2026-08-11  
> **Status**: Active development — post multi-agent final pass  
> **Decision record**: [`.agent/reports/shared/pmf_20260810_canonical_shared_report.md`](../../.agent/reports/shared/pmf_20260810_canonical_shared_report.md) · [admin status report](../../.agent/reports/admin/pmf_20260809_status_report.md)

## Overview

**Mobile Fortress** is a cooperative tower-defense game set during the **1540s–1560s Wōkòu (倭寇) pirate crisis** on the East Asian coast: players defend a coastal fortress network (Main HQ, Resource Outposts, Trading Outposts) against land-and-sea raids, commanding an East Asian primary civilization (**Ming** default) reinforced by a Western supporting civilization (**Portuguese** default).

**Near-term priority (75% game / 25% website):** an offline **dual-front** Godot 4 prototype that **shows promise** to the owner and two collaborators. Portfolio/research first, commercial second (≈60/40).

Status markers: ✅ Done · 🚧 In Progress · 📋 Pending · ❌ Rejected · 🔬 Research · ⏸ Deferred

---

## Game Concept Summary

| Aspect | Decision | Notes |
| --- | --- | --- |
| **Setting** | 1540s–1560s Wōkòu coast; historical aesthetics + accessible fiction | Market research gap |
| **Core loop** | Dual land/sea grids; build vs combat phases; heroes (aura + active); cross-front synergy | [`gameplay.md`](roadmaps/gameplay.md) |
| **Presentation** | Isometric 2.5D on **Godot 4**; ukiyo-e-readable art bar | Supersedes SurfaceView/SpriteKit primary |
| **Simulation** | **C++20** (EnTT, FlatBuffers); godot-cpp **and** C++ modules | [`shared_core.md`](roadmaps/shared_core.md) |
| **Co-op** | Asymmetric land/sea = launch pillar; **local Wi‑Fi first**; not in Slice-0 | [`co_op_modes.md`](roadmaps/co_op_modes.md) |
| **Online** | Server-authoritative replication when needed; offline campaign first | GameLift **not** mandatory |
| **Monetization** | Cosmetics → battle pass → skin lootboxes; **no** gameplay gacha; rewarded ads only | [`monetization.md`](roadmaps/monetization.md) |
| **ML** | Identity: RL DDA + swarm/evo; CMAB later; WFC/TGNN research; sentiment HITL | [`ai_systems.md`](roadmaps/ai_systems.md) |
| **Targets** | Android 13+, iOS 17+; 30+ FPS; 10–40 units | |

---

## Roadmap Phases

| Phase | Focus | Status |
| --- | --- | --- |
| 0 | Template scaffolding (legacy native clients, CI, docs, agent tooling) | ✅ Done |
| **1a** | **Slice-0: offline dual-front Godot prototype** | 🚧 **Current** |
| 1 | Single-player Wōkòu-era loop polish (G3+, economy, heroes) | 📋 Pending |
| 2 | C++ sim packaging (S0–S5) behind Godot | 📋 Parallel after VS1 starts |
| 3 | Meta: cosmetics/battle pass/skin lootboxes, clans, LiveOps foundations | ⏸ After slice fun |
| 4 | Local Wi‑Fi asymmetric co-op → later online session service | ⏸ After slice fun |
| 5 | ML systems (gated) + sentiment research | 🔬 / ⏸ |
| 6 | LiveOps, compliance, regional launch | ⏸ |
| 7 | Internal dashboard (static/local first; live Docker later) | ⏸ Secondary (25%) |

**Ownership:** small team (3 humans). Track owners mostly TBD; [`ai_systems.md`](roadmaps/ai_systems.md) owned by ACFHarbinger.

### Topic roadmaps

| Roadmap | Scope |
| --- | --- |
| [`vertical_slice.md`](roadmaps/vertical_slice.md) | **Slice-0 acceptance + deliverables** |
| [`co_op_modes.md`](roadmaps/co_op_modes.md) | Asymmetric co-op design (implement later) |
| [`gameplay.md`](roadmaps/gameplay.md) | Core TD loop, heroes, outposts |
| [`shared_core.md`](roadmaps/shared_core.md) | Godot + C++ architecture |
| [`ui_ux.md`](roadmaps/ui_ux.md) | Menus, HUD, shop UI |
| [`performance.md`](roadmaps/performance.md) | 30 FPS / 40-unit budgets |
| [`monetization.md`](roadmaps/monetization.md) | Cosmetics-first; no power gacha |
| [`backend.md`](roadmaps/backend.md) | Online services (deferred) |
| [`ai_systems.md`](roadmaps/ai_systems.md) | DDA, swarm, CMAB, sentiment research |
| [`qa_testing.md`](roadmaps/qa_testing.md) | Tests + playtest gates |
| [`ios.md`](roadmaps/ios.md) | Godot iOS export path |
| [`internal_dashboard.md`](roadmaps/internal_dashboard.md) | React dashboard + MFP islands |
| [`repo_automation.md`](roadmaps/repo_automation.md) | Issue sync / agent process |
| [`dev_tools.md`](roadmaps/dev_tools.md) | **Draft** — god mode, debug overlay, playtest tooling |

Completed items → [`CHANGELOG.md`](CHANGELOG.md).

---

## Track: Template Scaffolding (complete)

Legacy Android SurfaceView + iOS SpriteKit skeletons, CI/CD, docs, `.agent/`, `infra/` scaffolding. See prior changelog entries. These trees are **not** the primary product path going forward.

---

## Track: Slice-0 — Offline Dual-Front Prototype (current)

**Canonical detail:** [`roadmaps/vertical_slice.md`](roadmaps/vertical_slice.md).

| # | Item | Status |
| --- | --- | --- |
| VS0 | Godot 4 client expansion from `core/project.godot` | 🚧 |
| VS1 | **G2 dual-front core loop** | 📋 **Next implement** |
| VS2–VS10 | Pathing stub, input, phases, outposts, hero/support, art, save, exports, playtest | 📋 |

**Supersedes:** 2026-08-09 Android-first single-lane VS1–VS5 timebox.

---

## Track: Internal Dashboard (secondary)

React host under `docs/website/`. **Static/local/batch first**; live remote not required for small team. See [`internal_dashboard.md`](roadmaps/internal_dashboard.md). ID5 real-time WebSocket remains rejected for v1. Sentiment automation is research (A12/A13), not launch automation.

---

## Immediate execution order

1. **G2 / VS1** dual-front playable loop on Godot  
2. S0 Godot↔C++ spike (godot-cpp + modules) in parallel when capacity allows  
3. VS playtest gate (“shows promise”)  
4. Then G3 pathing depth, cosmetics track, local Wi‑Fi co-op design implementation  

**Do not** start with multiplayer fleet, power gacha, or autonomous sentiment balancing.
