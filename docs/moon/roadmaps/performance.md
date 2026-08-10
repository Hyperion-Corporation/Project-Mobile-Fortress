# Performance Roadmap

**Owner:** TBD

Scope: dual-front siege units, pathfinding, and (later) netcode inside a mobile thermal/battery budget.

**2026-08-11 targets:** **30+ FPS**, **~40** simultaneous units (minimum meaningful fight **≥10**), Android 13+ / iOS 17+. Swarm experiments may cap presentation/sim presentation rate around 30 FPS rather than offloading to a server for offline play.

| # | Item | Effort | Status |
| --- | --- | --- | --- |
| P1 | Fixed-timestep sim loop (Godot + C++ tick ownership defined in S0) | S | 🚧 Adapt from template |
| P2 | ECS (EnTT) in C++ core for siege entities | L | 📋 Pending |
| P3 | Flow Field / pathing recompute budget | M | 📋 Pending |
| P4 | Entity/component pooling; no hot-path allocations | M | 📋 Pending |
| P5 | FlatBuffers zero-copy snapshots (save/net) | M | 📋 Pending |
| P6 | Godot mobile export profiling (draw calls, lights, particles) | M | 📋 Pending |
| P7 | Frame-timing regression checks on target devices | L | 📋 Pending |
| P8 | Thermal/battery pass at 40-unit dual-front load | M | 📋 Pending |
| P9 | Swarm/Boids cost envelopes vs FPS floor | M | 📋 With A11 |

Effort key: S = days, M = 1–2 weeks, L = 3–6 weeks, XL = multi-month/cross-cutting.
