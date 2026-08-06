# Performance Roadmap

Scope: keeping hundreds of concurrent siege units, Flow Field recomputation, and Co-Op netcode inside a mobile frame/thermal budget. See [`research/Multiplayer Tower Defense Implementation.md`](../../research/Multiplayer%20Tower%20Defense%20Implementation.md) §"Technical Underpinnings" and §"High-Performance State Management and ECS Paradigms".

| # | Item | Effort | Status |
| --- | --- | --- | --- |
| P1 | ~~Fixed-timestep `GameLoop` with capped catch-up iterations~~ — template baseline, carried forward into the Rust core's tick loop | S | ✅ Done |
| P2 | Migrate simulation state to an ECS (`hecs`) inside the shared Rust core for cache-local, archetype-based iteration over hundreds of siege entities | L | 📋 Pending |
| P3 | Flow Field recomputation budget: single grid-wide Dijkstra pass per tower placement, amortized across frames if the grid is large | M | 📋 Pending |
| P4 | Entity/component pooling to avoid per-frame allocation in the update/render hot path (both native clients and the Rust core) | M | 📋 Pending |
| P5 | Zero-copy state snapshots (`rkyv`) across the UniFFI boundary to avoid per-frame (de)serialization cost | M | 📋 Pending |
| P6 | Baseline Profiles (`androidx.profileinstaller`) for faster cold start | M | 📋 Pending |
| P7 | Macrobenchmark module for frame-timing regression detection, including under active Co-Op netcode traffic | L | 📋 Pending |
| P8 | ARM thermal/battery profiling pass targeting sub-$100 Android devices (per Market Research's hardware-democratization findings) | M | 📋 Pending |
