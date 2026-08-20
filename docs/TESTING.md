# Testing Guide

| Layer | Location | Framework | Command |
| --- | --- | --- | --- |
| Android unit tests (JVM) | `android/app/src/test/` | JUnit 4 + `kotlin.test` | `./gradlew testDebugUnitTest` (`just unit-test`) |
| Android instrumented tests (on-device) | `android/app/src/androidTest/` | JUnit 4 + Espresso + Compose UI test | `./gradlew connectedDebugAndroidTest` (`just test-instrumented`) |
| iOS unit tests | `ios/Tests/` | XCTest | `xcodebuild ... test` (`just ios-test`) |

## What goes where

- **Android unit tests**: pure `engine/` logic — entity update math, collision detection, `GameState` serialization round-trips, the fixed-timestep accumulator's catch-up cap. No Android framework classes.
- **Android instrumented tests**: anything touching real framework behavior — `Activity`/`SurfaceView` lifecycle transitions, Compose screen rendering and interaction, permission flows.
- **iOS tests** (`ios/Tests/`): `GameManagerTests` (state-machine transitions), `HighScoreStoreTests` (persistence + ranking), `LevelLoaderTests` (JSON decoding against `game/src/level-schema.json`), `PhysicsMathTests` (pure movement math on `PlayerNode`, no live `SKScene`/physics simulation required). Kept framework-light on purpose — none of these need a running app or UI interaction, only a simulator to host the test bundle.

## CI

`.github/workflows/ci.yml` has four jobs: `android-lint-and-unit-test`, `android-build-debug`, and `android-instrumented-tests` (Ubuntu runners, unit tests + `ktlintCheck` + Android Lint on every push/PR, instrumented tests via `reactivecircus/android-emulator-runner` on a headless emulator — the slowest Android job, kept intentionally small), plus `ios-test` (a `macos-latest` runner running the full XCTest suite via `xcodebuild`).

## Coverage

Android coverage is uploaded to [Codecov](https://codecov.io/); thresholds are configured in [`git/codecov.yaml`](https://github.com/ACFHarbinger/Project-Mobile-Fortress/blob/main/codecov.yaml). iOS coverage is not currently collected/uploaded — add `-enableCodeCoverage YES` to the `ios-test` CI step and a coverage-export step if you want parity.

## Writing Tests

See [`.agent/rules/testing_qa.md`](https://github.com/ACFHarbinger/Project-Mobile-Fortress/blob/main/.agent/rules/testing_qa.md) and [`.agent/workflows/testing_qa.md`](https://github.com/ACFHarbinger/Project-Mobile-Fortress/blob/main/.agent/workflows/testing_qa.md) for Android edge cases that need explicit coverage (surface teardown mid-frame, process-death-and-restore, rotation while paused vs. running), and [`.agent/rules/swift.md`](https://github.com/ACFHarbinger/Project-Mobile-Fortress/blob/main/.agent/rules/swift.md) / [`.agent/workflows/ios_lifecycle.md`](https://github.com/ACFHarbinger/Project-Mobile-Fortress/blob/main/.agent/workflows/ios_lifecycle.md) for the iOS equivalents (scene backgrounding, save/restore).
