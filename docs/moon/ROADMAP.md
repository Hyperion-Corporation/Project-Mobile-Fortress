# Mobile Fortress — Roadmap

[![Godot](https://img.shields.io/badge/Godot-4.x-478CBF?logo=godotengine&logoColor=white)](https://godotengine.org/)
[![C++](https://img.shields.io/badge/C%2B%2B20-Simulation_Core-00599C?logo=cplusplus&logoColor=white)](https://isocpp.org/)
[![Android](https://img.shields.io/badge/Android-13%2B-3DDC84?logo=android&logoColor=white)](https://developer.android.com/)
[![iOS](https://img.shields.io/badge/iOS-17%2B-000000?logo=apple&logoColor=white)](https://developer.apple.com/ios/)

> **Version**: 6.0  
> **Date**: 2026-10-09  
> **Status**: Active development — Slice-0 VS0–VS9 delivered; VS10 playtest gate pending  
> **Decision record**: [`.agent/reports/shared/pmf_20260810_canonical_shared_report.md`](https://github.com/Hyperion-Corporation/Project-Mobile-Fortress/blob/main/.agent/reports/shared/pmf_20260810_canonical_shared_report.md) · [admin status report](https://github.com/Hyperion-Corporation/Project-Mobile-Fortress/blob/main/.agent/reports/admin/pmf_20260809_status_report.md)

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
| **1a** | **Slice-0: offline dual-front Godot prototype** | 🚧 **Current** — VS0–VS9 ✅; VS10 playtest gate pending |
| 1 | Single-player Wōkòu-era loop polish (G3+, economy, heroes) | 🚧 In progress — delivered via agent rounds 1–4; several rows Partial pending playtest data |
| 2 | C++ sim packaging (S0–S5) behind Godot | 🚧 Partial — S0/S1/S3/S4 ✅, S2/S5/S7/S8 🚧, S6 pending (see [`shared_core.md`](roadmaps/shared_core.md)) |
| 3 | Meta: cosmetics/battle pass/skin lootboxes, clans, LiveOps foundations | ⏸ After slice fun |
| 4 | Local Wi‑Fi asymmetric co-op → later online session service | ⏸ After slice fun |
| 5 | ML systems (gated) + sentiment research | 🔬 / ⏸ |
| 6 | LiveOps, compliance, regional launch | ⏸ |
| 7 | Internal dashboard (static/local first; live Docker later) | 🚧 Secondary (25%) — ID2/ID3/ID6 delivered, ID7/ID8 🚧 Partial, ID5 rejected (see [`internal_dashboard.md`](roadmaps/internal_dashboard.md)) |

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
| [`dev_tools.md`](roadmaps/dev_tools.md) | God mode, debug overlay, playtest tooling |

Completed items → [`CHANGELOG.md`](CHANGELOG.md).

---

## Track: Template Scaffolding (complete)

Legacy Android SurfaceView + iOS SpriteKit skeletons, CI/CD, docs, `.agent/`, `infra/` scaffolding. See prior changelog entries. These trees are **not** the primary product path going forward.

---

## Track: Slice-0 — Offline Dual-Front Prototype (current)

**Canonical detail:** [`roadmaps/vertical_slice.md`](roadmaps/vertical_slice.md).

| # | Item | Status |
| --- | --- | --- |
| VS0 | Godot 4 client expansion from `game/project.godot` | ✅ Scaffold playable |
| VS1 | **G2 dual-front core loop** | ✅ Done (classic + modular views) |
| VS2–VS9 | Pathing stub, input, phases, outposts, hero/support, art, save, exports | ✅ Done (see [`vertical_slice.md`](roadmaps/vertical_slice.md) for per-item notes) |
| VS10 | Collaborator playtest + "shows promise" decision record | 🚧 **Protocol ready** — sessions pending ([`VS10_PLAYTEST_PROTOCOL.md`](VS10_PLAYTEST_PROTOCOL.md)) |

**Supersedes:** 2026-08-09 Android-first single-lane VS1–VS5 timebox.

### Where we are (2026-10-09, per-area snapshot — area files are the source of truth)

| Area | Headline status (from the area file) |
| --- | --- |
| [`vertical_slice.md`](roadmaps/vertical_slice.md) | VS0–VS9 ✅; VS10 🚧 Protocol ready |
| [`gameplay.md`](roadmaps/gameplay.md) | G2 playable; G3/G4/G5/G6/G7/G8/G12 🚧 Partial; G10 ✅; G9/G11/G13 deferred |
| [`shared_core.md`](roadmaps/shared_core.md) | S0/S1/S3/S4 ✅; S2/S5/S7/S8 🚧; S6 pending |
| [`ui_ux.md`](roadmaps/ui_ux.md) | U2/U3 ✅; U8/U9/U10 delivered; U4 HUD delivered, T70 layout held for snapshot compatibility (T76); U1 slice-0 theme; U5–U7 deferred |
| [`dev_tools.md`](roadmaps/dev_tools.md) | DT1–DT8 🚧 Slice-0 wired |
| [`performance.md`](roadmaps/performance.md) | P3/P4/P7 🚧 Partial (headless baselines; on-device runs open); rest pending |
| [`qa_testing.md`](roadmaps/qa_testing.md) | Q1 ✅; Q2/Q3/Q4 🚧 Partial; Q10 pending — Slice-0 exit gate |
| [`ai_systems.md`](roadmaps/ai_systems.md) | A4 🚧 Partial (off by default, tuning pending playtests); rest research/deferred |
| [`ios.md`](roadmaps/ios.md) | IOS1–IOS3 🚧 Partial (device runs need macOS) |
| [`internal_dashboard.md`](roadmaps/internal_dashboard.md) | ID2/ID3/ID6 ✅; ID7/ID8 🚧 Partial; ID1 in progress; ID5 rejected |
| [`monetization.md`](roadmaps/monetization.md) | M1 ❌ rejected (power gacha); M3 first track pending after slice fun |
| [`backend.md`](roadmaps/backend.md) | B1 ✅; rest deferred |
| [`co_op_modes.md`](roadmaps/co_op_modes.md) | C1 ✅ schema doc delivered; implementation deferred post Slice-0 |

---

## Track: Internal Dashboard (secondary)

React host under `docs/website/`. **Static/local/batch first**; live remote not required for small team. See [`internal_dashboard.md`](roadmaps/internal_dashboard.md): ID2 (IA/wireframes), ID3 (dashboard skeleton) and ID6 (lore map) are delivered; ID7 (visualizer) and ID8 (interactive demo) are Partial; ID5 real-time WebSocket remains rejected for v1. Sentiment automation is research (A12/A13), not launch automation.

---

## Immediate execution order

1. **VS10 playtest gate** — owner + collaborator sessions per [`VS10_PLAYTEST_PROTOCOL.md`](VS10_PLAYTEST_PROTOCOL.md); both must reach "shows promise" (Phase 1a exit)  
2. Post-gate polish backlog: Flow-Field presentation depth (G3/S2), A4 DDA tuning against playtest data, on-device perf runs (P7/P8, Android arm64 core under S8)  
3. Local Wi‑Fi asymmetric co-op design implementation (C2+) after Phase 1a  
4. Cosmetics/monetization track (M3) after slice fun is confirmed  

**Do not** start with multiplayer fleet, power gacha, or autonomous sentiment balancing.
