# Testing Guide

| Layer | Location | Framework | Command |
| --- | --- | --- | --- |
| Android unit tests (JVM) | `android/app/src/test/` | JUnit 4 + `kotlin.test` | `./gradlew testDebugUnitTest` (`just unit-test`) |
| Android instrumented tests (on-device) | `android/app/src/androidTest/` | JUnit 4 + Espresso + Compose UI test | `./gradlew connectedDebugAndroidTest` (`just test-instrumented`) |
| iOS unit tests | `ios/Tests/` | XCTest | `xcodebuild ... test` (`just ios-test`) |
| Godot headless smokes | `game/tests/*_smoke.gd` | Godot 4.7 `--headless` `SceneTree` scripts | `just test::godot-smokes` (`scripts/run_godot_smokes.sh`) |

## Godot headless smokes (game/)

Every `game/tests/*_smoke.gd` is a headless `SceneTree` smoke invoked as `godot --path game --headless --script res://tests/<name>.gd`. `scripts/run_godot_smokes.sh` (wrapped by `just test::godot-smokes`) discovers them automatically — adding a new `*_smoke.gd` needs no runner or CI edits. It performs a one-off `--import` pass, runs each smoke with a per-smoke timeout (`SMOKE_TIMEOUT`, default 120s), and fails a smoke on a non-zero exit **or** on known Godot failure text in its output (`SCRIPT ERROR`, `Parse Error`, a printed `FAIL`) even when the exit code is 0. It prints a per-smoke PASS/FAIL table, writes a combined log (`SMOKE_LOG`), and exits non-zero if any smoke failed. A fresh import that aborts with exit 134 is retried once; other non-zero exits, a failed retry, or failure text from either attempt fail the gate; smokes still run to collect diagnostics. Timeouts force termination after a further five seconds if the process ignores SIGTERM. Run a subset with `just test::godot-smokes simulation gameplay`; override the binary with `GODOT=/path/to/godot`.

Smokes that genuinely cannot run headless belong in the commented `SKIP_LIST` at the top of the script, each with a stated reason (currently empty — all smokes run). The native extension must be built first (`game/bin/libmobile_fortress_core*.so`, see `game/BUILD_CPP.md`).

CI: `.github/workflows/godot-game.yml` runs the script on every PR/push touching `game/**` (plus the unchanged CMake/`ctest` job) and uploads `godot-smokes.log` as an artifact when the smoke job fails.

Runner regression tests use a temporary fixture and fake Godot binary: `python3 -m unittest discover -s scripts/tests -p test_run_godot_smokes.py -v` (also run in CI).

## What goes where

- **Android unit tests**: pure `engine/` logic — entity update math, collision detection, `GameState` serialization round-trips, the fixed-timestep accumulator's catch-up cap. No Android framework classes.
- **Android instrumented tests**: anything touching real framework behavior — `Activity`/`SurfaceView` lifecycle transitions, Compose screen rendering and interaction, permission flows.
- **iOS tests** (`ios/Tests/`): `GameManagerTests` (state-machine transitions), `HighScoreStoreTests` (persistence + ranking), `LevelLoaderTests` (JSON decoding against `game/src/level-schema.json`), `PhysicsMathTests` (pure movement math on `PlayerNode`, no live `SKScene`/physics simulation required). Kept framework-light on purpose — none of these need a running app or UI interaction, only a simulator to host the test bundle.

## CI

`.github/workflows/ci.yml` covers the legacy template trees and `scripts/*.sh`:

- A `changes` job diffs the push/PR range and gates the legacy jobs per tree: the three Android jobs run only when `android/**`, `gradle/**`, the root Gradle build files, `justfile`, or the workflow itself change; `ios-test` (`macos-latest`, full XCTest suite via `xcodebuild`) runs only when `ios/**` or the workflow changes. The live product under `game/**` is covered by `.github/workflows/godot-game.yml` instead, so game pushes are no longer gated on the legacy trees.
- A `shellcheck` job lints every `scripts/*.sh` with the digest-pinned `koalaman/shellcheck` 0.11.0 image. Run the same check locally with `docker run --rm -v "$PWD:/mnt" -w /mnt koalaman/shellcheck:v0.11.0 scripts/*.sh`; keep new/edited scripts clean.

### Legacy-tree findings (recorded 2026-10-08, T50)

- `gradle/wrapper/gradle-wrapper.jar` was a non-official build and failed `gradle/actions/setup-gradle` wrapper validation on every run. It was regenerated with Gradle 8.7's own `wrapper` task and now matches the official 8.7 checksum (`cb0da675…156b8`).
- The Android tree still has a toolchain mismatch: `gradle/libs.versions.toml` pins **AGP 9.3.1**, which cannot run on the wrapper-pinned **Gradle 8.7** (`NoClassDefFoundError: org/gradle/features/binding/ProjectTypeBinding` at plugin apply — a Gradle 9 API). Deliberate product fix needed: AGP back to 8.5.2 (per `.agent/AGENTS.md`) or a wrapper upgrade to Gradle 9.x.
- `ios/MyGame.xcodeproj` fails to parse on the `macos-latest` runner under Xcode 26.6 ("project is damaged … parse error"), although the pbxproj passes static structure checks (no conflict markers, no dangling UUID refs, valid OpenStep plist, no BOM/CRLF). Needs a macOS host to root-cause. The Android/iOS jobs remain wired to their trees and will re-run (and re-surface these findings) on real changes there.

## Coverage

Android coverage is uploaded to [Codecov](https://codecov.io/); thresholds are configured in [`git/codecov.yaml`](https://github.com/ACFHarbinger/Project-Mobile-Fortress/blob/main/codecov.yaml). iOS coverage is not currently collected/uploaded — add `-enableCodeCoverage YES` to the `ios-test` CI step and a coverage-export step if you want parity.

## Writing Tests

See [`.agent/rules/testing_qa.md`](https://github.com/ACFHarbinger/Project-Mobile-Fortress/blob/main/.agent/rules/testing_qa.md) and [`.agent/workflows/testing_qa.md`](https://github.com/ACFHarbinger/Project-Mobile-Fortress/blob/main/.agent/workflows/testing_qa.md) for Android edge cases that need explicit coverage (surface teardown mid-frame, process-death-and-restore, rotation while paused vs. running), and [`.agent/rules/swift.md`](https://github.com/ACFHarbinger/Project-Mobile-Fortress/blob/main/.agent/rules/swift.md) / [`.agent/workflows/ios_lifecycle.md`](https://github.com/ACFHarbinger/Project-Mobile-Fortress/blob/main/.agent/workflows/ios_lifecycle.md) for the iOS equivalents (scene backgrounding, save/restore).
