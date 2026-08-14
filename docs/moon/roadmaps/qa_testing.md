# QA & Testing Roadmap

**Owner:** TBD

Scope: correctness of dual-front gameplay, C++/Godot integration, later netcode, and retention instrumentation.

| # | Item | Effort | Status |
| --- | --- | --- | --- |
| Q1 | Template unit/instrumented skeletons (historical) | S | ✅ Done |
| Q2 | CI matrices (update for Godot export + Android 13+ / iOS 17+) | M | 🚧 **Partial** — `.github/workflows/godot-core.yml` CMake/`ctest` + headless `simulation_smoke.gd`; Android jobs unchanged |
| Q3 | C++ core unit + property tests (pathing, ECS ordering) | L | 🚧 **Partial** — doctest `sim_world_tests` (reset/spend/raiders/save-load/wave-on-flow) |
| Q4 | Regression harness: fixed seed → consistent outcomes (soft determinism; not lockstep-hard) | L | 🚧 **Partial** — S7 fixed-dt replay in `sim_world_tests` |
| Q5 | Netcode tests under latency/jitter (post online) | L | 📋 Deferred |
| Q6 | Device farm coverage for Godot Android/iOS exports | M | 📋 Deferred |
| Q7 | Crash reporting on release builds | S | 📋 Pending |
| Q8 | Retention analytics instrumentation with opt-out = no collection | M | 📋 Deferred until consent design |
| Q9 | ~~Gacha-rate audit for power gacha~~ → **lootbox probability audit** for cosmetic skin boxes only | M | 📋 Deferred with M1b/M2 |
| Q10 | Playtesting dual-front pacing / cognitive load (Slice-0 exit) | M | 📋 Pending · Slice-0 gate |

Effort key: S = days, M = 1–2 weeks, L = 3–6 weeks, XL = multi-month/cross-cutting.
