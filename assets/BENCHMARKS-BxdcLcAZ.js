const e=`# Performance Benchmarks

*Last updated: 2026-08-06.*

> **TODO:** No automated benchmark suite exists yet — this document records the **target budgets and planned instrumentation**, not measured results. Neither native client ships the real Mobile Fortress core loop today (see [\`.agent/AGENTS.md\`](https://github.com/ACFHarbinger/Project-Mobile-Fortress/blob/main/.agent/AGENTS.md) §7 "Known Constraints"); benchmarking the inherited template skeletons (a bouncing-entity demo on Android, a top-down shooter skeleton on iOS) wouldn't be representative of anything. This doc will gain real numbers as [\`docs/moon/roadmaps/performance.md\`](moon/roadmaps/performance.md)'s items land — track it there, not here, for status.

---

## Table of Contents

- [Target Budgets](#target-budgets)
- [Planned Benchmark Suite](#planned-benchmark-suite)
- [Why These Targets](#why-these-targets)
- [Profiling Tools (Available Today)](#profiling-tools-available-today)
- [Reporting a Regression](#reporting-a-regression)

---

## Target Budgets

| Metric | Target | Rationale |
| --- | --- | --- |
| Frame time (Android, mid-range device) | ≤ 16.6ms (60fps) sustained during a full siege wave (hundreds of concurrent units) | [\`docs/moon/roadmaps/performance.md\`](moon/roadmaps/performance.md) P3/P4; Market Research's hardware-democratization findings (sub-$100 devices, P8) |
| Frame time (iOS) | ≤ 16.6ms (60fps), matching SpriteKit's display-link cadence | Parity with Android target |
| Flow Field recompute | Amortized across frames for large grids; no single-frame spike from a tower placement | [\`docs/moon/roadmaps/performance.md\`](moon/roadmaps/performance.md) P3 |
| Per-frame heap allocation (update/render hot path) | Zero | [\`.agent/rules/game_loop_performance.md\`](https://github.com/ACFHarbinger/Project-Mobile-Fortress/blob/main/.agent/rules/game_loop_performance.md) — allocation churn is the most common cause of GC/ARC-driven frame drops |
| Cold start (Android, Baseline Profiles) | Meaningfully faster than JIT-only cold start | [\`docs/moon/roadmaps/performance.md\`](moon/roadmaps/performance.md) P6 |
| JNI/Swift-C++-interop FFI round-trip (once the C++ core lands) | Zero-copy via FlatBuffers; no per-frame (de)serialization allocation | [\`docs/moon/roadmaps/performance.md\`](moon/roadmaps/performance.md) P5; [\`docs/moon/roadmaps/shared_core.md\`](moon/roadmaps/shared_core.md) |
| Co-Op netcode state sync | Within GameLift FlexMatch's latency-graduated matchmaking thresholds (see [\`research/Multiplayer Tower Defense Implementation.md\`](research/Multiplayer%20Tower%20Defense%20Implementation.md) §"Matchmaking and Fleet Orchestration") | [\`docs/moon/roadmaps/backend.md\`](moon/roadmaps/backend.md) |

---

## Planned Benchmark Suite

| Suite | Runner (planned) | Measures | Tracked by |
| --- | --- | --- | --- |
| Android Macrobenchmark | \`androidx.benchmark.macro\` module | Frame timing, cold/warm start | [\`docs/moon/roadmaps/performance.md\`](moon/roadmaps/performance.md) P7 |
| iOS Instruments trace | \`xcodebuild test\` + Time Profiler / Core Animation instrument | Frame timing, allocation hotspots | [\`docs/moon/roadmaps/performance.md\`](moon/roadmaps/performance.md) (iOS parity, no P-number yet) |
| C++ core micro-benchmarks | [Google Benchmark](https://github.com/google/benchmark) (planned, once the library exists) | ECS iteration throughput, Flow Field recompute cost, FlatBuffers (de)serialization cost | [\`docs/moon/roadmaps/shared_core.md\`](moon/roadmaps/shared_core.md), [\`docs/moon/roadmaps/performance.md\`](moon/roadmaps/performance.md) P2/P5 |
| ARM thermal/battery profiling | Manual pass on representative sub-$100 Android hardware | Sustained-load thermal throttling behavior | [\`docs/moon/roadmaps/performance.md\`](moon/roadmaps/performance.md) P8 |
| \`docs/website/vue\` bundle size | \`vite build\` output report | Initial JS payload (Mermaid/KaTeX must stay lazy-loaded, see [\`docs/DEPENDENCY_POLICY.md\`](DEPENDENCY_POLICY.md)) | Not yet gated in CI |

None of these runners exist in the repository yet — this table is the plan the roadmap items above will implement against, so that when the first suite lands it has an agreed target to report against rather than an arbitrary one invented after the fact.

---

## Why These Targets

- **60fps, not 30fps:** the core loop supports "hundreds of low-tier enemy combatants" on screen simultaneously during a siege wave (per [\`docs/design/game_design_document.md\`](design/game_design_document.md) §3) — at 30fps, the Flow-Field-routed swarm reads as choppy rather than as the "overwhelming visual spectacle" the design targets.
- **Zero per-frame allocation:** both platforms' GC/ARC pause behavior is nondeterministic under allocation pressure — a budget of "mostly zero, occasionally spikes" is indistinguishable from "occasionally drops frames," so the target is a hard zero in the hot path, not a soft average.
- **Sub-$100 device coverage:** directly sourced from the market-gap rationale in [\`reports/Tower Defense Market Research.md\`](reports/Tower%20Defense%20Market%20Research.md) — a tower-defense/4X hybrid that only runs acceptably on flagship hardware misses a meaningful slice of the addressable market this project targets.

---

## Profiling Tools (Available Today)

Even without a committed benchmark suite, these are available right now against the current template-skeleton clients:

\`\`\`bash
# Android — CPU Profiler / Perfetto via Android Studio, or from the command line:
adb shell am start -n com.acfharbinger.mobilefortress/.MainActivity
# then attach Android Studio's profiler, or capture a Perfetto trace directly.

# iOS — Instruments (requires a macOS host, see docs/TROUBLESHOOTING.md):
xcrun xctrace record --template 'Time Profiler' --launch ios/MyGame.xcodeproj
\`\`\`

See [\`.agent/rules/game_loop_performance.md\`](https://github.com/ACFHarbinger/Project-Mobile-Fortress/blob/main/.agent/rules/game_loop_performance.md)'s closing note on both platforms: profile before "optimizing" — most naive frame-drop reports trace back to allocation or an accidental main-thread blocking call, not raw compute cost.

---

## Reporting a Regression

Once a benchmark suite exists and starts running in CI, a regression should be reported as a GitHub issue with: the metric that regressed, the before/after numbers, the commit range, and the device/simulator profile used. Until then, report suspected performance problems the same way as any other bug — see [\`docs/TROUBLESHOOTING.md\`](TROUBLESHOOTING.md#getting-further-help).
`;export{e as default};
