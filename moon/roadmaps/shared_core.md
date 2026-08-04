# Shared Core Roadmap — Rust + UniFFI (decided)

Today `core/` is assets + documentation only — see [`core/README.md`](../../core/README.md). **This decision is now made**: Mobile Fortress requires a real compiled shared simulation core, not documentation-only convention, because Co-Op multiplayer needs bit-identical simulation state across both native clients. See [`research/Multiplayer Tower Defense Implementation.md`](../../research/Multiplayer%20Tower%20Defense%20Implementation.md) §"Architecting the Shared Computational Core" for the full evaluation.

## Decision: Option B — Rust core via UniFFI

The shared core is implemented in Rust and bridged to Kotlin (Android) and Swift (iOS) via [UniFFI](https://mozilla.github.io/uniffi-rs/), Mozilla's automated multi-language bindings generator. Rationale over the alternatives considered:

- **vs. Kotlin Multiplatform (KMP):** KMP's managed-language GC pauses and Kotlin/Native's C-interop friction on iOS jeopardize the 16.6ms frame budget for a CPU-bound Flow Field + ECS simulation with hundreds of concurrent entities.
- **vs. staying documentation-only:** acceptable for a single-player demo, but Co-Op multiplayer requires deterministic, identical simulation logic on both platforms — hand-synced Kotlin/Swift implementations will drift under active development.

## Architecture

| Layer | Technology | Purpose |
| --- | --- | --- |
| Simulation | Rust, ECS via [`hecs`](https://lib.rs/crates/hecs) | Cache-local archetype storage for pathfinding, combat, and economy systems |
| FFI bridge | [UniFFI](https://mozilla.github.io/uniffi-rs/) | Auto-generated C-ABI scaffolding + idiomatic Kotlin/Swift wrappers, avoiding handwritten-FFI memory bugs |
| Serialization | [`rkyv`](https://github.com/rkyv/rkyv) | Zero-copy state snapshots across the FFI boundary and over the network |
| Concurrency | `Arc`/`Mutex`/`RwLock`, or lock-free MPSC channels between simulation and FFI threads | Enforces Rust's "concurrent read, exclusive write" model |

## Roadmap

| # | Item | Effort | Status |
| --- | --- | --- | --- |
| S1 | Stand up the Rust workspace (`core/` compiled crate) with `hecs` and a minimal ECS skeleton (position/velocity/health components) | L | 📋 Pending |
| S2 | Port Flow Field pathfinding into the Rust core | L | 📋 Pending |
| S3 | UniFFI bindings generation wired into the Android Gradle build and Xcode build | M | 📋 Pending |
| S4 | `rkyv`-based state snapshot passed across the UniFFI boundary as an opaque `RustBuffer`; native clients render UI-state differentials only | M | 📋 Pending |
| S5 | Replace Android's `engine/` and iOS's `Engine/`/`Core/GameManager.swift` game-logic bodies with calls into the shared core, keeping native code as the presentation/input layer only | XL | 📋 Pending |
| S6 | Async bridging: expose Rust `Future`s to Kotlin coroutines / Swift `async`/`await`, auditing for the known `callbackFlow`-cancellation leak pattern | M | 📋 Pending |
| S7 | Cross-platform determinism test suite (see [`qa_testing.md`](qa_testing.md#Q4)) — fixed-point arithmetic and synchronized PRNGs where floating-point divergence would break lockstep-style sync | L | 📋 Pending |

Effort key: S = days, M = 1–2 weeks, L = 3–6 weeks, XL = multi-month/cross-cutting.
