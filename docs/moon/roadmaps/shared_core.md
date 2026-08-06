# Shared Core Roadmap — C++ (decided)

Today `core/` is assets + documentation only — see [`core/README.md`](https://github.com/ACFHarbinger/Project-Mobile-Fortress/blob/main/core/README.md). **This decision is now made**: Mobile Fortress requires a real compiled shared simulation core, not documentation-only convention, because Co-Op multiplayer needs bit-identical simulation state across both native clients. See [`research/Multiplayer Tower Defense Implementation.md`](../../research/Multiplayer%20Tower%20Defense%20Implementation.md) §"Architecting the Shared Computational Core" for the full evaluation.

## Decision: Option B — C++ core, bridged via JNI (Android) and Swift C++ interop (iOS)

The shared core is implemented in C++20 and bridged to Kotlin (Android) via JNI and to Swift (iOS) via Swift's native C++ interoperability (falling back to an Objective-C++ shim for any construct Swift can't import directly). Rationale over the alternatives considered:

- **vs. Kotlin Multiplatform (KMP):** KMP's managed-language GC pauses and Kotlin/Native's C-interop friction on iOS jeopardize the 16.6ms frame budget for a CPU-bound Flow Field + ECS simulation with hundreds of concurrent entities.
- **vs. Rust + UniFFI:** technically attractive (compile-time memory/thread safety, mature ECS/serialization crates), but this org standardizes native performance-critical modules on C++ (see Image-Toolkit's `base/` for precedent) — one systems language across projects means shared tooling, shared CI runners, and one set of engineers who can review the core, at the cost of losing the borrow checker's compile-time guarantees (see "Trade-offs" below).
- **vs. staying documentation-only:** acceptable for a single-player demo, but Co-Op multiplayer requires deterministic, identical simulation logic on both platforms — hand-synced Kotlin/Swift implementations will drift under active development.

## Trade-offs vs. a Rust core

C++ has no compiler-enforced borrow checker or `Send`/`Sync` marker traits, so the safety properties Rust would have given for free here (no data races, no use-after-free across the FFI boundary) become a discipline problem instead of a compiler-enforced one. Mitigations, all mandatory before `S5` lands:

- RAII everywhere; no raw owning pointers in simulation code — `std::unique_ptr`/`std::shared_ptr` or EnTT's own registry-owned storage only.
- AddressSanitizer + UndefinedBehaviorSanitizer in CI for every core build (ThreadSanitizer too, once `S6`'s concurrency lands) — non-negotiable given Rust's compile-time checks aren't available.
- `clang-tidy` (bugprone-*, cppcoreguidelines-*) as a required CI gate on `core/`, playing the role static analysis has to play harder in C++ than it does in Rust.

## Architecture

| Layer | Technology | Purpose |
| --- | --- | --- |
| Simulation | C++20, ECS via [EnTT](https://github.com/skypjack/entt) | Cache-local, archetype/sparse-set storage for pathfinding, combat, and economy systems |
| FFI bridge | Hand-written C ABI shim over the C++ core, bound via JNI (Android) and Swift's C++ interop / an Objective-C++ shim (iOS) | No automated multi-language binding generator in the C++ ecosystem matches UniFFI's maturity — the C ABI surface is kept intentionally small and hand-reviewed instead |
| Serialization | [FlatBuffers](https://flatbuffers.dev/) | Zero-copy state snapshots across the FFI boundary and over the network — also used natively by both Kotlin and Swift if either side ever needs to parse a buffer without crossing the FFI boundary |
| Concurrency | `std::shared_mutex`/`std::atomic`, or a lock-free SPSC/MPSC queue between the simulation and bridge threads | Enforces a "concurrent read, exclusive write" model by convention (see "Trade-offs" above for why this needs sanitizers/review rather than compiler enforcement) |
| Dependency management | CMake + [vcpkg](https://vcpkg.io/) (manifest mode: `vcpkg.json` + `vcpkg-configuration.json`) | Pulls in EnTT, FlatBuffers, and the test/benchmark toolchain reproducibly — see [`docs/DEPENDENCY_POLICY.md`](../../DEPENDENCY_POLICY.md) |

## Roadmap

| # | Item | Effort | Status |
| --- | --- | --- | --- |
| S1 | Stand up the C++ workspace (`core/` compiled library, CMake + vcpkg manifest) with EnTT and a minimal ECS skeleton (position/velocity/health components) | L | 📋 Pending |
| S2 | Port Flow Field pathfinding into the C++ core | L | 📋 Pending |
| S3 | JNI bindings (Android Gradle build, via CMake's `externalNativeBuild`) and Swift C++ interop / Objective-C++ shim (Xcode build) wired up and producing a callable stub | M | 📋 Pending |
| S4 | FlatBuffers-based state snapshot passed across the C ABI boundary as an opaque buffer; native clients render UI-state differentials only | M | 📋 Pending |
| S5 | Replace Android's `engine/` and iOS's `Engine/`/`Core/GameManager.swift` game-logic bodies with calls into the shared core, keeping native code as the presentation/input layer only — gated on the sanitizer/clang-tidy CI setup in "Trade-offs" above | XL | 📋 Pending |
| S6 | Async bridging: expose C++ async results (a small callback/promise abstraction, or `std::future` where it fits) to Kotlin coroutines / Swift `async`/`await`, with explicit lifetime/ownership rules at the boundary and ThreadSanitizer coverage — this is exactly the class of bug Rust's `Send`/`Sync` would have caught at compile time, so treat it as higher-risk than a typical async-bridging task | M | 📋 Pending |
| S7 | Cross-platform determinism test suite (see [`qa_testing.md`](qa_testing.md)) — fixed-point arithmetic and synchronized PRNGs where floating-point divergence would break lockstep-style sync | L | 📋 Pending |

Effort key: S = days, M = 1–2 weeks, L = 3–6 weeks, XL = multi-month/cross-cutting.
