# QA & Testing Roadmap

Scope: correctness of the shared simulation core, netcode determinism, and the retention benchmarks Mobile Fortress is designed against. See [`reports/Tower Defense Market Research.md`](../reports/Tower%20Defense%20Market%20Research.md) §"Key Performance Indicators (KPIs) and Retention Benchmarks" for the target metrics below.

| # | Item | Effort | Status |
| --- | --- | --- | --- |
| Q1 | ~~Unit test skeleton (`GameEngineTest`)~~ / ~~Instrumented test skeleton (`MainActivityTest`)~~ — template baseline | S | ✅ Done |
| Q2 | CI instrumented-test matrix across API levels (29, 35) | S | ✅ Done |
| Q3 | C++ core unit + property tests for Flow Field correctness (no unreachable tiles, no path oscillation) and ECS system ordering | L | 📋 Pending |
| Q4 | Determinism test harness: identical inputs + identical seed must yield bit-identical simulation state across ARM/x86 | L | 📋 Pending |
| Q5 | Netcode integration tests under simulated latency/jitter/packet loss for server-authoritative sync + client reconciliation | L | 📋 Pending |
| Q6 | Device farm (Firebase Test Lab) integration for broader Android device/thermal coverage | M | 📋 Pending |
| Q7 | Crash reporting (Firebase Crashlytics or similar) wired into release builds, both platforms | S | 📋 Pending |
| Q8 | Retention analytics instrumentation (D1/D7/D30) with internal targets benchmarked against the midcore-strategy averages: D1 ≈ 42%, D7 ≈ 21%, D30 ≈ 11.5% | M | 📋 Pending |
| Q9 | Gacha-rate audit tooling: automated verification that displayed probabilities match server-side roll weights (regulatory compliance, see [`monetization.md`](monetization.md)) | M | 📋 Pending |
| Q10 | Playtesting pass for Day/Night pacing, land+naval dual-front cognitive load, and calibration (avoid the "deep strategy" fatigue noted in Market Research §"Decline of Deep Strategy") | M | 📋 Pending |

Effort key: S = days, M = 1–2 weeks, L = 3–6 weeks, XL = multi-month/cross-cutting.
