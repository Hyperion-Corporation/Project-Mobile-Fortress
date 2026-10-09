# Testing Guide

| Layer | Location | Framework | Command |
| --- | --- | --- | --- |
| Android unit tests (JVM) | `android/app/src/test/` | JUnit 4 + `kotlin.test` | `./gradlew testDebugUnitTest` (`just unit-test`) |
| Android instrumented tests (on-device) | `android/app/src/androidTest/` | JUnit 4 + Espresso + Compose UI test | `./gradlew connectedDebugAndroidTest` (`just test-instrumented`) |
| iOS unit tests | `ios/Tests/` | XCTest | `xcodebuild ... test` (`just ios-test`) |
| Godot headless smokes | `game/tests/*_smoke.gd` | Godot 4.7 `--headless` `SceneTree` scripts | `just test::godot-smokes` (`scripts/run_godot_smokes.sh`) |
| Native C++ sim tests | `game/tests/native/` | doctest (CMake/`ctest`) | `ctest --test-dir game/build` |
| Perf budget bench | `game/tests/perf_budget_bench.gd` | manual headless benchmark | `scripts/run_perf_bench.sh` |

## Godot headless smokes (game/)

Every `game/tests/*_smoke.gd` is a headless `SceneTree` smoke invoked as `godot --path game --headless --script res://tests/<name>.gd`. `scripts/run_godot_smokes.sh` (wrapped by `just test::godot-smokes`) discovers them automatically — adding a new `*_smoke.gd` needs no runner or CI edits. It performs a one-off `--import` pass, runs each smoke with a per-smoke timeout (`SMOKE_TIMEOUT`, default 120s), and fails a smoke on a non-zero exit **or** on known Godot failure text in its output (`SCRIPT ERROR`, `Parse Error`, a printed `FAIL`) even when the exit code is 0. It prints a per-smoke PASS/FAIL table, writes a combined log (`SMOKE_LOG`), and exits non-zero if any smoke failed. A fresh import that aborts with exit 134 is retried once; other non-zero exits, a failed retry, or failure text from either attempt fail the gate; smokes still run to collect diagnostics. Timeouts force termination after a further five seconds if the process ignores SIGTERM. Run a subset with `just test::godot-smokes simulation gameplay`; override the binary with `GODOT=/path/to/godot`.

Smokes that genuinely cannot run headless belong in the commented `SKIP_LIST` at the top of the script, each with a stated reason (currently empty — all smokes run). The native extension must be built first (`game/bin/libmobile_fortress_core*.so`, see `game/BUILD_CPP.md`).

**Layout smokes must not rely on a clean player profile.** Returning-player state (saved progression, run history, persisted settings such as Large Text) changes menu/HUD layout and has hidden real bugs before — a main-menu clipping bug was invisible on a clean profile (T61 finding, T77 fix). Any new layout smoke sets up its own saved progress/history inside its private `XDG_DATA_HOME` instead of assuming a fresh `user://`.

CI: `.github/workflows/godot-game.yml` runs the script on every PR/push touching `game/**` (plus the unchanged CMake/`ctest` job) and uploads `godot-smokes.log` as an artifact when the smoke job fails.

Runner regression tests use a temporary fixture and fake Godot binary: `python3 -m unittest discover -s scripts/tests -p test_run_godot_smokes.py -v` (also run in CI).

### Per-smoke coverage (29 smokes on disk, 2026-10-09 — read from the smoke files)

The runner discovers smokes automatically, so this table describes coverage, not a
list to keep in sync — new smokes are added to CI with no edits anywhere.

| Smoke | Covers |
| --- | --- |
| `accessibility_smoke` | U8: ≥48dp touch targets, closed-loop keyboard/gamepad focus, WCAG AA contrast from ThemeTokens pairs, large-text round-trip, screen-reader metadata |
| `battle_hud_layout_smoke` | T59: rendered-window target sizing for every interactive HUD control at 1280×720 / 720×1280 / 390×844 / 844×390, large text on/off, non-overlap, viewport containment, fixed pre-T59 grid coverage baseline (16640 px²); results-panel rank lines |
| `battle_layout_smoke` | T70: both grids fully inside the viewport (containment), grids do not overlap each other or interactive HUD buttons, rendered cell size reported, at 1280×720 / 844×390 / 720×1280 / 390×844; off-canvas mutation check |
| `dda_smoke` | A4: `SimulationCore` DDA toggle, intensity readout, wave scaling |
| `dda_battle_smoke` | T48: DDA battle hookup, DT5 overlay intensity readout, DT7 wave-start DDA fields |
| `determinism_smoke` | T65: fixed-dt repeat and mid-wave save/load on every catalog level; full-buffer comparison plus one-tick placement perturbation |
| `debug_cheats_smoke` | DT1/DT2: debug APIs + force-lose through `GameSession.end_run` |
| `dev_access_smoke` | DT8: developer-mode unlock independent of telemetry; opens overlay stub |
| `dev_diag_smoke` | DT5/DT4: overlay stats + pause/step/speed time control |
| `flatbuffers_smoke` | S4: FlatBuffers snapshot round-trip contract |
| `gameplay_smoke` | End-to-end active Slice-0 scene: backend check, placement on both fronts, combat start, first wave, HQ bounds |
| `game_session_smoke` | VS8: run results persisted to `user://last_run_results.json` (victory/reason/civs) |
| `hero_e_smoke` | T23: E fires every *ready* hero even when another is on cooldown |
| `level_catalog_smoke` | G5: dual-front catalog (incl. night tide); battle loads `GameSession.selected_level_path` |
| `level_picker_smoke` | DT6: overlay LevelPickSelect loads a different level in place |
| `level_schema_smoke` | T52: every catalog level validated against `game/src/level-schema.json`; loader cross-checks; broken-copy negative controls |
| `main_menu_smoke` | Configured entry scene, modular/classic/quit controls, backend status text |
| `modular_battle_smoke` | battle_root + `SimulationCore` defenders, hero redeploy across fronts |
| `offline_persistence_smoke` | VS8 modular path: snapshot write/resume via OfflinePersistence + battle_root helpers |
| `placement_afford_smoke` | T61: battle uses `UnitDefs.placement_plan`; Qi-on-sea cross-wallet case, infinite-wallet priority; menu rank + campaign stars |
| `playtest_log_smoke` | DT7: Mark session event to `user://`; sync maps to PlaytestNotesView shape |
| `progression_smoke` | G8: star rating, prestige, persistence, `GameSession` wiring |
| `scenario_control_smoke` | DT3: jump-wave, spawn-at-cell, reload current level (no RNG) |
| `settings_smoke` | U3: settings dialog + telemetry consent persistence |
| `simulation_smoke` | Godot↔C++ bridge contract: registration, reset, resources, raider spawn/damage/death, HQ-hit events, hero pulse + cooldown, cross-front synergy, save/load |
| `theme_tokens_smoke` | U10: ThemeTokens design system + transition helpers |
| `touch_placement_smoke` | G10: synthesised ScreenTouch/ScreenDrag placement on both fronts |
| `unit_catalog_smoke` | G12: unit catalog validation + cross-front synergy multipliers |
| `unit_token_smoke` | U9: UnitToken procedural tactical rendering |

## Native C++ sim tests (ctest)

`game/tests/native/` holds engine-free doctest suites for `SimWorld` (fixtures +
flow-field property tests); they are registered with CMake's `enable_testing()` and
run with:

```bash
ctest --test-dir game/build        # ran 2026-10-08: 1/1 passed
```

Build the tests and the extension per
[`game/BUILD_CPP.md`](https://github.com/Hyperion-Corporation/Project-Mobile-Fortress/blob/main/game/BUILD_CPP.md)
(`cmake -S game -B game/build && cmake --build game/build`, then copy the extension
binary into `game/bin/` as that file describes). The same job runs in CI
(`godot-game.yml`).

## Manual perf bench (not a CI gate)

`scripts/run_perf_bench.sh` runs `game/tests/perf_budget_bench.gd` headless against
the native extension: 2000-tick samples at 10/20/40/60-unit loads (tick budget
p95 ≤ 8000 µs, i.e. a 30 FPS frame quarter) plus a 2000-recompute flow-field
scenario on live combat grids (flow budget p95 ≤ 8000 µs/recompute). Run it on the
branch when touching the sim or flow recompute and record percentiles in
[`BENCHMARKS.md`](BENCHMARKS.md). Ran 2026-10-08: both budgets PASS (p95 = 1 µs
per tick @40 units; p95 = 1 µs/recompute).

## What goes where

- **Android unit tests**: pure `engine/` logic — entity update math, collision detection, `GameState` serialization round-trips, the fixed-timestep accumulator's catch-up cap. No Android framework classes.
- **Android instrumented tests**: anything touching real framework behavior — `Activity`/`SurfaceView` lifecycle transitions, Compose screen rendering and interaction, permission flows.
- **iOS tests** (`ios/Tests/`): `GameManagerTests` (state-machine transitions), `HighScoreStoreTests` (persistence + ranking), `LevelLoaderTests` (JSON decoding against `game/src/level-schema.json`), `PhysicsMathTests` (pure movement math on `PlayerNode`, no live `SKScene`/physics simulation required). Kept framework-light on purpose — none of these need a running app or UI interaction, only a simulator to host the test bundle.

## CI

`.github/workflows/ci.yml` covers the legacy template trees and `scripts/*.sh`:

- A `changes` job diffs the push/PR range and gates the legacy jobs per tree: the three Android jobs run only when `android/**`, `gradle/**`, the root Gradle build files, `justfile`, or the workflow itself change; `ios-test` (`macos-latest`, full XCTest suite via `xcodebuild`) runs only when `ios/**` or the workflow changes. The live product under `game/**` is covered by `.github/workflows/godot-game.yml` instead, so game pushes are no longer gated on the legacy trees.
- A `shellcheck` job lints every `scripts/*.sh` with the digest-pinned `koalaman/shellcheck` 0.11.0 image. Run the same check locally with `docker run --rm -v "$PWD:/mnt" -w /mnt koalaman/shellcheck:v0.11.0 scripts/*.sh`; keep new/edited scripts clean.

### Legacy-tree findings (recorded 2026-10-08, T50; Android toolchain moved forward by T71)

- `gradle/wrapper/gradle-wrapper.jar` was a non-official build and failed `gradle/actions/setup-gradle` wrapper validation on every run. Regenerated with Gradle 8.7's own `wrapper` task — **Resolved (T50)**, validation passed on run 37830995010. The wrapper later moved to **9.7.0** (T71); that jar's checksum is the official `7a9ce74c…62c5d`, also validation-clean.
- ~~The Android tree toolchain mismatch~~ **Resolved by moving forward (T71, 2026-10-09):** T63 had reverted the piecemeal dependabot bumps (AGP 9.3.1 against the Gradle 8.7 wrapper broke every run — CI: "Minimum supported Gradle version is 9.5.0"). T71 then moved the whole toolchain forward as **one coordinated set**, built and verified locally under JDK 21: Gradle wrapper **9.7.0** (official checksum `7a9ce74c…62c5d`), AGP **9.3.1** (Kotlin support is now built into AGP — `org.jetbrains.kotlin.android` is no longer applied), Kotlin **2.4.10**, ktlint-gradle **14.2.0** (five formatting-only fixes in `GameEngine.kt`/`GameState.kt`/`GameView.kt` for its new rules), androidx set at the bumped versions, **compileSdk 37** (core-ktx 1.19.0 / lifecycle 2.11.0 require it); **targetSdk deliberately stays 35** (separate runtime-behavior opt-in for the owner). `ktlintCheck`, `testDebugUnitTest` (3/3), `lintDebug`, `assembleDebug` all green. `.github/dependabot.yml` now groups `android-toolchain` (wrapper + AGP + Kotlin + ktlint, excluding kotlinx) and `android-libraries` (androidx + kotlinx) so coupled bumps arrive together; CI's Android jobs run for every `gradle/**` change (and both trees if the diff base is unavailable), so a breaking bump fails before merge. The Android CI jobs use JDK 21 (what was verified here); the instrumented-emulator job is unchanged.
- `ios/MyGame.xcodeproj` fails to parse on the `macos-latest` runner under Xcode 26.6 ("project is damaged … parse error"), although the pbxproj passes static structure checks (no conflict markers, no dangling UUID refs, valid OpenStep plist, no BOM/CRLF, balanced braces, no duplicate keys, no non-ASCII bytes; `objectVersion 56` / `compatibilityVersion "Xcode 14.0"` is a pair Xcode itself writes). Needs a macOS host to root-cause. The iOS job remains gated to `ios/**` and will re-surface this on real changes there.

## Coverage

Android coverage is uploaded to [Codecov](https://codecov.io/); thresholds are configured in [`git/codecov.yaml`](https://github.com/ACFHarbinger/Project-Mobile-Fortress/blob/main/codecov.yaml). iOS coverage is not currently collected/uploaded — add `-enableCodeCoverage YES` to the `ios-test` CI step and a coverage-export step if you want parity.

## Writing Tests

See [`.agent/rules/testing_qa.md`](https://github.com/ACFHarbinger/Project-Mobile-Fortress/blob/main/.agent/rules/testing_qa.md) and [`.agent/workflows/testing_qa.md`](https://github.com/ACFHarbinger/Project-Mobile-Fortress/blob/main/.agent/workflows/testing_qa.md) for Android edge cases that need explicit coverage (surface teardown mid-frame, process-death-and-restore, rotation while paused vs. running), and [`.agent/rules/swift.md`](https://github.com/ACFHarbinger/Project-Mobile-Fortress/blob/main/.agent/rules/swift.md) / [`.agent/workflows/ios_lifecycle.md`](https://github.com/ACFHarbinger/Project-Mobile-Fortress/blob/main/.agent/workflows/ios_lifecycle.md) for the iOS equivalents (scene backgrounding, save/restore).
