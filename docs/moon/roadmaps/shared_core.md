# Shared Core Roadmap — C++ + Godot (decided)

**Owner:** TBD

**2026-08-11 note (final multi-agent pass):** C++ remains firm. The primary **game client is Godot 4** (`core/project.godot`, Godot 4.7 seed). Owner direction: use **both godot-cpp (GDExtension) and C++ modules** where appropriate. Prior JNI/Swift-C++-interop-only framing is demoted — native SurfaceView/SpriteKit clients are no longer the primary presentation path. Server-authoritative replication is sufficient for online play (lockstep not required).

## Decision: C++ simulation with Godot presentation

| Layer | Technology | Purpose |
| --- | --- | --- |
| Presentation / tools | **Godot 4** (isometric 2.5D, exports to Android/iOS) | Unified client; abandons SurfaceView/SpriteKit as primary |
| Simulation | **C++20**, ECS via [EnTT](https://github.com/skypjack/entt) | Pathfinding, combat, economy systems |
| Godot integration | **godot-cpp (GDExtension)** and/or **C++ modules** | Owner: use both patterns as needed; exact boundary still spiked in S0 |
| Serialization | [FlatBuffers](https://flatbuffers.dev/) | State snapshots for save, tools, and later netcode |
| Optional packaging | Kotlin Multiplatform only if Godot export is insufficient for platform services | Not a second game stack by default |
| Dependency management | CMake + [vcpkg](https://vcpkg.io/) (manifest mode) for pure sim libs; Godot build for client | See [`docs/DEPENDENCY_POLICY.md`](../../DEPENDENCY_POLICY.md) |

### Why not the old dual-native default

- Dual Kotlin + Swift game clients double cost for a 3-person team.
- Godot unifies mobile (+ optional desktop) rendering and input.
- C++ remains for CPU-bound sim / research (swarm, RL hooks) and org consistency.

### Trade-offs vs. a Rust core

Unchanged: RAII, ASan/UBSan/TSan, `clang-tidy` are mandatory mitigations for C++ without a borrow checker.

## Roadmap

| # | Item | Effort | Status |
| --- | --- | --- | --- |
| S0 | **Spike:** Godot↔C++ boundary — GDExtension vs module layout, tick ownership, sample FlatBuffers state round-trip | M | 📋 Pending · parallel with VS1 |
| S1 | Stand up C++ workspace (CMake + vcpkg) with EnTT skeleton (position/velocity/health) | L | 📋 Pending |
| S2 | Port / implement pathfinding (Flow Field or interim) in C++ core | L | 📋 Pending |
| S3 | Wire godot-cpp and/or C++ module so Godot scenes call into the sim | M | 📋 Pending |
| S4 | FlatBuffers state snapshot for save/load and later replication | M | 📋 Pending |
| S5 | Move dual-front game logic out of GDScript/C# prototypes into C++ systems; Godot remains presentation/input | XL | 📋 Pending |
| S6 | Async/job bridging between sim thread and Godot main thread (with TSan coverage) | M | 📋 Pending |
| S7 | Cross-platform regression suite (fixed seed; soft determinism OK — lockstep not required) | L | 📋 Pending |
| S8 | Android 13+ / iOS 17+ export packaging for the Godot client | M | 📋 Pending |

Effort key: S = days, M = 1–2 weeks, L = 3–6 weeks, XL = multi-month/cross-cutting.

## Historical note

Earlier docs assumed Kotlin JNI + Swift C++ interop with dual native renderers, and researched Rust/UniFFI. Those remain in research/CHANGELOG history. Active work follows Godot + C++ as above.
