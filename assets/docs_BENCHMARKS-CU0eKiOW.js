const e=`# Performance Benchmarks

*Last updated: 2026-10-08.*

> The Godot/C++ desktop measurement is in [Simulation Tick Budget](#simulation-tick-budget-p7-desktop-baseline). Target-device measurements remain open under P7. The earlier budgets, planned suites and native-client profiling instructions below are legacy planning context; the current VS-A8 acceptance floor is 30+ FPS with 10–40 units.

---

## Table of Contents

- [Target Budgets](#target-budgets)
- [Planned Benchmark Suite](#planned-benchmark-suite)
- [Why These Targets](#why-these-targets)
- [Profiling Tools (Available Today)](#profiling-tools-available-today)
- [Simulation Tick Budget](#simulation-tick-budget-p7-desktop-baseline)
- [Flow-Field Recompute](#flow-field-recompute-p3-desktop-baseline)
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
| Co-Op netcode state sync | Within GameLift FlexMatch's latency-graduated matchmaking thresholds (see [\`moon/research/Multiplayer Tower Defense Implementation.md\`](moon/research/Multiplayer%20Tower%20Defense%20Implementation.md) §"Matchmaking and Fleet Orchestration") | [\`docs/moon/roadmaps/backend.md\`](moon/roadmaps/backend.md) |

---

## Planned Benchmark Suite

| Suite | Runner (planned) | Measures | Tracked by |
| --- | --- | --- | --- |
| Android Macrobenchmark | \`androidx.benchmark.macro\` module | Frame timing, cold/warm start | [\`docs/moon/roadmaps/performance.md\`](moon/roadmaps/performance.md) P7 |
| iOS Instruments trace | \`xcodebuild test\` + Time Profiler / Core Animation instrument | Frame timing, allocation hotspots | [\`docs/moon/roadmaps/performance.md\`](moon/roadmaps/performance.md) (iOS parity, no P-number yet) |
| C++ core micro-benchmarks | [Google Benchmark](https://github.com/google/benchmark) (planned, once the library exists) | ECS iteration throughput, Flow Field recompute cost, FlatBuffers (de)serialization cost | [\`docs/moon/roadmaps/shared_core.md\`](moon/roadmaps/shared_core.md), [\`docs/moon/roadmaps/performance.md\`](moon/roadmaps/performance.md) P2/P5 |
| ARM thermal/battery profiling | Manual pass on representative sub-$100 Android hardware | Sustained-load thermal throttling behavior | [\`docs/moon/roadmaps/performance.md\`](moon/roadmaps/performance.md) P8 |
| \`docs/website\` bundle size | \`vite build\` output report | Initial JS payload (Mermaid/KaTeX must stay lazy-loaded, see [\`docs/DEPENDENCY_POLICY.md\`](DEPENDENCY_POLICY.md)) | Not yet gated in CI |

None of these runners exist in the repository yet — this table is the plan the roadmap items above will implement against, so that when the first suite lands it has an agreed target to report against rather than an arbitrary one invented after the fact.

---

## Why These Targets

- **60fps, not 30fps:** the core loop supports "hundreds of low-tier enemy combatants" on screen simultaneously during a siege wave (per [\`docs/design/game_design_document.md\`](design/game_design_document.md) §3) — at 30fps, the Flow-Field-routed swarm reads as choppy rather than as the "overwhelming visual spectacle" the design targets.
- **Zero per-frame allocation:** both platforms' GC/ARC pause behavior is nondeterministic under allocation pressure — a budget of "mostly zero, occasionally spikes" is indistinguishable from "occasionally drops frames," so the target is a hard zero in the hot path, not a soft average.
- **Sub-$100 device coverage:** directly sourced from the market-gap rationale in [\`moon/reports/Tower Defense Market Research.md\`](moon/reports/Tower%20Defense%20Market%20Research.md) — a tower-defense/4X hybrid that only runs acceptably on flagship hardware misses a meaningful slice of the addressable market this project targets.

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

## Simulation Tick Budget (P7 Desktop Baseline)

First measured sim numbers for the project (T44). The benchmark times only
the native \`SimulationCore.tick()\` call — no rendering, HUD sync, or audio —
at the VS-A8 design ceiling (~40 units across both fronts, sustained raid).

### How to run it

\`\`\`bash
# Manual gate only — never wire into CI (timing is machine-dependent,
# and *_smoke.gd wiring would pick up only CI-safe smokes anyway).
scripts/run_perf_bench.sh
# or directly:
godot --path game --headless --script res://tests/perf_budget_bench.gd
\`\`\`

On a shared machine, prefix a private \`XDG_DATA_HOME=\` so parallel Godot
runs do not share \`user://\`. The script loads the real
\`slice0_dual_front.json\` level through the public \`SimulationCore\` API
(\`load_level_json\`, \`spawn_raider\`, \`spawn_defender\`), builds a 10 / 20 /
40 / 60-entity dual-front load (half raiders, half combat-engaged
defenders, split across land + sea fronts), warms up 200 ticks, then times
2000 fixed-dt (1/30 s) ticks per level with \`Time.get_ticks_usec()\` into a
pre-sized buffer (no benchmark-side allocation inside the timed loop) and reports
min / median / p95 / p99 / max plus the entity counts actually reached.
Untimed snapshots verify damage and movement on each front across the
measured window and a subsequent 60-tick probe. Synthetic 500-pixel defender
range keeps targets in reach throughout; high raider HP prevents deaths.
The public tick includes native event-array creation and bridge overhead.
If the native GDExtension did not load, the script prints FAIL and exits 1
rather than benchmarking a fallback backend.

### Budget derivation

VS-A8 requires 30+ FPS with 10–40 units. One 30 FPS frame is 33_333 us;
the sim tick is only part of a frame (rendering, HUD sync, audio, OS
margin), so the benchmark assigns the sim at most ~1/4 of the frame:
**\`SIM_BUDGET_US = 8000\`**. The p95 tick at the 40-unit ceiling is
compared against it: PASS (exit 0) at or under budget, WARN (exit 0) up to
3x budget, FAIL (exit 1) beyond — exit code fails only on gross regression
so the script is usable as a manual gate without being flaky.

### Measured numbers (2026-10-08)

Machine: 12th Gen Intel i9-12900HX (24 threads), desktop x86-64 Linux,
Godot 4.7.1 headless, lead-prepared native library (Release build type;
this task did not rebuild C++). Three consecutive reviewer runs after the
sustained-combat fix, 2000 timed ticks per load level per run:

| Load (entities) | Median (us) | p95 (us) | p99 (us) | Max spread across 3 runs (us) |
| --- | --- | --- | --- | --- |
| 10 (5 raiders + 5 defenders) | 0 | 1 | 1 | 4–6 |
| 20 (10 + 10) | 0 | 1 | 1 | 1–3 |
| 40 (20 + 20, design ceiling) | 0 | 1 | 1 | 2–4 |
| 60 (30 + 30, over-budget stress) | 0 | 1 | 2–3 | 3–4 |

Verdict: **PASS** in all three runs — p95@40 = 1 us against the 8000 us
budget, i.e. roughly three orders of magnitude of headroom on this
machine. Microsecond timer resolution is too coarse to establish a scaling curve
from these medians/p95 values; the outliers were not profiled. Start/end entity counts
matched the target load exactly in every run (no mid-run deaths).

### Explicit caveats (why P7 stays Partial, not Done)

- **Desktop only, NOT a target phone.** These numbers say nothing about
  Android 13+ / iOS 17+ devices, thermal throttling, or battery (P8).
  The "on target devices" part of P7 remains open: re-run this script on
  representative hardware before the collaborator playtest.
- **Sim tick only.** Rendering, TileMap/HUD sync, GDScript presentation
  (\`battle_root.gd\`), and audio are not measured.
- **Synthetic lane-path movement + defender targeting only.** The tick load
  uses explicit lane paths; the C++-owned wave-spawn path is not exercised
  here. Combat-phase wave scheduling is deliberately not started; defender
  attacks and movement run independently of that flag. Flow-field recompute
  is covered separately below (P3 baseline).
- Medians of 0 us mean elapsed times fall below the timer resolution;
  they do not mean zero simulation work. Damage/movement assertions detect
  a no-op tick independently of the timer.

---

## Flow-Field Recompute (P3 Desktop Baseline)

First measured recompute numbers for the project (T52). \`SimWorld::set_cell_solid\`
runs the whole-front BFS recompute synchronously, so timing that call *is*
timing the P3 cost — the same call \`BattleRoot\` makes on every defender
placement, redeploy, outpost loss, and DT6 level load.

### How to run it

Same script as the tick baseline (never CI — timing is machine-dependent):

\`\`\`bash
scripts/run_perf_bench.sh
\`\`\`

After the per-load tick lines, the script builds a live combat world on 8×5
grids (outpost solids as in \`BattleRoot._setup_grids\`, scheduled waves
disabled so only the scenario's own raiders exist), spawns 20 flow-mode
raiders (10 per front, \`uses_flow\` asserted — a lane-path world would not
measure recompute), then times 2000 defender-style solid place/remove
toggles (full place pass + full remove pass, cycling cells, fronts
alternating — each timed sample is exactly one \`set_cell_solid\` call, i.e.
one single-front recompute)
with untimed ticks between batches so the raid stays live. Raiders that reach
the last column damage the HQ and despawn — that is the flow path working end
to end — so the scenario tops the load back up untimed and proves liveness by
falling HQ HP rather than by stable counts. Reports min / median / p95 / p99 /
max microseconds per recompute plus its own budget line:
**\`FLOW_BUDGET_US = 8000\`** (same frame-fraction rationale as the tick —
recompute shares the frame with the tick, rendering, and HUD sync). PASS /
WARN / FAIL thresholds match the tick scenario; either scenario failing the
gross check fails the run.

### Measured numbers (2026-10-08)

Machine: 12th Gen Intel i9-12900HX (24 threads), desktop x86-64 Linux,
Godot 4.7.1 headless, current-\`harbinger\` native library. Three consecutive
runs, 2000 timed recomputes per run (20 flow raiders live):

| Run | Median (us) | p95 (us) | p99 (us) | Max (us) |
| --- | --- | --- | --- | --- |
| 1 | 0 | 1 | 1 | 4 |
| 2 | 0 | 1 | 1 | 1 |
| 3 | 0 | 1 | 1 | 1 |

Verdict: **PASS** in all three runs — p95 = 1 us against the 8000 us budget.
Expected: an 8×5 (40-cell) single-front BFS is tens of cell visits; single-digit
microseconds are the honest order of magnitude on desktop. The outliers were
not profiled; timer resolution is 1 us.

### Explicit caveats (why P3 stays Partial, not Done)

- **Desktop only, NOT a target phone** — same caveat as the tick baseline.
- **Small live grids.** 8×5 with ~20 raiders is the Slice-0 shape; larger
  grids, heavier solid churn (many simultaneous placements), and combined
  tick+recompute frame cost on device are still open.
- **C++-owned wave spawn still unmeasured**; rendering/HUD sync excluded.

---

## Reporting a Regression

Once a benchmark suite exists and starts running in CI, a regression should be reported as a GitHub issue with: the metric that regressed, the before/after numbers, the commit range, and the device/simulator profile used. Until then, report suspected performance problems the same way as any other bug — see [\`docs/TROUBLESHOOTING.md\`](TROUBLESHOOTING.md#getting-further-help).
`;export{e as default};
