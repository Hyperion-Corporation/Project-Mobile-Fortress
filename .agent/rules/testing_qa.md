# Testing & QA Rules

## Android

- **Unit tests** (`android/app/src/test/`, JUnit 4 + `kotlin.test`, runs on the JVM via `testDebugUnitTest`) cover pure logic: `engine/` update/collision/scoring math, `GameState` save/restore serialization, utility scoring/curves. No `android.*` framework classes reachable here except via Robolectric if unavoidable — prefer keeping `engine/` framework-free instead.
- **Instrumented tests** (`android/app/src/androidTest/`, JUnit 4 + Espresso/Compose UI test, runs on a device/emulator via `connectedDebugAndroidTest`) cover anything touching real Android framework behavior: `Activity` lifecycle transitions, `SurfaceView` creation, Compose screen interaction, permission flows.
- Every new `engine/` class needs at least one unit test covering its update/render-adjacent logic with a concrete assertion, not just "doesn't throw."
- Test the fixed-timestep accumulator's catch-up cap explicitly (see [`game_loop_performance.md`](game_loop_performance.md)) — this is the kind of boundary condition that's invisible in normal play and only shows up as a production frame-rate collapse.
- Test game-state save/restore round-trips (`GameState` → serialized → `GameState`) with a value-equality assertion, not just "did it not crash."
- CI runs unit tests on every push; instrumented tests run via the `reactivecircus/android-emulator-runner` GitHub Action (see [`.github/workflows/ci.yml`](../../.github/workflows/ci.yml)) — keep the instrumented suite small and fast, it's the slowest CI job.

## Android edge cases that need explicit coverage

- Surface torn down mid-frame (`lockCanvas()` returns `null`) — render loop must not crash.
- App backgrounded and resumed mid-level — `GameState` must restore to the same logical position, not reset.
- Rotation while paused vs. while running.

## iOS

- **`ios/Tests/`** (XCTest, runs on a simulator via `xcodebuild test`) covers the same "pure logic vs. framework behavior" split as Android's two tiers, but in one target — see `docs/TESTING.md`'s note on why iOS doesn't need a separate instrumented tier.
- Every new `Engine/`/`Core/` type needs at least one test covering its behavior with a concrete assertion, not just "doesn't throw" — same standard as Android's `engine/`.
- Test `GameManager`'s state transitions explicitly (see `GameManagerTests.swift`) — this is iOS's equivalent of testing Android's fixed-timestep accumulator boundary conditions: the kind of thing that's invisible in normal play and only shows up as a stuck/incorrect screen.
- Test persistence round-trips (`HighScoreStore`, `SettingsStore`) with a value-equality assertion against a real (test-suite-scoped) `UserDefaults`, not a mock.

## iOS edge cases that need explicit coverage

- App backgrounded mid-run — `GameManager.pause()` must actually be reached (see [`.agent/workflows/ios_lifecycle.md`](../workflows/ios_lifecycle.md)); a score/level in progress must not be lost.
- `LevelLoader` given a missing/malformed resource name — must throw a typed `LevelLoaderError`, never crash (see `LevelLoaderTests.testThrowsForMissingLevel`).
