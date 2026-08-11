# Shared Core Roadmap — C++ + Godot (decided)

**Owner:** TBD

**2026-08-11 note (final multi-agent pass):** C++ remains firm. The primary **game client is Godot 4**. Owner direction: use **both godot-cpp (GDExtension) and C++ modules** where appropriate.

**2026-08-11 implementation note:** GDExtension `SimulationCore` is live under `core/src/cpp/` + `mobile_fortress_core.gdextension` (raiders, defenders, outposts, dual currency, HQ). Build: [`core/BUILD_CPP.md`](../../../core/BUILD_CPP.md). Epic #129.

## Decision: C++ simulation with Godot presentation

| Layer | Technology | Purpose |
| --- | --- | --- |
| Presentation / tools | **Godot 4** (isometric 2.5D, exports to Android/iOS) | Unified client |
| Simulation | **C++20**, ECS via [EnTT](https://github.com/skypjack/entt) | Pathing, combat, economy |
| Godot integration | **godot-cpp (GDExtension)** first; C++ modules later if needed | Owner C4 |
| Serialization | [FlatBuffers](https://flatbuffers.dev/) | Snapshots / net later |
| Dependency management | CMake + FetchContent (godot-cpp, EnTT); optional vcpkg | See `core/CMakeLists.txt` |

## Roadmap

| # | Item | Effort | Status |
| --- | --- | --- | --- |
| S0 | **Spike:** Godot↔C++ boundary (GDExtension) | M | ✅ **Done** — `SimulationCore` loads in Godot 4.7 |
| S1 | C++ workspace (CMake) with EnTT skeleton | L | ✅ **Done** — `core/CMakeLists.txt` + EnTT components |
| S2 | Pathfinding in C++ (Flow Field later; lane paths now) | L | 🚧 **Partial** — lane waypoint motion; Flow Field still open (#69) |
| S3 | Wire godot-cpp so Godot scenes call into the sim | M | ✅ **Done** — modular `battle_root` + classic `main.gd` |
| S4 | FlatBuffers state snapshot for save/load and later replication | M | ✅ **Done** — `save_state`/`load_state` + `src/schema/simulation_state.fbs` |
| S5 | Move dual-front game logic into C++; Godot presentation | XL | 🚧 **In progress** — defenders/raiders/outposts/combat in C++; UX still Godot |
| S6 | Async/job bridging sim thread ↔ Godot main (TSan) | M | 📋 Pending (retarget from Kotlin/Swift era) |
| S7 | Cross-platform regression suite (soft determinism) | L | 🚧 **Partial** — headless smokes in `core/tests/` |
| S8 | Android 13+ / iOS 17+ Godot export packaging | M | 📋 Pending |

Effort key: S = days, M = 1–2 weeks, L = 3–6 weeks, XL = multi-month/cross-cutting.
