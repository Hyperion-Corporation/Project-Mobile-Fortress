# QA & Testing Roadmap

**Owner:** TBD

Scope: correctness of dual-front gameplay, C++/Godot integration, later netcode, and retention instrumentation.

| # | Item | Effort | Status |
| --- | --- | --- | --- |
| Q1 | Template unit/instrumented skeletons (historical) | S | ✅ Done |
| Q2 | CI matrices (update for Godot export + Android 13+ / iOS 17+) | M | 🚧 **Partial** — `godot-game.yml` runs every `game/tests/*_smoke.gd` headless via `scripts/run_godot_smokes.sh` (plus the existing CMake/`ctest` job; smoke log artifact on failure; runner regression tests cover failure detection); legacy `ci.yml` Android/iOS jobs are now path-gated to their own trees with wrapper-jar validation fixed (AGP 9.3.1 vs Gradle 8.7 and an Xcode 26.6 parse failure recorded as findings, see `docs/TESTING.md`), and a shellcheck job lints `scripts/*.sh`; T53 fixes downstream gate dependencies and runs both trees when the diff base is unavailable; Godot export + Android/iOS version matrices unchanged |
| Q3 | C++ core unit + property tests (pathing, ECS ordering) | L | 🚧 **Partial** — doctest `sim_world_tests` (reset/spend/raiders/save-load/wave-on-flow) |
| Q4 | Regression harness: fixed seed → consistent outcomes (soft determinism; not lockstep-hard) | L | 🚧 **Partial** — S7 fixed-dt replay in `sim_world_tests` |
| Q5 | Netcode tests under latency/jitter (post online) | L | 📋 Deferred |
| Q6 | Device farm coverage for Godot Android/iOS exports | M | 📋 Deferred |
| Q7 | Crash reporting on release builds | S | 📋 Pending |
| Q8 | Retention analytics instrumentation with opt-out = no collection | M | 📋 Deferred until consent design |
| Q9 | ~~Gacha-rate audit for power gacha~~ → **lootbox probability audit** for cosmetic skin boxes only | M | 📋 Deferred with M1b/M2 |
| Q10 | Playtesting dual-front pacing / cognitive load (Slice-0 exit) | M | 📋 Pending · Slice-0 gate |

Effort key: S = days, M = 1–2 weeks, L = 3–6 weeks, XL = multi-month/cross-cutting.
