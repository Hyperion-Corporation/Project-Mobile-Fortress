# Workflow: Testing & QA

## Android

1. Classify the change: pure logic (`engine/`) → unit test under `android/app/src/test/`; anything touching Android framework classes (`Activity`, `SurfaceView`, Compose UI) → instrumented test under `android/app/src/androidTest/`.
2. Write the test before or alongside the fix/feature, asserting a concrete expected value — not just "doesn't throw."
3. For game-loop/timing-sensitive changes, add a boundary-condition test (see [`.agent/rules/testing_qa.md`](../rules/testing_qa.md)) in addition to the happy path.
4. Run `just unit-test` locally (fast, JVM-only) before pushing; run `just test-instrumented` for anything lifecycle/UI-related before opening a PR — CI runs it too but it's the slowest job, catch failures locally first.
5. Run `just lint-check` (`ktlintCheck` + Android Lint) — treat new lint warnings on touched files as blocking, pre-existing warnings elsewhere as out of scope for this change.

## iOS

1. Add the test to `ios/Tests/` — there's no unit-vs-instrumented split to classify into (see `docs/TESTING.md`), just write it against `@testable import MyGame`.
2. Write the test before or alongside the fix/feature, asserting a concrete expected value — not just "doesn't throw."
3. For `GameScene`/game-loop-timing changes, add a boundary-condition test on the delta-clamping behavior (see [`.agent/rules/testing_qa.md`](../rules/testing_qa.md)) in addition to the happy path.
4. Run `just ios-test` locally (needs a simulator) before pushing — requires a macOS host, see [`.devcontainer/README.md`](../../.devcontainer/README.md).
5. Run `just ios-check` (`xcodebuild analyze`) — treat new warnings on touched files as blocking, pre-existing warnings elsewhere as out of scope for this change.
